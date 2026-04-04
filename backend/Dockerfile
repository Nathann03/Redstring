FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/backend/src

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt /app/backend/requirements.txt
COPY backend/requirements-llm.txt /app/backend/requirements-llm.txt

ARG INSTALL_LLM=false
ARG LLAMA_CUDA=false
RUN pip install --no-cache-dir -r /app/backend/requirements.txt && \
    if [ "$INSTALL_LLM" = "true" ]; then \
      if [ "$LLAMA_CUDA" = "true" ]; then export CMAKE_ARGS="-DGGML_CUDA=on" FORCE_CMAKE=1; fi; \
      pip install --no-cache-dir -r /app/backend/requirements-llm.txt; \
    fi

COPY backend /app/backend

EXPOSE 8000

CMD ["bash", "/app/backend/start_backend.sh"]
