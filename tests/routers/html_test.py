import pytest
from fastapi.testclient import TestClient
from starlette.datastructures import URL

from fyscience.schemas import OAPathway, FullPaper, Author
from fyscience.routers.html import _is_doi_query, _get_response_headers


@pytest.mark.parametrize(
    "endpoint", ["/", "/team", "/howto", "/technology", "/republishing"]
)
def test_endpoint_responds_ok(endpoint, client: TestClient) -> None:
    r = client.get(endpoint)
    assert r.status_code == 200


def test_hit_error_page(client: TestClient) -> None:
    r = client.get("/foobar")
    print(r)
    assert r.status_code == 404


def test_hit_human_error_page(client: TestClient) -> None:
    r = client.get("/foobar", headers=({"Accept": "text/html"}))
    print(r)
    assert r.status_code == 404
    assert b"Not Found" in r.content


def test_no_author_found(monkeypatch, client: TestClient):
    providers = [
        "semantic_scholar.get_author_with_papers",
        "semantic_scholar.get_author_id",
        "orcid.get_author_with_papers",
        "crossref.get_author_with_papers",
    ]
    for provider in providers:
        monkeypatch.setattr(f"fyscience.routers.api.{provider}", lambda *a, **kw: None)

    r = client.get("/search?query=Some+Author")
    assert r.status_code == 404


def test_search_missing_args(client: TestClient) -> None:
    r = client.get("/search")
    assert r.status_code == 422


@pytest.mark.parametrize(
    "query,is_doi",
    [
        ("51453144", False),
        ("0000-0000-0000-0000", False),
        ("firstname lastname", False),
        ("firstname lastname", False),
        ("10.1002/(sici)1521-254(199905/06)1:3<16::aid-jgm34>3.3.co;2-q", True),
        ("10.1103/physreva.65.04814", True),
        ("10.4321/s0004-061420090300002", True),
        ("https://doi.org/10.4321/s0004-061420090300002", True),
    ],
)
def test_is_doi_query(
    query: str, is_doi: bool, client: TestClient, monkeypatch
) -> None:
    assert _is_doi_query(query) == is_doi


def test_get_response_headers():
    dev_url = URL("https://dev.freeyourscience.org/index.html")
    dev_headers = _get_response_headers(dev_url)
    assert "X-Robots-Tag" in dev_headers

    prod_url = URL("https://freeyourscience.org/index.html")
    prod_headers = _get_response_headers(prod_url)
    assert "X-Robots-Tag" not in prod_headers
