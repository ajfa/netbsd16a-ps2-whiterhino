#!/bin/sh
# Checks the NetBSD 1.6 hpcmips binary sets (the userland: same little-endian MIPS ABI
# as the PS2) and downloads the playstation2 port files of the netbsd-1-6 branch that
# the disk needs (MAKEDEV, ttys).
#
# archive.netbsd.org cuts non-browser downloads short, so get these seven sets with a
# web browser first and put them in $SETS:
#   http://archive.netbsd.org/pub/NetBSD-archive/NetBSD-1.6/hpcmips/binary/sets/
#   base.tgz comp.tgz etc.tgz games.tgz man.tgz misc.tgz text.tgz
#
# Usage:  SETS=media/sets ./fetch-sets.sh
set -e
SETS=${SETS:-sets}
cd "$SETS"
# From the release's own MD5 file.
md5sum -c <<'EOF'
b1e7ecd1a384fdddfc36a1dd795cf0a5  base.tgz
d609a025034d8dcd3b258e6f217bfe28  comp.tgz
a58b0eca498f4b558cf243fbb467de12  etc.tgz
512dc16ab39798734350857e680baf38  games.tgz
a0e7b48a4cc4b7e4ea4d999a5e4ba3bf  man.tgz
99c5058410ed76571936a171296adc02  misc.tgz
978fb058f98ec3165f36b560a6f369bf  text.tgz
EOF
mkdir -p port
G=https://raw.githubusercontent.com/NetBSD/src/netbsd-1-6
curl -fsSL -o port/MAKEDEV "$G/etc/etc.playstation2/MAKEDEV"
curl -fsSL -o port/MAKEDEV.local "$G/etc/MAKEDEV.local"
curl -fsSL -o port/ttys "$G/etc/etc.playstation2/ttys"
ls -l port
