from typing import Optional

from fastapi import APIRouter, Header, HTTPException, Depends
from fastapi.responses import HTMLResponse

from wbf.author_papers import dois_from_semantic_scholar_author_api
from wbf.schemas import PaperWithOAPathway, PaperWithOAStatus
from wbf.oa_status import unpaywall_status_api
from wbf.oa_pathway import oa_pathway
from wbf.deps import get_settings, Settings


api_router = APIRouter()


@api_router.get("/", response_class=HTMLResponse)
def get_landing_page():
    return "<html><h1>HI!</h1></html>"


@api_router.get("/authors")
def get_publications_for_author(
    semantic_scholar_id: str, accept: Optional[str] = Header("text/html")
):
    # TODO: Consider allowing override of accept headers via url parameter

    dois = dois_from_semantic_scholar_author_api(semantic_scholar_id)
    papers = [get_paper(doi) for doi in dois]

    if "text/html" in accept:
        return HTMLResponse(f"<html>{papers}</html>")
    elif "application/json" in accept or "*/*" in accept:
        return papers
    else:
        raise HTTPException(
            406,
            "Only text/html and application/json is available. "
            + f"But neither of them was found in accept header {accept}",
        )


@api_router.get("/papers", response_model=PaperWithOAPathway)
def get_paper(doi: str, settings: Settings = Depends(get_settings)):
    """Get paper with OpenAccess status and pathway for a given DOI."""
    oa_status, issn = unpaywall_status_api(doi=doi, email=settings.unpaywall_email)

    paper_with_status = PaperWithOAStatus(doi=doi, issn=issn, oa_status=oa_status)

    paper_with_pathway = oa_pathway(
        paper=paper_with_status, api_key=settings.sherpa_api_key
    )

    return paper_with_pathway
