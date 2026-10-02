#!/bin/sh
# Makes the two kernel files from the NetBSD 1.6A/playstation2 GENERIC kernel:
#   netbsd      the kernel patched for "root on wd0a" (goes into the disk as /netbsd)
#   vmlinux.gz  the same kernel, gzipped, for the emulator's -kload-kernel
#               (kloader-instant only loads a kernel with this name)
#
# Usage:  KERNEL=path/to/netbsd-GENERIC.gz OUT=media/kernel ./make-kernel.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
: "${KERNEL:?set KERNEL to netbsd-GENERIC.gz (or the uncompressed kernel)}"
OUT=${OUT:-kernel}
mkdir -p "$OUT"
case "$KERNEL" in
	*.gz) gzip -dc "$KERNEL" > "$OUT/netbsd-GENERIC" ;;
	*) cp "$KERNEL" "$OUT/netbsd-GENERIC" ;;
esac
python3 "$HERE/patch-rootspec.py" "$OUT/netbsd-GENERIC" "$OUT/netbsd" wd0a
gzip -9 -n -c "$OUT/netbsd" > "$OUT/vmlinux.gz"
rm -f "$OUT/netbsd-GENERIC"
md5sum "$OUT/netbsd" "$OUT/vmlinux.gz"
