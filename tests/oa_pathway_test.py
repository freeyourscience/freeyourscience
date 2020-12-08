import os

import wbf.oa_pathway as oa_pathway_module
from wbf.oa_pathway import oa_pathway
from wbf.schemas import (
    Paper,
    PaperWithOAStatus,
    OAPathway,
    OAStatus,
)


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


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
