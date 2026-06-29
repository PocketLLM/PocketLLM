"""Regression tests for the Vercel FastAPI deployment contract."""

from __future__ import annotations

import json
import tomllib
import unittest
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


class VercelDeploymentConfigTests(unittest.TestCase):
    """Keep Vercel's build and function runtimes aligned."""

    def test_python_runtime_is_314(self) -> None:
        python_version = (BACKEND_ROOT / ".python-version").read_text(
            encoding="utf-8"
        ).strip()
        pyproject = tomllib.loads(
            (BACKEND_ROOT / "pyproject.toml").read_text(encoding="utf-8")
        )

        self.assertEqual(python_version, "3.14")
        self.assertEqual(pyproject["project"]["requires-python"], "~=3.14.0")

    def test_vercel_uses_fastapi_without_a_server_build_command(self) -> None:
        vercel_config = json.loads(
            (BACKEND_ROOT / "vercel.json").read_text(encoding="utf-8")
        )
        pyproject = tomllib.loads(
            (BACKEND_ROOT / "pyproject.toml").read_text(encoding="utf-8")
        )

        self.assertEqual(vercel_config["framework"], "fastapi")
        self.assertIsNone(vercel_config["buildCommand"])
        self.assertEqual(pyproject["tool"]["vercel"]["entrypoint"], "main:app")


if __name__ == "__main__":
    unittest.main()
