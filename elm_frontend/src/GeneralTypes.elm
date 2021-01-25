module GeneralTypes exposing (DOI, NamedUrl, PaperMetadata, renderUrl)

import Html exposing (Html, a, text)
import Html.Attributes exposing (class, href)


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


renderUrl : NamedUrl -> Html msg
renderUrl { url, description } =
    a [ href url, class "link", class "link-secondary" ] [ text description ]
