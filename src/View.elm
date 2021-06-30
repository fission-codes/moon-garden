module View exposing (..)

import Css
import FeatherIcons
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, href, id, placeholder, type_, value)
import Html.Styled.Events as Events
import Tailwind.Breakpoints exposing (..)
import Tailwind.Utilities exposing (..)


test : msg -> Html msg
test noOp =
    -- signinScreen { onClickSignIn = noOp }
    -- loadingScreen { message = "Spinning violently around the y-axis...", isError = True }
    appShellSidebar
        { navigation =
            List.concat
                [ [ buttonCreateNewNote { onClick = noOp }
                  , searchInput
                        { styles = [ mt_8 ]
                        , onInput = \_ -> noOp
                        }
                  ]
                , List.map
                    (\result ->
                        searchResult
                            { label = result
                            , link = "#" ++ appShellSidebarMainSectionId
                            , styles = [ mt_4 ]
                            }
                    )
                    [ "Moon Garden"
                    , "Markdown"
                    , "WNFS"
                    , "Wikilinks"
                    , "Geometric Algebra for Computer Science"
                    ]
                ]
        , main =
            [ titleInput
                { onInput = \_ -> noOp
                , value = ""
                , styles = []
                }
            , autoresizeTextarea
                { onChange = \_ -> noOp
                , content = ""
                , styles =
                    [ Css.property "min-height" "16rem"
                    , mt_8
                    ]
                }
            ]
        }


loadingScreen : { message : String, isError : Bool } -> Html msg
loadingScreen element =
    appShellCentered
        [ moonGardenTitle
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
        [ moonGardenTitle
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


moonGardenTitle : Html msg
moonGardenTitle =
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


searchInput :
    { onInput : String -> msg
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
            , placeholder "Type to Search"
            , Events.onInput element.onInput
            , css
                [ px_4
                , py_3
                , rounded_md
                , bg_beige_200
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


searchResult :
    { label : String
    , link : String
    , styles : List Css.Style
    }
    -> Html msg
searchResult element =
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


buttonCreateNewNote : { onClick : msg } -> Html msg
buttonCreateNewNote element =
    button
        [ Events.onClick element.onClick
        , css
            [ leafButtonStyle
            , py_3
            ]
        ]
        [ text "Create New Note" ]


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
            ]
        ]
        [ pre
            [ css
                [ flex_grow
                , flex_shrink_0
                , text_transparent
                , pointer_events_none
                ]
            ]
            [ text element.content
            , text "\n"
            ]
        , textarea
            [ placeholder "Start writing markdown and use [[wikilinks]]"
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
