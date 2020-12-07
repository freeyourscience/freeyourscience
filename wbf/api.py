import os
from typing import Optional

from fastapi import APIRouter, Header, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from wbf.author_papers import (
    # TODO: Switch back to official API once stable
    crawl_dois_from_semantic_scholar_author_page as dois_from_semantic_scholar_author_api,
)
from wbf.schemas import PaperWithOAPathway, PaperWithOAStatus
from wbf.oa_status import unpaywall_status_api
from wbf.oa_pathway import oa_pathway
from wbf.deps import get_settings, Settings


TEMPLATE_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "templates")

api_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)


@api_router.get("/", response_class=HTMLResponse)
def get_landing_page(request: Request):
    return templates.TemplateResponse(
        "landing_page.html", {"request": request, "n_nocost_papers": "46.796.300"}
    )


@api_router.get("/authors")
def get_publications_for_author(
    semantic_scholar_id: str,
    request: Request,
    accept: Optional[str] = Header("text/html"),
    settings: Settings = Depends(get_settings),
):
    # TODO: Consider allowing override of accept headers via url parameter

    # TODO: Semantic scholar only seems to have the DOI of the preprint and not the
    #       finally published paper's DOI (see e.g. semantic scholar ID 51453144)
    dois = dois_from_semantic_scholar_author_api(semantic_scholar_id)
    papers = [get_paper(doi, settings=settings) for doi in dois]

    if "text/html" in accept:
        return templates.TemplateResponse(
            "publications_for_author.html",
            {"request": request, "papers": [p for p in papers]},
        )
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
