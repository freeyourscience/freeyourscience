from copy import deepcopy
from typing import Optional, Union

from fyscience.schemas import (
    OAPathway,
    PaperWithOAStatus,
    PaperWithOAPathway,
    FullPaper,
)
from fyscience.sherpa import get_pathway as sherpa_pathway_api


def oa_pathway(
    paper: Union[PaperWithOAStatus, FullPaper],
    cache=None,
    api_key: Optional[str] = None,
) -> Union[PaperWithOAStatus, FullPaper]:
    """Enrich a given paper with information about the available open access pathway
    collected from the Sherpa API.

    Cache can be anything that exposes ``get(key, default)`` and ``__setitem__``
    """
    details, pathway_uri = None, None
    if paper.is_open_access:
        pathway = OAPathway.already_oa
    elif paper.is_open_access is None:
        pathway = OAPathway.not_attempted
    else:
        if cache is not None:
            pathway = cache.get(paper.issn, None)
            if not pathway:
                pathway, pathway_uri, details = sherpa_pathway_api(paper.issn, api_key)
                cache[paper.issn] = pathway
        else:
            pathway, pathway_uri, details = sherpa_pathway_api(paper.issn, api_key)

    if isinstance(paper, PaperWithOAStatus):
        return PaperWithOAPathway(
            oa_pathway=pathway,
            oa_pathway_uri=pathway_uri,
            oa_pathway_details=details,
            **paper.dict()
        )
    else:
        paper.oa_pathway = pathway
        paper.oa_pathway_uri = pathway_uri
        paper.oa_pathway_details = details
        return paper


def remove_costly_oa_from_publisher_policy(policy: dict) -> dict:
    """A potential input is ``FullPaper.oa_pathway_details[i]``"""
    _policy = deepcopy(policy)

    _policy["permitted_oa"] = [
        poa
        for poa in _policy["permitted_oa"]
        if "additional_oa_fee" in poa and poa["additional_oa_fee"] == "no"
    ]

    return _policy
