import contextlib
import importlib.util
import io
import os
import tempfile
import unittest
from pathlib import Path


SPEC = importlib.util.spec_from_file_location("dotfiles_setup", Path(__file__).parents[1] / "setup.py")
assert SPEC is not None and SPEC.loader is not None
setup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(setup)


class SetupTests(unittest.TestCase):
    def test_codex_group_registers_configuration(self):
        home = Path("/tmp/test-home")
        groups = {group.name: group for group in setup.build_groups(home)}

        codex_links = {link.dst: link.src for link in groups["Codex"].links}

        self.assertEqual(codex_links[f"{home}/.codex/config.toml"], "codex/config.toml")

    def test_codex_auto_review_settings_are_top_level(self):
        content = (setup.REPO / "codex/config.toml").read_text()
        top_level = content.split("[projects.", 1)[0]

        self.assertIn('approval_policy = "on-request"', top_level)
        self.assertIn('approvals_reviewer = "auto_review"', top_level)
        self.assertIn('default_permissions = ":workspace"', top_level)

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

    def test_herdr_tab_name_uses_agent_specific_instructions(self):
        home = Path("/tmp/test-home")
        groups = {group.name: group for group in setup.build_groups(home)}

        claude_links = {link.dst: link.src for link in groups["Claude Code"].links}
        codex_links = {link.dst: link.src for link in groups["Codex"].links}

        self.assertEqual(
            claude_links[f"{home}/.claude/skills/herdr-tab-name"],
            "claude/skills/herdr-tab-name",
        )
        self.assertEqual(
            codex_links[f"{home}/.agents/skills/herdr-tab-name"],
            "codex/skills/herdr-tab-name",
        )

    def test_run_migrates_managed_herdr_tab_name_link(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            destination = home / ".agents/skills/herdr-tab-name"
            destination.parent.mkdir(parents=True)
            os.symlink(setup.REPO / "claude/skills/herdr-tab-name", destination)

            with contextlib.redirect_stdout(io.StringIO()):
                stats = setup.run(home=home)

            self.assertEqual(stats.failed, 0)
            self.assertEqual(stats.replaced, 1)
            self.assertEqual(
                destination.resolve(),
                setup.REPO / "codex/skills/herdr-tab-name",
            )

    def test_run_creates_symlinks_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            with contextlib.redirect_stdout(io.StringIO()):
                first = setup.run(home=home)
                second = setup.run(home=home)

            self.assertEqual(first.failed, 0)
            self.assertTrue((home / ".agents/skills/spec").is_symlink())
            self.assertEqual(second.created, 0)
            self.assertGreater(second.skipped, 0)

    def test_dry_run_does_not_create_codex_skill_links(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            with contextlib.redirect_stdout(io.StringIO()):
                stats = setup.run(dry_run=True, home=home)

            self.assertEqual(stats.failed, 0)
            self.assertGreater(stats.created, 0)
            self.assertFalse((home / ".agents/skills/spec").exists())

    def test_run_removes_managed_legacy_skill_links(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            claude_legacy = home / ".claude/skills/dev"
            codex_legacy = home / ".agents/skills/dev"
            claude_legacy.parent.mkdir(parents=True)
            codex_legacy.parent.mkdir(parents=True)
            os.symlink(setup.REPO / "claude/skills/dev", claude_legacy)
            os.symlink(setup.REPO / "codex/skills/dev", codex_legacy)

            with contextlib.redirect_stdout(io.StringIO()):
                stats = setup.run(home=home)

            self.assertEqual(stats.failed, 0)
            self.assertEqual(stats.removed, 2)
            self.assertFalse(os.path.lexists(claude_legacy))
            self.assertFalse(os.path.lexists(codex_legacy))

    def test_run_preserves_an_unmanaged_legacy_skill_path(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            legacy = home / ".agents/skills/dev"
            legacy.parent.mkdir(parents=True)
            legacy.write_text("keep")

            with contextlib.redirect_stdout(io.StringIO()):
                stats = setup.run(home=home)

            self.assertEqual(stats.failed, 1)
            self.assertEqual(legacy.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
