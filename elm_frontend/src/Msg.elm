module Msg exposing (Msg(..))

import Animation
import Http
import Papers.Backend as Backend


type Msg
    = GotPaper (Result Http.Error Backend.Paper)
    | Animate Animation.Msg
    | ToggleVisible Int
