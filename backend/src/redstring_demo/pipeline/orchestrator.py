"""End-to-end orchestration for the hybrid retrieval + RAG pipeline."""

from __future__ import annotations

import logging
from typing import Iterable, List, Optional, Tuple

from ..core.models import LLMResponse, PipelineOutput, PlayerQuery, RetrievalHitType
from ..services.cache import InMemoryCache
from ..services.llm import LocalLLMService
from ..services.rag import RAGContextBuilder
from ..services.retrieval import RetrievalEngine
from ..services.tts import TurboTTSStub
from ..services.warmup import WarmupManager

logger = logging.getLogger(__name__)


class HybridDialogueOrchestrator:
    """Coordinates fallback layers and caching for NPC interactions."""

    def __init__(
        self,
        warmup_manager: WarmupManager,
        retrieval_engine: RetrievalEngine,
        rag_builder: RAGContextBuilder,
        llm_service: LocalLLMService,
        tts_service: TurboTTSStub,
        cache: Optional[InMemoryCache] = None,
        unusual_ttl: float = 600.0,
    ) -> None:
        self._warmup = warmup_manager
        self._retrieval = retrieval_engine
        self._rag_builder = rag_builder
        self._llm = llm_service
        self._tts = tts_service
        self._cache = cache or InMemoryCache(default_ttl=unusual_ttl)
        self._unusual_ttl = unusual_ttl

    def handle_query(self, query: PlayerQuery, tts_enabled: bool = True) -> PipelineOutput:
        logger.debug("Handling query for NPC '%s': %s", query.npc_id, query.player_question)
        warmup_status = self._warmup.handle(query, self._llm.is_ready())
        if not warmup_status.is_llm_ready:
            logger.debug("LLM not ready; returning warm-up line for NPC '%s'", query.npc_id)
            return PipelineOutput(
                text=warmup_status.preset_dialogue or "",
                source="preset_dialogue",
                warmup=warmup_status,
                audio=None,
                similarity=None,
                cached=False,
                spinner_message="AI model spinning up..." if warmup_status.show_spinner else None,
            )

        cache_key = self._cache_key(query)
        cached_entry = self._cache.get(cache_key)
        if cached_entry:
            logger.debug("Cache hit for NPC '%s' question '%s'", query.npc_id, query.player_question)
            audio = self._tts.maybe_synthesize(cached_entry.value, tts_enabled)
            spinner = "AI is speaking" if audio else None
            source = cached_entry.metadata.get("source", "cache")
            similarity = cached_entry.metadata.get("similarity")
            return PipelineOutput(
                text=cached_entry.value,
                source=source,
                warmup=warmup_status,
                audio=audio,
                similarity=similarity,
                cached=True,
                spinner_message=spinner,
            )

        retrieval_result = self._retrieval.search(query.npc_id, query.player_question)
        logger.debug(
            "Retrieval outcome for NPC '%s': type=%s similarity=%.3f",
            query.npc_id,
            retrieval_result.hit_type,
            retrieval_result.similarity,
        )
        if retrieval_result.hit_type == RetrievalHitType.EXACT and retrieval_result.response_text:
            text = retrieval_result.response_text
            source = "retrieval_exact"
            similarity = retrieval_result.similarity
        elif retrieval_result.hit_type == RetrievalHitType.FUZZY and retrieval_result.response_text:
            llm_response = self._llm.rephrase(query, retrieval_result.response_text)
            text = llm_response.text
            source = "retrieval_fuzzy"
            similarity = retrieval_result.similarity
        else:
            logger.debug("Falling back to RAG + LLM for NPC '%s'", query.npc_id)
            llm_response = self._generate_with_rag(query, [])
            text = llm_response.text
            source = "llm_rag"
            similarity = retrieval_result.similarity if retrieval_result.similarity else 0.0
            self._cache.set(cache_key, text, ttl=self._unusual_ttl, source=source, similarity=similarity)

        audio = self._tts.maybe_synthesize(text, tts_enabled)
        spinner_message = "AI is speaking" if audio else None
        return PipelineOutput(
            text=text,
            source=source,
            warmup=warmup_status,
            audio=audio,
            similarity=similarity,
            cached=False,
            spinner_message=spinner_message,
        )

    def process_queued_queries(self, tts_enabled: bool = True) -> List[PipelineOutput]:
        queued = self._warmup.drain_queue()
        logger.debug("Processing %d queued queries", len(queued))
        outputs: List[PipelineOutput] = []
        for queued_query in queued:
            outputs.append(self.handle_query(queued_query, tts_enabled=tts_enabled))
        return outputs

    def queued_query_count(self) -> int:
        return len(self._warmup.queued_queries())

    def _generate_with_rag(self, query: PlayerQuery, retrieved_snippets: Iterable[str]) -> LLMResponse:
        context = self._rag_builder.build_context(query, retrieved_snippets)
        logger.debug("Invoking LLM generate for NPC '%s'", query.npc_id)
        return self._llm.generate(query, context)

    @staticmethod
    def _cache_key(query: PlayerQuery) -> Tuple[str, str, str]:
        return (query.save_id, query.npc_id, query.player_question.lower())
