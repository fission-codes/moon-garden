module Routes exposing (..)

import Url exposing (Url)
import Url.Builder as Url
import Url.Parser exposing (..)


type Route
    = Dashboard
    | EditNote String


fromFragment : Url -> Url
fromFragment url =
    { protocol = url.protocol
    , host = url.host
    , port_ = url.port_
    , path = url.fragment |> Maybe.withDefault ""
    , query = url.query
    , fragment = Nothing
    }


parse : Url -> Maybe Route
parse url =
    Url.Parser.parse routes (fromFragment url)


routes : Parser (Route -> Route) Route
routes =
    oneOf
        [ map EditNote (s "edit-note" </> string)
        , map Dashboard top
        ]


toLink : Route -> String
toLink route =
    case route of
        Dashboard ->
            "#"

        EditNote name ->
            "#" ++ Url.percentEncode name
