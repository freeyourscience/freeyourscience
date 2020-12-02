input_of_papers = [
  {'doi':'10.1011/111111' , 'issn':'1234-1234'},
  {'doi':'10.1011/222222' , 'issn':'1234-1234'}
]

def is_oa(paper: dict):
  if paper['doi'] == '10.1011/111111':
    return True
  else:
    return False

n_pubs = len(input_of_papers)

non_oa_papers = list(filter(is_oa, input_of_papers))

n_oa = n_pubs - len(non_oa_papers)

n_pathway_nocost, n_pathway_other, n_unknown = 500, 50, 50

print(f"looked at {n_pubs} publications")
print(f"{n_oa} are already OA")
print(f"{n_pathway_nocost} could be OA at no cost")
print(f"{n_pathway_other} could only be OA at cost")
print(f"{n_unknown} could not be determined")
