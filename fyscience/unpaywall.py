import os
from typing import Optional, List

import requests
from pydantic import BaseModel
from loguru import logger

from fyscience.schemas import FullPaper
from fyscience.utils import assemble_author_name


class Paper(BaseModel):
    """https://unpaywall.org/data-format#doi-object"""

    best_oa_location: Optional[dict] = None
    data_standard: int
    doi: str
    doi_url: str
    genre: Optional[str] = None
    is_paratext: bool
    is_oa: bool
    journal_is_in_doaj: bool
    journal_is_oa: bool
    journal_issns: Optional[str] = None
    journal_issn_l: Optional[str] = None
    journal_name: Optional[str] = None
    oa_locations: List[dict]
    first_oa_location: Optional[dict] = None
    oa_status: str
    published_date: Optional[str] = None
    publisher: Optional[str] = None
    title: Optional[str] = None
    updated: str
    year: Optional[int] = None
    z_authors: Optional[List[dict]] = None


def _get_paper(doi: str, email: Optional[str] = None) -> Optional[Paper]:
    """Fetch paper information, most notable information about the availability of an
    open access version as well as the ISSN for a given DOI from the unpaywall API
    (api.unpaywall.org)

    Raises
    ------
    RuntimeError
        In case no email address is passed to the function as an argument and none is
        found in the ``UNPAYWALL_EMAIL`` environment variable.
    """
    email = os.getenv("UNPAYWALL_EMAIL") if email is None else email
    if email is None or not email:
        raise RuntimeError(
            "No email address for use with the unpaywall API in the 'UNPAYWALL_EMAIL'"
            + " environment variable."
        )

    response = requests.get(f"https://api.unpaywall.org/v2/{doi}?email={email}")
    if response.status_code != 200:
        logger.error(
            {
                "event": "unpaywall_get_paper",
                "message": "response_not_ok",
                "doi": doi,
                "status_code": response.status_code,
                "response": response.content.decode() if response.content else "",
            }
        )
        return None

    data = response.json()
    paper = Paper(**data)
    return paper


def _extract_authors(authors: List[dict]) -> str:
    if len(authors) == 1:
        return assemble_author_name(authors[0])

    if "sequence" in authors[0]:
        first_authors = [a for a in authors if a["sequence"] == "first"]
        first_author = first_authors[0] if first_authors else authors[0]
    else:
        first_author = authors[0]

    return f"{assemble_author_name(first_author)} et al."


def get_paper(doi: str, email: Optional[str] = None) -> Optional[FullPaper]:
    paper = _get_paper(doi, email)
    if paper is None:
        return None

    oa_location_url = None
    if paper.best_oa_location is not None:
        oa_location_url = paper.best_oa_location.get(
            "url",
            paper.best_oa_location.get(
                "url_for_pdf",
                None,
            ),
        )

    return FullPaper(
        doi=doi,
        issn=paper.journal_issn_l,
        is_open_access=paper.is_oa,
        title=paper.title,
        year=paper.year,
        journal=paper.journal_name,
        authors=_extract_authors(paper.z_authors) if paper.z_authors else None,
        oa_location_url=oa_location_url,
        published_date=paper.published_date,
    )
