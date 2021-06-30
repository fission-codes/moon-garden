module View exposing (view)

import Browser
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Ports
import Tailwind.Utilities exposing (..)

import Model exposing (Model)
import Msg exposing (Msg)

view : Model -> Browser.Document Msg
view model =
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
