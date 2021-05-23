module FreePathwayTest exposing (..)

import Date
import Expect
import Papers.FreePathway exposing (embargoTimeDeltaString, remainingEmbargo)
import Test exposing (Test, describe, test)
import Time exposing (Month(..))


suite : Test
suite =
    describe "free pathway tests"
        [ describe "embargoTimeDeltaString"
            [ test "embargo passed" <|
                let
                    publishedDate =
                        Date.fromCalendarDate 2018 Sep 4

                    today =
                        Date.fromCalendarDate 2021 May 24

                    embargo =
                        { units = "months", amount = 12 }
                in
                \_ ->
                    Expect.equal
                        Nothing
                        (embargoTimeDeltaString today publishedDate embargo)
            ]
        , describe "remainingEmbargo"
            [ test "embargo passed" <|
                let
                    publishedDate =
                        Just (Date.fromCalendarDate 2020 Jan 2)

                    today =
                        Date.fromCalendarDate 2021 Jan 1

                    embargo =
                        Just { units = "months", amount = 11 }
                in
                \_ ->
                    Expect.equal
                        Nothing
                        (remainingEmbargo today publishedDate embargo)
            , test "embargo about to pass" <|
                let
                    publishedDate =
                        Just (Date.fromCalendarDate 2020 Jan 2)

                    today =
                        Date.fromCalendarDate 2021 Jan 1

                    embargo =
                        Just { units = "months", amount = 12 }
                in
                \_ ->
                    Expect.equal
                        (Just "for free after 2021-01-02")
                        (remainingEmbargo today publishedDate embargo)
            , test "no embargo" <|
                let
                    publishedDate =
                        Just (Date.fromCalendarDate 2020 Jan 2)

                    today =
                        Date.fromCalendarDate 2021 Jan 1

                    embargo =
                        Nothing
                in
                \_ ->
                    Expect.equal
                        Nothing
                        (remainingEmbargo today publishedDate embargo)
            , test "no published date" <|
                let
                    publishedDate =
                        Nothing

                    today =
                        Date.fromCalendarDate 2021 Jan 1

                    embargo =
                        Just { units = "months", amount = 12 }
                in
                \_ ->
                    Expect.equal
                        (Just "12 months after the original publication")
                        (remainingEmbargo today publishedDate embargo)
            , test "days embargo" <|
                let
                    publishedDate =
                        Just (Date.fromCalendarDate 2020 Jan 3)

                    today =
                        Date.fromCalendarDate 2021 Jan 1

                    embargo =
                        Just { units = "days", amount = 365 }
                in
                \_ ->
                    Expect.equal
                        (Just "for free after 2021-01-02")
                        (remainingEmbargo today publishedDate embargo)
            , test "years embargo" <|
                let
                    publishedDate =
                        Just (Date.fromCalendarDate 2020 Jan 3)

                    today =
                        Date.fromCalendarDate 2021 Jan 1

                    embargo =
                        Just { units = "years", amount = 1 }
                in
                \_ ->
                    Expect.equal
                        (Just "for free after 2021-01-03")
                        (remainingEmbargo today publishedDate embargo)
            ]
        ]
