port module Ports exposing (..)

-- Send


type alias PlaybackCommand =
    { path : String
    , time : Float
    , rate : Float
    }


port sendActiveHeight : Float -> Cmd msg


port sendPlayback : PlaybackCommand -> Cmd msg


port sendPath : String -> Cmd msg


-- Receive


port receiveScrollData : (Float -> msg) -> Sub msg
