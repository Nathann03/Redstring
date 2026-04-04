#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-/app/backend/src}"

python3 -m redstring_demo.bootstrap_model

exec uvicorn redstring_demo.api:app --host 0.0.0.0 --port "${PORT:-8000}"
