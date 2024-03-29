module Papers.Utils exposing
    ( DOI
    , NamedUrl
    , PaperMetadata
    , articleVersionString
    , publisherNotes
    , renderPaperMetaData
    , renderPaperMetaDataWithDoi
    , renderUrl
    )

import Date exposing (Date)
import Html exposing (Attribute, Html, a, div, li, p, span, text, ul)
import Html.Attributes exposing (class, href, rel, target)
import HtmlUtils exposing (renderList, ulWithHeading)


type alias DOI =
    String


type alias PaperMetadata =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , publishedDate : Maybe Date
    , issn : Maybe String
    , url : Maybe String
    , recommendShareYourPaper : Bool
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


publisherNotes : Maybe (List String) -> Maybe (List String) -> List (Html msg)
publisherNotes notes prerequisites =
    case ( notes, prerequisites ) of
        ( Nothing, Nothing ) ->
            [ text "" ]

        ( Just nts, Nothing ) ->
            nts |> ulWithHeading [ text "The publisher notes:" ] text

        ( Nothing, Just pqs ) ->
            pqs |> ulWithHeading [ text "The publisher notes the following prerequisites:" ] text

        ( Just nts, Just pqs ) ->
            let
                notesList =
                    nts |> List.map text |> List.map (\l -> li [] [ l ])

                prerequisitesList =
                    [ li [] [ text "Prerequisites to consider:" ]
                    , pqs |> List.map text |> renderList
                    ]
            in
            [ p [ class "mb-0" ]
                [ text "The publisher notes:" ]
            , ul [] (notesList ++ prerequisitesList)
            ]


renderUrl : NamedUrl -> Html msg
renderUrl { url, description } =
    a [ href url ] [ text description ]


renderPaperMetaDataWithDoi : (List (Attribute msg) -> List (Html msg) -> Html msg) -> PaperMetadata -> List (Html msg)
renderPaperMetaDataWithDoi titleElement { title, journal, authors, year, doi, url } =
    let
        journalString =
            case journal of
                Just j ->
                    j ++ ", "

                Nothing ->
                    "Unknown journal, "
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
        , text (", " ++ doi ++ " ")
        , a
            [ href (Maybe.withDefault ("https://doi.org/" ++ doi) url)
            , target "_blank"
            , rel "noopener"
            , Html.Attributes.title (Maybe.withDefault ("https://doi.org/" ++ doi) url)
            ]
            [ span [ class "material-icons" ] [ text "launch" ]
            ]
        ]
    ]



-- TODO turn into div of spans, the content of spans contructed outside of renderer


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
    , div [ class "publications__item__info__metadata" ]
        [ text
            (String.concat
                [ journalString
                , authors |> Maybe.withDefault "Unknown authors"
                , " ("
                , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                , ") "
                ]
            )
        , a
            [ href (Maybe.withDefault ("https://doi.org/" ++ doi) url)
            , target "_blank"
            , rel "noopener"
            , Html.Attributes.title (Maybe.withDefault ("https://doi.org/" ++ doi) url)
            ]
            [ span [ class "material-icons" ] [ text "launch" ]
            ]
        ]
    ]
