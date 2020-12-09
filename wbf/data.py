from typing import List
import json

from wbf.schemas import OAPathway, PaperWithOAPathway


def load_jsonl(filepath):
    with open(filepath, "r") as fh:
        for line in fh:
            yield json.loads(line)


def calculate_metrics(papers: List[PaperWithOAPathway]):
    n_oa = 0
    n_pathway_nocost = 0
    n_pathway_other = 0
    n_unknown = 0

    for p in papers:
        if p.is_open_access:
            n_oa += 1
        elif p.oa_pathway is OAPathway.nocost:
            n_pathway_nocost += 1
        elif p.oa_pathway is OAPathway.other:
            n_pathway_other += 1
        elif p.is_open_access is None or p.oa_pathway is OAPathway.not_found:
            n_unknown += 1

    return n_oa, n_pathway_nocost, n_pathway_other, n_unknown
