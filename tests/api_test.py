from fastapi.testclient import TestClient

from wbf.schemas import OAPathway, OAStatus, PaperWithOAStatus, PaperWithOAPathway


def test_get_landing_page(client: TestClient) -> None:
    r = client.get("/")
    assert r.ok


def test_get_publications_for_author(client: TestClient) -> None:
    url = "/authors?semantic_scholar_id=51453144"

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

    r = client.get("/papers?doi=123")
    assert not r.ok
    assert r.status_code == 422

    r = client.get("/papers?issn=123")
    assert not r.ok
    assert r.status_code == 422


def test_get_paper(monkeypatch, client: TestClient) -> None:
    issn = "1618-5641"
    doi = "10.1007/s00580-005-0536-8"
    oa_status = OAStatus.not_oa.value
    oa_pathway = OAPathway.nocost.value

    monkeypatch.setattr(
        "wbf.api.oa_status",
        lambda paper: PaperWithOAStatus(oa_status=oa_status, **paper.dict()),
    )
    monkeypatch.setattr(
        "wbf.api.oa_pathway",
        lambda paper: PaperWithOAPathway(oa_pathway=oa_pathway, **paper.dict()),
    )

    r = client.get(f"/papers?doi={doi}&issn={issn}")
    assert r.ok
    paper = r.json()
    assert paper["oa_status"] == oa_status
    assert paper["oa_pathway"] == oa_pathway
    assert paper["doi"] == doi
    assert paper["issn"] == issn
