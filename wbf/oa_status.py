import os
from typing import Optional, Tuple

import requests

from wbf.schemas import OAStatus, Paper, PaperWithOAStatus


def unpaywall_status_api(
    doi: str, email: Optional[str] = None
) -> Tuple[OAStatus, Optional[str]]:
    """Fetch information about the availability of an open access version as well as
    the ISSN for a given DOI from the unpaywall API (api.unpaywall.org)

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
        return OAStatus.not_found, None

    data = response.json()
    oa_status = OAStatus.oa if data["is_oa"] else OAStatus.not_oa
    return oa_status, data["journal_issn_l"]


def oa_status(paper: Paper) -> PaperWithOAStatus:
    """Enrich a given paper with information about the availability of an open access
    copy collected from the an unpaywall data dump or the unpaywall API.
    """
    oa_status, _ = unpaywall_status_api(paper.doi)

    return PaperWithOAStatus(oa_status=oa_status, **paper.dict())
