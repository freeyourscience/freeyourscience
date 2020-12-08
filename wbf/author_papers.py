from typing import List

import requests

# TODO: Add API key for prod setting


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
