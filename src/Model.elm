module Model exposing (Model (..))


type Model
    = Unauthenticated NonAuthed
    | Authenticated

type NonAuthed
    = Loading
    | Cancelled
