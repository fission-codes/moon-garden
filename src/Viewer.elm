module Viewer exposing (..)

import Browser
import Browser.Navigation as Navigation
import Html.Styled as Html exposing (Html)
import Routes
import Tailwind.Utilities exposing (..)
import Url exposing (Url)
import View


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | UsernameChanged String
    | UsernameSubmitted


type alias Model =
    { url : Url
    , navKey : Navigation.Key
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
        , onUrlRequest = LinkClicked
        }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url navKey =
    ( { url = url
      , navKey = navKey
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

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

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    { title = "🌛 Moon Garden 🌱"
    , body = [ Html.toUnstyled <| viewBody model ]
    }


post =
    """A [\\[\\[Journal\\]\\]](/#/edit-note/Journal) entry.

* I need to figure out a way to handle the Elm cache.
  I don't yet really know how to do this. It's annoying.
  Renames and deletions are particularly tricky.
* I want to build the viewer portion

## What is this?

```js
async function loadFS() {
    // ...
}
```

### Amazing

I think a lot about "declarative" vs "imperative" recently.
We could represent the filesystem declaratively or we could do imperative changes on it.
Why not say "make sure there's a file with this content" instead of saying "make this file have this content".
Or why not say "I want these files in this directory", instead of saying "remove this, add this, etc.".

The thing is, you don't want the **whole filesystem** in memory at once.

So you won't be able to say "I want this exact state of the filesystem", you need a way to say "I don't care about these files, but I want this to be the structure in the filesystem apart from that".

Or maybe you need a way to handle whole subtrees/files as an identity. Saying "whatever was at `Documents/Test.md`, I now want at `Documents/Notes/Test.md`". Or "whatever was at `public/Apps/Published/a` I now want at `public/Apps/Published/b`".

---

I get that it's weird. At the end-user level we're doing *imperative changes*. "Add some text here, change the title there, check some checkmark here."
Should we convert that into a declarative view of data? And then convert that back into changes?
It all seems so weird.
But at the same time, we like to write code that depends on the current state of the system, not on changes.
So either, we have to implement our algorithms given some changes, or we have to convert our deltas into a concrete state.
"""


viewBody : Model -> Html Msg
viewBody _ =
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
                { location = Routes.toLink (Routes.Editor Routes.Dashboard)
                , label = [ Html.text "build your own moon garden" ]
                }
            , Html.text " with fission."
            ]
        ]
