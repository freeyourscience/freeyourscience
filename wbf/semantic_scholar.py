from typing import List, Optional

import requests
from pydantic import BaseModel

# TODO: Add API key for prod setting


class Paper(BaseModel):
    """Unofficial schema, reconstructed from API response at
    https://api.semanticscholar.org/v1/paper/

    TODO: Inquire about official schema documentation and remove Optional for mandatory
    fields.
    """

    abstract: Optional[str] = None
    arxivId: Optional[str] = None
    authors: List[Optional[dict]] = None
    citationVelocity: Optional[int] = None
    citations: List[Optional[dict]] = None
    corpusId: Optional[int] = None
    doi: Optional[str] = None
    fieldsOfStudy: List[Optional[str]] = None
    influentialCitationCount: Optional[int] = None
    is_open_access: Optional[bool] = None
    is_publisher_licensed: Optional[bool] = None
    paperId: Optional[str] = None
    references: List[Optional[dict]] = None
    title: Optional[str] = None
    topics: List[Optional[dict]] = None
    url: Optional[str] = None
    venue: Optional[str] = None
    year: Optional[int] = None


def get_paper(paper_id: str) -> Optional[Paper]:
    r = requests.get(f"https://api.semanticscholar.org/v1/paper/{paper_id}")

    if not r.ok:
        # TODO: Log and/or handle differently.
        return None

    paper = Paper(**r.json())
    return paper


def get_author(author_id: str) -> dict:
    r = requests.get(f"https://api.semanticscholar.org/v1/author/{author_id}")
    author = r.json()
    return author


def get_dois(author_id: str) -> List[str]:
    author = get_author(author_id)
    papers = [get_paper(paper["paperId"]) for paper in author["papers"]]
    dois = [
        paper.doi for paper in papers if paper is not None and paper.doi is not None
    ]
    return dois
