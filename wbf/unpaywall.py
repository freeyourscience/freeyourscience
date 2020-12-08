import os
from typing import Optional, Tuple, List

import requests
from pydantic import BaseModel

from wbf.schemas import OAStatus


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
    journal_name: str
    oa_locations: List[dict]
    first_oa_location: Optional[dict] = None
    oa_status: str
    published_date: Optional[str] = None
    publisher: str
    title: str
    updated: str
    year: Optional[int] = None
    z_authors: List[dict]


def get_paper(doi: str, email: Optional[str] = None) -> Optional[Paper]:
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


def get_oa_status_and_issn(
    doi: str, email: Optional[str] = None
) -> Tuple[OAStatus, Optional[str]]:
    """Get paper from unpaywall API and extract OAStatus as well as ISSN."""
    paper = get_paper(doi, email)

    if paper is None:
        return OAStatus.not_found, None

    oa_status = OAStatus.oa if paper.is_oa else OAStatus.not_oa
    return oa_status, paper.journal_issn_l
