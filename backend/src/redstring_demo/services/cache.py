"""In-memory cache used for response reuse and queue persistence."""

from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Any, Dict, Optional, Tuple


@dataclass
class CacheEntry:
    value: Any
    expires_at: float
    metadata: Dict[str, Any]


class InMemoryCache:
    """Simple cache with optional TTL semantics."""

    def __init__(self, default_ttl: float = 300.0) -> None:
        self._default_ttl = default_ttl
        self._store: Dict[str, CacheEntry] = {}

    @staticmethod
    def _serialize_key(parts: Tuple[Any, ...]) -> str:
        return "|".join(str(part) for part in parts)

    def get(self, key_parts: Tuple[Any, ...]) -> Optional[CacheEntry]:
        key = self._serialize_key(key_parts)
        entry = self._store.get(key)
        if not entry:
            return None
        if entry.expires_at and entry.expires_at < time.time():
            del self._store[key]
            return None
        return entry

    def set(
        self,
        key_parts: Tuple[Any, ...],
        value: Any,
        ttl: Optional[float] = None,
        **metadata: Any,
    ) -> None:
        lifetime = ttl if ttl is not None else self._default_ttl
        expires_at = time.time() + lifetime if lifetime > 0 else float("inf")
        key = self._serialize_key(key_parts)
        self._store[key] = CacheEntry(value=value, expires_at=expires_at, metadata=metadata)

    def clear(self) -> None:
        self._store.clear()

