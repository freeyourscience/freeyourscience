import os
import json
import argparse
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
