import os
import json

import pytest
from requests import Response
from fyscience.sherpa import get_pathway, has_no_cost_oa_policy
from fyscience.schemas import OAPathway


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


@pytest.mark.parametrize(
    "issn,pathway",
    [
        ("1179-3163", OAPathway.other),
        ("2050-084X", OAPathway.nocost),
        ("DOESNT-EXIST", OAPathway.not_found),
    ],
)
def test_get_pathway_successes(issn, pathway, monkeypatch):
    with open(os.path.join(ASSETS_PATH, "publishers.json"), "r") as fh:
        publishers = json.load(fh)["items"]

    def mock_get_publisher(url):
        publisher_issn = url.split('"')[-2]
        selected_publishers = [p for p in publishers if publisher_issn in json.dumps(p)]
        response = Response()
        response.status_code = 200
        response._content = json.dumps({"items": selected_publishers}).encode("utf-8")
        return response

    monkeypatch.setattr("fyscience.sherpa.requests.get", mock_get_publisher)

    sherpa_pathway, _, _ = get_pathway(
        issn=issn,
        api_key="DUMMY-KEY",
    )
    assert sherpa_pathway is pathway


def test_get_pathway_request_error(monkeypatch):
    def mock_get_publisher(url):
        response = Response()
        response.status_code = 404
        return response

    monkeypatch.setattr("fyscience.sherpa.requests.get", mock_get_publisher)

    pathway, _, _ = get_pathway(
        issn="1234-1234",
        api_key="DUMMY-KEY",
    )
    assert pathway == OAPathway.not_found


def test_get_pathway_with_no_api_key():
    api_key = os.environ.pop("SHERPA_API_KEY", False)

    with pytest.raises(RuntimeError):
        get_pathway(issn="1234-1234")

    if api_key:
        os.environ["SHERPA_API_KEY"] = api_key


@pytest.mark.parametrize(
    "policy,expected",
    [
        # In case open access isn't prohibited but no permitted_oa regulations are
        # available, we choose to be conservative and assume that there might be costs
        ({"open_access_prohibited": "no"}, False),
        ({"open_access_prohibited": "yes"}, False),
        # If the additional_oa_fee key is absent, we choose to be conservative and
        # assume that there might be costs
        ({"permitted_oa": [{}], "open_access_prohibited": "no"}, False),
        (
            {
                "permitted_oa": [{"additional_oa_fee": "no"}],
                "open_access_prohibited": "no",
            },
            True,
        ),
        (
            {
                "permitted_oa": [{"additional_oa_fee": "yes"}],
                "open_access_prohibited": "no",
            },
            False,
        ),
    ],
)
def test_has_no_cost_oa_policy(policy, expected):
    result = has_no_cost_oa_policy(policy)
    assert result == expected
