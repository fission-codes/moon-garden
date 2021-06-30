module Main exposing (main)

import Browser
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Ports
import Tailwind.Utilities exposing (..)


-- 🔠 ---------------------------------------------------------------------------


type Model
    = Unauthed Unauthenticated
    | Authenticated


type Unauthenticated
    = Loading
    | Cancelled
    | SignIn


type Msg
    = NoOp -- FIXME Replace with navigation messages
    | WebnativeSignIn
    | WebnativeInit Bool


type alias Flags =
    ()


-- 〽️  --------------------------------------------------------------------------


main : Program Flags Model Msg
main =
    Browser.application
        { init = \_ _ _ -> ( Unauthenticated Loading, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


-- 🔁 --------------------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

                -- FIXME check if already logged in
        WebnativeInit isAuthed ->
            ( initAuthState isAuthed, Cmd.none )

        WebnativeSignIn ->
            ( model, Ports.redirectToLobby () )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.webnativeInit WebnativeInit


initAuthState : Bool -> Model
initAuthState isAuthenticated =
    if isAuthenticated then
        Authenticated
    else
        Unauthenticated SignIn


-- 🖼️  ---------------------------------------------------------------------------


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled <| body model ]
    }

body : Model -> Html Msg
body model =
    case model of
        Unauthenticated _ -> unauthenticated
        Authenticated -> authenticated

authenticated : Html Msg
authenticated =
    mainContainer
        [ Html.h1 [] [ Html.text "yay logged in" ]
        ]


unauthenticated : Html Msg
unauthenticated =
    mainContainer
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

        , Html.button [ css [ bg_gray_50 ] ]
            [ Html.text "Sign in with Fission" ]
        ]

mainContainer : List (Html Msg) -> Html Msg
mainContainer =
    Html.main_
        [ css
            [ p_6
            , text_bluegray_800
            , bg_beige_100
            , flex_grow
            ]
        ]
