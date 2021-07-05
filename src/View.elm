module View exposing (..)

import Css
import Css.Media
import FeatherIcons
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, href, id, placeholder, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)


appName : String
appName =
    "Moon Garden"


loadingScreen : { message : String, isError : Bool } -> Html msg
loadingScreen element =
    appShellCentered
        [ titleText [ text_center ] appName
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
            [ if element.isError then
                span [ css [ text_2xl ] ]
                    [ text "😳" ]

              else
                span [ css [ text_2xl, animate_spin ] ]
                    [ text "🌕" ]
            , span [] [ text element.message ]
            ]
        ]


signinScreen : { onClickSignIn : msg } -> Html msg
signinScreen element =
    appShellCentered
        [ titleText [ text_center ] appName
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


{-| The default scroll position for the app shell with a
sidebar is going to be to the far left - thus you'll see
the navigation first.

Thus, the main section has an 'id' set to this value.
Use this to potentially set the scroll position or set
the url to `something ++ #<appShellSidebarMainSectionId>`.

-}
appShellSidebarMainSectionId : String
appShellSidebarMainSectionId =
    "main"


appShellSidebar :
    { navigation : List (Html msg)
    , main : List (Html msg)
    }
    -> Html msg
appShellSidebar element =
    div
        [ css
            [ bg_beige_100
            , flex
            , flex_row
            , flex_grow
            , flex_shrink_0
            , overflow_x_auto
            , Css.property "scroll-snap-type" "x mandatory"
            ]
        ]
        [ nav
            [ css
                [ w_64
                , py_6
                , flex_shrink_0
                , Css.property "scroll-snap-align" "start"
                , overflow_y_auto
                , flex
                , flex_col
                , max_h_screen
                , xl
                    [ Css.property "margin-left" "calc(50vw - 16rem - 384px)"
                    ]
                ]
            ]
            [ div
                [ css
                    [ border_beige_300
                    , border_r_4
                    , px_5
                    , flex
                    , flex_col
                    , flex_grow
                    ]
                ]
                element.navigation
            ]
        , section
            [ id appShellSidebarMainSectionId
            , css
                [ p_6
                , flex
                , flex_col
                , flex_grow
                , flex_shrink_0
                , h_full
                , w_screen
                , Css.property "scroll-snap-align" "start"
                , overflow_y_auto
                , max_h_screen
                , sm
                    [ w_auto
                    , flex_shrink
                    ]
                , xl
                    [ mr_auto
                    , max_w_screen_md
                    ]
                ]
            ]
            element.main
        ]


appShellColumn : List (Html msg) -> Html msg
appShellColumn content =
    div
        [ css
            [ bg_beige_100
            , items_center
            , flex
            , flex_col
            , flex_grow
            , flex_shrink_0
            , py_6
            , sm [ pt_12 ]
            ]
        ]
        [ main_
            [ css
                [ max_w_xl
                , w_full
                , mx_auto
                , flex
                , flex_col
                , flex_grow
                , space_y_8
                , px_6
                ]
            ]
            content
        ]


titleText : List Css.Style -> String -> Html msg
titleText styles content =
    h1
        [ css
            [ Css.batch styles
            , text_bluegray_800
            , text_3xl
            , font_title
            , sm [ text_4_dot_5xl ]
            ]
        ]
        [ text content ]


subtitleText : List Css.Style -> String -> Html msg
subtitleText styles content =
    h2
        [ css
            [ Css.batch styles
            , text_bluegray_800
            , text_2xl
            , font_title
            , sm [ text_3xl ]
            ]
        ]
        [ text content ]


paragraph : List Css.Style -> List (Html msg) -> Html msg
paragraph styles content =
    p
        [ css
            [ Css.batch styles
            , font_body
            , text_bluegray_800
            ]
        ]
        content


searchInput :
    { onInput : String -> msg
    , placeholder : String
    , styles : List Css.Style
    }
    -> Html msg
searchInput element =
    div
        [ css
            [ relative
            , flex
            , flex_col
            , Css.batch element.styles
            ]
        ]
        [ input
            [ type_ "text"
            , placeholder element.placeholder
            , Events.onInput element.onInput
            , css
                [ px_4
                , py_3
                , rounded_md
                , bg_beige_200
                , text_bluegray_800
                , focusable
                , font_mono
                , Css.pseudoElement "placeholder"
                    [ text_beige_400
                    ]
                ]
            ]
            []
        , FeatherIcons.search
            |> FeatherIcons.withSize 20
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span
                [ css
                    [ text_beige_400
                    , my_auto
                    ]
                ]
            |> List.singleton
            |> div
                [ css
                    [ absolute
                    , pointer_events_none
                    , right_4
                    , inset_y_0
                    , flex
                    , flex_row
                    ]
                ]
        ]


searchGrid : List (Html msg) -> Html msg
searchGrid content =
    ul
        [ css
            [ grid
            , gap_3
            , grid_cols_1
            , Css.Media.withMediaQuery [ "(min-width: 580px)" ]
                [ grid_cols_3 ]
            , Css.Media.withMediaQuery [ "(min-width: 360px)" ]
                [ grid_cols_2 ]
            ]
        ]
        content


searchResults : List (Html msg) -> Html msg
searchResults content =
    ul
        [ css
            [ flex
            , flex_col
            , space_y_4
            , mt_4
            ]
        ]
        (List.map
            (\item -> li [ css [ flex, flex_row ] ] [ item ])
            content
        )


referencedNoteCard :
    { label : String
    , link : String
    , styles : List Css.Style
    }
    -> Html msg
referencedNoteCard element =
    a
        [ href element.link
        , css
            [ Css.batch element.styles
            , rounded_md
            , bg_beige_200
            , px_4
            , py_3
            , focusable
            , font_body
            , text_bluegray_800
            , transform_gpu
            , transition_transform
            , Css.active
                [ scale_95 ]
            ]
        ]
        [ text element.label ]


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


leafyButton : { label : String, onClick : msg } -> Html msg
leafyButton element =
    button
        [ Events.onClick element.onClick
        , css
            [ leafButtonStyle
            , py_3
            , mb_1
            ]
        ]
        [ text element.label ]


titleInput :
    { onInput : String -> msg
    , value : String
    , styles : List Css.Style
    }
    -> Html msg
titleInput element =
    input
        [ type_ "text"
        , placeholder "Enter a Title"
        , value element.value
        , Events.onInput element.onInput
        , css
            [ Css.batch element.styles
            , w_full
            , bg_transparent
            , text_3xl
            , text_bluegray_800
            , font_title
            , Css.pseudoElement "placeholder"
                [ text_beige_400
                ]
            , sm
                [ text_4xl
                ]
            ]
        ]
        []


editorTextareaStyle : Css.Style
editorTextareaStyle =
    Css.batch
        [ Css.property "min-height" "16rem"
        , mt_8
        ]


autoresizeTextarea :
    { onChange : String -> msg
    , content : String
    , styles : List Css.Style
    }
    -> Html msg
autoresizeTextarea element =
    div
        [ Events.onInput element.onChange
        , css
            [ Css.batch element.styles
            , w_full
            , relative
            , font_mono
            , text_base
            , leading_normal
            , flex
            , flex_col
            , flex_shrink_0
            ]
        ]
        [ pre
            [ css
                [ flex_grow
                , flex_shrink_0
                , text_transparent
                , pointer_events_none
                , whitespace_pre_wrap
                ]
            ]
            [ text element.content
            , text "\n"
            ]
        , textarea
            [ placeholder "Start writing markdown and use [[wikilinks]]"
            , value element.content
            , css
                [ bg_transparent
                , text_gray_900
                , absolute
                , inset_0
                , w_full
                , h_full
                , resize_none
                , Css.pseudoElement "placeholder"
                    [ text_beige_400
                    ]
                ]
            ]
            [ text element.content ]
        ]


wikilinksSection :
    { styles : List Css.Style
    , wikilinks : List (Html msg)
    }
    -> Html msg
wikilinksSection element =
    section
        []
        [ h3
            [ css
                [ Css.batch element.styles
                , text_2xl
                , text_bluegray_800
                , font_title
                ]
            ]
            [ text "Wikilinks" ]
        , ul
            [ css
                [ flex
                , flex_col
                , mt_3
                , space_y_1
                , items_start
                ]
            ]
            element.wikilinks
        ]


wikilinkExisting : { label : String, link : String } -> Html msg
wikilinkExisting element =
    a
        [ href element.link
        , css
            [ text_bluegray_800
            , font_body
            , p_2
            , relative
            , z_0
            , Css.visited
                [ Css.pseudoElement "before"
                    [ bg_rose_300
                    ]
                ]
            , Css.hover
                [ Css.pseudoElement "before"
                    [ top_2 ]
                ]
            , Css.pseudoElement "before"
                [ Css.property "content" "''"
                , Css.property "z-index" "-1"
                , absolute
                , bg_moon_200
                , bottom_2
                , inset_x_2
                , Css.property "top" "56%"
                , transition_all
                , duration_200
                ]
            ]
        ]
        [ text element.label ]


wikilinkNew : { label : String, onClickCreate : msg } -> Html msg
wikilinkNew element =
    span
        [ Events.onClick element.onClickCreate
        , css
            [ flex
            , flex_row
            , items_center
            , text_bluegray_800
            , font_body
            , p_2
            , rounded_md
            , transform_gpu
            , Css.property "transition-properties" "colors transform"
            , duration_200
            , cursor_pointer
            , Css.hover
                [ bg_beige_200 ]
            , Css.active
                [ scale_95 ]
            ]
        ]
        [ span [] [ text element.label ]
        , FeatherIcons.plus
            |> FeatherIcons.withSize 20
            |> FeatherIcons.toHtml []
            |> fromUnstyled
            |> List.singleton
            |> span
                [ css
                    [ text_bluegray_800
                    , ml_1
                    ]
                ]
        ]
