"""Semantic retrieval over pregenerated NPC dialogue."""

from __future__ import annotations

import logging
from typing import Dict, List

from ..core.embeddings import SimpleEmbeddingModel
from ..core.models import PregeneratedDialogue, RetrievalHitType, RetrievalResult

logger = logging.getLogger(__name__)


class RetrievalEngine:
    """Find the closest pregenerated response for an NPC."""

    def __init__(
        self,
        records_by_character: Dict[str, List[PregeneratedDialogue]],
        threshold: float = 0.72,
    ) -> None:
        self._embedding_model = SimpleEmbeddingModel()
        self._threshold = threshold
        self._records_by_character = records_by_character
        self._embeddings: Dict[str, List[Dict[str, object]]] = {}
        for character_id, records in records_by_character.items():
            self._embeddings[character_id] = [
                {
                    "record": record,
                    "embedding": self._embedding_model.embed(record.embedding_text),
                }
                for record in records
            ]

    def search(self, character_id: str, question: str, evidence_id: str | None = None) -> RetrievalResult:
        if evidence_id:
            direct_hit = self._direct_evidence_hit(character_id, evidence_id)
            if direct_hit is not None:
                return direct_hit

        query_embedding = self._embedding_model.embed(question)
        if not query_embedding:
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)

        best_similarity = 0.0
        best_record: PregeneratedDialogue | None = None
        for entry in self._embeddings.get(character_id, []):
            similarity = self._embedding_model.cosine_similarity(query_embedding, entry["embedding"])
            if similarity > best_similarity:
                best_similarity = similarity
                best_record = entry["record"]

        if not best_record or best_similarity < self._threshold:
            logger.info("route=retrieval outcome=miss character_id=%s similarity=%.3f", character_id, best_similarity)
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=best_similarity)

        logger.info(
            "route=retrieval outcome=hit character_id=%s similarity=%.3f source_id=%s",
            character_id,
            best_similarity,
            best_record.source_id,
        )
        return RetrievalResult(
            hit_type=RetrievalHitType.HIT,
            similarity=best_similarity,
            response_text=best_record.text,
            source_id=best_record.source_id,
            clues=list(best_record.clues),
            metadata={"tags": list(best_record.tags)},
        )

    def _direct_evidence_hit(self, character_id: str, evidence_id: str) -> RetrievalResult | None:
        for entry in self._embeddings.get(character_id, []):
            record = entry["record"]
            if record.evidence_id != evidence_id:
                continue
            logger.info(
                "route=retrieval outcome=direct_evidence_hit character_id=%s evidence_id=%s source_id=%s",
                character_id,
                evidence_id,
                record.source_id,
            )
            return RetrievalResult(
                hit_type=RetrievalHitType.HIT,
                similarity=1.0,
                response_text=record.text,
                source_id=record.source_id,
                clues=list(record.clues),
                metadata={"tags": list(record.tags), "evidence_id": evidence_id},
            )
        return None
