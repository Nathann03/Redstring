"""RAG prompt construction utilities."""

from __future__ import annotations

import logging
from typing import Dict, Iterable, List

from ..core.models import PlayerQuery, RAGContext

logger = logging.getLogger(__name__)


class AnchorFactsStore:
    """Provides canonical NPC anchor facts."""

    def __init__(self, anchor_facts: Dict[str, List[str]]) -> None:
        self._anchor_facts = anchor_facts

    def get_facts(self, npc_id: str) -> List[str]:
        return list(self._anchor_facts.get(npc_id, []))


class RAGContextBuilder:
    """Builds structured context for the LLM fallback."""

    def __init__(self, anchor_store: AnchorFactsStore) -> None:
        self._anchor_store = anchor_store

    def build_context(
        self,
        query: PlayerQuery,
        retrieved_snippets: Iterable[str],
    ) -> RAGContext:
        dynamic_facts = self._extract_dynamic_facts(query)
        anchor_facts = self._anchor_store.get_facts(query.npc_id)
        snippets_list = list(retrieved_snippets)
        logger.debug(
            "Building RAG context for NPC '%s' with %d anchor facts and %d retrieved snippets",
            query.npc_id,
            len(anchor_facts),
            len(snippets_list),
        )
        return RAGContext(
            player_question=query.player_question,
            dynamic_facts=dynamic_facts,
            anchor_facts=anchor_facts,
            retrieved_snippets=snippets_list,
        )

    @staticmethod
    def _extract_dynamic_facts(query: PlayerQuery) -> Dict[str, object]:
        npc_states = query.game_state.get("npc_states", {})
        npc_state = npc_states.get(query.npc_id, {})
        extracted = {
            "npc_state": npc_state,
            "player_inventory": query.game_state.get("player_inventory", []),
            "player_reputation": query.game_state.get("player_reputation"),
        }
        case_id = query.game_state.get("case_id")
        if case_id is not None:
            extracted["case_id"] = case_id
        return extracted
