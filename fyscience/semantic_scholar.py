from typing import List, Optional

import requests
from pydantic import BaseModel
from loguru import logger

from fyscience.schemas import FullPaper, Author


class Paper(BaseModel):
    """Unofficial schema, reconstructed from API response at
    https://api.semanticscholar.org/v1/paper/

    TODO: Inquire about official schema documentation and remove Optional for mandatory
    fields.
    """

    abstract: Optional[str] = None
    arxivId: Optional[str] = None
    authors: Optional[List[dict]] = None
    citationVelocity: Optional[int] = None
    citations: Optional[List[dict]] = None
    corpusId: Optional[int] = None
    doi: Optional[str] = None
    fieldsOfStudy: Optional[List[str]] = None
    influentialCitationCount: Optional[int] = None
    is_open_access: Optional[bool] = None
    is_publisher_licensed: Optional[bool] = None
    paperId: Optional[str] = None
    references: Optional[List[dict]] = None
    title: Optional[str] = None
    topics: Optional[List[dict]] = None
    url: Optional[str] = None
    venue: Optional[str] = None
    year: Optional[int] = None


class S2Author(BaseModel):
    aliases: Optional[List[str]] = None
    authorId: str  # could be int?
    influentialCitationCount: Optional[int] = None
    name: Optional[str] = None
    papers: Optional[List[dict]] = None
    url: Optional[str] = None


def _get_request(
    relative_url: str, api_key: str, graph_api: bool = False, **kwargs
) -> requests.Response:
    if api_key is not None:
        headers = kwargs.pop("headers", None)
        if isinstance(headers, dict):
            headers["x-api-key"] = api_key
        else:
            headers = {"x-api-key": api_key}
        kwargs["headers"] = headers

        url = (
            "https://partner.semanticscholar.org"
            + f"{'/graph' if graph_api else ''}/v1/{relative_url}"
        )

    else:
        url = (
            "https://api.semanticscholar.org"
            + f"{'/graph' if graph_api else ''}/v1/{relative_url}"
        )

    return requests.get(url, **kwargs)


def _get_paper(paper_id: str, api_key: str = None) -> Optional[Paper]:
    r = _get_request(f"paper/{paper_id}", api_key)

    if not r.ok:
        logger.error(
            {
                "event": "s2_get_paper",
                "message": "response_not_ok",
                "paper_id": paper_id,
                "status_code": r.status_code,
                "response": r.content.decode() if r.content else "",
            }
        )
        return None

    return Paper(**r.json())


def get_paper(paper_id: str, api_key: str = None) -> Optional[FullPaper]:
    paper = _get_paper(paper_id, api_key)
    if paper is None or paper.doi is None:
        logger.info(
            {
                "event": "s2_get_paper",
                "message": "paper_without_doi",
                "paper_id": paper_id,
            }
        )
        return None

    oa_location_url = paper.url if paper.is_open_access else None

    return FullPaper(
        doi=paper.doi,
        is_open_access=paper.is_open_access,
        title=paper.title,
        oa_location_url=oa_location_url,
    )


def _get_author(author_id: str, api_key: str = None) -> Optional[S2Author]:
    r = _get_request(f"author/{author_id}", api_key)

    if not r.ok:
        logger.error(
            {
                "event": "s2_get_author",
                "message": "response_not_ok",
                "author": author_id,
                "status_code": r.status_code,
                "response": r.content.decode() if r.content else "",
            }
        )
        return None

    return S2Author(**r.json())


def get_author_with_papers(author_id: str, api_key: str = None) -> Optional[Author]:
    author = _get_author(author_id, api_key)
    if author is None:
        return None

    author.papers = [] if author.papers is None else author.papers
    paper_ids = [p["paperId"] for p in author.papers]

    return Author(
        name=author.name,
        provider="semantic_scholar",
        profile_url=author.url,
        paper_ids=paper_ids,
    )


def get_dois(author_id: str, api_key: str = None) -> List[str]:
    author = get_author_with_papers(author_id, api_key)
    if author is None:
        return []

    author.papers = [] if author.papers is None else author.papers
    dois = [paper.doi for paper in author.papers if paper.doi is not None]
    return dois


def extract_profile_id_from_url(url: str) -> Optional[str]:
    url = url.rstrip("/?")
    url_without_params = url.split("?")[0]
    url_without_params = url_without_params.rstrip("/")
    author_id = url_without_params.split("/")[-1]
    return author_id


def get_author_id(author_name: str, api_key: str = None) -> Optional[str]:
    """Get S2 author ID via the author search."""
    r = _get_request(
        f"author/search?query={author_name}", api_key=api_key, graph_api=True
    )
    if not r.ok:
        return None

    data = r.json().get("data")
    if not data:
        return None

    return data[0].get("authorId")
