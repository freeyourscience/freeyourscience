import pytest
from fastapi.testclient import TestClient

from fyscience.schemas import (
    OAPathway,
    PaperWithOAPathway,
    FullPaper,
    PaperWithOAStatus,
)
from fyscience import main
from fyscience.deps import Settings, get_settings
from fyscience.semantic_scholar import Author
from fyscience.api import _is_doi_query


def get_settings_override():
    return Settings(sherpa_api_key="DUMMY-API-KEY", unpaywall_email="TEST@MAIL.LOCAL")


main.app.dependency_overrides[get_settings] = get_settings_override


def test_get_landing_page(client: TestClient) -> None:
    r = client.get("/")
    assert r.ok


@pytest.mark.parametrize(
    "author,provider",
    [
        (51453144, "semantic_scholar.get_author_with_papers"),
        ("0000-0000-0000-0000", "orcid.get_author_with_papers"),
        ("firstname lastname", "crossref.get_author_with_papers"),
    ],
)
def test_get_publications_for_author_html(
    author, provider, monkeypatch, client: TestClient
) -> None:
    url = f"/search?query={author}"

    monkeypatch.setattr(
        f"fyscience.api.{provider}",
        lambda *a, **kw: Author(
            name="Dummy Author", papers=[FullPaper(doi="10.1007/s00580-005-0536-0")]
        ),
    )

    monkeypatch.setattr(
        "fyscience.api._construct_paper",
        lambda *a, **kw: FullPaper(
            issn="1618-5641",
            doi="10.1007/s00580-005-0536-0",
            oa_status=False,
            oa_pathway=OAPathway.nocost.value,
            oa_pathway_details=[],
            title="Best Paper Ever!",
        ),
    )

    r = client.get(url)
    assert r.ok

    monkeypatch.setattr(f"fyscience.api.{provider}", lambda *a, **kw: None)

    r = client.get(url)
    assert r.status_code == 404


@pytest.mark.parametrize(
    "profile,provider",
    [
        (51453144, "semantic_scholar.get_author_with_papers"),
        ("0000-0000-0000-0000", "orcid.get_author_with_papers"),
        ("firstname lastname", "crossref.get_author_with_papers"),
    ],
)
def test_get_publications_for_author(
    profile, provider, monkeypatch, client: TestClient
) -> None:
    url = f"/api/authors?profile={profile}"

    monkeypatch.setattr(
        f"fyscience.api.{provider}",
        lambda *a, **kw: Author(
            name="Dummy Author", papers=[FullPaper(doi="10.1007/s00580-005-0536-0")]
        ),
    )

    r = client.get(url)
    assert r.ok

    monkeypatch.setattr(f"fyscience.api.{provider}", lambda *a, **kw: None)

    r = client.get(url)
    assert r.status_code == 404


def test_get_publications_for_author_without_profile_arg(client: TestClient) -> None:
    r = client.get("/api/authors")
    assert not r.ok
    assert r.status_code == 422


@pytest.mark.parametrize(
    "author,provider",
    [
        (51453144, "semantic_scholar.get_author_with_papers"),
        ("0000-0000-0000-0000", "orcid.get_author_with_papers"),
        ("firstname lastname", "crossref.get_author_with_papers"),
    ],
)
def test_no_author(author, provider, monkeypatch, client: TestClient) -> None:
    url = f"/search?query={author}"

    monkeypatch.setattr(f"fyscience.api.{provider}", lambda *a, **kw: None)

    r = client.get(url)
    assert not r.ok
    assert r.status_code == 404


@pytest.mark.parametrize(
    "author,provider",
    [
        (51453144, "semantic_scholar.get_author_with_papers"),
        ("0000-0000-0000-0000", "orcid.get_author_with_papers"),
        ("firstname lastname", "crossref.get_author_with_papers"),
    ],
)
def test_no_publications_for_author(
    author, provider, monkeypatch, client: TestClient
) -> None:
    url = f"/search?query={author}"

    monkeypatch.setattr(
        f"fyscience.api.{provider}",
        lambda *a, **kw: Author(name="Dummy Author", papers=[]),
    )

    r = client.get(url)
    assert r.ok


def test_search_missing_args(client: TestClient) -> None:
    r = client.get("/search")
    assert not r.ok
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
    ],
)
def test_is_doi_query(
    query: str, is_doi: bool, client: TestClient, monkeypatch
) -> None:
    assert _is_doi_query(query) == is_doi


def test_get_paper(monkeypatch, client: TestClient) -> None:
    issn = "1618-5641"
    doi = "10.1007/s00580-005-0536-8"
    is_open_access = False
    oa_pathway = OAPathway.nocost.value

    monkeypatch.setattr(
        "fyscience.api.unpaywall_get_paper",
        lambda *a, **kw: FullPaper(doi=doi, issn=issn, is_open_access=is_open_access),
    )
    monkeypatch.setattr(
        "fyscience.api.validate_oa_status_from_s2",
        lambda *a, **kw: PaperWithOAStatus(
            doi=doi, issn=issn, is_open_access=is_open_access
        ),
    )
    monkeypatch.setattr(
        "fyscience.api.oa_pathway",
        lambda paper, **kw: PaperWithOAPathway(oa_pathway=oa_pathway, **paper.dict()),
    )

    r = client.get(f"/api/papers?doi={doi}")
    assert r.ok
    paper = r.json()
    assert paper["is_open_access"] == is_open_access
    assert paper["oa_pathway"] == oa_pathway
    assert paper["doi"] == doi
    assert paper["issn"] == issn
