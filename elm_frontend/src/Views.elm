module Views exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Types exposing (..)


renderLoadingSpinner : Html Msg
renderLoadingSpinner =
    div [ class "spinner-border text-primary fs-5 m-2", attribute "role" "status" ]
        [ span [ class "visually-hidden" ] [ text "Loading..." ]
        ]


ulWithHeading : String -> (a -> Html Msg) -> List a -> List (Html Msg)
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


renderList : List (Html Msg) -> Html Msg
renderList list =
    ul []
        (List.map
            (\item -> li [] [ item ])
            list
        )


renderUrl : NamedUrl -> Html Msg
renderUrl { url, description } =
    a [ href url, class "link", class "link-secondary" ] [ text description ]



-- PAPER


renderPaper : Paper -> Html Msg
renderPaper paper =
    let
        isOpenAccess =
            Maybe.withDefault False paper.isOpenAccess
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
            [ div []
                (renderPaperHeader paper)
            , paper.recommendedPathway
                |> Maybe.map renderRecommendedPathway
                |> Maybe.withDefault (text "")
            ]
        , if not isOpenAccess then
            div [ class "col-12 col-md-3 fs-6 text-md-end" ]
                (renderPathwayButtons paper)

          else
            text ""
        ]


renderPaperHeader : Paper -> List (Html Msg)
renderPaperHeader ({ journal, authors, year, doi } as paper) =
    let
        paperTitle =
            paper.title
    in
    [ div [ class "fs-5 mb-1" ] [ text (Maybe.withDefault "Unknown title" paperTitle) ]
    , div [ class "mb-1" ]
        [ text
            (String.concat
                [ journal |> Maybe.withDefault "Unknown journal"
                , ", "
                , authors |> Maybe.withDefault "Unknown authors"
                , " ("
                , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                , "), "
                , doi
                ]
            )
        , a [ href ("https://doi.org/" ++ doi), class "link-secondary", target "_blank" ]
            [ img
                [ src "/static/img/box-arrow-up-right.svg"
                , alt ""
                , width 12
                , height 12
                , title ("Visit article: " ++ Maybe.withDefault "" paperTitle)
                ]
                []
            ]
        ]
    ]


renderPathwayButtons : Paper -> List (Html Msg)
renderPathwayButtons paper =
    let
        oaPathwayURI =
            Maybe.withDefault "#" paper.oaPathwayURI

        paperTitle =
            Maybe.withDefault "Unknown title" paper.title
    in
    [ div []
        [ a
            [ href oaPathwayURI
            , target "_blank"
            , class "btn btn-success text-decoration-none"
            , title ("View Open Access pathway for: " ++ paperTitle)
            ]
            [ text "View Open Access pathway"
            ]
        ]
    ]


renderRecommendedPathway : ( PolicyMetaData, NoCostOaPathway ) -> Html Msg
renderRecommendedPathway ( { profileUrl, additionalUrls, notes }, { locations, articleVersions, prerequisites, conditions, embargo } ) =
    let
        addEmbargo : Maybe String -> Maybe (List String) -> Maybe (List String)
        addEmbargo emb prereqs =
            case ( emb, prereqs ) of
                ( Just e, Just p ) ->
                    Just (List.append [ "If " ++ e ++ " have passed since publication" ] p)

                ( Just e, Nothing ) ->
                    Just [ "If " ++ e ++ " have passed since publication" ]

                ( Nothing, Just p ) ->
                    Just p

                _ ->
                    Nothing
    in
    div [ class "d-none" ]
        (List.concat
            [ [ p [] [ text "The publisher has a policy that lets you:" ] ]
            , locations
                |> ulWithHeading ("upload the " ++ String.join " or " articleVersions ++ " version to any of the following:") text
            , [ p [] [ text " You don't have pay a fee to do this." ] ]
            , prerequisites
                |> addEmbargo embargo
                |> Maybe.map (ulWithHeading "But only:" text)
                |> Maybe.withDefault [ text "" ]
            , conditions
                |> Maybe.map (ulWithHeading "Conditions are:" text)
                |> Maybe.withDefault [ text "" ]
            , additionalUrls
                |> Maybe.map (ulWithHeading "The publisher has provided the following links to further information:" renderUrl)
                |> Maybe.withDefault [ text "" ]
            , [ p []
                    [ text "The publisher has deposited this policy at "
                    , a [ href profileUrl, class "link", class "link-secondary" ] [ text "Sherpa" ]
                    , notes
                        |> Maybe.map (String.append "They also note: ")
                        |> Maybe.withDefault ""
                        |> text
                    ]
              ]
            ]
        )



-- PAPER SECTIONS


renderPaywalledNoCostPathwayPapers : List ( Int, Paper ) -> Html Msg
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
        , div [] (List.map renderPaper (List.map Tuple.second papers))
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
                                Just _ ->
                                    text (" (unknown publisher policy for: " ++ Maybe.withDefault "Unknown Journal" p.journal ++ ")")

                                _ ->
                                    text ""
                            ]
                    )
                    papers
                )
            ]



-- SOURCE PROFILE


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
