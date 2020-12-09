from wbf.schemas import Paper, PaperWithOAStatus
from wbf.unpaywall import get_paper as unpaywall_get_paper
from wbf.semantic_scholar import get_paper as s2_get_paper


def validate_oa_status_from_s2(paper: PaperWithOAStatus) -> PaperWithOAStatus:
    if not paper.is_open_access:
        s2_paper = s2_get_paper(paper.doi)
        if s2_paper is not None and s2_paper.is_open_access is not None:
            paper.is_open_access = s2_paper.is_open_access

    return paper


def oa_status(paper: Paper) -> PaperWithOAStatus:
    """Enrich a given paper with information about the availability of an open access
    copy collected from the an unpaywall data dump or the unpaywall API.
    """
    unpaywall_paper = unpaywall_get_paper(paper.doi)
    is_open_access = None if unpaywall_paper is None else unpaywall_paper.is_open_access

    paper_with_status = PaperWithOAStatus(is_open_access=is_open_access, **paper.dict())
    paper_with_status = validate_oa_status_from_s2(paper_with_status)

    return paper_with_status
