import os
import json

import fyscience.oa_pathway as oa_pathway_module
from fyscience.oa_pathway import oa_pathway, remove_costly_oa_from_publisher_policy
from fyscience.schemas import (
    Paper,
    PaperWithOAStatus,
    OAPathway,
)


ASSETS_PATH = os.path.join(os.path.dirname(__file__), "assets")


def test_oa_pathway(monkeypatch):
    base_paper = Paper(
        doi="10.1011/111111",
        issn="1234-1234",
    )

    paper = PaperWithOAStatus(is_open_access=True, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.already_oa

    paper = PaperWithOAStatus(is_open_access=None, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.not_attempted

    def mock_sherpa_pathway_api(*args, **kwargs):
        return OAPathway.already_oa, None

    monkeypatch.setattr(
        "fyscience.oa_pathway.sherpa_pathway_api", mock_sherpa_pathway_api
    )

    paper = PaperWithOAStatus(is_open_access=False, **base_paper.dict())
    updated_paper = oa_pathway(paper=paper)
    assert updated_paper.oa_pathway is OAPathway.already_oa


def test_oa_pathway_doesnt_call_api_when_cached(mocker):
    sherpa_pathway_api_spy = mocker.spy(oa_pathway_module, "sherpa_pathway_api")
    issn = "0003-987X"
    cache = {issn: OAPathway.nocost}

    oa_pathway(
        PaperWithOAStatus(doi="10.1011/111111", issn=issn, is_open_access=False),
        cache=cache,
    )

    assert sherpa_pathway_api_spy.call_count == 0


def test_oa_pathway_chaches_after_api_call(monkeypatch):
    issn = "1234-1234"
    target_pathway = OAPathway.nocost
    cache = {}

    def mock_sherpa_pathway_api(*args, **kwargs):
        return target_pathway, []

    monkeypatch.setattr(
        "fyscience.oa_pathway.sherpa_pathway_api", mock_sherpa_pathway_api
    )

    oa_pathway(
        PaperWithOAStatus(doi="10.1011/111111", issn=issn, is_open_access=False),
        cache=cache,
    )

    assert issn in cache
    assert cache[issn] is target_pathway


def test_remove_costly_oa_from_publisher_policy_without_additional_oa_fee_key():
    """Conservatively remove permitted oa entries without cost information"""

    with open(
        os.path.join(ASSETS_PATH, "policy_without_additional_oa_fee_key.json")
    ) as fh:
        policy = json.load(fh)

    updated_policy = remove_costly_oa_from_publisher_policy(policy)
    assert len(policy["permitted_oa"]) == 3
    assert len(updated_policy["permitted_oa"]) == 2
