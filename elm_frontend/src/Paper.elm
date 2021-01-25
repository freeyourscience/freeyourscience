module Paper exposing (OtherPathwayPaper, Paper, toPaper)

import BackendPaper exposing (BackendPaper)
import FreePathwayPaper exposing (NoCostOaPathway, PolicyMetaData, recommendPathway)
import GeneralTypes exposing (DOI, PaperMetadata)



-- TYPES


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


type alias OtherPathwayPaper =
    { meta : PaperMetadata
    , oaPathwayURI : String
    }



-- CONSTRUCTOR


toPaper : BackendPaper -> Paper
toPaper backendPaper =
    { doi = backendPaper.doi
    , title = backendPaper.title
    , journal = backendPaper.journal
    , authors = backendPaper.authors
    , year = backendPaper.year
    , issn = backendPaper.issn
    , isOpenAccess = backendPaper.isOpenAccess
    , oaPathway = backendPaper.oaPathway
    , oaPathwayURI = backendPaper.oaPathwayURI
    , recommendedPathway = Maybe.andThen recommendPathway backendPaper.pathwayDetails
    }
