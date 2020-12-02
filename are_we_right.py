from typing import Optional

input_of_papers = [
    {"doi": "10.1011/111111", "issn": "1234-1234"},
    {"doi": "10.1011/222222", "issn": "1234-1234"},
    {"doi": "10.1011/333333", "issn": "1234-1234"},
]
n_unknown = 0


def unpaywall_state(paper: dict) -> Optional[bool]:
    if paper["doi"] == "10.1011/111111":
        paper["unpaywall_status"] = True
    elif paper["doi"] == "10.1011/222222":
        paper["unpaywall_status"] = False
    else:
        paper["unpaywall_status"] = None

    return paper


n_pubs = len(input_of_papers)

papers_with_oa_states = list(map(unpaywall_state, input_of_papers))
n_oa = sum((True for p in papers_with_oa_states if p["unpaywall_status"]))
n_unknown += sum((True for p in papers_with_oa_states if p["unpaywall_status"] is None))

n_pathway_nocost, n_pathway_other = 500, 50

print(f"looked at {n_pubs} publications")
print(f"{n_oa} are already OA")
print(f"{n_pathway_nocost} could be OA at no cost")
print(f"{n_pathway_other} could only be OA at cost")
print(f"{n_unknown} could not be determined")
