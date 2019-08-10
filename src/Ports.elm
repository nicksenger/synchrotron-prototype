port module Ports exposing (..)

port receiveScrollData : (Float -> msg) -> Sub msg
