import re

from fastapi import APIRouter, Depends, Request, Response
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from fyscience.schemas import OAPathway, FullPaper
from fyscience.routers.api import get_author_with_papers
from fyscience.routers.deps import get_settings, Settings, TEMPLATE_PATH
from starlette.datastructures import URL

html_router = APIRouter()
templates = Jinja2Templates(directory=TEMPLATE_PATH)


def _get_response_headers(request_url: URL):
    headers = {"cache-control": "max-age=3600,public"}
    if request_url.hostname == "dev.freeyourscience.org":
        headers["X-Robots-Tag"] = "noindex,nofollow,nosnippet"
    return headers


def _is_paywalled_and_nocost(paper: FullPaper) -> bool:
    return (
        paper is not None
        and paper.is_open_access is False
        and paper.oa_pathway is OAPathway.nocost
    )


def _render_paper_page(
    doi: str, settings: Settings, request: Request
) -> templates.TemplateResponse:
    host = request.headers["host"]
    serverURL = (
        "https://" + host if host.endswith("freeyourscience.org") else "http://" + host
    )

    return templates.TemplateResponse(
        "paper.html",
        {"request": request, "doi": doi, "serverURL": serverURL},
        headers=_get_response_headers(request.url),
    )


def _render_author_page(
    author_query: str, settings: Settings, request: Request
) -> templates.TemplateResponse:
    author = get_author_with_papers(
        profile=author_query, request=request, settings=settings
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
        headers=_get_response_headers(request.url),
    )


def _simple_template_response(
    template_name: str, request: Request
) -> templates.TemplateResponse:
    """Convenience wrapper for template response initialization."""
    return templates.TemplateResponse(
        template_name, {"request": request}, headers=_get_response_headers(request.url)
    )


def _is_doi_query(string: str) -> bool:
    return re.match("\\b[0-9]{2}.[0-9]+/", string) is not None


@html_router.get("/", response_class=HTMLResponse)
def get_landing_page(request: Request, response: Response):
    return _simple_template_response("landing_page.html", request)


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


@html_router.get("/technology", response_class=HTMLResponse)
def get_technology_html(request: Request):
    return _simple_template_response("technology.html", request)


@html_router.get("/howto", response_class=HTMLResponse)
def get_howto_html(request: Request):
    return _simple_template_response("howto.html", request)


@html_router.get("/republishing", response_class=HTMLResponse)
def get_republishing_html(request: Request):
    return _simple_template_response("republishing.html", request)


@html_router.get("/team", response_class=HTMLResponse)
def get_team_html(request: Request):
    return _simple_template_response("team.html", request)


@html_router.get("/privacy", response_class=HTMLResponse)
def get_privacy_html(request: Request):
    return _simple_template_response("privacy_notice.html", request)
