#!/bin/bash
# run-eac-test.sh - boot a built GenX kernel in QEMU/KVM with the EAC command
# line and print what Easy Anti-Cheat v2 would see.
#
# Usage: run-eac-test.sh <bzImage> <modules-dir (…/lib/modules/<kver>)> <kernel-src-with-scripts> [workdir]
# Needs: qemu-system-x86_64 (+/dev/kvm), dracut, mkfs.ext4, zstd, gcc, expect-free (plain timeout).
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
image=$(realpath "${1:?bzImage}"); mods=$(realpath "${2:?modules dir}"); src=$(realpath "${3:?kernel src}")
work=${4:-$(mktemp -d "${TMPDIR:-/tmp}/genx-eac-test.XXXXXX")}; mkdir -p "${work}"; work=$(realpath "${work}")
kver=$(basename "${mods}")
EAC_REQ=${EAC_REQ-"lockdown=integrity lsm=landlock,lockdown,yama,integrity,bpf iommu.passthrough=0 intel_iommu=on module.sig_enforce=1 sysctl.kernel.kexec_load_disabled=1"}

echo ">>> root image"
rm -rf "${work}/root" "${work}/fs.img"; mkdir -p "${work}"/root/{bin,dev,etc,lib,proc,root,sbin,sys,test}
mkdir -p "${work}/root/sys/kernel/security"
touch "${work}/root/lib/ld-fake.so"; cp /etc/os-release "${work}/root/etc/os-release"
gcc -Os -static -o "${work}/root/sbin/init" "${here}/init.c"
# a small dependency-free module: signed copy as built, and one with the signature stripped
mapfile -t cands < <(find "${mods}/kernel/lib" "${mods}/kernel/fs/exfat" "${mods}/kernel/crypto" -name '*.ko*' 2>/dev/null | sort)
ko=
for f in "${cands[@]:0:60}"; do
	t=${work}/probe.ko
	case ${f} in *.zst) zstd -dqf "${f}" -o "${t}";; *.xz) xz -dkc "${f}" >"${t}";; *) cp "${f}" "${t}";; esac
	if [[ -z $(modinfo -F depends "${t}") ]]; then ko=${f}; break; fi
done
[[ -n ${ko} ]] || { echo "no dependency-free module found"; exit 1; }
echo "    test module: ${ko}"
case ${ko} in *.zst) zstd -dqf "${ko}" -o "${work}/root/test/signed.ko";; *.xz) xz -dkc "${ko}" >"${work}/root/test/signed.ko";; *) cp "${ko}" "${work}/root/test/signed.ko";; esac
modinfo "${work}/root/test/signed.ko" | grep -E '^(name|signer|sig_key)' | sed 's/^/    /'
# strip the appended signature (struct module_signature + magic trailer)
python3 -I - "${work}/root/test/signed.ko" "${work}/root/test/unsigned.ko" <<'PYEOF'
import struct, sys
data = open(sys.argv[1], 'rb').read()
magic = b"~Module signature appended~\n"
assert data.endswith(magic), "module is not signed"
body = data[:-len(magic)]
algo, hsh, id_type, signer_len, key_id_len, _p0, _p1, _p2, sig_len = struct.unpack(">8B I", body[-12:])
body = body[:-12 - sig_len - signer_len - key_id_len]
open(sys.argv[2], 'wb').write(body)
print(f"    stripped {len(data) - len(body)} signature bytes (id_type={id_type}, sig_len={sig_len})")
PYEOF
truncate -s 8M "${work}/fs.img"; mkfs.ext4 -q -d "${work}/root" -L groot "${work}/fs.img"

echo ">>> initramfs (dracut, no-hostonly, modules from ${mods})"
dracut --force --quiet --no-hostonly --kmoddir "${mods}" --kver "${kver}" \
	--force-add qemu --omit "crypt dm dmraid lvm mdraid multipath nbd network network-manager btrfs cifs nfs zfs plymouth rngd i18n dracut-systemd systemd systemd-initrd" \
	--nostrip --no-early-microcode --compress zstd "${work}/initrd.img" "${kver}" 2>&1 | grep -v '^dracut: ' | sed 's/^/    /' || true
ls -la "${work}/initrd.img"

echo ">>> qemu (q35, KVM, host CPU, emulated VT-d) with: ${EAC_REQ}"
kvm=; [[ -w /dev/kvm ]] && kvm="-enable-kvm -cpu host" || kvm="-cpu max"
timeout 300 qemu-system-x86_64 ${kvm} -machine q35,kernel-irqchip=split -device intel-iommu,intremap=on \
	-m 1024 -smp 4 -nographic -no-reboot -serial mon:stdio \
	-drive file="${work}/fs.img",if=none,id=d0,format=raw -device ide-hd,drive=d0,bus=ide.0 \
	-kernel "${image}" -initrd "${work}/initrd.img" \
	-append "root=LABEL=groot rootfstype=ext4 console=ttyS0,115200n8 loglevel=4 ${EAC_REQ}" 2>&1 | tee "${work}/console.log" | grep -E 'EAC-TEST|Kernel panic|Lockdown|lockdown|iommu: Default|DMAR: IOMMU enabled|Loaded X.509|module verification|Module verification' || true
echo ">>> full console log: ${work}/console.log"
