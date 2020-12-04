import os
import json

import pytest
from requests import Response

from wbf.are_we_right import (
    calculate_metrics,
    oa_pathway,
    unpaywall_status_api,
    sherpa_pathway_api,
)
from wbf.schemas import (
    Paper,
    PaperWithOAPathway,
    PaperWithOAStatus,
    OAPathway,
    OAStatus,
)


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_calculate_metrics():
    with open(os.path.join(ASSETS_PATH, "papers_enriched_dummy.json"), "r") as fh:
        papers = json.load(fh)

    papers = (PaperWithOAPathway(**paper) for paper in papers)

    n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(papers)

    assert n_oa == 1
    assert n_pathway_nocost == 1
    assert n_pathway_other == 1
    assert n_unknown == 1


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

    monkeypatch.setattr("wbf.are_we_right.requests.get", mock_get_publisher)

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

    monkeypatch.setattr("wbf.are_we_right.requests.get", mock_get_publisher)

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

    monkeypatch.setattr("wbf.are_we_right.sherpa_pathway_api", mock_sherpa_pathway_api)

    paper = PaperWithOAStatus(oa_status=OAStatus.not_oa, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.already_oa


def test_sherpa_pathway_api_with_no_api_key():
    api_key = os.environ.pop("SHERPA_API_KEY", False)

    with pytest.raises(RuntimeError):
        sherpa_pathway_api(issn="1234-1234")

    if api_key:
        os.environ["SHERPA_API_KEY"] = api_key


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

    monkeypatch.setattr("wbf.are_we_right.requests.get", mock_get_doi)

    irrelevant_dummy_doi = "10.1011/111111"
    unpaywall_status = unpaywall_status_api(irrelevant_dummy_doi, "dummy@local.test")

    assert unpaywall_status is oa_status


def test_unpaywall_status_api_with_no_email():
    email = os.environ.pop("UNPAYWALL_EMAIL", False)

    with pytest.raises(RuntimeError):
        unpaywall_status_api("10.1011/111111")

    if email:
        os.environ["UNPAYWALL_EMAIL"] = email
