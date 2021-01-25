module BuggyPaper exposing (BuggyPaper, viewList)

import GeneralTypes exposing (DOI)
import Html exposing (Html, a, div, h2, section, text)
import Html.Attributes exposing (class, href, target)



-- MODEL


type alias BuggyPaper =
    { doi : DOI
    , journal : Maybe String
    , oaPathway : Maybe String
    }



-- VIEW


viewList : List BuggyPaper -> Html msg
viewList papers =
    if List.isEmpty papers then
        text ""

    else
        section [ class "mb-5" ]
            [ h2 []
                [ text "Publications we had issues with"
                ]
            , div [ class "container" ]
                (List.map
                    (\p ->
                        div []
                            [ a [ href ("https://doi.org/" ++ p.doi), target "_blank", class "link-secondary" ]
                                [ text p.doi
                                ]
                            , case p.oaPathway of
                                Just _ ->
                                    text (" (unknown publisher policy for: " ++ Maybe.withDefault "Unknown Journal" p.journal ++ ")")

                                _ ->
                                    text ""
                            ]
                    )
                    papers
                )
            ]
