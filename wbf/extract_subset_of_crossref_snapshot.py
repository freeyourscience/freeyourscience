import json
import tarfile

SNAPSHOT_PATH = "/mnt/data/wbf/crossref-metadata-2020-10.json.tar.gz"

with tarfile.open(SNAPSHOT_PATH, "r:gz") as tar:
    for i, file in enumerate(tar):
        if file.name.endswith(".json"):
            data = json.loads(tar.extractfile(file).read())
            print(json.dumps(data, indent=2))
            break
