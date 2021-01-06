module MainTest exposing (..)

import Expect exposing (Expectation)
import Main exposing (recommendPathway)
import Test exposing (..)
import Types exposing (..)


recommendedPathway : Pathway
recommendedPathway =
    { articleVersion = "accepted"
    , locations = [ "Academic Social Network", "Author's Homepage" ]
    , prerequisites = [ "If Required by Institution", "12 months have passed since publication" ]
    , conditions = [ "Must be accompanied by set statement (see policy)", "Must link to publisher version" ]
    , notes = [ "If mandated to deposit before 12 months, the author must obtain a  waiver from their Institution/Funding agency or use  AuthorChoice" ]
    , urls = Just [ { description = "Vereinbarung zur Rechteűbertragung", url = "https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf" } ]
    , policyUrl = "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
    }


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
      , policyUrl = Just "https://v2.sherpa.ac.uk/id/publisher_policy/1390"
      }
    ]


suite : Test
suite =
    describe "recommendPathway"
        [ test "valid first prio pathway" <|
            \_ -> Expect.equal (Just recommendedPathway) (recommendPathway pathwayDetails)
        ]
