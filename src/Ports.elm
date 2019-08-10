port module Ports exposing (..)


-- Send


port sendActiveHeight : Float -> Cmd msg


-- Receive


port receiveScrollData : (Float -> msg) -> Sub msg
