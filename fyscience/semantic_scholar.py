from typing import List, Optional

import requests
from pydantic import BaseModel

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


def _get_request(relative_url: str, api_key: str, **kwargs) -> requests.Response:
    if api_key is not None:
        headers = kwargs.pop("headers", None)
        if isinstance(headers, dict):
            headers["x-api-key"] = api_key
        else:
            headers = {"x-api-key": api_key}
        kwargs["headers"] = headers

        url = f"https://partner.semanticscholar.org/v1/{relative_url}"

    else:
        url = f"https://api.semanticscholar.org/v1/{relative_url}"

    return requests.get(url, **kwargs)


def _get_paper(paper_id: str, api_key: str = None) -> Optional[Paper]:
    r = _get_request(f"paper/{paper_id}", api_key)

    if not r.ok:
        # TODO: Log and/or handle differently.
        return None

    return Paper(**r.json())


def get_paper(paper_id: str, api_key: str = None) -> Optional[FullPaper]:
    paper = _get_paper(paper_id, api_key)
    if paper is None or paper.doi is None:
        return None

    return FullPaper(
        doi=paper.doi, is_open_access=paper.is_open_access, title=paper.title
    )


def _get_author(author_id: str, api_key: str = None) -> Optional[S2Author]:
    r = _get_request(f"author/{author_id}", api_key)

    if not r.ok:
        # TODO: Log and/or handle differently.
        return None

    return S2Author(**r.json())


def get_author_with_papers(author_id: str, api_key: str = None) -> Optional[Author]:
    author = _get_author(author_id, api_key)
    if author is None:
        return None

    author.papers = [] if author.papers is None else author.papers
    papers = [get_paper(paper["paperId"], api_key) for paper in author.papers]
    papers = [p for p in papers if p is not None]

    return Author(
        name=author.name,
        provider="semantic_scholar",
        profile_url=author.url,
        papers=papers,
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
