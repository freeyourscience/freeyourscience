import gzip
import json
import tarfile

UNPAYWALL_SNAPSHOT_PATH = "/mnt/data/wbf/unpaywall.jsonl.gz"


def extract_doi_issn(json_loader):
    """Yields only the doi and issn of a json record"""
    for record in json_loader:
        yield (
            {
                "doi": record["doi"],
                "is_oa": record["is_oa"],
                "journal_issn_l": record.get("journal_issn_l", "not-available"),
            }
        )


def load_unpaywall_snapshot(jsonl_gzip_path):
    """Yields records from unpaywall snapshot jsonl.gzip"""
    with gzip.open(jsonl_gzip_path) as file:
        for line in file:
            yield json.loads(line)


if __name__ == "__main__":
    subset = []
    doi_issn = extract_doi_issn(load_unpaywall_snapshot(UNPAYWALL_SNAPSHOT_PATH))
    for i in range(10000):
        if i % 100 == 0:
            subset.append(next(doi_issn))
        else:
            next(doi_issn)
    with open("tests/assets/unpaywall_subset.json", "w") as fh:
        json.dump(subset, fh)
