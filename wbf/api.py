import os
from typing import Optional

from fastapi import APIRouter, Header, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from wbf.schemas import PaperWithOAPathway, PaperWithOAStatus, OAPathway
from wbf.unpaywall import get_oa_status_and_issn
from wbf.oa_pathway import oa_pathway
from wbf.deps import get_settings, Settings
from wbf.semantic_scholar import get_dois


TEMPLATE_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "templates")

api_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)


def _get_paper(
    doi: str, unpaywall_email: str, sherpa_api_key: str
) -> Optional[PaperWithOAPathway]:

    oa_status, issn = get_oa_status_and_issn(doi=doi, email=unpaywall_email)
    if issn is None:
        return None

    paper_with_status = PaperWithOAStatus(doi=doi, issn=issn, oa_status=oa_status)

    paper_with_pathway = oa_pathway(paper=paper_with_status, api_key=sherpa_api_key)

    return paper_with_pathway


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
    dois = get_dois(semantic_scholar_id)
    papers = [
        _get_paper(
            doi=doi,
            sherpa_api_key=settings.sherpa_api_key,
            unpaywall_email=settings.unpaywall_email,
        )
        for doi in dois
    ]
    papers = [p for p in papers if p is not None and p.oa_pathway is OAPathway.nocost]

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

    paper = _get_paper(
        doi=doi,
        sherpa_api_key=settings.sherpa_api_key,
        unpaywall_email=settings.unpaywall_email,
    )

    if paper is None or paper.oa_pathway is not OAPathway.nocost:
        raise HTTPException(
            404, f"No paper found with DOI {doi} that can be re-published without fees."
        )

    return paper
