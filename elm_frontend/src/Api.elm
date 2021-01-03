module Api exposing (..)

import Http
import HttpBuilder exposing (withHeader)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra as Decode
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
        |> Decode.andMap (D.field "doi" D.string)
        |> Decode.andMap (D.maybe (D.field "title" D.string))
        |> Decode.andMap (D.maybe (D.field "journal" D.string))
        |> Decode.andMap (D.maybe (D.field "authors" D.string))
        |> Decode.andMap (D.maybe (D.field "year" D.int))
        |> Decode.andMap (D.maybe (D.field "issn" D.string))
        |> Decode.andMap (D.maybe (D.field "is_open_access" D.bool))
        |> Decode.andMap (D.maybe (D.field "oa_pathway" D.string))
        |> Decode.andMap (D.maybe (D.field "oa_pathway_uri" D.string))
        |> Decode.andMap pathwayDecoder


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson GotPaper paperDecoder)
        |> HttpBuilder.request
