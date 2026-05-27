#!/bin/bash
# =============================================================================
# PPT Translator — Start Script
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_PORT=8092
VLLM_PORT=8091

echo ""
echo "=============================================="
echo "  PPT Translator — Preflight Checks"
echo "=============================================="
echo ""

# ── Check Docker ──
if ! docker info &>/dev/null; then
    echo "  [FAIL] Docker daemon is not running."
    echo "         Start it with: sudo systemctl start docker"
    exit 1
fi
echo "  [OK] Docker is running"

# ── Check NVIDIA GPU ──
if ! nvidia-smi &>/dev/null; then
    echo "  [FAIL] NVIDIA GPU not detected."
    exit 1
fi
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
echo "  [OK] GPU detected: $GPU_NAME"

echo ""
echo "  All checks passed."
echo ""

# ── Check if vLLM is already running ──
if curl -sf "http://localhost:${VLLM_PORT}/health" &>/dev/null; then
    MODEL=$(curl -sf "http://localhost:${VLLM_PORT}/v1/models" 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['id'])" 2>/dev/null \
        || echo "unknown")
    echo "  [OK] vLLM already running on port ${VLLM_PORT} (model: ${MODEL})"
    echo "  Starting app container only..."
    echo ""
    docker compose build app 2>&1 | tail -5
    docker compose up -d app
else
    echo "  [INFO] vLLM not detected on port ${VLLM_PORT}."
    echo "  Starting vLLM + app via docker compose..."
    echo "  vLLM model loading takes 5-10 minutes on first launch."
    echo ""
    docker compose --profile vllm build 2>&1 | tail -5
    docker compose --profile vllm up -d
fi

# ── Wait for app ──
echo ""
echo "  Waiting for app to be ready..."
for i in $(seq 1 60); do
    if curl -sf "http://localhost:${APP_PORT}/api/health" &>/dev/null; then
        break
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo "  Still waiting... (${i}s)"
    fi
    sleep 1
done

# ── Detect host LAN IP ──
HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
if [ -z "$HOST_IP" ]; then
    HOST_IP=$(hostname -I | awk '{print $1}')
fi
if [ -z "$HOST_IP" ]; then
    HOST_IP="localhost"
fi

echo ""
echo "=============================================="
echo "  PPT Translator"
echo "=============================================="
echo ""
echo "  Open in your browser:"
echo ""
echo "    http://${HOST_IP}:${APP_PORT}"
echo ""
echo "  App health:  http://${HOST_IP}:${APP_PORT}/api/health"
echo "  vLLM:        http://${HOST_IP}:${VLLM_PORT}/health"
echo ""
echo "  Stop:        docker compose down"
echo "  Logs:        docker compose logs -f app"
echo ""
echo "=============================================="
echo ""

docker compose logs -f app