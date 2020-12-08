import os
from typing import Optional, Tuple

import requests

from wbf.schemas import OAStatus


def get_oa_status_and_issn(
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
