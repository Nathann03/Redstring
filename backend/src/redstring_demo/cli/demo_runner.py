"""Command-line helper to exercise the hybrid dialogue backend without the game client."""

from __future__ import annotations

import argparse
import json
import logging
import copy
import time
from pathlib import Path
from typing import Iterable, Optional, Sequence, Tuple

from ..core.models import PipelineOutput, PlayerQuery
from ..data.loader import DialogueDataset, load_dialogue_dataset
from ..pipeline.factory import build_demo_orchestrator, build_llama_orchestrator
from ..services.llm import LlamaGenerationConfig


DEMO_GAME_STATE = {
    "case_id": "case_demo",
    "npc_states": {
        "judge_emily": {
            "found_clues": ["torn_note", "bloody_knife"],
            "asked_questions": ["where_were_you_last_night"],
            "suspect_alibis": {"judge_emily": "court_until_9pm"},
        },
        "detective_ron": {
            "found_clues": ["harbor_ticket"],
            "asked_questions": ["what_did_you_find"],
            "suspect_alibis": {"mira_lane": "crowded_pier"},
        },
        "bartender_lucy": {
            "found_clues": ["ledger_page"],
            "asked_questions": ["seen_anyone_suspicious"],
            "suspect_alibis": {},
        },
    },
    "player_inventory": ["magnifying_glass", "case_notes"],
    "player_reputation": 0.5,
}


def build_player_query(question: str, npc_id: str) -> PlayerQuery:
    game_state = copy.deepcopy(DEMO_GAME_STATE)
    npc_states = game_state.setdefault("npc_states", {})
    npc_states.setdefault(
        npc_id,
        {
            "found_clues": [],
            "asked_questions": [],
            "suspect_alibis": {},
        },
    )
    return PlayerQuery(
        save_id="demo_save",
        player_id="demo_player",
        npc_id=npc_id,
        player_question=question,
        game_state=game_state,
    )


def run_demo(
    data_path: Optional[Path] = None,
    questions: Optional[Iterable[str]] = None,
    llama_config: Optional[LlamaGenerationConfig] = None,
    interactive: bool = False,
    npc_overrides: Optional[Iterable[str]] = None,
    tts_enabled: bool = False,
) -> None:
    dataset = load_dialogue_dataset(data_path)
    orchestrator, llm = _build_orchestrator(data_path, llama_config)
    warm_start_msg = _ensure_llm_ready(llm, bool(llama_config))
    if warm_start_msg:
        print(warm_start_msg)

    if interactive or not questions:
        _interactive_loop(orchestrator, llm, dataset, tts_enabled)
        return

    npc_cycle = list(npc_overrides or [])
    query_list = list(questions)
    for idx, question in enumerate(query_list):
        npc_id = _select_npc_for_question(question, dataset, npc_cycle, idx)
        query = build_player_query(question, npc_id)
        start = time.perf_counter()
        output = orchestrator.handle_query(query, tts_enabled=tts_enabled)
        duration = time.perf_counter() - start
        _print_output(question, output, npc_id=npc_id, latency_s=duration)


def _build_orchestrator(
    data_path: Optional[Path],
    llama_config: Optional[LlamaGenerationConfig],
) -> Tuple[object, object]:
    if llama_config:
        return build_llama_orchestrator(llama_config, path=data_path)
    return build_demo_orchestrator(path=data_path)


def _ensure_llm_ready(llm: object, using_llama: bool) -> Optional[str]:
    start = time.perf_counter() if using_llama else None
    llm.spin_up()
    if using_llama and start is not None:
        elapsed = time.perf_counter() - start
        return f"Local LLaMA model ready in {elapsed:.2f}s"
    return "Stub LLM ready" if not using_llama else None


def _interactive_loop(
    orchestrator: object,
    llm: object,
    dataset: DialogueDataset,
    tts_enabled: bool,
) -> None:
    npc_ids = sorted(dataset.npc_records.keys())
    print("\nInteractive demo mode")
    print("----------------------")
    print("Type the number or name of an NPC, then enter a question. Type 'quit' to exit.\n")
    last_npc = npc_ids[0] if npc_ids else "judge_emily"
    while True:
        print("Available NPCs:")
        for idx, npc in enumerate(npc_ids, start=1):
            print(f"  {idx}. {npc}")
        choice = input(f"Select NPC [default {last_npc}, q to quit]: ").strip()
        if not choice:
            npc_id = last_npc
        else:
            lower = choice.lower()
            if lower in {"q", "quit", "exit"}:
                print("Exiting interactive mode.")
                break
            if choice.isdigit() and 1 <= int(choice) <= len(npc_ids):
                npc_id = npc_ids[int(choice) - 1]
            elif choice in npc_ids:
                npc_id = choice
            else:
                print("Unrecognized NPC selection. Try again.\n")
                continue

        question = input(f"Ask {npc_id} (or 'quit' to exit): ").strip()
        if not question:
            print("Please enter a question.\n")
            continue
        if question.lower() in {"quit", "exit"}:
            print("Exiting interactive mode.")
            break

        query = build_player_query(question, npc_id)
        start = time.perf_counter()
        output = orchestrator.handle_query(query, tts_enabled=tts_enabled)
        duration = time.perf_counter() - start
        _print_output(question, output, npc_id=npc_id, latency_s=duration)
        last_npc = npc_id


def _select_npc_for_question(
    question: str,
    dataset: DialogueDataset,
    overrides: Sequence[str],
    index: int,
) -> str:
    if overrides and index < len(overrides):
        return overrides[index]

    lowered = question.lower()
    heuristics = (
        ("judge_emily", ["trial", "court", "judge", "verdict"]),
        ("detective_ron", ["harbor", "warehouse", "shipment", "stakeout", "detective"]),
        ("bartender_lucy", ["tavern", "weather", "gossip", "drink", "bar"]),
    )
    for npc_id, keywords in heuristics:
        if any(keyword in lowered for keyword in keywords) and npc_id in dataset.npc_records:
            return npc_id

    # Fallback to first NPC in dataset
    npc_ids = list(dataset.npc_records.keys())
    return npc_ids[index % len(npc_ids)] if npc_ids else "judge_emily"


def _print_output(
    question: str,
    output: PipelineOutput,
    npc_id: Optional[str] = None,
    latency_s: Optional[float] = None,
) -> None:
    divider = "=" * 60
    print(divider)
    print(f"Player question: {question}")
    if npc_id:
        print(f"NPC: {npc_id}")
    print(f"Source: {output.source}")
    if output.warmup and not output.warmup.is_llm_ready:
        print(f"Warm-up line: {output.text}")
        return
    print(f"Response text:\n{output.text}")
    if output.similarity is not None:
        print(f"Similarity: {output.similarity:.2f}")
    print(f"Cached: {output.cached}")
    if output.spinner_message:
        print(f"Spinner: {output.spinner_message}")
    if latency_s is not None:
        print(f"Latency: {latency_s * 1000:.1f} ms")
    print(divider)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the hybrid dialogue backend demo.")
    parser.add_argument(
        "--data-file",
        type=Path,
        help="Optional path to a custom npc_dialogue.json file.",
    )
    parser.add_argument(
        "--question",
        action="append",
        help="Override the default sample questions; may be specified multiple times.",
    )
    parser.add_argument(
        "--llama-config",
        type=Path,
        help="Optional path to a llama.cpp config JSON file (see backend/config/local_llm_config.example.json).",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        help="Set logging verbosity (default INFO).",
    )
    parser.add_argument(
        "--interactive",
        action="store_true",
        help="Launch an interactive prompt to choose NPCs and ask multiple questions.",
    )
    parser.add_argument(
        "--npc",
        action="append",
        help="Specify NPC ids for the provided questions (repeatable).",
    )
    parser.add_argument(
        "--enable-tts",
        action="store_true",
        help="Enable the Turbo TTS stub (defaults to off for CLI demos).",
    )
    args = parser.parse_args()
    logging.basicConfig(level=getattr(logging, args.log_level.upper(), logging.INFO))
    llama_cfg = _load_llama_config(args.llama_config) if args.llama_config else None
    run_demo(
        data_path=args.data_file,
        questions=args.question,
        llama_config=llama_cfg,
        interactive=args.interactive,
        npc_overrides=args.npc,
        tts_enabled=args.enable_tts,
    )


def _load_llama_config(path: Path) -> LlamaGenerationConfig:
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    return LlamaGenerationConfig(**payload)


if __name__ == "__main__":
    main()
