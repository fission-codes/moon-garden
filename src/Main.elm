module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html.Styled as Html exposing (Html)
import Json.Decode as D exposing (Decoder)
import List.Extra as List
import Maybe.Extra as Maybe
import Ports
import Random
import Return exposing (Return)
import Routes
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
    | Authed Authenticated


type Unauthenticated
    = Loading LoadingMessage
    | Cancelled
    | PleaseSignIn


type alias Authenticated =
    { username : String
    , notes : Dict String WNFSEntry
    , state : AuthenticatedState
    }


type AuthenticatedState
    = Dashboard DashboardState
    | EditNote EditNoteState


type alias DashboardState =
    { searchBuffer : String
    }


type alias EditNoteState =
    { titleBuffer : String
    , editorBuffer : String
    , persistState : PersistState
    , searchBuffer : String
    }


type PersistState
    = PersistedAs String
    | PersistingAs String
    | NotPersistedYet
    | LoadingNote


type Msg
    = NoOp -- FIXME Replace the need for this
    | UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | WebnativeSignIn
    | WebnativeInit (Maybe { username : String })
    | UpdateTitleBuffer String
    | UpdateEditorBuffer String
    | LoadedNote { noteName : String, noteData : String }
    | PersistedNote { noteName : String, noteData : String }
    | LoadedNotes (Result String (Dict String WNFSEntry))
    | CreateNewNote
    | DashboardCreateNewNote
    | UpdateSearchBuffer String
    | UpdateNavigationSearchBuffer String


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
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


init : Flags -> Url -> Navigation.Key -> Return Msg Model
init flags url navKey =
    let
        loadingMessage =
            Random.initialSeed flags.randomness
                |> Random.step randomLoadingMessage
                |> Tuple.first
    in
    { url = url
    , navKey = navKey
    , state = Unauthed (Loading (LoadingMessage loadingMessage))
    }
        |> Return.singleton



-- 🔁 --------------------------------------------------------------------------


update : Msg -> Model -> Return Msg Model
update msg model =
    case msg of
        NoOp ->
            model
                |> Return.singleton

        UrlChanged url ->
            { model | url = url }
                |> handleUrlChange

        LinkClicked request ->
            case request of
                Browser.External link ->
                    ( model
                    , Navigation.load link
                    )

                Browser.Internal url ->
                    ( { model | url = url }
                    , Navigation.pushUrl model.navKey (Url.toString url)
                    )

        WebnativeInit maybeAuthed ->
            case maybeAuthed of
                Just { username } ->
                    { model
                        | state =
                            Authed
                                { username = username
                                , notes = Dict.empty
                                , state =
                                    EditNote
                                        { titleBuffer = ""
                                        , editorBuffer = ""
                                        , persistState = NotPersistedYet
                                        , searchBuffer = ""
                                        }
                                }
                    }
                        |> handleUrlChange

                _ ->
                    { model | state = Unauthed PleaseSignIn }
                        |> Return.singleton

        WebnativeSignIn ->
            ( model
            , Ports.redirectToLobby ()
            )

        UpdateTitleBuffer updatedTitle ->
            updateEditNote
                (\authed note ->
                    { note
                        | titleBuffer = updatedTitle
                    }
                        |> Return.singleton
                        |> Return.effect_ (noteUpdateEffects note)
                        |> returnEditNote authed
                        |> returnAuthed model
                )
                model

        UpdateEditorBuffer updatedText ->
            updateEditNote
                (\authed note ->
                    { note
                        | editorBuffer = updatedText
                        , persistState = PersistingAs note.titleBuffer
                    }
                        |> Return.singleton
                        |> Return.effect_ (noteUpdateEffects note)
                        |> returnEditNote authed
                        |> returnAuthed model
                )
                model

        LoadedNotes result ->
            updateAuthed
                (\authed ->
                    case result of
                        Ok notes ->
                            { authed | notes = notes }
                                |> Return.singleton
                                |> returnAuthed model

                        Err _ ->
                            model
                                |> Return.singleton
                )
                model

        LoadedNote { noteName, noteData } ->
            updateEditNote
                (\authed note ->
                    { note
                        | titleBuffer = noteName
                        , editorBuffer = noteData
                        , persistState = PersistedAs noteName
                    }
                        |> Return.singleton
                        |> returnEditNote authed
                        |> returnAuthed model
                )
                model

        PersistedNote { noteName, noteData } ->
            updateEditNote
                (\authed note ->
                    if note.titleBuffer == noteName && note.editorBuffer == noteData then
                        { note | persistState = PersistedAs noteName }
                            |> Return.singleton
                            |> returnEditNote authed
                            |> returnAuthed model

                    else
                        model
                            |> Return.singleton
                )
                model

        CreateNewNote ->
            updateEditNote
                (\authed note ->
                    Return.return
                        { note
                            | titleBuffer = ""
                            , editorBuffer = ""
                            , persistState = NotPersistedYet
                        }
                        (Navigation.pushUrl model.navKey
                            (Routes.toLink (Routes.EditNote ""))
                        )
                        |> returnEditNote authed
                        |> returnAuthed model
                )
                model

        DashboardCreateNewNote ->
            updateAuthed
                (\authed ->
                    Return.return
                        { titleBuffer = ""
                        , editorBuffer = ""
                        , persistState = NotPersistedYet
                        , searchBuffer = ""
                        }
                        (Navigation.pushUrl model.navKey
                            (Routes.toLink (Routes.EditNote ""))
                        )
                        |> returnEditNote authed
                        |> returnAuthed model
                )
                model

        UpdateSearchBuffer updatedSearch ->
            updateDashboard
                (\authed dashboard ->
                    { dashboard | searchBuffer = updatedSearch }
                        |> Return.singleton
                        |> returnDashboard authed
                        |> returnAuthed model
                )
                model

        UpdateNavigationSearchBuffer updatedSearch ->
            updateEditNote
                (\authed note ->
                    { note | searchBuffer = updatedSearch }
                        |> Return.singleton
                        |> returnEditNote authed
                        |> returnAuthed model
                )
                model


updateAuthed : (Authenticated -> Return Msg Model) -> Model -> Return Msg Model
updateAuthed updater model =
    case model.state of
        Authed authed ->
            updater authed

        _ ->
            Return.singleton model


returnAuthed : Model -> Return Msg Authenticated -> Return Msg Model
returnAuthed model =
    Return.map (\authed -> { model | state = Authed authed })


updateEditNote : (Authenticated -> EditNoteState -> Return Msg Model) -> Model -> Return Msg Model
updateEditNote updater model =
    updateAuthed
        (\authed ->
            case authed.state of
                EditNote editNoteState ->
                    let
                        ( newModel, cmds ) =
                            updater authed editNoteState
                    in
                    ( newModel
                    , cmds
                    )

                _ ->
                    model |> Return.singleton
        )
        model


returnEditNote : Authenticated -> Return Msg EditNoteState -> Return Msg Authenticated
returnEditNote authenticated =
    Return.map (\editNoteState -> { authenticated | state = EditNote editNoteState })


updateDashboard : (Authenticated -> DashboardState -> Return Msg Model) -> Model -> Return Msg Model
updateDashboard updater model =
    updateAuthed
        (\authed ->
            case authed.state of
                Dashboard dashboard ->
                    let
                        ( newModel, cmds ) =
                            updater authed dashboard
                    in
                    ( newModel
                    , cmds
                    )

                _ ->
                    model |> Return.singleton
        )
        model


returnDashboard : Authenticated -> Return Msg DashboardState -> Return Msg Authenticated
returnDashboard authenticated =
    Return.map (\dashboard -> { authenticated | state = Dashboard dashboard })


handleUrlChange : Model -> Return Msg Model
handleUrlChange model =
    updateAuthed
        (\authed ->
            case Routes.parse model.url of
                Just (Routes.EditNote name) ->
                    Return.return
                        { authed
                            | state =
                                EditNote
                                    (case authed.state of
                                        EditNote note ->
                                            { note
                                                | titleBuffer = name
                                                , editorBuffer = ""
                                                , persistState = LoadingNote
                                            }

                                        _ ->
                                            { titleBuffer = name
                                            , editorBuffer = ""
                                            , persistState = LoadingNote
                                            , searchBuffer = ""
                                            }
                                    )
                        }
                        (Ports.loadNote name)
                        |> returnAuthed model

                _ ->
                    { authed
                        | state =
                            Dashboard
                                { searchBuffer = ""
                                }
                    }
                        |> Return.singleton
                        |> returnAuthed model
        )
        model


noteUpdateEffects : EditNoteState -> EditNoteState -> Cmd Msg
noteUpdateEffects noteBefore noteNow =
    case noteBefore.persistState of
        LoadingNote ->
            -- If it's still loading, we don't want to override
            -- the note with almost-empty text (!)
            Cmd.none

        NotPersistedYet ->
            Ports.persistNote
                { noteName = noteNow.titleBuffer
                , noteData = noteNow.editorBuffer
                }

        PersistedAs titleBefore ->
            if titleBefore == noteNow.titleBuffer then
                Ports.persistNote
                    { noteName = noteNow.titleBuffer
                    , noteData = noteNow.editorBuffer
                    }

            else
                Ports.renameNote
                    { noteNameBefore = titleBefore
                    , noteNameNow = noteNow.titleBuffer
                    , noteData = noteNow.editorBuffer
                    }

        PersistingAs titleBefore ->
            if titleBefore == noteNow.titleBuffer then
                Ports.persistNote
                    { noteName = noteNow.titleBuffer
                    , noteData = noteNow.editorBuffer
                    }

            else
                Ports.renameNote
                    { noteNameBefore = titleBefore
                    , noteNameNow = noteNow.titleBuffer
                    , noteData = noteNow.editorBuffer
                    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.webnativeInit WebnativeInit
        , Ports.loadedNotesLs (withDecoding (D.dict decodeWNFSEntry) LoadedNotes)
        , Ports.loadedNote LoadedNote
        , Ports.persistedNote PersistedNote
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
    , body = [ Html.toUnstyled <| viewBody model ]
    }


viewBody : Model -> Html Msg
viewBody model =
    case model.state of
        Unauthed unauthedState ->
            viewUnauthenticated unauthedState

        Authed authState ->
            viewAuthenticated authState


viewAuthenticated : Authenticated -> Html Msg
viewAuthenticated model =
    case model.state of
        Dashboard dashboard ->
            View.appShellColumn
                (if Dict.isEmpty model.notes then
                    [ View.titleText [] ("Hello, " ++ model.username)
                    , View.paragraph [ mt_6 ]
                        [ Html.text "Welcome to your personal Moon Garden! This is your dashboard."
                        , Html.br [] []
                        , Html.br [] []
                        , Html.text "It looks like your garden is empty right now. You can get started right away by creating a new note."
                        , Html.br [] []
                        , Html.text "If you come back here afterwards, you'll have a place to look at the seeds you've planted recently and a way to search through them."
                        ]
                    , View.leafyButton { onClick = DashboardCreateNewNote, label = "Create New Note" }
                    ]

                 else
                    List.concat
                        [ [ View.titleText [] ("Hello, " ++ model.username)
                          , View.searchInput
                                { placeholder = "Search Notes"
                                , onInput = UpdateSearchBuffer
                                , styles = [ mt_8 ]
                                }
                          ]
                        , if dashboard.searchBuffer == "" then
                            [ View.subtitleText [ mt_8 ] "Recent Notes" ]

                          else
                            []
                        , [ model.notes
                                |> Dict.values
                                |> List.filterMap
                                    (isMarkdownNote
                                        >> Maybe.andThen (isNotFiltered dashboard.searchBuffer)
                                    )
                                |> List.sortBy (.modificationTime >> (*) -1)
                                |> List.take 24
                                |> List.map viewRecentNote
                                |> View.searchGrid
                          ]
                        ]
                )

        EditNote note ->
            View.appShellSidebar
                { navigation =
                    [ View.referencedNoteCard
                        { label = "Dashboard"
                        , link = Routes.toLink Routes.Dashboard
                        , styles = [ mb_8, text_center ]
                        }
                    , View.leafyButton
                        { label = "Create New Note"
                        , onClick = CreateNewNote
                        }
                    , View.searchInput
                        { placeholder = "Type to Search"
                        , onInput = UpdateNavigationSearchBuffer
                        , styles = [ mt_8 ]
                        }
                    , model.notes
                        |> Dict.values
                        |> List.filterMap
                            (\wnfsEntry ->
                                wnfsEntry
                                    |> isMarkdownNote
                                    |> (if note.searchBuffer == "" then
                                            identity

                                        else
                                            Maybe.andThen (isNotFiltered note.searchBuffer)
                                       )
                            )
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


viewUnauthenticated : Unauthenticated -> Html Msg
viewUnauthenticated model =
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
        , link = Routes.toLink (Routes.EditNote note.name)
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


isNotFiltered : String -> MarkdownNoteRef -> Maybe MarkdownNoteRef
isNotFiltered needle markdownNote =
    let
        haystack =
            String.toLower markdownNote.name

        lowerNeedle =
            String.toLower needle

        stripAfterLetter needleLetter maybeHaystackRest =
            maybeHaystackRest
                |> Maybe.andThen
                    (\haystackRest ->
                        case String.indices (String.fromChar needleLetter) haystackRest of
                            [] ->
                                Nothing

                            index :: _ ->
                                Just (String.dropLeft (index + 1) haystackRest)
                    )
    in
    if
        lowerNeedle
            |> String.foldl stripAfterLetter (Just haystack)
            |> Maybe.isJust
    then
        Just markdownNote

    else
        Nothing
