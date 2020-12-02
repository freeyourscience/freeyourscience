import json
import tarfile

SNAPSHOT_PATH = "/mnt/data/wbf/crossref-metadata-2020-10.json.tar.gz"


def doi_issn_loader(json_tar_gz_path):
    with tarfile.open(json_tar_gz_path, "r:gz") as tar:
        for file in tar:
            if file.name.endswith(".json"):
                data = json.loads(tar.extractfile(file).read())
                for record in data["items"]:
                    yield (
                        {
                            "doi": record["DOI"],
                            "issn": record.get("ISSN", "not-available")[0],
                        }
                    )


if __name__ == "__main__":
    subset = []
    doi_issn = doi_issn_loader(SNAPSHOT_PATH)
    for i in range(1000000):
        if i % 100 == 0:
            subset.append(next(doi_issn))
        else:
            next(doi_issn)
    with open("tests/assets/crossref_subset.json", "w") as fh:
        json.dump(subset, fh)
