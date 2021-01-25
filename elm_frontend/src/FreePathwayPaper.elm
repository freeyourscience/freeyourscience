module FreePathwayPaper exposing (FreePathwayPaper, NoCostOaPathway, Pathway, PolicyMetaData, recommendPathway)

import BackendPaper exposing (BackendEmbargo, BackendLocation, BackendPermittedOA, BackendPolicy, BackendPrerequisites)
import GeneralTypes exposing (DOI, NamedUrl)
import String.Extra exposing (humanize)



-- TYPES


type alias FreePathwayPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , oaPathwayURI : String
    , recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
    , pathwayVisible : Bool
    }


type alias PolicyMetaData =
    { profileUrl : String
    , additionalUrls : Maybe (List NamedUrl)
    , notes : Maybe String
    }


type alias NoCostOaPathway =
    { articleVersions : List String
    , locationLabelsSorted : List String
    , prerequisites : Maybe (List String)
    , conditions : Maybe (List String)
    , embargo : Maybe String
    , notes : Maybe (List String)
    }


type alias Pathway =
    { additionalOaFee : String
    , locationSorted : BackendLocation
    , articleVersions : Maybe (List String)
    , conditions : Maybe (List String)
    , prerequisites : Maybe (List String)
    , embargo : Maybe String
    , notes : Maybe (List String)
    }



-- Select no-cost-oa-pathway


recommendPathway : List BackendPolicy -> Maybe ( PolicyMetaData, NoCostOaPathway )
recommendPathway policies =
    -- TODO: move scoring extraction & construction into locally scoped function
    policies
        |> flattenPolicies
        |> List.map (\( metadata, pathway ) -> ( scorePathway pathway, ( metadata, pathway ) ))
        |> List.sortBy Tuple.first
        |> List.reverse
        |> List.map Tuple.second
        |> List.map noCostOaPathway
        |> List.filterMap identity
        |> List.head


noCostOaPathway : ( PolicyMetaData, Pathway ) -> Maybe ( PolicyMetaData, NoCostOaPathway )
noCostOaPathway ( metadata, pathway ) =
    case ( pathway.additionalOaFee, pathway.articleVersions ) of
        ( "no", Just articleVersions ) ->
            Just
                ( metadata
                , { articleVersions = articleVersions
                  , locationLabelsSorted = humanizeLocations pathway.locationSorted
                  , prerequisites = pathway.prerequisites
                  , conditions = pathway.conditions
                  , embargo = pathway.embargo
                  , notes = pathway.notes
                  }
                )

        _ ->
            Nothing


flattenPolicies : List BackendPolicy -> List ( PolicyMetaData, Pathway )
flattenPolicies policies =
    policies
        |> List.map extractPathways
        |> List.concatMap (\( meta, pathways ) -> pathways |> List.map (Tuple.pair meta))


extractPathways : BackendPolicy -> ( PolicyMetaData, List Pathway )
extractPathways backendPolicy =
    ( backendPolicy
        |> parsePolicyMetaData
    , backendPolicy.permittedOA
        |> Maybe.withDefault []
        |> List.map parsePathway
    )


parsePathway : BackendPermittedOA -> Pathway
parsePathway { articleVersions, location, prerequisites, conditions, additionalOaFee, embargo, publicNotes } =
    let
        embargoToString : BackendEmbargo -> String
        embargoToString { amount, units } =
            String.join " " [ String.fromInt amount, units ]
    in
    { articleVersions =
        case articleVersions of
            [] ->
                Nothing

            _ ->
                Just articleVersions
    , locationSorted = { location | location = location.location |> List.sortBy scoreAllowedLocation |> List.reverse }
    , prerequisites = prerequisites |> Maybe.map parsePrequisites
    , conditions = conditions
    , additionalOaFee = additionalOaFee
    , embargo = embargo |> Maybe.map embargoToString
    , notes = publicNotes
    }


parsePolicyMetaData : BackendPolicy -> PolicyMetaData
parsePolicyMetaData { policyUrl, urls, notes } =
    { profileUrl = policyUrl
    , additionalUrls = urls
    , notes = notes
    }


parsePrequisites : BackendPrerequisites -> List String
parsePrequisites { prerequisites_phrases } =
    prerequisites_phrases
        |> List.map (\item -> item.phrase)


humanizeLocations : BackendLocation -> List String
humanizeLocations { location, namedRepository } =
    location
        |> List.map humanize
        |> List.map
            (\loc ->
                case ( loc, namedRepository ) of
                    ( "Named repository", Just repositoryNames ) ->
                        String.join " or " repositoryNames

                    _ ->
                        loc
            )
        |> List.map
            (\loc ->
                case loc of
                    "Non commercial repository" ->
                        "Non-commercial repositories"

                    "Authors homepage" ->
                        "Author's homepage"

                    "Academic social network" ->
                        "Academic social networks"

                    _ ->
                        loc
            )



-- SCORING


scorePathway : Pathway -> Float
scorePathway pathway =
    let
        versionScore =
            pathway.articleVersions
                |> Maybe.withDefault []
                |> List.map scoreAllowedVersion
                |> List.maximum
                |> Maybe.withDefault 0

        locationScore =
            pathway.locationSorted.location
                |> List.head
                |> Maybe.map scoreAllowedLocation
                |> Maybe.withDefault 0
    in
    versionScore + locationScore


scoreAllowedVersion : String -> Float
scoreAllowedVersion version =
    case version of
        "published" ->
            3

        "accepted" ->
            2

        "submitted" ->
            1

        _ ->
            0


scoreAllowedLocation : String -> Float
scoreAllowedLocation location =
    case location of
        "any_repository" ->
            6

        "preprint_repository" ->
            5

        "subject_repository" ->
            5

        "non_commercial_repository" ->
            5

        "non_commercial_subject_repository" ->
            4

        "institutional_repository" ->
            4

        "non_commercial_institutional_repository" ->
            4

        "named_repository" ->
            4

        "any_website" ->
            3

        "institutional_website" ->
            3

        "non_commercial_website" ->
            3

        "authors_homepage" ->
            3

        "academic_social_network" ->
            2

        "non_commercial_social_network" ->
            2

        "named_academic_social_network" ->
            2

        "funder_designated_location" ->
            2

        "this_journal" ->
            1

        _ ->
            0
