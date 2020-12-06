import os
import json
from typing import Optional

import requests

from wbf.schemas import OAStatus, OAPathway, PaperWithOAStatus, PaperWithOAPathway


# TODO: Consider for service version that nocost is currently assigned to pathways with
# additional prerequisites (e.g. specific funders or funders mandating OA)
# TODO: For service version, check if embargo still preventing OA and don't recommend
# embargoed papers for re-publication


def has_no_cost_oa_policy(policy: dict) -> bool:
    if policy["open_access_prohibited"] != "no":
        return False

    if "permitted_oa" not in policy:
        return False

    try:
        return any(
            [
                "additional_oa_fee" in perm and perm["additional_oa_fee"] == "no"
                for perm in policy["permitted_oa"]
            ]
        )
    except Exception:
        print("ERROR with policy:", json.dumps(policy))
        return False


def sherpa_pathway_api(issn: str, api_key: Optional[str] = None) -> OAPathway:
    """Fetch information about the available open access pathways for the publisher that
    owns a given ISSN from the Sherpa API (v2.sherpa.ac.uk)

    Raises
    ------
    RuntimeError
        In case no Sherpa API key is passed to the function as an argument and none is
        found in the ``SHERPA_API_KEY`` environment variable.
        To obtain an API key, register at https://v2.sherpa.ac.uk/cgi/register
    """
    api_key = os.getenv("SHERPA_API_KEY") if api_key is None else api_key
    if api_key is None or not api_key:
        raise RuntimeError(
            "No Sherpa API key available in the 'SHERPA_API_KEY' environment variable."
        )

    response = requests.get(
        "https://v2.sherpa.ac.uk/cgi/retrieve?"
        + f"item-type=publication&api-key={api_key}&format=Json&"
        + f'filter=[["issn","equals","{issn}"]]'
    )
    if not response.ok:
        return OAPathway.not_found

    publications = response.json()
    try:
        if (
            not publications
            or not publications["items"]
            or not publications["items"][0]["publisher_policy"]
        ):
            return OAPathway.not_found
    except Exception as e:
        print("ERROR with publications:", json.dumps(publications), e)
        return OAPathway.not_found

    # TODO: How to handle multiple publishers found for ISSN?
    oa_policies_no_cost = list(
        filter(has_no_cost_oa_policy, publications["items"][0]["publisher_policy"])
    )
    if not oa_policies_no_cost:
        return OAPathway.other

    return OAPathway.nocost


def oa_pathway(paper: PaperWithOAStatus, cache=None) -> PaperWithOAPathway:
    """Enrich a given paper with information about the available open access pathway
    collected from the Sherpa API.

    Cache can be anything that exposes ``get(key, default)`` and ``__setitem__``
    """
    if paper.oa_status is OAStatus.oa:
        pathway = OAPathway.already_oa
    elif paper.oa_status is OAStatus.not_found:
        pathway = OAPathway.not_attempted
    else:
        if cache is not None:
            pathway = cache.get(paper.issn, None)
            if not pathway:
                pathway = sherpa_pathway_api(paper.issn)
                cache[paper.issn] = pathway
        else:
            pathway = sherpa_pathway_api(paper.issn)

    return PaperWithOAPathway(oa_pathway=pathway, **paper.dict())
