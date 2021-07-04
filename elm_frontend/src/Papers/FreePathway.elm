module Papers.FreePathway exposing
    ( NoCostOaPathway
    , Paper
    , Pathway
    , PolicyMetaData
    , embargoTimeDeltaString
    , embargoToString
    , recommendPathway
    , remainingEmbargo
    , renderRecommendedPathway
    , scorePathway
    , viewList
    , viewPublicationItemInfo
    )

import Date exposing (Date, Unit(..), diff)
import Html exposing (Html, a, br, button, div, h2, h3, p, section, strong, text)
import Html.Attributes exposing (class, href)
import HtmlUtils exposing (addEmbargo, ulWithHeading)
import Msg exposing (Msg)
import Papers.Backend exposing (Embargo, Funder, Location, PermittedOA, Policy, Prerequisites)
import Papers.Utils exposing (NamedUrl, PaperMetadata, articleVersionString, renderPaperMetaData)
import String.Extra exposing (humanize)
import Time exposing (Month(..))



-- TYPES


type alias Paper =
    { meta : PaperMetadata
    , recommendedPathway : ( PolicyMetaData, NoCostOaPathway )
    }


type alias PolicyMetaData =
    { policyUrl : String
    , sherpaPublicationUrl : String
    , additionalUrls : Maybe (List NamedUrl)
    , notes : Maybe String
    }


type alias NoCostOaPathway =
    { articleVersions : List String
    , locationLabelsSorted : List String
    , prerequisites : Maybe (List String)
    , conditions : Maybe (List String)
    , embargo : Maybe Embargo
    , notes : Maybe (List String)
    , shareYourPaperCompatibleLocation : Bool
    }


type alias Pathway =
    { additionalOaFee : String
    , locationSorted : Location
    , articleVersions : Maybe (List String)
    , conditions : Maybe (List String)
    , prerequisites : Maybe (List String)
    , embargo : Maybe Embargo
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
        |> List.filter pathwayLocationDoesNotIncludeThisJournal
        |> List.map noCostOaPathway
        |> List.filterMap identity
        |> List.head


pathwayLocationDoesNotIncludeThisJournal : ( PolicyMetaData, Pathway ) -> Bool
pathwayLocationDoesNotIncludeThisJournal ( metadata, pathway ) =
    not (List.member "this_journal" pathway.locationSorted.location)


shareYourPaperCompatibleLocation : List String -> Bool
shareYourPaperCompatibleLocation locations =
    locations
        |> List.filter
            (\l ->
                List.member l
                    [ "any_repository", "preprint_repository", "non_commercial_repository" ]
            )
        |> List.isEmpty
        |> not


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
                  , shareYourPaperCompatibleLocation = shareYourPaperCompatibleLocation pathway.locationSorted.location
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


embargoToString : Embargo -> String
embargoToString { amount, units } =
    String.join " " [ String.fromInt amount, units ]


parsePathway : PermittedOA -> Pathway
parsePathway { articleVersions, location, prerequisites, conditions, additionalOaFee, embargo, publicNotes } =
    { articleVersions =
        case articleVersions of
            [] ->
                Nothing

            _ ->
                Just articleVersions
    , locationSorted = { location | location = location.location |> List.sortBy scoreAllowedLocation |> List.reverse }
    , prerequisites = prerequisites |> Maybe.map parsePrequisites |> Maybe.andThen identity
    , conditions = conditions
    , additionalOaFee = additionalOaFee
    , embargo = embargo
    , notes = publicNotes
    }


parsePolicyMetaData : Policy -> PolicyMetaData
parsePolicyMetaData { policyUrl, sherpaPublicationUrl, urls, notes } =
    { policyUrl = policyUrl
    , sherpaPublicationUrl = sherpaPublicationUrl
    , additionalUrls = urls
    , notes = notes
    }


parsePrequisites : Prerequisites -> Maybe (List String)
parsePrequisites { prerequisitesPhrases, prerequisiteSubjects, prerequisiteFunders } =
    -- TODO: add support for prerequisiteFunders
    --       since this consists of name and URL,
    --       this might be difficult to just integrate here
    let
        phrases =
            prerequisitesPhrases
                |> Maybe.map (List.map (\item -> item.phrase))

        subjects =
            prerequisiteSubjects
                |> Maybe.map
                    (\ps ->
                        [ "Manuscript must be from subjects: "
                            ++ String.join ", " ps
                        ]
                    )

        fundersPhrase =
            prerequisiteFunders
                |> Maybe.map (List.map funderName)
                |> Maybe.map (List.filterMap identity)
                |> Maybe.map
                    (\funder ->
                        [ "Work was funded by one of these funders: "
                            ++ String.join ", " funder
                        ]
                    )
    in
    case ( phrases, subjects, fundersPhrase ) of
        ( Nothing, Nothing, Nothing ) ->
            Nothing

        _ ->
            Just
                (Maybe.withDefault [] phrases
                    ++ Maybe.withDefault [] subjects
                    ++ Maybe.withDefault [] fundersPhrase
                )


funderName : Funder -> Maybe String
funderName { funderMetadata } =
    funderMetadata
        |> (\meta -> meta.name)
        |> List.head
        |> Maybe.map (\name -> name.name)


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


viewList : Date -> List ( Int, Paper ) -> Html Msg
viewList today papers =
    section []
        [ h2 []
            [ text "Paywalled with free open access pathway"
            ]
        , p []
            (if List.length papers > 0 then
                [ text
                    ("For the following publications, the publisher appears to allow no-cost open access re-publishing. "
                        ++ "Did we miss an already existing open access version? Let us know."
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
        , div [] (List.map (view today) papers)
        ]


viewPublicationItemInfo : Date -> Paper -> Html Msg
viewPublicationItemInfo today paper =
    div [ class "publications__item__info" ]
        [ div []
            (renderPaperMetaData h3 True paper.meta)
        , div [ class "publications__item__info__pathway" ]
            (renderRecommendedPathway today paper.meta.publishedDate paper.recommendedPathway)
        ]


view : Date -> ( Int, Paper ) -> Html Msg
view today ( id, paper ) =
    div [ class "publications__item" ]
        [ viewPublicationItemInfo today paper
        , renderPathwayButtons ( id, paper.meta )
        ]



-- VIEW ELEMENTS


renderPathwayButtons : ( Int, { a | title : Maybe String, doi : String, recommendShareYourPaper : Bool } ) -> Html Msg
renderPathwayButtons ( id, { title, doi, recommendShareYourPaper } ) =
    let
        paperTitle =
            Maybe.withDefault "Unknown title" title
    in
    div [ class "publications__item__buttons" ]
        -- TODO: Link absolute to URL and not relative
        [ if recommendShareYourPaper then
            a [ href ("/syp?doi=" ++ doi) ]
                [ button
                    [ class "pathway__button--show"
                    , class "pathway__button"
                    , Html.Attributes.title ("Re-publish: " ++ paperTitle)
                    ]
                    [ text "Re-publish" ]
                ]

          else
            a [ href ("/search?query=" ++ doi) ]
                [ button
                    [ class "pathway__button--show"
                    , class "pathway__button"
                    , Html.Attributes.title ("Re-publication details for: " ++ paperTitle)
                    ]
                    [ text "Details" ]
                ]
        ]


embargoUnit : String -> Maybe Unit
embargoUnit unit =
    -- TODO: Move into backend paper parser
    case unit of
        "days" ->
            Just Days

        "weeks" ->
            Just Weeks

        "months" ->
            Just Months

        "years" ->
            Just Years

        _ ->
            Nothing


embargoTimeDeltaString : Date -> Date -> Embargo -> Maybe String
embargoTimeDeltaString today published embargo =
    embargo.units
        |> embargoUnit
        |> Maybe.andThen
            (\unit ->
                if diff unit published today >= embargo.amount then
                    Nothing

                else
                    Just
                        ("for free after "
                            ++ (Date.add unit embargo.amount published |> Date.toIsoString)
                        )
            )


remainingEmbargo : Date -> Maybe Date -> Maybe Embargo -> Maybe String
remainingEmbargo today publishedDate embargo =
    case ( publishedDate, embargo ) of
        ( Just pub, Just emb ) ->
            embargoTimeDeltaString today pub emb

        ( Nothing, Just emb ) ->
            Just (embargoToString emb ++ " after the original publication")

        ( _, Nothing ) ->
            Nothing


renderRecommendedPathway : Date -> Maybe Date -> ( PolicyMetaData, NoCostOaPathway ) -> List (Html Msg)
renderRecommendedPathway today publicationDate ( policy, { articleVersions, conditions, embargo } ) =
    p []
        [ text "You can re-publish the "
        , strong [] [ text (articleVersionString articleVersions ++ " version") ]
        , text " "
        , text
            (embargo
                |> remainingEmbargo today publicationDate
                |> Maybe.withDefault "today for free"
            )
        , text "."
        ]
        :: (conditions
                |> addEmbargo (Maybe.map embargoToString embargo)
                |> Maybe.map (ulWithHeading [ text "Conditions are:" ] text)
                |> Maybe.withDefault [ text "" ]
           )
