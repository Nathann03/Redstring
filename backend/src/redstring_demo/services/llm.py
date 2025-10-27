"""Local LLM services used by the hybrid dialogue orchestrator."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Dict, List, Optional

from ..core.models import LLMResponse, PlayerQuery, RAGContext

logger = logging.getLogger(__name__)


class LocalLLMService:
    """Mimics an autoscaled LLM instance with warm-up behaviour."""

    def __init__(self) -> None:
        self._ready = False

    def is_ready(self) -> bool:
        return self._ready

    def spin_up(self) -> None:
        logger.debug("Spinning up LocalLLMService stub")
        self._ready = True

    def shut_down(self) -> None:
        logger.debug("Shutting down LocalLLMService stub")
        self._ready = False

    def generate(self, query: PlayerQuery, context: RAGContext) -> LLMResponse:
        logger.debug("Generating stub response for NPC '%s'", query.npc_id)
        dynamic_summary = self._format_dynamic_facts(context.dynamic_facts)
        anchor_summary = "; ".join(context.anchor_facts) if context.anchor_facts else "no anchor records"
        retrieved_summary = (
            "; ".join(context.retrieved_snippets) if context.retrieved_snippets else "no related testimony"
        )
        text = (
            f"I reviewed the case file for save {query.save_id}. "
            f"Regarding your question \"{query.player_question}\": {dynamic_summary} "
            f"My standing notes say: {anchor_summary}. Related remarks: {retrieved_summary}."
        )
        reasoning = {
            "dynamic_facts_used": context.dynamic_facts,
            "anchor_facts_used": context.anchor_facts,
            "retrieved_snippets_used": context.retrieved_snippets,
        }
        return LLMResponse(text=text, reasoning=reasoning)

    def rephrase(self, query: PlayerQuery, base_response: str) -> LLMResponse:
        logger.debug("Rephrasing stub response for NPC '%s'", query.npc_id)
        text = (
            f"You asked \"{query.player_question}\". Here's what I can share: "
            f"{base_response} That's the closest match I recall."
        )
        reasoning = {
            "mode": "rephrase",
            "base_response": base_response,
        }
        return LLMResponse(text=text, reasoning=reasoning)

    @staticmethod
    def _format_dynamic_facts(dynamic_facts: Dict[str, object]) -> str:
        npc_state = dynamic_facts.get("npc_state") or {}
        inventory = dynamic_facts.get("player_inventory") or []
        reputation = dynamic_facts.get("player_reputation")

        parts: List[str] = []
        if npc_state:
            clues = npc_state.get("found_clues")
            if clues:
                parts.append(f"I noted the clues {', '.join(clues)}.")
            asked = npc_state.get("asked_questions")
            if asked:
                parts.append(f"You already asked {', '.join(asked)}.")
            alibis = npc_state.get("suspect_alibis")
            if alibis:
                formatted = ", ".join(f"{suspect}={alibi}" for suspect, alibi in alibis.items())
                parts.append(f"Recorded alibis: {formatted}.")
        if inventory:
            parts.append(f"Your inventory currently holds {', '.join(inventory)}.")
        if reputation is not None:
            parts.append(f"Your reputation score stands at {reputation}.")
        if not parts:
            return "I found no new details in the save file."
        return " ".join(parts)


@dataclass
class LlamaGenerationConfig:
    """Configuration for the llama.cpp powered LLM."""

    model_path: str
    n_ctx: int = 2048
    n_threads: int = 4
    temperature: float = 0.7
    top_p: float = 0.95
    max_tokens: int = 256


class LlamaCppLLMService(LocalLLMService):
    """Wraps llama-cpp-python to run a local GGUF model."""

    def __init__(self, config: LlamaGenerationConfig) -> None:
        super().__init__()
        self._config = config
        self._llm: Optional[object] = None

    def spin_up(self) -> None:
        if self._llm is not None:
            self._ready = True
            return
        try:
            from llama_cpp import Llama  # type: ignore
        except ImportError as exc:  # pragma: no cover - exercised when dependency missing
            raise RuntimeError(
                "llama-cpp-python is not installed. Install it with "
                "`python3 -m pip install -r backend/requirements-llm.txt`."
            ) from exc

        self._llm = Llama(
            model_path=self._config.model_path,
            n_ctx=self._config.n_ctx,
            n_threads=self._config.n_threads,
        )
        logger.info("Loaded llama model from %s", self._config.model_path)
        self._ready = True

    def shut_down(self) -> None:
        logger.debug("Unloading llama model")
        self._llm = None
        self._ready = False

    def generate(self, query: PlayerQuery, context: RAGContext) -> LLMResponse:
        if self._llm is None:
            raise RuntimeError("LLM not ready. Call spin_up() before generate().")
        prompt = self._build_prompt(query, context)
        logger.debug(
            "Generating llama response for NPC '%s' with prompt length %d",
            query.npc_id,
            len(prompt),
        )
        completion = self._llm.create_completion(  # type: ignore[attr-defined]
            prompt=prompt,
            max_tokens=self._config.max_tokens,
            temperature=self._config.temperature,
            top_p=self._config.top_p,
            stop=["\n\nPlayer", "###"],
        )
        text = completion["choices"][0]["text"].strip()
        if not text:
            # Fall back to deterministic formatting if the model returned nothing.
            return super().generate(query, context)
        reasoning = {
            "dynamic_facts_used": context.dynamic_facts,
            "anchor_facts_used": context.anchor_facts,
            "retrieved_snippets_used": context.retrieved_snippets,
            "prompt": prompt,
        }
        return LLMResponse(text=text, reasoning=reasoning)

    def rephrase(self, query: PlayerQuery, base_response: str) -> LLMResponse:
        if self._llm is None:
            return super().rephrase(query, base_response)
        logger.debug("Rephrasing llama response for NPC '%s'", query.npc_id)
        prompt = (
            "### Instruction:\n"
            "Rephrase the response so it matches the NPC's voice without changing facts.\n"
            "### Player Question:\n"
            f"{query.player_question}\n"
            "### Base Response:\n"
            f"{base_response}\n"
            "### Rephrased Response:\n"
        )
        completion = self._llm.create_completion(  # type: ignore[attr-defined]
            prompt=prompt,
            max_tokens=120,
            temperature=0.6,
            top_p=0.9,
            stop=["###"],
        )
        text = completion["choices"][0]["text"].strip()
        if not text:
            return super().rephrase(query, base_response)
        reasoning = {
            "mode": "rephrase",
            "prompt": prompt,
            "base_response": base_response,
        }
        return LLMResponse(text=text, reasoning=reasoning)

    @staticmethod
    def _build_prompt(query: PlayerQuery, context: RAGContext) -> str:
        dynamic_facts = context.dynamic_facts
        anchor_lines = "\n".join(f"- {fact}" for fact in context.anchor_facts) or "- None"
        retrieved_lines = "\n".join(f"- {snippet}" for snippet in context.retrieved_snippets) or "- None"
        return (
            "### NPC Briefing ###\n"
            f"Save ID: {query.save_id}\n"
            f"NPC ID: {query.npc_id}\n"
            f"Player Reputation: {dynamic_facts.get('player_reputation')}\n"
            f"Inventory: {', '.join(dynamic_facts.get('player_inventory', []))}\n"
            "NPC State: "
            f"{dynamic_facts.get('npc_state')}\n"
            "Anchor Facts:\n"
            f"{anchor_lines}\n"
            "Retrieved Testimony:\n"
            f"{retrieved_lines}\n"
            "### Player Question ###\n"
            f"{query.player_question}\n"
            "### NPC Response ###\n"
        )
