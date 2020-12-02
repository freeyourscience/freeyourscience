import os
import json

import pytest
from requests import Response

from wbf.are_we_right import calculate_metrics, oa_pathway


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
            "unpaywall_status": "not-oa",
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
            "unpaywall_status": "not-oa",
        },
        api_key="DUMMY-KEY",
    )
    assert updated_paper["pathway"] == "not-found"


def test_oa_pathway_irrelevant_oa_status():
    paper = {
        "doi": "10.1011/111111",
        "issn": "1234-1234",
    }

    paper["unpaywall_status"] = "oa"
    updated_paper = oa_pathway(paper=paper, api_key="DUMMY-KEY")
    assert updated_paper["pathway"] == "already-oa"

    paper["unpaywall_status"] = "not-found"
    updated_paper = oa_pathway(paper=paper, api_key="DUMMY-KEY")
    assert updated_paper["pathway"] == "not-attempted"


def test_oa_pathway_with_no_api_key():
    api_key = os.environ.pop("SHERPA_API_KEY")

    with pytest.raises(RuntimeError):
        oa_pathway(
            paper={
                "doi": "10.1011/111111",
                "issn": "1234-1234",
                "unpaywall_status": "not-oa",
            }
        )

    api_key = os.environ["SHERPA_API_KEY"] = api_key
