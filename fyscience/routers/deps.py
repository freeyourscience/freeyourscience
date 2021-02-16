import os
from typing import Optional
from functools import lru_cache
from pydantic import BaseSettings


TEMPLATE_PATH = os.path.join(
    os.path.abspath(os.path.dirname(__file__)), "..", "templates"
)


class Settings(BaseSettings):
    sherpa_api_key: str
    unpaywall_email: str
    s2_api_key: Optional[str] = None

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()
