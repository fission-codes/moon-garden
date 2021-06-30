module View exposing (..)

import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)


test : msg -> Html msg
test noOp =
    -- signinScreen { onClickSignIn = noOp }
    loadingScreen { message = "Spinning violently around the y-axis..." }


loadingScreen : { message : String } -> Html msg
loadingScreen element =
    appShellCentered
        [ moonGarden
        , p
            [ css
                [ font_body
                , text_bluegray_700
                , flex
                , flex_col
                , items_center
                , space_y_2
                ]
            ]
            [ span
                [ css
                    [ text_2xl
                    , animate_spin
                    ]
                ]
                [ text "🌕" ]
            , span [] [ text element.message ]
            ]
        ]


signinScreen : { onClickSignIn : msg } -> Html msg
signinScreen element =
    appShellCentered
        [ moonGarden
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
            [ Events.onClick element.onClickSignIn
            , css
                [ px_12
                , py_3
                , leafButtonStyle
                ]
            ]
            [ text "Sign in With Fission" ]
        ]


appShellCentered : List (Html msg) -> Html msg
appShellCentered content =
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
        [ main_
            [ css
                [ max_w_md
                , m_auto
                , flex
                , flex_col
                , items_center
                , space_y_8
                ]
            ]
            content
        ]


moonGarden : Html msg
moonGarden =
    h1
        [ css
            [ text_bluegray_800
            , text_center
            , text_2xl
            , font_title
            , sm [ text_5xl ]
            ]
        ]
        [ text "Moon Garden" ]


leafButtonStyle : Css.Style
leafButtonStyle =
    Css.batch
        [ -- font
          font_button
        , Css.property "font-weight" "100"

        -- colors
        , bg_leaf_600
        , text_white
        , Css.property "box-shadow" "0 0.25rem 0 0 #95A25C"
        , focusable

        -- corners
        , rounded_md
        , rounded_tl_3xl
        , rounded_br_3xl

        -- button press animation
        , transform_gpu
        , translate_y_0
        , Css.property "transition-property" "transform box-shadow"
        , duration_100
        , Css.active
            [ translate_y_1
            , Css.property "box-shadow" "0 0 0 0 #95A25C"
            ]
        ]
