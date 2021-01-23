module Main exposing (..)

import Animation exposing (percent)
import Api exposing (..)
import Array exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import Json.Encode exposing (float)
import Types exposing (..)
import Utils exposing (..)
import Views exposing (..)



-- MODEL


type alias Model =
    { unfetchedDOIs : List DOI
    , fetchedPapers : List Bool
    , freePathwayPapers : Array FreePathwayPaper
    , otherPathwayPapers : List OtherPathwayPaper
    , openAccessPapers : List Paper
    , buggyPapers : List Paper
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
    ( { unfetchedDOIs = Maybe.withDefault [] (List.tail flags.dois)
      , fetchedPapers = []
      , freePathwayPapers = Array.empty
      , otherPathwayPapers = []
      , openAccessPapers = []
      , buggyPapers = []
      , authorName = flags.authorName
      , authorProfileURL = flags.authorProfileURL
      , serverURL = flags.serverURL
      , style = Animation.style [ Animation.width (percent 0), Animation.opacity 1 ]
      }
    , case List.head flags.dois of
        Just nextDOI ->
            fetchPaper flags.serverURL nextDOI

        Nothing ->
            Cmd.none
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
                            , Animation.opacity (toFloat (min 1 (List.length model.unfetchedDOIs)))
                            ]
                        ]
                        model.style
            }

        updateUnfetched m =
            { m | unfetchedDOIs = List.drop 1 model.unfetchedDOIs }

        updateFetched m =
            { m | fetchedPapers = List.append m.fetchedPapers [ True ] }

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
                |> updateUnfetched
                |> updateStyle
                |> updateFetched
            , case List.head model.unfetchedDOIs of
                Just nextDOI ->
                    fetchPaper model.serverURL nextDOI

                Nothing ->
                    Cmd.none
            )

        -- TODO: add the erroneous dois as well?
        GotPaper (Err _) ->
            ( model
                |> updateUnfetched
                |> updateFetched
            , case List.head model.unfetchedDOIs of
                Just nextDOI ->
                    fetchPaper model.serverURL nextDOI

                Nothing ->
                    Cmd.none
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


percentDOIsFetched : Model -> Float
percentDOIsFetched model =
    max
        10
        (100
            * toFloat (List.length model.fetchedPapers)
            / (toFloat (List.length model.fetchedPapers) + toFloat (List.length model.unfetchedDOIs))
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
    policies
        |> flattenPolicies
        |> List.map noCostOaPathway
        |> List.filterMap identity
        |> List.map scoreNoCostPathway
        |> List.sortBy Tuple.first
        |> List.map Tuple.second
        |> List.reverse
        |> List.head


scoreNoCostPathway : ( PolicyMetaData, NoCostOaPathway ) -> ( Float, ( PolicyMetaData, NoCostOaPathway ) )
scoreNoCostPathway ( metaData, pathway ) =
    -- NOTE: It feels like this function should only output a float and it should be the parent
    -- context's responsibility to combine the score with the policy meta data and pathway details
    let
        version_score =
            pathway.articleVersions
                |> List.map scoreAllowedVersion
                |> List.maximum
                |> Maybe.withDefault 0

        location_score =
            pathway.locations
                |> List.map scoreAllowedLocation
                |> List.maximum
                |> Maybe.withDefault 0
    in
    ( version_score + location_score, ( metaData, pathway ) )


scoreAllowedVersion : String -> Float
scoreAllowedVersion version =
    case version of
        "published" ->
            30

        "accepted" ->
            20

        "submitted" ->
            10

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
parsePathway { articleVersions, location, prerequisites, conditions, additionalOaFee, embargo } =
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
    , locations = location |> parseLocations
    , prerequisites = prerequisites |> Maybe.map parsePrequisites
    , conditions = conditions
    , additionalOaFee = additionalOaFee
    , embargo = embargo |> Maybe.map embargoToString
    }


noCostOaPathway : ( PolicyMetaData, Pathway ) -> Maybe ( PolicyMetaData, NoCostOaPathway )
noCostOaPathway ( metadata, pathway ) =
    case ( pathway.additionalOaFee, pathway.locations, pathway.articleVersions ) of
        ( "no", Just locations, Just articleVersions ) ->
            Just
                ( metadata
                , { articleVersions = articleVersions
                  , locations = locations
                  , prerequisites = pathway.prerequisites
                  , conditions = pathway.conditions
                  , embargo = pathway.embargo
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


parseLocations : BackendLocation -> Maybe (List String)
parseLocations { location, namedRepository } =
    let
        locations =
            List.concat [ location, Maybe.withDefault [] namedRepository ]
                |> List.filter (\loc -> loc /= "named_repository")
                |> List.map
                    (\loc ->
                        case loc of
                            "academic_social_network" ->
                                "Academic Social Networks"

                            "non_commercial_repository" ->
                                "Non-commercial Repositories"

                            "authors_homepage" ->
                                "Author's Homepage"

                            a ->
                                String.replace "_" " " a
                    )
    in
    case locations of
        [] ->
            Nothing

        _ ->
            Just locations
