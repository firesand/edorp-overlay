# KernelSmith changes derived from the GenX build check

The three patches apply, in order, on top of KernelSmith commit `71d2703` (the initial
release, what `sys-kernel/kernelsmith-9999` built on 2026-10-27):

```bash
git clone https://github.com/firesand/kernelsmith.git
cd kernelsmith
git am /path/to/kernelsmith/000*.patch
cargo test -p kernelsmith-core && cargo check --workspace && cargo clippy -p kernelsmith-core
```

The second patch makes the AutoFDO profile reuse happen when the job is prepared (after the
wizard turned AutoFDO on), lets a build reuse a `MODULES_SIGN_KEY` Portage already has (one key
per machine), and records the Portage signing files where the Library can remove them. The third
names the Kconfig gates (`USB_USBNET`, `VSOCKETS`) that the dock-NIC and vhost-vsock keep requests
depend on; a real build (`7.3.0-ks-max2`, 2026-10-28) had reported those five as verify misses.
These patches are also open as https://github.com/firesand/kernelsmith/pull/1.

What it adds, each a direct answer to a gap found in the `7.3.0-ks-max` build:

| Gap in the "max" build | Change |
|---|---|
| No module signed (`MODULE_SIG_ALL`/`FORCE` off, taint `O+E`); an EAC entry would refuse every module including `vmd` | New Security tweak **Module signing**: off / sign / sign-and-enforce. One persistent key in `/etc/kernelsmith/keys/modules-signing.pem` (root:portage 0640), `MODULE_SIG_KEY` set in the config stage, in-tree modules signed by `modules_install`, out-of-tree ones signed by a `sign_modules` helper after `emerge @module-rebuild` (compressed modules handled), and `/etc/portage/{env,package.env,package.use}/kernelsmith-modules-sign` so Portage keeps signing nvidia-drivers, xpadneo and r8125 on later rebuilds |
| No lockdown-early, MOK keyring trusted, no EAC entry | New Security tweak **Anti-cheat readiness** (needs enforce): the CachyOS EAC Kconfig set plus a GRUB script `/etc/grub.d/41_kernelsmith-eac-<release>` adding "Gentoo (EAC) <release>" with `lockdown=integrity lsm=… iommu.passthrough=0 module.sig_enforce=1 sysctl.kernel.kexec_load_disabled=1 intel_iommu=on`; removed with the kernel. The plan check states plainly that Epic's well-known-key rule still fails for self-built kernels |
| loop, dm-crypt, br_netfilter, macvlan/vxlan, xfs/f2fs/cifs/squashfs, sr_mod, USB serial, snd-aloop gone | Keep families **Encrypted, virtual & RAM disks** (incl. all ciphers), **More filesystems**, **Sensors, fans & RGB controllers**, **Optical drives & USB serial adapters**; VPN/virtualization families gain br_netfilter, macvlan/ipvlan/vxlan/tap, VLAN, TLS, cake, BPF classifiers; USB audio gains snd-aloop/virmidi; webcams keep all of `drivers/media/usb`; docks default on when Thunderbolt is loaded |
| `AUTOFDO_CLANG=y` but no profile passed | `BuildPlan::new` reuses the newest recorded profile automatically, `kernelsmith plan/build --afdo FILE` / `--no-afdo`, the build warns when no `-fprofile-sample-use` reached the compiler, manifest records the profile |
| i915/xe kept without an Intel GPU (mei_hdcp/mei_pxp depend on them) | **Platform features this PC doesn't have** drops the other vendor's IOMMU/SME/P-state, LA57/SGX/TDX by CPU flag, `EFI_MIXED`, x32, and GPU drivers of absent vendors (i915/xe/mei_hdcp/mei_pxp here) |
| `NR_CPUS=8192`, NUMA, paravirt/Xen/Hyper-V guest code, all LSMs, `ACPI_DEBUG` | **CPU count & memory topology** (NR_CPUS next power of two, NUMA off on one node), **Virtual-machine guest support**, **Unused security modules** (keeps what `/sys/kernel/security/lsm` lists), `ACPI_DEBUG` joins the developer self-checks, **Hardening defaults with a runtime cost** (off by default) |
| `VMD=m` with the root NVMe behind VMD | VMD becomes a critical built-in requirement when a VMD controller is detected |

Verification done on GenX before exporting: 22 core unit tests (4 new), `cargo check --workspace`
and `cargo clippy` clean (the repository has no CI workflow of its own), `kernelsmith detect --json` reports the new fields correctly for this machine,
`kernelsmith plan` with `signing=enforce anticheat=ready` produced `example-build-GenX.sh`
(bash -n clean; `example-plan-GenX.toml` is its plan), its embedded GRUB script was dry-run
against the installed `7.3.0-ks-max` files and produced a correct entry, and the `sign_modules`
helper was run on copies of two unsigned modules from `/lib/modules/7.3.0-ks-max` (one plain,
one `.ko.zst`): both signed with the GenX certificate on the first pass, untouched on the second.

Not done: no real build was run with the patched KernelSmith (needs root), and the branch was
not pushed to github.com/firesand/kernelsmith.
