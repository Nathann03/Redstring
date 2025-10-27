# Backend Demo Walkthrough

Use this checklist to prove out the hybrid retrieval + RAG pipeline locally before wiring it into GameMaker. Start with the shared setup, then pick either the stub demo (no local model) or the llama.cpp demo.

1. **Set up the environment**
   ```bash
   python3 -m venv backend/.venv
   source backend/.venv/bin/activate
   python3 -m pip install --upgrade pip
   python3 -m pip install -r backend/requirements.txt
   ```
2. **Review or edit dialogue data**
   - Open `backend/data/npc_dialogue.json`.
   - Add new NPCs, preset dialogue, anchor facts, or pregenerated responses as needed.
   - Save the file; no rebuild is required because the backend reads it on startup.
3. **Run automated tests** (skips TTS by default and exercises warm-up, retrieval, caching, and RAG):
   ```bash
   source backend/.venv/bin/activate
   TMPDIR=$(pwd)/backend/.tmp python3 -m pytest backend/tests -q --capture=no
   ```
## A) Stub LLM demo (no local model)

1. Launch the interactive CLI (runs instantly, uses deterministic stub responses):
   ```bash
   source backend/.venv/bin/activate
   PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner --interactive --log-level DEBUG
   ```
   - Pick an NPC from the menu, type a question, and the CLI shows which layer (preset, retrieval, or RAG) answered.
   - Flags: `--question` (non-interactive one-shot), `--npc` to force the responder, `--enable-tts` to include the Turbo TTS stub.

## B) Local LLaMA demo (llama.cpp)

1. Install the optional dependency (first build can take a few minutes):
   ```bash
   source backend/.venv/bin/activate
   python3 -m pip install -r backend/requirements-llm.txt
   ```
2. Copy the config template and point `model_path` at your GGUF (e.g., `/mnt/c/.../Meta-Llama-3.1-8B-Instruct-Q6_K_L.gguf`):
   ```bash
   cp backend/config/local_llm_config.example.json backend/config/local_llm_config.json
   # edit backend/config/local_llm_config.json to update model_path, threads, etc.
   ```
   - Download a GGUF (Q4_K_M is recommended) model from here: https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/blob/main/README.md 
3. Run the interactive CLI with the local model (first prompt may take a couple of minutes while the model loads; subsequent prompts reuse it):
   ```bash
   source backend/.venv/bin/activate
   PYTHONPATH=backend/src python3 -m redstring_demo.cli.demo_runner \
     --interactive \
     --llama-config backend/config/local_llm_config.json \
     --log-level DEBUG
   ```
   - Once the model reports `Local LLaMA model ready`, interact just like the stub demo; retrieval hits return instantly, and unusual questions fall back to RAG + llama.

## C) Integrate with GameMaker (or another client)

- Import `redstring_demo.pipeline.factory.build_llama_orchestrator` (or `build_demo_orchestrator` if you stay on the stub) from Python.
- Call `llm.spin_up()` once during game startup so retrieval hits stay low-latency.
- Send payloads shaped like `backend/tests/test_pipeline.py` into `orchestrator.handle_query(...)`; pass `tts_enabled=True` when you want the ElevenLabs-style stub to respond.

With these steps complete, you can confidently show the backend flow in isolation and later plug the same orchestrator into the GameMaker runtime via your preferred IPC (REST, WebSocket, or FFI).
