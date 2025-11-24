# Hybrid Retrieval + RAG Demo Backend

This directory contains a self-contained prototype of the hybrid retrieval and RAG pipeline described in the system design. Everything runs locally and relies on in-memory services so it can be demoed without paid APIs.

## Quickstart

1. Create the virtual environment and install test dependencies:
   ```bash
   python3 -m venv backend/.venv
   source backend/.venv/bin/activate
   python3 -m pip install --upgrade pip
   python3 -m pip install -r backend/requirements.txt
   ```
2. Run the unit tests to exercise the full flow without TTS or external models:
   ```bash
   source backend/.venv/bin/activate
   python3 -m pytest backend/tests -q
   ```
   If your environment restricts temporary directories (common in sandboxed setups), set `TMPDIR=$(pwd)/backend/.tmp` and add `--capture=no` to the pytest command.
3. (Optional) Launch the CLI demo to see responses in the terminal:
   ```bash
   source backend/.venv/bin/activate
   PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner --interactive
   ```
   - Use `--interactive` (default when no `--question` is supplied) for a menu where you pick an NPC and fire off multiple questions.
   - Flags: `--question "<your text>"`, `--npc <npc_id>`, `--enable-tts`, `--data-file /path/to/npc_dialogue.json`, `--log-level DEBUG`.

## Editing Dialogue & Vector Store Data

- Dialogue, anchor facts, preset dialogue, and pregenerated responses live in `backend/data/npc_dialogue.json`.
- Add or edit NPC entries in that file to immediately update the warm-up lines, anchor facts, and retrieval responses.
- The local “vector DB” seeds itself from the same JSON file on startup; no external service is required. If you want to point at a different file, pass `--data-file /path/to/npc_dialogue.json` to `PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner` or call `build_demo_orchestrator(path=Path(...))` from `redstring_demo.pipeline.factory` in code.

## Package Structure

- `redstring_demo/core`: cross-cutting dataclasses and embedding utilities.
- `redstring_demo/data`: JSON loader + in-memory vector store seeded from `npc_dialogue.json`.
- `redstring_demo/services`: warm-up queue, RAG builder, LLM/TTS stubs, cache, and retrieval engine.
- `redstring_demo/pipeline`: orchestrator and factory wiring all layers together.
- `redstring_demo/cli`: terminal demo wiring (`python3 -m redstring_demo.cli.demo_runner`).

## Optional: Local LLaMA Model via llama.cpp

The orchestrator defaults to a deterministic stub LLM so the tests stay fast and offline. To experiment with a local quantized model:

1. Install the additional dependency (compilation may take a few minutes):
   ```bash
   source backend/.venv/bin/activate
   python3 -m pip install -r backend/requirements-llm.txt
   ```
2. Copy `backend/config/local_llm_config.example.json` to `backend/config/local_llm_config.json` and update the `model_path` to point to a GGUF model on disk.
   - Download a GGUF (Q4_K_M is recommended) model from here: https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/blob/main/README.md
3. Launch the CLI with the config to verify everything locally (add `--interactive` for a menu, `--log-level DEBUG` for verbose tracing):
   ```bash
   source backend/.venv/bin/activate
   PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner \
     --llama-config backend/config/local_llm_config.json \
     --interactive
   ```
4. In downstream code, load the configuration and call `build_llama_orchestrator(...)` from `redstring_demo.pipeline.factory`. Call `llm.spin_up()` once at startup to load the model, then continue using the orchestrator as in the tests. If the llama dependency is unavailable, the system falls back to the deterministic stub.

> **Tip:** A great balance of speed and quality on consumer GPUs/CPUs is `Meta-Llama-3.1-8B-Instruct-Q6_K_L.gguf`. Point `model_path` at the GGUF on your WSL filesystem (e.g. `/mnt/c/.../Meta-Llama-3.1-8B-Instruct-Q6_K_L.gguf`).

## API Keys

If you eventually connect to paid APIs (e.g., remote TTS), duplicate `backend/demo_keys.example.json` and populate your secrets. The current demo uses stubs so no keys are required.
