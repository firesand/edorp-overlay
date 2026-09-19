# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

"""Check that an upstream ASAR payload can be used with amd64 Electron."""

import json
from pathlib import Path
import struct
import sys


def check_file(name, data):
    if name.endswith((".node", ".so", ".dll", ".dylib", ".exe", ".bin")) or data[:4] in (
        b"\x7fELF", b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf",
        b"\xce\xfa\xed\xfe", b"\xfe\xed\xfa\xce", b"\xca\xfe\xba\xbe",
    ) or data[:2] == b"MZ":
        raise ValueError(f"Architecture-specific payload requires review: {name}")


def main():
    resources, lock_path, app_version, electron_version = sys.argv[1:]
    lock = json.loads(Path(lock_path).read_text())["packages"]
    if lock[""]["version"] != app_version:
        raise ValueError("Source version does not match the ebuild")
    if lock["node_modules/electron"]["version"] != electron_version:
        raise ValueError("Electron version does not match the upstream lockfile")

    resources = Path(resources)
    archive = (resources / "app.asar").read_bytes()
    header_size = struct.unpack_from("<I", archive, 4)[0]
    json_size = struct.unpack_from("<I", archive, 12)[0]
    header = json.loads(archive[16:16 + json_size])
    payload_start = 8 + header_size
    package = None

    def walk(entries, prefix=""):
        nonlocal package
        for name, entry in entries.items():
            path = prefix + name
            if "files" in entry:
                walk(entry["files"], path + "/")
            elif "link" in entry:
                raise ValueError(f"ASAR link requires review: {path}")
            elif not entry.get("unpacked"):
                start = payload_start + int(entry["offset"])
                end = start + entry["size"]
                if start < payload_start or end > len(archive):
                    raise ValueError(f"Invalid ASAR extent: {path}")
                data = archive[start:end]
                check_file(path, data)
                if path == "package.json":
                    package = json.loads(data)

    walk(header["files"])
    if not package or package["name"] != "plexo" or package["version"] != app_version:
        raise ValueError("Packaged application does not match the source version")
    for path in resources.rglob("*"):
        if path.is_symlink():
            raise ValueError(f"Resource link requires review: {path}")
        if path.is_file() and path.name != "app.asar":
            check_file(str(path.relative_to(resources)), path.read_bytes())
    print(f"Verified Plexo {app_version}: portable resources, Electron {electron_version}")


if __name__ == "__main__":
    main()
