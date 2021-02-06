module HtmlUtils exposing (renderList, ulWithHeading)

import Html exposing (Html, li, p, text, ul)
import Html.Attributes exposing (class)


ulWithHeading : String -> (a -> Html msg) -> List a -> List (Html msg)
ulWithHeading heading renderElement list =
    let
        renderedList =
            list
                |> List.map renderElement
                |> renderList
    in
    [ p [ class "mb-0" ] [ text heading ]
    , renderedList
    ]


renderList : List (Html msg) -> Html msg
renderList list =
    ul []
        (List.map
            (\item -> li [] [ item ])
            list
        )
