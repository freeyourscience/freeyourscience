module ServerSideLogging exposing (callToActionLogMessage, postLogToBackend, reportHttpError)

import Http
import HttpBuilder exposing (withBody, withExpect, withHeader)
import Json.Encode
import Msg exposing (Msg(..))


extractMessage : Http.Error -> Maybe String
extractMessage error =
    case error of
        Http.BadBody m ->
            Just m

        Http.BadStatus s ->
            Just ("BadStatus with code: " ++ String.fromInt s)

        _ ->
            Nothing


callToActionLogMessage : Bool -> Bool -> String -> String
callToActionLogMessage recommendShareYourPaper canShareYourPaper doi =
    case ( recommendShareYourPaper, canShareYourPaper ) of
        -- The happy path where we can offer our users the SYP option because it does
        -- not rely on institutional repository
        ( True, True ) ->
            "recommend_cansyp_" ++ doi

        -- If this happens, something is broken, because we should never recommend SYP
        -- if SYP itself says the publication can't be shared
        ( True, False ) ->
            "recommend_cantsyp_" ++ doi

        -- We are being conservative and don't recommend SYP because the allows location
        -- in the Sherpa pathway doesn't match
        ( False, True ) ->
            "norecommend_cansyp_" ++ doi

        -- For a Sherpa classified free pathway publication (only given by call context)
        -- SYP specifies it can't be shared
        ( False, False ) ->
            "norecommend_cant_" ++ doi


postLogToBackend : String -> String -> String -> Cmd Msg
postLogToBackend serverURL event message =
    HttpBuilder.post (serverURL ++ "/api/logs")
        |> withBody
            (Http.jsonBody
                (Json.Encode.object
                    [ ( "event", Json.Encode.string ("client_side_" ++ event) )
                    , ( "message", Json.Encode.string message )
                    ]
                )
            )
        |> withExpect (Http.expectWhatever Msg.HttpNoOp)
        |> HttpBuilder.request


reportHttpError : String -> Http.Error -> Cmd Msg
reportHttpError serverURL error =
    extractMessage error
        |> Maybe.map (postLogToBackend serverURL "http_error")
        |> Maybe.withDefault Cmd.none
