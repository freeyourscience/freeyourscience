from .are_we_right import calculate_metrics


def test_calculate_metrics():
    papers = [
        {
            "doi": "10.1011/111111",
            "issn": "1234-1234",
            "pathway": "already-oa",
            "unpaywall_status": "oa",
        },
        {
            "doi": "10.1011/222222",
            "issn": "1234-1234",
            "pathway": "nocost",
            "unpaywall_status": "not-oa",
        },
        {
            "doi": "10.1011/222222",
            "issn": "1234-5678",
            "pathway": "other",
            "unpaywall_status": "not-oa",
        },
        {
            "doi": "10.1011/444444",
            "issn": "1234-1234",
            "pathway": "not-attempted",
            "unpaywall_status": "not-found",
        },
    ]

    n_oa, n_pathway_nocost, n_pathway_other, n_unknown = calculate_metrics(papers)

    assert n_oa == 1
    assert n_pathway_nocost == 1
    assert n_pathway_other == 1
    assert n_unknown == 1
