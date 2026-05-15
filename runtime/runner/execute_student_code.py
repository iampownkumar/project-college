#!/usr/bin/env python3
"""
Lab Exam Runner Script
======================
Executes student code in a subprocess and returns a JSON result
with stdout, stderr, exit code, and duration.

Usage:
  python execute_student_code.py <source_file> [stdin_data]

Output (stdout):
  {"stdout": "...", "stderr": "...", "exit_code": 0, "duration_ms": 42}
"""

import sys
import subprocess
import json
import time


def main() -> None:
    if len(sys.argv) < 2:
        result = {
            "stdout": "",
            "stderr": "Runner error: No source file path provided.",
            "exit_code": 1,
            "duration_ms": 0,
        }
        print(json.dumps(result))
        return

    source_file: str = sys.argv[1]
    stdin_data: str | None = sys.argv[2] if len(sys.argv) > 2 else None

    # Timeout is 30 seconds by default; can be overridden via env var
    timeout: int = int(__import__("os").environ.get("EXAM_TIMEOUT_SECONDS", "30"))

    start: float = time.monotonic()

    try:
        proc = subprocess.run(
            [sys.executable, source_file],
            input=stdin_data,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        duration_ms: int = int((time.monotonic() - start) * 1000)
        output = {
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "exit_code": proc.returncode,
            "duration_ms": duration_ms,
        }
    except subprocess.TimeoutExpired:
        duration_ms = int((time.monotonic() - start) * 1000)
        output = {
            "stdout": "",
            "stderr": f"Execution timed out after {timeout} seconds.",
            "exit_code": -1,
            "duration_ms": duration_ms,
        }
    except FileNotFoundError:
        duration_ms = int((time.monotonic() - start) * 1000)
        output = {
            "stdout": "",
            "stderr": f"Source file not found: {source_file}",
            "exit_code": -1,
            "duration_ms": duration_ms,
        }
    except Exception as exc:  # noqa: BLE001
        duration_ms = int((time.monotonic() - start) * 1000)
        output = {
            "stdout": "",
            "stderr": f"Runner error: {exc}",
            "exit_code": -1,
            "duration_ms": duration_ms,
        }

    print(json.dumps(output))


if __name__ == "__main__":
    main()
