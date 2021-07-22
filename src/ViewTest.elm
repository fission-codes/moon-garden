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
view _ =
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
            -- viewDashboardEmpty
            viewNote
        ]
    }


viewEditor : Model -> Html Msg
viewEditor model =
    View.appShellSidebar
        { navigation =
            List.concat
                [ [ View.leafyButton
                        { label = "Create New Note"
                        , onClick = Just NoOp
                        , styles = []
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
                            , link = ""
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
        , mainId = ""
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
viewDashboard _ =
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
        , View.leafyButton { onClick = Just NoOp, label = "Create New Note", styles = [] }
        ]


viewNote : Html Msg
viewNote =
    View.appShellSidebar
        { navigation =
            [ View.wikilinksSection
                { styles = [ mt_8 ]
                , wikilinks =
                    [ View.wikilinkExisting { label = "WNFS", link = "#" }
                    , View.wikilinkExisting { label = "Fission", link = "#" }
                    , View.wikilinkNew { label = "Markdown", onClickCreate = NoOp }
                    ]
                }
            ]
        , mainId = ""
        , main =
            [ View.renderedDocument
                { title = "Moon Garden"
                , markdownContent = markdownExample
                }
            ]
        }


markdownExample : String
markdownExample =
    """An h1 header
============

Paragraphs are separated by a blank line.

2nd paragraph. *Italic*, **bold**, and `monospace`. Itemized lists
look like:

  * this one
  * that one
  * the other one

Note that --- not considering the asterisk --- the actual text
content starts at 4-columns in.

> Block quotes are
> written like so.
>
> They can span multiple paragraphs,
> if you like.

Use 3 dashes for an em-dash. Use 2 dashes for ranges (ex., "it's all
in chapters 12--14"). Three dots ... will be converted to an ellipsis.
Unicode is supported. ☺



An h2 header
------------

Here's a numbered list:

 1. first item
 2. second item
 3. third item

Note again how the actual text starts at 4 columns in (4 characters
from the left side). Here's a code sample:

    # Let me re-iterate ...
    for i in 1 .. 10 { do-something(i) }

As you probably guessed, indented 4 spaces. By the way, instead of
indenting the block, you can use delimited blocks, if you like:

~~~
define foobar() {
    print "Welcome to flavor country!";
}
~~~

(which makes copying & pasting easier). You can optionally mark the
delimited block for Pandoc to syntax highlight it:

~~~python
import time
# Quick, count to ten!
for i in range(10):
    # (but not *too* quick)
    time.sleep(0.5)
    print(i)
~~~



### An h3 header ###

Now a nested list:

 1. First, get these ingredients:

      * carrots
      * celery
      * lentils

 2. Boil some water.

 3. Dump everything in the pot and follow
    this algorithm:

        find wooden spoon
        uncover pot
        stir
        cover pot
        balance wooden spoon precariously on pot handle
        wait 10 minutes
        goto first step (or shut off burner when done)

    Do not bump wooden spoon or it will fall.

Notice again how text always lines up on 4-space indents (including
that last line which continues item 3 above).

Here's a link to [a website](http://foo.bar), to a [local
doc](local-doc.html), and to a [section heading in the current
doc](#an-h2-header). Here's a footnote [^1].

[^1]: Some footnote text.

Tables can look like this:

Name           Size  Material      Color
------------- -----  ------------  ------------
All Business      9  leather       brown
Roundabout       10  hemp canvas   natural
Cinderella       11  glass         transparent

Table: Shoes sizes, materials, and colors.

(The above is the caption for the table.) Pandoc also supports
multi-line tables:

--------  -----------------------
Keyword   Text
--------  -----------------------
red       Sunsets, apples, and
          other red or reddish
          things.

green     Leaves, grass, frogs
          and other things it's
          not easy being.
--------  -----------------------

A horizontal rule follows.

***

Here's a definition list:

apples
  : Good for making applesauce.

oranges
  : Citrus!

tomatoes
  : There's no "e" in tomatoe.

Again, text is indented 4 spaces. (Put a blank line between each
term and  its definition to spread things out more.)

Here's a "line block" (note how whitespace is honored):

| Line one
|   Line too
| Line tree

and images can be specified like so:

![example image](example-image.jpg "An exemplary image")

Inline math equation: $\\omega = d\\phi / dt$. Display
math should get its own line like so:

$$I = \\int \\rho R^{2} dV$$

And note that you can backslash-escape any punctuation characters
which you wish to be displayed literally, ex.: \\`foo\\`, \\*bar\\*, etc.
"""
