import os
import json
import argparse
from typing import Optional

import requests


def unpaywall_status_api(doi: str, email: Optional[str] = None) -> str:
    """Fetch information about the availability of an open access version for a given
    DOI from the unpaywall API (api.unpaywall.org) and return "oa", "not-oa" or
    "not-found" as the DOI's open access status.

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
        return "not-found"

    data = response.json()
    return "oa" if data["is_oa"] else "not-oa"


def oa_status(paper: dict) -> dict:
    """Enrich a given paper with information about the availability of an open access
    copy collected from the an unpaywall data dump or the unpaywall API, which is added
    as an "oa_status" key to the given dictionary that can contain any of the following
    values:
      * oa (the paper is available as open access)
      * not-oa (no open access version of the paper is available)
      * not-found (in case no paper was found or there was an issue with the request)

    TODO: Use unpaywall dump as first resource and only fall back to API
    """
    paper["oa_status"] = unpaywall_status_api(paper["doi"])

    return paper


def sherpa_pathway_api(issn: str, api_key: Optional[str] = None) -> str:
    """Fetch information about the available open access pathways for the publisher that
    owns a given ISSN from the Sherpa API (v2.sherpa.ac.uk) and return one of the
    following values:
      * already-oa (the paper is already available as open access)
      * not-attempted (there is no information about the open access availability)
      * nocost (the publisher policy allows for re-publishing without additional cost)
      * other (the publisher policy doesn't allow for free re-publishing)
      * not-found (no information about the publisher policy could be retreived)

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
        return "not-found"

    publications = response.json()
    if not publications or not publications["items"]:
        return "not-found"

    # TODO: How to handle multiple publishers found for ISSN?

    oa_policies_no_cost = [
        policy
        for policy in publications["items"][0]["publisher_policy"]
        if policy["open_access_prohibited"] == "no"
        and any([perm["additional_oa_fee"] == "no" for perm in policy["permitted_oa"]])
    ]
    if not oa_policies_no_cost:
        return "other"

    return "nocost"


def oa_pathway(paper: dict) -> dict:
    """Enrich a given paper with information about the available open access pathway
    collected from the Sherpa API (v2.sherpa.ac.uk), which is added as a "pathway" key
    to the given dictionary that can contain any of the following values:
      * already-oa (the paper is already available as open access)
      * not-attempted (there is no information about the open access availability)
      * nocost (the publisher policy allows for re-publishing without additional cost)
      * other (the publisher policy doesn't allow for free re-publishing)
      * not-found (no information about the publisher policy could be retreived)

    TODO: Cache publisher policies.
    """
    if paper["oa_status"] == "oa":
        paper["pathway"] = "already-oa"
        return paper

    if paper["oa_status"] == "not-found":
        paper["pathway"] = "not-attempted"
        return paper

    paper["pathway"] = sherpa_pathway_api(paper["issn"])

    return paper


def calculate_metrics(papers):
    n_oa = 0
    n_pathway_nocost = 0
    n_pathway_other = 0
    n_unknown = 0

    for p in papers:
        if p["oa_status"] == "oa":
            n_oa += 1
        elif p["pathway"] == "nocost":
            n_pathway_nocost += 1
        elif p["pathway"] == "other":
            n_pathway_other += 1
        elif p["oa_status"] == "not-found" or p["pathway"] == "not-found":
            n_unknown += 1

    return n_oa, n_pathway_nocost, n_pathway_other, n_unknown


if __name__ == "__main__":
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
