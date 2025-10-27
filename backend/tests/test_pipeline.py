from __future__ import annotations

from redstring_demo.core.models import PlayerQuery
from redstring_demo.pipeline.factory import build_demo_orchestrator


SAMPLE_GAME_STATE = {
    "case_id": "case_01",
    "npc_states": {
        "judge_emily": {
            "found_clues": ["bloody_knife", "torn_note"],
            "asked_questions": ["where_were_you_last_night"],
            "suspect_alibis": {"judge_emily": "court_until_9pm"},
        },
        "detective_ron": {
            "found_clues": ["harbor_ticket"],
            "asked_questions": [],
            "suspect_alibis": {},
        },
    },
    "player_inventory": ["magnifying_glass"],
    "player_reputation": 0.7,
}


def make_query(question: str, npc_id: str = "judge_emily") -> PlayerQuery:
    return PlayerQuery(
        save_id="save_01",
        player_id="player_123",
        npc_id=npc_id,
        player_question=question,
        game_state=SAMPLE_GAME_STATE,
    )


def test_warmup_fallback_enqueues_and_returns_preset():
    orchestrator, llm = build_demo_orchestrator()
    query = make_query("Did anyone leave after the trial?")

    result = orchestrator.handle_query(query, tts_enabled=False)

    assert result.source == "preset_dialogue"
    assert result.warmup is not None
    assert not result.warmup.is_llm_ready
    assert result.warmup.queued
    assert orchestrator.queued_query_count() == 1
    assert result.spinner_message == "AI model spinning up..."

    llm.spin_up()
    processed = orchestrator.process_queued_queries(tts_enabled=False)

    assert len(processed) == 1
    processed_result = processed[0]
    assert processed_result.source == "retrieval_exact"
    assert processed_result.audio is None


def test_retrieval_fuzzy_hit_triggers_rephrase():
    orchestrator, llm = build_demo_orchestrator()
    llm.spin_up()
    query = make_query("Did anyone sneak out after the trial?")

    result = orchestrator.handle_query(query, tts_enabled=False)

    assert result.source == "retrieval_fuzzy"
    assert "closest match" in result.text
    assert result.similarity is not None and result.similarity >= 0.7


def test_rag_generation_on_miss_and_caching_behaviour():
    orchestrator, llm = build_demo_orchestrator()
    llm.spin_up()
    question = "What strategy should I use on the harbor stakeout?"
    query = make_query(question, npc_id="detective_ron")

    first = orchestrator.handle_query(query, tts_enabled=False)
    assert first.source == "llm_rag"
    assert "harbor" in first.text.lower()
    assert "magnifying_glass" in first.text
    assert not first.cached

    second = orchestrator.handle_query(query, tts_enabled=False)
    assert second.cached
    assert second.source == "llm_rag"
    assert second.audio is None
    assert second.spinner_message is None


def test_tts_can_be_disabled():
    orchestrator, llm = build_demo_orchestrator()
    llm.spin_up()
    query = make_query("Did anyone leave after the trial?")

    result = orchestrator.handle_query(query, tts_enabled=False)

    assert result.audio is None
    assert result.spinner_message is None
