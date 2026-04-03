# RedString Dialogue API Backend

## Current Scope
- Standalone NPC dialogue API only.
- No ElevenLabs or TTS integration.
- No app-layer IP allowlist.
- Bearer token auth only.

## Request Contract
- `POST /warmup` exists for client-side model preload.
- `character_info`
- `player_question`
- `game_state`
  - `found_clues`
  - `asked_questions`
  - `npc_id`

## Response Contract
- `response`
- `clues_unlocked`

The final API response is always shaped by the FastAPI response model, not by raw model output.

## Output Enforcement
- The llama prompt requests JSON only.
- Parsed model output is accepted only if it is a JSON object with exactly:
  - `response`
  - `clues_unlocked`
- If parsing fails or extra keys appear, the service falls back to the deterministic grounded generator.
- Clue IDs are then filtered against `character_info.evidence_knowledge`.

## Active Architecture
- `redstring_demo/api.py`: FastAPI app and typed response models, including `/warmup`.
- `redstring_demo/services/dialogue_router.py`: confession check, retrieval-first route, LLM fallback.
- `redstring_demo/services/retrieval_engine.py`: semantic retrieval.
- `redstring_demo/services/llm_service.py`: deterministic fallback plus optional llama.cpp generation.
- `redstring_demo/services/clue_extractor.py`: clue candidate selection.
- `redstring_demo/services/validator.py`: response and clue validation.
- `redstring_demo/bootstrap_model.py`: GGUF downloader.

## Deployment
- Single `g4dn.xlarge` Spot instance is the recommended demo shape.
- Keep the model on EBS to avoid redownloading.
- Keep the process warm with `REDSTRING_WARM_START=true`.
- If you need even less cold-start pain, bake the GGUF into a custom AMI.

## Cleanup Status
- Legacy warmup/TTS/RAG/orchestrator code removed.
- Old CLI demo flow removed.
- Backend now reads as one deployable dialogue API.
