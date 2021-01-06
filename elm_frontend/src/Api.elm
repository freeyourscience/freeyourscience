module Api exposing (..)

import Http
import HttpBuilder exposing (withHeader)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Types exposing (..)


recommendedPathway : Pathway
recommendedPathway =
    { articleVersion = "accepted"
    , locations = [ "Academic Social Network", "Author's Homepage" ]
    , prerequisites = [ "If Required by Institution", "12 months have passed since publication" ]
    , conditions = [ "Must be accompanied by set statement (see policy)", "Must link to publisher version" ]
    , notes = [ "If mandated to deposit before 12 months, the author must obtain a  waiver from their Institution/Funding agency or use  AuthorChoice" ]
    , urls = [ { name = "Best Page Ever", url = "https://freeyourscience.org" } ]
    , policyUrl = "https://freeyourscience.org"
    }


pathwayDecoder : Decoder Pathway
pathwayDecoder =
    D.succeed recommendedPathway


paperDecoder : Decoder Paper
paperDecoder =
    D.succeed Paper
        |> required "doi" D.string
        |> required "title" (D.nullable D.string)
        |> required "journal" (D.nullable D.string)
        |> required "authors" (D.nullable D.string)
        |> required "year" (D.nullable D.int)
        |> required "issn" (D.nullable D.string)
        |> required "is_open_access" (D.nullable D.bool)
        |> required "oa_pathway" (D.nullable D.string)
        |> required "oa_pathway_uri" (D.nullable D.string)
        |> required "oa_pathway_details" (D.nullable pathwayDecoder)


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson GotPaper paperDecoder)
        |> HttpBuilder.request
