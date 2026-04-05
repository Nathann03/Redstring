"""Response validation and safety rails for dialogue generation."""

from __future__ import annotations

import re
from typing import Iterable, List

from ..core.embeddings import SimpleEmbeddingModel
from ..core.models import CharacterInfo, GameState

SENTENCE_SPLIT_PATTERN = re.compile(r"(?<=[.!?])\s+")


class DialogueValidator:
    """Clamp responses to grounded, short, valid output."""

    def __init__(self) -> None:
        self._embedding_model = SimpleEmbeddingModel()

    def sanitize_response(
        self,
        text: str,
        fallback_text: str,
        grounding_facts: Iterable[str],
        require_grounding: bool = True,
    ) -> str:
        cleaned = " ".join(text.strip().split())
        if not cleaned:
            return fallback_text

        sentences = [sentence.strip() for sentence in SENTENCE_SPLIT_PATTERN.split(cleaned) if sentence.strip()]
        if len(sentences) > 2:
            cleaned = " ".join(sentences[:2])

        if len(cleaned) > 280:
            cleaned = cleaned[:277].rstrip() + "..."

        if require_grounding:
            facts_blob = " ".join(grounding_facts)
            similarity = self._embedding_model.cosine_similarity(
                self._embedding_model.embed(cleaned),
                self._embedding_model.embed(facts_blob),
            )
            if facts_blob and similarity < 0.08:
                return fallback_text
        return cleaned

    @staticmethod
    def validate_clues(character_info: CharacterInfo, game_state: GameState, clues: Iterable[str]) -> List[str]:
        allowed = character_info.evidence_knowledge
        already_found = set(game_state.found_clues)
        deduped: List[str] = []
        for clue_id in clues:
            if clue_id in allowed and clue_id not in already_found and clue_id not in deduped:
                deduped.append(clue_id)
        return deduped
