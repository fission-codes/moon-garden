port module Ports exposing (..)

import Json.Decode as Json


port webnativeInit : (Bool -> msg) -> Sub msg


port redirectToLobby : () -> Cmd msg


port persistNote : { noteName : String, noteData : String } -> Cmd msg


port loadedNotesLs : (Json.Value -> msg) -> Sub msg
