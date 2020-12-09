import os
import argparse
from functools import partial

from wbf.cache import json_filesystem_cache
from wbf.data import load_jsonl, calculate_metrics
from wbf.oa_pathway import oa_pathway
from wbf.oa_status import validate_oa_status_from_s2
from wbf.schemas import PaperWithOAStatus


if __name__ == "__main__":
    # TODO: Consider checking against publicly available publishers / ISSNS (e.g. elife)
    parser = argparse.ArgumentParser()
    # TODO: find way to reintroduce '--limit' for generator based loading
    parser.add_argument(
        "--pathway-cache",
        type=str,
        default="./pathway.json",
        help="Path to cache open access pathway information at.",
    )
    parser.add_argument(
        "--unpaywall-extract",
        type=str,
        default="../tests/assets/unpaywall_subset.jsonl",
        help="Path to extract of unpaywall dataset with doi, issn and oa status",
    )
    args = parser.parse_args()

    # Load data
    dataset_file_path = os.path.join(os.path.dirname(__file__), args.unpaywall_extract)

    # TODO: Skip papers with ISSNs for which cache says no policy could be found
    papers_with_oa_status = (
        PaperWithOAStatus(
            doi=paper["doi"],
            issn=paper["journal_issn_l"],
            oa_status=("oa" if paper["is_oa"] else "not_oa"),
        )
        for paper in load_jsonl(dataset_file_path)
        if paper["journal_issn_l"] is not None
    )

    with json_filesystem_cache(args.pathway_cache) as pathway_cache:
        # Enrich data
        papers_with_s2_validated_oa_status = map(
            validate_oa_status_from_s2, papers_with_oa_status
        )
        papers_with_pathway = map(
            partial(oa_pathway, cache=pathway_cache), papers_with_s2_validated_oa_status
        )

        # Calculate & report metrics
        # TODO: count number of papers from generator
        n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(
            papers_with_pathway
        )

    print(f"{n_oa} are already OA")
    print(f"{n_pathway_nocost} could be OA at no cost")
    print(f"{n_pathway_other} has other OA pathway(s)")
    print(f"{n_unknown} could not be determined")
