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
    , recommendedPathway : Maybe Pathway
    }


type alias BackendPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , isOpenAccess : Maybe Bool
    , oaPathway : Maybe String
    , oaPathwayURI : Maybe String
    , pathwayDetails : Maybe (List PathwayDetails)
    }


type alias NamedUrl =
    { description : String
    , url : String
    }


type alias Pathway =
    { articleVersion : String
    , locations : List String
    , prerequisites : List String
    , conditions : List String
    , notes : List String
    , urls : List NamedUrl
    , policyUrl : String
    }


type alias PathwayDetails =
    { urls : Maybe (List NamedUrl)
    , permittedOA : Maybe (List PermittedOA)
    }


type alias PermittedOA =
    { additionalOaFee : String
    , location : Location
    , articleVersion : List String
    , conditions : List String
    }


type alias Location =
    { location : List String
    , namedRepository : Maybe (List String)
    }


type Msg
    = GotPaper (Result Http.Error BackendPaper)
    | Animate Animation.Msg
