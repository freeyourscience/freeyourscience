import pytest

from wbf.oa_status import validate_oa_status_from_s2
from wbf.schemas import FullPaper


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
        "wbf.oa_status.s2_get_paper",
        lambda *a, **kw: FullPaper(doi="10.110/dummy", is_open_access=reference),
    )
    updated_paper = validate_oa_status_from_s2(paper)
    assert updated_paper.is_open_access == expected
