module Msg exposing (Msg(..))

import FreePathwayPaperMsg
import MainMsg


type Msg
    = MsgForMain MainMsg.Msg
    | MsgForFreePathwayPaper FreePathwayPaperMsg.Msg
