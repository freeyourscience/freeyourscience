port module Paper exposing (..)

import Browser
import Debug
import Html exposing (Html, div, h1, main_, p, text)
import Html.Attributes exposing (class)
import HtmlUtils exposing (viewSearchBar)
import Http
import HttpBuilder exposing (withHeader)
import Msg exposing (Msg)
import Papers.Backend as Backend
import Papers.FreePathway as FreePathway
import Papers.OpenAccess as OpenAccess
import Papers.OtherPathway as OtherPathway
import Papers.Utils exposing (DOI)


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
                [ h1 [] [ text "Re-publish open access today" ]
                , { paper | pathwayVisible = True }
                    |> FreePathway.viewPublicationItemInfo
                ]

        Just (OP paper) ->
            main_ [ class "paper", class "otherpathway" ]
                [ h1 [] [ text "Paywalled with non-free policy" ]
                , searchBar
                , text ("OP" ++ Maybe.withDefault "" paper.meta.title)
                ]

        Just (OA paper) ->
            main_ [ class "paper", class "openaccess" ]
                [ h1 [] [ text "Already open access" ]
                , searchBar
                , div [ class "publications__item__info" ]
                    (Papers.Utils.renderPaperMetaData div
                        { title = paper.title
                        , journal = paper.journal
                        , authors = paper.authors
                        , year = paper.year
                        , doi = paper.doi
                        , issn = paper.issn
                        , url = Just paper.oaLocationURL
                        }
                    )
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
