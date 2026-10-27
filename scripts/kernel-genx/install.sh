#!/bin/bash
# install.sh - put the GenX kernel configuration into place (run as root).
#
#   sudo ./install.sh            # install everything, then prints next steps
#   sudo ./install.sh --check    # only show what would change
#
# Installs:
#   /etc/portage/savedconfig/sys-kernel/cachyos-kernel   (config-GenX-<ver>, version-less
#                                                         so it also seeds future bumps)
#   /etc/kernel/config.d/*.config                        (fragments, merged last by
#                                                         kernel-build.eclass)
#   /etc/portage/package.use/cachyos-kernel              (savedconfig modules-sign -propeller)
#   /etc/portage/package.use/nvidia  (+= dist-kernel modules-sign)
#   /etc/portage/make.conf           (+= MODULES_SIGN_KEY/CERT/HASH)
#   /etc/portage/kernel-signing/genx-modules-signing.{pem,crt}  root:portage 0640/0644
#   /etc/grub.d/41_genx_eac                              ("Gentoo (EAC)" boot entry)
# It never runs emerge, dracut or grub-mkconfig itself.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
check=0; [[ ${1:-} == --check ]] && check=1
(( EUID == 0 )) || (( check )) || { echo "run as root (sudo $0)"; exit 1; }

keysrc=${GENX_KEY_DIR:-${here}/keys}
cfg=$(ls "${here}"/config-GenX-* 2>/dev/null | grep -v '\.report$' | sort -V | tail -n1)
[[ -n ${cfg} ]] || { echo "no config-GenX-<ver> next to this script"; exit 1; }

say() { printf '  %-8s %s\n' "$1" "$2"; }
put() { # put <mode> <owner> <src> <dst>
	local mode=$1 owner=$2 src=$3 dst=$4
	if [[ -e ${dst} ]] && cmp -s "${src}" "${dst}"; then say same "${dst}"; return; fi
	[[ -e ${dst} ]] && say update "${dst}" || say install "${dst}"
	(( check )) && return
	install -D -m "${mode}" -o "${owner%:*}" -g "${owner#*:}" "${src}" "${dst}"
}
append_once() { # append_once <marker> <file> <snippet-file>
	local marker=$1 file=$2 snip=$3
	if grep -qF "${marker}" "${file}" 2>/dev/null; then say same "${file} (${marker})"; return; fi
	say append "${file} (${marker})"
	(( check )) && return
	{ echo; grep -v '^# Append to\|^# Add to' "${snip}"; } >>"${file}"
}

echo "GenX kernel configuration -> $(hostname)"
echo "config: ${cfg}"

put 0644 root:root "${cfg}" /etc/portage/savedconfig/sys-kernel/cachyos-kernel
for f in "${here}"/fragments/*.config; do
	put 0644 root:root "${f}" "/etc/kernel/config.d/$(basename "${f}")"
done
put 0644 root:root "${here}/portage/package.use--cachyos-kernel" /etc/portage/package.use/cachyos-kernel
put 0755 root:root "${here}/grub.d/41_genx_eac" /etc/grub.d/41_genx_eac

if [[ -f ${keysrc}/genx-modules-signing.pem ]]; then
	put 0640 root:portage "${keysrc}/genx-modules-signing.pem" /etc/portage/kernel-signing/genx-modules-signing.pem
	put 0644 root:root    "${keysrc}/genx-modules-signing.crt" /etc/portage/kernel-signing/genx-modules-signing.crt
else
	say skip "signing key: ${keysrc}/genx-modules-signing.pem not found (set GENX_KEY_DIR)"
fi

append_once 'MODULES_SIGN_KEY=' /etc/portage/make.conf "${here}/portage/make.conf--snippet"
append_once 'x11-drivers/nvidia-drivers dist-kernel modules-sign' /etc/portage/package.use/nvidia "${here}/portage/package.use--nvidia"

(( check )) && { echo "(check mode, nothing written)"; exit 0; }
cat <<'NEXT'

Next steps (as root):
  emerge -av1 =sys-kernel/cachyos-kernel-7.3.0-r3 x11-drivers/nvidia-drivers
      kernel first, then nvidia-drivers signs its modules with the GenX key,
      installkernel runs dracut + grub-mkconfig (the EAC entry appears there).
  reboot, pick the normal "Gentoo GNU/Linux" entry first and check:
      uname -r; modinfo -F signer nvidia; cat /sys/kernel/security/lockdown
  then try "Gentoo (EAC) 7.3.0-cachyos-dist" and check:
      cat /sys/kernel/security/lockdown        -> none [integrity] confidentiality
      cat /sys/kernel/security/lsm             -> ...,lockdown,...,bpf
      cat /proc/sys/kernel/kexec_load_disabled -> 1
      cat /sys/module/module/parameters/sig_enforce -> Y
      cat /sys/kernel/iommu_groups/0/type      -> DMA-FQ (not identity)
NEXT
