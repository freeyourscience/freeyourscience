module Papers.Utils exposing (DOI, NamedUrl, PaperMetadata, renderPaperMetaData, renderUrl)

import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (alt, class, height, href, src, target, width)


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


renderPaperMetaData : PaperMetadata -> List (Html msg)
renderPaperMetaData { title, journal, authors, year, doi } =
    [ div [ class "fs-5 mb-1" ] [ text (Maybe.withDefault "Unknown title" title) ]
    , div [ class "mb-1" ]
        [ text
            (String.concat
                [ journal |> Maybe.withDefault "Unknown journal"
                , ", "
                , authors |> Maybe.withDefault "Unknown authors"
                , " ("
                , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                , "), "
                , doi
                ]
            )
        , a [ href ("https://doi.org/" ++ doi), class "link-secondary", target "_blank" ]
            [ img
                [ src "/static/img/box-arrow-up-right.svg"
                , alt ""
                , width 12
                , height 12
                , Html.Attributes.title ("Visit article: " ++ Maybe.withDefault "" title)
                ]
                []
            ]
        ]
    ]
