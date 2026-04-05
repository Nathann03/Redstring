"""Structured LLM generation for RedString dialogue."""

from __future__ import annotations

import json
import logging
import re
from typing import Iterable, List, Sequence

import requests

from ..core.embeddings import SimpleEmbeddingModel
from ..core.models import CharacterInfo, DialogueRequest, GeneratedDialogue, LlamaGenerationConfig

logger = logging.getLogger(__name__)
JSON_OBJECT_PATTERN = re.compile(r"\{.*\}", re.DOTALL)
GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"
OPENROUTER_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
GAME_BACKGROUND = (
    "RedString is a 2D detective game set in a stormy lighthouse research facility. "
    "The player investigates the murder of Morgan Blackwell and is trying to determine the killer, "
    "the weapon, and the crime scene location. The current canonical solution is Yuki Tanaka with the "
    "missing wrench in the tidal pool lab, but you must only reveal information that this NPC would truthfully "
    "know, suspect, admit under pressure, or confess after the confession trigger. Stay grounded in the provided "
    "evidence and character knowledge. Never speak as the narrator or game system."
)
CASE_RELATED_HINTS = (
    "morgan",
    "murder",
    "kill",
    "killed",
    "alibi",
    "evidence",
    "clue",
    "weapon",
    "suspect",
    "crime",
    "scene",
    "lab",
    "wrench",
    "jacket",
    "rope",
    "wire",
    "vial",
    "letter opener",
    "where were",
    "who was",
    "why were",
    "did you",
    "what happened",
)
AMBIENT_HINTS = (
    "favorite",
    "ice cream",
    "food",
    "music",
    "movie",
    "color",
    "hobby",
    "weather",
    "what day",
    "what time",
    "how are you",
    "weekend",
    "birthday",
    "family",
    "vacation",
    "where are you from",
)


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
        if not is_case_related_question(request.player_question, request.evidence_id):
            response = self._compose_ambient_fallback_response(request.character_info)
            reasoning = {"mode": "deterministic_ambient_fallback"}
            return GeneratedDialogue(response=response, clues_unlocked=[], reasoning=reasoning)
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

    @staticmethod
    def _compose_ambient_fallback_response(character_info: CharacterInfo) -> str:
        if character_info.character_id == "james_okoye":
            return "James gives a tired shrug and answers with dry patience, sounding more human than guarded for a moment."
        if character_info.character_id == "catch_wallace":
            return "Catch grunts, then gives you a rough but genuine answer instead of another argument."
        if character_info.character_id == "yuki_tanaka":
            return "Yuki pauses, then answers in a clipped, controlled way that still sounds like a real preference."
        if character_info.character_id == "riley_chen":
            return "Riley looks relieved to be asked something normal and answers with an awkward, honest little smile."
        return "The NPC answers casually, if a little wearily."


def is_case_related_question(question: str, evidence_id: str | None = None) -> bool:
    lowered = question.lower().strip()
    if not lowered:
        return False
    if any(hint in lowered for hint in CASE_RELATED_HINTS) or "evid_" in lowered:
        return True
    if evidence_id:
        return not any(hint in lowered for hint in AMBIENT_HINTS)
    return False


class GeminiLLMService(LocalLLMService):
    """Gemini-backed generation used as a remote fallback or explicit bypass target."""

    def __init__(self, api_key: str = "", model: str = "gemini-3-flash-preview") -> None:
        super().__init__()
        self._api_key = api_key
        self._model = model

    def is_available(self) -> bool:
        return bool(self._api_key and self._model)

    def generate(self, request: DialogueRequest, suggested_clues: List[str] | None = None) -> GeneratedDialogue:
        if not self.is_available():
            raise RuntimeError("Gemini generation requested but REDSTRING_GEMINI_API_KEY is not configured")

        system_prompt, user_prompt = _build_generation_prompts(request, suggested_clues or [])
        try:
            response = requests.post(
                GEMINI_ENDPOINT.format(model=self._model),
                params={"key": self._api_key},
                headers={"Content-Type": "application/json"},
                json={
                    "systemInstruction": {"parts": [{"text": system_prompt}]},
                    "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
                    "generationConfig": {
                        "temperature": 0.25,
                        "topP": 0.9,
                        "maxOutputTokens": 160,
                        "responseMimeType": "application/json",
                    },
                },
                timeout=30,
            )
            response.raise_for_status()
            raw_text = _extract_candidate_text(response.json())
        except requests.RequestException as exc:
            logger.warning("Gemini request failed: %s", exc)
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_gemini_request_error", "error": str(exc)},
            )

        payload = _parse_model_payload(raw_text)
        if payload is None:
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_gemini_invalid_json", "raw_text": raw_text},
            )

        response_text = str(payload.get("response", "")).strip()
        clues_raw = payload.get("clues_unlocked", [])
        if not isinstance(clues_raw, list) or not all(isinstance(item, str) for item in clues_raw):
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_gemini_invalid_clue_array", "raw_text": raw_text},
            )
        if not response_text:
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": "fallback_from_gemini_empty_response", "raw_text": raw_text},
            )

        return GeneratedDialogue(
            response=response_text,
            clues_unlocked=[str(item) for item in clues_raw],
            reasoning={"mode": "gemini", "model": self._model, "system_prompt": system_prompt, "user_prompt": user_prompt},
        )


class HostedChatLLMService(LocalLLMService):
    """Shared helpers for hosted chat-completion style providers."""

    provider_name = "hosted"

    def __init__(self, api_key: str = "", model: str = "") -> None:
        super().__init__()
        self._api_key = api_key
        self._model = model

    def is_available(self) -> bool:
        return bool(self._api_key and self._model)

    def generate(self, request: DialogueRequest, suggested_clues: List[str] | None = None) -> GeneratedDialogue:
        if not self.is_available():
            raise RuntimeError(f"{self.provider_name} generation requested but API key is not configured")

        system_prompt, user_prompt = _build_generation_prompts(request, suggested_clues or [])
        try:
            raw_text = self._request_text(system_prompt, user_prompt)
        except requests.RequestException as exc:
            logger.warning("%s request failed: %s", self.provider_name.capitalize(), exc)
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": f"fallback_from_{self.provider_name}_request_error", "error": str(exc)},
            )

        payload = _parse_model_payload(raw_text)
        if payload is None:
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": f"fallback_from_{self.provider_name}_invalid_json", "raw_text": raw_text},
            )

        response_text = str(payload.get("response", "")).strip()
        clues_raw = payload.get("clues_unlocked", [])
        if not isinstance(clues_raw, list) or not all(isinstance(item, str) for item in clues_raw):
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": f"fallback_from_{self.provider_name}_invalid_clue_array", "raw_text": raw_text},
            )
        if not response_text:
            fallback = super().generate(request, suggested_clues)
            return GeneratedDialogue(
                response=fallback.response,
                clues_unlocked=fallback.clues_unlocked,
                reasoning={"mode": f"fallback_from_{self.provider_name}_empty_response", "raw_text": raw_text},
            )

        return GeneratedDialogue(
            response=response_text,
            clues_unlocked=[str(item) for item in clues_raw],
            reasoning={"mode": self.provider_name, "model": self._model, "system_prompt": system_prompt, "user_prompt": user_prompt},
        )

    def _request_text(self, system_prompt: str, user_prompt: str) -> str:
        raise NotImplementedError


class GroqLLMService(HostedChatLLMService):
    provider_name = "groq"

    def _request_text(self, system_prompt: str, user_prompt: str) -> str:
        response = requests.post(
            GROQ_ENDPOINT,
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": self._model,
                "temperature": 0.25,
                "top_p": 0.9,
                "max_tokens": 160,
                "response_format": {"type": "json_object"},
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
            },
            timeout=30,
        )
        response.raise_for_status()
        payload = response.json()
        return _extract_openai_candidate_text(payload)


class OpenRouterLLMService(HostedChatLLMService):
    provider_name = "openrouter"

    def _request_text(self, system_prompt: str, user_prompt: str) -> str:
        response = requests.post(
            OPENROUTER_ENDPOINT,
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": self._model,
                "temperature": 0.25,
                "top_p": 0.9,
                "max_tokens": 160,
                "response_format": {"type": "json_object"},
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
            },
            timeout=30,
        )
        response.raise_for_status()
        payload = response.json()
        return _extract_openai_candidate_text(payload)


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

        system_prompt, user_prompt = _build_generation_prompts(request, suggested_clues or [])
        prompt = (
            "### System\n"
            f"{system_prompt}\n"
            "### User\n"
            f"{user_prompt}\n"
            "### Response JSON\n"
        )
        logger.info("route=llm mode=llama character_id=%s", request.character_info.character_id)
        completion = self._llm.create_completion(  # type: ignore[attr-defined]
            prompt=prompt,
            max_tokens=self._config.max_tokens,
            temperature=self._config.temperature,
            top_p=self._config.top_p,
            stop=["###"],
        )
        text = completion["choices"][0]["text"].strip()
        payload = _parse_model_payload(text)
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
            reasoning={"mode": "llama", "system_prompt": system_prompt, "user_prompt": user_prompt},
        )


def _build_generation_prompts(request: DialogueRequest, suggested_clues: Sequence[str]) -> tuple[str, str]:
    character = request.character_info
    knowledge = character.knowledge_base
    evidence_knowledge = "\n".join(
        f"- {clue_id}: {description}" for clue_id, description in character.evidence_knowledge.items()
    ) or "- None"
    behavior_guidelines = "\n".join(f"- {item}" for item in character.behavior_guidelines) or "- None"
    truths = "\n".join(f"- {item}" for item in knowledge.truth) or "- None"
    admissions = "\n".join(f"- {item}" for item in knowledge.will_admit_when_pressed) or "- None"
    hard_denials = "\n".join(f"- {item}" for item in knowledge.will_never_admit) or "- None"
    others = "\n".join(f"- {item}" for item in knowledge.knows_about_others) or "- None"
    confession_trigger = "\n".join(f"- {item}" for item in character.confession_trigger) or "- None"

    system_prompt = (
        f"{GAME_BACKGROUND}\n\n"
        "You are generating one NPC dialogue turn for the interrogation system.\n"
        "Stay fully in character. Keep the answer grounded, concise, and emotionally consistent with the NPC.\n"
        "The response must be 1-2 sentences.\n"
        "If the player asks about the investigation, do not invent facts, clues, locations, timelines, or motives beyond the supplied context.\n"
        "If the player asks an ordinary small-talk or personal question that is not about the case, answer naturally in character.\n"
        "For those non-investigation questions, you may improvise harmless everyday preferences, mood, habits, opinions, or observations that fit the NPC's personality and situation.\n"
        "Do not force evidence, clues, or murder details into a small-talk answer unless the player is actually asking about the case.\n"
        "If the player asks something outside this NPC's knowledge, answer narrowly, deflect, or admit uncertainty while staying in character.\n"
        "Return JSON only with exactly two keys: response and clues_unlocked.\n"
        "clues_unlocked must be a JSON array of evidence ids and may only include ids from Allowed Evidence Knowledge.\n"
        "Do not reveal the hidden solution unless this NPC would truthfully know it and the supplied confession/evidence state makes that admission appropriate."
    )

    user_prompt = (
        "Game Context:\n"
        f"- Objective: Determine the suspect, weapon, and location of Morgan Blackwell's murder.\n"
        f"- Player is currently questioning NPC id {character.character_id}.\n"
        f"- NPC name: {character.name}\n"
        f"- NPC age: {character.age}\n"
        f"- NPC occupation: {character.occupation}\n"
        f"- NPC current location: {character.location}\n"
        f"- Requested generation backend: {request.generation_backend or 'auto'}\n\n"
        "NPC Roleplay Profile:\n"
        f"- Personality prompt: {character.personality_prompt}\n"
        f"- Relationship to Morgan Blackwell: {knowledge.relationship_to_victim}\n"
        f"- Alibi: {knowledge.alibi}\n\n"
        "Behavior Guidelines:\n"
        f"{behavior_guidelines}\n\n"
        "Facts This NPC Knows Are True:\n"
        f"{truths}\n\n"
        "Facts This NPC Might Admit Under Pressure:\n"
        f"{admissions}\n\n"
        "Facts This NPC Refuses To Admit Early:\n"
        f"{hard_denials}\n\n"
        "What This NPC Knows About Other Characters:\n"
        f"{others}\n\n"
        "Allowed Evidence Knowledge:\n"
        f"{evidence_knowledge}\n\n"
        "Confession Trigger:\n"
        f"{confession_trigger}\n\n"
        "Current Conversation State:\n"
        f"- Presented evidence id: {json.dumps(request.evidence_id)}\n"
        f"- Found clues: {json.dumps(request.game_state.found_clues)}\n"
        f"- Asked questions so far: {json.dumps(request.game_state.asked_questions)}\n"
        f"- Active NPC in game state: {json.dumps(request.game_state.npc_id)}\n"
        f"- Suggested clues if warranted: {json.dumps(list(suggested_clues))}\n\n"
        f"Player Question:\n{request.player_question}\n\n"
        'Respond as JSON like {"response":"...", "clues_unlocked":["EVID_XX"]}.'
    )
    return system_prompt, user_prompt


def _extract_candidate_text(payload: dict[str, object]) -> str:
    candidates = payload.get("candidates", [])
    if not isinstance(candidates, list) or not candidates:
        return ""
    first = candidates[0]
    if not isinstance(first, dict):
        return ""
    content = first.get("content", {})
    if not isinstance(content, dict):
        return ""
    parts = content.get("parts", [])
    if not isinstance(parts, list):
        return ""
    chunks: List[str] = []
    for part in parts:
        if isinstance(part, dict) and isinstance(part.get("text"), str):
            chunks.append(str(part["text"]))
    return "\n".join(chunks).strip()


def _extract_openai_candidate_text(payload: dict[str, object]) -> str:
    choices = payload.get("choices", [])
    if not isinstance(choices, list) or not choices:
        return ""
    first = choices[0]
    if not isinstance(first, dict):
        return ""
    message = first.get("message", {})
    if not isinstance(message, dict):
        return ""
    content = message.get("content", "")
    return str(content).strip() if isinstance(content, str) else ""


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
