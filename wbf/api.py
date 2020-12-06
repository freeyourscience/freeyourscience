from typing import Optional

from fastapi import APIRouter, Header, HTTPException
from fastapi.responses import HTMLResponse

from wbf.schemas import PaperWithOAPathway

api_router = APIRouter()


@api_router.get("/", response_class=HTMLResponse)
def get_landing_page():
    return "<html><h1>HI!</h1></html>"


@api_router.get("/authors")
def get_publications_for_author(
    semantic_scholar_id: str, accept: Optional[str] = Header("text/html")
):
    # TODO: Consider allowing override of accept headers via url parameter
    papers = [
        PaperWithOAPathway(
            oa_status="not_oa",
            doi="10.1007/s00580-005-0536-8",
            issn="1618-5641",
            oa_pathway="nocost",
        ),
        PaperWithOAPathway(
            oa_status="not_oa",
            doi="10.2307/2438925",
            issn="0002-9122",
            oa_pathway="nocost",
        ),
    ]

    if "text/html" in accept:
        return HTMLResponse("<html>Publications with OA status go here.</html>")
    elif "application/json" in accept or "*/*" in accept:
        return papers
    else:
        raise HTTPException(
            406,
            "Only text/html and application/json is available. "
            + f"But neither of them was found in accept header {accept}",
        )


@api_router.get("/papers", response_model=PaperWithOAPathway)
def get_paper(doi: str):
    return PaperWithOAPathway(
        oa_status="not_oa",
        doi="10.1007/s00580-005-0536-8",
        issn="1618-5641",
        oa_pathway="nocost",
    )
