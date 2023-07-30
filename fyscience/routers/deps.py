import os
from typing import Optional
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


TEMPLATE_PATH = os.path.join(
    os.path.abspath(os.path.dirname(__file__)), "..", "templates"
)


class Settings(BaseSettings):
    sherpa_api_key: str
    unpaywall_email: str
    s2_api_key: Optional[str] = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


@lru_cache()
def get_settings():
    return Settings()
