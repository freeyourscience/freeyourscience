module MainTest exposing (..)

import Expect exposing (Expectation)
import Main exposing (parsePolicies)
import Test exposing (..)
import Types exposing (..)


recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
recommendedPathway =
    ( { additionalUrls = Just [ { description = "Vereinbarung zur Rechteűbertragung", url = "https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf" } ]
      , profileUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
      , notes = Just "Notes about this policy"
      }
    , { articleVersions = [ "submitted" ]
      , locations = [ "Academic Social Networks", "Author's Homepage", "Non-commercial Repositories", "PubMed Central" ]

      -- TODO: Add/test parsing embargo into prerequisites
      , prerequisites = Just [ "If Required by Funder" ]
      , conditions = Just [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
      }
    )


pathwayDetails : List BackendPolicy
pathwayDetails =
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
                        { location = [ "academic_social_network", "authors_homepage", "non_commercial_repository", "named_repository" ]
                        , namedRepository = Just [ "PubMed Central" ]
                        }
                  , articleVersions = [ "submitted" ]
                  , conditions = Just [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
                  , prerequisites =
                        Just
                            { prerequisites = [ "when_required_by_funder" ]
                            , prerequisites_phrases =
                                [ { value = "when_required_by_funder"
                                  , phrase = "If Required by Funder"
                                  , language = "en"
                                  }
                                ]
                            }
                  }
                ]
      , policyUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
      , notes = Just "Notes about this policy"
      }
    ]


suite : Test
suite =
    describe "recommendPathway"
        [ test "valid first prio pathway" <|
            \_ -> Expect.equal (Just recommendedPathway) (parsePolicies pathwayDetails)
        ]
