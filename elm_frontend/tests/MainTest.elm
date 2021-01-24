module MainTest exposing (..)

import Expect
import Main exposing (parsePolicies, scoreNoCostPathway)
import Test exposing (Test, describe, test)
import Types exposing (..)


recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
recommendedPathway =
    ( { additionalUrls = Just [ { description = "Vereinbarung zur Rechteűbertragung", url = "https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf" } ]
      , profileUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
      , notes = Just "Notes about this policy"
      }
    , { articleVersions = [ "submitted" ]
      , locations = [ "Non-commercial repositories", "PubMed Central", "Author's homepage", "Academic social networks" ]
      , prerequisites = Just [ "If Required by Funder" ]
      , embargo = Just "12 months"
      , conditions = Just [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
      , notes = Just [ "Pathway specific notes" ]
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
                  , embargo = Just { amount = 12, units = "months" }
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
                  , publicNotes = Just [ "Pathway specific notes" ]
                  }
                ]
      , policyUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
      , notes = Just "Notes about this policy"
      }
    ]


suite : Test
suite =
    describe "main tests"
        [ describe "recommendPathway"
            [ test "valid first prio pathway" <|
                \_ -> Expect.equal (Just recommendedPathway) (parsePolicies pathwayDetails)
            ]
        , describe "scoreNoCostPathway"
            [ test "relative score example" <|
                let
                    liberal_pathway =
                        { articleVersions = [ "published" ]
                        , locations = [ "any_repository" ]
                        , prerequisites = Nothing
                        , conditions = Nothing
                        , embargo = Nothing
                        , notes = Nothing
                        }

                    restrictive_pathway =
                        { articleVersions = [ "submitted" ]
                        , locations = [ "this_journal" ]
                        , prerequisites = Nothing
                        , conditions = Nothing
                        , embargo = Nothing
                        , notes = Nothing
                        }
                in
                \_ -> Expect.greaterThan (scoreNoCostPathway restrictive_pathway) (scoreNoCostPathway liberal_pathway)
            ]
        ]
