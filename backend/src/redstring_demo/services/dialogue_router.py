"""Top-level dialogue routing for retrieval, LLM fallback, and confession override."""

from __future__ import annotations

import logging
import re
import time
from dataclasses import dataclass
from typing import Iterable, List

from ..core.models import CharacterInfo, DialogueRequest, DialogueResponse, GeneratedDialogue, RetrievalHitType
from .clue_extractor import ClueExtractor
from .llm_service import GeminiLLMService, LocalLLMService
from .retrieval_engine import RetrievalEngine
from .validator import DialogueValidator

logger = logging.getLogger(__name__)
EVIDENCE_ID_PATTERN = re.compile(r"EVID_\d+")


@dataclass
class DialogueRouter:
    """Hybrid router: confession -> retrieval -> LLM fallback."""

    retrieval_engine: RetrievalEngine
    llm_service: LocalLLMService
    gemini_service: GeminiLLMService
    clue_extractor: ClueExtractor
    validator: DialogueValidator

    def route(self, request: DialogueRequest) -> DialogueResponse:
        started = time.perf_counter()
        character = request.character_info

        confession_response = self._confession_if_ready(character, request.game_state.found_clues)
        if confession_response:
            latency_ms = (time.perf_counter() - started) * 1000
            logger.info("route=confession character_id=%s latency_ms=%.2f", character.character_id, latency_ms)
            return DialogueResponse(
                response=confession_response,
                clues_unlocked=[],
                route="confession",
                latency_ms=latency_ms,
                confession=True,
            )

        retrieval = self.retrieval_engine.search(
            character.character_id,
            request.player_question,
            evidence_id=request.evidence_id,
        )
        if retrieval.hit_type == RetrievalHitType.HIT and retrieval.response_text:
            clues = self.validator.validate_clues(
                character,
                request.game_state,
                self.clue_extractor.extract(character, request.player_question, request.game_state, retrieval.clues),
            )
            latency_ms = (time.perf_counter() - started) * 1000
            logger.info("route=retrieval character_id=%s latency_ms=%.2f", character.character_id, latency_ms)
            return DialogueResponse(
                response=retrieval.response_text,
                clues_unlocked=clues,
                route="retrieval",
                latency_ms=latency_ms,
            )

        suggested_clues = self.clue_extractor.extract(character, request.player_question, request.game_state)
        generated, route_name = self._generate_dialogue(request, suggested_clues)
        fallback_text = self.llm_service.generate(request, suggested_clues=[]).response
        response_text = self.validator.sanitize_response(
            generated.response,
            fallback_text=fallback_text,
            grounding_facts=self.llm_service.grounded_facts(character),
        )
        clues = self.validator.validate_clues(
            character,
            request.game_state,
            generated.clues_unlocked,
        )
        latency_ms = (time.perf_counter() - started) * 1000
        logger.info("route=%s character_id=%s latency_ms=%.2f", route_name, character.character_id, latency_ms)
        return DialogueResponse(
            response=response_text,
            clues_unlocked=clues,
            route=route_name,
            latency_ms=latency_ms,
        )

    def handle_query(self, request: DialogueRequest) -> DialogueResponse:
        return self.route(request)

    def _generate_dialogue(self, request: DialogueRequest, suggested_clues: List[str]) -> tuple[GeneratedDialogue, str]:
        backend = (request.generation_backend or "auto").lower()

        if backend == "gemini":
            generated = self.gemini_service.generate(request, suggested_clues=suggested_clues)
            return generated, "gemini"

        if backend == "local":
            generated = self.llm_service.generate(request, suggested_clues=suggested_clues)
            return generated, "llm"

        if self.gemini_service.is_available() and not self.llm_service.is_ready():
            generated = self.gemini_service.generate(request, suggested_clues=suggested_clues)
            return generated, "gemini"

        generated = self.llm_service.generate(request, suggested_clues=suggested_clues)
        return generated, "llm"

    @staticmethod
    def _confession_if_ready(character_info: CharacterInfo, found_clues: Iterable[str]) -> str | None:
        if not character_info.confession_trigger:
            return None
        required = {
            clue_id
            for item in character_info.confession_trigger
            for clue_id in EVIDENCE_ID_PATTERN.findall(item.upper())
        }
        if not required or not required.issubset(set(found_clues)):
            return None

        if character_info.character_id == "yuki_tanaka":
            return (
                "Fine. Morgan would not alter the data, and that made them a liability. "
                "I removed the problem, and I want counsel before I say anything else."
            )
        return (
            f"{character_info.name} breaks composure and admits the truth. "
            "They ask for a lawyer before continuing."
        )
