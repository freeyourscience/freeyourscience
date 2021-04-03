import json

from fastapi import APIRouter, HTTPException, Depends, Request
from loguru import logger

from fyscience.schemas import OAPathway, FullPaper, Author, LogMessageShowPathway
from fyscience.unpaywall import get_paper as unpaywall_get_paper
from fyscience.oa_pathway import oa_pathway, remove_costly_oa_from_publisher_policy
from fyscience.oa_status import validate_oa_status_from_s2
from fyscience import orcid, semantic_scholar, crossref
from fyscience.routers.deps import get_settings, Settings


api_router = APIRouter()

# TODO: Sanitize user input


def _construct_paper(
    doi: str, unpaywall_email: str, sherpa_api_key: str, s2_api_key: str
) -> FullPaper:

    paper = unpaywall_get_paper(doi=doi, email=unpaywall_email)
    if paper is None:
        paper = FullPaper(doi=doi)

    if paper.issn is None and not paper.is_open_access:
        logger.warning(
            {
                "message": "no_issn_for_paywalled_pub",
                "provider": "unpaywall",
                "doi": doi,
                "paper": json.dumps(paper.dict()),
            }
        )
        return paper

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

    return paper


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
    extracted_orcid = orcid.extract_orcid(profile)
    if extracted_orcid is not None:
        author = orcid.get_author_with_papers(extracted_orcid)

    else:
        author_id = semantic_scholar.extract_profile_id_from_url(profile)
        if not author_id.isnumeric():
            author_id = semantic_scholar.get_author_id(profile, settings.s2_api_key)

        if author_id is not None:
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


@api_router.post("/api/logs/show-pathway", include_in_schema=False)
def create_show_pathway_log_entry(message: LogMessageShowPathway):
    logger.info({"event": "show_pathway_click", "doi": message.doi})

    return None
