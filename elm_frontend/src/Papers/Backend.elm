module Papers.Backend exposing (Embargo, Location, Paper, PermittedOA, Policy, Prerequisites, paperDecoder)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)
import Papers.Utils exposing (DOI, NamedUrl)



-- TYPES


type alias Paper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , isOpenAccess : Maybe Bool
    , oaPathway : Maybe String
    , oaPathwayURI : Maybe String
    , pathwayDetails : Maybe (List Policy)
    , oaLocationURL : Maybe String
    }


type alias Policy =
    { urls : Maybe (List NamedUrl)
    , permittedOA : Maybe (List PermittedOA)
    , policyUrl : String -- TODO: this should come from oaPathwayURI
    , notes : Maybe String
    }


type alias PermittedOA =
    { additionalOaFee : String
    , location : Location
    , articleVersions : List String
    , conditions : Maybe (List String)
    , prerequisites : Maybe Prerequisites
    , embargo : Maybe Embargo
    , publicNotes : Maybe (List String)
    }


type alias Prerequisites =
    { prerequisites : List String
    , prerequisitesPhrases : List Phrase
    , prerequisitesFunders : Maybe (List Funder)
    , prerequisitesSubjects : Maybe (List String)
    }


type alias Phrase =
    { value : String
    , phrase : String
    , language : String
    }


type alias Funder =
    { funderMetadata : FunderMetadata }


type alias FunderMetadata =
    { name : String
    , url : String
    }


type alias Location =
    { location : List String
    , namedRepository : Maybe (List String)
    }


type alias Embargo =
    { amount : Int
    , units : String
    }



-- DECODERS


namedUrlDecoder : Decoder NamedUrl
namedUrlDecoder =
    D.succeed NamedUrl
        |> required "description" D.string
        |> required "url" D.string


locationDecoder : Decoder Location
locationDecoder =
    D.succeed Location
        |> required "location" (D.list D.string)
        |> optional "named_repository" (D.maybe (D.list D.string)) Nothing


prerequisitesDecoder : Decoder Prerequisites
prerequisitesDecoder =
    D.succeed Prerequisites
        |> required "prerequisites" (D.list D.string)
        |> required "prerequisites_phrases" (D.list phraseDecoder)
        |> optional "prerequisites_funders" (D.maybe (D.list funderDecoder)) Nothing
        |> optional "prequisite_subjects" (D.maybe (D.list D.string)) Nothing


phraseDecoder : Decoder Phrase
phraseDecoder =
    D.succeed Phrase
        |> required "value" D.string
        |> required "phrase" D.string
        |> required "language" D.string


funderDecoder : Decoder Funder
funderDecoder =
    D.succeed Funder
        |> required "funder_metadata" funderMetadataDecoder


funderMetadataDecoder : Decoder FunderMetadata
funderMetadataDecoder =
    D.succeed FunderMetadata
        |> required "name" D.string
        |> required "url" D.string


embargoDecoder : Decoder Embargo
embargoDecoder =
    D.succeed Embargo
        |> required "amount" D.int
        |> required "units" D.string


permittedOADecoder : Decoder PermittedOA
permittedOADecoder =
    D.succeed PermittedOA
        |> required "additional_oa_fee" D.string
        |> required "location" locationDecoder
        |> required "article_version" (D.list D.string)
        |> optional "conditions" (D.nullable (D.list D.string)) Nothing
        |> optional "prerequisites" (D.nullable prerequisitesDecoder) Nothing
        |> optional "embargo" (D.nullable embargoDecoder) Nothing
        |> optional "public_notes" (D.nullable (D.list D.string)) Nothing


policyDetailsDecoder : Decoder Policy
policyDetailsDecoder =
    D.succeed Policy
        |> required "urls" (D.nullable (D.list namedUrlDecoder))
        |> required "permitted_oa" (D.nullable (D.list permittedOADecoder))
        |> required "uri" D.string
        |> optional "notes" (D.nullable D.string) Nothing


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
        |> required "oa_pathway_details" (D.nullable (D.list policyDetailsDecoder))
        |> required "oa_location_url" (D.nullable D.string)
