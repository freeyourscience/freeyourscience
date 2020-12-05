import os
import json

import pytest
from requests import Response

import wbf.oa_pathway as oa_pathway_module
from wbf.oa_pathway import oa_pathway, sherpa_pathway_api, has_no_cost_oa_policy
from wbf.schemas import (
    Paper,
    PaperWithOAStatus,
    OAPathway,
    OAStatus,
)


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


@pytest.mark.parametrize(
    "issn,pathway",
    [
        ("1179-3163", OAPathway.other),
        ("2050-084X", OAPathway.nocost),
        ("DOESNT-EXIST", OAPathway.not_found),
    ],
)
def test_sherpa_pathway_api_successes(issn, pathway, monkeypatch):
    with open(os.path.join(ASSETS_PATH, "publishers.json"), "r") as fh:
        publishers = json.load(fh)["items"]

    def mock_get_publisher(url):
        publisher_issn = url.split('"')[-2]
        selected_publishers = [p for p in publishers if publisher_issn in json.dumps(p)]
        response = Response()
        response.status_code = 200
        response._content = json.dumps({"items": selected_publishers}).encode("utf-8")
        return response

    monkeypatch.setattr("wbf.oa_pathway.requests.get", mock_get_publisher)

    sherpa_pathway = sherpa_pathway_api(
        issn=issn,
        api_key="DUMMY-KEY",
    )
    assert sherpa_pathway is pathway


def test_sherpa_pathway_api_request_error(monkeypatch):
    def mock_get_publisher(url):
        response = Response()
        response.status_code = 404
        return response

    monkeypatch.setattr("wbf.oa_pathway.requests.get", mock_get_publisher)

    pathway = sherpa_pathway_api(
        issn="1234-1234",
        api_key="DUMMY-KEY",
    )
    assert pathway == OAPathway.not_found


def test_oa_pathway(monkeypatch):
    base_paper = Paper(
        doi="10.1011/111111",
        issn="1234-1234",
    )

    paper = PaperWithOAStatus(oa_status=OAStatus.oa, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.already_oa

    paper = PaperWithOAStatus(oa_status=OAStatus.not_found, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.not_attempted

    def mock_sherpa_pathway_api(*args, **kwargs):
        return OAPathway.already_oa

    monkeypatch.setattr("wbf.oa_pathway.sherpa_pathway_api", mock_sherpa_pathway_api)

    paper = PaperWithOAStatus(oa_status=OAStatus.not_oa, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.already_oa


def test_sherpa_pathway_api_with_no_api_key():
    api_key = os.environ.pop("SHERPA_API_KEY", False)

    with pytest.raises(RuntimeError):
        sherpa_pathway_api(issn="1234-1234")

    if api_key:
        os.environ["SHERPA_API_KEY"] = api_key


def test_oa_pathway_doesnt_call_api_when_cached(mocker):
    sherpa_pathway_api_spy = mocker.spy(oa_pathway_module, "sherpa_pathway_api")
    issn = "0003-987X"
    cache = {issn: OAPathway.nocost}

    oa_pathway(
        PaperWithOAStatus(doi="10.1011/111111", issn=issn, oa_status=OAStatus.not_oa),
        cache=cache,
    )

    assert sherpa_pathway_api_spy.call_count == 0


def test_oa_pathway_chaches_after_api_call(monkeypatch):
    issn = "1234-1234"
    target_pathway = OAPathway.nocost
    cache = {}

    def mock_sherpa_pathway_api(*args, **kwargs):
        return target_pathway

    monkeypatch.setattr("wbf.oa_pathway.sherpa_pathway_api", mock_sherpa_pathway_api)

    oa_pathway(
        PaperWithOAStatus(doi="10.1011/111111", issn=issn, oa_status=OAStatus.not_oa),
        cache=cache,
    )

    assert issn in cache
    assert cache[issn] is target_pathway


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
