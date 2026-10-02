#!/bin/sh
# Boots NetBSD 1.6A/playstation2 in the patched WhiteRhino, in a window.
#
# Environment (paths; the defaults are relative to this directory):
#   PCSX2      the patched pcsx2-qt binary, built with the patched kloader
#              resources                        (default ../whiterhino/build/bin/pcsx2-qt)
#   BIOS_DIR   directory with the PS2 BIOS      (default ../bios)
#   BIOS_FILE  BIOS file name in BIOS_DIR       (default scph39001.bin)
#   KERNEL     vmlinux.gz made by make-kernel.sh (default ../media/kernel/vmlinux.gz)
#   HDD        disk image made by build-hdd.sh   (default ../netbsd-ps2-hdd.raw)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
PCSX2=${PCSX2:-$HERE/../whiterhino/build/bin/pcsx2-qt}
BIOS_DIR=${BIOS_DIR:-$HERE/../bios}
BIOS_FILE=${BIOS_FILE:-scph39001.bin}
KERNEL=${KERNEL:-$HERE/../media/kernel/vmlinux.gz}
HDD=${HDD:-$HERE/../netbsd-ps2-hdd.raw}
CFG=${XDG_CONFIG_HOME:-$HERE/../config}

mkdir -p "$CFG/PCSX2/inis"
cat > "$CFG/PCSX2/inis/PCSX2.ini" <<INI
[UI]
SettingsVersion = 1
SetupWizardIncomplete = false
ConfirmShutdown = false
StartFullscreen = false
[Folders]
Bios = $BIOS_DIR
[Filenames]
BIOS = $BIOS_FILE
[EmuCore]
HostFs = true
[EmuCore/CPU]
ExtraMemory = false
[EmuCore/CPU/Recompiler]
EnableEE = false
[EmuCore/GS]
Renderer = 13
[SPU2/Output]
Backend = Null
[DEV9/Hdd]
HddEnable = true
HddFile = $HDD
[DEV9/Eth]
EthEnable = true
EthApi = Sockets
EthDevice = Auto
InterceptDHCP = true
AutoMask = true
AutoGateway = true
ModeDNS1 = Internal
ModeDNS2 = Manual
[USB1]
Type = hidkbd
[AutoUpdater]
CheckAtStartup = false
INI

export XDG_CONFIG_HOME="$CFG"
# Guest kernel entry point: from here on user-mode SYSCALLs go to NetBSD, not to the
# BIOS syscall HLE.
export WHITERHINO_GUEST_ENTRY=0x80010000
export LIBGL_ALWAYS_SOFTWARE=1
[ -n "$DISPLAY" ] && export QT_QPA_PLATFORM=xcb
exec "$PCSX2" -nogui -fastboot -logfile "$CFG/emulator.log" \
	-kload-kernel "$KERNEL" -kload-instant
