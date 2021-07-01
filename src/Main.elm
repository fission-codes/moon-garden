module Main exposing (main)

import Browser
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events as Event exposing (..)
import Ports
import Random as Random
import Tailwind.Utilities exposing (..)
import View as View



-- 🔠 ---------------------------------------------------------------------------


type Model
    = Unauthed Unauthenticated
    | Authed Authenticated -- FIXME add more actions to Authenticated


type Unauthenticated
    = Init
    | Loading LoadingMessage
    | Cancelled
    | PleaseSignIn


type Authenticated
    = Note
        { editorBuffer : String
        , dirty : Bool
        , saving : Bool
        }


type Msg
    = NoOp -- FIXME Replace with navigation messages
    | GeneratedLoadingMessage LoadingMessage
    | WebnativeSignIn
    | WebnativeInit Bool
    | UpdateEditorBuffer String
    | PersistNote { noteName : String, noteData : String }


type LoadingMessage
    = LoadingMessage String


type alias Flags =
    ()



-- 〽️  --------------------------------------------------------------------------


main : Program Flags Model Msg
main =
    Browser.application
        { init = \_ _ _ -> ( Unauthed Init, Cmd.map GeneratedLoadingMessage randomLoadingMessage )
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

        UpdateEditorBuffer updatedText ->
            ( Authed <|
                Note
                    { editorBuffer = updatedText
                    , dirty = True
                    , saving = False
                    }
            , Cmd.none
            )

        PersistNote { noteName, noteData } ->
            ( model, Ports.persistNote { noteName = noteName, noteData = noteData } )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.webnativeInit WebnativeInit


initAuthState : Bool -> Model
initAuthState isAuthenticated =
    if isAuthenticated then
        Authed <|
            Note
                { editorBuffer = ""
                , dirty = False
                , saving = False
                }

    else
        Unauthed PleaseSignIn


randomLoadingMessage : Cmd LoadingMessage
randomLoadingMessage =
    -- Source: https://gist.github.com/meain/6440b706a97d2dd71574769517e7ed32
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
        |> Random.uniform "Loading..."
        |> Random.generate LoadingMessage



-- 🖼️  ---------------------------------------------------------------------------


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled <| body model ]
    }


body : Model -> Html Msg
body model =
    case model of
        Unauthed unauthedState ->
            unauthenticated unauthedState

        Authed authState ->
            authenticated authState


authenticated : Authenticated -> Html Msg
authenticated model =
    case model of
        Note { editorBuffer } ->
            mainContainer
                [ Html.h1 []
                    [ Html.text "yay logged in" ]
                , Html.textarea
                    [ Event.onInput UpdateEditorBuffer
                    , Attr.placeholder "Type your note here. Markdown supported!"
                    ]
                    [ Html.text editorBuffer ]
                , Html.button [ Event.onClick <| PersistNote { noteName = "testing2", noteData = editorBuffer } ]
                    [ Html.text "Save" ]
                ]


unauthenticated : Unauthenticated -> Html Msg
unauthenticated model =
    case model of
        Init ->
            View.loadingScreen { message = "Initializing...", isError = False }

        Loading (LoadingMessage message) ->
            View.loadingScreen { message = message, isError = False }

        Cancelled ->
            View.loadingScreen { message = "Auth cancelled", isError = True }

        PleaseSignIn ->
            View.signinScreen { onClickSignIn = WebnativeSignIn }


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
