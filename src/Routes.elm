module Routes exposing
    ( EditorRoute(..)
    , Route(..)
    , UrlRequest(..)
    , ViewerRoute(..)
    , editorFragmentRoutes
    , fromRequestInEditor
    , fromRequestInViewer
    , fromUrl
    , routes
    , toLink
    , viewerFragmentRoutes
    )

import Browser
import Url exposing (Url)
import Url.Builder as Url
import Url.Parser exposing (..)


type Route
    = Editor EditorRoute
    | Viewer ViewerRoute


type EditorRoute
    = EditorDashboard
    | EditorEditNote String


type ViewerRoute
    = ViewerDashboard


type UrlRequest route
    = Internal Url route
    | External String


fromRequestInEditor : Browser.UrlRequest -> UrlRequest EditorRoute
fromRequestInEditor req =
    case req of
        Browser.External link ->
            External link

        Browser.Internal url ->
            case fromUrl url of
                Editor route ->
                    Internal url route

                _ ->
                    External (Url.toString url)


fromRequestInViewer : Browser.UrlRequest -> UrlRequest ViewerRoute
fromRequestInViewer req =
    case req of
        Browser.External link ->
            External link

        Browser.Internal url ->
            case fromUrl url of
                Viewer route ->
                    Internal url route

                _ ->
                    External (Url.toString url)


fromUrl : Url -> Route
fromUrl url =
    parse routes url
        |> Maybe.withDefault (Editor EditorDashboard)


routes : Parser (Route -> Route) Route
routes =
    oneOf
        [ map (Maybe.withDefault EditorDashboard >> Editor)
            (top </> fragmentRoute editorFragmentRoutes)
        , map (Maybe.withDefault ViewerDashboard >> Viewer)
            (top </> s "viewer" </> fragmentRoute viewerFragmentRoutes)
        ]


editorFragmentRoutes : Parser (EditorRoute -> EditorRoute) EditorRoute
editorFragmentRoutes =
    oneOf
        [ map (EditorEditNote << Maybe.withDefault "" << Url.percentDecode)
            (top </> s "edit-note" </> string)
        , map (EditorEditNote "")
            (top </> s "edit-note")
        , map EditorDashboard
            top
        ]


viewerFragmentRoutes : Parser (ViewerRoute -> ViewerRoute) ViewerRoute
viewerFragmentRoutes =
    oneOf
        [ map ViewerDashboard
            top
        ]


toLink : Route -> String
toLink route =
    case route of
        Editor EditorDashboard ->
            "/#/"

        Editor (EditorEditNote name) ->
            "/#/edit-note/" ++ Url.percentEncode name

        Viewer ViewerDashboard ->
            "/viewer/"



-- Internal


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
