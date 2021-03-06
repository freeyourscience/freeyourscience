module HtmlUtils exposing (addEmbargo, renderList, ulWithHeading, viewSearchForm, viewSearchNoteWithLinks)

import Html exposing (Html, a, button, div, form, input, li, p, small, span, text, ul)
import Html.Attributes exposing (action, attribute, class, href, id, method, name, placeholder, target, type_, value)


ulWithHeading : List (Html msg) -> (a -> Html msg) -> List a -> List (Html msg)
ulWithHeading heading renderElement list =
    let
        renderedList =
            list
                |> List.map renderElement
                |> renderList
    in
    [ p [ class "mb-0" ] heading
    , renderedList
    ]


renderList : List (Html msg) -> Html msg
renderList list =
    ul []
        (List.map
            (\item -> li [] [ item ])
            list
        )


viewSearchForm : String -> Html msg -> List (Html.Attribute msg) -> Html msg
viewSearchForm searchString searchNote progressStyle =
    form [ action "/search", class "search", id "search-form", method "GET" ]
        [ input [ class "search__input", name "query", placeholder "Author name, ORCID or DOI", attribute "required" "", type_ "text", value searchString ]
            []
        , button [ class "search__button", type_ "submit" ]
            [ text "Search" ]
        , div [ class "search__progressbar__container" ]
            [ div (progressStyle ++ [ class "search__progressbar__progress" ])
                []
            ]
        , small [ class "search__small" ] [ searchNote ]
        ]


viewSearchNoteWithLinks : String -> Html msg
viewSearchNoteWithLinks searchQuery =
    span []
        [ text "If you can't find your publications using your name try your "
        , a [ href ("https://orcid.org/orcid-search/search?searchQuery=" ++ searchQuery), target "_blank" ]
            [ text "ORCID" ]
        , text ", "
        , a [ href ("https://www.semanticscholar.org/search?q=" ++ searchQuery ++ "&sort=relevance"), target "_blank" ]
            [ text "Semantic Scholar ID" ]
        , text " or an individual DOI"
        ]


addEmbargo : Maybe String -> Maybe (List String) -> Maybe (List String)
addEmbargo embargo targetList =
    case ( embargo, targetList ) of
        ( Just e, Just l ) ->
            Just (List.append [ e ++ " have passed since publication" ] l)

        ( Just e, Nothing ) ->
            Just [ e ++ " have passed since publication" ]

        ( Nothing, Just l ) ->
            Just l

        _ ->
            Nothing
