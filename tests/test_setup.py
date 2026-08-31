import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path


SPEC = importlib.util.spec_from_file_location("dotfiles_setup", Path(__file__).parents[1] / "setup.py")
assert SPEC is not None and SPEC.loader is not None
setup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(setup)


class SetupTests(unittest.TestCase):
    def test_skill_groups_register_all_managed_skills(self):
        home = Path("/tmp/test-home")
        groups = {group.name: group for group in setup.build_groups(home)}

        claude_links = {
            Path(link.dst).name: link.src
            for link in groups["Claude Code"].links
            if "/.claude/skills/" in link.dst
        }
        codex_links = {
            Path(link.dst).name: link.src
            for link in groups["Codex"].links
            if "/.agents/skills/" in link.dst
        }

        self.assertEqual(set(claude_links), set(setup.CLAUDE_SKILLS))
        self.assertEqual(set(codex_links), set(setup.CLAUDE_SKILLS))
        for skill in setup.CLAUDE_SKILLS:
            self.assertEqual(claude_links[skill], f"claude/skills/{skill}")
        for skill in setup.SHARED_SKILLS:
            self.assertEqual(codex_links[skill], f"claude/skills/{skill}")
        for skill in setup.CODEX_SKILLS:
            self.assertEqual(codex_links[skill], f"codex/skills/{skill}")

    def test_registered_skills_have_matching_metadata(self):
        for skill in setup.CLAUDE_SKILLS:
            source_dir = setup.REPO / (
                f"claude/skills/{skill}" if skill in setup.SHARED_SKILLS else f"codex/skills/{skill}"
            )
            content = (source_dir / "SKILL.md").read_text()
            self.assertIn(f"name: {skill}", content)

    def test_run_creates_symlinks_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            with contextlib.redirect_stdout(io.StringIO()):
                first = setup.run(home=home)
                second = setup.run(home=home)

            self.assertEqual(first.failed, 0)
            self.assertTrue((home / ".agents/skills/dev").is_symlink())
            self.assertEqual(second.created, 0)
            self.assertGreater(second.skipped, 0)

    def test_dry_run_does_not_create_codex_skill_links(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            with contextlib.redirect_stdout(io.StringIO()):
                stats = setup.run(dry_run=True, home=home)

            self.assertEqual(stats.failed, 0)
            self.assertGreater(stats.created, 0)
            self.assertFalse((home / ".agents/skills/dev").exists())


if __name__ == "__main__":
    unittest.main()
