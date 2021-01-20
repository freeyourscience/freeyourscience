module Utils exposing (..)

import Types exposing (..)


optionalYearComparison : { a | year : Maybe Int } -> { a | year : Maybe Int } -> Order
optionalYearComparison p1 p2 =
    let
        y1 =
            Maybe.withDefault 9999999999 p1.year

        y2 =
            Maybe.withDefault 9999999999 p2.year
    in
    compare y2 y1
