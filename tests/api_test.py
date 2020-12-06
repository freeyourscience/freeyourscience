from fastapi.testclient import TestClient

from wbf.schemas import OAPathway, OAStatus, PaperWithOAPathway


def test_get_landing_page(client: TestClient) -> None:
    r = client.get("/")
    assert r.ok


def test_get_publications_for_author(monkeypatch, client: TestClient) -> None:
    url = "/authors?semantic_scholar_id=51453144"

    monkeypatch.setattr(
        "wbf.api.dois_from_semantic_scholar_author_api",
        lambda *a, **kw: ["123/123.123"],
    )
    monkeypatch.setattr(
        "wbf.api.get_paper",
        lambda *a, **kw: PaperWithOAPathway(
            issn="1618-5641",
            doi="10.1007/s00580-005-0536-8",
            oa_status=OAStatus.not_oa.value,
            oa_pathway=OAPathway.nocost.value,
        ),
    )

    r = client.get(url)
    assert r.ok

    r = client.get(url, headers={"accept": "text/html"})
    assert r.ok

    r = client.get(url, headers={"accept": "application/json"})
    assert r.ok

    r = client.get(url, headers={"accept": "unspported/type"})
    assert not r.ok
    assert r.status_code == 406

    r = client.get("/authors")
    assert not r.ok
    assert r.status_code == 422


def test_get_paper_missing_args(client: TestClient) -> None:
    r = client.get("/papers")
    assert not r.ok
    assert r.status_code == 422


def test_get_paper(monkeypatch, client: TestClient) -> None:
    issn = "1618-5641"
    doi = "10.1007/s00580-005-0536-8"
    oa_status = OAStatus.not_oa.value
    oa_pathway = OAPathway.nocost.value

    monkeypatch.setattr(
        "wbf.api.unpaywall_status_api",
        lambda *a, **kw: (oa_status, issn),
    )
    monkeypatch.setattr(
        "wbf.api.oa_pathway",
        lambda paper: PaperWithOAPathway(oa_pathway=oa_pathway, **paper.dict()),
    )

    r = client.get(f"/papers?doi={doi}")
    assert r.ok
    paper = r.json()
    assert paper["oa_status"] == oa_status
    assert paper["oa_pathway"] == oa_pathway
    assert paper["doi"] == doi
    assert paper["issn"] == issn
