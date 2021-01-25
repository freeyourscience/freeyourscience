module HtmlUtils exposing (ulWithHeading)

import Html exposing (Html, li, p, text, ul)


ulWithHeading : String -> (a -> Html msg) -> List a -> List (Html msg)
ulWithHeading heading renderElement list =
    let
        renderedList =
            list
                |> List.map renderElement
                |> renderList
    in
    [ p [] [ text heading ]
    , renderedList
    ]


renderList : List (Html msg) -> Html msg
renderList list =
    ul []
        (List.map
            (\item -> li [] [ item ])
            list
        )
