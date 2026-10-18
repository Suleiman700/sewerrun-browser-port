"""Extract per-course placement data (checkpoints/photos/slalom/weapons/weaponsx) from decompiled game chunks."""
import struct, re, json, sys, os

root = sys.argv[1] if len(sys.argv) > 1 else '_work/decomp/game/chunks'
out = sys.argv[2] if len(sys.argv) > 2 else 'courses.json'

key = open(os.path.join(root, 'KEY_-3.bin'), 'rb').read()
_, _, _, used = struct.unpack_from('<HHII', key, 0)
xmed_of = {}
for i in range(used):
    sec, cast, fcc = struct.unpack_from('<II4s', key, 12 + i * 12)
    if fcc[::-1] == b'XMED':
        xmed_of[cast] = sec

def member_name(cast):
    d = open(os.path.join(root, f'CASt-{cast}.bin'), 'rb').read()
    m = re.search(rb'(checkpoints|photos|slalom|weaponsx|weapons)(\d)', d)
    return (m.group(1).decode(), int(m.group(2))) if m else None

def xmed_text(sec):
    d = open(os.path.join(root, f'XMED-{sec}.bin'), 'rb').read()
    # styled-text XMED: text stored as "<hexlen>,<text>"
    for m in re.finditer(rb'([0-9A-F]{1,6}),', d):
        n = int(m.group(1), 16)
        body = d[m.end():m.end() + n]
        if n == 0:
            continue
        if body.startswith(b'vector') and len(body) == n:
            return body.decode('latin1')
    return ''

vec = re.compile(r'vector\(\s*([-0-9.e+]+)\s*,\s*([-0-9.e+]+)\s*,\s*([-0-9.e+]+)\s*\)')
courses = {c: {} for c in range(1, 10)}
for f in os.listdir(root):
    if not f.startswith('CASt-'):
        continue
    cast = int(f[5:-4])
    nm = member_name(cast)
    if not nm or cast not in xmed_of:
        continue
    kind, course = nm
    lines = [l for l in re.split(r'[\r\n]+', xmed_text(xmed_of[cast])) if l.strip()]
    pts = []
    for l in lines:
        m = vec.search(l)
        if not m:
            print('unparsed line', kind, course, repr(l)); continue
        pts.append([float(m.group(i)) for i in (1, 2, 3)])
    if kind == 'checkpoints':
        courses[course][kind] = [{'pos': pts[i], 'axis': pts[i + 1]} for i in range(0, len(pts) - 1, 2)]
    else:
        courses[course][kind] = [{'pos': p} for p in pts]

json.dump(courses, open(out, 'w'), indent=1)
for c, v in courses.items():
    print(c, {k: len(x) for k, x in v.items()})
