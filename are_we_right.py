input_of_papers = [
  {'doi':'10.1011/111111' , 'issn':'1234-1234'}
]

n_pubs = len(input_of_papers)

n_oa, n_pathway_nocost, n_pathway_other, n_unknown = 400, 500, 50, 50

print(f"looked at {n_pubs} publications")
print(f"{n_oa} are already OA")
print(f"{n_pathway_nocost} could be OA at no cost")
print(f"{n_pathway_other} could only be OA at cost")
print(f"{n_unknown} could not be determined")
