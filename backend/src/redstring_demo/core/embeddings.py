"""Simple embedding utilities for local retrieval without external dependencies."""

from __future__ import annotations

import math
import re
from collections import Counter
from typing import Dict


TOKEN_PATTERN = re.compile(r"\w+")


class SimpleEmbeddingModel:
    """Minimal bag-of-words embedding model with cosine similarity."""

    def embed(self, text: str) -> Dict[str, float]:
        tokens = TOKEN_PATTERN.findall(text.lower())
        if not tokens:
            return {}
        counts = Counter(tokens)
        total = sum(counts.values())
        return {token: count / total for token, count in counts.items()}

    @staticmethod
    def cosine_similarity(vec_a: Dict[str, float], vec_b: Dict[str, float]) -> float:
        if not vec_a or not vec_b:
            return 0.0
        dot = sum(vec_a[token] * vec_b.get(token, 0.0) for token in vec_a)
        norm_a = math.sqrt(sum(value * value for value in vec_a.values()))
        norm_b = math.sqrt(sum(value * value for value in vec_b.values()))
        if not norm_a or not norm_b:
            return 0.0
        return dot / (norm_a * norm_b)

