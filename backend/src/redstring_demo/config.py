"""Environment-backed settings for the dialogue API."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass(frozen=True)
class Settings:
    secret_key: str
    character_file: Path
    dialogue_file: Path
    llm_config_path: Optional[Path]
    warm_start: bool
    gemini_api_key: str
    gemini_model: str


def load_settings() -> Settings:
    secret_key = os.getenv("REDSTRING_SECRET_KEY", "")
    llm_config_raw = os.getenv("REDSTRING_LLM_CONFIG", "").strip()
    return Settings(
        secret_key=secret_key,
        character_file=Path(os.getenv("REDSTRING_CHARACTER_FILE", "backend/character_info.txt")),
        dialogue_file=Path(os.getenv("REDSTRING_DIALOGUE_FILE", "backend/data/npc_dialogue.json")),
        llm_config_path=Path(llm_config_raw) if llm_config_raw else None,
        warm_start=os.getenv("REDSTRING_WARM_START", "true").lower() in {"1", "true", "yes"},
        gemini_api_key=os.getenv("REDSTRING_GEMINI_API_KEY", os.getenv("GEMINI_API_KEY", "")).strip(),
        gemini_model=os.getenv("REDSTRING_GEMINI_MODEL", "gemini-3-flash-preview").strip(),
    )
