module Views exposing (..)

import Browser.Events exposing (Visibility(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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


renderOpenAccessPaper : Paper -> Html Msg
renderOpenAccessPaper paper =
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
            [ renderPaperHeader paper ]
        ]


renderFreePathwayPaper : ( Int, FreePathwayPaper ) -> Html Msg
renderFreePathwayPaper ( id, { pathwayVisible, recommendedPathway } as paper ) =
    let
        pathwayClass =
            if pathwayVisible then
                ""

            else
                "d-none"
    in
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            [ div []
                (renderNarrowPaperHeader paper)
            , div [ class pathwayClass ]
                (renderRecommendedPathway paper.oaPathwayURI recommendedPathway)
            ]
        , div [ class "col-12 col-md-3 fs-6 text-md-end" ]
            (renderPathwayButtons pathwayVisible ( id, paper.title ))
        ]


renderNonFreePathwayPaper : OtherPathwayPaper -> Html Msg
renderNonFreePathwayPaper paper =
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            (renderNarrowPaperHeader paper)
        ]


type alias PaperMeta a =
    { a
        | doi : DOI
        , title : Maybe String
        , authors : Maybe String
        , year : Maybe Int
        , journal : Maybe String
    }


renderNarrowPaperHeader : PaperMeta a -> List (Html Msg)
renderNarrowPaperHeader { title, journal, authors, year, doi } =
    [ div [ class "fs-5 mb-1" ] [ text (Maybe.withDefault "Unknown title" title) ]
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
                , Html.Attributes.title ("Visit article: " ++ Maybe.withDefault "" title)
                ]
                []
            ]
        ]
    ]


renderPaperHeader : Paper -> Html Msg
renderPaperHeader ({ journal, authors, year, doi } as paper) =
    let
        paperTitle =
            paper.title

        isOpenAccess =
            Maybe.withDefault False paper.isOpenAccess
    in
    div
        [ class
            ("paper-details col-12 fs-6 mb-2 mb-md-0"
                ++ (if isOpenAccess then
                        ""

                    else
                        " col-md-9"
                   )
            )
        ]
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


renderPathwayButtons : Bool -> ( Int, Maybe String ) -> List (Html Msg)
renderPathwayButtons pathwayIsVisible ( id, title ) =
    let
        paperTitle =
            Maybe.withDefault "Unknown title" title

        verb =
            if pathwayIsVisible then
                "Hide"

            else
                "Show"

        style =
            if pathwayIsVisible then
                "btn btn-light"

            else
                "btn btn-success"
    in
    [ div []
        [ button
            [ onClick (TogglePathwayDisplay id)
            , class style
            , Html.Attributes.title (verb ++ "Open Access pathway for: " ++ paperTitle)
            ]
            [ text (verb ++ " Open Access pathway")
            ]
        ]
    ]


renderRecommendedPathway : String -> ( PolicyMetaData, NoCostOaPathway ) -> List (Html Msg)
renderRecommendedPathway journalPolicyUrl ( policy, { locationLabelsSorted, articleVersions, prerequisites, conditions, embargo, notes } ) =
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

        articleVersion =
            articleVersions
                |> List.filter (\v -> v == "published")
                |> List.head
                |> Maybe.withDefault (String.join " or " articleVersions)
    in
    List.concat
        [ [ p [] [ text "The publisher has a policy that lets you:" ] ]
        , locationLabelsSorted
            |> List.take 3
            |> ulWithHeading ("upload the " ++ articleVersion ++ " version to any of the following:") text
        , [ p [] [ text " You don't have pay a fee to do this." ] ]
        , prerequisites
            |> addEmbargo embargo
            |> Maybe.map (ulWithHeading "But only:" text)
            |> Maybe.withDefault [ text "" ]
        , conditions
            |> Maybe.map (ulWithHeading "Conditions are:" text)
            |> Maybe.withDefault [ text "" ]
        , notes
            |> Maybe.map (ulWithHeading "Notes regarding this pathway:" text)
            |> Maybe.withDefault [ text "" ]
        , policy.additionalUrls
            |> Maybe.map (ulWithHeading "The publisher has provided the following links to further information:" renderUrl)
            |> Maybe.withDefault [ text "" ]
        , [ p []
                [ policy.notes
                    |> Maybe.map (String.append "Regarding the policy they note: ")
                    |> Maybe.withDefault ""
                    |> text
                ]
          ]
        , [ p []
                [ text "More information about this and other Open Access policies for this publication can be found in the "
                , a [ href journalPolicyUrl, class "link", class "link-secondary" ] [ text "Sherpa Policy Database" ]
                ]
          ]
        ]



-- PAPER SECTIONS


renderPaywalledNoCostPathwayPapers : List ( Int, FreePathwayPaper ) -> Html Msg
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
        , div [] (List.map renderFreePathwayPaper papers)
        ]


renderNonFreePolicyPapers : List OtherPathwayPaper -> Html Msg
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
            , div [] (List.map renderNonFreePathwayPaper papers)
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
            div [] (List.map renderOpenAccessPaper papers)
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
