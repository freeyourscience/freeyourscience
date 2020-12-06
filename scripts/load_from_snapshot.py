import gzip
import json

UNPAYWALL_SNAPSHOT_PATH = "/mnt/data/wbf/unpaywall.jsonl.gz"


def extract_fields(json_loader):
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
    doi_issn = extract_fields(load_unpaywall_snapshot(UNPAYWALL_SNAPSHOT_PATH))
    with open("tests/assets/unpaywall_subset.jsonl", "w") as fh:
        for i, record in enumerate(doi_issn):
            if i == 1000:
                break
            fh.write(json.dumps(record))
            fh.write("\n")
