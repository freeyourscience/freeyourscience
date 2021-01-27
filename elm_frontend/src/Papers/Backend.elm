module Papers.Backend exposing (BackendEmbargo, BackendLocation, BackendPaper, BackendPermittedOA, BackendPolicy, BackendPrerequisites, paperDecoder)

import GeneralTypes exposing (DOI, NamedUrl)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline exposing (optional, required)



-- TYPES


type alias BackendPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , isOpenAccess : Maybe Bool
    , oaPathway : Maybe String
    , oaPathwayURI : Maybe String
    , pathwayDetails : Maybe (List BackendPolicy)
    , oaLocationURL : Maybe String
    }


type alias BackendPolicy =
    { urls : Maybe (List NamedUrl)
    , permittedOA : Maybe (List BackendPermittedOA)
    , policyUrl : String -- TODO: this should come from oaPathwayURI
    , notes : Maybe String
    }


type alias BackendPermittedOA =
    { additionalOaFee : String
    , location : BackendLocation
    , articleVersions : List String
    , conditions : Maybe (List String)
    , prerequisites : Maybe BackendPrerequisites
    , embargo : Maybe BackendEmbargo
    , publicNotes : Maybe (List String)
    }


type alias BackendPrerequisites =
    { prerequisites : List String
    , prerequisites_phrases : List BackendPhrase
    }


type alias BackendPhrase =
    { value : String
    , phrase : String
    , language : String
    }


type alias BackendLocation =
    { location : List String
    , namedRepository : Maybe (List String)
    }


type alias BackendEmbargo =
    { amount : Int
    , units : String
    }



-- DECODERS


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


embargoDecoder : Decoder BackendEmbargo
embargoDecoder =
    D.succeed BackendEmbargo
        |> required "amount" D.int
        |> required "units" D.string


permittedOADecoder : Decoder BackendPermittedOA
permittedOADecoder =
    D.succeed BackendPermittedOA
        |> required "additional_oa_fee" D.string
        |> required "location" locationDecoder
        |> required "article_version" (D.list D.string)
        |> optional "conditions" (D.nullable (D.list D.string)) Nothing
        |> optional "prerequisites" (D.nullable prerequisitesDecoder) Nothing
        |> optional "embargo" (D.nullable embargoDecoder) Nothing
        |> optional "public_notes" (D.nullable (D.list D.string)) Nothing


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
        |> required "oa_location_url" (D.nullable D.string)
