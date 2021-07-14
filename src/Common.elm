module Common exposing
    ( MarkdownNoteRef
    , WNFSEntry
    , decodeMetadata
    , decodeWNFSEntry
    , isMarkdownNote
    , isNotFiltered
    , withDecoding
    )

import Json.Decode as D exposing (Decoder)
import List.Extra as List
import Maybe.Extra as Maybe


withDecoding : Decoder a -> (Result String a -> msg) -> D.Value -> msg
withDecoding decoder toMsg json =
    D.decodeValue decoder json
        |> Result.mapError D.errorToString
        |> toMsg


type alias WNFSEntry =
    { isFile : Bool
    , name : String
    , cid : String
    , metadata :
        { unixMeta :
            { mtime : Int
            , ctime : Int
            }
        }
    }


decodeWNFSEntry : Decoder WNFSEntry
decodeWNFSEntry =
    D.map4 WNFSEntry
        (D.field "isFile" D.bool)
        (D.field "name" D.string)
        (D.field "cid" D.string)
        (D.field "metadata" decodeMetadata)


decodeMetadata : Decoder { unixMeta : { mtime : Int, ctime : Int } }
decodeMetadata =
    D.map2
        (\mtime ctime ->
            { unixMeta =
                { mtime = mtime
                , ctime = ctime
                }
            }
        )
        (D.at [ "unixMeta", "mtime" ] D.int)
        (D.at [ "unixMeta", "ctime" ] D.int)



-- MarkdownNote


type alias MarkdownNoteRef =
    { name : String
    , modificationTime : Int
    , creationTime : Int
    }


isMarkdownNote : WNFSEntry -> Maybe MarkdownNoteRef
isMarkdownNote entry =
    let
        ensureIsMarkdown ( name, extension ) =
            -- we require lowercase "md", because we will always save as .md
            if extension == "md" then
                Just name

            else
                Nothing
    in
    if entry.isFile then
        entry.name
            |> splitLast "."
            |> Maybe.andThen ensureIsMarkdown
            |> Maybe.map
                (\name ->
                    { name = name
                    , modificationTime = entry.metadata.unixMeta.mtime
                    , creationTime = entry.metadata.unixMeta.ctime
                    }
                )

    else
        Nothing


splitLast : String -> String -> Maybe ( String, String )
splitLast needle haystack =
    haystack
        |> String.split needle
        |> List.unconsLast
        |> Maybe.map
            (\( last, rest ) ->
                ( rest |> String.join needle
                , last
                )
            )


isNotFiltered : String -> MarkdownNoteRef -> Maybe MarkdownNoteRef
isNotFiltered needle markdownNote =
    let
        haystack =
            String.toLower markdownNote.name

        lowerNeedle =
            String.toLower needle

        stripAfterLetter needleLetter maybeHaystackRest =
            maybeHaystackRest
                |> Maybe.andThen
                    (\haystackRest ->
                        case String.indices (String.fromChar needleLetter) haystackRest of
                            [] ->
                                Nothing

                            index :: _ ->
                                Just (String.dropLeft (index + 1) haystackRest)
                    )
    in
    if
        lowerNeedle
            |> String.foldl stripAfterLetter (Just haystack)
            |> Maybe.isJust
    then
        Just markdownNote

    else
        Nothing
