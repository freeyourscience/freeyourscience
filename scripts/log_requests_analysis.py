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

import pandas as pd
import altair as alt

from fyscience.schemas import Paper
from fyscience.oa_status import oa_status


def interpret_payload(log):
    if "GET / " in log["payload"]:
        log.update({"interpreted": "landing page hit"})
    elif "GET /syp?" in log["payload"]:
        log.update({"interpreted": "SYP hit"})
    elif "GET /static/singlePaper" in log["payload"]:
        log.update({"interpreted": "singlePaper JS loaded"})
    elif "GET /static/author" in log["payload"]:
        log.update({"interpreted": "authors JS loaded"})
    elif "GET /search?query=10." in log["payload"]:
        log.update({"interpreted": "DOI search"})
    elif "GET /search?" in log["payload"]:
        log.update({"interpreted": "non-DOI search"})
    return log


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

    withPayload = filter(lambda log: log.get("textPayload", False), logs)
    payloads = map(
        lambda log: {"payload": log["textPayload"], "timestamp": log["timestamp"]},
        withPayload,
    )
    interpreted = map(interpret_payload, payloads)

    data = pd.DataFrame(filter(lambda log: log.get("interpreted", False), interpreted))
    selection = alt.selection_multi(fields=["interpreted"])
    color = alt.condition(
        selection, alt.Color("interpreted:N", legend=None), alt.value("lightgray")
    )
    bar = (
        alt.Chart(data)
        .mark_bar()
        .encode(
            x="yearmonthdate(timestamp):T",
            y="count(interpreted)",
            color=color,
            tooltip=["interpreted:N", "count(interpreted)"],
        )
        .properties(width=1200, height=400)
        .interactive()
    )

    legend = (
        alt.Chart(data)
        .mark_point()
        .encode(y=alt.Y("interpreted:N", axis=alt.Axis(orient="right")), color=color)
        .add_selection(selection)
    )

    chart = bar | legend
    chart.save("./requests.html")