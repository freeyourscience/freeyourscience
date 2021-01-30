module MainTest exposing (..)

import Expect
import Papers.Backend exposing (Policy)
import Papers.FreePathway exposing (NoCostOaPathway, Pathway, PolicyMetaData, recommendPathway, scorePathway)
import Test exposing (Test, describe, test)


pathway : Pathway
pathway =
    { additionalOaFee = "no"
    , articleVersions = Just [ "submitted" ]
    , locationSorted =
        { location = [ "this_journal", "any_repository" ]
        , namedRepository = Nothing
        }
    , prerequisites = Just [ "If Required by Funder" ]
    , embargo = Just "12 months"
    , conditions = Just [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
    , notes = Just [ "Pathway specific notes" ]
    }


noCostOaPathway : NoCostOaPathway
noCostOaPathway =
    { articleVersions = [ "submitted" ]
    , locationLabelsSorted = [ "Non-commercial repositories", "PubMed Central", "Author's homepage", "Academic social networks" ]
    , prerequisites = Just [ "If Required by Funder" ]
    , embargo = Just "12 months"
    , conditions = Just [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
    , notes = Just [ "Pathway specific notes" ]
    }


recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
recommendedPathway =
    ( { additionalUrls = Just [ { description = "Vereinbarung zur Rechteűbertragung", url = "https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf" } ]
      , profileUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
      , notes = Just "Notes about this policy"
      }
    , noCostOaPathway
    )


pathwayDetails : List Policy
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
                \_ -> Expect.equal (Just recommendedPathway) (recommendPathway pathwayDetails)
            ]
        , describe "scoreNoCostPathway"
            [ test "relative score example" <|
                let
                    liberalPathway =
                        { pathway
                            | articleVersions = Just [ "published" ]
                            , locationSorted =
                                { location = [ "any_repository" ]
                                , namedRepository = Nothing
                                }
                            , additionalOaFee = "no"
                        }

                    restrictivePathway =
                        { pathway
                            | articleVersions = Just [ "submitted" ]
                            , locationSorted =
                                { location = [ "this_journal" ]
                                , namedRepository = Nothing
                                }
                            , additionalOaFee = "no"
                        }
                in
                \_ -> Expect.greaterThan (scorePathway restrictivePathway) (scorePathway liberalPathway)
            ]
        ]
