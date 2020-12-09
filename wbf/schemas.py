from typing import List, Optional
from enum import Enum

from pydantic import BaseModel, Field

# TODO: Unify paper models


class OAStatus(str, Enum):
    oa = "oa"
    not_oa = "not_oa"
    not_found = "not_found"


class OAPathway(str, Enum):
    already_oa = "already_oa"
    not_attempted = "not_attempted"
    nocost = "nocost"
    other = "other"
    not_found = "not_found"


class Paper(BaseModel):
    """The data model for a paper"""

    # Regex taken from:
    # https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    # TODO: Check if regex is applicable
    doi: str = Field(
        ...,
        # regex="/^10.\d{4,9}/[-._;()/:A-Z0-9]+$/i"
    )

    # Regex taken from:
    # https://en.wikipedia.org/wiki/International_Standard_Serial_Number
    # TODO: Check if regex is applicable
    issn: str = Field(
        ...,
        # regex="^[0-9]{4}-[0-9]{3}[0-9xX]$"
    )


class PaperWithOAStatus(Paper):
    oa_status: OAStatus = Field(...)


class PaperWithOAPathway(PaperWithOAStatus):
    oa_pathway: OAPathway = Field(...)
    oa_pathway_details: Optional[List[dict]] = None


class DetailedPaper(PaperWithOAPathway):
    title: str


class FullPaper(BaseModel):
    doi: str
    title: Optional[str] = None
    issn: Optional[str] = None
    oa_status: Optional[OAStatus] = None
    oa_pathway: Optional[OAPathway] = None
    oa_pathway_details: Optional[List[dict]] = None
