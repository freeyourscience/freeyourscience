import json


def load_jsonl(filepath):
    with open(filepath, "r") as fh:
        for line in fh:
            yield json.loads(line)
