module Utils exposing (..)

import Types exposing (..)


optionalYearComparison : Paper -> Paper -> Order
optionalYearComparison p1 p2 =
    let
        y1 =
            Maybe.withDefault 9999999999 p1.year

        y2 =
            Maybe.withDefault 9999999999 p2.year
    in
    compare y2 y1



-- PAPER TYPES


isPaywalledNoCostPathwayPaper : Paper -> Bool
isPaywalledNoCostPathwayPaper p =
    not (Maybe.withDefault True p.isOpenAccess) && Maybe.withDefault "unknown" p.oaPathway == "nocost"


isNonFreePolicyPaper : Paper -> Bool
isNonFreePolicyPaper p =
    not (Maybe.withDefault True p.isOpenAccess) && Maybe.withDefault "unknown" p.oaPathway == "other"


isOpenAccessPaper : Paper -> Bool
isOpenAccessPaper p =
    Maybe.withDefault False p.isOpenAccess


isBuggyPaper : Paper -> Bool
isBuggyPaper p =
    p.isOpenAccess == Nothing || p.oaPathway == Nothing || Maybe.withDefault "unknown" p.oaPathway == "not_found"
