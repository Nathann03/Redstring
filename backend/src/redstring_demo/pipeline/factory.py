"""Factory helpers for the structured dialogue router."""

from __future__ import annotations

from pathlib import Path
from typing import Optional, Tuple

from ..core.models import LlamaGenerationConfig
from ..data.loader import CharacterDataset, load_character_dataset, load_dialogue_dataset
from ..services.clue_extractor import ClueExtractor
from ..services.dialogue_router import DialogueRouter
from ..services.llm_service import (
    GeminiLLMService,
    GroqLLMService,
    LlamaCppLLMService,
    LocalLLMService,
    OpenRouterLLMService,
)
from ..services.retrieval_engine import RetrievalEngine
from ..services.validator import DialogueValidator


def build_dialogue_router(
    character_path: Optional[Path] = None,
    dialogue_path: Optional[Path] = None,
    llm_config: Optional[LlamaGenerationConfig] = None,
    gemini_api_key: str = "",
    gemini_model: str = "gemini-3-flash-preview",
    groq_api_key: str = "",
    groq_model: str = "meta-llama/llama-4-scout-17b-16e-instruct",
    openrouter_api_key: str = "",
    openrouter_model: str = "openrouter/auto",
) -> Tuple[DialogueRouter, LocalLLMService, CharacterDataset]:
    character_dataset = load_character_dataset(character_path)
    dialogue_dataset = load_dialogue_dataset(dialogue_path)
    llm_service: LocalLLMService
    if llm_config:
        llm_service = LlamaCppLLMService(llm_config)
    else:
        llm_service = LocalLLMService()
    router = DialogueRouter(
        retrieval_engine=RetrievalEngine(dialogue_dataset.records),
        llm_service=llm_service,
        gemini_service=GeminiLLMService(api_key=gemini_api_key, model=gemini_model),
        groq_service=GroqLLMService(api_key=groq_api_key, model=groq_model),
        openrouter_service=OpenRouterLLMService(api_key=openrouter_api_key, model=openrouter_model),
        clue_extractor=ClueExtractor(),
        validator=DialogueValidator(),
    )
    return router, llm_service, character_dataset
