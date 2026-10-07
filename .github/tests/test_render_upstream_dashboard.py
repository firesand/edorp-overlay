from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path
import tomllib
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / ".github/scripts/render_upstream_dashboard.py"
SPEC = importlib.util.spec_from_file_location("render_upstream_dashboard", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
dashboard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(dashboard)


class RenderDashboardTest(unittest.TestCase):
    def test_shadps4_watchers_track_stable_core_and_published_launcher(self) -> None:
        with (REPO_ROOT / ".github/upstream.toml").open("rb") as file:
            config = tomllib.load(file)
        core = config["games-emulation/shadps4-bin"]
        self.assertTrue(core["use_latest_release"])
        self.assertFalse(core.get("include_prereleases", False))
        self.assertEqual("v.0.19.0".removeprefix(core["prefix"]), "0.19.0")

        launcher = config["games-emulation/shadps4-qtlauncher-bin"]
        self.assertEqual(launcher["source"], "regex")
        self.assertEqual(
            launcher["url"],
            "https://api.github.com/repos/shadps4-emu/shadps4-qtlauncher/releases?per_page=100",
        )
        # The later release deliberately has a lower SHA. Asset and commit
        # creation times must not replace the release publication time.
        feed = json.dumps([
            {
                "tag_name": "shadPS4QtLauncher-2026-10-05-" + "1" * 40,
                "published_at": "2026-10-05T21:00:00Z",
                "assets": [{"created_at": "2026-10-06T01:00:00Z"}],
            },
            {
                "tag_name": "shadPS4QtLauncher-2026-10-05-" + "f" * 40,
                "published_at": "2026-10-05T20:51:54Z",
            },
            {"sha": "a" * 40, "commit": {"committer": {"date": "2026-10-07T00:00:00Z"}}},
        ])
        versions = [
            re.sub(launcher["from_pattern"], launcher["to_pattern"], stamp)
            for stamp in re.findall(launcher["regex"], feed)
        ]
        self.assertEqual(versions, ["20261005.210000", "20261005.205154"])
        self.assertGreater(versions[0], versions[1])

    def test_unsloth_watcher_normalizes_beta_and_stable_releases(self) -> None:
        with (REPO_ROOT / ".github/upstream.toml").open("rb") as file:
            entry = tomllib.load(file)["app-misc/unsloth-desktop"]
        for tag, version in (
            ("v0.1.812-beta", "0.1.812_beta"),
            ("v1.0.0", "1.0.0"),
        ):
            with self.subTest(tag=tag):
                normalized = tag.removeprefix(entry["prefix"])
                normalized = re.sub(entry["from_pattern"], entry["to_pattern"], normalized)
                self.assertEqual(normalized, version)

    def test_wolfcut_watcher_accepts_concat_stable_releases(self) -> None:
        with (REPO_ROOT / ".github/upstream.toml").open("rb") as file:
            entry = tomllib.load(file)["media-video/wolfcut"]
        for tag, version in (
            ("v0.2.0-alpha.21", "0.2.0_alpha21"),
            ("v0.2.3", "0.2.3"),
        ):
            with self.subTest(tag=tag):
                self.assertIsNotNone(re.fullmatch(entry["include_regex"], tag))
                normalized = tag.removeprefix(entry["prefix"])
                normalized = re.sub(entry["from_pattern"], entry["to_pattern"], normalized)
                self.assertEqual(normalized, version)
        for tag in ("nightly", "models-v1", "v0.2.3-rc.1"):
            self.assertIsNone(re.fullmatch(entry["include_regex"], tag))

    def test_empty_update_list_closes_dashboard(self) -> None:
        self.assertEqual(dashboard.render_dashboard([], {}), "")
        self.assertEqual(
            dashboard.render_dashboard(
                [
                    {
                        "name": "gui-apps/walker",
                        "oldver": "2.17.0",
                        "newver": "2.17.0",
                        "delta": "equal",
                    }
                ],
                {},
            ),
            "",
        )

    def test_output_is_sorted_and_escapes_upstream_values(self) -> None:
        config = {
            "z/pkg": {
                "source": "pypi",
                "pypi": "safe-project",
                "policy": "review",
            },
            "a/pkg": {
                "source": "github",
                "github": "owner/project",
                "policy": "snapshot",
                "group": "paired",
                "note": "Review @maintainer | then test.",
            },
        }
        updates = [
            {"name": "z/pkg", "oldver": "1", "newver": "2", "delta": "new"},
            {
                "name": "a/pkg",
                "oldver": "1",
                "newver": "2|@team</code>",
                "delta": "new",
            },
        ]

        body = dashboard.render_dashboard(updates, config)

        self.assertLess(body.index("a/pkg"), body.index("z/pkg"))
        self.assertIn("2&#124;&#64;team&lt;/code&gt;", body)
        self.assertIn("Review &#64;maintainer &#124; then test.", body)
        self.assertNotIn("@team", body)
        self.assertTrue(body.startswith(dashboard.MARKER))

    def test_missing_config_entry_is_an_error(self) -> None:
        with self.assertRaisesRegex(ValueError, "no matching config"):
            dashboard.render_dashboard(
                [
                    {
                        "name": "missing/package",
                        "oldver": "1",
                        "newver": "2",
                        "delta": "new",
                    }
                ],
                {},
            )

    def test_real_config_and_baseline_cover_the_same_entries(self) -> None:
        with (REPO_ROOT / ".github/upstream.toml").open("rb") as file:
            config = tomllib.load(file)
        baseline = json.loads(
            (REPO_ROOT / ".github/upstream-old.json").read_text(
                encoding="utf-8"
            )
        )

        config.pop("__config__")
        package_atoms = {
            "/".join(path.relative_to(REPO_ROOT).parts[:2])
            for path in REPO_ROOT.glob("*/*/*.ebuild")
        }
        self.assertEqual(set(config), set(baseline))
        self.assertEqual(
            set(config) - package_atoms,
            {"ci/pkgcheck-image", "net-analyzer/bettercap::caplets"},
        )
        self.assertTrue(package_atoms <= set(config))
        for atom, entry in config.items():
            self.assertIn(entry["policy"], dashboard.POLICY_NAMES, atom)
            dashboard.source_url(entry)


if __name__ == "__main__":
    unittest.main()
