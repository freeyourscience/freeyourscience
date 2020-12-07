from typing import List

import requests
from bs4 import BeautifulSoup

# TODO: Add API key for prod setting
# TODO: The semantic scholar API seems to be unstable (returns 500 errors out of the
# blue), check if caching and retries are enough to mitigate this or reach out to
# semantic scholar API team


def semantic_scholar_paper_api(paper_id: str) -> dict:
    r = requests.get(f"https://api.semanticscholar.org/v1/paper/{paper_id}")
    paper = r.json()
    return paper


def semantic_scholar_author_api(author_id: str) -> dict:
    r = requests.get(f"https://api.semanticscholar.org/v1/author/{author_id}")
    author = r.json()
    return author


def dois_from_semantic_scholar_author_api(author_id: str) -> List[str]:
    author = semantic_scholar_author_api(author_id)
    papers = [
        semantic_scholar_paper_api(paper["paperId"]) for paper in author["papers"]
    ]
    dois = [paper["doi"] for paper in papers]
    return dois


def crawl_dois_from_semantic_scholar_author_page(author_id: str) -> List[str]:
    """Intermediate alternative to Semantic Scholar API for dev until API is fixed."""
    dois = []
    page = 1
    while True:
        r = requests.get(
            f"https://www.semanticscholar.org/author/{author_id}?sort=influence&page={page}"
        )
        html = r.content.decode()

        if "No Papers Found" in html:
            break

        page += 1

        soup = BeautifulSoup(html)
        doi_links = soup.find_all(
            "a", href=lambda v: v and v.startswith("https://doi.org")
        )
        dois.extend([link["href"].lstrip("https://doi.org/") for link in doi_links])

    return dois
