from typing import Optional

from wbf.schemas import OAStatus, OAPathway, PaperWithOAStatus, PaperWithOAPathway
from wbf.sherpa import get_pathway as sherpa_pathway_api

# TODO: Consider for service version that nocost is currently assigned to pathways with
# additional prerequisites (e.g. specific funders or funders mandating OA)
# TODO: For service version, check if embargo still preventing OA and don't recommend
# embargoed papers for re-publication


def oa_pathway(
    paper: PaperWithOAStatus, cache=None, api_key: Optional[str] = None
) -> PaperWithOAPathway:
    """Enrich a given paper with information about the available open access pathway
    collected from the Sherpa API.

    Cache can be anything that exposes ``get(key, default)`` and ``__setitem__``
    """
    details = None
    if paper.oa_status is OAStatus.oa:
        pathway = OAPathway.already_oa
    elif paper.oa_status is OAStatus.not_found:
        pathway = OAPathway.not_attempted
    else:
        if cache is not None:
            pathway = cache.get(paper.issn, None)
            if not pathway:
                pathway, details = sherpa_pathway_api(paper.issn, api_key)
                cache[paper.issn] = pathway
        else:
            pathway, details = sherpa_pathway_api(paper.issn, api_key)

    return PaperWithOAPathway(
        oa_pathway=pathway, oa_pathway_details=details, **paper.dict()
    )
