module Papers.FreePathway exposing (FreePathwayPaper, NoCostOaPathway, Pathway, PolicyMetaData, recommendPathway, scorePathway, viewList)

import Html exposing (Html, a, button, div, h2, p, section, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import HtmlUtils exposing (ulWithHeading)
import Msg exposing (Msg)
import Papers.Backend exposing (BackendEmbargo, BackendLocation, BackendPermittedOA, BackendPolicy, BackendPrerequisites)
import Papers.Utils exposing (NamedUrl, PaperMetadata, renderPaperMetaData, renderUrl)
import String.Extra exposing (humanize)



-- TYPES


type alias FreePathwayPaper =
    { meta : PaperMetadata
    , oaPathwayURI : String
    , recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
    , pathwayVisible : Bool -- TODO: might be better served as a union type e.g. List (Visibility FreePathwayPaper)
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



-- UPDATE
-- Logic for going from backend policies to a single recommended pathway (if is exists)


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



-- UPDATE - PARSING BACKEND DATA


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



-- UPDATE - SCORING OF PATHWAYS


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



-- VIEW


viewList : List ( Int, FreePathwayPaper ) -> Html Msg
viewList papers =
    section [ class "mb-5" ]
        [ h2 []
            [ text "Unnecessarily paywalled publications"
            ]
        , p [ class "fs-6 mb-4" ]
            [ text
                ("We found no Open Access version for the following publications. "
                    ++ "However, the publishers likely allow no-cost re-publication as Open Access."
                )
            ]
        , div [] (List.map view papers)
        ]


view : ( Int, FreePathwayPaper ) -> Html Msg
view ( id, { pathwayVisible, recommendedPathway } as paper ) =
    let
        pathwayClass =
            if pathwayVisible then
                ""

            else
                "d-none"
    in
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            [ div []
                (renderPaperMetaData paper.meta)
            , div [ class pathwayClass ]
                (renderRecommendedPathway paper.oaPathwayURI recommendedPathway)
            ]
        , div [ class "col-12 col-md-3 fs-6 text-md-end" ]
            (renderPathwayButtons pathwayVisible ( id, paper.meta ))
        ]



-- VIEW ELEMENTS


renderPathwayButtons : Bool -> ( Int, { a | title : Maybe String } ) -> List (Html Msg)
renderPathwayButtons pathwayIsVisible ( id, { title } ) =
    let
        paperTitle =
            Maybe.withDefault "Unknown title" title

        verb =
            if pathwayIsVisible then
                "Hide"

            else
                "Show"

        style =
            if pathwayIsVisible then
                "btn btn-light"

            else
                "btn btn-success"
    in
    [ div []
        [ button
            [ onClick (Msg.ToggleVisible id)
            , class style
            , Html.Attributes.title (verb ++ "Open Access pathway for: " ++ paperTitle)
            ]
            [ text (verb ++ " Open Access pathway")
            ]
        ]
    ]


renderRecommendedPathway : String -> ( PolicyMetaData, NoCostOaPathway ) -> List (Html Msg)
renderRecommendedPathway journalPolicyUrl ( policy, { locationLabelsSorted, articleVersions, prerequisites, conditions, embargo, notes } ) =
    let
        addEmbargo : Maybe String -> Maybe (List String) -> Maybe (List String)
        addEmbargo emb prereqs =
            case ( emb, prereqs ) of
                ( Just e, Just p ) ->
                    Just (List.append [ "If " ++ e ++ " have passed since publication" ] p)

                ( Just e, Nothing ) ->
                    Just [ "If " ++ e ++ " have passed since publication" ]

                ( Nothing, Just p ) ->
                    Just p

                _ ->
                    Nothing

        articleVersion =
            articleVersions
                |> List.filter (\v -> v == "published")
                |> List.head
                |> Maybe.withDefault (String.join " or " articleVersions)
    in
    List.concat
        [ [ p [] [ text "The publisher has a policy that lets you:" ] ]
        , locationLabelsSorted
            |> List.take 3
            |> ulWithHeading ("upload the " ++ articleVersion ++ " version to any of the following:") text
        , [ p [] [ text " You don't have pay a fee to do this." ] ]
        , prerequisites
            |> addEmbargo embargo
            |> Maybe.map (ulWithHeading "But only:" text)
            |> Maybe.withDefault [ text "" ]
        , conditions
            |> Maybe.map (ulWithHeading "Conditions are:" text)
            |> Maybe.withDefault [ text "" ]
        , notes
            |> Maybe.map (ulWithHeading "Notes regarding this pathway:" text)
            |> Maybe.withDefault [ text "" ]
        , policy.additionalUrls
            |> Maybe.map (ulWithHeading "The publisher has provided the following links to further information:" renderUrl)
            |> Maybe.withDefault [ text "" ]
        , [ p []
                [ policy.notes
                    |> Maybe.map (String.append "Regarding the policy they note: ")
                    |> Maybe.withDefault ""
                    |> text
                ]
          ]
        , [ p []
                [ text "More information about this and other Open Access policies for this publication can be found in the "
                , a [ href journalPolicyUrl, class "link", class "link-secondary" ] [ text "Sherpa Policy Database" ]
                ]
          ]
        ]
