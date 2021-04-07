module Papers.Utils exposing (DOI, NamedUrl, PaperMetadata, articleVersionString, renderPaperMetaData, renderUrl)

import Animation exposing (display)
import Html exposing (Attribute, Html, a, div, img, text)
import Html.Attributes exposing (class, href, src, target)


type alias DOI =
    String


type alias PaperMetadata =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , url : Maybe String
    }


type alias NamedUrl =
    { description : String
    , url : String
    }


articleVersionString : List String -> String
articleVersionString articleVersions =
    articleVersions
        |> List.filter (\v -> v == "published")
        |> List.head
        |> Maybe.withDefault (String.join " or " articleVersions)


renderUrl : NamedUrl -> Html msg
renderUrl { url, description } =
    a [ href url ] [ text description ]


renderPaperMetaData : (List (Attribute msg) -> List (Html msg) -> Html msg) -> Bool -> PaperMetadata -> List (Html msg)
renderPaperMetaData titleElement displayUnknownJournal { title, journal, authors, year, doi, url } =
    let
        journalString =
            case ( journal, displayUnknownJournal ) of
                ( Just j, _ ) ->
                    j ++ ", "

                ( Nothing, True ) ->
                    "Unknown journal, "

                ( Nothing, False ) ->
                    ""
    in
    [ titleElement [ class "publications__item__info__title" ]
        [ text (Maybe.withDefault "Unknown title" title)
        ]
    , div [ class "" ]
        [ text
            (String.concat
                [ journalString
                , authors |> Maybe.withDefault "Unknown authors"
                , " ("
                , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                , ")"
                ]
            )
        , a
            [ href (Maybe.withDefault ("https://doi.org/" ++ doi) url)
            , target "_blank"
            , Html.Attributes.title (Maybe.withDefault ("https://doi.org/" ++ doi) url)
            ]
            [ text " 🔗" ]
        ]
    ]
