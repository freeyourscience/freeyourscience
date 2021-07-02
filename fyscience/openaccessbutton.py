from typing import Optional

import requests


def get_paper_metadata(doi: str) -> Optional[dict]:
    """Get OA Button's paper meta data for a given DOI."""
    r = requests.get("https://api.openaccessbutton.org/find", params={"doi": doi})
    if not r.ok:
        return None

    return r.json()


def get_permissions(doi: str) -> Optional[dict]:
    """Get OA Button's re-publication permission details for a given DOI."""
    r = requests.get(
        "https://api.openaccessbutton.org/permissions", params={"doi": doi}
    )
    if not r.ok:
        return None

    return r.json()
