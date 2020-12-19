module Types exposing (..)

import Http
import Json.Encode exposing (int)


type alias Model =
    { unfetchedDOIs : List DOI
    , fetchedPapers : List Paper
    , authorName : String
    , authorProfileURL : String
    , serverURL : String
    }


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
