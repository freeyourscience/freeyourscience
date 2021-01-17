module Api exposing (fetchPaper, paperDecoder)

import Http
import HttpBuilder exposing (withHeader)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import Types exposing (..)


namedUrlDecoder : Decoder NamedUrl
namedUrlDecoder =
    D.succeed NamedUrl
        |> required "description" D.string
        |> required "url" D.string


locationDecoder : Decoder BackendLocation
locationDecoder =
    D.succeed BackendLocation
        |> required "location" (D.list D.string)
        |> optional "named_repository" (D.maybe (D.list D.string)) Nothing


prerequisitesDecoder : Decoder BackendPrerequisites
prerequisitesDecoder =
    D.succeed BackendPrerequisites
        |> required "prerequisites" (D.list D.string)
        |> required "prerequisites_phrases" (D.list phraseDecoder)


phraseDecoder : Decoder BackendPhrase
phraseDecoder =
    D.succeed BackendPhrase
        |> required "value" D.string
        |> required "phrase" D.string
        |> required "language" D.string


permittedOADecoder : Decoder BackendPermittedOA
permittedOADecoder =
    D.succeed BackendPermittedOA
        |> required "additional_oa_fee" D.string
        |> required "location" locationDecoder
        |> required "article_version" (D.list D.string)
        |> optional "conditions" (D.nullable (D.list D.string)) Nothing
        |> optional "prerequisites" (D.nullable prerequisitesDecoder) Nothing


policyDetailsDecoder : Decoder BackendPolicy
policyDetailsDecoder =
    D.succeed BackendPolicy
        |> required "urls" (D.nullable (D.list namedUrlDecoder))
        |> required "permitted_oa" (D.nullable (D.list permittedOADecoder))
        |> required "uri" D.string
        |> optional "notes" (D.nullable D.string) Nothing


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
        |> required "oa_pathway_details" (D.nullable (D.list policyDetailsDecoder))


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson GotPaper paperDecoder)
        |> HttpBuilder.request
