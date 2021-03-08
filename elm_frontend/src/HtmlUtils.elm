module HtmlUtils exposing (renderList, ulWithHeading, viewSearchBar)

import Html exposing (Html, button, div, form, input, li, p, small, text, ul)
import Html.Attributes exposing (action, attribute, class, id, method, name, placeholder, type_, value)


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


viewSearchBar : String -> String -> List (Html.Attribute msg) -> Html msg
viewSearchBar searchString smallNote progressStyle =
    form [ action "/search", class "search", id "search-form", method "GET" ]
        [ input [ class "search__input", name "query", placeholder "Author name, ORCID or DOI", attribute "required" "", type_ "text", value searchString ]
            []
        , button [ class "search__button", type_ "submit" ]
            [ text "Search" ]
        , div [ class "search__progressbar__container" ]
            [ div (progressStyle ++ [ class "search__progressbar__progress" ])
                []
            ]
        , small [ class "search__small" ]
            [ text smallNote ]
        ]
