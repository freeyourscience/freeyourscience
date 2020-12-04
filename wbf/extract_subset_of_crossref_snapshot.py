import json
import tarfile

SNAPSHOT_PATH = "/mnt/data/wbf/crossref-metadata-2020-10.json.tar.gz"


def extract_doi_issn(json_loader):
    """Yields only the doi and issn of a json record"""
    for record in json_loader:
        yield (
            {
                "doi": record["DOI"],
                "issn": record.get("ISSN", "not-available")[0],
            }
        )


def load_crossref_snapshot(json_tar_gz_path):
    """Yields records from crossreff snapshot json.tar.gz"""
    with tarfile.open(json_tar_gz_path, "r:gz") as tar:
        for file in tar:
            if file.name.endswith(".json"):
                data = json.loads(tar.extractfile(file).read())
                for record in data["items"]:
                    yield record


if __name__ == "__main__":
    subset = []
    doi_issn = extract_doi_issn(load_crossref_snapshot(SNAPSHOT_PATH))
    for i in range(1000000):
        if i % 100 == 0:
            subset.append(next(doi_issn))
        else:
            next(doi_issn)
    with open("tests/assets/crossref_subset.json", "w") as fh:
        json.dump(subset, fh)
