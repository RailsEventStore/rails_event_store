module Page.Debug exposing (..)

import Html exposing (..)
import Flags exposing (Flags)

type alias Model = { resVersion : String, repositoryAdapter : String }

init : Flags -> Model
init flags  =
  { resVersion = flags.resVersion, repositoryAdapter = flags.repositoryAdapter }

view: Model -> Html a
view model =
    div [] [
        p [] [text ("RubyEventStore version: " ++ model.resVersion)],
        p [] [text ("RubyEventStore adapter: " ++ model.repositoryAdapter)]
    ]
