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
        evidence_threshold: float = 0.5,
    ) -> None:
        self._embedding_model = SimpleEmbeddingModel()
        self._threshold = threshold
        self._evidence_threshold = evidence_threshold
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
        query_embedding = self._embedding_model.embed(question)
        if not query_embedding:
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)

        if evidence_id:
            evidence_hit = self._best_similarity_hit(
                character_id,
                query_embedding,
                threshold=self._evidence_threshold,
                evidence_id=evidence_id,
            )
            if evidence_hit is not None:
                return evidence_hit
            logger.info(
                "route=retrieval outcome=evidence_filtered_miss character_id=%s evidence_id=%s",
                character_id,
                evidence_id,
            )
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)

        best_hit = self._best_similarity_hit(
            character_id,
            query_embedding,
            threshold=self._threshold,
        )
        if best_hit is None:
            logger.info("route=retrieval outcome=miss character_id=%s similarity=%.3f", character_id, 0.0)
            return RetrievalResult(hit_type=RetrievalHitType.MISS, similarity=0.0)

        return best_hit

    def _best_similarity_hit(
        self,
        character_id: str,
        query_embedding: Dict[str, float],
        threshold: float,
        evidence_id: str | None = None,
    ) -> RetrievalResult | None:
        best_similarity = 0.0
        best_record: PregeneratedDialogue | None = None
        for entry in self._embeddings.get(character_id, []):
            record = entry["record"]
            if evidence_id and record.evidence_id != evidence_id:
                continue
            similarity = self._embedding_model.cosine_similarity(query_embedding, entry["embedding"])
            if similarity > best_similarity:
                best_similarity = similarity
                best_record = record

        if not best_record or best_similarity < threshold:
            return None

        logger.info(
            "route=retrieval outcome=hit character_id=%s similarity=%.3f source_id=%s evidence_id=%s",
            character_id,
            best_similarity,
            best_record.source_id,
            evidence_id,
        )
        return RetrievalResult(
            hit_type=RetrievalHitType.HIT,
            similarity=best_similarity,
            response_text=best_record.text,
            source_id=best_record.source_id,
            clues=list(best_record.clues),
            metadata={"tags": list(best_record.tags), "evidence_id": evidence_id},
        )
