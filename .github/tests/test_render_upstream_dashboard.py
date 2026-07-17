from __future__ import annotations

import importlib.util
import json
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
