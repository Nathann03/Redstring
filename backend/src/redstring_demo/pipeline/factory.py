"""Factory helpers to wire the demo orchestrator stack."""

from __future__ import annotations

from pathlib import Path
from typing import Optional, Tuple, TypeVar

from ..core.embeddings import SimpleEmbeddingModel
from ..data.loader import DialogueDataset, load_dialogue_dataset
from ..data.vector_store import LocalVectorStore
from ..services.cache import InMemoryCache
from ..services.llm import LlamaCppLLMService, LlamaGenerationConfig, LocalLLMService
from ..services.rag import AnchorFactsStore, RAGContextBuilder
from ..services.retrieval import RetrievalEngine
from ..services.tts import TurboTTSStub
from ..services.warmup import PresetDialogueStore, WarmupManager
from .orchestrator import HybridDialogueOrchestrator

LLMServiceT = TypeVar("LLMServiceT", bound=LocalLLMService)


def _build_dataset(path: Optional[Path] = None) -> DialogueDataset:
    return load_dialogue_dataset(path)


def _build_orchestrator_with_llm(
    llm_service: LLMServiceT,
    dataset: Optional[DialogueDataset] = None,
) -> Tuple[HybridDialogueOrchestrator, LLMServiceT]:
    dialogue_dataset = dataset or _build_dataset()
    embedding_model = SimpleEmbeddingModel()
    vector_store = LocalVectorStore(
        embedding_model=embedding_model,
        responses=dialogue_dataset.vector_records(),
        exact_threshold=0.9,
        fuzzy_threshold=0.7,
    )
    retrieval_engine = RetrievalEngine(vector_store=vector_store)
    anchor_store = AnchorFactsStore(dialogue_dataset.anchor_map())
    rag_builder = RAGContextBuilder(anchor_store)
    preset_store = PresetDialogueStore(dialogue_dataset.preset_map())
    warmup_manager = WarmupManager(preset_store)
    tts_service = TurboTTSStub()
    cache = InMemoryCache(default_ttl=600.0)
    orchestrator = HybridDialogueOrchestrator(
        warmup_manager=warmup_manager,
        retrieval_engine=retrieval_engine,
        rag_builder=rag_builder,
        llm_service=llm_service,
        tts_service=tts_service,
        cache=cache,
        unusual_ttl=600.0,
    )
    return orchestrator, llm_service


def build_demo_orchestrator(path: Optional[Path] = None) -> Tuple[HybridDialogueOrchestrator, LocalLLMService]:
    llm_service = LocalLLMService()
    dataset = _build_dataset(path)
    return _build_orchestrator_with_llm(llm_service, dataset=dataset)


def build_llama_orchestrator(
    config: LlamaGenerationConfig,
    path: Optional[Path] = None,
) -> Tuple[HybridDialogueOrchestrator, LlamaCppLLMService]:
    llm_service = LlamaCppLLMService(config)
    dataset = _build_dataset(path)
    return _build_orchestrator_with_llm(llm_service, dataset=dataset)

