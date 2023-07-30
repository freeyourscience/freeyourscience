from typing import Optional

import requests


def get_paper_metadata(doi: str) -> Optional[dict]:
    """Get OA Button's paper meta data for a given DOI."""
    r = requests.post(
        "https://api.openaccessbutton.org/find",
        json={
            "doi": doi,
            "config": {
                "repo_name": "Zenodo",
                "oa_deposit_off": True,
                "dark_deposit_off": True,
                "not_library": True,
                "autorun_off": False,
                "owner": "team@freeyourscience.org",
            },
            "from": "anonymous",
            "plugin": "shareyourpaper",
            "embedded": f"https://freeyourscience.org/syp?doi={doi}",
        },
    )
    if r.status_code not in ["200", "201"]:
        return None

    return r.json()


def get_permissions(doi: str) -> Optional[dict]:
    """Get OA Button's re-publication permission details for a given DOI."""
    r = requests.get(
        "https://api.openaccessbutton.org/permissions", params={"doi": doi}
    )
    if r.status_code != 200:
        return None

    return r.json()
