import requests
import urllib.parse
from loguru import logger

from fyscience.schemas import Author


_CROSSREF_API_USER_AGENT = (
    "FreeYourScience/1.0 "
    "(https://freeyourscience.org/; "
    "mailto:team@freeyourscience.org)"
)


def get_author_with_papers(name: str):
    query = urllib.parse.urlencode({"query.author": name})
    r = requests.get(
        f"https://api.crossref.org/works?{query}",
        headers={"User-Agent": _CROSSREF_API_USER_AGENT},
    )
    if not r.ok:
        logger.error(
            {
                "event": "crossref_get_author_with_papers",
                "message": "response_not_ok",
                "author": name,
                "status_code": r.status_code,
                "response": r.content.decode() if r.content else "",
            }
        )
        return None

    result = r.json()
    paper_ids = [p["DOI"] for p in result["message"]["items"] if "DOI" in p]

    query = urllib.parse.urlencode({"q": name})
    profile_url = f"https://search.crossref.org/?{query}"

    return Author(
        name=name, paper_ids=paper_ids, provider="crossref", profile_url=profile_url
    )
