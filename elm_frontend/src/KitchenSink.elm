module KitchenSink exposing (..)

import Animation
import Array
import Browser
import Html exposing (..)
import Main exposing (..)
import Types exposing (..)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


oaPaper1 : Paper
oaPaper1 =
    { doi = "10.100/1010-1234"
    , title = Just "Free Publication 123"
    , journal = Just "Cool Journal"
    , authors = Just "Folks et al."
    , year = Just 1970
    , issn = Just ""
    , isOpenAccess = Just True
    , oaPathway = Nothing
    , oaPathwayURI = Nothing
    , recommendedPathway = Nothing
    }


freePathwayPaper1 : FreePathwayPaper
freePathwayPaper1 =
    { doi = "10.123/1010-4321"
    , title = Just "Paywalled pub with the best title"
    , journal = Just "Paywall Inc."
    , authors = Just "Ronald Snape et al."
    , year = Just 1990
    , issn = Just "1234-1234"
    , oaPathwayURI = "#"
    , recommendedPathway =
        ( { profileUrl = "#"
          , additionalUrls =
                Just
                    [ { description = "Copyright & Details"
                      , url = "#"
                      }
                    , { description = "Why not to open access"
                      , url = "#"
                      }
                    ]
          , notes = Just "Policy notes are awesome"
          }
        , { articleVersions = [ "submitted", "accepted" ]
          , locations = [ "Author's homepage", "Preprint Server" ]
          , prerequisites = Just [ "Prerequisite to take care of", "Another prerequisite" ]
          , conditions = Just [ "Condition one", "Second condition", "Third condition" ]
          , embargo = Just "Wait for the day of doom and then two days more"
          , notes = Just [ "pathway note 1", "pathway note 2" ]
          }
        )
    , pathwayVisible = True
    }


freePathwayPaper2 : FreePathwayPaper
freePathwayPaper2 =
    { doi = "10.123/1010-4321"
    , title = Just "Hidden pub with the best title"
    , journal = Just "Paywall Inc."
    , authors = Just "Ronald Snape et al."
    , year = Just 1990
    , issn = Just "1234-1234"
    , oaPathwayURI = "#"
    , recommendedPathway =
        ( { profileUrl = "#"
          , additionalUrls =
                Just
                    [ { description = "Copyright & Details"
                      , url = "#"
                      }
                    , { description = "Why not to open access"
                      , url = "#"
                      }
                    ]
          , notes = Just "Policy notes are awesome"
          }
        , { articleVersions = [ "submitted", "accepted" ]
          , locations = [ "Author's homepage", "Preprint Server" ]
          , prerequisites = Just [ "Prerequisite to take care of", "Another prerequisite" ]
          , conditions = Just [ "Condition one", "Second condition", "Third condition" ]
          , embargo = Just "Wait for the day of doom and then two days more"
          , notes = Just [ "pathway note 1", "pathway note 2" ]
          }
        )
    , pathwayVisible = True
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { initialDOIs = []
      , freePathwayPapers =
            Array.fromList
                [ freePathwayPaper1
                , freePathwayPaper2
                ]
      , otherPathwayPapers = []
      , openAccessPapers =
            [ oaPaper1
            ]
      , buggyPapers = []
      , numFailedDOIRequests = 0
      , authorName = "Dummy Author"
      , authorProfileURL = "https://freeyourscience.org"
      , serverURL = ""
      , style = Animation.style []
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )
