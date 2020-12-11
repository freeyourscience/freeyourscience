import re
from typing import Optional

import requests
import xml.etree.ElementTree as ET

from wbf.schemas import FullPaper, Author

# TODO: Add API key for prod setting

EXT_IDS = "{http://www.orcid.org/ns/common}external-ids"
EXT_ID_TYPE = "{http://www.orcid.org/ns/common}external-id-type"
EXT_ID_VALUE = "{http://www.orcid.org/ns/common}external-id-value"
CREDIT_NAME = "{http://www.orcid.org/ns/personal-details}credit-name"
FAMILY_NAME = "{http://www.orcid.org/ns/personal-details}family-name"
GIVEN_NAMES = "{http://www.orcid.org/ns/personal-details}given-names"
WORKS = "{http://www.orcid.org/ns/activities}works"


def get_author_with_papers(orcid: str) -> Optional[Author]:
    r = requests.get(f"https://pub.orcid.org/{orcid}")
    if not r.ok:
        # TODO: Log and/or handle differently
        return None

    xml = r.content.decode()
    root = ET.fromstring(xml)

    credit_name = list(root.iter(CREDIT_NAME))
    if credit_name:
        author_name = credit_name[0].text
    else:
        given_names = list(root.iter(GIVEN_NAMES))[0].text
        faily_name = list(root.iter(FAMILY_NAME))[0].text
        author_name = f"{given_names} {faily_name}"

    works = list(root.iter(WORKS))[0]
    external_ids = [eid for eid in works.iter(EXT_IDS)]
    dois_with_issn = {}
    for eids in external_ids:
        doi, issn = None, None
        for child in eids:
            if child.find(EXT_ID_TYPE).text == "doi":
                doi = child.find(EXT_ID_VALUE).text
            elif child.find(EXT_ID_TYPE).text == "issn":
                issn = child.find(EXT_ID_VALUE).text

        if doi is not None and issn is not None:
            dois_with_issn[doi] = issn
        elif doi is not None and doi not in dois_with_issn:
            dois_with_issn[doi] = None

    papers = [FullPaper(doi=doi, issn=issn) for doi, issn in dois_with_issn.items()]
    return Author(
        name=author_name,
        papers=papers,
        provider="orcid",
        profile_url=f"https://orcid.org/{orcid}",
    )


def is_orcid(orcid: str) -> bool:
    return re.match("[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}", orcid) is not None
