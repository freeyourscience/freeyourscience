module Papers.OtherPathway exposing (Paper, view, viewList)

import Html exposing (Html, div, h3, p, section, text)
import Html.Attributes exposing (class)
import Papers.Utils exposing (PaperMetadata, renderPaperMetaData)


type alias Paper =
    { meta : PaperMetadata
    , oaPathwayURI : String
    }


view : Paper -> Html msg
view paper =
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            (renderPaperMetaData div True paper.meta)
        ]


viewList : List Paper -> Html msg
viewList papers =
    if List.isEmpty papers then
        text ""

    else
        section [ class "mb-5" ]
            [ h3 []
                [ text "Publications with non-free publisher policies"
                ]
            , p [ class "fs-6 mb-4" ]
                [ text
                    ("The following publications do not seem to have any no-cost open access "
                        ++ "re-publishing pathways, or do not allow open access publishing at all."
                    )
                ]
            , div [] (List.map view papers)
            ]
