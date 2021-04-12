module ServerSideLogging exposing (reportHttpError)

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


postLogToBackend : String -> String -> String -> Cmd Msg
postLogToBackend serverURL event message =
    HttpBuilder.post (serverURL ++ "/api/logs")
        |> withHeader "Content-Type" "application/json"
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
