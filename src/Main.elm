module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html.Styled as Html exposing (Html)
import Json.Decode as D exposing (Decoder)
import List.Extra as List
import Ports
import Random
import Routes exposing (Route)
import Tailwind.Utilities exposing (..)
import Url exposing (Url)
import View



-- 🔠 ---------------------------------------------------------------------------


type alias Model =
    { url : Url
    , navKey : Navigation.Key
    , state : State
    }


type State
    = Unauthed Unauthenticated
    | Authed Authenticated -- FIXME add more actions to Authenticated


type Unauthenticated
    = Loading LoadingMessage
    | Cancelled
    | PleaseSignIn


type alias Authenticated =
    { notes : Dict String WNFSEntry
    , state : AuthenticatedState
    }


type AuthenticatedState
    = EditNote EditNoteState


type alias EditNoteState =
    { titleBuffer : String
    , editorBuffer : String
    }


type Msg
    = NoOp -- FIXME Replace with navigation messages
    | GeneratedLoadingMessage LoadingMessage
    | WebnativeSignIn
    | WebnativeInit Bool
    | UpdateTitleBuffer String
    | UpdateEditorBuffer String
    | PersistNote { noteName : String, noteData : String }
    | LoadedNotes (Result String (Dict String WNFSEntry))


type LoadingMessage
    = LoadingMessage String


type alias Flags =
    { randomness : Int
    }



-- 〽️  --------------------------------------------------------------------------


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        loadingMessage =
            Random.initialSeed flags.randomness
                |> Random.step randomLoadingMessage
                |> Tuple.first
    in
    ( { url = url
      , navKey = navKey
      , state = Unauthed (Loading (LoadingMessage loadingMessage))
      }
    , Cmd.none
    )



-- 🔁 --------------------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GeneratedLoadingMessage loading ->
            ( { model | state = Unauthed (Loading loading) }
            , Cmd.none
            )

        WebnativeInit isAuthed ->
            ( { model
                | state =
                    if isAuthed then
                        Authed
                            { notes = Dict.empty
                            , state =
                                EditNote
                                    { titleBuffer = ""
                                    , editorBuffer = ""
                                    }
                            }

                    else
                        Unauthed PleaseSignIn
              }
            , Cmd.none
            )

        WebnativeSignIn ->
            ( model, Ports.redirectToLobby () )

        UpdateTitleBuffer updatedTitle ->
            updateAuthed
                (updateEditNote
                    (\note ->
                        ( { note
                            | titleBuffer = updatedTitle
                          }
                        , Cmd.none
                        )
                    )
                )
                model

        UpdateEditorBuffer updatedText ->
            updateAuthed
                (updateEditNote
                    (\note ->
                        ( { note
                            | editorBuffer = updatedText
                          }
                        , Cmd.none
                        )
                    )
                )
                model

        LoadedNotes result ->
            updateAuthed
                (\authed ->
                    case result of
                        Ok notes ->
                            ( { authed | notes = notes }
                            , Cmd.none
                            )

                        Err _ ->
                            ( authed, Cmd.none )
                )
                model

        PersistNote { noteName, noteData } ->
            ( model, Ports.persistNote { noteName = noteName, noteData = noteData } )


updateAuthed : (Authenticated -> ( Authenticated, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
updateAuthed updater model =
    case model.state of
        Authed authed ->
            let
                ( newAuthed, cmds ) =
                    updater authed
            in
            ( { model | state = Authed newAuthed }, cmds )

        _ ->
            ( model, Cmd.none )


updateEditNote : (EditNoteState -> ( EditNoteState, Cmd Msg )) -> Authenticated -> ( Authenticated, Cmd Msg )
updateEditNote updater authed =
    case authed.state of
        EditNote editNoteState ->
            let
                ( newState, cmds ) =
                    updater editNoteState
            in
            ( { authed | state = EditNote newState }
            , cmds
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.webnativeInit WebnativeInit
        , Ports.loadedNotesLs (withDecoding (D.dict decodeWNFSEntry) LoadedNotes)
        ]


randomLoadingMessage : Random.Generator String
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



-- 🖼️  ---------------------------------------------------------------------------


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled <| body model ]
    }


body : Model -> Html Msg
body model =
    case model.state of
        Unauthed unauthedState ->
            unauthenticated unauthedState

        Authed authState ->
            authenticated authState


authenticated : Authenticated -> Html Msg
authenticated model =
    case model.state of
        EditNote note ->
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
                    , model.notes
                        |> Dict.values
                        |> List.filterMap isMarkdownNote
                        |> List.sortBy (.modificationTime >> (*) -1)
                        |> List.map viewRecentNote
                        |> View.searchResults
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
        Loading (LoadingMessage message) ->
            View.loadingScreen { message = message, isError = False }

        Cancelled ->
            View.loadingScreen { message = "Auth cancelled", isError = True }

        PleaseSignIn ->
            View.signinScreen { onClickSignIn = WebnativeSignIn }


viewRecentNote : MarkdownNoteRef -> Html Msg
viewRecentNote note =
    View.referencedNoteCard
        { label = note.name
        , link = "#"
        , styles = []
        }



-- Utilitites


withDecoding : Decoder a -> (Result String a -> msg) -> D.Value -> msg
withDecoding decoder toMsg json =
    D.decodeValue decoder json
        |> Result.mapError D.errorToString
        |> toMsg


type alias WNFSEntry =
    { isFile : Bool
    , name : String
    , cid : String
    , metadata :
        { unixMeta :
            { mtime : Int
            , ctime : Int
            }
        }
    }


decodeWNFSEntry : Decoder WNFSEntry
decodeWNFSEntry =
    D.map4 WNFSEntry
        (D.field "isFile" D.bool)
        (D.field "name" D.string)
        (D.field "cid" D.string)
        (D.field "metadata" decodeMetadata)


decodeMetadata : Decoder { unixMeta : { mtime : Int, ctime : Int } }
decodeMetadata =
    D.map2
        (\mtime ctime ->
            { unixMeta =
                { mtime = mtime
                , ctime = ctime
                }
            }
        )
        (D.at [ "unixMeta", "mtime" ] D.int)
        (D.at [ "unixMeta", "ctime" ] D.int)



-- MarkdownNote


type alias MarkdownNoteRef =
    { name : String
    , modificationTime : Int
    , creationTime : Int
    }


isMarkdownNote : WNFSEntry -> Maybe MarkdownNoteRef
isMarkdownNote entry =
    let
        ensureIsMarkdown ( name, extension ) =
            -- we require lowercase "md", because we will always save as .md
            if extension == "md" then
                Just name

            else
                Nothing
    in
    if entry.isFile then
        entry.name
            |> splitLast "."
            |> Maybe.andThen ensureIsMarkdown
            |> Maybe.map
                (\name ->
                    { name = name
                    , modificationTime = entry.metadata.unixMeta.mtime
                    , creationTime = entry.metadata.unixMeta.ctime
                    }
                )

    else
        Nothing


splitLast : String -> String -> Maybe ( String, String )
splitLast needle haystack =
    haystack
        |> String.split needle
        |> List.unconsLast
        |> Maybe.map
            (\( last, rest ) ->
                ( rest |> String.join needle
                , last
                )
            )
