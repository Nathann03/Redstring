"""Structured LLM generation for RedString dialogue."""

from __future__ import annotations

import json
import logging
import re
from typing import Iterable, List

from ..core.embeddings import SimpleEmbeddingModel
from ..core.models import CharacterInfo, DialogueRequest, GeneratedDialogue, LlamaGenerationConfig

logger = logging.getLogger(__name__)
JSON_OBJECT_PATTERN = re.compile(r"\{.*\}", re.DOTALL)


class LocalLLMService:
    """Grounded local generation with optional llama.cpp inference."""

    def __init__(self) -> None:
        self._embedding_model = SimpleEmbeddingModel()
        self._ready = False

    def spin_up(self) -> None:
        self._ready = True

    def is_ready(self) -> bool:
        return self._ready

    def generate(self, request: DialogueRequest, suggested_clues: List[str] | None = None) -> GeneratedDialogue:
        facts = self._select_supporting_facts(request.character_info, request.player_question, request.evidence_id)
        response = self._compose_grounded_response(request.character_info, request.player_question, facts)
        reasoning = {"supporting_facts": facts, "mode": "deterministic"}
        return GeneratedDialogue(response=response, clues_unlocked=list(suggested_clues or []), reasoning=reasoning)

    def grounded_facts(self, character_info: CharacterInfo) -> List[str]:
        return _grounding_facts(character_info)

    def _select_supporting_facts(
        self,
        character_info: CharacterInfo,
        question: str,
        evidence_id: str | None = None,
        limit: int = 2,
    ) -> List[str]:
        pool = _grounding_facts(character_info)
        if evidence_id and evidence_id in character_info.evidence_knowledge:
            pool = [character_info.evidence_knowledge[evidence_id], *pool]
        query_embedding = self._embedding_model.embed(question)
        ranked = sorted(
            pool,
            key=lambda fact: self._embedding_model.cosine_similarity(
                query_embedding,
                self._embedding_model.embed(fact),
            ),
            reverse=True,
        )
        selected = [fact for fact in ranked[:limit] if fact]
        return selected or [character_info.knowledge_base.relationship_to_victim or character_info.knowledge_base.alibi]

    def _compose_grounded_response(self, character_info: CharacterInfo, question: str, facts: List[str]) -> str:
        lead = facts[0] if facts else character_info.knowledge_base.alibi
        follow_up = facts[1] if len(facts) > 1 else ""
        lowered = question.lower()

        if character_info.character_id == "james_okoye":
            response = f"Technically, {lead.lower()}."
            if "motive" in lowered or "argument" in lowered:
                response += f" {follow_up or 'Morgan and I did argue over publication credit, but that does not make me a killer.'}"
            return response

        if character_info.character_id == "catch_wallace":
            response = f"I'll be plain: {lead.lower()}."
            if "morgan" in lowered or "threat" in lowered:
                response += f" {follow_up or 'I was angry about the fishing fallout, but I never meant Morgan harm.'}"
            return response

        if character_info.character_id == "yuki_tanaka":
            response = f"My position is straightforward: {lead.lower()}."
            if "data" in lowered or "motive" in lowered:
                response += f" {follow_up or 'Any disagreement with Morgan was professional.'}"
            return response

        if character_info.character_id == "riley_chen":
            response = f"Um, sorry, but {lead.lower()}."
            if "yuki" in lowered or "hear" in lowered:
                response += f" {follow_up or 'I did overhear arguments between Morgan and Yuki before all this.'}"
            return response

        parts = [lead]
        if follow_up:
            parts.append(follow_up)
        return " ".join(parts)


class LlamaCppLLMService(LocalLLMService):
    """Use llama.cpp when a local quantized model is available."""

    def __init__(self, config: LlamaGenerationConfig) -> None:
        super().__init__()
        self._config = config
        self._llm: object | None = None

    def spin_up(self) -> None:
        if self._llm is not None:
            self._ready = True
            return
        try:
            from llama_cpp import Llama  # type: ignore
        except ImportError as exc:  # pragma: no cover
            raise RuntimeError(
                "llama-cpp-python is not installed. Install backend/requirements-llm.txt."
            ) from exc
        self._llm = Llama(
            model_path=self._config.model_path,
            n_ctx=self._config.n_ctx,
            n_threads=self._config.n_threads,
        )
        self._ready = True

    def generate(self, request: DialogueRequest, suggested_clues: List[str] | None = None) -> GeneratedDialogue:
        if self._llm is None:
            return super().generate(request, suggested_clues)

        prompt = self._build_prompt(request, suggested_clues or [])
        logger.info("route=llm mode=llama character_id=%s", request.character_info.character_id)
        completion = self._llm.create_completion(  # type: ignore[attr-defined]
            prompt=prompt,
            max_tokens=self._config.max_tokens,
            temperature=self._config.temperature,
            top_p=self._config.top_p,
            stop=["###"],
        )
        text = completion["choices"][0]["text"].strip()
        payload = self._parse_model_payload(text)
        if payload is None:
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_invalid_json", "raw_text": text},
            )

        response = str(payload.get("response", "")).strip()
        clues_raw = payload.get("clues_unlocked", [])
        if not isinstance(clues_raw, list) or not all(isinstance(item, str) for item in clues_raw):
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_invalid_clue_array", "raw_text": text},
            )

        if not response:
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_empty_response"},
            )

        return GeneratedDialogue(
            response=response,
            clues_unlocked=[str(item) for item in clues_raw],
            reasoning={"mode": "llama", "prompt": prompt},
        )

    def _build_prompt(self, request: DialogueRequest, suggested_clues: List[str]) -> str:
        character = request.character_info
        allowed_evidence = "\n".join(
            f"- {clue_id}: {description}"
            for clue_id, description in character.evidence_knowledge.items()
        ) or "- None"
        guidelines = "\n".join(f"- {item}" for item in character.behavior_guidelines) or "- None"
        truths = "\n".join(f"- {item}" for item in character.knowledge_base.truth) or "- None"
        others = "\n".join(f"- {item}" for item in character.knowledge_base.knows_about_others) or "- None"
        admissions = "\n".join(f"- {item}" for item in character.knowledge_base.will_admit_when_pressed) or "- None"
        return (
            "### System\n"
            "You are generating detective-game NPC dialogue.\n"
            "Return JSON only with keys response and clues_unlocked.\n"
            "Keep response to 1-2 sentences.\n"
            "Use only the supplied facts.\n"
            "Do not invent clues.\n"
            "### Personality\n"
            f"{character.personality_prompt}\n"
            "### Behavior Guidelines\n"
            f"{guidelines}\n"
            "### Relationship To Victim\n"
            f"{character.knowledge_base.relationship_to_victim}\n"
            "### Alibi\n"
            f"{character.knowledge_base.alibi}\n"
            "### Truth\n"
            f"{truths}\n"
            "### Will Admit When Pressed\n"
            f"{admissions}\n"
            "### Knows About Others\n"
            f"{others}\n"
            "### Allowed Evidence Knowledge\n"
            f"{allowed_evidence}\n"
            "### Suggested Clues\n"
            f"{json.dumps(suggested_clues)}\n"
            "### Found Clues\n"
            f"{json.dumps(request.game_state.found_clues)}\n"
            "### Current Evidence\n"
            f"{json.dumps(request.evidence_id)}\n"
            "### Asked Questions\n"
            f"{json.dumps(request.game_state.asked_questions)}\n"
            "### Player Question\n"
            f"{request.player_question}\n"
            "### Response JSON\n"
        )

    @staticmethod
    def _parse_model_payload(raw_text: str) -> dict[str, object] | None:
        candidate = raw_text.strip()
        if not candidate:
            return None
        try:
            parsed = json.loads(candidate)
        except (json.JSONDecodeError, TypeError, ValueError):
            match = JSON_OBJECT_PATTERN.search(candidate)
            if not match:
                return None
            try:
                parsed = json.loads(match.group(0))
            except (json.JSONDecodeError, TypeError, ValueError):
                return None
        if not isinstance(parsed, dict):
            return None
        if set(parsed.keys()) != {"response", "clues_unlocked"}:
            return None
        return parsed


def _grounding_facts(character_info: CharacterInfo) -> List[str]:
    knowledge = character_info.knowledge_base
    facts: List[str] = [knowledge.alibi, knowledge.relationship_to_victim]
    facts.extend(knowledge.truth)
    facts.extend(knowledge.will_admit_when_pressed)
    facts.extend(knowledge.knows_about_others)
    facts.extend(character_info.evidence_knowledge.values())
    return [fact for fact in facts if fact]
