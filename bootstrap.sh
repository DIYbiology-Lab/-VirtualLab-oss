#!/usr/bin/env bash
# bootstrap.sh — Virtual Lab × gpt-oss@vLLM 初期セットアップ（WSL2 / Ubuntu）
set -Eeuo pipefail

proj_root="$(pwd)"
compose_file="${proj_root}/compose.yaml"

require() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 not found"; exit 1; }; }

require docker
docker compose version >/dev/null 2>&1 || { echo "ERROR: Docker Compose V2 required"; exit 1; }

mkdir -p ./hf-cache ./work

echo "== NVIDIA GPU check (nvidia-smi inside CUDA container) =="
if ! docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
  echo "WARN: CUDA test container failed. Ensure NVIDIA driver & Docker GPU are enabled."
fi

read -rp "Mode [r=runtime(初回DL)/b=bundled(重み同梱)] (r/b) > " MODE
MODE="${MODE,,}"; [[ "${MODE}" =~ ^(r|b)$ ]] || { echo "Invalid mode"; exit 1; }

read -rp "Model size [20=20b / 120=120b] > " MZ
case "${MZ}" in
  120) MODEL_ID="openai/gpt-oss-120b" ;;
  20|"" ) MODEL_ID="openai/gpt-oss-20b" ;;
  *) echo "Invalid model size"; exit 1 ;;
esac

export MODEL_ID
export VLLM_API_KEY="local-oss"
export COMPOSE_PROFILES="$([[ "${MODE}" = "b" ]] && echo bundled || echo runtime)"

echo "== Summary =="
echo "  compose: ${compose_file}"
echo "  profile: ${COMPOSE_PROFILES}"
echo "  model  : ${MODEL_ID}"
echo "  key    : ${VLLM_API_KEY}"

echo "== Build & Up =="
docker compose -f "${compose_file}" --profile "${COMPOSE_PROFILES}" up -d --build

echo "== Wait for LLM API (http://localhost:8000/v1/models) =="
for i in {1..60}; do
  if curl -fsS -H "Authorization: Bearer ${VLLM_API_KEY}" http://localhost:8000/v1/models >/dev/null 2>&1; then
    ok=1; break
  fi
  sleep 2
done
[[ "${ok:-0}" = "1" ]] || { echo "WARN: LLM API not healthy yet."; }

echo "== Jupyter (Virtual Lab) =="
echo "  URL:  http://localhost:8888"
echo "  Test (inside vlab container):"
echo "  docker compose -f ${compose_file} exec $( [[ ${COMPOSE_PROFILES} = runtime ]] && echo vlab-runtime || echo vlab-bundled ) python - <<'PY'"
cat <<'PY'
from openai import OpenAI
import os
cli = OpenAI(base_url=os.environ["OPENAI_BASE_URL"], api_key=os.environ["OPENAI_API_KEY"])
r = cli.chat.completions.create(model=os.environ.get("MODEL_ID","openai/gpt-oss-20b"),
    messages=[{"role":"user","content":"hello"}], max_tokens=8)
print(r.choices[0].message.content)
PY