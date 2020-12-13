import os
import json

from contextlib import contextmanager


@contextmanager
def json_filesystem_cache(name):
    pathway_cache = dict()
    if os.path.isfile(name):
        with open(name, "r") as fh:
            pathway_cache = json.load(fh)
            print(f"Loaded {len(pathway_cache)} cached ISSN to OA pathway mappings")
    try:
        yield pathway_cache
    finally:
        print(f"Cached {len(pathway_cache)} ISSN to OA pathway mappings")
        with open(name, "w") as fh:
            json.dump(pathway_cache, fh, indent=2)
