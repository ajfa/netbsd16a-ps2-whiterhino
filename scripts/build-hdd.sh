#!/bin/sh
# Builds a NetBSD 1.6A/playstation2 hard disk image: the NetBSD 1.6 hpcmips userland
# in FFSv1 on wd0a, 128 MB of swap on wd0b, and the disklabel in sector 1 with no MBR,
# as the port expects. Device nodes use the port's majors; the rest are made on the
# first boot with the port's MAKEDEV.
#
# Usage (as root, on Linux; needs makefs, python3):
#   SETS=media/sets KERNEL_ELF=media/kernel/netbsd HDD=netbsd-ps2-hdd.raw ./build-hdd.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
: "${SETS:?set SETS to the directory filled by fetch-sets.sh}"
: "${KERNEL_ELF:?set KERNEL_ELF to the patched kernel made by make-kernel.sh}"
: "${HDD:?set HDD to the disk image to create}"
TOTAL=$((2 * 1024 * 1024 * 2))          # 2 GiB in 512-byte sectors
A_OFF=64
B_SIZE=$((128 * 1024 * 2))              # 128 MiB of swap
A_SIZE=$((TOTAL - A_OFF - B_SIZE))
B_OFF=$((A_OFF + A_SIZE))
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
R=$WORK/root
mkdir -p "$R"

for s in base etc comp text man misc games; do
	tar -xzpf "$SETS/$s.tgz" --numeric-owner -C "$R"
done

cp "$SETS/port/ttys" "$R/etc/ttys"
cp "$SETS/port/MAKEDEV" "$R/dev/MAKEDEV"
cp "$SETS/port/MAKEDEV.local" "$R/dev/MAKEDEV.local"
chmod 555 "$R/dev/MAKEDEV"

cat > "$R/etc/fstab" <<'EOF'
/dev/wd0a	/	ffs	rw	1 1
/dev/wd0b	none	swap	sw	0 0
kernfs		/kern	kernfs	rw
EOF
mkdir -p "$R/kern"
# The running kernel at /netbsd, for ps, netstat and kvm_mkdb.
cp "$KERNEL_ELF" "$R/netbsd"
chmod 444 "$R/netbsd"
cat >> "$R/etc/rc.local" <<'EOF'
if [ ! -e /dev/ttyp0 ]; then
	echo -n ' MAKEDEV'; (cd /dev && sh MAKEDEV all)
fi
EOF
cat >> "$R/etc/rc.conf" <<'EOF'
rc_configured=YES
hostname=ps2
sendmail=NO
postfix=NO
inetd=NO
cron=YES
wscons=NO
savecore=NO
update_motd=NO
dhclient=YES
dhclient_flags="smap0"
EOF

# Minimal /dev with the playstation2 majors (netbsd-1-6 MAKEDEV).
cd "$R/dev"
rm -f console null zero mem kmem tty klog drum stdin stdout stderr ttyE* ttyEcfg wd0* rwd0*
mknod console c 2 0; mknod null c 0 2; mknod zero c 0 12
mknod mem c 0 0; mknod kmem c 0 1; mknod drum c 1 0; mknod klog c 5 0
mknod tty c 3 0; mknod stdin c 4 0; mknod stdout c 4 1; mknod stderr c 4 2
chmod 666 null zero tty stdin stdout stderr; chmod 640 mem kmem drum; chmod 600 klog console
for u in 0 1 2 3; do mknod ttyE$u c 27 $u; done; mknod ttyEcfg c 27 255
i=0; for p in a b c d e f g h; do mknod wd0$p b 1 $i; mknod rwd0$p c 10 $i; i=$((i + 1)); done
# dhclient runs before rc.local's MAKEDEV and needs bpf on the first boot.
for u in 0 1 2 3; do mknod bpf$u c 25 $u; done; chmod 600 bpf*
mknod random c 26 0; mknod urandom c 26 1; chmod 444 random; chmod 644 urandom
chmod 640 wd0* rwd0*; chgrp 5 wd0* rwd0*
cd /

makefs -t ffs -B le -o version=1,bsize=8192,fsize=1024,minfree=5 \
	-s $((A_SIZE * 512)) "$WORK/root.ffs" "$R"
rm -f "$HDD"
truncate -s $((TOTAL * 512)) "$HDD"
dd if="$WORK/root.ffs" of="$HDD" bs=512 seek=$A_OFF conv=notrunc status=none
python3 "$HERE/disklabel.py" "$HDD" $TOTAL $A_OFF $A_SIZE $B_OFF $B_SIZE
echo "Built $HDD"
