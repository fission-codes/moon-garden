module Main exposing (main)


import Browser
import Html exposing (Html, text, pre, h1)


type alias Model = ()
type alias Flags = ()


type Msg = NoOp


main : Program Flags Model Msg
main =
  Browser.application
      { init = \_ _ _ -> ((), Cmd.none)
      , update = \_ _ -> ((), Cmd.none)
      , subscriptions = subscriptions
      , view = view

      , onUrlChange = \_ -> NoOp
      , onUrlRequest = \_ -> NoOp
      }


view : Model -> Browser.Document Msg
view () =
    { title = "Fission Digital Garden"
    , body = [ body ]
    }

body : Html Msg
body =
  h1 []
      [ text "Welcome to the Fission Digital Garden! 🌱" ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
