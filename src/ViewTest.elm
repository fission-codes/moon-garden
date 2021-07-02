module ViewTest exposing (..)

import Browser
import Html.Styled as Html exposing (Html)
import Tailwind.Utilities exposing (..)
import View


type alias Model =
    { title : String
    , content : String
    }


type Msg
    = NoOp
    | ChangeContent String
    | ChangeTitle String


main : Program {} Model Msg
main =
    Browser.application
        { init =
            \_ _ _ ->
                ( { title = ""
                  , content = ""
                  }
                , Cmd.none
                )
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ChangeContent content ->
            ( { model | content = content }
            , Cmd.none
            )

        ChangeTitle title ->
            ( { model | title = title }
            , Cmd.none
            )


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body =
        [ Html.toUnstyled <|
            -- View.signinScreen { onClickSignIn = NoOp }
            -- View.loadingScreen
            --     { message = "Spinning violently around the y-axis..."
            --     , isError = True
            --     }
            -- viewEditor model
            -- viewDashboard model
            viewDashboardEmpty
        ]
    }


viewEditor : Model -> Html Msg
viewEditor model =
    View.appShellSidebar
        { navigation =
            List.concat
                [ [ View.leafyButton
                        { label = "Create New Note"
                        , onClick = NoOp
                        }
                  , View.searchInput
                        { styles = [ mt_8 ]
                        , placeholder = "Type to Search"
                        , onInput = \_ -> NoOp
                        }
                  ]
                , List.map
                    (\result ->
                        View.referencedNoteCard
                            { label = result
                            , link = "#" ++ View.appShellSidebarMainSectionId
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
            [ View.titleInput
                { onInput = ChangeTitle
                , value = model.title
                , styles = []
                }
            , View.autoresizeTextarea
                { onChange = ChangeContent
                , content = model.content
                , styles = [ View.editorTextareaStyle ]
                }
            , View.wikilinksSection
                { styles = [ mt_8 ]
                , wikilinks =
                    [ View.wikilinkExisting { label = "WNFS", link = "#" }
                    , View.wikilinkExisting { label = "Fission", link = "#" }
                    , View.wikilinkNew { label = "Markdown", onClickCreate = NoOp }
                    ]
                }
            ]
        }


viewDashboard : Model -> Html Msg
viewDashboard model =
    View.appShellColumn
        [ View.titleText [] "Hello, matheus23"
        , View.paragraph [ mt_6 ]
            [ Html.text "Welcome to your personal Moon Garden! This is your dashboard." ]
        , View.searchInput
            { onInput = \_ -> NoOp
            , placeholder = "Search for Notes"
            , styles = [ mt_8 ]
            }
        , View.subtitleText [ mt_8 ] "Recent Notes"
        , View.searchGrid
            (List.map
                (\label ->
                    View.referencedNoteCard { label = label, link = "#", styles = [] }
                )
                [ "Moon Garden"
                , "WNFS"
                , "Webnative"
                , "Markdown"
                , "Wikilinks"
                ]
            )
        ]


viewDashboardEmpty : Html Msg
viewDashboardEmpty =
    View.appShellColumn
        [ View.titleText [] "Hello, matheus23"
        , View.paragraph [ mt_6 ]
            [ Html.text "Welcome to your personal Moon Garden! This is your dashboard."
            , Html.br [] []
            , Html.br [] []
            , Html.text "It looks like your garden is empty right now. You can get started right away by creating a new note."
            , Html.br [] []
            , Html.text "If you come back here afterwards, you'll have a place to look at the seeds you've planted recently and a way to search through them."
            ]
        , View.leafyButton { onClick = NoOp, label = "Create New Note" }
        ]
