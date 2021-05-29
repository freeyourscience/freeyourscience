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
    div [ class "publications__item" ]
        [ div [ class "publications__item__info" ]
            (renderPaperMetaData div True paper.meta)
        ]


viewList : List Paper -> Html msg
viewList papers =
    if List.isEmpty papers then
        text ""

    else
        section []
            [ h3 []
                [ text "Publications with non-free publisher policies"
                ]
            , p []
                [ text
                    ("The following publications do not seem to have any no-cost open access "
                        ++ "re-publishing pathways, or do not allow open access publishing at all."
                    )
                ]
            , div [] (List.map view papers)
            ]
