input_of_papers = [
    {"doi": "10.1011/111111", "issn": "1234-1234"},
    {"doi": "10.1011/222222", "issn": "1234-1234"},
    {"doi": "10.1011/222222", "issn": "1234-5678"},
    {"doi": "10.1011/444444", "issn": "1234-1234"},
]
"""
looked at 4 publications"
1 are already OA"
1 could be OA at no cost"
1 has other OA pathway(s)"
1 could not be determined"
"""


def unpaywall_status(paper: dict) -> dict:
    if paper["doi"] == "10.1011/111111":
        paper["unpaywall_status"] = "oa"
    elif paper["doi"] == "10.1011/222222":
        paper["unpaywall_status"] = "not-oa"
    else:
        paper["unpaywall_status"] = "not-found"

    return paper


def oa_pathway(paper: dict) -> dict:
    if paper["unpaywall_status"] == "oa":
        paper["pathway"] = "already-oa"
        return paper
    if paper["unpaywall_status"] == "not-found":
        paper["pathway"] = "not-attempted"
        return paper

    if paper["issn"] == "1234-1234":
        paper["pathway"] = "nocost"
    elif paper["issn"] == "1234-5678":
        paper["pathway"] = "other"
    else:
        paper["pathway"] = "not-found"

    return paper


n_pubs = len(input_of_papers)

papers_with_oa_status = map(unpaywall_status, input_of_papers)
papers_with_pathway = map(oa_pathway, papers_with_oa_status)

n_oa = 0
n_pathway_nocost = 0
n_pathway_other = 0
n_unknown = 0

for p in papers_with_pathway:
    if p["unpaywall_status"] == "oa":
        n_oa += 1
    elif p["pathway"] == "nocost":
        n_pathway_nocost += 1
    elif p["pathway"] == "other":
        n_pathway_other += 1
    elif p["unpaywall_status"] == "not-found" or p["pathway"] == "not-found":
        n_unknown += 1

print(f"looked at {n_pubs} publications")
print(f"{n_oa} are already OA")
print(f"{n_pathway_nocost} could be OA at no cost")
print(f"{n_pathway_other} has other OA pathway(s)")
print(f"{n_unknown} could not be determined")
