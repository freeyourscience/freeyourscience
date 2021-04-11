import os
import json

from contextlib import contextmanager


@contextmanager
def json_filesystem_cache(name):
    pathway_cache = dict()
    if os.path.isfile(name):
        with open(name, "r") as fh:
            pathway_cache = json.load(fh)
            print(f"Loaded cache containing {len(pathway_cache)} items from file")
    try:
        yield pathway_cache
    finally:
        print(f"Saved cache containing {len(pathway_cache)} items to file")
        with open(name, "w") as fh:
            json.dump(pathway_cache, fh, indent=2)
