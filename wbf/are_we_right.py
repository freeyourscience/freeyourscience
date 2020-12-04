import os
import json
import argparse
from typing import Optional, List

import requests

from wbf.schemas import (
    OAPathway,
    OAStatus,
    Paper,
    PaperWithOAPathway,
    PaperWithOAStatus,
)


def unpaywall_status_api(doi: str, email: Optional[str] = None) -> OAStatus:
    """Fetch information about the availability of an open access version for a given
    DOI from the unpaywall API (api.unpaywall.org)

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
        return OAStatus.not_found

    data = response.json()
    return OAStatus.oa if data["is_oa"] else OAStatus.not_oa


def oa_status(paper: Paper) -> PaperWithOAStatus:
    """Enrich a given paper with information about the availability of an open access
    copy collected from the an unpaywall data dump or the unpaywall API.

    TODO: Use unpaywall dump as first resource and only fall back to API
    """
    oa_status = unpaywall_status_api(paper.doi)

    return PaperWithOAStatus(oa_status=oa_status, **paper.dict())


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
    if not publications or not publications["items"]:
        return OAPathway.not_found

    # TODO: How to handle multiple publishers found for ISSN?

    oa_policies_no_cost = [
        policy
        for policy in publications["items"][0]["publisher_policy"]
        if policy["open_access_prohibited"] == "no"
        and any([perm["additional_oa_fee"] == "no" for perm in policy["permitted_oa"]])
    ]
    if not oa_policies_no_cost:
        return OAPathway.other

    return OAPathway.nocost


def oa_pathway(paper: PaperWithOAStatus) -> PaperWithOAPathway:
    """Enrich a given paper with information about the available open access pathway
    collected from the Sherpa API.

    TODO: Cache publisher policies.
    """
    if paper.oa_status is OAStatus.oa:
        pathway = OAPathway.already_oa
    elif paper.oa_status is OAStatus.not_found:
        pathway = OAPathway.not_attempted
    else:
        pathway = sherpa_pathway_api(paper.issn)

    return PaperWithOAPathway(oa_pathway=pathway, **paper.dict())


def calculate_metrics(papers: List[PaperWithOAPathway]):
    n_oa = 0
    n_pathway_nocost = 0
    n_pathway_other = 0
    n_unknown = 0

    for p in papers:
        if p.oa_status is OAStatus.oa:
            n_oa += 1
        elif p.oa_pathway is OAPathway.nocost:
            n_pathway_nocost += 1
        elif p.oa_pathway is OAPathway.other:
            n_pathway_other += 1
        elif p.oa_status is OAStatus.not_found or p.oa_pathway is OAPathway.not_found:
            n_unknown += 1

    return n_oa, n_pathway_nocost, n_pathway_other, n_unknown


if __name__ == "__main__":
    # TODO: Consider checking against publicly available publishers / ISSNS (e.g. elife)
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--limit",
        type=int,
        default=20,
        help="Limit the number of papers to process, set to 0 to remove limit.",
    )
    args = parser.parse_args()

    # Load data
    dataset_file_path = os.path.join(
        os.path.dirname(__file__), "..", "tests", "assets", "crossref_subset.json"
    )
    with open(dataset_file_path, "r") as fh:
        input_of_papers = json.load(fh)

    if args.limit:
        input_of_papers = input_of_papers[: args.limit]

    input_of_papers = [Paper(**paper) for paper in input_of_papers]

    # Enrich data
    papers_with_oa_status = map(oa_status, input_of_papers)
    papers_with_pathway = map(oa_pathway, papers_with_oa_status)

    # Calculate & report metrics
    n_pubs = len(input_of_papers)
    n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(
        papers_with_pathway
    )

    print(f"looked at {n_pubs} publications")
    print(f"{n_oa} are already OA")
    print(f"{n_pathway_nocost} could be OA at no cost")
    print(f"{n_pathway_other} has other OA pathway(s)")
    print(f"{n_unknown} could not be determined")
