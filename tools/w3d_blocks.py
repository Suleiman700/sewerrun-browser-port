import struct, sys, collections
def blocks(data):
    assert data[:4] == b'3DEM'
    off = 16  # 3DEM header
    while off + 8 <= len(data):
        t, sz = struct.unpack_from('<II', data, off)
        yield t, off + 8, sz
        off += 8 + sz
        off = (off + 3) & ~3
if __name__ == '__main__':
    tot = collections.Counter()
    for p in sys.argv[1:]:
        d = open(p, 'rb').read()
        c = collections.Counter()
        for t, o, sz in blocks(d):
            c[hex(t)] += 1
            if len(sys.argv) == 2:
                name = ''
                if sz > 2:
                    n = struct.unpack_from('<H', d, o)[0]
                    if 0 < n < 64: name = d[o+2:o+2+n].decode('latin1')
                print(hex(t), sz, name)
        tot.update(c)
    if len(sys.argv) > 2: print(tot)
