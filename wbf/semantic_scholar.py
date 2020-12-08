from typing import List

import requests

# TODO: Add API key for prod setting


def get_paper(paper_id: str) -> dict:
    r = requests.get(f"https://api.semanticscholar.org/v1/paper/{paper_id}")
    paper = r.json()
    return paper


def get_author(author_id: str) -> dict:
    r = requests.get(f"https://api.semanticscholar.org/v1/author/{author_id}")
    author = r.json()
    return author


def get_dois(author_id: str) -> List[str]:
    author = get_author(author_id)
    papers = [get_paper(paper["paperId"]) for paper in author["papers"]]
    dois = [paper["doi"] for paper in papers]
    return dois
