module Main exposing (main)

import Browser
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Ports
import Tailwind.Utilities exposing (..)

import Msg exposing (Msg (..))
import Model exposing (Model (..))
import View exposing (view)


type alias Flags =
    ()


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


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        WebnativeInit isAuthenticated ->
            ( authFromBool isAuthenticated
            , Cmd.none
            )

authFromBool : Bool -> Model
authFromBool isAuthenticated =
    if isAuthenticated then
        Authenticated
    else
        NotAuthenticated

subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.webnativeInit WebnativeInit
