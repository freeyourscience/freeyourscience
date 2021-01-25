module OpenAccessPaper exposing (OpenAccessPaper)

import GeneralTypes exposing (DOI)



-- TYPES


type alias OpenAccessPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    }
