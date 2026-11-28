#!/usr/bin/env bash
# Canonical Bend formal verification gate entrypoint (local macOS/Linux and CI).
set -euo pipefail
cd "$(dirname "$0")/../.."
exec python3 -B test/bend/run.py "$@"
