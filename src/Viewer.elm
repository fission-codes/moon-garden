module Viewer exposing (..)

import Browser
import Browser.Navigation as Navigation
import Common exposing (MarkdownNoteRef, WNFSEntry)
import Dict exposing (Dict)
import Html.Styled as Html exposing (Html)
import Json.Decode as D
import RemoteData exposing (RemoteData)
import Return exposing (Return)
import Routes
import Tailwind.Utilities exposing (..)
import Url exposing (Url)
import View
import Viewer.Ports as Ports


type Msg
    = UrlChanged Url
    | LinkClicked (Routes.UrlRequest Routes.ViewerRoute)
    | UsernameChanged String
    | UsernameSubmitted
    | LoadedNotesFor (Result String { username : String, notes : Dict String WNFSEntry })
    | LoadedNote (Result String { username : String, note : { noteName : String, noteData : String } })


type alias Model =
    { url : Url
    , navKey : Navigation.Key
    , state : State
    }


type State
    = Dashboard DashboardState
    | InGarden InGardenState
    | InGardenNote InGardenNoteState


type alias DashboardState =
    { usernameBuffer : String
    }


type alias InGardenState =
    { username : String
    , notes : RemoteData String (Dict String WNFSEntry)
    }


type alias InGardenNoteState =
    { username : String
    , note : RemoteData String { noteName : String, noteData : String }
    }


type alias Flags =
    {}


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = UrlChanged
        , onUrlRequest = Routes.fromRequestInViewer >> LinkClicked
        }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url navKey =
    { url = url
    , navKey = navKey
    , state =
        Dashboard
            { usernameBuffer = ""
            }
    }
        |> handleUrlChange


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        UsernameChanged username ->
            case model.state of
                Dashboard state ->
                    { state | usernameBuffer = username }
                        |> (\newState -> { model | state = Dashboard newState })
                        |> Return.singleton

                _ ->
                    model |> Return.singleton

        UsernameSubmitted ->
            case model.state of
                Dashboard state ->
                    model
                        |> Return.singleton
                        |> Return.effect_
                            (\_ ->
                                Navigation.pushUrl model.navKey
                                    (Routes.toLink
                                        (Routes.Viewer
                                            (Routes.ViewerGarden state.usernameBuffer)
                                        )
                                    )
                            )

                _ ->
                    model |> Return.singleton

        LoadedNotesFor result ->
            case ( model.state, result ) of
                ( InGarden garden, Ok { username, notes } ) ->
                    if username == garden.username then
                        { garden | notes = RemoteData.Success notes }
                            |> (\newGarden -> { model | state = InGarden newGarden })
                            |> Return.singleton

                    else
                        model |> Return.singleton

                ( InGarden garden, Err message ) ->
                    { garden | notes = RemoteData.Failure message }
                        |> (\newGarden -> { model | state = InGarden newGarden })
                        |> Return.singleton

                _ ->
                    model |> Return.singleton

        LoadedNote result ->
            case result of
                Ok { username, note } ->
                    { model
                        | state =
                            InGardenNote
                                { username = username
                                , note = RemoteData.Success note
                                }
                    }
                        |> Return.singleton

                Err message ->
                    case model.state of
                        InGardenNote garden ->
                            { model
                                | state =
                                    InGardenNote
                                        { garden
                                            | note = RemoteData.Failure message
                                        }
                            }
                                |> Return.singleton

                        _ ->
                            model |> Return.singleton


handleUrlChange : Model -> Return Msg Model
handleUrlChange model =
    case Routes.fromUrl model.url of
        Routes.Viewer Routes.ViewerDashboard ->
            { model | state = Dashboard { usernameBuffer = "" } }
                |> Return.singleton

        Routes.Viewer (Routes.ViewerGarden username) ->
            { model
                | state =
                    InGarden
                        { username = username
                        , notes = RemoteData.Loading
                        }
            }
                |> Return.singleton
                |> Return.effect_
                    (\_ ->
                        Ports.loadNotesFor { username = username }
                    )

        Routes.Viewer (Routes.ViewerGardenNote username noteName) ->
            model
                |> Return.singleton
                |> Return.effect_
                    (\_ ->
                        Ports.loadNote { username = username, noteName = noteName }
                    )

        Routes.Editor editorRoute ->
            model
                |> Return.singleton
                |> Return.effect_
                    (\_ ->
                        Cmd.batch
                            -- This will load the correct route without adding another history entry.
                            -- This prevents a reload-loop when trying to go back in history once.
                            [ Navigation.replaceUrl model.navKey (Routes.toLink (Routes.Editor editorRoute))
                            , Navigation.reload
                            ]
                    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        common =
            Sub.batch
                [ Ports.loadedNote
                    (Common.withDecoding
                        (D.map2 (\username note -> { username = username, note = note })
                            (D.field "username" D.string)
                            (D.field "note"
                                (D.map2 (\noteName noteData -> { noteName = noteName, noteData = noteData })
                                    (D.field "noteName" D.string)
                                    (D.field "noteData" D.string)
                                )
                            )
                        )
                        LoadedNote
                    )
                , Ports.loadedNoteFailed (\{ message } -> LoadedNote (Err message))
                ]
    in
    case model.state of
        InGarden _ ->
            Sub.batch
                [ Ports.loadedNotesFor
                    (Common.withDecoding
                        (D.map2 (\username notes -> { username = username, notes = notes })
                            (D.field "username" D.string)
                            (D.field "notes" (D.dict Common.decodeWNFSEntry))
                        )
                        LoadedNotesFor
                    )
                , Ports.loadedNotesForFailed (\{ message } -> LoadedNotesFor (Err message))
                , common
                ]

        _ ->
            common


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled <| viewBody model ]
    }


viewBody : Model -> Html Msg
viewBody model =
    case model.state of
        Dashboard _ ->
            View.appShellColumn
                [ View.titleText [] "Moon Garden"
                , View.paragraph []
                    [ Html.text "is a digital garden app built on the Fission Platform."
                    , Html.br [] []
                    , Html.br [] []
                    , Html.text "Check out the a digital garden by entering a fission username:"
                    ]
                , View.usernameForm
                    { onSubmit = UsernameSubmitted
                    , onChangeUsername = UsernameChanged
                    }
                , View.paragraph []
                    [ Html.text "Think this is cool? You can totally "
                    , View.link
                        { location = Routes.toLink (Routes.Editor Routes.EditorDashboard)
                        , label = [ Html.text "build your own moon garden" ]
                        }
                    , Html.text " with fission."
                    ]
                ]

        InGarden garden ->
            View.appShellColumn
                (List.concat
                    [ [ View.titleText [] (garden.username ++ "'s\nMoon Garden") ]
                    , case garden.notes of
                        RemoteData.Success notes ->
                            [ View.subtitleText [ mt_8 ] "Recent Notes"
                            , notes
                                |> Dict.values
                                |> List.filterMap Common.isMarkdownNote
                                |> List.sortBy (.modificationTime >> (*) -1)
                                |> List.take 24
                                |> List.map (viewRecentNote garden.username)
                                |> View.searchGrid
                            ]

                        remote ->
                            [ View.subtitleText [ mt_8 ] "Recent Notes"
                            , View.loadingSection
                                { isError = RemoteData.isFailure remote
                                , message =
                                    if RemoteData.isFailure remote then
                                        "Couldn't find any notes for " ++ garden.username

                                    else
                                        "Loading... 🚶"
                                , styles = [ w_full, h_64 ]
                                }
                            ]
                    ]
                )

        InGardenNote gardenNote ->
            case gardenNote.note of
                RemoteData.Success note ->
                    View.appShellSidebar
                        { navigation = []
                        , mainId = model.url.fragment |> Maybe.withDefault ""
                        , main =
                            [ View.renderedDocument
                                { title = note.noteName
                                , markdownContent = note.noteData
                                }
                            ]
                        }

                RemoteData.Failure err ->
                    View.appShellSidebar
                        { navigation = []
                        , mainId = model.url.fragment |> Maybe.withDefault ""
                        , main =
                            [ [ "There was an error trying to load a note for the user "
                              , gardenNote.username
                              , ". The error message is:"
                              ]
                                |> String.concat
                                |> Html.text
                            , Html.pre []
                                [ Html.text err ]
                            ]
                        }

                _ ->
                    -- TODO loading screen?
                    View.appShellSidebar
                        { navigation = []
                        , main = []
                        }


viewRecentNote : String -> MarkdownNoteRef -> Html Msg
viewRecentNote username note =
    View.referencedNoteCard
        { label = note.name
        , link = Routes.toLink (Routes.Viewer (Routes.ViewerGardenNote username note.name))
        , styles = []
        }
