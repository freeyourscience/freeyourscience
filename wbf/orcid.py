from typing import List, Optional, Tuple

import requests
import xml.etree.ElementTree as ET

from wbf.schemas import FullPaper

# TODO: Add API key for prod setting

EXT_IDS = "{http://www.orcid.org/ns/common}external-ids"
EXT_ID_TYPE = "{http://www.orcid.org/ns/common}external-id-type"
EXT_ID_VALUE = "{http://www.orcid.org/ns/common}external-id-value"


def _get_dois_with_issn_from_works(
    orcid: str,
) -> Optional[List[Tuple(str, Optional[str])]]:
    r = requests.get(f"https://pub.orcid.org/{orcid}/works")
    if not r.ok:
        # TODO: Log and/or handle differently
        return None

    xml = r.content.decode()
    works = ET.fromstring(xml)
    external_ids = [eid for eid in works.iter(EXT_IDS)]
    dois_with_issn = []
    for eids in external_ids:
        doi, issn = None, None
        for child in eids:
            if child.find(EXT_ID_TYPE).text == "doi":
                doi = child.find(EXT_ID_VALUE).text
            elif child.find(EXT_ID_TYPE).text == "issn":
                issn = child.find(EXT_ID_VALUE).text

        if not (doi is None and issn is None):
            dois_with_issn.append((doi, issn))

    return dois_with_issn


def get_papers(orcid: str) -> Optional[List[FullPaper]]:
    dois_with_issn = _get_dois_with_issn_from_works(orcid)
    papers = [FullPaper(doi=doi, issn=issn) for doi, issn in dois_with_issn]
    return papers
