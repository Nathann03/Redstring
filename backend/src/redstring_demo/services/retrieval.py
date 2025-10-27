"""Retrieval engine that wraps the local vector store."""

from __future__ import annotations

import logging

from ..core.models import RetrievalResult
from ..data.vector_store import LocalVectorStore

logger = logging.getLogger(__name__)


class RetrievalEngine:
    """Delegates vector similarity search to a local vector store."""

    def __init__(self, vector_store: LocalVectorStore) -> None:
        self._vector_store = vector_store

    def search(self, npc_id: str, question: str) -> RetrievalResult:
        logger.debug("Retrieval requested for NPC '%s' question='%s'", npc_id, question)
        return self._vector_store.search(npc_id, question)
