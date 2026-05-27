#!/bin/bash
# =============================================================================
# PPT Translator — Download Models
# Downloads the Qwen3.6-35B-A3B model and DFlash speculative draft model
# =============================================================================

echo ""
echo "=============================================="
echo "  PPT Translator — Model Download"
echo "=============================================="
echo ""

HF_CACHE="${HF_CACHE:-$HOME/.cache/huggingface}"

echo "  Cache directory: ${HF_CACHE}"
echo ""

# Check if huggingface-cli is available
if command -v huggingface-cli &>/dev/null; then
    echo "  Downloading Qwen/Qwen3.6-35B-A3B..."
    huggingface-cli download Qwen/Qwen3.6-35B-A3B --cache-dir "${HF_CACHE}"

    echo ""
    echo "  Downloading z-lab/Qwen3.6-35B-A3B-DFlash (speculative draft model)..."
    huggingface-cli download z-lab/Qwen3.6-35B-A3B-DFlash --cache-dir "${HF_CACHE}"
else
    echo "  huggingface-cli not found. Install with:"
    echo "    pip install huggingface_hub[cli]"
    echo ""
    echo "  Or pull models via Docker:"
    echo "    docker run --gpus all -v ${HF_CACHE}:/root/.cache/huggingface nvcr.io/nvidia/vllm:26.01-py3 \\"
    echo "      --model Qwen/Qwen3.6-35B-A3B --max-model-len 1024 --max-num-seqs 1"
    echo "    (Ctrl+C after model download completes)"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Download Complete"
echo "=============================================="
echo ""
echo "  Models cached in: ${HF_CACHE}"
echo "  Start the demo with: ./start.sh"
echo ""
