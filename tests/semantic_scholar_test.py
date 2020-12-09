from wbf.semantic_scholar import get_paper, Paper


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
