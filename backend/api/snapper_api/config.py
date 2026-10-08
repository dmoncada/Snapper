import os
from pathlib import Path

from dotenv import load_dotenv


def discogs_token() -> str:
    load_dotenv(Path(__file__).resolve().parents[1] / ".env", override=False)
    return os.environ.get("DISCOGS_TOKEN", "").strip()
