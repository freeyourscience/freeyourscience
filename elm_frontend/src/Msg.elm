module Msg exposing (Msg(..))

import Animation
import BackendPaper exposing (BackendPaper)
import Http


type Msg
    = GotPaper (Result Http.Error BackendPaper)
    | Animate Animation.Msg
    | ToggleVisible Int
