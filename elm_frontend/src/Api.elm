module Api exposing (..)

import Http
import HttpBuilder exposing (withHeader)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Types exposing (..)


namedUrlDecoder : Decoder NamedUrl
namedUrlDecoder =
    D.succeed NamedUrl
        |> required "description" D.string
        |> required "url" D.string


locationDecoder : Decoder Location
locationDecoder =
    D.succeed Location
        |> required "location" (D.list D.string)


permittedOADecoder : Decoder PermittedOA
permittedOADecoder =
    D.succeed PermittedOA
        |> required "additional_oa_fee" D.string
        |> required "location" locationDecoder
        |> required "article_version" (D.list D.string)
        |> required "conditions" (D.list D.string)


pathwayDetailsDecoder : Decoder PathwayDetails
pathwayDetailsDecoder =
    D.succeed PathwayDetails
        |> required "urls" (D.nullable (D.list namedUrlDecoder))
        |> required "permitted_oa" (D.nullable (D.list permittedOADecoder))


paperDecoder : Decoder BackendPaper
paperDecoder =
    D.succeed BackendPaper
        |> required "doi" D.string
        |> required "title" (D.nullable D.string)
        |> required "journal" (D.nullable D.string)
        |> required "authors" (D.nullable D.string)
        |> required "year" (D.nullable D.int)
        |> required "issn" (D.nullable D.string)
        |> required "is_open_access" (D.nullable D.bool)
        |> required "oa_pathway" (D.nullable D.string)
        |> required "oa_pathway_uri" (D.nullable D.string)
        |> required "oa_pathway_details" (D.nullable (D.list pathwayDetailsDecoder))


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson GotPaper paperDecoder)
        |> HttpBuilder.request
