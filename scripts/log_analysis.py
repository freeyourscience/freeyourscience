import json
import argparse
from pathlib import Path

if __name__ == "__main__":
    parser = argparse.ArgumentParser("FYS Log Analysis")
    parser.add_argument("log_dir", type=str)
    args = parser.parse_args()
    log_dir = Path(args.log_dir)
    print("Loading all JSON files in directory", args.log_dir)

    logs = []
    num_files = 0
    for path in log_dir.rglob("*.json"):
        num_files += 1
        with open(log_dir / path.name, "r") as fh:
            logs.extend([json.loads(line) for line in fh.readlines()])
    print(f"Finished loading {num_files} log files")

    events = {}
    for log in logs:
        text_payload = log["textPayload"]
        extract = text_payload.split(" - ")[-1]

        # Fix that extracts aren't JSON but string representations of Python dicts
        extract = extract.replace("'", "<QTE>").replace('"', "'").replace("<QTE>", '"')
        extract = extract.replace("True", "true").replace("False", "false")

        payload = json.loads(extract)

        if not payload["event"] in events:
            events[payload["event"]] = []
        events[payload["event"]].append(payload)

    print("Found events:", list(events.keys()))

    unique_dois = set([e["doi"] for e in events["get_paper"]])
    print(len(unique_dois), "unique DOIs searched")
