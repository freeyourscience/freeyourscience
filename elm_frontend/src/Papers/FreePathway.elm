module Papers.FreePathway exposing
    ( NoCostOaPathway
    , Paper
    , Pathway
    , PolicyMetaData
    , recommendPathway
    , renderRecommendedPathway
    , scorePathway
    , viewList
    , viewPublicationItemInfo
    )

import Html exposing (Html, a, br, button, div, h2, h3, li, p, section, small, strong, text, ul)
import Html.Attributes exposing (class, href, style)
import Html.Events exposing (onClick)
import HtmlUtils exposing (renderList, ulWithHeading)
import Msg exposing (Msg)
import Papers.Backend exposing (Embargo, Location, PermittedOA, Policy, Prerequisites)
import Papers.Utils exposing (NamedUrl, PaperMetadata, articleVersionString, publisherNotes, renderPaperMetaData, renderUrl)
import String.Extra exposing (humanize)



-- TYPES


type alias Paper =
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
    , locationSorted : Location
    , articleVersions : Maybe (List String)
    , conditions : Maybe (List String)
    , prerequisites : Maybe (List String)
    , embargo : Maybe String
    , notes : Maybe (List String)
    }



-- UPDATE
-- Logic for going from backend policies to a single recommended pathway (if is exists)


recommendPathway : List Policy -> Maybe ( PolicyMetaData, NoCostOaPathway )
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


flattenPolicies : List Policy -> List ( PolicyMetaData, Pathway )
flattenPolicies policies =
    policies
        |> List.map extractPathways
        |> List.concatMap (\( meta, pathways ) -> pathways |> List.map (Tuple.pair meta))


extractPathways : Policy -> ( PolicyMetaData, List Pathway )
extractPathways backendPolicy =
    ( backendPolicy
        |> parsePolicyMetaData
    , backendPolicy.permittedOA
        |> Maybe.withDefault []
        |> List.map parsePathway
    )


parsePathway : PermittedOA -> Pathway
parsePathway { articleVersions, location, prerequisites, conditions, additionalOaFee, embargo, publicNotes } =
    let
        embargoToString : Embargo -> String
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


parsePolicyMetaData : Policy -> PolicyMetaData
parsePolicyMetaData { policyUrl, urls, notes } =
    { profileUrl = policyUrl
    , additionalUrls = urls
    , notes = notes
    }


parsePrequisites : Prerequisites -> List String
parsePrequisites { prerequisitesPhrases, prerequisiteSubjects } =
    -- TODO: add prerequisiteFunders.funderMetadata
    (prerequisitesPhrases
        |> List.map (\item -> item.phrase)
    )
        ++ (prerequisiteSubjects
                |> Maybe.map
                    (\ps ->
                        [ "Manuscript must be from subjects: "
                            ++ String.join ", " ps
                        ]
                    )
                |> Maybe.withDefault []
           )


humanizeLocations : Location -> List String
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


viewList : List ( Int, Paper ) -> Html Msg
viewList papers =
    section []
        [ h2 []
            [ text "Paywalled with free open access pathway"
            ]
        , p []
            (if List.length papers > 0 then
                [ text
                    ("We found no open access version for the following publications. "
                        ++ "However, the publishers appear to allow no-cost re-publication as open access."
                    )
                ]

             else
                [ text
                    ("We found no paywalled publications with free open access re-publication pathways. "
                        ++ "Either you are already doing a wonderful job of keeping all your publications open access, "
                        ++ "or we are doing a bad job of finding all your publications."
                    )
                , br [] []
                , text "Let us know via "
                , a [ href "mailto:team@freeyourscience.org" ] [ text "team@freeyourscience.org" ]
                ]
            )
        , div [] (List.map view papers)
        ]


viewPublicationItemInfo : Paper -> Html Msg
viewPublicationItemInfo paper =
    div [ class "publications__item__info" ]
        [ div []
            (renderPaperMetaData h3 True False paper.meta)
        , div [ class "publications__item__info__pathway" ]
            (renderRecommendedPathway paper.recommendedPathway)
        ]


view : ( Int, Paper ) -> Html Msg
view ( id, paper ) =
    div [ class "publications__item" ]
        [ viewPublicationItemInfo paper
        , renderPathwayButtons ( id, paper.meta )
        ]



-- VIEW ELEMENTS


renderPathwayButtons : ( Int, { a | title : Maybe String, doi : String } ) -> Html Msg
renderPathwayButtons ( id, { title, doi } ) =
    let
        paperTitle =
            Maybe.withDefault "Unknown title" title
    in
    div [ class "publications__item__buttons" ]
        -- TODO: Link absolute to URL and not relative
        [ a [ href ("/search?query=" ++ doi) ]
            [ button
                [ class "pathway__button--show"
                , class "pathway__button"
                , Html.Attributes.title ("Re-publication details for: " ++ paperTitle)
                ]
                [ text "Details" ]
            ]
        ]


renderRecommendedPathway : ( PolicyMetaData, NoCostOaPathway ) -> List (Html Msg)
renderRecommendedPathway ( policy, { locationLabelsSorted, articleVersions, prerequisites, conditions, embargo, notes } ) =
    let
        addEmbargo : Maybe String -> Maybe (List String) -> Maybe (List String)
        addEmbargo emb pqs =
            case ( emb, pqs ) of
                ( Just e, Just p ) ->
                    Just (List.append [ e ++ " have passed since publication" ] p)

                ( Just e, Nothing ) ->
                    Just [ e ++ " have passed since publication" ]

                ( Nothing, Just p ) ->
                    Just p

                _ ->
                    Nothing
    in
    p []
        [ text "You can re-publish the "
        , strong [] [ text (articleVersionString articleVersions ++ " version") ]
        , text " today for free."
        ]
        :: (conditions
                |> addEmbargo embargo
                |> Maybe.map (ulWithHeading [ text "Conditions are:" ] text)
                |> Maybe.withDefault [ text "" ]
           )
