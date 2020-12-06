import os
import json

from wbf.data import calculate_metrics
from wbf.schemas import PaperWithOAPathway


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_calculate_metrics():
    with open(os.path.join(ASSETS_PATH, "papers_enriched_dummy.json"), "r") as fh:
        papers = json.load(fh)

    papers = (PaperWithOAPathway(**paper) for paper in papers)

    n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(papers)

    assert n_oa == 1
    assert n_pathway_nocost == 1
    assert n_pathway_other == 1
    assert n_unknown == 1
