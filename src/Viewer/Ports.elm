port module Viewer.Ports exposing (..)

import Json.Decode as Json


port loadNotesFor : { username : String } -> Cmd msg


port loadedNotesFor : (Json.Value -> msg) -> Sub msg


port loadNote : { username : String, noteName : String } -> Cmd msg


port loadedNote : (Json.Value -> msg) -> Sub msg
