module Author exposing (Model, main, subscriptions, update, view)

import Animation exposing (percent)
import Array exposing (Array)
import Browser
import Debug
import Html exposing (Html, a, div, footer, h1, h2, main_, p, small, text)
import Html.Attributes exposing (class, href, target)
import HtmlUtils exposing (viewSearchForm)
import Http
import HttpBuilder exposing (withHeader)
import Msg exposing (Msg)
import Papers.Backend as Backend
import Papers.Buggy as Buggy
import Papers.FreePathway as FreePathway
import Papers.OpenAccess as OpenAccess
import Papers.OtherPathway as OtherPathway
import Papers.Utils exposing (DOI, PaperMetadata)
import ServerSideLogging


type alias Model =
    { initialDOIs : List DOI
    , freePathwayPapers : Array FreePathway.Paper
    , otherPathwayPapers : List OtherPathway.Paper
    , openAccessPapers : List OpenAccess.Paper
    , buggyPapers : List Buggy.Paper
    , numFailedDOIRequests : Int
    , authorName : String
    , searchQuery : String
    , authorProfileURL : String
    , serverURL : String
    , style : Animation.State
    }



-- INIT


type alias Flags =
    { dois : List String
    , serverURL : String
    , authorName : String
    , authorProfileURL : String
    , searchQuery : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { initialDOIs = flags.dois
      , freePathwayPapers = Array.empty
      , otherPathwayPapers = []
      , openAccessPapers = []
      , buggyPapers = []
      , numFailedDOIRequests = 0
      , authorName = flags.authorName
      , authorProfileURL = flags.authorProfileURL
      , searchQuery = flags.searchQuery
      , serverURL = flags.serverURL
      , style = Animation.style [ Animation.width (percent 0), Animation.opacity 1 ]
      }
    , Cmd.batch (List.map (fetchPaper flags.serverURL) flags.dois)
    )


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson Msg.GotPaper Backend.paperDecoder)
        |> HttpBuilder.request



-- VIEW


view : Model -> Html Msg
view model =
    let
        paperMetaCompare : { a | meta : PaperMetadata } -> { a | meta : PaperMetadata } -> Order
        paperMetaCompare p1 p2 =
            let
                y1 =
                    Maybe.withDefault 9999999999 p1.meta.year

                y2 =
                    Maybe.withDefault 9999999999 p2.meta.year
            in
            compare y2 y1

        indexedPapersYearComp : ( Int, { a | meta : PaperMetadata } ) -> ( Int, { a | meta : PaperMetadata } ) -> Order
        indexedPapersYearComp ( _, p1 ) ( _, p2 ) =
            paperMetaCompare p1 p2

        paywalledNoCostPathwayPapers =
            List.sortWith indexedPapersYearComp (Array.toIndexedList model.freePathwayPapers)

        nonFreePolicyPapers =
            List.sortWith paperMetaCompare model.otherPathwayPapers
    in
    div []
        [ main_ [ class "author" ]
            [ h1 [] [ text "Results" ]
            , viewSearchForm model.authorName
                "If you can't find your publications using your name try your ORCID, Semantic Scholar ID or an individual DOI"
                (Animation.render model.style)
            , FreePathway.viewList paywalledNoCostPathwayPapers
            , h2 [] [ text "Other search results" ]
            , p [] [ text "For completeness, here are the other publications we found for your search." ]
            , div [ class "author__otherresults" ]
                [ OtherPathway.viewList nonFreePolicyPapers
                , OpenAccess.viewList model.openAccessPapers
                , Buggy.viewList model.buggyPapers
                ]
            ]
        , renderFooter model.authorProfileURL
        ]



-- VIEW SOURCE PROFILE


renderFooter : String -> Html Msg
renderFooter authorProfileURL =
    footer [ class "container text-center m-4" ]
        [ small []
            [ text "("
            , a [ href authorProfileURL, target "_blank", class "link-dark" ]
                [ text "Source Profile"
                ]
            , text " that was used to retreive the author's publications.)"
            ]
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateStyle m =
            { m
                | style =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.width (percent (percentDOIsFetched model))
                            , Animation.opacity
                                (toFloat
                                    (min 1 (List.length model.initialDOIs - numberFetchedPapers m))
                                )
                            ]
                        ]
                        model.style
            }
    in
    case msg of
        Msg.GotPaper (Ok backendPaper) ->
            ( model
                |> classifyPaper backendPaper
                |> updateStyle
            , Cmd.none
            )

        Msg.GotPaper (Err error) ->
            let
                _ =
                    Debug.log "Error in GotPaper" error
            in
            ( { model | numFailedDOIRequests = model.numFailedDOIRequests + 1 }
            , ServerSideLogging.reportHttpError model.serverURL error
            )

        Msg.Animate animMsg ->
            ( { model
                | style = Animation.update animMsg model.style
              }
            , Cmd.none
            )

        Msg.HttpNoOp (Err error) ->
            let
                _ =
                    Debug.log "Error for no-op" error
            in
            ( model, Cmd.none )

        Msg.HttpNoOp (Ok ()) ->
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
            FreePathway.Paper meta pwUri pathway
                |> (\p -> { model | freePathwayPapers = Array.push p model.freePathwayPapers })

        ( Just False, Just pwUri, Nothing ) ->
            OtherPathway.Paper meta pwUri
                |> (\p -> { model | otherPathwayPapers = model.otherPathwayPapers ++ [ p ] })

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
                |> (\p -> { model | openAccessPapers = model.openAccessPapers ++ [ p ] })

        _ ->
            { model | buggyPapers = model.buggyPapers ++ [ Buggy.Paper meta backendPaper.oaPathway ] }



-- UPDATE LOADING BAR


numberFetchedPapers : Model -> Int
numberFetchedPapers model =
    List.length model.buggyPapers
        + Array.length model.freePathwayPapers
        + List.length model.openAccessPapers
        + List.length model.otherPathwayPapers
        + model.numFailedDOIRequests


percentDOIsFetched : Model -> Float
percentDOIsFetched model =
    -- Report at least 10 percent at all times to provide immediate loading feedback.
    max
        10
        (100
            * (model |> numberFetchedPapers |> toFloat)
            / (model.initialDOIs |> List.length |> toFloat)
        )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Msg.Animate [ model.style ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
