module Main exposing (main)

import Browser
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities exposing (..)


type alias Model =
    ()


type alias Flags =
    ()


type Msg
    = NoOp


main : Program Flags Model Msg
main =
    Browser.application
        { init = \_ _ _ -> ( (), Cmd.none )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


view : Model -> Browser.Document Msg
view () =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled body ]
    }


body : Html Msg
body =
    Html.main_
        [ css
            [ p_6
            , text_bluegray_800
            , bg_beige_100
            , flex_grow
            ]
        ]
        [ Html.h1
            [ css
                [ font_title
                , text_4xl
                , font_thin
                ]
            ]
            [ Html.text "Welcome to 🌛 Moon Garden! 🌱" ]
        , Html.p
            [ css
                [ font_body
                , mt_6
                ]
            ]
            [ Html.text "A digital garden / second brain, built on Fission. Please take a seat and plant a seed." ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
