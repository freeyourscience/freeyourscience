module Msg exposing (Msg(..))

import Animation
import Http
import Papers.Backend exposing (BackendPaper)


type Msg
    = GotPaper (Result Http.Error BackendPaper)
    | Animate Animation.Msg
    | ToggleVisible Int
