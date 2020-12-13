import os
from typing import Optional, List

import requests
from pydantic import BaseModel

from fyscience.schemas import FullPaper


class Paper(BaseModel):
    """https://unpaywall.org/data-format#doi-object"""

    best_oa_location: Optional[dict] = None
    data_standard: int
    doi: str
    doi_url: str
    genre: str
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
    publisher: str
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
    if not response.ok:
        return None

    data = response.json()
    paper = Paper(**data)
    return paper


def get_paper(doi: str, email: Optional[str] = None) -> Optional[FullPaper]:
    paper = _get_paper(doi, email)
    if paper is None:
        return None

    full_paper = FullPaper(
        doi=doi,
        issn=paper.journal_issn_l,
        is_open_access=paper.is_oa,
        title=paper.title,
        year=paper.year,
        journal=paper.journal_name,
    )

    if paper.z_authors is not None:
        first_author = [a for a in paper.z_authors if a["sequence"] == "first"][0]
        full_paper.authors = f"{first_author['given']} {first_author['family']} et al."

    return full_paper
