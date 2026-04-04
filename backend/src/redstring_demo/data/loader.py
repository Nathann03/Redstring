"""Load character definitions and pregenerated dialogue data."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

from ..core.models import CharacterInfo, CharacterKnowledge, PregeneratedDialogue

DEFAULT_CHARACTER_PATH = Path(__file__).resolve().parents[3] / "character_info.txt"
DEFAULT_DIALOGUE_PATH = Path(__file__).resolve().parents[3] / "data" / "npc_dialogue.json"
EVIDENCE_ID_PATTERN = re.compile(r"EVID_\d+")


@dataclass(frozen=True)
class CharacterDataset:
    """Character records keyed by character_id."""

    records: Dict[str, CharacterInfo]

    def get(self, character_id: str) -> CharacterInfo:
        return self.records[character_id]


@dataclass(frozen=True)
class DialogueDataset:
    """Pregenerated dialogue indexed by character_id."""

    records: Dict[str, List[PregeneratedDialogue]] = field(default_factory=dict)

    def get(self, character_id: str) -> List[PregeneratedDialogue]:
        return list(self.records.get(character_id, []))


def load_character_dataset(path: Optional[Path] = None) -> CharacterDataset:
    resolved = path or DEFAULT_CHARACTER_PATH
    if not resolved.exists():
        raise FileNotFoundError(f"Character info file not found at {resolved}")

    contents = resolved.read_text(encoding="utf-8")
    decoder = json.JSONDecoder()
    idx = 0
    records: Dict[str, CharacterInfo] = {}
    while idx < len(contents):
        while idx < len(contents) and contents[idx].isspace():
            idx += 1
        if idx >= len(contents):
            break
        payload, next_idx = decoder.raw_decode(contents, idx)
        character = _parse_character_info(payload)
        records[character.character_id] = character
        idx = next_idx
    return CharacterDataset(records=records)


def load_dialogue_dataset(path: Optional[Path] = None) -> DialogueDataset:
    resolved = path or DEFAULT_DIALOGUE_PATH
    if not resolved.exists():
        raise FileNotFoundError(f"Dialogue data file not found at {resolved}")

    payload = json.loads(resolved.read_text(encoding="utf-8"))
    records: Dict[str, List[PregeneratedDialogue]] = {}
    for entry in payload.get("npc_data", []):
        npc_id = str(entry["npc_id"])
        items = [
            PregeneratedDialogue(
                source_id=str(item["source_id"]),
                text=str(item["text"]),
                embedding_text=str(item.get("embedding_text", item["text"])),
                evidence_id=str(item["evidence_id"]) if item.get("evidence_id") else None,
                tags=[str(tag) for tag in item.get("tags", [])],
                clues=[str(clue) for clue in item.get("clues", []) if EVIDENCE_ID_PATTERN.fullmatch(str(clue))],
            )
            for item in entry.get("responses", [])
        ]
        records[npc_id] = items
    return DialogueDataset(records=records)


def _parse_character_info(payload: Dict[str, object]) -> CharacterInfo:
    knowledge_raw = dict(payload.get("knowledge_base", {}))
    knowledge = CharacterKnowledge(
        alibi=str(knowledge_raw.get("alibi", "")),
        truth=[str(item) for item in knowledge_raw.get("truth", [])],
        will_admit_when_pressed=[str(item) for item in knowledge_raw.get("will_admit_when_pressed", [])],
        will_never_admit=[str(item) for item in knowledge_raw.get("will_never_admit", knowledge_raw.get("will_never_admit_until_overwhelming_evidence", []))],
        knows_about_others=[str(item) for item in knowledge_raw.get("knows_about_others", [])],
        relationship_to_victim=str(knowledge_raw.get("relationship_to_victim", "")),
    )
    evidence_knowledge = {
        str(clue_id): str(description)
        for clue_id, description in dict(payload.get("evidence_knowledge", {})).items()
        if EVIDENCE_ID_PATTERN.fullmatch(str(clue_id))
    }
    return CharacterInfo(
        character_id=str(payload["character_id"]),
        name=str(payload.get("name", "")),
        age=str(payload.get("age", "")),
        occupation=str(payload.get("occupation", "")),
        location=str(payload.get("location", "")),
        personality_prompt=str(payload.get("personality_prompt", "")),
        knowledge_base=knowledge,
        evidence_knowledge=evidence_knowledge,
        behavior_guidelines=[str(item) for item in payload.get("behavior_guidelines", [])],
        confession_trigger=[str(item) for item in payload.get("confession_trigger", [])],
    )
