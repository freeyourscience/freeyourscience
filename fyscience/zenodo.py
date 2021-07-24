from typing import Optional
import requests

from loguru import logger


def get_open_access_url(doi: str) -> Optional[str]:
    # TODO: Add access_token parameter with registered API token
    r = requests.get("https://zenodo.org/api/records", params={"q": f'doi:"{doi}"'})

    if not r.ok:
        logger.error(
            {
                "event": "zenodo_get_open_access_url",
                "message": "response_not_ok",
                "doi": doi,
                "status_code": r.status_code,
                "response": r.content.decode() if r.content else "",
            }
        )
        return None

    hits = r.json().get("hits")
    if not hits or hits["total"] == 0:
        return None

    for hit in hits["hits"]:
        if hit["metadata"]["access_right"] == "open":
            return hit["links"]["html"]

    logger.warning(
        {
            "event": "zenodo_get_open_access_url",
            "message": "hits_but_no_open_access_rights",
            "doi": doi,
        }
    )
    return None
