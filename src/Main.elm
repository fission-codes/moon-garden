module Main exposing (main)

import Browser
import Html exposing (Html, text, pre, h1)


type alias Model = ()
type alias Flags = ()


type Msg = NoOp


main : Program Flags Model Msg
main =
  Browser.element
      { init = \_ -> ((), Cmd.none)
      , update = (\_ _ -> ((), Cmd.none))
      , subscriptions = subscriptions
      , view = view
      }


view : Model -> Html Msg
view () =
  h1 []
      [ text "Welcome to the Fission Digital Garden 🌱" ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
