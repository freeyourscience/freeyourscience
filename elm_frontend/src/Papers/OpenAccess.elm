module Papers.OpenAccess exposing (Paper, view, viewList)

import Html exposing (Html, a, br, div, h3, p, section, text)
import Html.Attributes exposing (class, href, target)
import Papers.Utils exposing (DOI, renderPaperMetaData)


type alias Paper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , oaLocationURL : String
    }


view : Paper -> Html msg
view paper =
    div [ class "publications__item" ]
        [ div [ class "publications__item__info" ]
            (renderPaperMetaData div
                False
                False
                { title = paper.title
                , journal = paper.journal
                , authors = paper.authors
                , year = paper.year
                , doi = paper.doi
                , issn = paper.issn
                , url = Just paper.oaLocationURL
                }
            )
        ]


viewList : List Paper -> Html msg
viewList papers =
    section [ class "mb-5" ]
        [ h3 [ class "mb-3" ]
            [ text "Open access publications"
            ]
        , p [] [ text "Open access versions of these publications have been successfully indexed by Unpaywall.org" ]
        , if List.isEmpty papers then
            p []
                [ text "We could not find any of your open access publications in the unpaywall.org database."
                , br [] []
                , text "In case you think there should be open access publications here, help "
                , a [ href "https://unpaywall.org/sources", target "_blank" ] [ text "unpaywall.org" ]
                , text " to find them."
                ]

          else
            div [] (List.map view papers)
        ]
