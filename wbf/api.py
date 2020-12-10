from typing import Optional, List

from fastapi import APIRouter, Header, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from wbf.schemas import PaperWithOAPathway, PaperWithOAStatus, OAPathway, FullPaper
from wbf.unpaywall import get_paper as unpaywall_get_paper
from wbf.oa_pathway import oa_pathway, remove_costly_oa_from_publisher_policy
from wbf.oa_status import validate_oa_status_from_s2
from wbf.deps import get_settings, Settings, TEMPLATE_PATH
from wbf.semantic_scholar import get_author_with_papers, extract_profile_id_from_url


api_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)


def _get_non_oa_no_cost_paper(
    doi: str, unpaywall_email: str, sherpa_api_key: str
) -> Optional[FullPaper]:

    paper = unpaywall_get_paper(doi=doi, email=unpaywall_email)
    if paper is None or paper.issn is None:
        return None

    title = paper.title

    paper = PaperWithOAStatus(
        doi=doi, issn=paper.issn, is_open_access=paper.is_open_access
    )
    paper = validate_oa_status_from_s2(paper)
    if paper.is_open_access or paper.is_open_access is None:
        return None

    paper = oa_pathway(paper=paper, api_key=sherpa_api_key)
    if paper.oa_pathway is not OAPathway.nocost:
        return None

    # TODO: Add this title straight away, but this requires moving to support FullPaper
    #       in all places (most notably oa_pathway)
    paper = FullPaper(title=title, **paper.dict())

    return paper


def _filter_non_oa_no_cost_papers(
    papers: List[FullPaper], unpaywall_email: str, sherpa_api_key: str
) -> List[FullPaper]:
    papers = [p for p in papers if p.doi is not None]
    papers = [
        _get_non_oa_no_cost_paper(p.doi, unpaywall_email, sherpa_api_key)
        for p in papers
        if p.doi is not None and p.is_open_access is False
    ]
    papers = [p for p in papers if p is not None and p.oa_pathway is OAPathway.nocost]
    return papers


def _remove_costly_oa_paths_from_oa_pathway_details(paper: FullPaper) -> FullPaper:
    if paper.oa_pathway_details is None:
        return paper

    paper.oa_pathway_details = [
        remove_costly_oa_from_publisher_policy(pwd) for pwd in paper.oa_pathway_details
    ]
    return paper


@api_router.get("/", response_class=HTMLResponse)
def get_landing_page(request: Request):
    return templates.TemplateResponse(
        "landing_page.html", {"request": request, "n_nocost_papers": "46.796.300"}
    )


@api_router.get("/authors")
def get_publications_for_author(
    semantic_scholar_profile: str,
    request: Request,
    accept: str = Header("text/html"),
    settings: Settings = Depends(get_settings),
):
    # TODO: Consider allowing override of accept headers via url parameter

    # TODO: Semantic scholar only seems to have the DOI of the preprint and not the
    #       finally published paper's DOI (see e.g. semantic scholar ID 51453144)
    author_id = extract_profile_id_from_url(semantic_scholar_profile)
    author = get_author_with_papers(author_id)
    if author is None:
        raise HTTPException(404, f"No author found for {semantic_scholar_profile}")

    author.papers = [] if author.papers is None else author.papers
    author.papers = _filter_non_oa_no_cost_papers(
        papers=author.papers,
        unpaywall_email=settings.unpaywall_email,
        sherpa_api_key=settings.sherpa_api_key,
    )
    author.papers = [
        _remove_costly_oa_paths_from_oa_pathway_details(p) for p in author.papers
    ]

    if "text/html" in accept:
        return templates.TemplateResponse(
            "publications_for_author.html",
            {"request": request, "author": author},
        )
    elif "application/json" in accept or "*/*" in accept:
        return author
    else:
        raise HTTPException(
            406,
            "Only text/html and application/json is available. "
            + f"But neither of them was found in accept header {accept}",
        )


@api_router.get("/papers", response_model=PaperWithOAPathway)
def get_paper(
    doi: str,
    request: Request,
    accept: str = Header("text/html"),
    settings: Settings = Depends(get_settings),
):
    """Get paper with OpenAccess status and pathway for a given DOI."""

    paper = _get_non_oa_no_cost_paper(
        doi=doi,
        sherpa_api_key=settings.sherpa_api_key,
        unpaywall_email=settings.unpaywall_email,
    )

    if paper is None:
        raise HTTPException(
            404,
            f"No paywalled paper found with DOI {doi} that can be re-published without "
            + "fees.",
        )

    if "text/html" in accept:
        return templates.TemplateResponse(
            "paper.html", {"request": request, "paper": paper}
        )
    elif "application/json" in accept or "*/*" in accept:
        return paper
    else:
        raise HTTPException(
            406,
            "Only text/html and application/json is available. "
            + f"But neither of them was found in accept header {accept}",
        )
