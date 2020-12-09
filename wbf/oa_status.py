from wbf.schemas import Paper, PaperWithOAStatus, OAStatus
from wbf.unpaywall import get_oa_status_and_issn as unpaywall_status_api
from wbf.semantic_scholar import get_paper as s2_get_paper


def validate_oa_status_from_s2(paper: PaperWithOAStatus) -> PaperWithOAStatus:
    if paper.oa_status is not OAStatus.oa:
        s2_paper = s2_get_paper(paper.doi)
        if s2_paper is not None and s2_paper.is_open_access:
            paper.oa_status = OAStatus.oa

    return paper


def oa_status(paper: Paper) -> PaperWithOAStatus:
    """Enrich a given paper with information about the availability of an open access
    copy collected from the an unpaywall data dump or the unpaywall API.
    """
    oa_status, _ = unpaywall_status_api(paper.doi)

    paper_with_status = PaperWithOAStatus(oa_status=oa_status, **paper.dict())
    paper_with_status = validate_oa_status_from_s2(paper_with_status)

    return paper_with_status
