import re

from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from loguru import logger

from fyscience.schemas import OAPathway, FullPaper
from fyscience.routers.api import get_paper, get_author_with_papers
from fyscience.routers.deps import get_settings, Settings, TEMPLATE_PATH

html_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)


def _is_paywalled_and_nocost(paper: FullPaper) -> bool:
    return (
        paper is not None
        and paper.is_open_access is False
        and paper.oa_pathway is OAPathway.nocost
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


@html_router.get("/", response_class=HTMLResponse)
def get_landing_page(request: Request):
    return templates.TemplateResponse(
        "landing_page.html", {"request": request, "n_nocost_papers": "46.796.300"}
    )


@html_router.get("/search", response_class=HTMLResponse)
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


@html_router.get("/glossary", response_class=HTMLResponse)
def get_glossary_html(request: Request):
    return templates.TemplateResponse("glossary.html", {"request": request})


@html_router.get("/republish", response_class=HTMLResponse)
def get_republish_html(request: Request):
    return templates.TemplateResponse("republish.html", {"request": request})


@html_router.get("/legal", response_class=HTMLResponse)
def get_legal_html(request: Request):
    return templates.TemplateResponse("legal.html", {"request": request})


@html_router.get("/team", response_class=HTMLResponse)
def get_team_html(request: Request):
    return templates.TemplateResponse("team.html", {"request": request})
