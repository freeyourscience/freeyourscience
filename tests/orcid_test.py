import os
import pytest

from fastapi import Response
from wbf.orcid import _get_dois_with_issn_from_works, is_orcid


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_get_dois_with_issn_from_works(monkeypatch):
    def mock_get(*a, **kw):
        with open(os.path.join(ASSETS_PATH, "orcid_works.xml"), "r") as fh:
            xml = fh.read()
        r = Response()
        r.content = xml.encode()
        r.status_code = 200
        r.ok = True
        return r

    monkeypatch.setattr("wbf.orcid.requests.get", mock_get)

    dois_with_issn = _get_dois_with_issn_from_works("0000-0000-0000-0000")
    assert len(dois_with_issn) == 5


@pytest.mark.parametrize(
    "orcid,expected",
    [
        ("0000-0000-0000-0000", True),
        ("1234-0000-0000-0000", True),
        ("1234-4321-1234-1111", True),
        ("4321-1234-1111", False),
        ("1111", False),
        ("0000-asda-0000-0000", False),
        ("0000-12312-0000-0000", False),
        ("0000-123-0000-0000", False),
    ],
)
def test_is_orchid(orcid, expected):
    assert is_orcid(orcid) == expected
