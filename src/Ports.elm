port module Ports exposing (..)


port webnativeInit : (Bool -> msg) -> Sub msg


port redirectToLobby : () -> Cmd msg
