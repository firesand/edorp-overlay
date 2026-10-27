# GenX kernel: CachyOS dist-kernel tailored to this machine, EAC v2 ready

Machine: ASUS ROG MAXIMUS Z790 HERO, i9-14900K, RTX 4090 (nvidia kernel-open),
NVMe behind Intel VMD, I226-V, AX211, USB4. Gentoo, GRUB + dracut, OpenRGB /
intel-undervolt / Docker / Tailscale / KVM in daily use.

The kernel package stays `sys-kernel/cachyos-kernel` from the CachyOS-kernels
overlay (a Gentoo *distribution kernel*, `kernel-build.eclass`). What this
directory adds is the Gentoo-native customisation layer:

* a **hardware-trimmed savedconfig** produced by `make localmodconfig` from a
  snapshot of the loaded modules, with whole hot-plug subsystems kept;
* **config fragments** for `/etc/kernel/config.d/` holding every deliberate
  built-in decision (CPU topology, no guest/paravirt code, no foreign GPUs,
  EAC requirements, perf defaults). They are merged last by the eclass, so
  they survive version bumps even without the savedconfig;
* **signed modules** with a persistent key, for the kernel and for
  `x11-drivers/nvidia-drivers[dist-kernel,modules-sign]`;
* a **GRUB entry "Gentoo (EAC)"** that boots the same kernel with the command
  line Easy Anti-Cheat Linux v2 checks, leaving the normal entry untouched.

## Status against Epic's EAC Linux v2 requirements

| Epic requirement | GenX kernel | Note |
|---|---|---|
| Kernel + modules signed with a **well-known key** | **not satisfiable with a self-built kernel** | Epic's list (Oct 2026): Canonical, Fedora, Universal Blue, Debian, openSUSE, SUSE, Rocky, Alma, Microsoft UEFI CA. Gentoo and CachyOS are not on it. A key you generate yourself will never pass this check, whatever the config. |
| TPM 2.0 present and enabled | OK | Intel PTT, `/dev/tpm0`, `TCG_TIS`/`TCG_CRB` built in |
| Secure Boot enabled, only well-known keys | **off on this machine** (SetupMode 0, SecureBoot 0) | Separate project: sbctl keys, sign GRUB, `USE=secureboot` on the kernel. Still fails the well-known-key rule. |
| Measured boot | GRUB measures when the `tpm` module is loaded | `GRUB_PRELOAD_MODULES="tpm"` belongs to the Secure Boot project |
| IOMMU on, passthrough off | OK via `intel_iommu=on iommu.passthrough=0` on the EAC entry | VT-d is on in firmware (28 IOMMU groups); today it runs in identity mode |
| Lockdown integrity at boot | OK via `lockdown=integrity` on the EAC entry | not forced in Kconfig, see below |
| kexec disabled at boot | OK via `sysctl.kernel.kexec_load_disabled=1` | kexec compiled in, as CachyOS does |
| BPF LSM active | OK | `CONFIG_BPF_LSM=y`, `CONFIG_LSM="landlock,lockdown,yama,integrity,bpf"`, repeated on the command line |
| Signed modules enforced | OK | `MODULE_SIG_FORCE=y`, no MOK keyring, secondary keyring only accepts keys signed by the built-in one |

So: this kernel is *configured* exactly like the CachyOS EAC kernel and will
pass every check Epic's service can do locally, except the one that matters
for Fortnite today, the signing key. That part only moves when a distribution
whose kernel you can boot gets its key on Epic's list (CachyOS is working on a
`linux-cachyos-eac` signed with their key, see the `eac` branch of
CachyOS/linux-cachyos and CachyOS/wiki PR 650).

## Differences from the CachyOS `linux-cachyos-eac` PKGBUILD

| | CachyOS EAC kernel | GenX |
|---|---|---|
| `LOCK_DOWN_KERNEL_FORCE_INTEGRITY` | y (dedicated kernel, always locked) | n, `lockdown=integrity` on the EAC entry only, so `intel-undervolt`, MSR tools and hibernation keep working on the normal entry |
| `INTEL_IOMMU_DEFAULT_ON` | y | n, `intel_iommu=on` on the EAC entry only (no DMA-translation overhead on the normal entry) |
| `HIBERNATION` | n | y (lockdown blocks it at runtime on the EAC entry anyway) |
| Scheduler | EEVDF | BORE (as before on this machine) |
| `MODULE_SIG_FORCE`, no `INTEGRITY_MACHINE_KEYRING`, `SECONDARY_TRUSTED_KEYRING_SIGNED_BY_BUILTIN`, `SECURITY_LOCKDOWN_LSM_EARLY`, `BPF_LSM` | y | y (identical) |
| SBAT section | yes (shim revocation) | no (no shim on this machine) |
| EAC command line | identical | identical |

## What changed against the stock CachyOS config

Numbers for 7.3.0-r3 (`config-GenX-7.3.0.report` has the full diff):

| | stock CachyOS (after USE flags) | GenX |
|---|---|---|
| built-in (`=y`) | 3261 | 2598 |
| modules (`=m`) | 6374 | 2262 |

Built-in decisions (see `fragments/10-genx-hardware.config`):

* `NR_CPUS=32`, no `MAXSMP` (cpumasks on the stack instead of heap);
* `NUMA=n` (one node; also drops NUMA balancing);
* `HYPERVISOR_GUEST=n`: no paravirt ops, Xen, Hyper-V, KVM-guest or TDX-guest
  code. KVM **host** support stays;
* `X86_5LEVEL=n` (no LA57 on Raptor Lake), no SGX, no TDX host, no AMD memory
  encryption / AMD IOMMU, no 32-bit EFI mixed mode, no x32 ABI;
* SELinux, Smack, TOMOYO, AppArmor, IPE, LoadPin, SafeSetID removed (never in
  `CONFIG_LSM`); Yama, Landlock, lockdown, BPF kept;
* NVMe core/driver, VMD, btrfs, AHCI, xHCI, USB HID built in: the root
  filesystem is reachable without an initramfs;
* amdgpu, radeon, i915, xe removed. **nouveau stays as a module**: nvidia_drm
  links against `drm_ttm_helper` and `drm_display_helper`, which only exist
  while an in-tree driver selects them. nvidia-drivers blacklists nouveau in
  `/etc/modprobe.d/nvidia.conf`, as today. `MEMORY_HOTPLUG` also stays, because
  `ZONE_DEVICE`/`DEVICE_PRIVATE`/`HMM_MIRROR` (nvidia-uvm, CUDA HMM) depend on it;
* `ACPI_DEBUG`, `IKHEADERS` off;
* `fragments/40-genx-perf.config`: `init_on_alloc`, kernel stack offset
  randomisation and hardened usercopy default to off (all re-enableable on
  the command line). Delete that file to keep the CachyOS defaults.

Module trimming (`genconfig.sh`): everything that was loaded in
`lsmod-GenX.txt` stays; these subsystems are kept wholesale regardless:
USB, HID, input, Bluetooth, USB network, WireGuard, PPP, PHY/MDIO, hwmon,
LEDs, dm/md, block (loop, zram, nbd), vhost, USB media (webcams, capture
cards), MMC/card readers, TPM, Intel platform and thermal drivers, USB audio,
netfilter, IPv4/IPv6, bridge, tc/sched, Bluetooth, wireless core, VLAN, TLS,
vsock, **all filesystems** (minus the cluster/legacy ones in
`25-genx-drop-exotic-fs.config`), all crypto and lib.
`20-genx-keep-modules.config` adds a few explicit ones (sr/sg, macvlan,
ipvlan, vxlan, tap, ifb, snd-aloop, ie31200 EDAC, uinput).

**Dropped and needing a rebuild if the hardware changes:** other GPU drivers,
non-Intel Ethernet (e1000e, r8169, ...), USB/PCIe Wi-Fi chipsets other than
iwlwifi, VFIO, virtio guest drivers, IIO sensors, InfiniBand, staging. Add a
`/etc/kernel/config.d/50-local.config` with the option set to `m`, or add the
module to `lsmod-GenX.txt` and regenerate.

Unchanged from your previous build: BORE, clang 22 ThinLTO, `-O3`,
`-march=native` (raptorlake), AutoFDO with `/home/edo/autofdo-profiling/kernel.afdo`,
BBR3 + FQ, 1000 Hz, NO_HZ_IDLE, full preemption, performance governor default,
`SCHED_CLASS_EXT` with BTF for scx. `propeller` is turned off: without a
Propeller profile it only adds basic-block address-map metadata.

## Files

| file | purpose |
|---|---|
| `config-GenX-7.3.0` | full generated config, installed as `/etc/portage/savedconfig/sys-kernel/cachyos-kernel` |
| `config-GenX-7.3.0.report` | counts and the complete option diff against the stock config |
| `fragments/*.config` | the deliberate decisions, also installed to `/etc/kernel/config.d/` |
| `genconfig.sh` | regenerates the config from a prepared tree (see below) |
| `lsmod-GenX.txt` | module snapshot the trim is based on (2026-10-27) |
| `grub.d/41_genx_eac` | GRUB script producing the "Gentoo (EAC)" entry |
| `portage/*` | package.use / make.conf snippets |
| `keys/` | module signing key pair (git-ignored, local only) |
| `install.sh` | copies all of the above into place (root) |
| `qemu-eac-test/` | boots a built kernel in QEMU/KVM with the EAC command line and reports lockdown/LSM/signature/IOMMU state |

## Install

```bash
sudo ./install.sh --check     # dry run
sudo ./install.sh
sudo emerge -av1 =sys-kernel/cachyos-kernel-7.3.0-r3 x11-drivers/nvidia-drivers
```

Order matters: the kernel installs `/usr/src/linux-7.3.0-cachyos-dist` and
its certificate; nvidia-drivers then builds against it and signs
`nvidia*.ko` with the same key (`MODULES_SIGN_KEY` from make.conf). The
kernel's postinst runs installkernel (dracut, grub-mkconfig), which also
writes the EAC entry. From now on `emerge -uDN @world` rebuilds nvidia-drivers
on every kernel bump through `virtual/dist-kernel`.

The signing key is installed `root:portage 0640`: kernel-build.eclass reads it
as root, but linux-mod-r1 (nvidia) signs in `src_install` as the portage user.
Keep a copy of `keys/` somewhere safe; a lost key just means regenerating one
and rebuilding kernel + nvidia.

After the reboot (normal entry first):

```bash
uname -r && modinfo -F signer nvidia && cat /sys/kernel/security/lockdown
```

Then the "Gentoo (EAC) 7.3.0-cachyos-dist" entry:

```bash
cat /sys/kernel/security/lockdown        # none [integrity] confidentiality
cat /sys/kernel/security/lsm             # capability,landlock,lockdown,yama,bpf
cat /proc/sys/kernel/kexec_load_disabled # 1
cat /sys/module/module/parameters/sig_enforce  # Y
cat /sys/kernel/iommu_groups/0/type      # DMA-FQ
```

In the EAC entry, `intel-undervolt` and other MSR writers are refused by
lockdown; `nvidia-smi`, OpenRGB (i2c-dev), liquidctl, lm-sensors keep working.

## Regenerating for a new cachyos-kernel version

```bash
cd /var/db/repos/CachyOS-kernels
USE=-savedconfig ebuild sys-kernel/cachyos-kernel/cachyos-kernel-<ver>.ebuild clean prepare
scripts/kernel-genx/genconfig.sh \
    /var/tmp/portage-disk/portage/sys-kernel/cachyos-kernel-<ver>/work/cachyos-<ver>-<rel> \
    scripts/kernel-genx/config-GenX-<ver> [lsmod snapshot]
sudo ./install.sh
```

`USE=-savedconfig` matters: the generator wants the ebuild's own config as
input, not last time's result. Without regenerating, the installed version-less
savedconfig plus `/etc/kernel/config.d/` already carry over to the next bump
(`olddefconfig` fills in new options with their defaults, so new drivers stay
off until you add them).

## Build and boot test results (2026-10-27)

Non-root validation on GenX itself, from a scratch `PORTAGE_CONFIGROOT` with
exactly the files `install.sh` installs (`ebuild ... clean compile install`,
`-j23`, clang 22.1.8 ThinLTO, AutoFDO profile applied):

| | stock 7.3.0-r1 on this box | GenX 7.3.0-r3 |
|---|---|---|
| compile time | n/a | about 9.5 min |
| modules built / installed | 6558, 213 MB | 2281, 49 MB |
| bzImage | 17.3 MB | 15.9 MB |
| signed modules | none (no `modules-sign`) | all 2281, signer `GenX kernel module signing key` |

(`modinfo -F signer` prints nothing on this box because `sys-apps/kmod` is
built without `pkcs7`; the signature trailer is there.)

QEMU/KVM boot of the built image (`qemu-eac-test/run-eac-test.sh`, q35 with an
emulated VT-d, same modules, dracut no-hostonly initramfs):

| check | EAC command line | normal command line |
|---|---|---|
| boots to init | yes, `7.3.0-cachyos-dist` | yes |
| `/sys/kernel/security/lockdown` | `none [integrity] confidentiality` | `[none] integrity confidentiality` |
| `/sys/kernel/security/lsm` | `lockdown,capability,landlock,yama,bpf` | same |
| `kexec_load_disabled` | 1 | 0 |
| `module.sig_enforce` | Y | Y (`MODULE_SIG_FORCE`) |
| IOMMU group type | `DMA-FQ` (translated) | no groups (not enabled) |
| insmod of a module with its signature stripped | `Key was rejected by service` | `Key was rejected by service` |
| insmod of the signed module | loaded | loaded |
| open `/dev/port` for writing | refused (lockdown) | allowed |

nvidia-drivers 615.78.08 with `USE="dist-kernel modules-sign"` built against
the staged tree (`KERNEL_DIR` pointed at the image): nvidia, nvidia-drm,
nvidia-modeset, nvidia-uvm and nvidia-peermem all compile with `NUMA=n` and
the other trims, carry `vermagic=7.3.0-cachyos-dist`, and each has a PKCS#7
signature whose certificate is `GenX kernel module signing key`; nvidia-drm
resolves `drm_ttm_helper` from the kept nouveau selection.

What was not tested: a real boot on the hardware (needs root to install), the
TPM path (no TPM in the VM) and the dist-kernel `USE=test` phase (its i440FX
machine needs `ata_piix`, which is kept, but the phase was not run).
