module Papers.Buggy exposing (Paper, viewList)

import Html exposing (Html, div, h3, p, section, text)
import Html.Attributes exposing (style)
import Papers.Utils exposing (PaperMetadata, renderPaperMetaData)


type alias Paper =
    { meta : PaperMetadata
    , oaPathway : Maybe String
    }


renderPaperMetaDataWithIssues : PaperMetadata -> List (Html msg)
renderPaperMetaDataWithIssues metaData =
    let
        issueStyle =
            [ style "margin-top" "0.5rem" ]
    in
    renderPaperMetaData div True metaData
        ++ [ case ( metaData.issn, metaData.journal ) of
                ( Nothing, Nothing ) ->
                    p issueStyle
                        [ text "↯ Could not find the venue's ISSN and thus no open access policies."
                        ]

                ( Just issn, Just journal ) ->
                    p issueStyle
                        [ text ("↯ Could not find open access policies for \"" ++ journal ++ "\" (ISSN: " ++ issn ++ ")")
                        ]

                ( Just issn, Nothing ) ->
                    p issueStyle
                        [ text ("↯ Could not find open access policies for ISSN: " ++ issn)
                        ]

                ( Nothing, Just journal ) ->
                    p issueStyle
                        [ text ("↯ Could not find the ISSN for \"" ++ journal ++ "\" and thus no open access policies.")
                        ]
           ]


viewList : List Paper -> Html msg
viewList papers =
    if List.isEmpty papers then
        text ""

    else
        section []
            (h3 [] [ text "Publications with insufficient information" ]
                :: List.concat
                    (papers |> List.map (\paper -> renderPaperMetaDataWithIssues paper.meta))
            )
