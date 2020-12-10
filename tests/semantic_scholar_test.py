import pytest

from wbf.semantic_scholar import get_paper, Paper, extract_profile_id_from_url


def test_get_paper_no_paper(monkeypatch):
    monkeypatch.setattr("wbf.semantic_scholar._get_paper", lambda *a, **kw: None)
    paper = get_paper("irrelevant_dummy_id")
    assert paper is None


def test_get_paper_no_doi(monkeypatch):
    monkeypatch.setattr(
        "wbf.semantic_scholar._get_paper", lambda *a, **kw: Paper(doi=None)
    )
    paper = get_paper("irrelevant_dummy_id")
    assert paper is None


@pytest.mark.parametrize(
    "url,profile_id",
    [
        (
            "https://www.s2.org/author/K.-Harris/144931354?sort=influence&page=1",
            "144931354",
        ),
        (
            "https://www.s2.org/author/K.-Harris/144931354/?sort=influence&page=1",
            "144931354",
        ),
        (
            "https://www.s2.org/author/K.-Harris/144931354",
            "144931354",
        ),
        (
            "https://www.s2.org/author/K.-Harris/144931354/",
            "144931354",
        ),
        (
            "https://www.s2.org/author/K.-Harris/144931354/?",
            "144931354",
        ),
        (
            "https://www.s2.org/author/K.-Harris/144931354?",
            "144931354",
        ),
        ("144931354", "144931354"),
        ("K.-Harris/144931354", "144931354"),
    ],
)
def test_extract_profile_id_from_url(url, profile_id):
    extracted_id = extract_profile_id_from_url(url)
    assert extracted_id == profile_id
