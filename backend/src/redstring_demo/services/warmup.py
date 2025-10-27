"""Warm-up fallback handling for when the LLM service is still spinning up."""

from __future__ import annotations

import logging
from itertools import cycle
from typing import Dict, Iterable, List

from ..core.models import PlayerQuery, WarmupStatus

logger = logging.getLogger(__name__)


class PresetDialogueStore:
    """Cycles through preset dialogue lines per NPC."""

    def __init__(self, preset_dialogues: Dict[str, Iterable[str]]) -> None:
        self._cycles: Dict[str, any] = {}
        for npc_id, lines in preset_dialogues.items():
            sequence = list(lines)
            if not sequence:
                continue
            self._cycles[npc_id] = cycle(sequence)

    def next_line(self, npc_id: str) -> str:
        iterator = self._cycles.get(npc_id)
        if not iterator:
            return "I'm thinking..."
        return next(iterator)


class WarmupManager:
    """Queues player queries while warm-up fallback messaging is displayed."""

    def __init__(self, preset_store: PresetDialogueStore) -> None:
        self._preset_store = preset_store
        self._queue: List[PlayerQuery] = []

    def handle(self, query: PlayerQuery, llm_ready: bool) -> WarmupStatus:
        if llm_ready:
            return WarmupStatus(
                is_llm_ready=True,
                preset_dialogue=None,
                show_spinner=False,
                queued=False,
                queue_length=len(self._queue),
            )

        self._queue.append(query)
        logger.debug(
            "Queued query for NPC '%s' while LLM warms up; queue length=%d",
            query.npc_id,
            len(self._queue),
        )
        return WarmupStatus(
            is_llm_ready=False,
            preset_dialogue=self._preset_store.next_line(query.npc_id),
            show_spinner=True,
            queued=True,
            queue_length=len(self._queue),
        )

    def queued_queries(self) -> List[PlayerQuery]:
        return list(self._queue)

    def drain_queue(self) -> List[PlayerQuery]:
        pending = list(self._queue)
        self._queue.clear()
        return pending
