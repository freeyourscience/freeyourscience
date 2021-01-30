module Papers.OtherPathway exposing (OtherPathwayPaper, view, viewList)

import Html exposing (Html, div, h2, p, section, text)
import Html.Attributes exposing (class)
import Papers.Utils exposing (PaperMetadata, renderPaperMetaData)



-- TYPES


type alias OtherPathwayPaper =
    { meta : PaperMetadata
    , oaPathwayURI : String
    }


view : OtherPathwayPaper -> Html msg
view paper =
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            (renderPaperMetaData paper.meta)
        ]


viewList : List OtherPathwayPaper -> Html msg
viewList papers =
    if List.isEmpty papers then
        text ""

    else
        section [ class "mb-5" ]
            [ h2 []
                [ text "Publications with non-free publisher policies"
                ]
            , p [ class "fs-6 mb-4" ]
                [ text
                    ("The following publications do not seem to have any no-cost Open Access "
                        ++ "re-publishing pathways, or do not allow Open Access publishing at all."
                    )
                ]
            , div [] (List.map view papers)
            ]
