"""Download the logs with the following command after authenticating and selecting the
matching project (find out the right one with "gcloud projects list")

gclout auth login

gsutil -m rsync -r \
  "gs://prod-log-bucket/run.googleapis.com/stderr/" \
  .

and pass the directory from which the download was run to this script.
"""

import json
import argparse
from pathlib import Path

from fyscience.schemas import Paper
from fyscience.oa_status import oa_status


if __name__ == "__main__":
    parser = argparse.ArgumentParser("FYS Log Analysis")
    parser.add_argument("log_dir", type=str)
    parser.add_argument(
        "--verbose", action="store_true", help="increase output verbosity"
    )
    args = parser.parse_args()
    verbose = args.verbose
    log_dir = Path(args.log_dir)
    print("Loading all JSON files in directory", log_dir)

    logs = []
    num_files = 0
    for path in log_dir.rglob("*.json"):
        num_files += 1
        with open(path, "r") as fh:
            logs.extend([json.loads(line) for line in fh.readlines()])
    print(f"Finished loading {num_files} log files")

    events = {}
    for log in logs:
        text_payload = log["textPayload"]
        if not (
            " INFO " in text_payload
            or " WARNING " in text_payload
            or " ERROR " in text_payload
        ):
            if verbose:
                print("Skipping:", text_payload)
            continue

        extract = text_payload.split(" - {")[-1]
        extract = "{" + extract

        # Fix that extracts aren't JSON but string representations of Python dicts
        extract = extract.replace("'", "<QTE>").replace('"', "'").replace("<QTE>", '"')
        extract = extract.replace("True", "true").replace("False", "false")

        payload = json.loads(extract)

        if not payload["event"] in events:
            events[payload["event"]] = []
        events[payload["event"]].append(payload)

    print("Found events:", list(events.keys()))

    unique_dois = set([e["doi"] for e in events["get_paper"]])
    print(len(unique_dois), "unique DOIs requested")

    found = {e["doi"]: e for e in events["get_paper"] if e["message"] == "paper_found"}
    print(len(found), "unique publications found")

    can_syp = [e for e in found.values() if e.get("can_syp", False) and not e["is_oa"]]
    print(len(can_syp), "can ShareYourPaper")

    free_pathway = [e for e in found.values() if e["pathway"] == "OAPathway.nocost"]
    print(len(free_pathway), "with Sherpa free pathway")

    free_pathway_and_syp = [e for e in can_syp if e["pathway"] == "OAPathway.nocost"]
    print(len(free_pathway_and_syp), "with Sherpa free pathway and SYP")

    cases = [
        ("recommend_cansyp", "SYP allows -> SYP button"),
        ("norecommend_cansyp", "SYP allows -> Details button"),
    ]
    for case, description in cases:
        case_events = [
            e
            for e in events["client_side_author_free_pathway_paper"]
            if e["message"].startswith(case)
        ]
        print(len(case_events), description)

    # free_pathway_papers = [
    #     oa_status(Paper(doi=e["doi"], issn="")) for e in free_pathway
    # ]
    # now_oa = [p for p in free_pathway_papers if p.is_open_access]
    # print(
    #     len(now_oa), "of requested that were previously paywalled are open access now"
    # )
