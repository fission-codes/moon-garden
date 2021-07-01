module Main exposing (main)

import Browser
import Html.Styled as Html exposing (Html)
import Ports
import Random
import Tailwind.Utilities exposing (..)
import View



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
        { titleBuffer : String
        , editorBuffer : String
        , dirty : Bool
        , saving : Bool
        }


type Msg
    = NoOp -- FIXME Replace with navigation messages
    | GeneratedLoadingMessage LoadingMessage
    | WebnativeSignIn
    | WebnativeInit Bool
    | UpdateTitleBuffer String
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

        UpdateTitleBuffer updatedTitle ->
            case model of
                Authed (Note note) ->
                    ( Authed <|
                        Note
                            { note
                                | titleBuffer = updatedTitle
                            }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateEditorBuffer updatedText ->
            case model of
                Authed (Note note) ->
                    ( Authed <|
                        Note
                            { note
                                | editorBuffer = updatedText
                            }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

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
                { titleBuffer = ""
                , editorBuffer = ""
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
        Note note ->
            View.appShellSidebar
                { navigation =
                    [ View.leafyButton
                        { label = "Create New Note"
                        , onClick = NoOp
                        }
                    , View.searchInput
                        { styles = [ mt_8 ]
                        , placeholder = "Type to Search"
                        , onInput = \_ -> NoOp
                        }
                    ]
                , main =
                    [ View.titleInput
                        { onInput = UpdateTitleBuffer
                        , value = note.titleBuffer
                        , styles = []
                        }
                    , View.autoresizeTextarea
                        { onChange = UpdateEditorBuffer
                        , content = note.editorBuffer
                        , styles = [ View.editorTextareaStyle ]
                        }
                    , View.leafyButton
                        { label = "Save"
                        , onClick =
                            PersistNote
                                { noteName = note.titleBuffer
                                , noteData = note.editorBuffer
                                }
                        }

                    -- , View.wikilinksSection
                    --     { styles = [ mt_8 ]
                    --     , wikilinks =
                    --         [ View.wikilinkExisting { label = "WNFS", link = "#" }
                    --         , View.wikilinkExisting { label = "Fission", link = "#" }
                    --         , View.wikilinkNew { label = "Markdown", onClickCreate = NoOp }
                    --         ]
                    --     }
                    ]
                }


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
