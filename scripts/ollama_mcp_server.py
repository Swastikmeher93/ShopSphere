# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=1.9,<2"]
# ///
"""MCP tools for Ollama's authenticated cloud chat API."""

import json
import os
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from mcp.server.fastmcp import FastMCP


def _load_local_env() -> None:
    env_file = Path(__file__).resolve().parent.parent / ".env"
    if not env_file.exists():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        os.environ.setdefault(name.strip(), value.strip().strip("\"'"))


_load_local_env()


BASE_URL = os.environ.get("OLLAMA_BASE_URL", "https://ollama.com").rstrip("/")
API_KEY = os.environ.get("OLLAMA_API_KEY", "")
TIMEOUT = int(os.environ.get("OLLAMA_TIMEOUT", "180"))
mcp = FastMCP("ollama")


def _post(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    if not API_KEY:
        raise RuntimeError("OLLAMA_API_KEY is not set in the environment.")
    request = Request(
        f"{BASE_URL}{path}",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=TIMEOUT) as response:
            result = json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        details = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Ollama returned HTTP {error.code}: {details}") from error
    except (URLError, TimeoutError) as error:
        raise RuntimeError(f"Could not reach the Ollama API at {BASE_URL}.") from error
    if not isinstance(result, dict):
        raise RuntimeError("Ollama returned an unexpected response.")
    return result


@mcp.tool()
def ollama_chat(model: str, messages: list[dict[str, str]]) -> str:
    """Send role/content messages to an Ollama Cloud model."""
    if not messages:
        raise ValueError("messages must contain at least one role/content message")
    result = _post(
        "/api/chat",
        {"model": model, "messages": messages, "stream": False},
    )
    message = result.get("message", {})
    return str(message.get("content", ""))


if __name__ == "__main__":
    mcp.run(transport="stdio")
