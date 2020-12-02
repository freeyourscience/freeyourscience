import json
import tarfile

SNAPSHOT_PATH = "/mnt/data/wbf/crossref-metadata-2020-10.json.tar.gz"

with tarfile.open(SNAPSHOT_PATH, "r:gz") as tar:
    for i, file in enumerate(tar):
        if file.name.endswith(".json"):
            data = json.loads(tar.extractfile(file).read())
            extract = [(i['DOI'], i.get('ISSN', 'not-available')[0]) for i in data['items']]
            print(extract)
            break
