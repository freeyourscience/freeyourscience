module Msg exposing (Msg(..))

import Animation
import Date exposing (Date)
import Http
import Papers.Backend as Backend


type Msg
    = GotPaper (Result Http.Error Backend.Paper)
    | Animate Animation.Msg
    | HttpNoOp (Result Http.Error ())
    | ReceiveDate Date
