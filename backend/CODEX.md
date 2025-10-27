# Codex Backend Overview

## Purpose
- Local prototype of the hybrid Retrieval + RAG + LLM dialogue pipeline.
- Designed to serve NPC dialogue with warm-up fallbacks, cached retrieval hits, and llama.cpp RAG fallback.
- All data stored in JSON (`backend/data/npc_dialogue.json`); no paid APIs required.

## Key Components
- `redstring_demo/core`: dataclasses and embeddings.
- `redstring_demo/data`: JSON loader + in-memory vector store.
- `redstring_demo/services`: warm-up queue, retrieval, RAG builder, LLM stubs / llama.cpp wrapper, TTS stub, cache.
- `redstring_demo/pipeline`: orchestrator + factory wiring all layers.
- `redstring_demo/cli`: interactive CLI demo; supports stub or llama-backed runs.

## Typical Flow
1. Player question + save state packaged into `PlayerQuery`.
2. Warm-up manager decides whether to serve preset dialogue while LLM loads.
3. Vector search checks pregenerated responses (exact/fuzzy hits).
4. Misses drop to RAG builder → LLM (stub or llama) → optional caching + TTS stub.
5. Orchestrator returns `PipelineOutput` with metadata (source, similarity, latency).

## Running locally
```
python3 -m venv backend/.venv
source backend/.venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r backend/requirements.txt
```
- Tests: `TMPDIR=$(pwd)/backend/.tmp python3 -m pytest backend/tests -q --capture=no`
- Stub CLI: `PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner --interactive`
- LLaMA CLI: install `backend/requirements-llm.txt`, copy & edit `backend/config/local_llm_config.json`, run `PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner --llama-config backend/config/local_llm_config.json --interactive`

## Notes
- Logging: pass `--log-level DEBUG` to the CLI to see warm-up, retrieval, RAG, and LLM traces.
- LLaMA warm start prints `Local LLaMA model ready in …s` once per session; keep the process alive for instant retrieval hits.
- TTS stub exists (`--enable-tts`) but defaults off for demos.

