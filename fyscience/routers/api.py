import json

from fastapi import APIRouter, HTTPException, Depends, Request, Response
from loguru import logger

from fyscience.schemas import OAPathway, FullPaper, Author, LogEntry
from fyscience.unpaywall import get_paper as unpaywall_get_paper
from fyscience.oa_pathway import oa_pathway
from fyscience.oa_status import validate_oa_status_from_s2_and_zenodo
from fyscience import openaccessbutton, orcid, semantic_scholar, crossref
from fyscience.routers.deps import get_settings, Settings


api_router = APIRouter()


@api_router.get("/api/authors", response_model=Author)
def get_author_with_papers(
    profile: str, request: Request, settings: Settings = Depends(get_settings)
):
    """Get all information associated with a specific author search string, which can
    either be an ORCID, Semantic Scholar Profile ID or URL, or an author name to be
    searched for with the Crossref meta-data search.
    The returned ``Author.paper_ids`` contains a list of DOIs or S2 paper IDs provided
    by the chosen search method.
    To fetch fully populated papers, use ``GET api/papers?doi=...``
    """
    author = None

    extracted_orcid = orcid.extract_orcid(profile)
    if extracted_orcid is not None:
        author = orcid.get_author_with_papers(extracted_orcid)

    if author is None:
        author_id = semantic_scholar.extract_profile_id_from_url(profile)
        if not author_id.isnumeric():
            author_id = semantic_scholar.get_author_id(profile, settings.s2_api_key)

        if author_id is not None:
            author = semantic_scholar.get_author_with_papers(
                author_id, settings.s2_api_key
            )

    if author is None:
        author = crossref.get_author_with_papers(profile)

    if author is None:
        logger.info(
            {
                "event": "get_author_with_papers",
                "message": "no_author_found",
                "search_profile": profile,
                "trace_context": request.headers.get("x-cloud-trace-context"),
            }
        )
        raise HTTPException(404, f"No author found for {profile}")

    # TODO: Resolve duplicate DOIs more intelligently (always choose the more recent
    #       version, or the one with more info)
    author.paper_ids = list(set(author.paper_ids))

    logger.info(
        {
            "event": "get_author_with_papers",
            "message": "author_found",
            "search_profile": profile,
            "provider": author.provider,
            "n_papers": len(author.paper_ids),
            "trace_context": request.headers.get("x-cloud-trace-context"),
        }
    )

    return author


def extract_doi(input: str) -> str:
    return input.split("doi.org/")[-1]


@api_router.get("/api/papers", response_model=FullPaper)
def get_paper(
    paper_id: str,
    request: Request,
    response: Response,
    settings: Settings = Depends(get_settings),
):
    """Get paper with OpenAccess status and pathway for a given DOI."""
    response.headers["cache-control"] = "max-age=3600,public"

    doi = extract_doi(paper_id)

    if "/" not in paper_id:
        paper = semantic_scholar.get_paper(paper_id)

        if paper is None:
            raise HTTPException(404, f"No paper found for {paper_id}")

        doi = paper.doi

    paper = unpaywall_get_paper(doi=doi, email=settings.unpaywall_email)
    if paper is None:
        paper = FullPaper(doi=doi)

    if paper.issn is None and not paper.is_open_access:
        logger.warning(
            {
                "event": "get_paper",
                "message": "no_issn_for_paywalled_pub",
                "doi": doi,
                "provider": "unpaywall",
                "paper": json.dumps(paper.dict()),
                "trace_context": request.headers.get("x-cloud-trace-context"),
            }
        )
        return paper

    # TODO: Don't do this twice if the author papers already have the s2 status
    #       Potentially move towards an enrich as opposed to a construct approach
    paper = validate_oa_status_from_s2_and_zenodo(paper, settings.s2_api_key)

    paper = oa_pathway(paper=paper, api_key=settings.sherpa_api_key)
    if paper.oa_pathway is OAPathway.not_found:
        logger.warning(
            {
                "event": "get_paper",
                "message": "no_policy_for_issn",
                "doi": doi,
                "provider": "sherpa",
                "issn": paper.issn,
                "paper": json.dumps(paper.dict()),
                "trace_context": request.headers.get("x-cloud-trace-context"),
            }
        )

    # Ensure it's a FullPaper and not just a PaperWithOAStatus
    paper = FullPaper(**paper.dict())

    # NOTE: There are cases where there is no best_permission but an all_permission key
    #       e.g. https://api.openaccessbutton.org/permissions?doi=10.1055/s-0030-1263175
    perms = openaccessbutton.get_permissions(paper.doi)
    if perms is not None:
        if perms.get("best_permission", None):
            paper.can_share_your_paper = perms["best_permission"]["can_archive"]
        elif perms.get("all_permissions", None):
            paper.can_share_your_paper = perms["all_permissions"][0]["can_archive"]

    logger.info(
        {
            "event": "get_paper",
            "message": "paper_found",
            "doi": doi,
            "is_oa": paper.is_open_access,
            "can_syp": paper.can_share_your_paper,
            "pathway": str(paper.oa_pathway),
            "trace_context": request.headers.get("x-cloud-trace-context"),
        }
    )

    return paper


@api_router.get("/debug", include_in_schema=False)
def get_request_headers(request: Request):
    return {"headers": request.headers, "url_scheme": request.url.scheme}


@api_router.post("/api/logs", include_in_schema=False)
def create_show_pathway_log_entry(log_entry: LogEntry, request: Request):
    logger.info(
        {
            "event": log_entry.event,
            "message": log_entry.message,
            "trace_context": request.headers.get("x-cloud-trace-context"),
        }
    )

    return None
