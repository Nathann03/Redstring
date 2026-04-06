from __future__ import annotations

import pytest
from fastapi import HTTPException
from starlette.requests import Request

from redstring_demo.api import create_app
from redstring_demo.config import Settings
from redstring_demo.core.models import DialogueRequest, GameState
from redstring_demo.pipeline.factory import build_dialogue_router
from redstring_demo.security import enforce_access
from redstring_demo.services import llm_service


def _settings() -> Settings:
    return Settings(
        secret_key="test-secret",
        character_file=_path("backend/character_info.txt"),
        dialogue_file=_path("backend/data/npc_dialogue.json"),
        llm_config_path=None,
        warm_start=True,
        gemini_api_key="",
        gemini_model="gemini-3-flash-preview",
        groq_api_key="",
        groq_model="meta-llama/llama-4-scout-17b-16e-instruct",
        openrouter_api_key="",
        openrouter_model="openrouter/auto",
    )


def _path(relative: str):
    from pathlib import Path

    return Path(__file__).resolve().parents[2] / relative


def _character(character_id: str):
    router, _, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    return dataset.get(character_id)


def test_retrieval_hit_returns_structured_response():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("james_okoye"),
        player_question="What does this timed test prove?",
        game_state=GameState(found_clues=["EVID_09"], asked_questions=[], npc_id="james_okoye"),
        evidence_id="EVID_09",
    )

    result = router.route(request)

    assert result.route == "retrieval"
    assert any(
        phrase in result.response.lower()
        for phrase in (
            "timed water quality tests",
            "thirty-minute interval",
            "progression of the reaction",
        )
    )
    assert result.clues_unlocked == []


def test_evidence_id_does_not_force_unrelated_retrieval_hit():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("james_okoye"),
        player_question="Did you kill them?",
        game_state=GameState(found_clues=["EVID_09"], asked_questions=[], npc_id="james_okoye"),
        evidence_id="EVID_09",
        generation_backend="local",
    )

    result = router.route(request)

    assert result.route == "llm"
    assert "timed water quality tests" not in result.response.lower()


def test_llm_fallback_stays_grounded_and_filters_existing_clues():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("catch_wallace"),
        player_question="Why were you so upset about Morgan's research?",
        game_state=GameState(found_clues=["EVID_08"], asked_questions=[], npc_id="catch_wallace"),
    )

    result = router.route(request)

    assert result.route == "llm"
    assert "morgan" in result.response.lower() or "fishing" in result.response.lower() or "business" in result.response.lower()
    assert "killer" not in result.response.lower() or "not" in result.response.lower()
    assert result.clues_unlocked == []


def test_ambient_question_falls_back_without_random_evidence_blurt():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("james_okoye"),
        player_question="What's your favorite flavor of ice cream?",
        game_state=GameState(found_clues=["EVID_09"], asked_questions=[], npc_id="james_okoye"),
        generation_backend="local",
    )

    result = router.route(request)

    assert result.route == "llm"
    assert "beacon room vial is toxic" not in result.response.lower()
    assert result.clues_unlocked == []


def test_natural_evidence_question_can_hit_retrieval_without_auto_unlocking_clue():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("riley_chen"),
        player_question="What is this test tube?",
        evidence_id="EVID_06",
        game_state=GameState(found_clues=[], asked_questions=[], npc_id="riley_chen"),
        generation_backend="local",
    )

    result = router.route(request)

    assert result.route == "retrieval"
    assert result.clues_unlocked == []


def test_natural_evidence_question_with_evidence_id_stays_case_related():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("riley_chen"),
        player_question="What is this test tube?",
        evidence_id="EVID_06",
        game_state=GameState(found_clues=[], asked_questions=[], npc_id="riley_chen"),
        generation_backend="local",
    )

    result = router.route(request)

    assert result.route == "retrieval"
    assert any(
        phrase in result.response.lower()
        for phrase in (
            "contamination tests",
            "wear gloves",
            "safety procedures",
        )
    )


def test_confession_override_requires_all_trigger_clues():
    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
    )
    llm.spin_up()
    request = DialogueRequest(
        character_info=dataset.get("yuki_tanaka"),
        player_question="Did you kill Morgan?",
        game_state=GameState(
            found_clues=["EVID_02", "EVID_07", "EVID_08", "EVID_09", "EVID_10", "EVID_11"],
            asked_questions=[],
            npc_id="yuki_tanaka",
        ),
    )

    result = router.route(request)

    assert result.route == "confession"
    assert result.confession is True
    assert "removed the problem" in result.response.lower()


def test_auto_backend_uses_gemini_when_local_llm_is_not_ready(monkeypatch):
    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "candidates": [
                    {
                        "content": {
                            "parts": [
                                {
                                    "text": '{"response":"I stayed in the equipment room and watched the timed test the whole time.","clues_unlocked":[]}'
                                }
                            ]
                        }
                    }
                ]
            }

    captured = {}

    def fake_post(url, params=None, headers=None, json=None, timeout=None):
        captured["url"] = url
        captured["params"] = params
        captured["json"] = json
        return FakeResponse()

    monkeypatch.setattr(llm_service.requests, "post", fake_post)

    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
        gemini_api_key="test-gemini-key",
        gemini_model="gemini-3-flash-preview",
    )
    request = DialogueRequest(
        character_info=dataset.get("james_okoye"),
        player_question="Why do you keep hiding behind technical jargon when I question your motives?",
        game_state=GameState(found_clues=["EVID_09"], asked_questions=["who_are_you"], npc_id="james_okoye"),
        generation_backend="auto",
    )

    result = router.route(request)

    assert llm.is_ready() is False
    assert result.route == "gemini"
    assert "timed test" in result.response.lower()
    assert captured["params"] == {"key": "test-gemini-key"}
    prompt_blob = str(captured["json"])
    assert "Morgan Blackwell" in prompt_blob
    assert "Dr. James Finnegan" in prompt_blob
    assert "EVID_09" in prompt_blob


def test_auto_backend_falls_through_to_groq_after_gemini_failure(monkeypatch):
    class GeminiFailureResponse:
        status_code = 429

        def raise_for_status(self):
            import requests

            raise requests.HTTPError("429 Client Error")

    class GroqSuccessResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "choices": [
                    {
                        "message": {
                            "content": '{"response":"I did not kill Morgan. Ask something more precise if you want a useful answer.","clues_unlocked":[]}'
                        }
                    }
                ]
            }

    captured = {"calls": []}

    def fake_post(url, params=None, headers=None, json=None, timeout=None):
        captured["calls"].append(url)
        if "generativelanguage.googleapis.com" in url:
            return GeminiFailureResponse()
        if "api.groq.com" in url:
            return GroqSuccessResponse()
        raise AssertionError(f"Unexpected URL: {url}")

    monkeypatch.setattr(llm_service.requests, "post", fake_post)

    router, llm, dataset = build_dialogue_router(
        character_path=_path("backend/character_info.txt"),
        dialogue_path=_path("backend/data/npc_dialogue.json"),
        gemini_api_key="test-gemini-key",
        gemini_model="gemini-3-flash-preview",
        groq_api_key="test-groq-key",
        groq_model="test-groq-model",
    )
    request = DialogueRequest(
        character_info=dataset.get("james_okoye"),
        player_question="Did you kill Morgan?",
        game_state=GameState(found_clues=["EVID_09"], asked_questions=[], npc_id="james_okoye"),
        generation_backend="auto",
    )

    result = router.route(request)

    assert result.route == "groq"
    assert "did not kill morgan" in result.response.lower()
    assert any("generativelanguage.googleapis.com" in url for url in captured["calls"])
    assert any("api.groq.com" in url for url in captured["calls"])


def test_api_rejects_missing_bearer_token():
    scope = {
        "type": "http",
        "method": "POST",
        "path": "/dialogue",
        "headers": [],
        "client": ("203.0.113.10", 1234),
    }
    request = Request(scope)

    with pytest.raises(HTTPException) as exc:
        enforce_access(request, _settings(), None)

    assert exc.value.status_code == 401


def test_api_contract_is_registered():
    app = create_app(_settings())
    schema = app.openapi()

    assert "/dialogue" in schema["paths"]
    assert "post" in schema["paths"]["/dialogue"]
    body_schema = schema["components"]["schemas"]["DialogueRequestPayload"]
    assert "npc_id" in body_schema["properties"]
    assert "evidence_id" in body_schema["properties"]
    assert "generation_backend" in body_schema["properties"]
    generation_backend_schema = body_schema["properties"]["generation_backend"]
    enum_values = generation_backend_schema["anyOf"][0]["enum"]
    assert "groq" in enum_values
    assert "openrouter" in enum_values
    assert "/warmup" in schema["paths"]
    assert "post" in schema["paths"]["/warmup"]
    assert "/health" in schema["paths"]
    assert "get" in schema["paths"]["/health"]
