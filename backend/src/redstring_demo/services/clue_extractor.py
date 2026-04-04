"""Strict clue selection for dialogue responses."""

from __future__ import annotations

import re
from typing import Iterable, List, Sequence

from ..core.embeddings import SimpleEmbeddingModel
from ..core.models import CharacterInfo, GameState

EVIDENCE_ID_PATTERN = re.compile(r"EVID_\d+")


class ClueExtractor:
    """Return only valid, deduplicated clues for the current NPC."""

    def __init__(self) -> None:
        self._embedding_model = SimpleEmbeddingModel()

    def extract(
        self,
        character_info: CharacterInfo,
        player_question: str,
        game_state: GameState,
        candidate_clues: Sequence[str] | None = None,
    ) -> List[str]:
        allowed = character_info.evidence_knowledge
        already_found = set(game_state.found_clues)
        ordered: List[str] = []

        for clue_id in candidate_clues or []:
            if clue_id in allowed and clue_id not in already_found and clue_id not in ordered:
                ordered.append(clue_id)

        direct_mentions = self._extract_evidence_ids(player_question)
        for clue_id in direct_mentions:
            if clue_id in allowed and clue_id not in already_found and clue_id not in ordered:
                ordered.append(clue_id)

        if ordered:
            return ordered

        question_embedding = self._embedding_model.embed(player_question)
        best_clue = None
        best_similarity = 0.0
        for clue_id, description in allowed.items():
            if clue_id in already_found:
                continue
            similarity = self._embedding_model.cosine_similarity(
                question_embedding,
                self._embedding_model.embed(description),
            )
            if similarity > best_similarity:
                best_similarity = similarity
                best_clue = clue_id

        if best_clue and best_similarity >= 0.45:
            return [best_clue]
        return []

    @staticmethod
    def _extract_evidence_ids(text: str) -> Iterable[str]:
        return EVIDENCE_ID_PATTERN.findall(text.upper())
