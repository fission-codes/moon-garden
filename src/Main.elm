module Main exposing (main)

import Browser
import Ports
import Random as Random

import Html.Attributes as Attr exposing (..)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)

import Tailwind.Utilities exposing (..)


-- 🔠 ---------------------------------------------------------------------------


type Model
    = Unauthed Unauthenticated
    | Authenticated


type Unauthenticated
    = Init
    | Loading LoadingMessage
    | Cancelled
    | SignIn


type Msg
    = NoOp -- FIXME Replace with navigation messages
    | GeneratedLoadingMessage LoadingMessage
    | WebnativeSignIn
    | WebnativeInit Bool


type LoadingMessage
    = LoadingMessage String

type alias Flags =
    ()


-- 〽️  --------------------------------------------------------------------------


main : Program Flags Model Msg
main =
    Browser.application
        { init = \_ _ _ -> ( Unauthed Init, Cmd.map (GeneratedLoadingMessage) randomLoadingMessage )
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

        GeneratedLoadingMessage loading ->
            ( Unauthed (Loading loading), Cmd.none )

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
        Unauthed SignIn


randomLoadingMessage : Cmd LoadingMessage
randomLoadingMessage =
    Random.generate LoadingMessage <|
        -- Source: https://gist.github.com/meain/6440b706a97d2dd71574769517e7ed32
        Random.uniform "Loading..."
            [ "Reticulating splines..."
            , "Generating witty dialog..."
            , "Swapping time and space..."
            , "Spinning violently around the y-axis..."
            , "Tokenizing real life..."
            , "Bending the spoon..."
            , "Filtering morale..."
            , "Don't think of purple hippos..."
            , "Checking the gravitational constant in your locale..."
            , "You're not in Kansas any more..."
            , "...at least you're not on hold..."
            , "Follow the white rabbit..."
            , "Counting backwards from Infinity..."
            ]


-- 🖼️  ---------------------------------------------------------------------------


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled <| body model ]
    }


body : Model -> Html Msg
body model =
    case model of
        Unauthed unauthedState -> unauthenticated unauthedState
        Authenticated -> authenticated


authenticated : Html Msg
authenticated =
    mainContainer
        [ Html.h1 [] [ Html.text "yay logged in" ]
        , Html.textarea [] []
        ]

unauthenticated : Unauthenticated -> Html Msg
unauthenticated model =
  case model of
      Init ->
          unauthedPage
              [ Html.p []
                  [ Html.text "Initializing..." ]
              ]

      Loading (LoadingMessage message) ->
          unauthedPage
              [ Html.p []
                  [ Html.text message ]
              ]

      Cancelled ->
          unauthedPage
            [ Html.text "Cancelled sign in"
            , Html.button [ css [ bg_gray_50 ] ]
                [ Html.text "Sign in with Fission" ]
            ]

      SignIn ->
          unauthedPage
            [ Html.button [ css [ bg_gray_50 ] ]
                [ Html.text "Sign in with Fission" ]
            ]

unauthedPage : List (Html Msg) -> Html Msg
unauthedPage inner =
    let
        common =
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
    in
        mainContainer (common ++ inner)

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
