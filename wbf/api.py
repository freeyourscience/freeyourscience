from fastapi import APIRouter, Header, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from loguru import logger

from wbf.schemas import PaperWithOAStatus, OAPathway, FullPaper
from wbf.unpaywall import get_paper as unpaywall_get_paper
from wbf.oa_pathway import oa_pathway, remove_costly_oa_from_publisher_policy
from wbf.oa_status import validate_oa_status_from_s2
from wbf import orcid, semantic_scholar, crossref
from wbf.deps import get_settings, Settings, TEMPLATE_PATH


api_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)

# TODO: Sanitize user input


def _construct_paper(doi: str, unpaywall_email: str, sherpa_api_key: str) -> FullPaper:

    paper = unpaywall_get_paper(doi=doi, email=unpaywall_email)
    if paper is None or paper.issn is None:
        return FullPaper(doi=doi, issn=paper.issn)

    title = paper.title
    journal = paper.journal
    year = paper.year
    authors = paper.authors

    paper = PaperWithOAStatus(
        doi=doi, issn=paper.issn, is_open_access=paper.is_open_access
    )
    # TODO: Don't do this twice if the author papers already have the s2 status
    #       Potentially move towards an enrich as opposed to a construct approach
    paper = validate_oa_status_from_s2(paper)

    paper = oa_pathway(paper=paper, api_key=sherpa_api_key)

    # TODO: Add this title straight away, but this requires moving to support FullPaper
    #       in all places (most notably oa_pathway)
    paper = FullPaper(
        title=title, journal=journal, authors=authors, year=year, **paper.dict()
    )

    return paper


def _is_paywalled_and_nocost(paper: FullPaper) -> bool:
    return (
        paper is not None
        and paper.is_open_access is False
        and paper.oa_pathway is OAPathway.nocost
    )


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
    profile: str,
    request: Request,
    accept: str = Header("text/html"),
    settings: Settings = Depends(get_settings),
):
    # TODO: Consider allowing override of accept headers via url parameter

    if orcid.is_orcid(profile):
        author = orcid.get_author_with_papers(profile)
    else:
        author_id = semantic_scholar.extract_profile_id_from_url(profile)
        if author_id.isnumeric():
            # TODO: Semantic scholar only seems to have the DOI of the preprint and not
            #       the finally published paper's DOI
            #       (see e.g. semantic scholar ID 51453144)
            author = semantic_scholar.get_author_with_papers(author_id)
        else:
            author = crossref.get_author_with_papers(profile)

    if author is None:
        raise HTTPException(404, f"No author found for {profile}")

    author.papers = [] if author.papers is None else author.papers
    author.papers = [
        _construct_paper(p.doi, settings.unpaywall_email, settings.sherpa_api_key)
        for p in author.papers
    ]
    author.papers = [
        _remove_costly_oa_paths_from_oa_pathway_details(p) for p in author.papers
    ]

    author.papers = sorted(
        author.papers,
        key=lambda p: float("inf") if p.year is None else p.year,
        reverse=True,
    )

    papers_not_oa_nocost = []
    papers_other_policies = []
    papers_already_oa = []
    papers_with_issues = []
    for p in author.papers:
        if _is_paywalled_and_nocost(p):
            papers_not_oa_nocost.append(p)
        elif p.is_open_access:
            papers_already_oa.append(p)
        elif p.oa_pathway is OAPathway.other:
            papers_other_policies.append(p)
        else:
            papers_with_issues.append(p)

    logger.debug(
        {
            "profile": profile,
            "provider": author.provider,
            "n_papers": len(author.papers),
        }
    )

    if "text/html" in accept:
        return templates.TemplateResponse(
            "publications_for_author.html",
            {
                "request": request,
                "author": author,
                "papers_not_oa_nocost": papers_not_oa_nocost,
                "papers_other_policies": papers_other_policies,
                "papers_already_oa": papers_already_oa,
                "papers_with_issues": papers_with_issues,
            },
        )
    elif "application/json" in accept or "*/*" in accept:
        return author
    else:
        raise HTTPException(
            406,
            "Only text/html and application/json is available. "
            + f"But neither of them was found in accept header {accept}",
        )


@api_router.get("/papers", response_model=FullPaper)
def get_paper(
    doi: str,
    request: Request,
    accept: str = Header("text/html"),
    settings: Settings = Depends(get_settings),
):
    """Get paper with OpenAccess status and pathway for a given DOI."""
    paper = _construct_paper(
        doi=doi,
        sherpa_api_key=settings.sherpa_api_key,
        unpaywall_email=settings.unpaywall_email,
    )

    if not _is_paywalled_and_nocost(paper):
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
