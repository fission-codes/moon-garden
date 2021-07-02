port module Ports exposing (..)

import Json.Decode as Json


port webnativeInit : (Bool -> msg) -> Sub msg


port redirectToLobby : () -> Cmd msg


port persistNote : { noteName : String, noteData : String } -> Cmd msg


port persistedNote : ({ noteName : String, noteData : String } -> msg) -> Sub msg


port loadNote : String -> Cmd msg


port loadedNote : ({ noteName : String, noteData : String } -> msg) -> Sub msg


port loadedNotesLs : (Json.Value -> msg) -> Sub msg
