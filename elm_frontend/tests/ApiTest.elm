module ApiTest exposing (..)

import Api exposing (paperDecoder)
import Expect
import Json.Decode as D
import Test exposing (Test, describe, test)
import Types exposing (..)


fullPaperJson : String
fullPaperJson =
    """
{
    "doi": "10.1002/STAB.201710469",
    "title": "Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau",
    "journal": "Stahlbau",
    "authors": "Sigrid Brell-Cokcan et al.",
    "year": 2017,
    "issn": "0038-9145",
    "is_open_access": false,
    "oa_pathway": "nocost",
    "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/1908",
    "oa_pathway_details": [
        {
            "open_access_prohibited": "no",
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
                    "embargo": {
                        "amount":12,
                        "units_phrases": [
                            {"phrase":"Months","value":"months","language":"en"}
                            ],
                        "units": "months"
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
{"doi":"10.1002/STAB.201710469","title":"Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau","journal":"Stahlbau","authors":"Sigrid Brell-Cokcan et al.","year":2017,"issn":"0038-9145","is_open_access":false,"oa_pathway":"nocost","oa_pathway_uri":"https://v2.sherpa.ac.uk/id/publication/1908","oa_pathway_details":null}
"""


fullPaperElm : BackendPaper
fullPaperElm =
    { doi = "10.1002/STAB.201710469"
    , title = Just "Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau"
    , journal = Just "Stahlbau"
    , authors = Just "Sigrid Brell-Cokcan et al."
    , year = Just 2017
    , issn = Just "0038-9145"
    , isOpenAccess = Just False
    , oaPathway = Just "nocost"
    , oaPathwayURI = Just "https://v2.sherpa.ac.uk/id/publication/1908"
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
                          , prerequisites = Nothing
                          , embargo = Just { amount = 12, units = "months" }
                          }
                        ]
              , policyUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
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
                    D.decodeString paperDecoder fullPaperJson
            in
            \_ -> Expect.equal (Ok fullPaperElm) decodedPaper
        , test "Handle null for oa_pathway_details" <|
            \_ -> Expect.equal (Ok { fullPaperElm | pathwayDetails = Nothing }) (D.decodeString paperDecoder oaPathwayNull)
        ]
