"""Brewfile regression: modern Bash is declared once, in the CLI tools section."""

from pathlib import Path
import unittest


BREWFILE = Path(__file__).resolve().parents[1] / "Brewfile"


class BrewfileTests(unittest.TestCase):
    def setUp(self):
        self.lines = BREWFILE.read_text(encoding="utf-8").splitlines()

    def formula_lines(self, name):
        prefix = f'brew "{name}"'
        return [line for line in self.lines if line.startswith(prefix)]

    def test_modern_bash_is_declared_once(self):
        self.assertEqual(len(self.formula_lines("bash")), 1)

    def test_jq_is_not_duplicated(self):
        self.assertEqual(len(self.formula_lines("jq")), 1)

    def test_bash_sits_in_command_line_tools_before_bat(self):
        section = self.lines.index("# Command Line Tools & Development")
        bash_index = next(i for i, line in enumerate(self.lines) if line.startswith('brew "bash"'))
        bat_index = next(i for i, line in enumerate(self.lines) if line.startswith('brew "bat"'))
        self.assertGreater(bash_index, section)
        self.assertEqual(bash_index + 1, bat_index)


if __name__ == "__main__":
    unittest.main()
