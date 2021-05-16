import requests
import urllib.parse
from loguru import logger

from fyscience.schemas import Author, FullPaper


_CROSSREF_API_USER_AGENT = (
    "FreeYourScience/1.0 "
    "(https://freeyourscience.org/; "
    "mailto:team@freeyourscience.org)"
)


def _parse_paper(paper: dict) -> FullPaper:
    issn = paper.get("ISSN", None)
    if issn is not None:
        issn = issn[0]

    title = paper.get("title", None)
    if title is not None:
        title = title[0]

    return FullPaper(doi=paper["DOI"], issn=issn, title=title)


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
    papers = [_parse_paper(p) for p in result["message"]["items"] if "DOI" in p]

    query = urllib.parse.urlencode({"q": name})
    profile_url = f"https://search.crossref.org/?{query}"

    return Author(
        name=name, papers=papers, provider="crossref", profile_url=profile_url
    )
