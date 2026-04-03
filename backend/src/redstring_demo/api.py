"""FastAPI application for the standalone RedString dialogue service."""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Literal, Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
from pydantic import BaseModel, Field, model_validator

from .config import Settings, load_settings
from .core.models import CharacterInfo, CharacterKnowledge, DialogueRequest, GameState, LlamaGenerationConfig
from .data.loader import load_character_dataset, load_dialogue_dataset
from .pipeline.factory import build_dialogue_router
from .security import enforce_access

logger = logging.getLogger(__name__)


class CharacterKnowledgePayload(BaseModel):
    alibi: str
    truth: List[str] = Field(default_factory=list)
    will_admit_when_pressed: List[str] = Field(default_factory=list)
    will_never_admit: List[str] = Field(default_factory=list)
    will_never_admit_until_overwhelming_evidence: List[str] = Field(default_factory=list)
    knows_about_others: List[str] = Field(default_factory=list)
    relationship_to_victim: str = ""


class CharacterInfoPayload(BaseModel):
    character_id: str
    name: str
    age: str = ""
    occupation: str = ""
    location: str = ""
    personality_prompt: str
    knowledge_base: CharacterKnowledgePayload
    evidence_knowledge: Dict[str, str] = Field(default_factory=dict)
    behavior_guidelines: List[str] = Field(default_factory=list)
    confession_trigger: List[str] = Field(default_factory=list)


class GameStatePayload(BaseModel):
    found_clues: List[str] = Field(default_factory=list)
    asked_questions: List[str] = Field(default_factory=list)
    npc_id: Optional[str] = None


class DialogueRequestPayload(BaseModel):
    npc_id: Optional[str] = None
    character_info: Optional[CharacterInfoPayload] = None
    player_question: str
    evidence_id: Optional[str] = None
    generation_backend: Optional[Literal["auto", "local", "gemini"]] = None
    game_state: GameStatePayload = Field(default_factory=GameStatePayload)

    @model_validator(mode="after")
    def validate_character_source(self) -> "DialogueRequestPayload":
        if not self.npc_id and not self.character_info:
            raise ValueError("either npc_id or character_info is required")
        return self


class DialogueResponsePayload(BaseModel):
    response: str
    clues_unlocked: List[str]


class WarmupResponsePayload(BaseModel):
    status: str
    llm_ready: bool


def create_app(settings: Settings | None = None) -> FastAPI:
    app = FastAPI(title="RedString Dialogue API", version="1.0.0")
    resolved_settings = settings or load_settings()
    router, llm_service, character_dataset = _build_runtime(resolved_settings)

    def authorize(request: Request, authorization: str | None = Header(default=None)) -> None:
        enforce_access(request, resolved_settings, authorization)

    @app.get("/health")
    def health() -> Dict[str, Any]:
        return {
            "status": "ok",
            "llm_ready": llm_service.is_ready(),
            "gemini_available": bool(resolved_settings.gemini_api_key),
            "known_characters": sorted(character_dataset.records.keys()),
        }

    @app.post("/warmup", response_model=WarmupResponsePayload, dependencies=[Depends(authorize)])
    def warmup() -> WarmupResponsePayload:
        if not llm_service.is_ready():
            llm_service.spin_up()
        return WarmupResponsePayload(status="ok", llm_ready=llm_service.is_ready())

    @app.post("/dialogue", response_model=DialogueResponsePayload, dependencies=[Depends(authorize)])
    def dialogue(payload: DialogueRequestPayload) -> DialogueResponsePayload:
        character_info = _resolve_character_info(payload, character_dataset)
        if payload.game_state.npc_id and payload.game_state.npc_id != character_info.character_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="game_state.npc_id must match the resolved character id",
            )
        request_model = DialogueRequest(
            character_info=character_info,
            player_question=payload.player_question,
            game_state=GameState(
                found_clues=list(payload.game_state.found_clues),
                asked_questions=list(payload.game_state.asked_questions),
                npc_id=payload.game_state.npc_id or character_info.character_id,
            ),
            evidence_id=payload.evidence_id,
            generation_backend=payload.generation_backend,
        )
        result = router.route(request_model)
        logger.info("request_complete route=%s latency_ms=%.2f", result.route, result.latency_ms)
        return DialogueResponsePayload(
            response=result.response,
            clues_unlocked=result.clues_unlocked,
        )

    return app


def _build_runtime(settings: Settings):
    llm_config = _load_llama_config(settings.llm_config_path) if settings.llm_config_path else None
    router, llm_service, character_dataset = build_dialogue_router(
        character_path=settings.character_file,
        dialogue_path=settings.dialogue_file,
        llm_config=llm_config,
        gemini_api_key=settings.gemini_api_key,
        gemini_model=settings.gemini_model,
    )
    if settings.warm_start:
        llm_service.spin_up()
    return router, llm_service, character_dataset


def _load_llama_config(path: Path) -> LlamaGenerationConfig:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return LlamaGenerationConfig(**payload)


def _to_character_info(payload: CharacterInfoPayload) -> CharacterInfo:
    knowledge = CharacterKnowledge(
        alibi=payload.knowledge_base.alibi,
        truth=list(payload.knowledge_base.truth),
        will_admit_when_pressed=list(payload.knowledge_base.will_admit_when_pressed),
        will_never_admit=list(
            payload.knowledge_base.will_never_admit
            or payload.knowledge_base.will_never_admit_until_overwhelming_evidence
        ),
        knows_about_others=list(payload.knowledge_base.knows_about_others),
        relationship_to_victim=payload.knowledge_base.relationship_to_victim,
    )
    return CharacterInfo(
        character_id=payload.character_id,
        name=payload.name,
        age=payload.age,
        occupation=payload.occupation,
        location=payload.location,
        personality_prompt=payload.personality_prompt,
        knowledge_base=knowledge,
        evidence_knowledge=dict(payload.evidence_knowledge),
        behavior_guidelines=list(payload.behavior_guidelines),
        confession_trigger=list(payload.confession_trigger),
    )


def _resolve_character_info(payload: DialogueRequestPayload, dataset) -> CharacterInfo:
    if payload.character_info is not None:
        return _to_character_info(payload.character_info)
    assert payload.npc_id is not None
    try:
        return dataset.get(payload.npc_id)
    except KeyError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"unknown npc_id: {payload.npc_id}",
        ) from exc


app = create_app()
