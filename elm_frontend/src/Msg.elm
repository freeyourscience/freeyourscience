module Msg exposing (Msg(..))

import Animation
import Http
import Papers.Backend as Backend
import Papers.Utils exposing (DOI)


type Msg
    = GotPaper (Result Http.Error Backend.Paper)
    | Animate Animation.Msg
    | TogglePathwayVisibility Int DOI
    | HttpNoOp (Result Http.Error ())
