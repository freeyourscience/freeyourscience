import os
import json

import pytest
from requests import Response

from wbf.unpaywall import get_oa_status_and_issn
from wbf.schemas import OAStatus


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


@pytest.mark.parametrize(
    "is_oa,oa_status,issn",
    [
        (True, OAStatus.oa, "1234-1234"),
        (False, OAStatus.not_oa, "1234-1234"),
        (None, OAStatus.not_found, None),
    ],
)
def test_get_oa_status_and_issn(is_oa, oa_status, issn, monkeypatch):
    def mock_get_doi(*args, **kwargs):
        response = Response()
        if is_oa is None:
            response.status_code = 404
        else:
            response.status_code = 200
            response._content = json.dumps(
                {"is_oa": is_oa, "journal_issn_l": issn}
            ).encode("utf-8")
        return response

    monkeypatch.setattr("wbf.unpaywall.requests.get", mock_get_doi)

    irrelevant_dummy_doi = "10.1011/111111"
    unpaywall_status, unpaywall_issn = get_oa_status_and_issn(
        irrelevant_dummy_doi, "dummy@local.test"
    )

    assert unpaywall_status is oa_status
    assert unpaywall_issn == issn


def test_get_oa_status_and_issn_with_no_email():
    email = os.environ.pop("UNPAYWALL_EMAIL", False)

    with pytest.raises(RuntimeError):
        get_oa_status_and_issn("10.1011/111111")

    if email:
        os.environ["UNPAYWALL_EMAIL"] = email
