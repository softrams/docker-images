FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"
WORKDIR /app
COPY mcp/jira-mcp/pyproject.toml mcp/jira-mcp/uv.lock mcp/jira-mcp/README.md ./
COPY mcp/jira-mcp/src ./src
RUN uv sync --frozen --no-dev
RUN useradd -m -u 1002 -s /bin/bash appuser && chown -R appuser:appuser /app
USER appuser
ENV PATH="/app/.venv/bin:${PATH}"
ENTRYPOINT ["mcp-atlassian"]
