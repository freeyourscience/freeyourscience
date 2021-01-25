module GeneralTypes exposing (DOI, NamedUrl, PaperMetadata)


type alias DOI =
    String


type alias PaperMetadata =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    }


type alias NamedUrl =
    { description : String
    , url : String
    }
