import os
import pytest

from requests import Response
from fyscience.orcid import get_author_with_papers, is_orcid, extract_orcid


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_get_author_with_papers(monkeypatch):
    def mock_get(*a, **kw):
        with open(os.path.join(ASSETS_PATH, "orcid_author.xml"), "r") as fh:
            xml = fh.read()
        r = Response()
        r._content = xml.encode()
        r.status_code = 200
        return r

    monkeypatch.setattr("fyscience.orcid.requests.get", mock_get)
    author = get_author_with_papers("0000-0000-0000-0000")

    assert len(author.papers) == 2
    dois_with_issn = {p.doi: p.issn for p in author.papers}
    assert dois_with_issn["10.1087/20120404"] == "1741-4857"
    assert dois_with_issn["10.1111/test.12241"] is None
    assert author.name == "Sofia Maria Hernandez Garcia"


@pytest.mark.parametrize(
    "orcid,expected",
    [
        ("0000-0000-0000-0000", True),
        ("1234-0000-0000-0000", True),
        ("1234-4321-1234-1111", True),
        ("1234-4321-1234-111X", True),
        ("4321-1234-1111", False),
        ("1111", False),
        ("0000-asda-0000-0000", True),
        ("0000-12312-0000-0000", False),
        ("0000-123-0000-0000", False),
    ],
)
def test_is_orchid(orcid, expected):
    assert is_orcid(orcid) == expected


@pytest.mark.parametrize(
    "input,expected",
    [
        ("1234-4321-1234-111X", "1234-4321-1234-111X"),
        ("https://orcid.org/1234-4321-1234-111X", "1234-4321-1234-111X"),
        ("1111", None),
        ("https://freeyourscience.org", None),
    ],
)
def test_extract_orcid(input, expected):
    assert extract_orcid(input) == expected
