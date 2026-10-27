#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Kernelsmith build script — generated 2026-10-27 17:06 UTC
#
#  Kernel name : 7.3.0-ks-genx-ks
#  Profile     : Gaming
#  Source      : /usr/src/linux-7.3.0-cachyos-r3
#  Build tree  : /usr/src/linux-7.3.0-ks-genx-ks
#
#  This is exactly what Kernelsmith runs as root. You can keep it and run it
#  yourself later with:   sudo bash /tmp/claude-1000/-home-edo-backup-omgently-EDORP/204675f9-58aa-424c-ae12-ad31cfde4189/scratchpad/xdg/data/kernelsmith/jobs/20261027-170601-genx-ks/build.sh
#  Your original source tree in /usr/src is never modified.
# ─────────────────────────────────────────────────────────────────────────────
set -Eeuo pipefail
exec 2>&1
umask 022
export LC_ALL=C LANG=C HOME=/root
export PATH=/usr/lib/llvm/22/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

JOB=/tmp/claude-1000/-home-edo-backup-omgently-EDORP/204675f9-58aa-424c-ae12-ad31cfde4189/scratchpad/xdg/data/kernelsmith/jobs/20261027-170601-genx-ks
SRC=/usr/src/linux-7.3.0-cachyos-r3
TREE=/usr/src/linux-7.3.0-ks-genx-ks
REL=7.3.0-ks-genx-ks
JOBS=32
STATE=/var/lib/kernelsmith
MANIFEST="$STATE/kernels/$REL.toml"
MAKE=(make -C "$TREE" --no-print-directory -j"$JOBS" LOCALVERSION= LLVM=1)

stage() { echo "::stage::$1::$2"; }
note()  { echo "::note::$*"; }
warn()  { echo "::warn::$*"; }
fail()  { echo "::error::$*"; exit 1; }
kconf() { "$TREE/scripts/config" --file "$TREE/.config" "$@"; }
at_least_m() {
    local s
    for s in "$@"; do
        grep -q "^CONFIG_$s=y" "$TREE/.config" || kconf -m "$s"
    done
}

INSTALL_STARTED=0
TREE_CREATED=0
cleanup() {
    local rc=$?
    if [[ $rc -ne 0 && $TREE_CREATED -eq 1 && $INSTALL_STARTED -eq 0 ]]; then
        echo "::note::Removing the unfinished build tree $TREE"
        rm -rf --one-file-system "$TREE"
    fi
}
trap cleanup EXIT
trap 'echo "::error::Command failed (line $LINENO): $BASH_COMMAND"' ERR
trap 'echo "::error::Build cancelled"; exit 130' TERM INT

echo "::plan::preflight,prepare,config,verify,build,modules,kernel,modrebuild,clean"

# ── 1. Preflight ─────────────────────────────────────────────────────────────
stage preflight "Checking your system"
[[ $EUID -eq 0 ]] || fail "This script must run as root (try: sudo bash $0)."
for tool in make patch bc flex bison perl cpio awk sed clang ld.lld llvm-ar llvm-nm llvm-objcopy pahole openssl; do
    command -v "$tool" >/dev/null || fail "Missing build tool: $tool"
done
[[ -d $SRC ]] || fail "Source tree $SRC not found."
[[ ! -e $TREE ]] || fail "$TREE already exists — pick another kernel name."
[[ ! -e /lib/modules/$REL ]] || fail "A kernel called $REL is already installed."
note "Building $REL with $JOBS parallel jobs"

# ── 2. Prepare an untouched copy of the source ───────────────────────────────
stage prepare "Preparing kernel source"
note "Copying the source to $TREE (instant on btrfs/xfs thanks to reflinks)"
TREE_CREATED=1
cp -a --reflink=auto "$SRC" "$TREE"
mkdir -p "$TREE/.kernelsmith"
cp "$JOB/plan.toml" "$TREE/.kernelsmith/plan.toml"
note "Cleaning the copy (make mrproper)"
"${MAKE[@]}" -s mrproper
rm -f "$TREE"/localversion*

# ── 4. Configure ─────────────────────────────────────────────────────────────
stage config "Configuring"
note 'Starting from: Your current kernel'\''s configuration'
cp "$JOB/seed.config" "$TREE/.config"
"${MAKE[@]}" -s olddefconfig
note "Keeping only drivers for your hardware (make localmodconfig)"
( yes '' || true ) | "${MAKE[@]}" LSMOD="$JOB/modules.lst" LMC_KEEP=arch/x86/crypto:arch/x86/kvm:crypto:drivers/block:drivers/bluetooth:drivers/cdrom:drivers/hid:drivers/hwmon:drivers/i2c:drivers/input:drivers/leds:drivers/md:drivers/media/common:drivers/media/mc:drivers/media/usb:drivers/media/v4l2-core:drivers/memstick:drivers/mmc:drivers/net/wireguard:drivers/thunderbolt:drivers/usb/class:drivers/usb/serial:drivers/usb/storage:drivers/usb/typec:drivers/vfio:drivers/vhost:fs/autofs:fs/btrfs:fs/cachefiles:fs/erofs:fs/exfat:fs/ext4:fs/f2fs:fs/fat:fs/fuse:fs/hfs:fs/hfsplus:fs/isofs:fs/netfs:fs/nfs:fs/nfs_common:fs/nfsd:fs/nls:fs/ntfs3:fs/overlayfs:fs/smb:fs/squashfs:fs/udf:fs/xfs:lib/crypto:net/8021q:net/bluetooth:net/bridge:net/ipv4/netfilter:net/ipv6/netfilter:net/key:net/netfilter:net/sched:net/sunrpc:net/tls:net/vmw_vsock:net/xfrm:sound/core:sound/drivers:sound/usb:virt localmodconfig \
    > "$TREE/.kernelsmith/localmodconfig.log" 2>&1 \
    || { tail -n 20 "$TREE/.kernelsmith/localmodconfig.log"; fail "localmodconfig failed"; }

apply_choices() {
    # Link-Time Optimization (LTO): ThinLTO
    kconf -e LTO_CLANG_THIN -d LTO_NONE -d LTO_CLANG_FULL -d LTO_CLANG_THIN_DIST
    # Optimization level: -O3
    kconf -e CC_OPTIMIZE_FOR_PERFORMANCE_O3 -d CC_OPTIMIZE_FOR_PERFORMANCE -d CC_OPTIMIZE_FOR_SIZE
    # Profile-guided optimization (AutoFDO): Off
    kconf -d AUTOFDO_CLANG -d PROPELLER_CLANG
    # CPU instruction set: Native (this CPU)
    kconf -e X86_NATIVE_CPU -d GENERIC_CPU -d MZEN4
    # Default CPU speed policy: Performance
    kconf -e CPU_FREQ_DEFAULT_GOV_PERFORMANCE -d CPU_FREQ_DEFAULT_GOV_POWERSAVE -d CPU_FREQ_DEFAULT_GOV_USERSPACE -d CPU_FREQ_DEFAULT_GOV_ONDEMAND -d CPU_FREQ_DEFAULT_GOV_CONSERVATIVE -d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
    # CPU scheduler: BORE
    kconf -e SCHED_BORE
    # sched_ext (swappable BPF schedulers): On
    kconf -e BPF_SYSCALL -e BPF_JIT -e DEBUG_INFO_BTF -e SCHED_CLASS_EXT
    # Timer frequency: 1000 Hz
    kconf -e HZ_1000 -d HZ_100 -d HZ_250 -d HZ_300 -d HZ_500 -d HZ_600 -d HZ_750 --set-val HZ 1000
    # Preemption model: Full
    kconf -e PREEMPT -d PREEMPT_LAZY -d PREEMPT_RT -e PREEMPT_DYNAMIC
    # Idle timer behaviour: Idle tickless
    kconf -e NO_HZ_IDLE -d HZ_PERIODIC -d NO_HZ_FULL -e NO_HZ
    # Transparent Huge Pages: Always
    kconf -e TRANSPARENT_HUGEPAGE -e TRANSPARENT_HUGEPAGE_ALWAYS -d TRANSPARENT_HUGEPAGE_MADVISE -d TRANSPARENT_HUGEPAGE_NEVER
    # Multi-Gen LRU: On
    kconf -e LRU_GEN -e LRU_GEN_ENABLED
    # Compressed memory (zswap & zram): On (zstd)
    kconf -e ZSWAP -e ZSWAP_DEFAULT_ON -e ZSWAP_SHRINKER_DEFAULT_ON -e CRYPTO_ZSTD -e ZSWAP_COMPRESSOR_DEFAULT_ZSTD -d ZSWAP_COMPRESSOR_DEFAULT_DEFLATE -d ZSWAP_COMPRESSOR_DEFAULT_LZO -d ZSWAP_COMPRESSOR_DEFAULT_842
    kconf -d ZSWAP_COMPRESSOR_DEFAULT_LZ4 -d ZSWAP_COMPRESSOR_DEFAULT_LZ4HC -e ZRAM_BACKEND_ZSTD -e ZRAM_BACKEND_LZ4
    at_least_m ZRAM
    # NTSYNC for Wine & Proton: On
    kconf -e NTSYNC
    # Controllers & Steam support: Keep
    kconf -e USER_NS -e FUTEX -e HIDRAW -e INPUT_JOYSTICK -e USB_HIDDEV -e JOYSTICK_XPAD_FF
    at_least_m INPUT_UINPUT UHID INPUT_JOYDEV INPUT_EVDEV JOYSTICK_XPAD HID_PLAYSTATION HID_SONY HID_NINTENDO
    at_least_m HID_STEAM HID_MICROSOFT HID_LOGITECH
    # TCP congestion control: BBRv3
    kconf -e TCP_CONG_ADVANCED -e TCP_CONG_BBR3 -e DEFAULT_BBR3 -d DEFAULT_BIC -d DEFAULT_CUBIC -d DEFAULT_HTCP -d DEFAULT_HYBLA -d DEFAULT_VEGAS
    kconf -d DEFAULT_VENO -d DEFAULT_WESTWOOD -d DEFAULT_DCTCP -d DEFAULT_RENO -d DEFAULT_BBR --set-str DEFAULT_TCP_CONG bbr3 -e NET_SCH_FQ -e NET_SCH_DEFAULT
    kconf -e DEFAULT_FQ -d DEFAULT_FQ_CODEL -d DEFAULT_FQ_PIE -d DEFAULT_SFQ -d DEFAULT_PFIFO_FAST
    # Disk I/O schedulers: Build all in
    kconf -e MQ_IOSCHED_DEADLINE -e MQ_IOSCHED_KYBER -e IOSCHED_BFQ -e MQ_IOSCHED_ADIOS
    # Debug information: Minimal + BTF
    kconf -e DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT -d DEBUG_INFO_NONE -d DEBUG_INFO_DWARF4 -d DEBUG_INFO_DWARF5 -e DEBUG_INFO_BTF -e DEBUG_INFO_BTF_MODULES -d DEBUG_INFO_REDUCED
    # Developer self-checks: Turn off
    kconf -d KASAN -d KCSAN -d KMSAN -d UBSAN -d LOCKDEP -d PROVE_LOCKING -d LOCK_STAT -d DEBUG_ATOMIC_SLEEP
    kconf -d DEBUG_PREEMPT -d DEBUG_MUTEXES -d DEBUG_RT_MUTEXES -d DEBUG_SPINLOCK -d DEBUG_LIST -d DEBUG_SG -d DEBUG_NOTIFIERS -d DEBUG_KMEMLEAK
    kconf -d DEBUG_PAGEALLOC -d PAGE_OWNER -d SLUB_DEBUG_ON -d DEBUG_VM -d DEBUG_OBJECTS -d LATENCYTOP -d ACPI_DEBUG
    # Kernel & module compression: zstd
    kconf -e KERNEL_ZSTD -d KERNEL_GZIP -d KERNEL_BZIP2 -d KERNEL_LZMA -d KERNEL_XZ -d KERNEL_LZO -d KERNEL_LZ4 -e MODULE_COMPRESS
    kconf -e MODULE_COMPRESS_ZSTD -d MODULE_COMPRESS_GZIP -d MODULE_COMPRESS_XZ -e MODULE_COMPRESS_ALL
    # Rust kernel support: Off
    kconf -d RUST
    # Built-in boot options (Clear Linux style): Desktop
    kconf -e CMDLINE_BOOL --set-str CMDLINE 'nowatchdog nmi_watchdog=0 page_alloc.shuffle=1' -d CMDLINE_OVERRIDE
    # CPU vulnerability mitigations: Keep on
    kconf -e CPU_MITIGATIONS
    # Module signing: Sign and enforce
    kconf -e MODULE_SIG -e MODULE_SIG_ALL -d MODULE_SIG_FORCE -e MODULE_SIG_SHA512 -d MODULE_SIG_SHA256 -d MODULE_SIG_SHA384 -d MODULE_SIG_SHA3_256 -d MODULE_SIG_SHA3_384
    kconf -d MODULE_SIG_SHA3_512 -e MODULE_SIG_FORCE -d MODULE_FORCE_LOAD
    # Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready
    kconf -e SECURITY -e SECURITYFS -e SECURITY_LOCKDOWN_LSM -e SECURITY_LOCKDOWN_LSM_EARLY -e LOCK_DOWN_KERNEL_FORCE_NONE -d LOCK_DOWN_KERNEL_FORCE_INTEGRITY -d LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY -e BPF_SYSCALL
    kconf -e BPF_LSM -e SECURITY_LANDLOCK -e SECURITY_YAMA -e INTEGRITY --set-str LSM landlock,lockdown,yama,integrity,bpf -e SYSTEM_TRUSTED_KEYRING -e SECONDARY_TRUSTED_KEYRING -e SECONDARY_TRUSTED_KEYRING_SIGNED_BY_BUILTIN
    kconf -d INTEGRITY_MACHINE_KEYRING -d MODULE_FORCE_LOAD -e IOMMU_SUPPORT -e IRQ_REMAP -d IOMMU_DEFAULT_PASSTHROUGH -e IOMMU_DEFAULT_DMA_LAZY -e TCG_TPM -e TCG_TIS
    kconf -e TCG_CRB -e TCG_TPM2_HMAC -e KEXEC -e KEXEC_FILE -e KEXEC_SIG -e INTEL_IOMMU -e INTEL_IOMMU_SVM -e EFI_STUB
    kconf -e EFI_HANDOVER_PROTOCOL
    # Unused security modules: Only what's active
    kconf -d SECURITY_SELINUX -d SECURITY_SMACK -d SECURITY_TOMOYO -d SECURITY_APPARMOR -d SECURITY_IPE -d SECURITY_LOADPIN -d SECURITY_SAFESETID
    # Hardening defaults with a runtime cost: Fast
    kconf -d INIT_ON_ALLOC_DEFAULT_ON -d RANDOMIZE_KSTACK_OFFSET_DEFAULT -d HARDENED_USERCOPY_DEFAULT_ON
    # CPU count & memory topology: This PC
    kconf -d MAXSMP --set-val NR_CPUS 32 -d NUMA
    # Virtual-machine guest support: Bare metal only
    kconf -d HYPERVISOR_GUEST -d PARAVIRT -d KVM_GUEST -d XEN -d HYPERV -d INTEL_TDX_GUEST -d VMWARE_VMCI -d VIRTIO_MENU
    # Platform features this PC doesn't have: This PC
    kconf -d X86_X32_ABI -d AMD_IOMMU -d AMD_MEM_ENCRYPT -d X86_AMD_PSTATE -d X86_AMD_PLATFORM_DEVICE -d KVM_AMD -d X86_SGX -d INTEL_TDX_HOST
    kconf -d EFI_MIXED -d DRM_I915 -d DRM_XE -d INTEL_MEI_HDCP -d INTEL_MEI_PXP -d DRM_AMDGPU -d DRM_RADEON
    # Keep: USB drives & card readers
    at_least_m USB_STORAGE USB_UAS MMC_BLOCK MMC_SDHCI_PCI
    # Keep: Filesystems for external drives
    at_least_m VFAT_FS EXFAT_FS NTFS3_FS ISO9660_FS UDF_FS FUSE_FS NLS_CODEPAGE_437 NLS_ISO8859_1
    at_least_m NLS_UTF8
    # Keep: More filesystems
    at_least_m EXT4_FS XFS_FS F2FS_FS BTRFS_FS SQUASHFS EROFS_FS HFSPLUS_FS CIFS
    at_least_m NFS_FS NFSD AUTOFS_FS
    # Keep: Encrypted, virtual & RAM disks
    at_least_m BLK_DEV_LOOP BLK_DEV_DM DM_CRYPT DM_SNAPSHOT BLK_DEV_NBD ZRAM CRYPTO_XTS CRYPTO_AES_NI_INTEL
    # Keep: Keyboards, mice & controllers
    kconf -e HIDRAW
    at_least_m HID_GENERIC USB_HID INPUT_UINPUT
    # Keep: Bluetooth
    at_least_m BT BT_HCIBTUSB BT_RFCOMM BT_HIDP
    # Keep: USB headsets, audio interfaces & MIDI
    at_least_m SND_USB_AUDIO SND_RAWMIDI SND_HRTIMER SND_ALOOP SND_VIRMIDI
    # Keep: Webcams & capture cards
    kconf -e MEDIA_USB_SUPPORT -e MEDIA_CAMERA_SUPPORT
    at_least_m MEDIA_SUPPORT USB_VIDEO_CLASS
    # Keep: VPN & virtual networking
    at_least_m WIREGUARD TUN BRIDGE VETH BRIDGE_NETFILTER VLAN_8021Q TLS IFB
    at_least_m DUMMY NET_SCH_CAKE NET_CLS_BPF NET_ACT_BPF
    # Keep: Virtual machines & containers
    at_least_m KVM VFIO VFIO_PCI VHOST_NET VHOST_VSOCK TUN BRIDGE VETH
    at_least_m OVERLAY_FS BRIDGE_NETFILTER MACVLAN MACVTAP IPVLAN VXLAN TAP KVM_INTEL
    # Keep: Docks, Thunderbolt & USB-C
    at_least_m USB4 TYPEC USB_RTL8152 USB_NET_AX88179_178A USB_NET_CDC_NCM
    # Keep: Sensors, fans & RGB controllers
    at_least_m I2C_CHARDEV
    # Keep: Optical drives & USB serial adapters
    at_least_m BLK_DEV_SR CDROM CHR_DEV_SG USB_SERIAL USB_ACM
    # Boot essentials
    kconf -e MODULES -e MODULE_UNLOAD -e BLK_DEV_INITRD -e RD_GZIP -e RD_XZ -e RD_ZSTD -e RD_LZ4 -e DEVTMPFS
    kconf -e DEVTMPFS_MOUNT -e TMPFS -e TMPFS_POSIX_ACL -e PROC_FS -e SYSFS -e BINFMT_ELF -e BINFMT_SCRIPT -e UNIX
    kconf -e INET -e IKCONFIG -e IKCONFIG_PROC -e FW_LOADER -e FW_LOADER_COMPRESS -e FW_LOADER_COMPRESS_XZ -e FW_LOADER_COMPRESS_ZSTD -e MICROCODE
    kconf -d LOCALVERSION_AUTO -e EFI -e EFI_STUB -e EFI_PARTITION -e SYSFB_SIMPLEFB -e DRM -e DRM_SIMPLEDRM
    at_least_m BINFMT_MISC EFIVAR_FS VFAT_FS NLS_CODEPAGE_437 NLS_ISO8859_1
    # Root filesystem (btrfs) & disk controllers
    kconf -e BTRFS_FS -e BLK_DEV_NVME -e VMD -e SCSI -e BLK_DEV_SD -e ATA -e SATA_AHCI
    # Mounted filesystems
    at_least_m EXT4_FS NTFS3_FS VFAT_FS
    # OpenRC support
    kconf -e GENTOO_LINUX -e GENTOO_LINUX_UDEV -e GENTOO_LINUX_PORTAGE -e GENTOO_LINUX_INIT_SCRIPT -e BINFMT_SCRIPT -e CGROUPS -e EPOLL -e FILE_LOCKING
    kconf -e INOTIFY_USER -e SIGNALFD -e TIMERFD -e SHMEM -e EVENTFD -e FHANDLE -e CGROUPS -e NAMESPACES
    kconf -e IPC_NS -e NET_NS -e PID_NS -e SYSVIPC -e USER_NS -e UTS_NS
    # NVIDIA driver requirements
    kconf -e PROC_FS -e SYSVIPC -e X86_PAT -e MODULES -e DRM -e DRM_SIMPLEDRM -e DRM_FBDEV_EMULATION -d LOCKDEP
    kconf -d PROVE_LOCKING -d SLUB_DEBUG_ON -d DEBUG_MUTEXES
    at_least_m DRM_QXL
    # CPU power & topology
    kconf -e SMP -e SCHED_MC -e CPU_SUP_INTEL -e X86_INTEL_PSTATE -e INTEL_IDLE -e SCHED_MC_PRIO -e X86_THERMAL_VECTOR -e INTEL_HFI_THERMAL
    at_least_m SENSORS_CORETEMP X86_PKG_TEMP_THERMAL
    # Kernel name
    kconf --set-str LOCALVERSION -ks-genx-ks -d LOCALVERSION_AUTO
}

note "Applying your choices"
apply_choices
"${MAKE[@]}" -s olddefconfig
# Second pass: some options only become selectable once others are on.
apply_choices
"${MAKE[@]}" -s olddefconfig
# ── Module signing key (created once, reused by every build) ─────────────────
SIGN_KEY=/etc/kernelsmith/keys/modules-signing.pem
if [[ ! -s $SIGN_KEY ]]; then
    note "Creating the module signing key $SIGN_KEY"
    mkdir -p "$(dirname "$SIGN_KEY")"
    (
        umask 077
        openssl req -new -x509 -newkey rsa:4096 -sha512 -days 36500 -nodes -batch             -subj "/CN=Kernelsmith module signing key ($(cat /proc/sys/kernel/hostname 2>/dev/null || echo pc))/"             -keyout "$SIGN_KEY.tmp" -out "${SIGN_KEY%.pem}.crt" >/dev/null 2>&1
        # One PEM with key + certificate: what scripts/sign-file and Portage's MODULES_SIGN_KEY expect.
        cat "${SIGN_KEY%.pem}.crt" >> "$SIGN_KEY.tmp"
        mv "$SIGN_KEY.tmp" "$SIGN_KEY"
    )
    # Portage signs rebuilt drivers as the portage user, so the group may read the key.
    if getent group portage >/dev/null; then
        chgrp portage "$SIGN_KEY" "${SIGN_KEY%.pem}.crt" && chmod 0640 "$SIGN_KEY" && chmod 0644 "${SIGN_KEY%.pem}.crt"
    fi
fi
[[ -s ${SIGN_KEY%.pem}.crt ]] || openssl x509 -in "$SIGN_KEY" -out "${SIGN_KEY%.pem}.crt"
kconf --set-str MODULE_SIG_KEY "$SIGN_KEY"
"${MAKE[@]}" -s olddefconfig
SIGN_HASH=$(sed -n 's/^CONFIG_MODULE_SIG_HASH="\(.*\)"/\1/p' "$TREE/.config")
SIGN_HASH=${SIGN_HASH:-sha512}

# ── 5. Verify every requested option actually took effect ────────────────────
stage verify "Verifying configuration"
CRIT_MISS=()
verify() {
    local got ok=0
    got=$(sed -n "s/^CONFIG_$1=//p" "$TREE/.config" | head -n1 || true)
    [[ -n $got ]] || got=n
    case "$2" in
        ym) [[ $got == y || $got == m ]] && ok=1 ;;
        *)  [[ $got == "$2" ]] && ok=1 ;;
    esac
    if (( ok )); then
        echo "::verify::ok::$1::$2::$got::$4"
    else
        echo "::verify::miss::$1::$2::$got::$4"
        [[ $3 == 1 ]] && CRIT_MISS+=("CONFIG_$1 ($4)")
    fi
    return 0
}
verify ACPI_DEBUG n 0 'Developer self-checks: Turn off'
verify AMD_IOMMU n 0 'Platform features this PC doesn'\''t have: This PC'
verify AMD_MEM_ENCRYPT n 0 'Platform features this PC doesn'\''t have: This PC'
verify ATA y 1 'Root filesystem (btrfs) & disk controllers'
verify AUTOFDO_CLANG n 0 'Profile-guided optimization (AutoFDO): Off'
verify AUTOFS_FS ym 0 'Keep: More filesystems'
verify BINFMT_ELF y 1 'Boot essentials'
verify BINFMT_MISC ym 1 'Boot essentials'
verify BINFMT_SCRIPT y 1 'OpenRC support'
verify BLK_DEV_DM ym 0 'Keep: Encrypted, virtual & RAM disks'
verify BLK_DEV_INITRD y 1 'Boot essentials'
verify BLK_DEV_LOOP ym 0 'Keep: Encrypted, virtual & RAM disks'
verify BLK_DEV_NBD ym 0 'Keep: Encrypted, virtual & RAM disks'
verify BLK_DEV_NVME y 1 'Root filesystem (btrfs) & disk controllers'
verify BLK_DEV_SD y 1 'Root filesystem (btrfs) & disk controllers'
verify BLK_DEV_SR ym 0 'Keep: Optical drives & USB serial adapters'
verify BPF_JIT y 0 'sched_ext (swappable BPF schedulers): On'
verify BPF_LSM y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify BPF_SYSCALL y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify BRIDGE ym 0 'Keep: Virtual machines & containers'
verify BRIDGE_NETFILTER ym 0 'Keep: Virtual machines & containers'
verify BT ym 0 'Keep: Bluetooth'
verify BTRFS_FS y 1 'Root filesystem (btrfs) & disk controllers'
verify BT_HCIBTUSB ym 0 'Keep: Bluetooth'
verify BT_HIDP ym 0 'Keep: Bluetooth'
verify BT_RFCOMM ym 0 'Keep: Bluetooth'
verify CC_OPTIMIZE_FOR_PERFORMANCE n 0 'Optimization level: -O3'
verify CC_OPTIMIZE_FOR_PERFORMANCE_O3 y 0 'Optimization level: -O3'
verify CC_OPTIMIZE_FOR_SIZE n 0 'Optimization level: -O3'
verify CDROM ym 0 'Keep: Optical drives & USB serial adapters'
verify CGROUPS y 1 'OpenRC support'
verify CHR_DEV_SG ym 0 'Keep: Optical drives & USB serial adapters'
verify CIFS ym 0 'Keep: More filesystems'
verify CMDLINE '"nowatchdog nmi_watchdog=0 page_alloc.shuffle=1"' 0 'Built-in boot options (Clear Linux style): Desktop'
verify CMDLINE_BOOL y 0 'Built-in boot options (Clear Linux style): Desktop'
verify CMDLINE_OVERRIDE n 0 'Built-in boot options (Clear Linux style): Desktop'
verify CPU_FREQ_DEFAULT_GOV_CONSERVATIVE n 0 'Default CPU speed policy: Performance'
verify CPU_FREQ_DEFAULT_GOV_ONDEMAND n 0 'Default CPU speed policy: Performance'
verify CPU_FREQ_DEFAULT_GOV_PERFORMANCE y 0 'Default CPU speed policy: Performance'
verify CPU_FREQ_DEFAULT_GOV_POWERSAVE n 0 'Default CPU speed policy: Performance'
verify CPU_FREQ_DEFAULT_GOV_SCHEDUTIL n 0 'Default CPU speed policy: Performance'
verify CPU_FREQ_DEFAULT_GOV_USERSPACE n 0 'Default CPU speed policy: Performance'
verify CPU_MITIGATIONS y 0 'CPU vulnerability mitigations: Keep on'
verify CPU_SUP_INTEL y 0 'CPU power & topology'
verify CRYPTO_AES_NI_INTEL ym 0 'Keep: Encrypted, virtual & RAM disks'
verify CRYPTO_XTS ym 0 'Keep: Encrypted, virtual & RAM disks'
verify CRYPTO_ZSTD y 0 'Compressed memory (zswap & zram): On (zstd)'
verify DEBUG_ATOMIC_SLEEP n 0 'Developer self-checks: Turn off'
verify DEBUG_INFO_BTF y 0 'Debug information: Minimal + BTF'
verify DEBUG_INFO_BTF_MODULES y 0 'Debug information: Minimal + BTF'
verify DEBUG_INFO_DWARF4 n 0 'Debug information: Minimal + BTF'
verify DEBUG_INFO_DWARF5 n 0 'Debug information: Minimal + BTF'
verify DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT y 0 'Debug information: Minimal + BTF'
verify DEBUG_INFO_NONE n 0 'Debug information: Minimal + BTF'
verify DEBUG_INFO_REDUCED n 0 'Debug information: Minimal + BTF'
verify DEBUG_KMEMLEAK n 0 'Developer self-checks: Turn off'
verify DEBUG_LIST n 0 'Developer self-checks: Turn off'
verify DEBUG_MUTEXES n 1 'NVIDIA driver requirements'
verify DEBUG_NOTIFIERS n 0 'Developer self-checks: Turn off'
verify DEBUG_OBJECTS n 0 'Developer self-checks: Turn off'
verify DEBUG_PAGEALLOC n 0 'Developer self-checks: Turn off'
verify DEBUG_PREEMPT n 0 'Developer self-checks: Turn off'
verify DEBUG_RT_MUTEXES n 0 'Developer self-checks: Turn off'
verify DEBUG_SG n 0 'Developer self-checks: Turn off'
verify DEBUG_SPINLOCK n 0 'Developer self-checks: Turn off'
verify DEBUG_VM n 0 'Developer self-checks: Turn off'
verify DEFAULT_BBR n 0 'TCP congestion control: BBRv3'
verify DEFAULT_BBR3 y 0 'TCP congestion control: BBRv3'
verify DEFAULT_BIC n 0 'TCP congestion control: BBRv3'
verify DEFAULT_CUBIC n 0 'TCP congestion control: BBRv3'
verify DEFAULT_DCTCP n 0 'TCP congestion control: BBRv3'
verify DEFAULT_FQ y 0 'TCP congestion control: BBRv3'
verify DEFAULT_FQ_CODEL n 0 'TCP congestion control: BBRv3'
verify DEFAULT_FQ_PIE n 0 'TCP congestion control: BBRv3'
verify DEFAULT_HTCP n 0 'TCP congestion control: BBRv3'
verify DEFAULT_HYBLA n 0 'TCP congestion control: BBRv3'
verify DEFAULT_PFIFO_FAST n 0 'TCP congestion control: BBRv3'
verify DEFAULT_RENO n 0 'TCP congestion control: BBRv3'
verify DEFAULT_SFQ n 0 'TCP congestion control: BBRv3'
verify DEFAULT_TCP_CONG '"bbr3"' 0 'TCP congestion control: BBRv3'
verify DEFAULT_VEGAS n 0 'TCP congestion control: BBRv3'
verify DEFAULT_VENO n 0 'TCP congestion control: BBRv3'
verify DEFAULT_WESTWOOD n 0 'TCP congestion control: BBRv3'
verify DEVTMPFS y 1 'Boot essentials'
verify DEVTMPFS_MOUNT y 1 'Boot essentials'
verify DM_CRYPT ym 0 'Keep: Encrypted, virtual & RAM disks'
verify DM_SNAPSHOT ym 0 'Keep: Encrypted, virtual & RAM disks'
verify DRM y 1 'NVIDIA driver requirements'
verify DRM_AMDGPU n 0 'Platform features this PC doesn'\''t have: This PC'
verify DRM_FBDEV_EMULATION y 1 'NVIDIA driver requirements'
verify DRM_I915 n 0 'Platform features this PC doesn'\''t have: This PC'
verify DRM_QXL ym 1 'NVIDIA driver requirements'
verify DRM_RADEON n 0 'Platform features this PC doesn'\''t have: This PC'
verify DRM_SIMPLEDRM y 1 'NVIDIA driver requirements'
verify DRM_XE n 0 'Platform features this PC doesn'\''t have: This PC'
verify DUMMY ym 0 'Keep: VPN & virtual networking'
verify EFI y 1 'Boot essentials'
verify EFIVAR_FS ym 1 'Boot essentials'
verify EFI_HANDOVER_PROTOCOL y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify EFI_MIXED n 0 'Platform features this PC doesn'\''t have: This PC'
verify EFI_PARTITION y 1 'Boot essentials'
verify EFI_STUB y 1 'Boot essentials'
verify EPOLL y 1 'OpenRC support'
verify EROFS_FS ym 0 'Keep: More filesystems'
verify EVENTFD y 1 'OpenRC support'
verify EXFAT_FS ym 0 'Keep: Filesystems for external drives'
verify EXT4_FS ym 1 'Mounted filesystems'
verify F2FS_FS ym 0 'Keep: More filesystems'
verify FHANDLE y 1 'OpenRC support'
verify FILE_LOCKING y 1 'OpenRC support'
verify FUSE_FS ym 0 'Keep: Filesystems for external drives'
verify FUTEX y 0 'Controllers & Steam support: Keep'
verify FW_LOADER y 1 'Boot essentials'
verify FW_LOADER_COMPRESS y 1 'Boot essentials'
verify FW_LOADER_COMPRESS_XZ y 1 'Boot essentials'
verify FW_LOADER_COMPRESS_ZSTD y 1 'Boot essentials'
verify GENERIC_CPU n 0 'CPU instruction set: Native (this CPU)'
verify GENTOO_LINUX y 1 'OpenRC support'
verify GENTOO_LINUX_INIT_SCRIPT y 1 'OpenRC support'
verify GENTOO_LINUX_PORTAGE y 1 'OpenRC support'
verify GENTOO_LINUX_UDEV y 1 'OpenRC support'
verify HARDENED_USERCOPY_DEFAULT_ON n 0 'Hardening defaults with a runtime cost: Fast'
verify HFSPLUS_FS ym 0 'Keep: More filesystems'
verify HIDRAW y 0 'Keep: Keyboards, mice & controllers'
verify HID_GENERIC ym 0 'Keep: Keyboards, mice & controllers'
verify HID_LOGITECH ym 0 'Controllers & Steam support: Keep'
verify HID_MICROSOFT ym 0 'Controllers & Steam support: Keep'
verify HID_NINTENDO ym 0 'Controllers & Steam support: Keep'
verify HID_PLAYSTATION ym 0 'Controllers & Steam support: Keep'
verify HID_SONY ym 0 'Controllers & Steam support: Keep'
verify HID_STEAM ym 0 'Controllers & Steam support: Keep'
verify HYPERV n 0 'Virtual-machine guest support: Bare metal only'
verify HYPERVISOR_GUEST n 0 'Virtual-machine guest support: Bare metal only'
verify HZ 1000 0 'Timer frequency: 1000 Hz'
verify HZ_100 n 0 'Timer frequency: 1000 Hz'
verify HZ_1000 y 0 'Timer frequency: 1000 Hz'
verify HZ_250 n 0 'Timer frequency: 1000 Hz'
verify HZ_300 n 0 'Timer frequency: 1000 Hz'
verify HZ_500 n 0 'Timer frequency: 1000 Hz'
verify HZ_600 n 0 'Timer frequency: 1000 Hz'
verify HZ_750 n 0 'Timer frequency: 1000 Hz'
verify HZ_PERIODIC n 0 'Idle timer behaviour: Idle tickless'
verify I2C_CHARDEV ym 0 'Keep: Sensors, fans & RGB controllers'
verify IFB ym 0 'Keep: VPN & virtual networking'
verify IKCONFIG y 1 'Boot essentials'
verify IKCONFIG_PROC y 1 'Boot essentials'
verify INET y 1 'Boot essentials'
verify INIT_ON_ALLOC_DEFAULT_ON n 0 'Hardening defaults with a runtime cost: Fast'
verify INOTIFY_USER y 1 'OpenRC support'
verify INPUT_EVDEV ym 0 'Controllers & Steam support: Keep'
verify INPUT_JOYDEV ym 0 'Controllers & Steam support: Keep'
verify INPUT_JOYSTICK y 0 'Controllers & Steam support: Keep'
verify INPUT_UINPUT ym 0 'Keep: Keyboards, mice & controllers'
verify INTEGRITY y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify INTEGRITY_MACHINE_KEYRING n 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify INTEL_HFI_THERMAL y 0 'CPU power & topology'
verify INTEL_IDLE y 0 'CPU power & topology'
verify INTEL_IOMMU y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify INTEL_IOMMU_SVM y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify INTEL_MEI_HDCP n 0 'Platform features this PC doesn'\''t have: This PC'
verify INTEL_MEI_PXP n 0 'Platform features this PC doesn'\''t have: This PC'
verify INTEL_TDX_GUEST n 0 'Virtual-machine guest support: Bare metal only'
verify INTEL_TDX_HOST n 0 'Platform features this PC doesn'\''t have: This PC'
verify IOMMU_DEFAULT_DMA_LAZY y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify IOMMU_DEFAULT_PASSTHROUGH n 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify IOMMU_SUPPORT y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify IOSCHED_BFQ y 0 'Disk I/O schedulers: Build all in'
verify IPC_NS y 1 'OpenRC support'
verify IPVLAN ym 0 'Keep: Virtual machines & containers'
verify IRQ_REMAP y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify ISO9660_FS ym 0 'Keep: Filesystems for external drives'
verify JOYSTICK_XPAD ym 0 'Controllers & Steam support: Keep'
verify JOYSTICK_XPAD_FF y 0 'Controllers & Steam support: Keep'
verify KASAN n 0 'Developer self-checks: Turn off'
verify KCSAN n 0 'Developer self-checks: Turn off'
verify KERNEL_BZIP2 n 0 'Kernel & module compression: zstd'
verify KERNEL_GZIP n 0 'Kernel & module compression: zstd'
verify KERNEL_LZ4 n 0 'Kernel & module compression: zstd'
verify KERNEL_LZMA n 0 'Kernel & module compression: zstd'
verify KERNEL_LZO n 0 'Kernel & module compression: zstd'
verify KERNEL_XZ n 0 'Kernel & module compression: zstd'
verify KERNEL_ZSTD y 0 'Kernel & module compression: zstd'
verify KEXEC y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify KEXEC_FILE y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify KEXEC_SIG y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify KMSAN n 0 'Developer self-checks: Turn off'
verify KVM ym 0 'Keep: Virtual machines & containers'
verify KVM_AMD n 0 'Platform features this PC doesn'\''t have: This PC'
verify KVM_GUEST n 0 'Virtual-machine guest support: Bare metal only'
verify KVM_INTEL ym 0 'Keep: Virtual machines & containers'
verify LATENCYTOP n 0 'Developer self-checks: Turn off'
verify LOCALVERSION '"-ks-genx-ks"' 1 'Kernel name'
verify LOCALVERSION_AUTO n 1 'Kernel name'
verify LOCKDEP n 1 'NVIDIA driver requirements'
verify LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY n 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify LOCK_DOWN_KERNEL_FORCE_INTEGRITY n 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify LOCK_DOWN_KERNEL_FORCE_NONE y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify LOCK_STAT n 0 'Developer self-checks: Turn off'
verify LRU_GEN y 0 'Multi-Gen LRU: On'
verify LRU_GEN_ENABLED y 0 'Multi-Gen LRU: On'
verify LSM '"landlock,lockdown,yama,integrity,bpf"' 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify LTO_CLANG_FULL n 0 'Link-Time Optimization (LTO): ThinLTO'
verify LTO_CLANG_THIN y 0 'Link-Time Optimization (LTO): ThinLTO'
verify LTO_CLANG_THIN_DIST n 0 'Link-Time Optimization (LTO): ThinLTO'
verify LTO_NONE n 0 'Link-Time Optimization (LTO): ThinLTO'
verify MACVLAN ym 0 'Keep: Virtual machines & containers'
verify MACVTAP ym 0 'Keep: Virtual machines & containers'
verify MAXSMP n 0 'CPU count & memory topology: This PC'
verify MEDIA_CAMERA_SUPPORT y 0 'Keep: Webcams & capture cards'
verify MEDIA_SUPPORT ym 0 'Keep: Webcams & capture cards'
verify MEDIA_USB_SUPPORT y 0 'Keep: Webcams & capture cards'
verify MICROCODE y 1 'Boot essentials'
verify MMC_BLOCK ym 0 'Keep: USB drives & card readers'
verify MMC_SDHCI_PCI ym 0 'Keep: USB drives & card readers'
verify MODULES y 1 'NVIDIA driver requirements'
verify MODULE_COMPRESS y 0 'Kernel & module compression: zstd'
verify MODULE_COMPRESS_ALL y 0 'Kernel & module compression: zstd'
verify MODULE_COMPRESS_GZIP n 0 'Kernel & module compression: zstd'
verify MODULE_COMPRESS_XZ n 0 'Kernel & module compression: zstd'
verify MODULE_COMPRESS_ZSTD y 0 'Kernel & module compression: zstd'
verify MODULE_FORCE_LOAD n 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify MODULE_SIG y 0 'Module signing: Sign and enforce'
verify MODULE_SIG_ALL y 0 'Module signing: Sign and enforce'
verify MODULE_SIG_FORCE y 0 'Module signing: Sign and enforce'
verify MODULE_SIG_SHA256 n 0 'Module signing: Sign and enforce'
verify MODULE_SIG_SHA384 n 0 'Module signing: Sign and enforce'
verify MODULE_SIG_SHA3_256 n 0 'Module signing: Sign and enforce'
verify MODULE_SIG_SHA3_384 n 0 'Module signing: Sign and enforce'
verify MODULE_SIG_SHA3_512 n 0 'Module signing: Sign and enforce'
verify MODULE_SIG_SHA512 y 0 'Module signing: Sign and enforce'
verify MODULE_UNLOAD y 1 'Boot essentials'
verify MQ_IOSCHED_ADIOS y 0 'Disk I/O schedulers: Build all in'
verify MQ_IOSCHED_DEADLINE y 0 'Disk I/O schedulers: Build all in'
verify MQ_IOSCHED_KYBER y 0 'Disk I/O schedulers: Build all in'
verify MZEN4 n 0 'CPU instruction set: Native (this CPU)'
verify NAMESPACES y 1 'OpenRC support'
verify NET_ACT_BPF ym 0 'Keep: VPN & virtual networking'
verify NET_CLS_BPF ym 0 'Keep: VPN & virtual networking'
verify NET_NS y 1 'OpenRC support'
verify NET_SCH_CAKE ym 0 'Keep: VPN & virtual networking'
verify NET_SCH_DEFAULT y 0 'TCP congestion control: BBRv3'
verify NET_SCH_FQ y 0 'TCP congestion control: BBRv3'
verify NFSD ym 0 'Keep: More filesystems'
verify NFS_FS ym 0 'Keep: More filesystems'
verify NLS_CODEPAGE_437 ym 1 'Boot essentials'
verify NLS_ISO8859_1 ym 1 'Boot essentials'
verify NLS_UTF8 ym 0 'Keep: Filesystems for external drives'
verify NO_HZ y 0 'Idle timer behaviour: Idle tickless'
verify NO_HZ_FULL n 0 'Idle timer behaviour: Idle tickless'
verify NO_HZ_IDLE y 0 'Idle timer behaviour: Idle tickless'
verify NR_CPUS 32 0 'CPU count & memory topology: This PC'
verify NTFS3_FS ym 1 'Mounted filesystems'
verify NTSYNC y 0 'NTSYNC for Wine & Proton: On'
verify NUMA n 0 'CPU count & memory topology: This PC'
verify OVERLAY_FS ym 0 'Keep: Virtual machines & containers'
verify PAGE_OWNER n 0 'Developer self-checks: Turn off'
verify PARAVIRT n 0 'Virtual-machine guest support: Bare metal only'
verify PID_NS y 1 'OpenRC support'
verify PREEMPT y 0 'Preemption model: Full'
verify PREEMPT_DYNAMIC y 0 'Preemption model: Full'
verify PREEMPT_LAZY n 0 'Preemption model: Full'
verify PREEMPT_RT n 0 'Preemption model: Full'
verify PROC_FS y 1 'NVIDIA driver requirements'
verify PROPELLER_CLANG n 0 'Profile-guided optimization (AutoFDO): Off'
verify PROVE_LOCKING n 1 'NVIDIA driver requirements'
verify RANDOMIZE_KSTACK_OFFSET_DEFAULT n 0 'Hardening defaults with a runtime cost: Fast'
verify RD_GZIP y 1 'Boot essentials'
verify RD_LZ4 y 1 'Boot essentials'
verify RD_XZ y 1 'Boot essentials'
verify RD_ZSTD y 1 'Boot essentials'
verify RUST n 0 'Rust kernel support: Off'
verify SATA_AHCI y 1 'Root filesystem (btrfs) & disk controllers'
verify SCHED_BORE y 0 'CPU scheduler: BORE'
verify SCHED_CLASS_EXT y 0 'sched_ext (swappable BPF schedulers): On'
verify SCHED_MC y 0 'CPU power & topology'
verify SCHED_MC_PRIO y 0 'CPU power & topology'
verify SCSI y 1 'Root filesystem (btrfs) & disk controllers'
verify SECONDARY_TRUSTED_KEYRING y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECONDARY_TRUSTED_KEYRING_SIGNED_BY_BUILTIN y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECURITY y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECURITYFS y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECURITY_APPARMOR n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_IPE n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_LANDLOCK y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECURITY_LOADPIN n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_LOCKDOWN_LSM y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECURITY_LOCKDOWN_LSM_EARLY y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SECURITY_SAFESETID n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_SELINUX n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_SMACK n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_TOMOYO n 0 'Unused security modules: Only what'\''s active'
verify SECURITY_YAMA y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SENSORS_CORETEMP ym 0 'CPU power & topology'
verify SHMEM y 1 'OpenRC support'
verify SIGNALFD y 1 'OpenRC support'
verify SLUB_DEBUG_ON n 1 'NVIDIA driver requirements'
verify SMP y 0 'CPU power & topology'
verify SND_ALOOP ym 0 'Keep: USB headsets, audio interfaces & MIDI'
verify SND_HRTIMER ym 0 'Keep: USB headsets, audio interfaces & MIDI'
verify SND_RAWMIDI ym 0 'Keep: USB headsets, audio interfaces & MIDI'
verify SND_USB_AUDIO ym 0 'Keep: USB headsets, audio interfaces & MIDI'
verify SND_VIRMIDI ym 0 'Keep: USB headsets, audio interfaces & MIDI'
verify SQUASHFS ym 0 'Keep: More filesystems'
verify SYSFB_SIMPLEFB y 1 'Boot essentials'
verify SYSFS y 1 'Boot essentials'
verify SYSTEM_TRUSTED_KEYRING y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify SYSVIPC y 1 'NVIDIA driver requirements'
verify TAP ym 0 'Keep: Virtual machines & containers'
verify TCG_CRB y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify TCG_TIS y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify TCG_TPM y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify TCG_TPM2_HMAC y 0 'Anti-cheat readiness (Easy Anti-Cheat Linux v2): Ready'
verify TCP_CONG_ADVANCED y 0 'TCP congestion control: BBRv3'
verify TCP_CONG_BBR3 y 0 'TCP congestion control: BBRv3'
verify TIMERFD y 1 'OpenRC support'
verify TLS ym 0 'Keep: VPN & virtual networking'
verify TMPFS y 1 'Boot essentials'
verify TMPFS_POSIX_ACL y 1 'Boot essentials'
verify TRANSPARENT_HUGEPAGE y 0 'Transparent Huge Pages: Always'
verify TRANSPARENT_HUGEPAGE_ALWAYS y 0 'Transparent Huge Pages: Always'
verify TRANSPARENT_HUGEPAGE_MADVISE n 0 'Transparent Huge Pages: Always'
verify TRANSPARENT_HUGEPAGE_NEVER n 0 'Transparent Huge Pages: Always'
verify TUN ym 0 'Keep: Virtual machines & containers'
verify TYPEC ym 0 'Keep: Docks, Thunderbolt & USB-C'
verify UBSAN n 0 'Developer self-checks: Turn off'
verify UDF_FS ym 0 'Keep: Filesystems for external drives'
verify UHID ym 0 'Controllers & Steam support: Keep'
verify UNIX y 1 'Boot essentials'
verify USB4 ym 0 'Keep: Docks, Thunderbolt & USB-C'
verify USB_ACM ym 0 'Keep: Optical drives & USB serial adapters'
verify USB_HID ym 0 'Keep: Keyboards, mice & controllers'
verify USB_HIDDEV y 0 'Controllers & Steam support: Keep'
verify USB_NET_AX88179_178A ym 0 'Keep: Docks, Thunderbolt & USB-C'
verify USB_NET_CDC_NCM ym 0 'Keep: Docks, Thunderbolt & USB-C'
verify USB_RTL8152 ym 0 'Keep: Docks, Thunderbolt & USB-C'
verify USB_SERIAL ym 0 'Keep: Optical drives & USB serial adapters'
verify USB_STORAGE ym 0 'Keep: USB drives & card readers'
verify USB_UAS ym 0 'Keep: USB drives & card readers'
verify USB_VIDEO_CLASS ym 0 'Keep: Webcams & capture cards'
verify USER_NS y 1 'OpenRC support'
verify UTS_NS y 1 'OpenRC support'
verify VETH ym 0 'Keep: Virtual machines & containers'
verify VFAT_FS ym 1 'Mounted filesystems'
verify VFIO ym 0 'Keep: Virtual machines & containers'
verify VFIO_PCI ym 0 'Keep: Virtual machines & containers'
verify VHOST_NET ym 0 'Keep: Virtual machines & containers'
verify VHOST_VSOCK ym 0 'Keep: Virtual machines & containers'
verify VIRTIO_MENU n 0 'Virtual-machine guest support: Bare metal only'
verify VLAN_8021Q ym 0 'Keep: VPN & virtual networking'
verify VMD y 1 'Root filesystem (btrfs) & disk controllers'
verify VMWARE_VMCI n 0 'Virtual-machine guest support: Bare metal only'
verify VXLAN ym 0 'Keep: Virtual machines & containers'
verify WIREGUARD ym 0 'Keep: VPN & virtual networking'
verify X86_AMD_PLATFORM_DEVICE n 0 'Platform features this PC doesn'\''t have: This PC'
verify X86_AMD_PSTATE n 0 'Platform features this PC doesn'\''t have: This PC'
verify X86_INTEL_PSTATE y 0 'CPU power & topology'
verify X86_NATIVE_CPU y 0 'CPU instruction set: Native (this CPU)'
verify X86_PAT y 1 'NVIDIA driver requirements'
verify X86_PKG_TEMP_THERMAL ym 0 'CPU power & topology'
verify X86_SGX n 0 'Platform features this PC doesn'\''t have: This PC'
verify X86_THERMAL_VECTOR y 0 'CPU power & topology'
verify X86_X32_ABI n 0 'Platform features this PC doesn'\''t have: This PC'
verify XEN n 0 'Virtual-machine guest support: Bare metal only'
verify XFS_FS ym 0 'Keep: More filesystems'
verify ZRAM ym 0 'Keep: Encrypted, virtual & RAM disks'
verify ZRAM_BACKEND_LZ4 y 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZRAM_BACKEND_ZSTD y 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP y 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_COMPRESSOR_DEFAULT_842 n 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_COMPRESSOR_DEFAULT_DEFLATE n 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_COMPRESSOR_DEFAULT_LZ4 n 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_COMPRESSOR_DEFAULT_LZ4HC n 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_COMPRESSOR_DEFAULT_LZO n 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_COMPRESSOR_DEFAULT_ZSTD y 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_DEFAULT_ON y 0 'Compressed memory (zswap & zram): On (zstd)'
verify ZSWAP_SHRINKER_DEFAULT_ON y 0 'Compressed memory (zswap & zram): On (zstd)'
(( ${#CRIT_MISS[@]} == 0 )) || fail "Required options could not be enabled: ${CRIT_MISS[*]}"
read -r CY CM < <(awk -F= '/^CONFIG_/ { if ($2=="y") y++; else if ($2=="m") m++ } END { print y+0, m+0 }' "$TREE/.config")
echo "::config-stats::$CY::$CM"
# olddefconfig leaves include/config/auto.conf stale; refresh it before asking
# for the release name.
"${MAKE[@]}" -s syncconfig
GOT=$("${MAKE[@]}" -s kernelrelease)
if [[ $GOT != "$REL" ]]; then
    warn "Kernel release is $GOT (expected $REL)"
    REL=$GOT
    MANIFEST="$STATE/kernels/$REL.toml"
    [[ ! -e /lib/modules/$REL ]] || fail "A kernel called $REL is already installed."
fi
cp "$TREE/.config" "$TREE/.kernelsmith/config"

# ── 6. Compile ───────────────────────────────────────────────────────────────
stage build "Compiling the kernel"
"${MAKE[@]}"
note "Kernel image: $("${MAKE[@]}" -s image_name)"

# ── 7. Install ───────────────────────────────────────────────────────────────
PREV_LINK=$(readlink /usr/src/linux 2>/dev/null || true)
write_manifest() {
    mkdir -p "$STATE/kernels"
    {
        echo "# Written by Kernelsmith — used to uninstall this kernel cleanly."
        echo "release = \"$REL\""
        echo "name = '"genx-ks"'"
        echo "profile = '"gaming"'"
        echo "created = $(date +%s)"
        echo "status = \"$1\""
        echo "tree = \"$TREE\""
        echo "source = \"$SRC\""
        echo "modules_dir = \"/lib/modules/$REL\""
        echo "previous_symlink = \"$PREV_LINK\""
        echo "autofdo_ready = false"
        echo "autofdo_profile = '""'"
        echo "signing_key = \"$SIGN_KEY\""
        echo "files = ["
        if [[ -f $TREE/.kernelsmith/boot.files ]]; then
            while read -r f; do printf '  "%s",\n' "$f"; done < "$TREE/.kernelsmith/boot.files"
        fi
        echo "]"
    } > "$MANIFEST.tmp"
    mv "$MANIFEST.tmp" "$MANIFEST"
}
boot_snapshot() {
    # Only existing dirs (many systems have no /efi), and never let find's exit
    # status abort the install under pipefail.
    local d dirs=()
    for d in /boot /efi /boot/efi; do
        if [[ -d $d ]]; then dirs+=("$d"); fi
    done
    { find "${dirs[@]}" -xdev \( -type f -o -type l \) 2>/dev/null || true; } | sort -u
}

stage modules "Installing modules"
INSTALL_STARTED=1
write_manifest installing
"${MAKE[@]}" INSTALL_MOD_STRIP=1 modules_install

# ── Module signing helpers ────────────────────────────────────────────────────
has_sig() {
    # $1: module file, possibly compressed. The trailer is the last 28 bytes.
    case $1 in
        *.zst) zstd -dcq "$1" | tail -c 28 | grep -aq 'Module signature appended' ;;
        *.xz)  xz -dc "$1" | tail -c 28 | grep -aq 'Module signature appended' ;;
        *.gz)  gzip -dc "$1" | tail -c 28 | grep -aq 'Module signature appended' ;;
        *)     tail -c 28 "$1" | grep -aq 'Module signature appended' ;;
    esac
}
sign_modules() {
    local dir=$1 ko plain signed=0 total=0
    [[ -x $TREE/scripts/sign-file ]] || { warn "$TREE/scripts/sign-file is missing; out-of-tree modules were not signed"; return 0; }
    while IFS= read -r -d '' ko; do
        total=$((total + 1))
        has_sig "$ko" && continue
        plain=$ko
        case $ko in
            *.zst) plain=${ko%.zst}; zstd -dq --rm "$ko" -o "$plain" ;;
            *.xz)  plain=${ko%.xz};  xz -d "$ko" ;;
            *.gz)  plain=${ko%.gz};  gzip -d "$ko" ;;
        esac
        "$TREE/scripts/sign-file" "$SIGN_HASH" "$SIGN_KEY" "$SIGN_KEY" "$plain"
        signed=$((signed + 1))
        case $ko in
            *.zst) zstd -q --rm -19 "$plain" ;;
            *.xz)  xz "$plain" ;;
            *.gz)  gzip -9 "$plain" ;;
        esac
    done < <(find "$dir" -type f \( -name '*.ko' -o -name '*.ko.zst' -o -name '*.ko.xz' -o -name '*.ko.gz' \) -print0)
    note "Signed $signed of $total modules in $dir (the others already carried a signature)"
}
sign_modules "/lib/modules/$REL"

stage kernel "Installing kernel & updating bootloader"
boot_snapshot > "$TREE/.kernelsmith/boot.before"
# ── Anti-cheat boot entry (same kernel, EAC command line) ──────────────────
if [[ -d /etc/grub.d ]] && command -v grub-mkconfig >/dev/null; then
    EAC_SCRIPT="/etc/grub.d/41_kernelsmith-eac-$REL"
    cat > "$EAC_SCRIPT" <<'KS_EOF'
#!/bin/sh
# Written by Kernelsmith: boots __REL__ with the options Easy Anti-Cheat Linux v2
# checks on the measured command line. The normal entry stays unlocked.
set -e
prefix="/usr"
exec_prefix="/usr"
datarootdir="/usr/share"
. "${datarootdir}/grub/grub-mkconfig_lib"
REL=__REL__
EAC_REQ="lockdown=integrity lsm=landlock,lockdown,yama,integrity,bpf iommu.passthrough=0 module.sig_enforce=1 sysctl.kernel.kexec_load_disabled=1 intel_iommu=on"
kernel=/boot/vmlinuz-$REL
[ -e "$kernel" ] || exit 0
initrd=
for i in /boot/initramfs-$REL.img /boot/initrd-$REL /boot/initrd.img-$REL; do
    [ -e "$i" ] && initrd=$i && break
done
case x"$GRUB_DEVICE_UUID" in
    x) LINUX_ROOT_DEVICE=${GRUB_DEVICE} ;;
    *) LINUX_ROOT_DEVICE=UUID=${GRUB_DEVICE_UUID} ;;
esac
case x"$GRUB_FS" in
    xbtrfs)
        rootsubvol="`make_system_path_relative_to_its_root /`"
        rootsubvol="${rootsubvol#/}"
        [ "x${rootsubvol}" != x ] && GRUB_CMDLINE_LINUX="rootflags=subvol=${rootsubvol} ${GRUB_CMDLINE_LINUX}"
        ;;
esac
early=
for i in ${GRUB_EARLY_INITRD_LINUX_STOCK} ${GRUB_EARLY_INITRD_LINUX_CUSTOM}; do
    [ -e "/boot/${i}" ] && early="$early $(make_system_path_relative_to_its_root "/boot/${i}")"
done
gettext_printf "Found anti-cheat entry kernel: %s\n" "$kernel" >&2
cat <<ENTRY
menuentry 'Gentoo (EAC) $REL' --class gentoo --class gnu-linux --class gnu --class os \$menuentry_id_option 'kernelsmith-eac-$REL' {
	load_video
	insmod gzio
	insmod part_gpt
	insmod btrfs
ENTRY
[ x"$GRUB_DEVICE_BOOT" != x ] && prepare_grub_to_access_device "${GRUB_DEVICE_BOOT}" | grub_add_tab
cat <<ENTRY
	echo 'Loading Linux $REL (anti-cheat: lockdown=integrity, signed modules only, IOMMU on)'
	linux $(make_system_path_relative_to_its_root "$kernel") root=${LINUX_ROOT_DEVICE} ro ${GRUB_CMDLINE_LINUX} ${GRUB_CMDLINE_LINUX_DEFAULT} ${EAC_REQ}
ENTRY
if [ -n "$initrd" ]; then
    cat <<ENTRY
	echo 'Loading initial ramdisk ...'
	initrd${early} $(make_system_path_relative_to_its_root "$initrd")
ENTRY
fi
echo '}'
KS_EOF
    sed -i "s|__REL__|$REL|g" "$EAC_SCRIPT"
    chmod 0755 "$EAC_SCRIPT"
    echo "$EAC_SCRIPT" >> "$TREE/.kernelsmith/extra.files"
    note "Added the anti-cheat GRUB entry script $EAC_SCRIPT"
else
    warn "No GRUB: add a boot entry for $REL yourself with these options: lockdown=integrity lsm=landlock,lockdown,yama,integrity,bpf iommu.passthrough=0 module.sig_enforce=1 sysctl.kernel.kexec_load_disabled=1 intel_iommu=on"
fi
# Call Gentoo's installkernel directly (runs dracut/ugrd and updates GRUB or
# systemd-boot per its USE flags); `make install` is only the fallback.
if command -v installkernel >/dev/null; then
    installkernel "$REL" "$TREE/$("${MAKE[@]}" -s image_name)" "$TREE/System.map" /boot
else
    "${MAKE[@]}" install
fi
boot_snapshot > "$TREE/.kernelsmith/boot.after"
# Only files that are new AND carry this kernel's name belong to it.
comm -13 "$TREE/.kernelsmith/boot.before" "$TREE/.kernelsmith/boot.after" \
    | grep -F -- "$REL" > "$TREE/.kernelsmith/boot.files" || true
if [[ -f $TREE/.kernelsmith/extra.files ]]; then cat "$TREE/.kernelsmith/extra.files" >> "$TREE/.kernelsmith/boot.files"; fi
note "Installed: $(tr '\n' ' ' < "$TREE/.kernelsmith/boot.files")"
write_manifest installed
note "Pointing /usr/src/linux at the new tree"
if command -v eselect >/dev/null; then
    eselect kernel set "$(basename "$TREE")"
else
    ln -sfn "$(basename "$TREE")" /usr/src/linux
fi

stage modrebuild "Rebuilding driver modules"
# Portage removes a package's old files when it reinstalls it, which would take
# the NVIDIA (etc.) modules away from your *other* kernels. Save and restore them.
PRESERVE=$(mktemp -d /var/tmp/kernelsmith-preserve.XXXXXX)
for d in /var/db/pkg/*/*; do
    grep -qwE 'linux-mod(-r1)?' "$d/INHERITED" 2>/dev/null || continue
    awk '$1=="obj" && $2 ~ "^(/usr)?/lib/modules/" {print $2}' "$d/CONTENTS" 2>/dev/null || true
done | while read -r f; do
    if [[ -e $f ]]; then cp -a --parents "$f" "$PRESERVE/"; fi
done
# ── Keep Portage signing rebuilt drivers with the Kernelsmith key ──────────
if [[ -d /etc/portage && ( -d /etc/portage/package.use || ! -e /etc/portage/package.use ) ]]; then
    mkdir -p /etc/portage/env /etc/portage/package.env /etc/portage/package.use "$STATE"
    cat > /etc/portage/env/kernelsmith-modules-sign.conf <<KS_EOF
# Written by Kernelsmith: sign out-of-tree modules with the Kernelsmith key (linux-mod-r1).
MODULES_SIGN_KEY="$SIGN_KEY"
MODULES_SIGN_CERT="${SIGN_KEY%.pem}.crt"
MODULES_SIGN_HASH="$SIGN_HASH"
KS_EOF
    printf '%s\n' 'net-misc/r8125 kernelsmith-modules-sign.conf' 'x11-drivers/nvidia-drivers kernelsmith-modules-sign.conf' 'games-util/xpadneo kernelsmith-modules-sign.conf' > /etc/portage/package.env/kernelsmith-modules-sign
    printf '%s\n' 'net-misc/r8125 modules-sign' 'x11-drivers/nvidia-drivers modules-sign' 'games-util/xpadneo modules-sign' > /etc/portage/package.use/kernelsmith-modules-sign
    printf '%s\n' /etc/portage/env/kernelsmith-modules-sign.conf /etc/portage/package.env/kernelsmith-modules-sign /etc/portage/package.use/kernelsmith-modules-sign > "$STATE/signing.list"
    note "Portage will sign 3 driver package(s) with $SIGN_KEY on every rebuild"
else
    warn "/etc/portage/package.use is a file; not adding USE=modules-sign for your driver packages"
fi
MODREBUILD_OK=1
note "Running: emerge @module-rebuild for the new kernel"
if ! KERNEL_DIR="$TREE" emerge --ask=n --oneshot --quiet-build=y --color=n --nospinner @module-rebuild; then
    MODREBUILD_OK=0
    warn "Some driver modules failed to rebuild. The kernel is installed; fix the error above and run: KERNEL_DIR=$TREE emerge @module-rebuild"
fi
sign_modules "/lib/modules/$REL"
if [[ -n $PRESERVE && -d $PRESERVE ]]; then
    restored=0
    while read -r f; do
        dest="/${f#./}"
        if [[ ! -e $dest ]]; then
            mkdir -p "$(dirname "$dest")"
            cp -a "$PRESERVE/$f" "$dest"
            restored=$((restored + 1))
        fi
    done < <(cd "$PRESERVE" && find . -type f)
    if (( restored )); then
        for k in $(cd "$PRESERVE" && find . -type f | sed -nE 's#^\./(usr/)?lib/modules/([^/]+)/.*#\2#p' | sort -u); do
            if [[ $k != "$REL" ]]; then depmod -a "$k" || true; fi
        done
        note "Kept $restored driver file(s) working for your other kernels"
    fi
    rm -rf "$PRESERVE"
fi
echo "::modrebuild::$MODREBUILD_OK"

# ── Free disk space (external modules can still be built against this tree) ──
stage clean "Freeing disk space"
"${MAKE[@]}" -s clean

sync
echo "::done::$REL"
