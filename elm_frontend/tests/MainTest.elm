module MainTest exposing (..)

import Expect exposing (Expectation)
import Main exposing (recommendPathway, recommendedPathway)
import Test exposing (..)
import Types exposing (..)


pathwayDetails : List PathwayDetails
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
                        { location = [ "academic_social_network", "authors_homepage", "non_commercial_repository" ]
                        , namedRepository = Just [ "PubMed Central" ]
                        }
                  , articleVersion = [ "submitted" ]
                  , conditions = [ "Published source must be acknowledged", "Must link to publisher version with DOI" ]
                  }
                ]
      }
    ]


suite : Test
suite =
    describe "recommendPathway"
        [ test "valid first prio pathway" <|
            \_ -> Expect.equal recommendedPathway (recommendPathway pathwayDetails)
        ]
