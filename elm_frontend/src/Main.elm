module Main exposing (main)

import Animation exposing (percent)
import Array exposing (Array)
import BackendPaper exposing (BackendEmbargo, BackendLocation, BackendPaper, BackendPermittedOA, BackendPolicy, BackendPrerequisites, paperDecoder)
import Browser
import Browser.Events exposing (Visibility(..))
import Debug
import GeneralTypes exposing (DOI, NamedUrl)
import Html exposing (..)
import Html.Attributes exposing (alt, class, height, href, src, target, title, width)
import Html.Events exposing (..)
import Http
import HttpBuilder exposing (withHeader)
import String.Extra exposing (humanize)



-- MAIN
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



-- API


fetchPaper : String -> String -> Cmd Msg
fetchPaper serverURL doi =
    HttpBuilder.get (serverURL ++ "/api/papers?doi=" ++ doi)
        |> withHeader "Content-Type" "application/json"
        |> HttpBuilder.withExpect (Http.expectJson GotPaper paperDecoder)
        |> HttpBuilder.request



-- TYPES
-- INPUT DATA


type alias Flags =
    { dois : List String
    , serverURL : String
    , authorName : String
    , authorProfileURL : String
    }



-- MODEL


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
    , recommendedPathway : Maybe ( PolicyMetaData, NoCostOaPathway )
    }


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


type alias OtherPathwayPaper =
    { doi : DOI
    , title : Maybe String
    , journal : Maybe String
    , authors : Maybe String
    , year : Maybe Int
    , issn : Maybe String
    , oaPathwayURI : String
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



-- MSG


type Msg
    = GotPaper (Result Http.Error BackendPaper)
    | TogglePathwayDisplay Int
    | Animate Animation.Msg



-- UTILS


optionalYearComparison : { a | year : Maybe Int } -> { a | year : Maybe Int } -> Order
optionalYearComparison p1 p2 =
    let
        y1 =
            Maybe.withDefault 9999999999 p1.year

        y2 =
            Maybe.withDefault 9999999999 p2.year
    in
    compare y2 y1



-- Views


ulWithHeading : String -> (a -> Html Msg) -> List a -> List (Html Msg)
ulWithHeading heading renderElement list =
    let
        renderedList =
            list
                |> List.map renderElement
                |> renderList
    in
    [ p [] [ text heading ]
    , renderedList
    ]


renderList : List (Html Msg) -> Html Msg
renderList list =
    ul []
        (List.map
            (\item -> li [] [ item ])
            list
        )


renderUrl : NamedUrl -> Html Msg
renderUrl { url, description } =
    a [ href url, class "link", class "link-secondary" ] [ text description ]



-- PAPER


renderOpenAccessPaper : Paper -> Html Msg
renderOpenAccessPaper paper =
    let
        isOpenAccess =
            Maybe.withDefault False paper.isOpenAccess
    in
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class
                ("paper-details col-12 fs-6 mb-2 mb-md-0"
                    ++ (if isOpenAccess then
                            ""

                        else
                            " col-md-9"
                       )
                )
            ]
            [ renderPaperHeader paper ]
        ]


renderFreePathwayPaper : ( Int, FreePathwayPaper ) -> Html Msg
renderFreePathwayPaper ( id, { pathwayVisible, recommendedPathway } as paper ) =
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
                (renderNarrowPaperHeader paper)
            , div [ class pathwayClass ]
                (renderRecommendedPathway paper.oaPathwayURI recommendedPathway)
            ]
        , div [ class "col-12 col-md-3 fs-6 text-md-end" ]
            (renderPathwayButtons pathwayVisible ( id, paper.title ))
        ]


renderNonFreePathwayPaper : OtherPathwayPaper -> Html Msg
renderNonFreePathwayPaper paper =
    div [ class "row mb-3 author-pubs mb-4 pt-3 border-top" ]
        [ div
            [ class "paper-details col-12 fs-6 mb-2 mb-md-0 col-md-9" ]
            (renderNarrowPaperHeader paper)
        ]


type alias PaperMeta a =
    { a
        | doi : DOI
        , title : Maybe String
        , authors : Maybe String
        , year : Maybe Int
        , journal : Maybe String
    }


renderNarrowPaperHeader : PaperMeta a -> List (Html Msg)
renderNarrowPaperHeader { title, journal, authors, year, doi } =
    [ div [ class "fs-5 mb-1" ] [ text (Maybe.withDefault "Unknown title" title) ]
    , div [ class "mb-1" ]
        [ text
            (String.concat
                [ journal |> Maybe.withDefault "Unknown journal"
                , ", "
                , authors |> Maybe.withDefault "Unknown authors"
                , " ("
                , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                , "), "
                , doi
                ]
            )
        , a [ href ("https://doi.org/" ++ doi), class "link-secondary", target "_blank" ]
            [ img
                [ src "/static/img/box-arrow-up-right.svg"
                , alt ""
                , width 12
                , height 12
                , Html.Attributes.title ("Visit article: " ++ Maybe.withDefault "" title)
                ]
                []
            ]
        ]
    ]


renderPaperHeader : Paper -> Html Msg
renderPaperHeader ({ journal, authors, year, doi } as paper) =
    let
        paperTitle =
            paper.title

        isOpenAccess =
            Maybe.withDefault False paper.isOpenAccess
    in
    div
        [ class
            ("paper-details col-12 fs-6 mb-2 mb-md-0"
                ++ (if isOpenAccess then
                        ""

                    else
                        " col-md-9"
                   )
            )
        ]
        [ div [ class "fs-5 mb-1" ] [ text (Maybe.withDefault "Unknown title" paperTitle) ]
        , div [ class "mb-1" ]
            [ text
                (String.concat
                    [ journal |> Maybe.withDefault "Unknown journal"
                    , ", "
                    , authors |> Maybe.withDefault "Unknown authors"
                    , " ("
                    , year |> Maybe.map String.fromInt |> Maybe.withDefault ""
                    , "), "
                    , doi
                    ]
                )
            , a [ href ("https://doi.org/" ++ doi), class "link-secondary", target "_blank" ]
                [ img
                    [ src "/static/img/box-arrow-up-right.svg"
                    , alt ""
                    , width 12
                    , height 12
                    , title ("Visit article: " ++ Maybe.withDefault "" paperTitle)
                    ]
                    []
                ]
            ]
        ]


renderPathwayButtons : Bool -> ( Int, Maybe String ) -> List (Html Msg)
renderPathwayButtons pathwayIsVisible ( id, title ) =
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
            [ onClick (TogglePathwayDisplay id)
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



-- PAPER SECTIONS


renderPaywalledNoCostPathwayPapers : List ( Int, FreePathwayPaper ) -> Html Msg
renderPaywalledNoCostPathwayPapers papers =
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
        , div [] (List.map renderFreePathwayPaper papers)
        ]


renderNonFreePolicyPapers : List OtherPathwayPaper -> Html Msg
renderNonFreePolicyPapers papers =
    if List.isEmpty papers then
        text ""

    else
        section [ class "mb-5" ]
            [ h2 []
                [ text "Publications with non-free publisher policies"
                ]
            , p [ class "fs-6 mb-4" ]
                [ text
                    ("The following publications do not seem to have any no-cost Open Access "
                        ++ "re-publishing pathways, or do not allow Open Access publishing at all."
                    )
                ]
            , div [] (List.map renderNonFreePathwayPaper papers)
            ]


renderOpenAccessPapers : List Paper -> Html Msg
renderOpenAccessPapers papers =
    section [ class "mb-5" ]
        [ h2 [ class "mb-3" ]
            [ text "Open Access publications"
            ]
        , if List.isEmpty papers then
            p []
                [ text "We could not find any of your Open Access publications in the unpaywall.org database."
                , br [] []
                , text "In case you think there should be Open Access publications here, help "
                , a [ href "https://unpaywall.org/sources", target "_blank" ] [ text "unpaywall.org" ]
                , text " to find them."
                ]

          else
            div [] (List.map renderOpenAccessPaper papers)
        ]


renderBuggyPapers : List Paper -> Html Msg
renderBuggyPapers papers =
    if List.isEmpty papers then
        text ""

    else
        section [ class "mb-5" ]
            [ h2 []
                [ text "Publications we had issues with"
                ]
            , div [ class "container" ]
                (List.map
                    (\p ->
                        div []
                            [ a [ href ("https://doi.org/" ++ p.doi), target "_blank", class "link-secondary" ]
                                [ text p.doi
                                ]
                            , case p.oaPathway of
                                Just _ ->
                                    text (" (unknown publisher policy for: " ++ Maybe.withDefault "Unknown Journal" p.journal ++ ")")

                                _ ->
                                    text ""
                            ]
                    )
                    papers
                )
            ]



-- SOURCE PROFILE


renderFooter : String -> Html Msg
renderFooter authorProfileURL =
    footer [ class "container text-center m-4" ]
        [ small []
            [ text "("
            , a [ href authorProfileURL, target "_blank", class "link-dark" ]
                [ text "Source Profile"
                ]
            , text " that was used to retreive the author's papers.)"
            ]
        ]
