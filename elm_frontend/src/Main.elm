module Main exposing (..)

import Animation exposing (percent, px)
import Api exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (bool)
import List
import Maybe
import Types exposing (..)
import Utils exposing (..)
import Views exposing (..)


type alias Model =
    { unfetchedDOIs : List DOI
    , fetchedPapers : List Paper
    , authorName : String
    , authorProfileURL : String
    , serverURL : String
    , style : Animation.State
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { unfetchedDOIs = Maybe.withDefault [] (List.tail flags.dois)
      , fetchedPapers = []
      , authorName = flags.authorName
      , authorProfileURL = flags.authorProfileURL
      , serverURL = flags.serverURL
      , style = Animation.style [ Animation.width (percent 0), Animation.opacity 1 ]
      }
    , case List.head flags.dois of
        Just nextDOI ->
            fetchPaper flags.serverURL nextDOI

        Nothing ->
            Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Animate [ model.style ]


percentDOIsFetched : Model -> Float
percentDOIsFetched model =
    max
        10
        (100
            * toFloat (List.length model.fetchedPapers)
            / (toFloat (List.length model.fetchedPapers) + toFloat (List.length model.unfetchedDOIs))
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updatedModel =
            { model
                | style =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.width (percent (percentDOIsFetched model))
                            , Animation.opacity (toFloat (min 1 (List.length model.unfetchedDOIs)))
                            ]
                        ]
                        model.style
            }

        updatedDOIs =
            List.drop 1 model.unfetchedDOIs
    in
    case msg of
        GotPaper (Ok paper) ->
            ( { updatedModel
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
            ( { updatedModel | unfetchedDOIs = updatedDOIs }
            , Cmd.none
            )

        Animate animMsg ->
            ( { model
                | style = Animation.update animMsg model.style
              }
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
        [ span
            [ class "container"
            , class "progressbar__container"
            ]
            [ span (Animation.render model.style ++ [ class "progressbar_progress" ]) [ text "" ] ]
        , main_ []
            [ renderPaywalledNoCostPathwayPapers paywalledNoCostPathwayPapers
            , renderNonFreePolicyPapers nonFreePolicyPapers
            , renderOpenAccessPapers openAccessPapers
            , renderBuggyPapers buggyPapers
            ]
        , renderFooter model.authorProfileURL
        ]
