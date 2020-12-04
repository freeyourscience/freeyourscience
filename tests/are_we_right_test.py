import os
import json

import pytest
from requests import Response

from wbf.are_we_right import calculate_metrics, oa_pathway, unpaywall_status_api


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_calculate_metrics():
    with open(os.path.join(ASSETS_PATH, "papers_enriched_dummy.json"), "r") as fh:
        papers = json.load(fh)

    n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(papers)

    assert n_oa == 1
    assert n_pathway_nocost == 1
    assert n_pathway_other == 1
    assert n_unknown == 1


@pytest.mark.parametrize(
    "issn,pathway",
    [("1179-3163", "other"), ("2050-084X", "nocost"), ("DOESNT-EXIST", "not-found")],
)
def test_oa_pathway_successes(issn, pathway, monkeypatch):
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

    updated_paper = oa_pathway(
        paper={
            "doi": "10.1011/111111",
            "issn": issn,
            "oa_status": "not-oa",
        },
        api_key="DUMMY-KEY",
    )
    assert updated_paper["pathway"] == pathway


def test_oa_pathway_request_error(monkeypatch):
    def mock_get_publisher(url):
        response = Response()
        response.status_code = 404
        return response

    monkeypatch.setattr("wbf.are_we_right.requests.get", mock_get_publisher)

    updated_paper = oa_pathway(
        paper={
            "doi": "10.1011/111111",
            "issn": "1234-1234",
            "oa_status": "not-oa",
        },
        api_key="DUMMY-KEY",
    )
    assert updated_paper["pathway"] == "not-found"


def test_oa_pathway_irrelevant_oa_status():
    paper = {
        "doi": "10.1011/111111",
        "issn": "1234-1234",
    }

    paper["oa_status"] = "oa"
    updated_paper = oa_pathway(paper=paper, api_key="DUMMY-KEY")
    assert updated_paper["pathway"] == "already-oa"

    paper["oa_status"] = "not-found"
    updated_paper = oa_pathway(paper=paper, api_key="DUMMY-KEY")
    assert updated_paper["pathway"] == "not-attempted"


def test_oa_pathway_with_no_api_key():
    api_key = os.environ.pop("SHERPA_API_KEY", False)

    with pytest.raises(RuntimeError):
        oa_pathway(
            paper={
                "doi": "10.1011/111111",
                "issn": "1234-1234",
                "oa_status": "not-oa",
            }
        )

    if api_key:
        os.environ["SHERPA_API_KEY"] = api_key


@pytest.mark.parametrize(
    "is_oa,oa_status",
    [(True, "oa"), (False, "not-oa"), (None, "not-found")],
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

    assert unpaywall_status == oa_status


def test_unpaywall_status_api_with_no_email():
    email = os.environ.pop("UNPAYWALL_EMAIL", False)

    with pytest.raises(RuntimeError):
        unpaywall_status_api("10.1011/111111")

    if email:
        os.environ["UNPAYWALL_EMAIL"] = email
