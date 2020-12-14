import os
import json

import pytest
from requests import Response

from fyscience.unpaywall import get_paper, Paper


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")
DMUMMY_PAPER = Paper(
    data_standard=2,
    doi="10.110/dummy.doi",
    doi_url="https://doi.org/10.110/dummy.doi",
    genre="Fiction",
    is_paratext=False,
    is_oa=False,
    journal_is_in_doaj=True,
    journal_is_oa=False,
    oa_locations=[],
    oa_status="closed",
    publisher="Paywall Inc.",
    updated="",
)


@pytest.mark.parametrize(
    "is_oa,expected_is_oa,issn",
    [(True, True, "1234-1234"), (False, False, "1234-1234")],
)
def test_get_paper(is_oa, expected_is_oa, issn, monkeypatch):
    def mock_get_doi(*args, **kwargs):
        response = Response()
        response.status_code = 200
        response._content = json.dumps(
            {
                "doi": "10.1080/555222222",
                "doi_url": "https://doi.org/10.1080/asda23123",
                "title": "Some Title",
                "genre": "journal-article",
                "is_paratext": False,
                "published_date": "2020-03-01",
                "year": 1986,
                "journal_name": "Distance Education",
                "journal_issns": "0158-7919,1475-0198",
                "journal_issn_l": issn,
                "journal_is_oa": False,
                "journal_is_in_doaj": False,
                "publisher": "Information Publisher",
                "is_oa": is_oa,
                "oa_status": "gold" if is_oa else "closed",
                "has_repository_copy": False,
                "best_oa_location": None,
                "first_oa_location": None,
                "oa_locations": [],
                "updated": "2020-09-09T21:11:51.319309",
                "data_standard": 2,
                "z_authors": [
                    {"sequence": "first", "given": "Erling", "family": "Erlang"}
                ],
            }
        ).encode("utf-8")
        return response

    monkeypatch.setattr("fyscience.unpaywall.requests.get", mock_get_doi)

    paper = get_paper("10.1011/irrelevant.dummy", "dummy@local.test")

    assert paper.is_open_access == expected_is_oa
    assert paper.issn == issn


def test_get_paper_not_found(monkeypatch):
    def mock_get_doi(*args, **kwargs):
        response = Response()
        response.status_code = 404
        return response

    monkeypatch.setattr("fyscience.unpaywall.requests.get", mock_get_doi)
    paper = get_paper("10.1011/irrelevant.dummy", "dummy@local.test")
    assert paper is None


def test_get_paper_with_no_email():
    email = os.environ.pop("UNPAYWALL_EMAIL", False)

    with pytest.raises(RuntimeError):
        get_paper("10.1011/111111")

    if email:
        os.environ["UNPAYWALL_EMAIL"] = email


def test_get_paper_author_extraction(monkeypatch):
    authors = [
        {"given": "Dummy", "family": "Author", "sequence": "additional"},
        {"given": "Other", "family": "Author", "sequence": "first"},
    ]

    def mock_get_paper(*args, **kwargs):
        paper = DMUMMY_PAPER.copy()
        paper.z_authors = authors
        return paper

    monkeypatch.setattr("fyscience.unpaywall._get_paper", mock_get_paper)

    paper = get_paper("10.100/irrelevant.doi")
    first_author = authors[1]
    assert paper.authors.startswith(f"{first_author['given']} {first_author['family']}")


def test_get_paper_author_extraction_no_sequence(monkeypatch):
    authors_without_sequence_key = [
        {"given": "Dummy", "family": "Author"},
        {"given": "Other", "family": "Author"},
    ]

    def mock_get_paper(*args, **kwargs):
        paper = DMUMMY_PAPER.copy()
        paper.z_authors = authors_without_sequence_key
        return paper

    monkeypatch.setattr("fyscience.unpaywall._get_paper", mock_get_paper)

    paper = get_paper("10.100/irrelevant.doi")
    first_author = authors_without_sequence_key[0]
    assert paper.authors.startswith(f"{first_author['given']} {first_author['family']}")