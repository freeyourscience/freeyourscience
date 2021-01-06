module Views exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Types exposing (..)


renderLoadingSpinner : Html Msg
renderLoadingSpinner =
    div [ class "spinner-border text-primary fs-5 m-2", attribute "role" "status" ]
        [ span [ class "visually-hidden" ] [ text "Loading..." ]
        ]


renderPaper : Paper -> Html Msg
renderPaper paper =
    let
        paperTitle =
            Maybe.withDefault "Unknown Title" paper.title

        journal =
            Maybe.withDefault "Unknown Venue" paper.journal

        authors =
            Maybe.withDefault "Unknown Authors" paper.authors

        year =
            Maybe.withDefault 0 paper.year

        isOpenAccess =
            Maybe.withDefault False paper.isOpenAccess

        oaPathwayURI =
            Maybe.withDefault "#" paper.oaPathwayURI
    in
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class
                ("paper-details col-12 fs-6 mb-2 mb-md-0"
                    ++ (if isOpenAccess then
                            ""

                        else
                            " col-md-9"
                       )
                )
            ]
            [ div [ class "fs-5 mb-1" ]
                [ text paperTitle
                ]
            , text (journal ++ ", " ++ authors ++ " (" ++ String.fromInt year ++ "), " ++ paper.doi ++ " ")
            , a [ href ("https://doi.org/" ++ paper.doi), class "link-secondary", target "_blank" ]
                [ img
                    [ src "/static/img/box-arrow-up-right.svg"
                    , alt ""
                    , width 12
                    , height 12
                    , title ("Visit article: " ++ paperTitle)
                    ]
                    []
                ]
            , case paper.recommendedPathway of
                Just recommendedPathway ->
                    div []
                        [ p [] [ text "The publisher has a policy that lets you:" ]
                        , p [] [ text ("upload the " ++ recommendedPathway.articleVersion ++ " version to any of the following:") ]
                        , ul []
                            (List.map (\l -> li [] [ text l ]) recommendedPathway.locations)
                        , p [] [ text " You don't have pay a fee to do this." ]
                        , p [] [ text "But only:" ]
                        , ul []
                            (List.map (\l -> li [] [ text l ]) recommendedPathway.prerequisites)
                        , p [] [ text "Conditions are:" ]
                        , ul []
                            (List.map (\l -> li [] [ text l ]) recommendedPathway.conditions)
                        , p [] [ text "The publisher also notes:" ]
                        , ul []
                            (List.map (\l -> li [] [ text l ]) recommendedPathway.notes)
                        , p [] [ text "The publisher has provided the following links to further information:" ]
                        , Maybe.map
                            (\urls ->
                                ul []
                                    (List.map (\url -> li [] [ a [ href url.url, class "link", class "link-secondary" ] [ text url.description ] ])
                                        urls
                                    )
                            )
                            recommendedPathway.urls
                            |> Maybe.withDefault (text "")
                        , p []
                            [ text "The publisher has deposited this policy at "
                            , a [ href recommendedPathway.policyUrl, class "link", class "link-secondary" ] [ text "Sherpa" ]
                            ]
                        ]

                _ ->
                    text ""
            ]
        , if not isOpenAccess then
            div [ class "col-12 col-md-3 fs-6 text-md-end" ]
                [ div []
                    [ a
                        [ href oaPathwayURI
                        , target "_blank"
                        , class "btn btn-success text-decoration-none"
                        , title ("View Open Access pathways for: " ++ journal)
                        ]
                        [ text "View Open Access pathways"
                        ]
                    , br [] []
                    , a
                        [ href "#"
                        , class "link-secondary text-decoration-none link-oa-incorrect"
                        , title ("Is there an Open Access version for: " ++ paperTitle)
                        ]
                        [ text "Already Open Access?"
                        ]
                    ]
                ]

          else
            text ""
        ]


renderPaywalledNoCostPathwayPapers : List Paper -> Html Msg
renderPaywalledNoCostPathwayPapers papers =
    section [ class "mb-5" ]
        [ h2 []
            [ text "Unnecessarily paywalled publications"
            ]
        , p [ class "fs-6 mb-4" ]
            [ text
                ("We found no Open Access version for the following publications. "
                    ++ "However, the publishers likely allow no-cost re-publication as Open Access."
                )
            ]
        , div [] (List.map renderPaper papers)
        ]


renderNonFreePolicyPapers : List Paper -> Html Msg
renderNonFreePolicyPapers papers =
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
            , div [] (List.map renderPaper papers)
            ]


renderOpenAccessPapers : List Paper -> Html Msg
renderOpenAccessPapers papers =
    section [ class "mb-5" ]
        [ h2 [ class "mb-3" ]
            [ text "Open Access publications"
            ]
        , if List.isEmpty papers then
            p []
                [ text "We could not find any of your Open Access publications in the unpaywall.org database."
                , br [] []
                , text "In case you think there should be Open Access publications here, help "
                , a [ href "https://unpaywall.org/sources", target "_blank" ] [ text "unpaywall.org" ]
                , text " to find them."
                ]

          else
            div [] (List.map renderPaper papers)
        ]


renderBuggyPapers : List Paper -> Html Msg
renderBuggyPapers papers =
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
                            [ a [ href ("https://doi.org" ++ p.doi), target "_blank", class "link-secondary" ]
                                [ text p.doi
                                ]
                            , case p.oaPathway of
                                Just oaPathway ->
                                    text (" (unknown publisher policy for: " ++ Maybe.withDefault "Unknown Journal" p.journal ++ ")")

                                _ ->
                                    text ""
                            ]
                    )
                    papers
                )
            ]


renderFooter : String -> Html Msg
renderFooter authorProfileURL =
    footer [ class "container text-center m-4" ]
        [ small []
            [ text "("
            , a [ href authorProfileURL, target "_blank", class "link-dark" ]
                [ text "Source Profile"
                ]
            , text " that was used to retreive the author's papers.)"
            ]
        ]
