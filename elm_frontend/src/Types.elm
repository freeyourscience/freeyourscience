module Types exposing (..)

import Animation
import Http



-- INPUT DATA


type alias Flags =
    { dois : List String
    , serverURL : String
    , authorName : String
    , authorProfileURL : String
    }



-- MODEL


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
    , recommendedPathway : Maybe ( PolicyMetaData, NoCostOaPathway )
    }


type alias OpenAccessPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , oaLocationURL : String
    }


type alias FreePathwayPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , oaPathwayURI : String
    , recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
    , pathwayVisible : Bool
    }


type alias OtherPathwayPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , oaPathwayURI : String
    }


type alias PolicyMetaData =
    { profileUrl : String
    , additionalUrls : Maybe (List NamedUrl)
    , notes : Maybe String
    }


type alias NoCostOaPathway =
    { articleVersions : List String
    , locations : List String
    , prerequisites : Maybe (List String)
    , conditions : Maybe (List String)
    , embargo : Maybe String
    }


type alias Pathway =
    { additionalOaFee : String
    , locations : Maybe (List String)
    , articleVersions : Maybe (List String)
    , conditions : Maybe (List String)
    , prerequisites : Maybe (List String)
    , embargo : Maybe String
    }



-- GENERAL PURPOSE


type alias DOI =
    String


type alias NamedUrl =
    { description : String
    , url : String
    }



-- BACKEND PAPER


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
    , pathwayDetails : Maybe (List BackendPolicy)
    , oaLocationURL : Maybe String
    }


type alias BackendPolicy =
    { urls : Maybe (List NamedUrl)
    , permittedOA : Maybe (List BackendPermittedOA)
    , policyUrl : String -- TODO: this should come from oaPathwayURI
    , notes : Maybe String
    }


type alias BackendPermittedOA =
    { additionalOaFee : String
    , location : BackendLocation
    , articleVersions : List String
    , conditions : Maybe (List String)
    , prerequisites : Maybe BackendPrerequisites
    , embargo : Maybe BackendEmbargo
    }


type alias BackendPrerequisites =
    { prerequisites : List String
    , prerequisites_phrases : List BackendPhrase
    }


type alias BackendPhrase =
    { value : String
    , phrase : String
    , language : String
    }


type alias BackendLocation =
    { location : List String
    , namedRepository : Maybe (List String)
    }


type alias BackendEmbargo =
    { amount : Int
    , units : String
    }



-- MSG


type Msg
    = GotPaper (Result Http.Error BackendPaper)
    | TogglePathwayDisplay Int
    | Animate Animation.Msg
