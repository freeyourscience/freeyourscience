from typing import List, Optional
from enum import Enum

from pydantic import BaseModel, Field

# TODO: Unify paper models


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
    is_open_access: Optional[bool] = None


class PaperWithOAPathway(PaperWithOAStatus):
    oa_pathway: OAPathway = Field(...)
    oa_pathway_details: Optional[List[dict]] = None


class FullPaper(BaseModel):
    doi: str
    title: Optional[str] = None
    journal: Optional[str] = None
    authors: Optional[str] = None
    year: Optional[int] = None
    published_date: Optional[str] = None
    issn: Optional[str] = None
    is_open_access: Optional[bool] = None
    oa_location_url: Optional[str] = None
    oa_pathway: Optional[OAPathway] = None
    oa_pathway_details: Optional[List[dict]] = None
    can_share_your_paper: bool = False


class Author(BaseModel):
    name: str
    paper_ids: List[str]
    profile_url: Optional[str] = None
    provider: Optional[str] = None


class LogEntry(BaseModel):
    event: str
    message: str
