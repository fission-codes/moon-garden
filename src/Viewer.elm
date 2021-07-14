module Viewer exposing (..)

import Browser
import Browser.Navigation as Navigation
import Html.Styled as Html exposing (Html)
import Return exposing (Return)
import Routes
import Tailwind.Utilities exposing (..)
import Url exposing (Url)
import View


type Msg
    = UrlChanged Url
    | LinkClicked (Routes.UrlRequest Routes.ViewerRoute)
    | UsernameChanged String
    | UsernameSubmitted


type alias Model =
    { url : Url
    , navKey : Navigation.Key
    , state : State
    }


type State
    = Dashboard DashboardState
    | GardenOverview GardenOverviewState


type alias DashboardState =
    { usernameBuffer : String
    }


type alias GardenOverviewState =
    { username : String
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


handleUrlChange : Model -> Return Msg Model
handleUrlChange model =
    case Routes.fromUrl model.url of
        Routes.Viewer Routes.ViewerDashboard ->
            { model | state = Dashboard { usernameBuffer = "" } }
                |> Return.singleton

        Routes.Viewer (Routes.ViewerGarden username) ->
            { model
                | state =
                    GardenOverview
                        { username = username }
            }
                |> Return.singleton

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
subscriptions _ =
    Sub.none


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

        GardenOverview state ->
            View.appShellColumn
                [ View.titleText [] (state.username ++ "'s\nMoon Garden")
                ]
