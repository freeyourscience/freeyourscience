from typing import List

import requests

# TODO: Add API key for prod setting
# TODO: The semantic scholar API seems to be unstable (returns 500 errors out of the
# blue), check if caching and retries are enough to mitigate this or reach out to
# semantic scholar API team


def semantic_scholar_paper_api(paper_id: str, client=None) -> dict:
    client = requests if client is None else client
    r = client.get(f"https://api.semanticscholar.org/v1/paper/{paper_id}")
    paper = r.json()
    return paper


def semantic_scholar_author_api(author_id: str, client=None) -> dict:
    client = requests if client is None else client
    r = client.get(f"https://api.semanticscholar.org/v1/author/{author_id}")
    author = r.json()
    return author


def dois_from_semantic_scholar_author_api(author_id: str, client=None) -> List[str]:
    author = semantic_scholar_author_api(author_id, client)
    papers = [
        semantic_scholar_paper_api(paper["paperId"], client)
        for paper in author["papers"]
    ]
    dois = [paper["doi"] for paper in papers]
    return dois
