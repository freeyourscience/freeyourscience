import os

from requests import Response

from fyscience.crossref import get_author_with_papers


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_get_author_with_papers(monkeypatch):
    author_name = "author name"

    def mock_get(*a, **kw):
        with open(os.path.join(ASSETS_PATH, "crossref_author_search.json"), "r") as fh:
            content = fh.read()
        r = Response()
        r._content = content.encode()
        r.status_code = 200
        return r

    monkeypatch.setattr("fyscience.crossref.requests.get", mock_get)
    author = get_author_with_papers(author_name)

    assert len(author.papers) == 20
    dois_with_issn = {p.doi: p.issn for p in author.papers}
    assert dois_with_issn["10.1371/journal.pcbi.1006283"] == "1553-7358"
    assert author.name == author_name
