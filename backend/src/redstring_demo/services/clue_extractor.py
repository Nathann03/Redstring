"""Strict clue filtering for dialogue responses."""

from __future__ import annotations

from typing import List, Sequence

from ..core.models import CharacterInfo, GameState


class ClueExtractor:
    """Filter candidate clues to those the current NPC can legally reveal."""

    def extract(
        self,
        character_info: CharacterInfo,
        game_state: GameState,
        candidate_clues: Sequence[str] | None = None,
    ) -> List[str]:
        allowed = character_info.evidence_knowledge
        already_found = set(game_state.found_clues)
        ordered: List[str] = []

        for clue_id in candidate_clues or []:
            if clue_id in allowed and clue_id not in already_found and clue_id not in ordered:
                ordered.append(clue_id)

        return ordered
