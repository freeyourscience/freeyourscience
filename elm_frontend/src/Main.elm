module Main exposing (..)

import Api exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode exposing (bool)
import List
import Maybe
import Types exposing (..)
import Utils exposing (..)
import Views exposing (..)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \m -> Sub.none
        , view = view
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model
        (Maybe.withDefault [] (List.tail flags.dois))
        []
        flags.authorName
        flags.authorProfileURL
        flags.serverURL
    , case List.head flags.dois of
        Just nextDOI ->
            fetchPaper flags.serverURL nextDOI

        Nothing ->
            Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "update message:" msg

        updatedDOIs =
            List.drop 1 model.unfetchedDOIs
    in
    case msg of
        GotPaper (Ok paper) ->
            ( { model
                | fetchedPapers = List.append model.fetchedPapers [ paper ]
                , unfetchedDOIs = updatedDOIs
              }
            , case List.head model.unfetchedDOIs of
                Just nextDOI ->
                    fetchPaper model.serverURL nextDOI

                Nothing ->
                    Cmd.none
            )

        -- TODO: add the erroneous dois as well?
        GotPaper (Err err) ->
            ( { model | unfetchedDOIs = updatedDOIs }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    let
        preppedPapers =
            List.sortWith optionalYearComparison model.fetchedPapers

        paywalledNoCostPathwayPapers =
            List.filter isPaywalledNoCostPathwayPaper preppedPapers

        nonFreePolicyPapers =
            List.filter isNonFreePolicyPaper preppedPapers

        openAccessPapers =
            List.filter isOpenAccessPaper preppedPapers

        buggyPapers =
            List.filter isBuggyPaper preppedPapers
    in
    div []
        [ renderHeader model.unfetchedDOIs model.authorName paywalledNoCostPathwayPapers
        , main_ []
            [ renderPaywalledNoCostPathwayPapers paywalledNoCostPathwayPapers
            , renderNonFreePolicyPapers nonFreePolicyPapers
            , renderOpenAccessPapers openAccessPapers
            , renderBuggyPapers buggyPapers
            ]
        , renderFooter model.authorProfileURL
        ]
