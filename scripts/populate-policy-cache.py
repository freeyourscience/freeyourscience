import os
import requests

from dotenv import load_dotenv
from expression.core import pipe

load_dotenv()

api_key = os.getenv("SHERPA_API_KEY")
if api_key is None:
    raise RuntimeError(
        "No Sherpa API key available in the 'SHERPA_API_KEY' environment variable."
    )


def query_sherpa(issn):
    return requests.get(
        "https://v2.sherpa.ac.uk/cgi/retrieve?"
        + f"item-type=publication&api-key={api_key}&format=Json&"
        + f'filter=[["issn","equals","{issn}"]]'
    )


def extract_policy(response):
    if not response.ok:
        return "bad response"

    try:
        return response.json()["items"][0]["publisher_policy"]
    except Exception:
        return "No publication or policy found"


def get_policy(issn):
    return pipe(
        issn,
        query_sherpa,
        extract_policy,
    )


issn = "0000-0205"

print(get_policy(issn))