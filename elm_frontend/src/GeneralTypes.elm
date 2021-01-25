module GeneralTypes exposing (DOI, NamedUrl)


type alias DOI =
    String


type alias NamedUrl =
    { description : String
    , url : String
    }
