"""Local vector store seeded from the dialogue dataset."""

from __future__ import annotations

import logging
from typing import Dict, Iterable, List, Optional

from ..core.embeddings import SimpleEmbeddingModel
from ..core.models import RetrievalHitType, RetrievalResult

logger = logging.getLogger(__name__)


class LocalVectorStore:
    """In-memory vector store for pregenerated responses."""

    def __init__(
        self,
        embedding_model: SimpleEmbeddingModel,
        responses: Iterable[Dict[str, object]],
        exact_threshold: float = 0.9,
        fuzzy_threshold: float = 0.7,
    ) -> None:
        self._embedding_model = embedding_model
        self._exact_threshold = exact_threshold
        self._fuzzy_threshold = fuzzy_threshold
        self._store: Dict[str, List[Dict[str, object]]] = {}
        self.seed(responses)

    def seed(self, responses: Iterable[Dict[str, object]]) -> None:
        self._store.clear()
        for response in responses:
            npc_id = str(response["npc_id"])
            entry = {
                "npc_id": npc_id,
                "text": response["text"],
                "source_id": response["source_id"],
                "embedding": self._embedding_model.embed(str(response["embedding_text"])),
                "metadata": {"tags": ",".join(response.get("tags", []))},
            }
            self._store.setdefault(npc_id, []).append(entry)
        logger.debug("Vector store seeded with %d NPCs", len(self._store))

    def search(self, npc_id: str, question: str) -> RetrievalResult:
        options = self._store.get(npc_id, [])
        if not options:
            logger.debug("Vector store miss: NPC '%s' has no entries", npc_id)
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)
        query_embedding = self._embedding_model.embed(question)
        if not query_embedding:
            logger.debug("Vector store miss: empty embedding for question '%s'", question)
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)

        best_entry: Optional[Dict[str, object]] = None
        best_similarity = 0.0
        for entry in options:
            similarity = self._embedding_model.cosine_similarity(query_embedding, entry["embedding"])
            if similarity > best_similarity:
                best_similarity = similarity
                best_entry = entry

        if not best_entry:
            logger.debug("Vector store miss: no best entry found for NPC '%s'", npc_id)
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)

        if best_similarity >= self._exact_threshold:
            hit_type = RetrievalHitType.EXACT
        elif best_similarity >= self._fuzzy_threshold:
            hit_type = RetrievalHitType.FUZZY
        else:
            hit_type = RetrievalHitType.MISS

        logger.debug(
            "Vector store result: npc=%s similarity=%.3f hit_type=%s", npc_id, best_similarity, hit_type
        )
        return RetrievalResult(
            hit_type=hit_type,
            similarity=best_similarity,
            response_text=best_entry["text"] if hit_type != RetrievalHitType.MISS else None,
            source_id=best_entry["source_id"] if hit_type != RetrievalHitType.MISS else None,
            metadata=best_entry["metadata"] if hit_type != RetrievalHitType.MISS else {},
        )
