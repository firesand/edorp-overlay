#!/bin/bash
# genconfig.sh - build the GenX hardware-specific kernel config from a
# prepared sys-kernel/cachyos-kernel source tree.
#
# Usage: genconfig.sh <prepared-kernel-source-dir> <output-config> [lsmod-file]
#
# <prepared-kernel-source-dir> is ${S} after
#   ebuild /var/db/repos/CachyOS-kernels/sys-kernel/cachyos-kernel/cachyos-kernel-<ver>.ebuild clean prepare
# i.e. the CachyOS tree with the ebuild's USE-flag config already applied.
# The script never builds in that tree: all kconfig work happens in a
# temporary O= directory, so the tree stays clean for the ebuild.
#
# Steps:
#  1. olddefconfig on the ebuild's config
#  2. make localmodconfig against lsmod-GenX.txt, keeping whole hotplug
#     subsystems through LMC_KEEP
#  3. merge fragments/*.config (built-in trims, kept modules, EAC, perf)
#  4. olddefconfig, sanity checks, report
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src=${1:?prepared kernel source dir}
out=${2:?output config path}
lsmod_file=${3:-${here}/lsmod-GenX.txt}
src=$(realpath "${src}")
lsmod_file=$(realpath "${lsmod_file}")
out=$(realpath -m "${out}")

[[ -f ${src}/.config ]] || { echo "no .config in ${src} (run ebuild ... prepare first)" >&2; exit 1; }
[[ -f ${lsmod_file} ]] || { echo "lsmod file ${lsmod_file} not found" >&2; exit 1; }

# Subsystems whose modules are kept wholesale even if nothing is loaded now:
# anything hot-pluggable or loaded on demand by userspace.
LMC_KEEP="drivers/usb:drivers/hid:drivers/input:drivers/bluetooth"
LMC_KEEP+=":drivers/net/usb:drivers/net/wireguard:drivers/net/ppp:drivers/net/phy:drivers/net/mdio"
LMC_KEEP+=":drivers/hwmon:drivers/leds:drivers/md:drivers/block:drivers/vhost"
LMC_KEEP+=":drivers/media/usb:drivers/media/v4l2-core:drivers/media/common:drivers/media/mc"
LMC_KEEP+=":drivers/mmc:drivers/misc/cardreader:drivers/char/tpm"
LMC_KEEP+=":drivers/platform/x86/intel:drivers/thermal/intel"
LMC_KEEP+=":sound/usb"
LMC_KEEP+=":net/netfilter:net/ipv4:net/ipv6:net/bridge:net/sched:net/bluetooth"
LMC_KEEP+=":net/wireless:net/mac80211:net/8021q:net/tls:net/vmw_vsock"
LMC_KEEP+=":fs:crypto:lib:arch/x86/crypto"

make_args=()
if grep -q '^CONFIG_CC_IS_CLANG=y' "${src}/.config"; then
	make_args+=(LLVM=1 LLVM_IAS=1)
fi

O=$(mktemp -d "${TMPDIR:-/tmp}/genx-kconfig.XXXXXX")
trap 'rm -rf "${O}"' EXIT
cp "${src}/.config" "${O}/.config"
cp "${src}/.config" "${O}/config.base"

# kbuild refuses O= builds while the source tree holds a .config; park it.
mv "${src}/.config" "${src}/.config.genx-parked"
restore() { [[ -f ${src}/.config.genx-parked ]] && mv "${src}/.config.genx-parked" "${src}/.config"; rm -rf "${O}"; }
trap restore EXIT

mk() { make -C "${src}" O="${O}" "${make_args[@]}" "$@"; }

echo ">>> olddefconfig on the ebuild config"
mk olddefconfig >/dev/null
cp "${O}/.config" "${O}/config.olddef"

echo ">>> localmodconfig (LSMOD=${lsmod_file})"
# "yes" dies of SIGPIPE when conf stops reading, so judge the make status only.
set +o pipefail
yes '' | mk LSMOD="${lsmod_file}" LMC_KEEP="${LMC_KEEP}" localmodconfig >"${O}/localmodconfig.log" 2>&1
rc=${PIPESTATUS[1]}
set -o pipefail
(( rc == 0 )) || { cat "${O}/localmodconfig.log" >&2; exit 1; }
cp "${O}/.config" "${O}/config.localmod"

echo ">>> merging fragments"
frags=( "${here}"/fragments/*.config )
"${src}/scripts/kconfig/merge_config.sh" -m -r -O "${O}" "${O}/.config" "${frags[@]}" >"${O}/merge.log" 2>&1 || {
	cat "${O}/merge.log" >&2; exit 1; }
grep -E 'Previous value|Actual value|Requested value' "${O}/merge.log" >&2 || true

echo ">>> olddefconfig after merge"
mk olddefconfig >/dev/null

# Do not leak the per-build signing key path: kernel-build.eclass injects the
# real MODULES_SIGN_KEY path after the saved config is merged.
sed -i 's|^CONFIG_MODULE_SIG_KEY=.*|CONFIG_MODULE_SIG_KEY="certs/signing_key.pem"|' "${O}/.config"

echo ">>> sanity checks"
must_y=( X86_NATIVE_CPU SCHED_MC_PRIO SCHED_CLUSTER INTEL_HFI_THERMAL X86_INTEL_PSTATE
	MODULE_SIG MODULE_SIG_ALL MODULE_SIG_FORCE SECONDARY_TRUSTED_KEYRING_SIGNED_BY_BUILTIN
	SECURITY_LOCKDOWN_LSM SECURITY_LOCKDOWN_LSM_EARLY BPF_LSM SECURITY_LANDLOCK SECURITY_YAMA
	INTEL_IOMMU IRQ_REMAP TCG_TPM TCG_TIS TCG_CRB EFI_STUB
	NVME_CORE BLK_DEV_NVME VMD BTRFS_FS SATA_AHCI USB_XHCI_HCD USB_HID
	DEBUG_INFO_BTF SCHED_CLASS_EXT CPU_SUP_INTEL
	MEMORY_HOTPLUG ZONE_DEVICE DEVICE_PRIVATE HMM_MIRROR DRM_FBDEV_EMULATION DRM_KMS_HELPER )
must_n=( NUMA MAXSMP HYPERVISOR_GUEST PARAVIRT
	X86_5LEVEL X86_SGX INTEL_TDX_HOST AMD_MEM_ENCRYPT AMD_IOMMU EFI_MIXED
	SECURITY_SELINUX SECURITY_APPARMOR SECURITY_SMACK SECURITY_TOMOYO SECURITY_IPE SECURITY_LOADPIN
	INTEGRITY_MACHINE_KEYRING LOCK_DOWN_KERNEL_FORCE_INTEGRITY INTEL_IOMMU_DEFAULT_ON IOMMU_DEFAULT_PASSTHROUGH
	DRM_I915 DRM_XE DRM_AMDGPU DRM_RADEON CEPH_FS OCFS2_FS
	INIT_ON_ALLOC_DEFAULT_ON RANDOMIZE_KSTACK_OFFSET_DEFAULT )
must_m=( IGC IWLWIFI BT_HCIBTUSB SND_HDA_INTEL SND_USB_AUDIO KVM_INTEL TUN VETH BRIDGE NTSYNC
	USB_UAS INPUT_JOYDEV JOYSTICK_XPAD HID_PLAYSTATION USB_VIDEO_CLASS USB4 NTFS3_FS EXFAT_FS
	OVERLAY_FS NFSD DM_CRYPT BLK_DEV_LOOP ZRAM WIREGUARD BRIDGE_NETFILTER INPUT_UINPUT ATA_PIIX
	DRM_NOUVEAU DRM_TTM DRM_TTM_HELPER DRM_DISPLAY_HELPER ACPI_VIDEO VFAT_FS SND_HDA_CODEC_HDMI
	I2C_I801 I2C_CHARDEV SENSORS_NCT6775 SENSORS_CORETEMP INTEL_RAPL ITCO_WDT INTEL_MEI_ME ASUS_WMI
	TYPEC_UCSI SND_SOC_SOF_INTEL_TGL HID_LOGITECH_HIDPP USB_SERIAL_FTDI_SIO USB_RTL8152 BLK_DEV_SR )
fail=0
for o in "${must_y[@]}"; do grep -q "^CONFIG_${o}=y" "${O}/.config" || { echo "MISSING =y: ${o}" >&2; fail=1; }; done
for o in "${must_m[@]}"; do grep -qE "^CONFIG_${o}=[my]" "${O}/.config" || { echo "MISSING =m: ${o}" >&2; fail=1; }; done
for o in "${must_n[@]}"; do grep -q "^CONFIG_${o}=y" "${O}/.config" && { echo "STILL SET: ${o}" >&2; fail=1; }; done
grep -q '^CONFIG_NR_CPUS=32$' "${O}/.config" || { echo "NR_CPUS != 32" >&2; fail=1; }
grep -q '^CONFIG_LSM="landlock,lockdown,yama,integrity,bpf"$' "${O}/.config" || { echo "CONFIG_LSM wrong" >&2; fail=1; }
(( fail == 0 )) || exit 1

mkdir -p "$(dirname "${out}")"
cp "${O}/.config" "${out}"
{
	echo "# genconfig.sh report $(date -Is)"
	echo "# source: ${src}"
	echo "# lsmod:  ${lsmod_file} ($(grep -c . "${lsmod_file}") lines)"
	for f in config.base config.olddef config.localmod .config; do
		printf '%-16s y=%-5s m=%-5s\n' "${f}" "$(grep -c '=y$' "${O}/${f}")" "$(grep -c '=m$' "${O}/${f}")"
	done
	echo
	echo "## options changed between the ebuild config and the GenX config"
	diff <(grep -E '^(CONFIG_|# CONFIG_)' "${O}/config.olddef" | sort) <(grep -E '^(CONFIG_|# CONFIG_)' "${O}/.config" | sort) | grep '^[<>]' | sort -k2 || true
} >"${out}.report"
echo ">>> wrote ${out} and ${out}.report"
