module Paper exposing (BuggyPaper, OpenAccessPaper, OtherPathwayPaper)

import GeneralTypes exposing (DOI, PaperMetadata)



-- TYPES


type alias OpenAccessPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    }


type alias OtherPathwayPaper =
    { meta : PaperMetadata
    , oaPathwayURI : String
    }


type alias BuggyPaper =
    { doi : DOI
    , journal : Maybe String
    , oaPathway : Maybe String
    }
