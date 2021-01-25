module Main exposing (..)

import Animation exposing (percent)
import Api exposing (..)
import Array exposing (..)
import Browser
import Debug
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import String.Extra exposing (humanize)
import Types exposing (..)
import Utils exposing (..)
import Views exposing (..)



-- MODEL


type alias Model =
    { initialDOIs : List DOI
    , freePathwayPapers : Array FreePathwayPaper
    , otherPathwayPapers : List OtherPathwayPaper
    , openAccessPapers : List Paper
    , buggyPapers : List Paper
    , numFailedDOIRequests : Int
    , authorName : String
    , authorProfileURL : String
    , serverURL : String
    , style : Animation.State
    }



-- SETUP


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { initialDOIs = flags.dois
      , freePathwayPapers = Array.empty
      , otherPathwayPapers = []
      , openAccessPapers = []
      , buggyPapers = []
      , numFailedDOIRequests = 0
      , authorName = flags.authorName
      , authorProfileURL = flags.authorProfileURL
      , serverURL = flags.serverURL
      , style = Animation.style [ Animation.width (percent 0), Animation.opacity 1 ]
      }
    , Cmd.batch (List.map (fetchPaper flags.serverURL) flags.dois)
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Animate [ model.style ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateStyle m =
            { m
                | style =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.width (percent (percentDOIsFetched model))
                            , Animation.opacity
                                (toFloat
                                    (min 1 (List.length model.initialDOIs - numberFetchedPapers m))
                                )
                            ]
                        ]
                        model.style
            }

        togglePathwayVisibility : Array FreePathwayPaper -> Int -> Array FreePathwayPaper
        togglePathwayVisibility papers id =
            papers
                |> Array.get id
                |> Maybe.map (\p -> { p | pathwayVisible = not p.pathwayVisible })
                |> Maybe.map (\p -> Array.set id p papers)
                |> Maybe.withDefault papers
    in
    case msg of
        GotPaper (Ok backendPaper) ->
            ( model
                |> classifyPaper backendPaper
                |> updateStyle
            , Cmd.none
            )

        GotPaper (Err error) ->
            let
                _ =
                    Debug.log "Error in GotPaper" error
            in
            ( { model | numFailedDOIRequests = model.numFailedDOIRequests + 1 }
            , Cmd.none
            )

        TogglePathwayDisplay paperId ->
            ( { model | freePathwayPapers = togglePathwayVisibility model.freePathwayPapers paperId }
            , Cmd.none
            )

        Animate animMsg ->
            ( { model
                | style = Animation.update animMsg model.style
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    let
        indexedPapersYearComp : ( Int, { a | year : Maybe Int } ) -> ( Int, { a | year : Maybe Int } ) -> Order
        indexedPapersYearComp ( _, p1 ) ( _, p2 ) =
            optionalYearComparison p1 p2

        paywalledNoCostPathwayPapers =
            List.sortWith indexedPapersYearComp (Array.toIndexedList model.freePathwayPapers)

        nonFreePolicyPapers =
            List.sortWith optionalYearComparison model.otherPathwayPapers

        openAccessPapers =
            List.sortWith optionalYearComparison model.openAccessPapers

        buggyPapers =
            List.sortWith optionalYearComparison model.buggyPapers
    in
    div []
        [ span
            [ class "container"
            , class "progressbar__container"
            ]
            [ span (Animation.render model.style ++ [ class "progressbar_progress" ]) [ text "" ] ]
        , main_ []
            [ renderPaywalledNoCostPathwayPapers paywalledNoCostPathwayPapers
            , renderNonFreePolicyPapers nonFreePolicyPapers
            , renderOpenAccessPapers openAccessPapers
            , renderBuggyPapers buggyPapers
            ]
        , renderFooter model.authorProfileURL
        ]



-- LOADING BAR


numberFetchedPapers : Model -> Int
numberFetchedPapers model =
    List.length model.buggyPapers
        + Array.length model.freePathwayPapers
        + List.length model.openAccessPapers
        + List.length model.otherPathwayPapers
        + model.numFailedDOIRequests


percentDOIsFetched : Model -> Float
percentDOIsFetched model =
    -- Report at least 10 percent at all times to provide immediate loading feedback.
    max
        10
        (100
            * (model |> numberFetchedPapers |> toFloat)
            / (model.initialDOIs |> List.length |> toFloat)
        )



-- BACKEND-PAPER >>> PAPER


classifyPaper : BackendPaper -> Model -> Model
classifyPaper backendPaper model =
    let
        paper =
            toPaper backendPaper

        isOpenAccess =
            paper.isOpenAccess

        oaPathway =
            Maybe.map2 Tuple.pair
                paper.oaPathway
                paper.oaPathwayURI

        recommendedPathway =
            Maybe.andThen parsePolicies backendPaper.pathwayDetails
    in
    case ( isOpenAccess, oaPathway, recommendedPathway ) of
        ( Just False, Just ( "nocost", pwUri ), Just pathway ) ->
            { doi = backendPaper.doi
            , title = backendPaper.title
            , journal = backendPaper.journal
            , authors = backendPaper.authors
            , year = backendPaper.year
            , issn = backendPaper.issn
            , oaPathwayURI = pwUri
            , recommendedPathway = pathway
            , pathwayVisible = False
            }
                |> (\p -> { model | freePathwayPapers = Array.push p model.freePathwayPapers })

        ( Just False, Just ( "other", pwUri ), Nothing ) ->
            { doi = backendPaper.doi
            , title = backendPaper.title
            , journal = backendPaper.journal
            , authors = backendPaper.authors
            , year = backendPaper.year
            , issn = backendPaper.issn
            , oaPathwayURI = pwUri
            }
                |> (\p -> { model | otherPathwayPapers = model.otherPathwayPapers ++ [ p ] })

        ( Just True, _, _ ) ->
            { model | openAccessPapers = model.openAccessPapers ++ [ paper ] }

        _ ->
            { model | buggyPapers = model.buggyPapers ++ [ paper ] }


toPaper : BackendPaper -> Paper
toPaper backendPaper =
    { doi = backendPaper.doi
    , title = backendPaper.title
    , journal = backendPaper.journal
    , authors = backendPaper.authors
    , year = backendPaper.year
    , issn = backendPaper.issn
    , isOpenAccess = backendPaper.isOpenAccess
    , oaPathway = backendPaper.oaPathway
    , oaPathwayURI = backendPaper.oaPathwayURI
    , recommendedPathway = Maybe.andThen parsePolicies backendPaper.pathwayDetails
    }


parsePolicies : List BackendPolicy -> Maybe ( PolicyMetaData, NoCostOaPathway )
parsePolicies policies =
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
