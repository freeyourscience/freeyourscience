module Papers.Utils exposing (DOI, NamedUrl, PaperMetadata, renderPaperMetaData, renderUrl)

import Html exposing (Html, a, div, span, text)
import Html.Attributes exposing (class, href, target)


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
    a [ href url ] [ text description ]


renderPaperMetaData : PaperMetadata -> List (Html msg)
renderPaperMetaData { title, journal, authors, year, doi } =
    [ div [ class "publications__item__info__title" ]
        [ text (Maybe.withDefault "Unknown title" title)
        ]
    , div [ class "" ]
        [ span [ class "publications__item__info__journal" ]
            [ journal |> Maybe.withDefault "Unknown journal" |> text
            ]
        , text
            (String.concat
                [ " | "
                , authors |> Maybe.withDefault "Unknown authors"
                , " ("
                , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                , ") | "
                ]
            )
        , span [ class "publications__item__info__doi" ] [ text doi ]
        , a [ href ("https://doi.org/" ++ doi), target "_blank" ]
            [ text " ↗️"
            ]
        ]
    ]
