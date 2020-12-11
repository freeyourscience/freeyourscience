import os

from fastapi import Response
from wbf.orcid import _get_dois_with_issn_from_works


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_get_dois_with_issn_from_works(monkeypatch):
    def mock_get(*a, **kw):
        with open(os.path.join(ASSETS_PATH, "orcid_works.xml"), "r") as fh:
            xml = fh.read()
        r = Response()
        r.content = xml.encode()
        return r

    monkeypatch.setattr("wbf.orcid.requests.get", mock_get)

    dois_with_issn = _get_dois_with_issn_from_works("0000-0000-0000-0000")
    assert len(dois_with_issn) == 5
