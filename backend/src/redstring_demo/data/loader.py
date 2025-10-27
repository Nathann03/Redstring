"""Load NPC dialogue data from JSON files for the demo backend."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional

DEFAULT_DATA_PATH = Path(__file__).resolve().parents[3] / "data" / "npc_dialogue.json"


@dataclass
class DialogueEntry:
    source_id: str
    text: str
    embedding_text: str
    tags: List[str]

    def to_vector_record(self, npc_id: str) -> Dict[str, object]:
        return {
            "npc_id": npc_id,
            "source_id": self.source_id,
            "text": self.text,
            "embedding_text": self.embedding_text,
            "tags": self.tags,
        }


@dataclass
class NPCDialogueRecord:
    npc_id: str
    preset_dialogue: List[str]
    anchor_facts: List[str]
    responses: List[DialogueEntry]


@dataclass
class DialogueDataset:
    npc_records: Dict[str, NPCDialogueRecord]

    def preset_map(self) -> Dict[str, Iterable[str]]:
        return {npc_id: record.preset_dialogue for npc_id, record in self.npc_records.items()}

    def anchor_map(self) -> Dict[str, List[str]]:
        return {npc_id: record.anchor_facts for npc_id, record in self.npc_records.items()}

    def responses(self) -> List[DialogueEntry]:
        collected: List[DialogueEntry] = []
        for record in self.npc_records.values():
            collected.extend(record.responses)
        return collected

    def vector_records(self) -> List[Dict[str, object]]:
        records: List[Dict[str, object]] = []
        for npc_id, record in self.npc_records.items():
            for response in record.responses:
                records.append(response.to_vector_record(npc_id))
        return records


def load_dialogue_dataset(path: Optional[Path] = None) -> DialogueDataset:
    resolved_path = path or DEFAULT_DATA_PATH
    if not resolved_path.exists():
        raise FileNotFoundError(
            f"Dialogue data file not found at {resolved_path}. "
            "Create it from backend/data/npc_dialogue.json to continue."
        )

    with resolved_path.open("r", encoding="utf-8") as handle:
        raw = json.load(handle)

    npc_records: Dict[str, NPCDialogueRecord] = {}
    for entry in raw.get("npc_data", []):
        npc_id = str(entry["npc_id"])
        responses = [
            DialogueEntry(
                source_id=str(item["source_id"]),
                text=str(item["text"]),
                embedding_text=str(item.get("embedding_text", item["text"])),
                tags=[str(tag) for tag in item.get("tags", [])],
            )
            for item in entry.get("responses", [])
        ]
        npc_records[npc_id] = NPCDialogueRecord(
            npc_id=npc_id,
            preset_dialogue=[str(line) for line in entry.get("preset_dialogue", [])],
            anchor_facts=[str(fact) for fact in entry.get("anchor_facts", [])],
            responses=responses,
        )

    return DialogueDataset(npc_records=npc_records)
