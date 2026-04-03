# RedString Dialogue API

This `backend` folder is a standalone AI dialogue service for RedString. It is not the full game backend. The backend now owns the revised suspect + weapon + location story data, and the game sends the NPC being questioned, the player's question, the evidence piece currently being discussed, and the dialogue-relevant game state.

## API Contract

`POST /dialogue`

Headers:
- `Authorization: Bearer <REDSTRING_SECRET_KEY>`

Request body:

```json
{
  "npc_id": "james_okoye",
  "player_question": "Where were you during the murder window?",
  "evidence_id": "EVID_09",
  "game_state": {
    "found_clues": ["EVID_09"],
    "asked_questions": ["who_are_you"],
    "npc_id": "james_okoye"
  }
}
```

Response:

```json
{
  "response": "Those are my timed water quality tests. You have to collect a sample every thirty minutes, then watch the color change before the next one. I was stuck at this bench from 9 PM to midnight.",
  "clues_unlocked": []
}
```

Notes:
- `npc_id` is the preferred contract. The server loads the matching NPC record from [`backend/character_info.txt`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/character_info.txt).
- `evidence_id` should be the map evidence the player is asking about, such as `EVID_02` for the wrench or `EVID_11` for Yuki's damp jacket.
- The legacy `character_info` payload is still accepted for compatibility, but new clients should not send it.

`GET /health`

Returns:

```json
{
  "status": "ok",
  "llm_ready": true,
  "known_characters": ["catch_wallace", "james_okoye", "riley_chen", "yuki_tanaka"]
}
```

`POST /warmup`

Headers:
- `Authorization: Bearer <REDSTRING_SECRET_KEY>`

Response:

```json
{
  "status": "ok",
  "llm_ready": true
}
```

## How Output Structure Is Enforced

The backend does not trust raw LLM output directly.

Enforcement layers:
- The llama prompt instructs the model to return JSON only.
- The LLM service parses the model response and accepts it only if it is a JSON object with exactly these keys:
  - `response`
  - `clues_unlocked`
- If parsing fails, if the model adds extra keys, if `clues_unlocked` is not a string array, or if `response` is empty, the backend falls back to the deterministic grounded generator.
- The FastAPI endpoint itself returns a typed response model with only:
  - `response: str`
  - `clues_unlocked: list[str]`
- Clues are then filtered again so only valid IDs from `character_info.evidence_knowledge` survive.

So the practical guarantee is:
- API response shape is always correct.
- Invalid model JSON never leaks to the client.
- Invalid clue IDs are stripped before returning.

## Story Dataset

The revised capstone script lives in:
- [`backend/data/npc_dialogue.json`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/data/npc_dialogue.json)

It now stores:
- story-level metadata, including the suspect + weapon + location solution
- the 11 evidence entries from the updated PDF
- one pre-scripted evidence response per NPC per evidence item

The current solution in the backend data is:
- suspect: `Yuki Tanaka`
- weapon: `Wrench`
- location: `Tidal Pool Lab`

## Recommended Model

Recommended lightweight model:
- Repo: `bartowski/Llama-3.2-3B-Instruct-GGUF`
- File: `Llama-3.2-3B-Instruct-Q4_K_M.gguf`

Reasoning:
- roughly 2 GB instead of a much heavier 7B or 8B class model
- good enough for short, grounded detective dialogue
- faster startup and cheaper storage/bandwidth
- easier to keep warm on a single GPU instance

## Best Cold-Start Strategy

The best practical way to avoid an ugly cold start is:
- keep one instance running during your demo window
- warm the model at process startup with `REDSTRING_WARM_START=true`
- store the GGUF on the instance's EBS volume so it is not redownloaded on every restart

Best order of preference:
1. Keep the GGUF file on attached EBS and keep the service running.
2. If you rebuild instances often, bake the model into a custom AMI.
3. If you must download on boot, pull from S3 in the same region instead of from the public internet.

For a capstone demo, the simplest good setup is:
- one `g4dn.xlarge` instance
- one quantized 3B GGUF model on EBS
- one always-on process

That is better than trying to scale to zero. Scale-to-zero is what creates the worst cold start.

## Local Run

```bash
python3 -m venv backend/.venv
source backend/.venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r backend/requirements.txt
export PYTHONPATH=backend/src
export REDSTRING_SECRET_KEY=replace-me
uvicorn redstring_demo.api:app --reload
```

Optional llama.cpp install:

```bash
python3 -m pip install -r backend/requirements-llm.txt
export REDSTRING_LLM_CONFIG=backend/config/local_llm_config.json
export REDSTRING_HF_REPO_ID=bartowski/Llama-3.2-3B-Instruct-GGUF
export REDSTRING_HF_FILENAME=Llama-3.2-3B-Instruct-Q4_K_M.gguf
```

## AWS Deployment

Recommended AWS setup:
- one `g4dn.xlarge` Spot instance
- Deep Learning GPU AMI
- bearer-token auth at the app layer
- API port open publicly, protected by the bearer token
- GGUF stored on EBS and warmed on startup

Terraform is in:
- [`backend/iac/terraform`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/iac/terraform)

EC2 service files are in:
- [`backend/deploy/redstring-dialogue.service`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/deploy/redstring-dialogue.service)
- [`backend/deploy/redstring-dialogue.env.example`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/deploy/redstring-dialogue.env.example)
- [`backend/deploy/install_on_ec2.sh`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/deploy/install_on_ec2.sh)

Plain-text deployment steps are in:
- [`backend/AWS_DEPLOYMENT_STEPS.txt`](/mnt/c/Users/natha/OneDrive/Desktop/Redstring/backend/AWS_DEPLOYMENT_STEPS.txt)

## Recommended Game Startup Flow

When the player launches the game:

1. Call `GET /health`.
2. If `llm_ready` is `false`, call `POST /warmup` in the background.
3. Poll `/health` until `llm_ready` becomes `true`.
4. Only then allow the first real NPC conversation, or show a short loading state until warm-up finishes.

This is cleaner than sending a fake dialogue request just to force model load.

## Environment Variables

- `REDSTRING_SECRET_KEY`
- `REDSTRING_CHARACTER_FILE`
- `REDSTRING_DIALOGUE_FILE`
- `REDSTRING_LLM_CONFIG`
- `REDSTRING_HF_REPO_ID`
- `REDSTRING_HF_FILENAME`
- `HF_TOKEN`
- `REDSTRING_MODEL_S3_URI`
- `REDSTRING_MODEL_URL`
- `REDSTRING_WARM_START`
- `PORT`

## Tests

```bash
source backend/.venv/bin/activate
PYTHONPATH=backend/src python3 -m pytest backend/tests -q
```
