import os
import json
from typing import Optional, Tuple, List

import requests
from loguru import logger

from fyscience.schemas import OAPathway


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


def get_pathway(
    issn: str, api_key: Optional[str] = None
) -> Tuple[OAPathway, Optional[List[dict]]]:
    """Fetch information about the available open access pathways for the publciation
    (e.g. journal) with a given ISSN from the Sherpa API (v2.sherpa.ac.uk)

    Returns
    -------
    OA Pathway
    URI to the Sherpa publication details
    publisher policies with no cost pathways

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
    if response.status_code != 200:
        logger.error(
            {
                "event": "sherpa_get_pathway",
                "message": "response_not_ok",
                "issn": issn,
                "status_code": response.status_code,
                "response": response.content.decode() if response.content else "",
            }
        )
        return OAPathway.not_found, None

    publications = response.json()
    try:
        if (
            not publications
            or not publications["items"]
            or not publications["items"][0]["publisher_policy"]
        ):
            return OAPathway.not_found, None
    except Exception as e:
        print("ERROR with publications:", json.dumps(publications), e)
        return OAPathway.not_found, None

    policies = {}
    for publication in publications["items"]:
        for policy in publication["publisher_policy"]:
            # Since we are flattening all policies across publications, add the
            # publication URI to all policies
            policy["sherpa_publication_uri"] = publication["system_metadata"]["uri"]
            policies[policy["id"]] = policy

    oa_policies_no_cost = list(filter(has_no_cost_oa_policy, list(policies.values())))

    if not oa_policies_no_cost:
        return OAPathway.other, None

    return OAPathway.nocost, oa_policies_no_cost
