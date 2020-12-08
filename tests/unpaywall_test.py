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
                {
                    "doi": "10.1080/555222222",
                    "doi_url": "https://doi.org/10.1080/asda23123",
                    "title": "Some Title",
                    "genre": "journal-article",
                    "is_paratext": False,
                    "published_date": "2020-03-01",
                    "year": 1986,
                    "journal_name": "Distance Education",
                    "journal_issns": "0158-7919,1475-0198",
                    "journal_issn_l": issn,
                    "journal_is_oa": False,
                    "journal_is_in_doaj": False,
                    "publisher": "Information Publisher",
                    "is_oa": is_oa,
                    "oa_status": "gold" if is_oa else "closed",
                    "has_repository_copy": False,
                    "best_oa_location": None,
                    "first_oa_location": None,
                    "oa_locations": [],
                    "updated": "2020-09-09T21:11:51.319309",
                    "data_standard": 2,
                    "z_authors": [
                        {"sequence": "first", "given": "Erling", "family": "Erlang"}
                    ],
                }
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
