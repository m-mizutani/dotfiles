import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin/herdr-label"


class HerdrLabelTests(unittest.TestCase):
    def run_label(self, tab_id=None, pane_id=None, tab_exit=0, pane_exit=0):
        with tempfile.TemporaryDirectory() as directory:
            stub = Path(directory) / "herdr"
            calls = Path(directory) / "calls"
            stub.write_text(
                '#!/bin/sh\n'
                'printf "%s\\n" "$*" >> "$HERDR_TEST_CALLS"\n'
                'if [ "$1" = tab ]; then exit "$HERDR_TEST_TAB_EXIT"; fi\n'
                'exit "$HERDR_TEST_PANE_EXIT"\n'
            )
            stub.chmod(0o755)
            env = os.environ.copy()
            env.pop("HERDR_TAB_ID", None)
            env.pop("HERDR_PANE_ID", None)
            env.update(
                PATH=f"{directory}:{env['PATH']}",
                HERDR_TEST_CALLS=str(calls),
                HERDR_TEST_TAB_EXIT=str(tab_exit),
                HERDR_TEST_PANE_EXIT=str(pane_exit),
            )
            if tab_id is not None:
                env["HERDR_TAB_ID"] = tab_id
            if pane_id is not None:
                env["HERDR_PANE_ID"] = pane_id
            result = subprocess.run(
                [str(SCRIPT), "[impl] テスト対象"], env=env, capture_output=True, text=True
            )
            return result.returncode, calls.read_text().splitlines() if calls.exists() else []

    def test_without_herdr_ids_does_nothing(self):
        self.assertEqual(self.run_label(), (0, []))

    def test_renames_tab_and_pane(self):
        self.assertEqual(
            self.run_label(tab_id="tab-1", pane_id="pane-1"),
            (0, ["tab rename tab-1 [impl] テスト対象", "pane rename pane-1 [impl] テスト対象"]),
        )

    def test_rename_failure_is_returned(self):
        self.assertEqual(
            self.run_label(tab_id="tab-1", pane_id="pane-1", tab_exit=7),
            (7, ["tab rename tab-1 [impl] テスト対象", "pane rename pane-1 [impl] テスト対象"]),
        )


if __name__ == "__main__":
    unittest.main()
