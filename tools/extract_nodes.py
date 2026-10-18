"""Extract model nodes (name, parent, 4x4 transform, resource) from the 9 course W3D members."""
import struct, json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from w3d_blocks import blocks

root = sys.argv[1]
out = sys.argv[2]
# course index -> XMED chunk (course order from GameBehaviour.ls:99: Track01Sky01, Track02Sky01, ...)
COURSE_CHUNKS = {1: 2687, 2: 2689, 3: 2691, 4: 2693, 5: 2695, 6: 2697, 7: 2699, 8: 2701, 9: 2703}

def pstr(b, p):
    n = struct.unpack_from('<H', b, p)[0]
    return b[p + 2:p + 2 + n].decode('latin1'), p + 2 + n

def parse_node(b):
    name, p = pstr(b, 0)
    parent, p = pstr(b, p)
    # find matrix: 16 floats, column 3 = (0,0,0,1)
    for k in range(p, p + 8):
        if k + 64 > len(b): break
        m = struct.unpack_from('<16f', b, k)
        if abs(m[15] - 1) < 1e-6 and abs(m[3]) < 1e-6 and abs(m[7]) < 1e-6 and abs(m[11]) < 1e-6:
            res, _ = pstr(b, k + 64)
            return {'name': name, 'parent': parent, 'matrix': [round(x, 6) for x in m], 'resource': res}
    return None

result = {}
for course, chunk in COURSE_CHUNKS.items():
    d = open(os.path.join(root, f'XMED-{chunk}.bin'), 'rb').read()
    d = d[d.find(b'3DEM'):]
    nodes = []
    for t, o, sz in blocks(d):
        if (t & 0xff) == 0x72:
            n = parse_node(d[o:o + sz])
            if n: nodes.append(n)
            else: print('unparsed node in course', course)
    result[course] = nodes
    print(course, len(nodes), sorted({n['resource'] for n in nodes}))
json.dump(result, open(out, 'w'))
