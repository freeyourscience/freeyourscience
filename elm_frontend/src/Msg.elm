module Msg exposing (FreePathwayPaperMsg(..), MainMsg(..), Msg(..))

import Animation
import BackendPaper exposing (BackendPaper)
import Http


type Msg
    = MsgForMain MainMsg
    | MsgForFreePathwayPaper FreePathwayPaperMsg



-- MAIN


type MainMsg
    = GotPaper (Result Http.Error BackendPaper)
    | Animate Animation.Msg



-- FREEPATHWAYPAPER


type FreePathwayPaperMsg
    = ToggleVisible Int
