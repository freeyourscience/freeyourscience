port module Paper exposing (..)

import Browser
import Debug
import Html exposing (Html, a, article, dd, div, dl, dt, em, h1, h2, h3, li, main_, p, small, text, ul)
import Html.Attributes exposing (class, href, id, target)
import HtmlUtils exposing (ulWithHeading, viewSearchBar)
import Http
import HttpBuilder exposing (withHeader)
import Msg exposing (Msg)
import Papers.Backend as Backend
import Papers.FreePathway as FreePathway
import Papers.OpenAccess as OpenAccess
import Papers.OtherPathway as OtherPathway
import Papers.Utils exposing (DOI, articleVersionString, publisherNotes, renderPaperMetaData)


type SomePaper
    = FP FreePathway.Paper
    | OA OpenAccess.Paper
    | OP OtherPathway.Paper


type alias Model =
    { doi : DOI
    , serverURL : String
    , paper : Maybe SomePaper
    , error : Bool
    }


port title : String -> Cmd a



-- INIT


type alias Flags =
    { doi : String
    , serverURL : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { doi = flags.doi
      , serverURL = flags.serverURL
      , paper = Nothing
      , error = False
      }
    , fetchPaper flags.serverURL flags.doi
    )


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson Msg.GotPaper Backend.paperDecoder)
        |> HttpBuilder.request



-- VIEW


viewRightVersion : List String -> List (Html Msg)
viewRightVersion articleVersions =
    [ h3 [ id "version" ]
        [ text
            ("1. Find the "
                ++ articleVersionString articleVersions
                ++ " version of your manuscript"
            )
        ]
    , if List.member "published" articleVersions then
        p []
            [ text """For this publication you are allowed to re-publish
            the published version as open access for free.
            This version of the maniscript is the one published by e.g. a journal.
            It is usually a PDF file that has the journals logo
            and copyright notice on it and is typeset to the style
            of the journal."""
            ]

      else if List.member "accepted" articleVersions then
        p []
            [ text """For this publication you are allowed to re-publish
            the accepted version as open access for free.
            The accepted version is the final version of the manuscript
            sent by the author(s) to the publisher.
            This is the result of the peer review process and includes changes and
            corrections by the author(s), but not the copy-editing and typesetting
            done by the publisher.
            Content should be the same as the published version, but appearance
            might differ strongly."""
            ]

      else if List.member "submitted" articleVersions then
        p []
            [ text """For this publication you are allowed to re-publish the
            submitted version as open access for free.
            The submitted version is what was initially submitted for peer review.
            Content might differ strongly from the accepted version."""
            ]

      else
        p [] [ text "Unknown Version, please contact team@freeyourscience.org with the DOI." ]
    , p []
        [ text "The University of Cambridge Office of Scholarly Communication has a blog post with more in depth "
        , a [ href "https://unlockingresearch-blog.lib.cam.ac.uk/?p=1872" ]
            [ text "explanations of the different versions" ]
        , text ". "
        ]
    , small []
        [ text """We always display the pathway that allows the
        most mature version of the manuscript to be re-published.
        If you no longer have the version specified by the pathway
        you might also be allowed to re-publish an earlier one.
        Check the pathway details in the Sherpa Romeo policy database
        for what other versions are allowed. You will find a """
        , em []
            -- TODO: Link to policy
            [ text "Visit this policy" ]
        , text "link in the pathway result that takes you there. "
        ]
    ]


viewCheckConditions : Maybe (List String) -> Maybe (List String) -> Maybe (List String) -> List (Html Msg)
viewCheckConditions conditions notes prerequisites =
    [ h3 [ id "conditions" ]
        [ text "2. Check the conditions" ]
    , p []
        [ text """Before you re-publish you need to ensure that the following
        conditions are met. If there are none, you are good to go."""
        ]
    , ul []
        (List.map
            (\c -> li [] [ text c ])
            (Maybe.withDefault [] conditions)
        )
    ]
        ++ publisherNotes notes prerequisites


viewWhereTo : List String -> List (Html Msg)
viewWhereTo locationLabelsSorted =
    [ h3 [ id "where" ]
        [ text "3. Choose where to upload" ]
    , p []
        [ text """The pathway may allow you to upload your work in a variety of places.
        Our recommendation for choosing is:""" ]
    , ul []
        [ li []
            [ text "prefer public repositories over websites or social networks" ]
        , li []
            [ text "use places "
            , a [ href "https://unpaywall.org/sources" ]
                [ text "indexed by Unpaywall" ]
            ]
        , li []
            [ text "find suitable repositories with "
            , a [ href "https://v2.sherpa.ac.uk/opendoar/index.html" ]
                [ text "OpenDOAR" ]
            ]
        ]
    , p []
        [ text """A repository is very much like a digital library.
        Technically, it is any place where you can store digital assets
        that is usually indexed by search engines.
        This will ensure your work is easily findable and available to
        the widest possible audience.""" ]
    ]
        ++ (locationLabelsSorted
                |> List.take 3
                |> ulWithHeading
                    [ text "Available locations for this publication:"
                    ]
                    text
           )


viewRepublishTodayForFree : FreePathway.Paper -> Html Msg
viewRepublishTodayForFree paper =
    let
        ( _, pathway ) =
            paper.recommendedPathway
    in
    -- TODO: Add embargo
    article []
        (renderPaperMetaData
            div
            True
            paper.meta
            ++ viewRightVersion pathway.articleVersions
            ++ viewCheckConditions pathway.conditions pathway.notes pathway.prerequisites
            ++ viewWhereTo pathway.locationLabelsSorted
            ++ [ -- CO-AUTHORS
                 h3 [ id "coauthors" ]
                    [ text "4. Check with your co-authors" ]
               , p []
                    [ text """We'd suggest you only re-publish with the
                    consent of your co-authors.
                    That being said, copyright and co-authorship can be a
                    complex topic and we are in no position to provide legal
                    advice.""" ]

               -- UPLOAD
               , h3 [ id "upload" ]
                    [ text "5. Upload to selected repository" ]
               , p []
                    [ text """This step will be specific to your choosen repository.
                    If you have trouble with this step, your institution's librarians
                    are likely able to help you.""" ]

               -- LINK BACK
               , h3 [ id "linkback" ]
                    [ text "6. Link back to the initial publication" ]
               , p []
                    [ text """Most publisher's policies require that the re-published
                    version links back to the initial, paywalled publication.
                    If this is the case, make sure to follow their guidelines.
                    This also helps your readers cite the appropriate publication.""" ]
               , p []
                    [ text """This might mean adding a note like "Published in Dragon
                    Paywall Journal 10.200/123.123" when uploading to the repository.""" ]
               , p []
                    [ text "The exact method might be specified by the repository (e.g. "
                    , a [ href "https://arxiv.org/help/jref" ]
                        [ text "arXiv specific guide" ]
                    , text """). The publisher policy might also require the note to
                    follow a certain pattern."""
                    ]
               ]
        )


view : Model -> Html Msg
view model =
    let
        searchBar =
            viewSearchBar model.doi
                "If you can't find your publications using your name try your ORCID, Semantic Scholar ID or an individual DOI"
                []
    in
    case model.paper of
        Just (FP paper) ->
            main_ [ class "paper", class "freepathway" ]
                [ h1 [] [ text "Re-publish open access today for free" ]
                , paper |> viewRepublishTodayForFree
                ]

        Just (OP paper) ->
            main_ [ class "paper", class "otherpathway" ]
                [ h1 [] [ text "Result" ]
                , text ("OP" ++ Maybe.withDefault "" paper.meta.title)
                , p [ class "pathway-status" ]
                    [ text
                        ("This publications seems to be paywalled but the publisher "
                            ++ "policy does not allow free open access re-publication."
                        )
                    ]
                , searchBar
                ]

        Just (OA paper) ->
            main_ [ class "paper", class "openaccess" ]
                [ h1 [] [ text "Result" ]
                , div [ class "publications__item__info" ]
                    (Papers.Utils.renderPaperMetaData div
                        False
                        { title = paper.title
                        , journal = paper.journal
                        , authors = paper.authors
                        , year = paper.year
                        , doi = paper.doi
                        , issn = paper.issn
                        , url = Just paper.oaLocationURL
                        }
                    )
                , p [ class "pathway-status" ]
                    [ text "This publication is already "
                    , a [ href paper.oaLocationURL, target "_blank" ] [ text "open access" ]
                    , text " 🎉"
                    ]
                , searchBar
                ]

        Nothing ->
            main_ [ class "paper" ]
                [ h1 []
                    [ if model.error then
                        text "Not found"

                      else
                        text "Loading..."
                    ]
                , searchBar
                ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.GotPaper (Ok backendPaper) ->
            let
                modelWithClassifiedPaper =
                    model |> classifyPaper backendPaper
            in
            case modelWithClassifiedPaper.paper of
                Just (FP _) ->
                    ( modelWithClassifiedPaper
                    , title "Free Your Science | Re-publish open access today"
                    )

                _ ->
                    ( modelWithClassifiedPaper
                    , title "Free Your Science"
                    )

        Msg.GotPaper (Err error) ->
            let
                _ =
                    Debug.log "Error in GotPaper" error
            in
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


classifyPaper : Backend.Paper -> Model -> Model
classifyPaper backendPaper model =
    let
        isOpenAccess =
            backendPaper.isOpenAccess

        pathwayUri =
            backendPaper.oaPathwayURI

        meta =
            { doi = backendPaper.doi
            , title = backendPaper.title
            , journal = backendPaper.journal
            , authors = backendPaper.authors
            , year = backendPaper.year
            , issn = backendPaper.issn
            , url = Nothing
            }

        recommendedPathway =
            Maybe.andThen FreePathway.recommendPathway backendPaper.pathwayDetails
    in
    case ( isOpenAccess, pathwayUri, recommendedPathway ) of
        ( Just False, Just pwUri, Just pathway ) ->
            FreePathway.Paper meta pwUri pathway False
                |> (\p -> { model | paper = Just (FP p) })

        ( Just False, Just pwUri, Nothing ) ->
            OtherPathway.Paper meta pwUri
                |> (\p -> { model | paper = Just (OP p) })

        ( Just True, _, _ ) ->
            OpenAccess.Paper meta.doi
                meta.title
                meta.journal
                meta.authors
                meta.year
                meta.issn
                (Maybe.withDefault
                    ("https://doi.org/" ++ meta.doi)
                    backendPaper.oaLocationURL
                )
                |> (\p -> { model | paper = Just (OA p) })

        _ ->
            { model | error = True }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
