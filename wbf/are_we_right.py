import os
import json
import argparse
from functools import partial
from typing import List

from wbf.oa_pathway import oa_pathway
from wbf.oa_status import oa_status
from wbf.schemas import (
    OAPathway,
    OAStatus,
    Paper,
    PaperWithOAPathway,
)


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
    parser.add_argument(
        "--pathway-cache",
        type=str,
        default="./pathway.json",
        help="Path to cache open access pathway information at.",
    )
    args = parser.parse_args()

    # Load cache
    pathway_cache = dict()
    if os.path.isfile(args.pathway_cache):
        with open(args.pathway_cache, "r") as fh:
            pathway_cache = json.load(fh)
            print(f"Loaded {len(pathway_cache)} cached ISSN to OA pathway mappings")

    # Load data
    dataset_file_path = os.path.join(
        os.path.dirname(__file__), "..", "tests", "assets", "crossref_subset.json"
    )
    with open(dataset_file_path, "r") as fh:
        input_of_papers = json.load(fh)

    if args.limit:
        input_of_papers = input_of_papers[: args.limit]

    # TODO: Skip papers with ISSNs for which cache says no policy could be found
    input_of_papers = [Paper(**paper) for paper in input_of_papers]

    # Enrich data
    papers_with_oa_status = map(oa_status, input_of_papers)
    papers_with_pathway = map(
        partial(oa_pathway, cache=pathway_cache), papers_with_oa_status
    )

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

    # Save cache
    print(f"Cached {len(pathway_cache)} ISSN to OA pathway mappings")
    with open(args.pathway_cache, "w") as fh:
        json.dump(pathway_cache, fh, indent=2)
