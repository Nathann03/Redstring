#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/redstring}"
APP_USER="${APP_USER:-ubuntu}"
USE_LLM="${USE_LLM:-true}"
USE_CUDA="${USE_CUDA:-true}"

mkdir -p "$APP_ROOT"
chown -R "$APP_USER:$APP_USER" "$APP_ROOT"

python3 -m venv "$APP_ROOT/.venv"
source "$APP_ROOT/.venv/bin/activate"
python3 -m pip install --upgrade pip
python3 -m pip install -r "$APP_ROOT/backend/requirements.txt"

if [[ "$USE_LLM" == "true" ]]; then
  if [[ "$USE_CUDA" == "true" ]]; then
    export CMAKE_ARGS="-DGGML_CUDA=on"
    export FORCE_CMAKE=1
  fi
  python3 -m pip install -r "$APP_ROOT/backend/requirements-llm.txt"
fi

install -m 644 "$APP_ROOT/backend/deploy/redstring-dialogue.service" /etc/systemd/system/redstring-dialogue.service
systemctl daemon-reload
systemctl enable redstring-dialogue.service
systemctl restart redstring-dialogue.service
