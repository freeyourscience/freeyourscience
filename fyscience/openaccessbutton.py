from typing import Optional

import requests


def get_permissions(doi: str) -> Optional[dict]:
    """Get S2 author ID via the name search."""
    r = requests.get("https://api.openaccessbutton.org/find", params={"doi": doi})
    if not r.ok:
        return None

    return r.json()
