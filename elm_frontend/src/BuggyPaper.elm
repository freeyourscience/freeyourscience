module BuggyPaper exposing (BuggyPaper)

import GeneralTypes exposing (DOI)



-- TYPES


type alias BuggyPaper =
    { doi : DOI
    , journal : Maybe String
    , oaPathway : Maybe String
    }
