from functools import lru_cache
from pydantic import BaseSettings


class Settings(BaseSettings):
    sherpa_api_key: str
    unpaywall_email: str

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()
