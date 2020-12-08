from wbf.schemas import Paper, PaperWithOAStatus
from wbf.unpaywall import get_oa_status_and_issn as unpaywall_status_api


def oa_status(paper: Paper) -> PaperWithOAStatus:
    """Enrich a given paper with information about the availability of an open access
    copy collected from the an unpaywall data dump or the unpaywall API.
    """
    oa_status, _ = unpaywall_status_api(paper.doi)

    return PaperWithOAStatus(oa_status=oa_status, **paper.dict())
