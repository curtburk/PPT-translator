# PPT Translator — On-Prem Presentation Translation

Translate PowerPoint presentations into 28+ languages using on-prem AI on the HP ZGX Nano. Upload a `.pptx`, pick a target language, download the translated deck — all formatting, images, and layouts preserved. Zero cloud. Zero data leakage.

## What It Does

1. **Upload** a `.pptx` file through the web UI
2. **Select** source and target languages (28 languages supported)
3. **Translate** — the LLM translates all text content slide-by-slide
4. **Download** the translated `.pptx` with original formatting intact

Text is translated at the shape level using an LLM (Qwen3.6-35B-A3B via vLLM), which produces significantly better translations than small seq2seq models — especially for corporate training materials with domain-specific terminology.

## Architecture

```
┌──────────────┐     ┌───────────────────────────┐     ┌──────────────────────────┐
│   Browser    │────▶│  App Container (port 8092) │────▶│  vLLM Container (8091)   │
│   Upload UI  │◀────│  FastAPI + python-pptx     │◀────│  Qwen3.6-35B-A3B         │
│              │     │  extract → rebuild         │     │  + DFlash speculative     │
└──────────────┘     └───────────────────────────┘     └──────────────────────────┘
                                  │
                         All processing on-device
                         Data never leaves the ZGX Nano
```

**Key design decisions:**
- **Fully containerized** — `docker compose up` and you're running, no dependency resolution
- **python-pptx** for reading/writing PPTX (preserves all formatting, images, charts, layouts)
- **LLM translation** over small translation models — much better quality for corporate/technical content
- **Slide-by-slide batching** — each slide's text blocks translated in a single LLM call for context coherence
- **Async job processing** — upload returns immediately, frontend polls for progress

## Quick Start

### 1. Download models (first time only)

```bash
chmod +x download_models.sh
./download_models.sh
```

### 2. Start everything

```bash
chmod +x start.sh
./start.sh
```

That's it. The script builds the app container, starts vLLM (or reuses an existing instance on port 8091), and opens the web UI.

Open `http://<YOUR_ZGX_NANO_IP>:8092` in your browser.

### Stop

```bash
# Stop everything
docker compose down

# Stop app only, keep vLLM running for other demos
docker compose stop app
```

## Containers

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| `ppt-translator-app` | Built from `Dockerfile` | 8092 | FastAPI web app + python-pptx |
| `ppt-translator-vllm` | `nvcr.io/nvidia/vllm:26.01-py3` | 8091 | LLM inference |

If you already have a vLLM instance on port 8091 (e.g., shared across demos), the start script detects it and only launches the app container.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HF_CACHE` | `$HOME/.cache/huggingface` | HuggingFace model cache path |
| `HF_TOKEN` | *(empty)* | HuggingFace token for gated models |
| `VLLM_URL` | `http://vllm:8000` | vLLM endpoint (inside compose network) |
| `VLLM_MODEL` | `Qwen/Qwen3.6-35B-A3B` | Model name for API calls |

## Supported Languages

Arabic, Chinese (Simplified & Traditional), Czech, Danish, Dutch, Finnish, French, German, Hindi, Hungarian, Indonesian, Italian, Japanese, Korean, Malay, Norwegian Bokmål, Polish, Portuguese (Brazil & Portugal), Romanian, Russian, Spanish, Swedish, Thai, Turkish, Ukrainian, Vietnamese

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/translate` | Upload PPTX + target language, returns job ID |
| `GET`  | `/api/status/{job_id}` | Poll translation progress |
| `GET`  | `/api/download/{job_id}` | Download translated PPTX |
| `GET`  | `/api/languages` | List supported target languages |
| `GET`  | `/api/health` | Health check (includes vLLM status) |

## Demo Talking Points

- **Compliance by Architecture**: training materials with sensitive company info never leave the device
- **28 languages from one model**: no need to deploy separate translation models per language pair
- **Formatting preserved**: unlike copy-paste-translate workflows, the output is a ready-to-distribute deck
- **Cost story**: compare to per-document cloud translation API pricing at scale across a global workforce
- **Speed**: a typical 15-slide deck translates in 30-60 seconds depending on text density

## File Structure

```
ppt-translator/
├── Dockerfile             # App container image
├── docker-compose.yml     # vLLM + app orchestration
├── server.py              # FastAPI backend
├── requirements.txt       # Python deps (installed inside container)
├── start.sh               # Launch script
├── download_models.sh     # Model download helper
├── templates/
│   └── index.html         # Frontend UI
├── static/                # Static assets
├── uploads/               # Temp uploaded files (volume-mounted)
└── output/                # Translated PPTX files (volume-mounted)
```

## Port Allocation

This demo uses port **8092** for the web app, avoiding conflicts with:
- 8090 (existing demos)
- 8091 (vLLM inference)
- 8888 (Deck Factory / SearXNG)
