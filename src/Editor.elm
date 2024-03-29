module Editor exposing (main)

import Browser
import Browser.Navigation as Navigation
import Common exposing (MarkdownNoteRef, WNFSEntry)
import Dict exposing (Dict)
import Html.Styled as Html exposing (Html)
import Json.Decode as D
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
    | LinkClicked (Routes.UrlRequest Routes.EditorRoute)
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
        , onUrlRequest = Routes.fromRequestInEditor >> LinkClicked
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
                Routes.External link ->
                    ( model
                    , Navigation.load link
                    )

                Routes.Internal url _ ->
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
                            (Routes.toLink (Routes.Editor (Routes.EditorEditNote "")))
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
                            (Routes.toLink (Routes.Editor (Routes.EditorEditNote "")))
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
            case Routes.fromUrl model.url of
                Routes.Editor (Routes.EditorEditNote name) ->
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

                Routes.Editor Routes.EditorDashboard ->
                    { authed
                        | state =
                            Dashboard
                                { searchBuffer = ""
                                }
                    }
                        |> Return.singleton
                        |> returnAuthed model

                Routes.Viewer viewerRoute ->
                    model
                        |> Return.singleton
                        |> Return.effect_
                            (\_ ->
                                Cmd.batch
                                    -- If someone types /viewer in the url, this will change it to /viewer/ and load the correct route
                                    -- without adding another history entry. This prevents a reload-loop when trying to go back in history once
                                    [ Navigation.replaceUrl model.navKey (Routes.toLink (Routes.Viewer viewerRoute))
                                    , Navigation.reload
                                    ]
                            )
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
        , Ports.loadedNotesLs (Common.withDecoding (D.dict Common.decodeWNFSEntry) LoadedNotes)
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
            viewAuthenticated
                (model.url.fragment |> Maybe.withDefault "")
                authState


viewAuthenticated : String -> Authenticated -> Html Msg
viewAuthenticated urlFragment model =
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
                    , View.leafyButton { onClick = Just DashboardCreateNewNote, label = "Create New Note", styles = [] }
                    ]

                 else
                    List.concat
                        [ [ View.titleText [] ("Hello, " ++ model.username)
                          , View.leafyButton { onClick = Just DashboardCreateNewNote, label = "Create New Note", styles = [] }
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
                                    (Common.isMarkdownNote
                                        >> Maybe.andThen (Common.isNotFiltered dashboard.searchBuffer)
                                    )
                                |> List.sortBy (.modificationTime >> (*) -1)
                                |> List.take 24
                                |> List.map viewRecentNote
                                |> View.searchGrid
                          , View.link
                                { styles = [ mt_8 ]
                                , label = [ Html.text "View your publicly sharable garden" ]
                                , location = Routes.toLink (Routes.Viewer (Routes.ViewerGarden model.username))
                                }
                          ]
                        ]
                )

        EditNote note ->
            View.appShellSidebar
                { navigation =
                    [ View.referencedNoteCard
                        { label = "Dashboard"
                        , link = Routes.toLink (Routes.Editor Routes.EditorDashboard)
                        , styles = [ mb_8, text_center ]
                        }
                    , View.leafyButton
                        { label = "Create New Note"
                        , onClick = Just CreateNewNote
                        , styles = []
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
                                    |> Common.isMarkdownNote
                                    |> (if note.searchBuffer == "" then
                                            identity

                                        else
                                            Maybe.andThen (Common.isNotFiltered note.searchBuffer)
                                       )
                            )
                        |> List.sortBy (.modificationTime >> (*) -1)
                        |> List.map viewRecentNote
                        |> View.searchResults
                    ]
                , mainId = urlFragment
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
                    , View.link
                        { styles = [ mt_8 ]
                        , label = [ Html.text "View Note (sharable link)" ]
                        , location = Routes.toLink (Routes.Viewer (Routes.ViewerGardenNote model.username note.titleBuffer))
                        }
                    , View.spacer

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
        , link = Routes.toLink (Routes.Editor (Routes.EditorEditNote note.name))
        , styles = []
        }
