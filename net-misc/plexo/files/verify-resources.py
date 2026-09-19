# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

"""Check that the upstream amd64 bundle matches the pinned source revision.

Upstream began publishing native Linux amd64 builds at 1.0.0_rc.7, so the
package no longer repacks foreign-architecture resources onto a separately
downloaded Electron. What still needs guarding is that the shipped bundle is
the one the lockfile describes, and that every native addon the runtime can
load on this architecture is really x86-64.
"""

import json
from pathlib import Path
import struct
import sys

ELF_MAGIC = b"\x7fELF"
EM_X86_64 = 0x3E


def elf_machine(path):
    """Return the e_machine of an ELF file, or None if it is not ELF."""
    with path.open("rb") as handle:
        header = handle.read(20)
    if len(header) < 20 or header[:4] != ELF_MAGIC:
        return None
    return struct.unpack_from("<H", header, 18)[0]


def asar_package(archive_path):
    """Return the package.json object embedded in an ASAR archive."""
    archive = archive_path.read_bytes()
    header_size = struct.unpack_from("<I", archive, 4)[0]
    json_size = struct.unpack_from("<I", archive, 12)[0]
    header = json.loads(archive[16:16 + json_size])
    payload_start = 8 + header_size

    entry = header["files"].get("package.json")
    if not entry or "offset" not in entry:
        raise ValueError("ASAR archive has no inline package.json")
    start = payload_start + int(entry["offset"])
    end = start + entry["size"]
    if start < payload_start or end > len(archive):
        raise ValueError("Invalid ASAR extent for package.json")
    return json.loads(archive[start:end])


def main():
    resources, lock_path, app_version, electron_version, runtime = sys.argv[1:]

    lock = json.loads(Path(lock_path).read_text())["packages"]
    if lock[""]["version"] != app_version:
        raise ValueError("Source version does not match the ebuild")
    if lock["node_modules/electron"]["version"] != electron_version:
        raise ValueError("Electron version does not match the upstream lockfile")

    runtime = Path(runtime)
    if elf_machine(runtime) != EM_X86_64:
        raise ValueError(f"Bundled Electron runtime is not x86-64: {runtime}")

    resources = Path(resources)
    package = asar_package(resources / "app.asar")
    if package["name"] != "plexo" or package["version"] != app_version:
        raise ValueError("Packaged application does not match the source version")

    # Upstream ships every architecture's prebuilt addons side by side. Only the
    # linux_x64 copies are ever loaded here, so those must all be x86-64; a
    # native addon with no linux_x64 build at all would fail at runtime.
    addons = sorted(resources.rglob("*.node"))
    for addon in addons:
        if addon.is_symlink():
            raise ValueError(f"Native addon link requires review: {addon}")
        if "linux_x64" in addon.parts and elf_machine(addon) != EM_X86_64:
            raise ValueError(f"Native addon is not x86-64: {addon}")

    families = {addon.parent.parent for addon in addons}
    for family in sorted(families):
        if not any((family / "linux_x64").glob("*.node")):
            raise ValueError(f"Native addon has no linux_x64 build: {family}")

    print(
        f"Verified Plexo {app_version}: upstream amd64 bundle, "
        f"Electron {electron_version}, {len(addons)} native addon(s)"
    )


if __name__ == "__main__":
    main()
