import gzip
import json

UNPAYWALL_SNAPSHOT_PATH = "/home/hff/Downloads/unpaywall.jsonl.gz"


def extract_fields(json_loader):
    for record in json_loader:
        yield (
            {
                "doi": record["doi"],
                "is_oa": record["is_oa"],
                "journal_issn_l": record.get("journal_issn_l", "not-available"),
                "journal_name": record.get("journal_name", "not-available"),
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
            fh.write(json.dumps(record))
            fh.write("\n")
