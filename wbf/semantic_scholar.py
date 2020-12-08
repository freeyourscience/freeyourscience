from typing import List, Optional

import requests
from pydantic import BaseModel

# TODO: Add API key for prod setting


class Paper(BaseModel):
    """Unofficial schema, reconstructed from API response at
    https://api.semanticscholar.org/v1/paper/

    TODO: Inquire about official schema documentation.
    """

    abstract: str
    arxivId: Optional[str] = None
    authors: List[dict]
    citationVelocity: int
    citations: List[dict]
    corpusId: int
    doi: str
    fieldsOfStudy: List[str]
    influentialCitationCount: int
    is_open_access: bool
    is_publisher_licensed: bool
    paperId: str
    references: List[dict]
    title: str
    topics: List[dict]
    url: str
    venue: str
    year: int


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
    dois = [paper.doi for paper in papers if paper is not None]
    return dois
