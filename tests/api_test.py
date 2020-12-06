from fastapi.testclient import TestClient


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


def test_get_paper(client: TestClient) -> None:
    r = client.get("/papers?doi=10.1007/s00580-005-0536-8")
    assert r.ok

    r = client.get("/papers")
    assert not r.ok
    assert r.status_code == 422
