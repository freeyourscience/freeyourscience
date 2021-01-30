module Papers.OpenAccess exposing (Paper, view, viewList)

import Html exposing (Html, a, br, div, h2, img, p, section, text)
import Html.Attributes exposing (alt, class, height, href, src, target, title, width)
import Papers.Utils exposing (DOI)


type alias Paper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    }


view : Paper -> Html msg
view paper =
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            [ renderPaperHeader paper ]
        ]


viewList : List Paper -> Html msg
viewList papers =
    section [ class "mb-5" ]
        [ h2 [ class "mb-3" ]
            [ text "Open Access publications"
            ]
        , if List.isEmpty papers then
            p []
                [ text "We could not find any of your Open Access publications in the unpaywall.org database."
                , br [] []
                , text "In case you think there should be Open Access publications here, help "
                , a [ href "https://unpaywall.org/sources", target "_blank" ] [ text "unpaywall.org" ]
                , text " to find them."
                ]

          else
            div [] (List.map view papers)
        ]


renderPaperHeader : Paper -> Html msg
renderPaperHeader ({ journal, authors, year, doi } as paper) =
    let
        paperTitle =
            paper.title
    in
    div
        [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
        [ div [ class "fs-5 mb-1" ] [ text (Maybe.withDefault "Unknown title" paperTitle) ]
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
                    , title ("Visit article: " ++ Maybe.withDefault "" paperTitle)
                    ]
                    []
                ]
            ]
        ]
