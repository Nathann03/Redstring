"""Core models for the structured RedString dialogue backend."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional


@dataclass(frozen=True)
class GameState:
    """Minimal save-state data used by the backend dialogue system."""

    found_clues: List[str] = field(default_factory=list)
    asked_questions: List[str] = field(default_factory=list)
    npc_id: Optional[str] = None


@dataclass(frozen=True)
class CharacterKnowledge:
    """Structured knowledge that can be used to ground NPC responses."""

    alibi: str
    truth: List[str] = field(default_factory=list)
    will_admit_when_pressed: List[str] = field(default_factory=list)
    will_never_admit: List[str] = field(default_factory=list)
    knows_about_others: List[str] = field(default_factory=list)
    relationship_to_victim: str = ""


@dataclass(frozen=True)
class CharacterInfo:
    """Structured NPC definition received from the game or loaded from disk."""

    character_id: str
    name: str
    age: str
    occupation: str
    location: str
    personality_prompt: str
    knowledge_base: CharacterKnowledge
    evidence_knowledge: Dict[str, str]
    behavior_guidelines: List[str] = field(default_factory=list)
    confession_trigger: List[str] = field(default_factory=list)


@dataclass(frozen=True)
class DialogueRequest:
    """Single structured dialogue request from the client."""

    character_info: CharacterInfo
    player_question: str
    game_state: GameState
    evidence_id: Optional[str] = None


@dataclass(frozen=True)
class PregeneratedDialogue:
    """Retrieval record used for semantic lookup."""

    source_id: str
    text: str
    embedding_text: str
    evidence_id: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    clues: List[str] = field(default_factory=list)


class RetrievalHitType(str, Enum):
    MISS = "miss"
    HIT = "hit"


@dataclass(frozen=True)
class RetrievalResult:
    """Semantic retrieval result for pregenerated dialogue."""

    hit_type: RetrievalHitType
    similarity: float
    response_text: Optional[str] = None
    source_id: Optional[str] = None
    clues: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class GeneratedDialogue:
    """Structured text emitted by the LLM layer before validation."""

    response: str
    clues_unlocked: List[str] = field(default_factory=list)
    reasoning: Dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class DialogueResponse:
    """Final response shape returned to the client."""

    response: str
    clues_unlocked: List[str]
    route: str
    latency_ms: float
    confession: bool = False


@dataclass(frozen=True)
class LlamaGenerationConfig:
    """Configuration for llama.cpp backed inference."""

    model_path: str
    n_ctx: int = 2048
    n_threads: int = 4
    temperature: float = 0.25
    top_p: float = 0.9
    max_tokens: int = 120
