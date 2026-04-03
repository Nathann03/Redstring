"""Download a configured GGUF model from Hugging Face, S3, or a direct URL."""

from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


def ensure_model() -> Optional[Path]:
    config_path = os.getenv("REDSTRING_LLM_CONFIG", "").strip()
    if not config_path:
        logger.info("Model bootstrap skipped because REDSTRING_LLM_CONFIG is not set")
        return None

    model_path = _read_model_path(Path(config_path))
    if model_path.exists():
        logger.info("Model already present at %s", model_path)
        return model_path

    model_path.parent.mkdir(parents=True, exist_ok=True)

    hf_repo_id = os.getenv("REDSTRING_HF_REPO_ID", "").strip()
    hf_filename = os.getenv("REDSTRING_HF_FILENAME", "").strip()
    s3_uri = os.getenv("REDSTRING_MODEL_S3_URI", "").strip()
    direct_url = os.getenv("REDSTRING_MODEL_URL", "").strip()

    if hf_repo_id and hf_filename:
        return _download_from_hugging_face(hf_repo_id, hf_filename, model_path)
    if s3_uri:
        return _download_from_s3(s3_uri, model_path)
    if direct_url:
        return _download_from_url(direct_url, model_path)

    logger.warning("Model bootstrap skipped because no remote model source was configured")
    return None


def _read_model_path(config_path: Path) -> Path:
    payload = json.loads(config_path.read_text(encoding="utf-8"))
    model_path = payload.get("model_path")
    if not model_path:
        raise RuntimeError(f"{config_path} does not contain model_path")
    return Path(str(model_path))


def _download_from_hugging_face(repo_id: str, filename: str, target_path: Path) -> Path:
    from huggingface_hub import hf_hub_download

    token = os.getenv("HF_TOKEN", "").strip() or None
    logger.info("Downloading model from Hugging Face repo=%s file=%s", repo_id, filename)
    downloaded = hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        token=token,
        local_dir=str(target_path.parent),
        local_dir_use_symlinks=False,
    )
    downloaded_path = Path(downloaded)
    if downloaded_path != target_path:
        downloaded_path.replace(target_path)
    return target_path


def _download_from_s3(s3_uri: str, target_path: Path) -> Path:
    import boto3

    bucket, key = _split_s3_uri(s3_uri)
    logger.info("Downloading model from S3 bucket=%s key=%s", bucket, key)
    boto3.client("s3").download_file(bucket, key, str(target_path))
    return target_path


def _download_from_url(url: str, target_path: Path) -> Path:
    import requests

    logger.info("Downloading model from URL %s", url)
    with requests.get(url, stream=True, timeout=60) as response:
        response.raise_for_status()
        with target_path.open("wb") as handle:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    handle.write(chunk)
    return target_path


def _split_s3_uri(s3_uri: str) -> tuple[str, str]:
    if not s3_uri.startswith("s3://"):
        raise RuntimeError(f"Invalid S3 URI: {s3_uri}")
    remainder = s3_uri[5:]
    bucket, _, key = remainder.partition("/")
    if not bucket or not key:
        raise RuntimeError(f"Invalid S3 URI: {s3_uri}")
    return bucket, key


if __name__ == "__main__":
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO").upper())
    ensure_model()
