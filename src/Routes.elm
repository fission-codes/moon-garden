module Routes exposing (..)

import Url exposing (Url)
import Url.Builder as Url
import Url.Parser exposing (..)


type Route
    = Editor EditorRoute


type EditorRoute
    = Dashboard
    | EditNote String


fromFragment : Maybe String -> Url
fromFragment fragment =
    { protocol = Url.Https
    , host = ""
    , port_ = Nothing
    , path = fragment |> Maybe.withDefault "/"
    , query = Nothing
    , fragment = Nothing
    }


fragmentRoute : Parser (fragment -> fragment) fragment -> Parser (Maybe fragment -> a) a
fragmentRoute fragmentParser =
    fragment
        (\frag ->
            frag
                |> fromFragment
                |> parse fragmentParser
        )


fromUrl : Url -> Route
fromUrl url =
    parse routes url
        |> Maybe.withDefault (Editor Dashboard)


routes : Parser (Route -> Route) Route
routes =
    oneOf
        [ map (Maybe.withDefault Dashboard >> Editor)
            (top </> fragmentRoute editorFragmentRoutes)
        ]


editorFragmentRoutes : Parser (EditorRoute -> EditorRoute) EditorRoute
editorFragmentRoutes =
    oneOf
        [ map (EditNote << Maybe.withDefault "" << Url.percentDecode)
            (top </> s "edit-note" </> string)
        , map (EditNote "")
            (top </> s "edit-note")
        , map Dashboard
            top
        ]


toLink : Route -> String
toLink route =
    case route of
        Editor Dashboard ->
            "/#/"

        Editor (EditNote name) ->
            "/#/edit-note/" ++ Url.percentEncode name
