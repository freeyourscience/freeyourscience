import os
import json
from typing import Optional

import requests


def unpaywall_status(paper: dict) -> dict:
    if paper["doi"] == "10.1011/111111":
        paper["unpaywall_status"] = "oa"
    elif paper["doi"] == "10.1011/222222":
        paper["unpaywall_status"] = "not-oa"
    else:
        paper["unpaywall_status"] = "not-found"

    return paper


def oa_pathway(paper: dict, api_key: Optional[str] = None) -> dict:
    """Enrich a given paper with information about the available open access pathway
    collected from the Sherpa API (v2.sherpa.ac.uk), which is added as a "pathway" key
    to the given dictionary that can contain any of the following values:
      * already-oa (the paper is already available as open access)
      * not-attempted (there is no information about the open access availability)
      * nocost (the publisher policy allows for re-publishing without additional cost)
      * other (the publisher policy doesn't allow for free re-publishing)
      * not-found (no information about the publisher policy could be retreived)

    TODO: Cache publisher policies.

    Raises
    ------
    RuntimeError
        In case no Sherpa API key is passed to the function as an argument and none is
        found in the ``SHERPA_API_KEY`` environment variable.
        To obtain an API key, register at https://v2.sherpa.ac.uk/cgi/register
    """
    api_key = os.getenv("SHERPA_API_KEY", api_key)
    if api_key is None:
        raise RuntimeError(
            "No Sherpa API key available in the 'SHERPA_API_KEY' environment variable."
        )

    if paper["unpaywall_status"] == "oa":
        paper["pathway"] = "already-oa"
        return paper

    if paper["unpaywall_status"] == "not-found":
        paper["pathway"] = "not-attempted"
        return paper

    response = requests.get(
        "https://v2.sherpa.ac.uk/cgi/retrieve?"
        + f"item-type=publication&api-key={api_key}&format=Json&"
        + f'filter=[["issn","equals","{paper["issn"]}"]]'
    )
    if not response.ok:
        paper["pathway"] = "not-found"
        return paper

    publications = response.json()
    if not publications or not publications["items"]:
        paper["pathway"] = "not-found"
        return paper

    # TODO: How to handle multiple publishers found for ISSN?

    oa_policies_no_cost = [
        policy
        for policy in publications["items"][0]["publisher_policy"]
        if policy["open_access_prohibited"] == "no"
        and any([perm["additional_oa_fee"] == "no" for perm in policy["permitted_oa"]])
    ]
    if not oa_policies_no_cost:
        paper["pathway"] = "other"
        return paper

    paper["pathway"] = "nocost"
    return paper


def calculate_metrics(papers):
    n_oa = 0
    n_pathway_nocost = 0
    n_pathway_other = 0
    n_unknown = 0

    for p in papers:
        if p["unpaywall_status"] == "oa":
            n_oa += 1
        elif p["pathway"] == "nocost":
            n_pathway_nocost += 1
        elif p["pathway"] == "other":
            n_pathway_other += 1
        elif p["unpaywall_status"] == "not-found" or p["pathway"] == "not-found":
            n_unknown += 1

    return n_oa, n_pathway_nocost, n_pathway_other, n_unknown


if __name__ == "__main__":
    dataset_file_path = os.path.join(
        os.path.dirname(__file__), "..", "tests", "assets", "crossref_subset.json"
    )
    with open(dataset_file_path, "r") as fh:
        input_of_papers = json.load(fh)

    n_pubs = len(input_of_papers)

    papers_with_oa_status = map(unpaywall_status, input_of_papers)
    papers_with_pathway = map(oa_pathway, papers_with_oa_status)

    n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(
        papers_with_pathway
    )

    print(f"looked at {n_pubs} publications")
    print(f"{n_oa} are already OA")
    print(f"{n_pathway_nocost} could be OA at no cost")
    print(f"{n_pathway_other} has other OA pathway(s)")
    print(f"{n_unknown} could not be determined")
