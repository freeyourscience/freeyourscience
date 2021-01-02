module Types exposing (..)

import Animation
import Http
import Json.Encode exposing (int)


type alias Flags =
    { dois : List String
    , serverURL : String
    , authorName : String
    , authorProfileURL : String
    }


type alias DOI =
    String


type alias Paper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , isOpenAccess : Maybe Bool
    , oaPathway : Maybe String
    , oaPathwayURI : Maybe String
    }


type Msg
    = GotPaper (Result Http.Error Paper)
    | Animate Animation.Msg
