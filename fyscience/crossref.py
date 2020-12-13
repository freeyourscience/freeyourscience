import requests

from fyscience.schemas import Author, FullPaper

# TODO: Include the appropriate request headers and potentially API key for prod
#       https://github.com/CrossRef/rest-api-doc


def _parse_paper(paper: dict) -> FullPaper:
    issn = paper.get("ISSN", None)
    if issn is not None:
        issn = issn[0]

    title = paper.get("title", None)
    if title is not None:
        title = title[0]

    return FullPaper(doi=paper["DOI"], issn=issn, title=title)


def get_author_with_papers(name: str):
    url_name = name.replace(" ", "+")
    r = requests.get(f"https://api.crossref.org/works?query.author={url_name}")
    if not r.ok:
        return None

    result = r.json()
    papers = [_parse_paper(p) for p in result["message"]["items"] if "DOI" in p]
    return Author(
        name=name,
        papers=papers,
        provider="crossref",
        profile_url=f"https://search.crossref.org/?q={url_name}",
    )
