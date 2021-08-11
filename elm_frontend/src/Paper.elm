port module Paper exposing (..)

import Browser
import Date exposing (Date, fromIsoString)
import Debug
import Html exposing (Html, a, article, button, div, h1, h2, h3, main_, p, small, span, strong, text)
import Html.Attributes exposing (class, href, id, rel, target)
import HtmlUtils exposing (addEmbargo, ulWithHeading, viewSearchForm)
import Http
import HttpBuilder exposing (withHeader)
import Msg exposing (Msg)
import Papers.Backend as Backend
import Papers.FreePathway as FreePathway
import Papers.OpenAccess as OpenAccess
import Papers.OtherPathway as OtherPathway
import Papers.Utils exposing (DOI, articleVersionString, publisherNotes, renderPaperMetaDataWithDoi, renderUrl)
import ServerSideLogging
import Task
import Time exposing (Month(..))


type SomePaper
    = FP FreePathway.Paper
    | OA OpenAccess.Paper
    | OP OtherPathway.Paper


type alias Model =
    { doi : DOI
    , serverURL : String
    , paper : Maybe SomePaper
    , error : Bool
    , today : Date
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
      , today = Date.fromCalendarDate 1970 Jan 1
      }
    , Cmd.batch
        [ Date.today |> Task.perform Msg.ReceiveDate
        , fetchPaper flags.serverURL flags.doi
        ]
    )


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?paper_id=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson Msg.GotPaper Backend.paperDecoder)
        |> HttpBuilder.request



-- VIEW


viewWhosPublication : DOI -> Html Msg
viewWhosPublication doi =
    div [ class "whos-publication" ]
        [ h2 [] [ text "Your re-publishing choices" ]
        , div [ class "whos-publication__item" ]
            [ span [ class "whos-publication--title" ]
                [ text "Let us do the heavy lifting"
                ]
            , p []
                [ text
                    ("Our friends from the non-profit ShareYourPaper have checked the policy for you. "
                        ++ "Now, all you need is a PDF of your work."
                    )
                ]
            , a
                [ href ("/syp?doi=" ++ doi) ]
                [ button
                    [ class "pathway__button--show", class "pathway__button" ]
                    [ text "Re-publish" ]
                ]
            ]
        , div [ class "whos-publication__item" ]
            [ span [ class "whos-publication--title" ]
                [ text "Learn to re-publish yourself"
                ]
            , p []
                [ text
                    ("We think learning is great. So if you are curious to find out "
                        ++ "what individual steps are involved in re-publishing, "
                        ++ "there is a guide, customized for this publication, for you to "
                    )
                , a [ href "#guide" ] [ text "read below" ]
                , text "."
                ]
            ]
        , small [ class "whos-publication--footer" ]
            [ text
                ("Not your publication? Let the authors know what they can do. "
                    ++ "Share this page with them."
                )
            ]
        ]


viewRightVersion : List String -> String -> List (Html Msg)
viewRightVersion articleVersions sherpaPublicationUrl =
    let
        version =
            articleVersionString articleVersions
    in
    [ h3 [ id "version" ]
        [ text
            ("1. Find the "
                ++ version
                ++ " version of your manuscript"
            )
        ]
    , p []
        [ text "For this publication you are allowed to re-publish the "
        , strong [] [ text version ]
        , text " version as open access for free."
        ]
    , if String.contains "published" version then
        p []
            [ text """ The published version of the manuscript is for example the one
            published by a journal.
            It is usually a PDF file that has the journals logo and copyright notice on
            it and is typeset to the style of the journal.""" ]

      else
        text ""
    , if String.contains "accepted" version then
        p []
            [ text """The accepted version is the final version of the manuscript sent
            by the author(s) to the publisher.
            This is the result of the peer review process and includes changes and
            corrections by the author(s), but not the copy-editing and typesetting
            done by the publisher.
            Content should be the same as the published version, but appearance might
            differ strongly.""" ]

      else
        text ""
    , if String.contains "submitted" version then
        p []
            [ text """The submitted version is what was initially submitted for peer
            review. Content might differ strongly from the accepted version."""
            ]

      else
        text ""
    , p []
        [ text "The University of Cambridge Office of Scholarly Communication has a blog post with more in depth "
        , a [ href "https://unlockingresearch-blog.lib.cam.ac.uk/?p=1872" ]
            [ text "explanations of the different versions" ]
        , text " (accepted, submitted, published). "
        ]
    , small []
        [ text """We always display the pathway that allows the
        most mature version of the manuscript to be re-published.
        If you no longer have the version specified by the pathway
        you might also be allowed to re-publish an earlier one.
        Check the """
        , a [ href sherpaPublicationUrl, target "_blank", rel "noopener" ] [ text "pathway details for this publication" ]
        , text " in the Sherpa Romeo policy database for what other versions are allowed."
        ]
    ]


viewCheckConditions : ( FreePathway.PolicyMetaData, FreePathway.NoCostOaPathway ) -> List (Html Msg)
viewCheckConditions ( policy, pathway ) =
    h3 [ id "conditions" ]
        [ text "2. Check the conditions" ]
        :: (pathway.conditions
                |> addEmbargo (pathway.embargo |> Maybe.map FreePathway.embargoToString)
                |> Maybe.map
                    (ulWithHeading
                        [ text "Before you re-publish you need to ensure that the following conditions are met:"
                        ]
                        text
                    )
                |> Maybe.withDefault [ text "The publisher listed no explicit conditions." ]
           )
        ++ publisherNotes pathway.notes pathway.prerequisites
        ++ (policy.additionalUrls
                |> Maybe.map
                    (ulWithHeading
                        [ text "The publisher has provided the following links to further information:" ]
                        renderUrl
                    )
                |> Maybe.withDefault [ text "" ]
           )
        ++ [ p []
                [ policy.notes
                    |> Maybe.map (String.append "Regarding the policy they note: ")
                    |> Maybe.withDefault ""
                    |> text
                ]
           ]


viewWhereTo : List String -> List (Html Msg)
viewWhereTo locationLabelsSorted =
    h3 [ id "where" ]
        [ text "3. Choose where to upload" ]
        :: (locationLabelsSorted
                |> List.take 3
                |> ulWithHeading
                    [ text "The following locations are permitted for this publication:" ]
                    text
           )
        ++ [ p []
                [ text """Our recommendation for choosing is already reflected in the
                order of the options above: Prefer prefer public repositories over
                personal websites or social networks and use locations that are indexed
                so your publications are easy to find.""" ]
           , p []
                [ text """A repository is very much like a digital library.
                Technically, it is any place where you can store digital assets that is
                usually indexed by search engines.
                This will ensure your work is easily findable and available to the
                widest possible audience.""" ]
           ]


viewRepublishTodayForFree : FreePathway.Paper -> Html Msg
viewRepublishTodayForFree paper =
    let
        ( _, pathway ) =
            paper.recommendedPathway
    in
    article []
        (renderPaperMetaDataWithDoi
            div
            paper.meta
            ++ (if paper.meta.recommendShareYourPaper then
                    [ viewWhosPublication paper.meta.doi
                    , h2 [ id "guide" ] [ text "Custom re-publishing guide" ]
                    ]

                else
                    []
               )
            ++ viewRightVersion
                pathway.articleVersions
                (Tuple.first paper.recommendedPathway).sherpaPublicationUrl
            ++ viewCheckConditions paper.recommendedPathway
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
                    [ text """This step will be specific to your chosen repository.
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
                    follow a certain pattern; see point "2. Check the conditions" above."""
                    ]
               ]
        )


view : Model -> Html Msg
view model =
    let
        searchBar =
            viewSearchForm model.doi
                (text "If you can't find your publications using your name try your ORCID, Semantic Scholar ID or an individual DOI")
                []
    in
    case model.paper of
        Just (FP paper) ->
            let
                when =
                    case
                        FreePathway.remainingEmbargo
                            model.today
                            paper.meta.publishedDate
                            (Tuple.second paper.recommendedPathway).embargo
                    of
                        Just _ ->
                            "after an embargo"

                        Nothing ->
                            "today"
            in
            main_ [ class "paper", class "freepathway" ]
                [ h1 [] [ text ("Re-publish open access " ++ when ++ " for free") ]
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
                    (renderPaperMetaDataWithDoi div
                        { title = paper.title
                        , journal = paper.journal
                        , authors = paper.authors
                        , year = paper.year
                        , publishedDate = Nothing
                        , doi = paper.doi
                        , issn = paper.issn
                        , url = Just paper.oaLocationURL
                        , recommendShareYourPaper = False
                        }
                    )
                , p [ class "pathway-status" ]
                    [ text "This publication is already "
                    , a [ href paper.oaLocationURL, target "_blank", rel "noopener" ] [ text "open access" ]
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
            ( model
            , ServerSideLogging.reportHttpError model.serverURL error
            )

        Msg.ReceiveDate today ->
            ( { model | today = today }, Cmd.none )

        _ ->
            ( model, Cmd.none )


classifyPaper : Backend.Paper -> Model -> Model
classifyPaper backendPaper model =
    let
        isOpenAccess =
            backendPaper.isOpenAccess

        recommendedPathway =
            Maybe.andThen FreePathway.recommendPathway backendPaper.pathwayDetails

        recommendShareYourPaper =
            backendPaper.canShareYourPaper
                && (recommendedPathway
                        |> Maybe.map Tuple.second
                        |> Maybe.map (\p -> p.shareYourPaperCompatibleLocation)
                        |> Maybe.withDefault False
                   )

        meta =
            { doi = backendPaper.doi
            , title = backendPaper.title
            , journal = backendPaper.journal
            , authors = backendPaper.authors
            , year = backendPaper.year
            , publishedDate =
                backendPaper.publishedDate
                    |> Maybe.andThen (\d -> d |> fromIsoString |> Result.toMaybe)
            , issn = backendPaper.issn
            , url = Nothing
            , recommendShareYourPaper = recommendShareYourPaper
            }
    in
    case ( isOpenAccess, recommendedPathway ) of
        ( Just False, Just pathway ) ->
            FreePathway.Paper meta pathway
                |> (\p -> { model | paper = Just (FP p) })

        ( Just False, Nothing ) ->
            OtherPathway.Paper meta
                |> (\p -> { model | paper = Just (OP p) })

        ( Just True, _ ) ->
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
