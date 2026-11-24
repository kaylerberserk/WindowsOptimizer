import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECK = Path(__file__).resolve().parent / "check-batch.py"


class CheckBatchTests(unittest.TestCase):
    def _run(self, payload: bytes) -> subprocess.CompletedProcess:
        with tempfile.TemporaryDirectory(prefix="winopt-check-") as td:
            p = Path(td) / "sample.cmd"
            p.write_bytes(payload)
            return subprocess.run(
                [sys.executable, "-B", str(CHECK), str(p)],
                capture_output=True,
                text=True,
            )

    def test_valid_batch_passes(self):
        res = self._run(
            b"@echo off\r\n"
            b"rem goto :NOWHERE\r\n"
            b":: call :MISSING\r\n"
            b"echo goto :FAKE\r\n"
            b"set X=call :NOPE\r\n"
            b"goto :STEP\r\n"
            b":STEP\r\n"
            b"echo step\r\n"
            b":FALLTHROUGH\r\n"
            b"exit /b 0\r\n"
        )
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertIn("[OK] labels:", res.stdout)

    def test_bare_lf_and_bare_cr_return_42(self):
        self.assertEqual(self._run(b"@echo off\nexit /b 0\n").returncode, 42)
        self.assertEqual(self._run(b"@echo off\rexit /b 0\r\n").returncode, 42)

    def test_non_ascii_and_nul_return_44(self):
        self.assertEqual(self._run(b"@echo off\r\nrem caf\xc3\xa9\r\n").returncode, 44)
        self.assertEqual(self._run(b"@echo off\r\n\x00\r\n").returncode, 44)

    def test_duplicate_missing_and_unreachable_labels_fail(self):
        dup = self._run(b"@echo off\r\ngoto :A\r\n:A\r\n:A\r\nexit /b 0\r\n")
        self.assertEqual(dup.returncode, 1)
        self.assertIn("duplicate label", dup.stdout)

        miss = self._run(b"@echo off\r\ngoto :MISSING\r\n")
        self.assertEqual(miss.returncode, 1)
        self.assertIn("does not exist", miss.stdout)

        unreach = self._run(b"@echo off\r\nexit /b 0\r\n:DEAD\r\nexit /b 0\r\n")
        self.assertEqual(unreach.returncode, 1)
        self.assertIn("unreachable", unreach.stdout)

        dyn = self._run(b"@echo off\r\ngoto :%TARGET%\r\n")
        self.assertEqual(dyn.returncode, 1)
        self.assertIn("dynamic goto target", dyn.stdout)

    def test_unreadable_file_returns_43(self):
        res = subprocess.run(
            [sys.executable, "-B", str(CHECK), "/nonexistent/winopt/missing.cmd"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 43)

    def test_line_exceeding_cmd_limit_fails(self):
        res = self._run(b"@echo off\r\necho " + b"a" * 8200 + b"\r\n")
        self.assertEqual(res.returncode, 1)
        self.assertIn("exceeds cmd.exe limit", res.stdout)


if __name__ == "__main__":
    unittest.main()
