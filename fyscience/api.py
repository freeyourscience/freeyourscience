import json
import re

from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from loguru import logger

from fyscience.schemas import PaperWithOAStatus, OAPathway, FullPaper, Author
from fyscience.unpaywall import get_paper as unpaywall_get_paper
from fyscience.oa_pathway import oa_pathway, remove_costly_oa_from_publisher_policy
from fyscience.oa_status import validate_oa_status_from_s2
from fyscience import orcid, semantic_scholar, crossref
from fyscience.deps import get_settings, Settings, TEMPLATE_PATH


api_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)

# TODO: Sanitize user input


def _construct_paper(
    doi: str, unpaywall_email: str, sherpa_api_key: str, s2_api_key: str
) -> FullPaper:

    paper = unpaywall_get_paper(doi=doi, email=unpaywall_email)
    if paper is None or paper.issn is None:
        logger.warning(
            {
                "message": "unknown_doi",
                "provider": "unpaywall",
                "doi": doi,
                "paper": json.dumps(paper.dict()),
            }
        )
        return FullPaper(doi=doi)

    title = paper.title
    journal = paper.journal
    year = paper.year
    authors = paper.authors
    oa_location_url = paper.oa_location_url

    paper = PaperWithOAStatus(
        doi=doi, issn=paper.issn, is_open_access=paper.is_open_access
    )
    # TODO: Don't do this twice if the author papers already have the s2 status
    #       Potentially move towards an enrich as opposed to a construct approach
    paper = validate_oa_status_from_s2(paper, s2_api_key)

    paper = oa_pathway(paper=paper, api_key=sherpa_api_key)
    if paper.oa_pathway is OAPathway.not_found:
        logger.warning(
            {
                "message": "no_policy_for_issn",
                "provider": "sherpa",
                "issn": paper.issn,
                "paper": json.dumps(paper.dict()),
            }
        )

    # TODO: Add this title straight away, but this requires moving to support FullPaper
    #       in all places (most notably oa_pathway)
    paper = FullPaper(
        title=title,
        journal=journal,
        authors=authors,
        year=year,
        oa_location_url=oa_location_url,
        **paper.dict(),
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


@api_router.get("/api/authors", response_model=Author)
def get_author_with_papers(profile: str, settings: Settings = Depends(get_settings)):
    """Get all information associated with a specific author search string, which can
    either be an ORCID, Semantic Scholar Profile ID or URL, or an author name to be
    searched for with the Crossref meta-data search.
    The returned ``Author.papers`` contains a list of papers provided by the chosen
    search method, which is not fully populated with all information.
    To fetch fully populated papers, use ``GET api/papers?doi=...``
    """
    if orcid.is_orcid(profile):
        author = orcid.get_author_with_papers(profile)
    else:
        author_id = semantic_scholar.extract_profile_id_from_url(profile)
        if author_id.isnumeric():
            # TODO: Semantic scholar only seems to have the DOI of the preprint and not
            #       the finally published paper's DOI
            #       (see e.g. semantic scholar ID 51453144)
            author = semantic_scholar.get_author_with_papers(
                author_id, settings.s2_api_key
            )
        else:
            author = crossref.get_author_with_papers(profile)

    if author is None:
        raise HTTPException(404, f"No author found for {profile}")

    author.papers = [] if author.papers is None else author.papers
    # TODO: Resolve duplicate DOIs more intelligently (always choose the more recent
    #       version, or the one with more info)
    unique_papers = {p.doi: p for p in author.papers}
    author.papers = list(unique_papers.values())

    return author


@api_router.get("/api/papers", response_model=FullPaper)
def get_paper(doi: str, settings: Settings = Depends(get_settings)):
    """Get paper with OpenAccess status and pathway for a given DOI."""
    paper = _construct_paper(
        doi=doi,
        sherpa_api_key=settings.sherpa_api_key,
        unpaywall_email=settings.unpaywall_email,
        s2_api_key=settings.s2_api_key,
    )

    return paper


@api_router.get("/debug", include_in_schema=False)
def get_request_headers(request: Request):
    return {"headers": request.headers, "url_scheme": request.url.scheme}


@api_router.get("/", response_class=HTMLResponse, include_in_schema=False)
def get_landing_page(request: Request):
    return templates.TemplateResponse(
        "landing_page.html", {"request": request, "n_nocost_papers": "46.796.300"}
    )


def _render_paper_page(
    doi: str, settings: Settings, request: Request
) -> templates.TemplateResponse:
    paper = get_paper(doi=doi, settings=settings)

    if _is_paywalled_and_nocost(paper):
        category = "paywalled_nocost"
    elif paper.is_open_access:
        category = "already_oa"
    elif paper.oa_pathway is OAPathway.other:
        category = "other_policies"
    else:
        category = "issues"

    return templates.TemplateResponse(
        "paper.html", {"request": request, "paper": paper, "category": category}
    )


def _render_author_page(
    author_query: str, settings: Settings, request: Request
) -> templates.TemplateResponse:
    author = get_author_with_papers(author_query, settings)

    logger.debug(
        {
            "query": author_query,
            "provider": author.provider,
            "n_papers": len(author.papers),
        }
    )

    host = request.headers["host"]
    serverURL = (
        "https://" + host if host.endswith("freeyourscience.org") else "http://" + host
    )

    return templates.TemplateResponse(
        "publications_for_author.html",
        {
            "request": request,
            "serverURL": serverURL,
            "author": author,
            "search_string": author_query,
            "dois": [p.doi for p in author.papers],
        },
    )


def _is_doi_query(string: str) -> bool:
    return re.match("\\b[0-9]{2}.[0-9]+/", string) is not None


@api_router.get("/search", response_class=HTMLResponse, include_in_schema=False)
def get_search_result_html(
    query: str, request: Request, settings: Settings = Depends(get_settings)
):
    """Allows author name, ORCID, Semantic Scholar ID / profile URL and DOI queries."""

    if _is_doi_query(query):
        return _render_paper_page(doi=query, settings=settings, request=request)
    else:
        return _render_author_page(
            author_query=query, settings=settings, request=request
        )


@api_router.get("/about", response_class=HTMLResponse, include_in_schema=False)
def get_about_html(request: Request):
    return templates.TemplateResponse("about.html", {"request": request})
