port module Ports exposing (..)


port webnativeInit : (Bool -> msg) -> Sub msg


port redirectToLobby : () -> Cmd msg


port persistNote : {noteName : String, noteData : String} -> Cmd msg
