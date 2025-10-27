"""Turbo TTS v2.5 stub for local demos."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from ..core.models import AudioStream


@dataclass
class TTSRequest:
    text: str
    voice: str = "default_turbo"
    speed: float = 1.0


class TurboTTSStub:
    """Emulates latency and metadata for ElevenLabs Turbo TTS without API calls."""

    def __init__(self, default_latency_ms: int = 260, sample_rate_hz: int = 22050) -> None:
        self._default_latency_ms = default_latency_ms
        self._sample_rate_hz = sample_rate_hz

    def synthesize(self, request: TTSRequest) -> AudioStream:
        return AudioStream(
            text=request.text,
            latency_ms=self._default_latency_ms,
            sample_rate_hz=self._sample_rate_hz,
            format="pcm16",
        )

    def maybe_synthesize(self, text: str, enabled: bool, voice: Optional[str] = None) -> Optional[AudioStream]:
        if not enabled:
            return None
        request = TTSRequest(text=text, voice=voice or "default_turbo")
        return self.synthesize(request)

