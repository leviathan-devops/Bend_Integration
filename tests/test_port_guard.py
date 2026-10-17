"""The judge ports must never be contacted. Mocks bind port 0.

Each test keeps its own temp directory. The planted files exist only there.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from port_guard import bind_mock, forbidden_ports, scan


class PortGuardTest(unittest.TestCase):
    def test_planted_connection_is_refused(self) -> None:
        first, second = forbidden_ports()
        with tempfile.TemporaryDirectory(prefix="bend-port-") as td:
            root = Path(td)
            planted = root / "client.py"
            planted.write_text(f'open("http://127.0.0.1:{first}/health")\n', encoding="utf-8")
            self.assertTrue(scan(root), "planted connection was not refused")
            planted.write_text(f'open("http://127.0.0.1:{second}/")\n', encoding="utf-8")
            self.assertTrue(scan(root), "planted twin port was not refused")

    def test_planted_fixed_bind_is_refused(self) -> None:
        first, _second = forbidden_ports()
        with tempfile.TemporaryDirectory(prefix="bend-bind-") as td:
            root = Path(td)
            planted = root / "mock_server.py"
            planted.write_text(f'sock.bind(("127.0.0.1", {first}))\n', encoding="utf-8")
            self.assertTrue(scan(root), "planted fixed bind was not refused")

    def test_mock_binds_port_zero_and_source_is_clean(self) -> None:
        with tempfile.TemporaryDirectory(prefix="bend-mock-") as td:
            root = Path(td)
            good = root / "mock_server.py"
            good.write_text('sock.bind(("127.0.0.1", 0))\n', encoding="utf-8")
            self.assertEqual(scan(root), [])
            sock = bind_mock()
            try:
                host, port = sock.getsockname()
                self.assertEqual(host, "127.0.0.1")
                self.assertNotIn(port, forbidden_ports())
                self.assertGreater(port, 0)
            finally:
                sock.close()

    def test_repo_tree_has_no_forbidden_connection(self) -> None:
        self.assertEqual(scan(ROOT), [])


if __name__ == "__main__":
    unittest.main()
