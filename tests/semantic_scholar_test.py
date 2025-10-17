import pytest
from urllib3.exceptions import NameResolutionError

from fyscience.semantic_scholar import (
    get_paper,
    Paper,
    extract_profile_id_from_url,
    _get_request,
)


def test_get_paper_no_paper(monkeypatch):
    monkeypatch.setattr("fyscience.semantic_scholar._get_paper", lambda *a, **kw: None)
    paper = get_paper("irrelevant_dummy_id")
    assert paper is None


def test_get_paper_no_doi(monkeypatch):
    monkeypatch.setattr(
        "fyscience.semantic_scholar._get_paper", lambda *a, **kw: Paper(doi=None)
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


def test_dev_vs_prod_endpoint(monkeypatch):
    def mock_get_dev(url, **kwargs):
        assert url.startswith("https://api.semanticscholar.org")
        return None

    monkeypatch.setattr("fyscience.semantic_scholar.requests.get", mock_get_dev)
    _get_request("someEndpoint/123", api_key=None)

    def mock_get_prod(url, headers, **kwargs):
        assert url.startswith("https://partner.semanticscholar.org")
        assert "x-api-key" in headers
        return None

    monkeypatch.setattr("fyscience.semantic_scholar.requests.get", mock_get_prod)
    _get_request("someEndpoint/123", api_key="api_key_dummy")


def test_name_resolution_error(monkeypatch):
    def mock_get_dev(url, **kwargs):
        raise NameResolutionError(host="non-existing-host", conn=None, reason=None)

    monkeypatch.setattr("fyscience.semantic_scholar.requests.get", mock_get_dev)
    result = _get_request("someEndpoint/123", api_key=None)
    assert result == None
