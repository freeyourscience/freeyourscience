module ApiTest exposing (..)

import Expect
import Json.Decode as D
import Papers.Backend as Backend
import Test exposing (Test, describe, test)


fullPaperJson : String
fullPaperJson =
    """
{
    "doi": "10.1002/STAB.201710469",
    "title": "Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau",
    "journal": "Stahlbau",
    "authors": "Sigrid Brell-Cokcan et al.",
    "year": 2017,
    "published_date": null,
    "issn": "0038-9145",
    "is_open_access": false,
    "can_share_your_paper": false,
    "oa_pathway": "nocost",
    "oa_location_url": "https://doi.org/10.1002/STAB.201710469",
    "oa_pathway_details": [
        {
            "open_access_prohibited": "no",
            "sherpa_publication_uri": "https://v2.sherpa.ac.uk/id/publication/1908",
            "urls": [
                {
                    "description": "Vereinbarung zur Rechteűbertragung",
                    "url": "https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf"
                }
            ],
            "notes": "Notes about this policy",
            "permitted_oa": [
                {
                    "additional_oa_fee": "no",
                    "public_notes": [
                        "pathway notes"
                        ],
                    "embargo": {
                        "amount":12,
                        "units_phrases": [
                            {"phrase":"Months","value":"months","language":"en"}
                            ],
                        "units": "months"
                        },
                    "prerequisites": {
                        "prerequisites": ["required_by_funder"],
                        "prerequisites_phrases": [{
                                "phrase": "Required by funder",
                                "language": "en",
                                "value": "required_by_funder"
                            }],
                        "prerequisite_subjects": ["Math", "Chemistry"],
                        "prerequisite_funders": [
                            { "funder_metadata": {
                                "country_phrases": [
                                    {
                                    "value": "gb",
                                    "language": "en",
                                    "phrase": "United Kingdom"
                                    }
                                ],
                                "identifiers": [
                                    {
                                    "identifier": "http://dx.doi.org/10.13039/100004440",
                                    "type_phrases": [
                                        {
                                        "phrase": "FundRef DOI",
                                        "value": "fundref",
                                        "language": "en"
                                        }
                                    ],
                                    "type": "fundref"
                                    },
                                    {
                                    "type": "ror",
                                    "identifier": "https://ror.org/029chgv08",
                                    "type_phrases": [
                                        {
                                        "value": "ror",
                                        "language": "en",
                                        "phrase": "ROR ID"
                                        }
                                    ]
                                    }
                                ],
                                "id": 695,
                                "url": [
                                    {
                                    "url": "http://www.wellcome.ac.uk/",
                                    "language_phrases": [
                                        {
                                        "phrase": "English",
                                        "value": "en",
                                        "language": "en"
                                        }
                                    ],
                                    "language": "en"
                                    }
                                ],
                                "country": "gb",
                                "name": [
                                    {
                                    "name": "Wellcome Trust",
                                    "preferred_phrases": [
                                        {
                                        "value": "name",
                                        "language": "en",
                                        "phrase": "Name"
                                        }
                                    ],
                                    "preferred": "name",
                                    "language": "en",
                                    "language_phrases": [
                                        {
                                        "value": "en",
                                        "language": "en",
                                        "phrase": "English"
                                        }
                                    ]
                                    }
                                ],
                                "groups": [
                                    {
                                    "type": "funder_group",
                                    "id": 1059,
                                    "uri": "https://v2.sherpa.ac.uk/id/funder_group/1059",
                                    "name": "Europe PMC Funders' Group"
                                    },
                                    {
                                    "id": 1063,
                                    "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                                    "name": "Plan S Funders",
                                    "type": "funder_group"
                                    }
                                ]
                                },
                                "system_metadata": {
                                "id": 695,
                                "uri": "https://v2.sherpa.ac.uk/id/funder/695"
                                }
                            }
                        ]
                    },
                    "location": {
                        "location_phrases": [
                            {
                                "phrase": "Academic Social Network",
                                "language": "en",
                                "value": "academic_social_network"
                            },
                            {
                                "phrase": "Author's Homepage",
                                "language": "en",
                                "value": "authors_homepage"
                            },
                            {
                                "language": "en",
                                "value": "non_commercial_repository",
                                "phrase": "Non-Commercial Repository"
                            }
                        ],
                        "location": [
                            "academic_social_network",
                            "authors_homepage",
                            "non_commercial_repository"
                        ],
                        "named_repository" : [
                            "PubMed Central"
                        ]
                    },
                    "article_version": [
                        "submitted"
                    ],
                    "article_version_phrases": [
                        {
                            "language": "en",
                            "value": "submitted",
                            "phrase": "Submitted"
                        }
                    ],
                    "additional_oa_fee_phrases": [
                        {
                            "language": "en",
                            "value": "no",
                            "phrase": "No"
                        }
                    ],
                    "conditions": [
                        "Published source must be acknowledged",
                        "Must link to publisher version with DOI"
                    ]
                }
            ],
            "open_access_prohibited_phrases": [
                {
                    "language": "en",
                    "value": "no",
                    "phrase": "No"
                }
            ],
            "internal_moniker": "Ernst und Sohn",
            "publication_count": 12,
            "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/1390",
            "id": 1390
        }
    ]
}
"""


oaPathwayNull : String
oaPathwayNull =
    """
{
    "doi": "10.1002/STAB.201710469",
    "title": "Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau",
    "journal": "Stahlbau",
    "authors": "Sigrid Brell-Cokcan et al.",
    "year": 2017,
    "published_date": null,
    "issn": "0038-9145",
    "is_open_access": false,
    "can_share_your_paper": false,
    "oa_pathway": "nocost",
    "oa_pathway_details": null,
    "oa_location_url": "https://doi.org/10.1002/STAB.201710469"
}
"""


fullPaperElm : Backend.Paper
fullPaperElm =
    { doi = "10.1002/STAB.201710469"
    , title = Just "Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau"
    , journal = Just "Stahlbau"
    , authors = Just "Sigrid Brell-Cokcan et al."
    , year = Just 2017
    , publishedDate = Nothing
    , issn = Just "0038-9145"
    , isOpenAccess = Just False
    , oaPathway = Just "nocost"
    , oaLocationURL = Just "https://doi.org/10.1002/STAB.201710469"
    , pathwayDetails =
        Just
            [ { urls =
                    Just
                        [ { description = "Vereinbarung zur Rechteűbertragung"
                          , url = "https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf"
                          }
                        ]
              , permittedOA =
                    Just
                        [ { additionalOaFee = "no"
                          , location =
                                { location = [ "academic_social_network", "authors_homepage", "non_commercial_repository" ]
                                , namedRepository = Just [ "PubMed Central" ]
                                }
                          , articleVersions = [ "submitted" ]
                          , conditions = Just [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
                          , prerequisites =
                                Just
                                    { prerequisites = Just [ "required_by_funder" ]
                                    , prerequisitesPhrases =
                                        Just
                                            [ { value = "required_by_funder"
                                              , phrase = "Required by funder"
                                              , language = "en"
                                              }
                                            ]
                                    , prerequisiteFunders =
                                        Just
                                            [ { funderMetadata =
                                                    { name = [ { name = "Wellcome Trust" } ]
                                                    , url = [ { url = "http://www.wellcome.ac.uk/" } ]
                                                    }
                                              }
                                            ]
                                    , prerequisiteSubjects = Just [ "Math", "Chemistry" ]
                                    }
                          , embargo = Just { amount = 12, units = "months" }
                          , publicNotes = Just [ "pathway notes" ]
                          }
                        ]
              , policyUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
              , sherpaPublicationUrl = "https://v2.sherpa.ac.uk/id/publication/1908"
              , notes = Just "Notes about this policy"
              }
            ]
    }


suite : Test
suite =
    describe "Testing the paperDecoder"
        [ test "Successful decoding of full paper" <|
            let
                decodedPaper =
                    D.decodeString Backend.paperDecoder fullPaperJson
            in
            \_ -> Expect.equal (Ok fullPaperElm) decodedPaper
        , test "Handle null for oa_pathway_details" <|
            \_ ->
                Expect.equal
                    (Ok { fullPaperElm | pathwayDetails = Nothing })
                    (D.decodeString Backend.paperDecoder oaPathwayNull)
        ]
