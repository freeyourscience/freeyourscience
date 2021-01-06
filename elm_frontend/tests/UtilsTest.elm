module UtilsTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Http exposing (Expect)
import Test exposing (..)
import Types exposing (Paper)
import Utils exposing (isNonFreePolicyPaper, isPaywalledNoCostPathwayPaper)


fullPaper : Paper
fullPaper =
    Paper "10.100/dummy.doi"
        (Just "The best paper title")
        (Just "Abc Journal")
        (Just "Bob Ross et al.")
        (Just 2020)
        (Just "1234-1234")
        (Just False)
        (Just "nocost")
        (Just "#")
        (Just
            { articleVersion = "accepted"
            , locations = [ "Academic Social Network", "Author's Homepage" ]
            , prerequisites = [ "If Required by Institution", "12 months have passed since publication" ]
            , conditions = [ "Must be accompanied by set statement (see policy)", "Must link to publisher version" ]
            , notes = [ "If mandated to deposit before 12 months, the author must obtain a  waiver from their Institution/Funding agency or use  AuthorChoice" ]
            , urls = [ { description = "Best Page Ever", url = "https://freeyourscience.org" } ]
            , policyUrl = "https://freeyourscience.org"
            }
        )


suite : Test
suite =
    describe "Testing the paper filter functions"
        [ describe "paywalled no cost, main category"
            [ test "Correctly identify nocost paywalled" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just False, oaPathway = Just "nocost" }
                    in
                    Expect.equal True (isPaywalledNoCostPathwayPaper paper)
            , test "Correctly identify other & paywalled" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just False, oaPathway = Just "other" }
                    in
                    Expect.equal False (isPaywalledNoCostPathwayPaper paper)
            , test "Correctly identify not found & paywalled" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just False, oaPathway = Just "not_found" }
                    in
                    Expect.equal False (isPaywalledNoCostPathwayPaper paper)
            , test "Correctly identify not found & open access" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just True, oaPathway = Just "other" }
                    in
                    Expect.equal False (isPaywalledNoCostPathwayPaper paper)
            ]
        , describe "paywalled cost or other"
            [ test "Correctly identify other oa policy" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just False, oaPathway = Just "other" }
                    in
                    Expect.equal True (isNonFreePolicyPaper paper)
            , test "Correctly identify oa policy not found" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just False, oaPathway = Just "not_found" }
                    in
                    Expect.equal False (isNonFreePolicyPaper paper)
            , test "Correctly identify oa policy not attempted" <|
                \_ ->
                    let
                        paper =
                            { fullPaper | isOpenAccess = Just False, oaPathway = Just "not_attempted" }
                    in
                    Expect.equal False (isNonFreePolicyPaper paper)
            ]
        ]
