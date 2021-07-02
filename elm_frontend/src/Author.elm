module Author exposing (Model, main, subscriptions, update, view)

import Animation exposing (percent)
import Array exposing (Array)
import Browser
import Date exposing (Date, fromIsoString)
import Debug
import Html exposing (Html, a, div, h1, h2, main_, p, text)
import Html.Attributes exposing (class)
import HtmlUtils exposing (viewSearchForm, viewSearchNoteWithLinks)
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
import Task
import Time exposing (Month(..))


type alias Model =
    { initialPaperIds : List DOI
    , freePathwayPapers : Array FreePathway.Paper
    , otherPathwayPapers : List OtherPathway.Paper
    , openAccessPapers : List OpenAccess.Paper
    , buggyPapers : List Buggy.Paper
    , numFailedDOIRequests : Int
    , searchQuery : String
    , authorProfileURL : String
    , authorProfileProvider : String
    , serverURL : String
    , style : Animation.State
    , today : Date
    }



-- INIT


type alias Flags =
    { paperIds : List String
    , serverURL : String
    , authorProfileURL : String
    , authorProfileProvider : String
    , searchQuery : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { initialPaperIds = flags.paperIds
      , freePathwayPapers = Array.empty
      , otherPathwayPapers = []
      , openAccessPapers = []
      , buggyPapers = []
      , numFailedDOIRequests = 0
      , authorProfileURL = flags.authorProfileURL
      , authorProfileProvider = flags.authorProfileProvider
      , searchQuery = flags.searchQuery
      , serverURL = flags.serverURL
      , style = Animation.style [ Animation.width (percent 0), Animation.opacity 1 ]
      , today = Date.fromCalendarDate 1970 Jan 1
      }
    , Cmd.batch
        ((Date.today |> Task.perform Msg.ReceiveDate)
            :: List.map (fetchPaper flags.serverURL) flags.paperIds
        )
    )


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL paperId =
    HttpBuilder.get (serverURL ++ "/api/papers?paper_id=" ++ paperId)
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
            , viewSearchForm model.searchQuery
                (viewSearchNoteWithLinks
                    model.searchQuery
                    model.authorProfileURL
                    model.authorProfileProvider
                    (model |> numberFetchedPapers)
                )
                (Animation.render model.style)
            , FreePathway.viewList model.today paywalledNoCostPathwayPapers
            , h2 [] [ text "Other search results" ]
            , p [] [ text "For completeness, here are the other publications we found for your search." ]
            , div [ class "author__otherresults" ]
                [ OtherPathway.viewList nonFreePolicyPapers
                , OpenAccess.viewList model.openAccessPapers
                , Buggy.viewList model.buggyPapers
                ]
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
                                    (min 1 (List.length model.initialPaperIds - numberFetchedPapers m))
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

        Msg.ReceiveDate today ->
            ( { model | today = today }, Cmd.none )


classifyPaper : Backend.Paper -> Model -> Model
classifyPaper backendPaper model =
    let
        isOpenAccess =
            backendPaper.isOpenAccess

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
            , canShareYourPaper = backendPaper.canShareYourPaper
            }

        recommendedPathway =
            Maybe.andThen FreePathway.recommendPathway backendPaper.pathwayDetails
    in
    case ( isOpenAccess, recommendedPathway ) of
        ( Just False, Just pathway ) ->
            FreePathway.Paper meta pathway
                |> (\p -> { model | freePathwayPapers = Array.push p model.freePathwayPapers })

        ( Just False, Nothing ) ->
            OtherPathway.Paper meta
                |> (\p -> { model | otherPathwayPapers = model.otherPathwayPapers ++ [ p ] })

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
            / (model.initialPaperIds |> List.length |> toFloat)
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
