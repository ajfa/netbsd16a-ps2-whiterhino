#!/usr/bin/env python3
# Patches the NetBSD 1.6A/playstation2 GENERIC kernel (built "root on ?") to mount its
# root from a given partition without asking: writes the device name over the start of
# the embedded configuration text (_CFG_, informational only), points the rootspec
# variable at it and sets rootdev (wd is block major 1 in the port).
#
# Usage: patch-rootspec.py kernel-in kernel-out [device, default wd0a]
import struct, subprocess, sys

src, dst = sys.argv[1], sys.argv[2]
dev = (sys.argv[3] if len(sys.argv) > 3 else 'wd0a').encode() + b'\0'
data = bytearray(open(src, 'rb').read())

ph = subprocess.run(['readelf', '-lW', src], capture_output=True, text=True, check=True).stdout
load = [l.split() for l in ph.splitlines() if l.strip().startswith('LOAD')][0]
foff, vaddr, filesz = int(load[1], 16), int(load[2], 16), int(load[4], 16)


def off(va):
	o = va - vaddr + foff
	assert foff <= o < foff + filesz, hex(va)
	return o


sym = {}
for l in subprocess.run(['nm', src], capture_output=True, text=True, check=True).stdout.splitlines():
	p = l.split()
	if len(p) == 3:
		sym[p[2]] = int(p[0], 16)

i = data.find(b'_CFG_### START CONFIG FILE')
assert i > 0, 'no embedded config text'
data[i:i + len(dev)] = dev
struct.pack_into('<I', data, off(sym['rootspec']), i - foff + vaddr)
unit, part = int(dev[2:3]), dev[3] - ord('a')
struct.pack_into('<I', data, off(sym['rootdev']), (1 << 8) | (unit * 8 + part))
open(dst, 'wb').write(data)
print('root on', dev[:-1].decode())
