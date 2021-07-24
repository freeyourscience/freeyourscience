import pytest

from fyscience.oa_status import validate_oa_status_from_s2_and_zenodo
from fyscience.schemas import FullPaper


@pytest.mark.parametrize(
    "initial,reference,expected",
    [
        (True, True, True),
        (True, False, True),
        (True, None, True),
        (False, True, True),
        (False, False, False),
        (False, None, False),
        (None, True, True),
        (None, False, False),
        (None, None, None),
    ],
)
def test_validate_oa_status_from_s2(initial, reference, expected, monkeypatch):
    paper = FullPaper(doi="10.110/dummy", is_open_access=initial)
    monkeypatch.setattr(
        "fyscience.oa_status.semantic_scholar.get_paper",
        lambda *a, **kw: FullPaper(doi="10.110/dummy", is_open_access=reference),
    )
    monkeypatch.setattr(
        "fyscience.oa_status.zenodo.get_open_access_url",
        lambda *a, **kw: None,
    )
    updated_paper = validate_oa_status_from_s2_and_zenodo(paper)
    assert updated_paper.is_open_access == expected


@pytest.mark.parametrize(
    "initial,reference,expected",
    [
        (True, True, True),
        (True, False, True),
        (True, None, True),
        (False, True, True),
        (False, False, False),
        (False, None, False),
        (None, True, True),
        (None, False, None),
        (None, None, None),
    ],
)
def test_validate_oa_status_from_zenodo(initial, reference, expected, monkeypatch):
    paper = FullPaper(doi="10.110/dummy", is_open_access=initial)
    monkeypatch.setattr(
        "fyscience.oa_status.semantic_scholar.get_paper",
        lambda *a, **kw: FullPaper(doi="10.110/dummy", is_open_access=initial),
    )
    monkeypatch.setattr(
        "fyscience.oa_status.zenodo.get_open_access_url",
        lambda *a, **kw: "https://an-oa-location-url.local" if reference else None,
    )
    updated_paper = validate_oa_status_from_s2_and_zenodo(paper)
    assert updated_paper.is_open_access == expected
