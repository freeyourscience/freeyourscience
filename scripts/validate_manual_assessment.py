import os
from functools import partial

from wbf.cache import json_filesystem_cache
from wbf.data import load_jsonl
from wbf.schemas import PaperWithOAPathway, Paper
from wbf.oa_status import oa_status
from wbf.oa_pathway import oa_pathway


HERE = os.path.abspath(os.path.dirname(__file__))


if __name__ == "__main__":
    # load manually entered data (doi, issn, oa status, oa pathway)
    manual_references = [
        PaperWithOAPathway(
            doi=paper["doi"],
            issn=paper["journal_issn_l"],
            is_open_access=paper["is_oa"],
            oa_pathway=paper["oa_pathway"],
        )
        for paper in load_jsonl(
            os.path.join(HERE, "../tests/assets/manual_validation_set.jsonl")
        )
    ]

    # construct list of papers (no oa status, no pathway)
    base_papers = [Paper(doi=paper.doi, issn=paper.issn) for paper in manual_references]

    # enricht list of papers with status and pathway
    with json_filesystem_cache(os.path.join(HERE, "../pathway.json")) as pathway_cache:
        papers_with_status = [oa_status(paper) for paper in base_papers]
        papers_with_pathways = [
            partial(oa_pathway, cache=pathway_cache)(paper)
            for paper in papers_with_status
        ]

    # compare enriched lit with manually entered data
    for manual, automatic in zip(manual_references, papers_with_pathways):
        if manual != automatic:
            print(f"Conflict!\nM:{manual}\nA:{automatic}")
