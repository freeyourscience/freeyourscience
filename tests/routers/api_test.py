import pytest
from fastapi.testclient import TestClient

from fyscience.schemas import (
    OAPathway,
    PaperWithOAPathway,
    FullPaper,
    PaperWithOAStatus,
)
from fyscience import main
from fyscience.routers.deps import Settings, get_settings
from fyscience.semantic_scholar import Author


def get_settings_override():
    return Settings(sherpa_api_key="DUMMY-API-KEY", unpaywall_email="TEST@MAIL.LOCAL")


main.app.dependency_overrides[get_settings] = get_settings_override


@pytest.mark.parametrize(
    "profile,provider",
    [
        (51453144, "semantic_scholar.get_author_with_papers"),
        (
            "https://www.semanticscholar.org/author/Lukas-Gro%C3%9Fberger/51453144",
            "semantic_scholar.get_author_with_papers",
        ),
        ("https://orcid.org/0000-0000-0000-0000", "orcid.get_author_with_papers"),
        ("0000-0000-0000-0000", "orcid.get_author_with_papers"),
        ("firstname lastname", "crossref.get_author_with_papers"),
    ],
)
def test_get_publications_for_author(
    profile, provider, monkeypatch, client: TestClient
) -> None:
    url = f"/api/authors?profile={profile}"

    monkeypatch.setattr(
        f"fyscience.routers.api.{provider}",
        lambda *a, **kw: Author(
            name="Dummy Author", paper_ids=["10.1007/s00580-005-0536-0"]
        ),
    )

    r = client.get(url)
    assert r.ok


def test_no_author_found(monkeypatch, client: TestClient):
    providers = [
        "semantic_scholar.get_author_with_papers",
        "orcid.get_author_with_papers",
        "crossref.get_author_with_papers",
    ]
    for provider in providers:
        monkeypatch.setattr(f"fyscience.routers.api.{provider}", lambda *a, **kw: None)

    r = client.get("/api/authors?profile=Some+Author")
    assert r.status_code == 404


def test_get_publications_for_author_without_profile_arg(client: TestClient) -> None:
    r = client.get("/api/authors")
    assert not r.ok
    assert r.status_code == 422


def test_get_paper(monkeypatch, client: TestClient) -> None:
    issn = "1618-5641"
    doi = "10.1007/s00580-005-0536-8"
    is_open_access = False
    oa_pathway = OAPathway.nocost.value

    monkeypatch.setattr(
        "fyscience.routers.api.unpaywall_get_paper",
        lambda *a, **kw: FullPaper(doi=doi, issn=issn, is_open_access=is_open_access),
    )
    monkeypatch.setattr(
        "fyscience.routers.api.validate_oa_status_from_s2",
        lambda *a, **kw: PaperWithOAStatus(
            doi=doi, issn=issn, is_open_access=is_open_access
        ),
    )
    monkeypatch.setattr(
        "fyscience.routers.api.oa_pathway",
        lambda paper, **kw: PaperWithOAPathway(oa_pathway=oa_pathway, **paper.dict()),
    )

    r = client.get(f"/api/papers?doi={doi}")
    assert r.ok
    paper = r.json()
    assert paper["is_open_access"] == is_open_access
    assert paper["oa_pathway"] == oa_pathway
    assert paper["doi"] == doi
    assert paper["issn"] == issn


def test_log_endpoint(caplog, client: TestClient) -> None:
    event = "something_grand"
    message = "Details about how grand."

    r = client.post("/api/logs", json={"event": event, "message": message})
    assert r.ok, r

    assert event in caplog.text
    assert message in caplog.text
