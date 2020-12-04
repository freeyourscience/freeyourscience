import os
import json

import pytest
from requests import Response

from wbf.oa_status import unpaywall_status_api
from wbf.schemas import OAStatus


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


@pytest.mark.parametrize(
    "is_oa,oa_status",
    [(True, OAStatus.oa), (False, OAStatus.not_oa), (None, OAStatus.not_found)],
)
def test_unpaywall_status_api(is_oa, oa_status, monkeypatch):
    def mock_get_doi(*args, **kwargs):
        response = Response()
        if is_oa is None:
            response.status_code = 404
        else:
            response.status_code = 200
            response._content = json.dumps({"is_oa": is_oa}).encode("utf-8")
        return response

    monkeypatch.setattr("wbf.oa_status.requests.get", mock_get_doi)

    irrelevant_dummy_doi = "10.1011/111111"
    unpaywall_status = unpaywall_status_api(irrelevant_dummy_doi, "dummy@local.test")

    assert unpaywall_status is oa_status


def test_unpaywall_status_api_with_no_email():
    email = os.environ.pop("UNPAYWALL_EMAIL", False)

    with pytest.raises(RuntimeError):
        unpaywall_status_api("10.1011/111111")

    if email:
        os.environ["UNPAYWALL_EMAIL"] = email
