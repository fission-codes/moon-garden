module View exposing (..)

import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities exposing (..)


test : Html msg
test =
    signinScreen


signinScreen : Html msg
signinScreen =
    div
        [ css
            [ bg_beige_100
            , items_center
            , flex
            , flex_col
            , flex_grow
            , flex_shrink_0
            ]
        ]
        [ section
            [ css
                [ max_w_md
                , m_auto
                , flex
                , flex_col
                , items_center
                , space_y_8
                ]
            ]
            [ h1
                [ css
                    [ text_bluegray_800
                    , text_center
                    , text_5xl
                    , font_title
                    ]
                ]
                [ text "Moon Garden" ]
            , p
                [ css
                    [ text_bluegray_800
                    , text_center
                    , font_body
                    ]
                ]
                [ text "is a digital garden app built on the Fission Platform."
                , br [] []
                , br [] []
                , text "Start your own digital garden by logging in to your fission account or creating a new one:"
                ]
            , button
                [ css
                    [ font_button
                    , Css.property "font-weight" "100"
                    , bg_leaf_600
                    , text_white
                    , px_12
                    , py_3
                    , rounded_md
                    , rounded_tl_3xl
                    , rounded_br_3xl
                    , transform_gpu
                    , translate_y_0
                    , Css.property "transition-property" "transform box-shadow"
                    , duration_100
                    , Css.property "box-shadow" "0 0.25rem 0 0 #95A25C"
                    , Css.active
                        [ translate_y_1
                        , Css.property "box-shadow" "0 0 0 0 #95A25C"
                        ]
                    ]
                ]
                [ text "Sign in With Fission" ]
            ]
        ]
