#!/usr/bin/env python3
# Writes a little-endian NetBSD 1.6 disklabel to sector 1 of an image with no MBR,
# which is where the playstation2 port looks for it (LABELSECTOR 1).
# Partitions: a = 4.2BSD, b = swap, c = whole disk.
#
# Usage: disklabel.py image total_sectors a_offset a_size b_offset b_size
import struct, sys

img, total, a_off, a_size, b_off, b_size = sys.argv[1], *map(int, sys.argv[2:7])
MAGIC = 0x82564557
nsect, ntrack = 63, 16
spc = nsect * ntrack
parts = [
	(a_size, a_off, 1024, 7, 8, 16),   # a: FS_BSDFFS, fsize 1024, frag 8, cpg 16
	(b_size, b_off, 0, 1, 0, 0),       # b: FS_SWAP
	(total, 0, 0, 0, 0, 0),            # c: whole disk
]


def label(checksum):
	h = struct.pack('<IHH16s16s', MAGIC, 1, 0, b'ESDI', b'ps2hdd')   # DTYPE_ST506
	h += struct.pack('<IIIIII', 512, nsect, ntrack, total // spc, spc, total)
	h += struct.pack('<HHI', 0, 0, 0)
	h += struct.pack('<HHHH', 3600, 1, 0, 0)
	h += struct.pack('<III', 0, 0, 0)
	h += struct.pack('<5I', 0, 0, 0, 0, 0) + struct.pack('<5I', 0, 0, 0, 0, 0)
	h += struct.pack('<IHHII', MAGIC, checksum, len(parts), 8192, 8192)
	for p in parts:
		h += struct.pack('<IIIBBH', *p)
	return h


raw = label(0)
ck = 0
for i in range(0, len(raw), 2):
	ck ^= struct.unpack_from('<H', raw, i)[0]
with open(img, 'r+b') as f:
	f.seek(512)
	f.write(label(ck))
