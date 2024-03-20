module Page.Debug exposing (..)

import Html exposing (..)

type alias Model = { resVersion : String }

init : String -> Model
init resVersion =
  { resVersion = resVersion }

view: Model -> Html a
view model =
    text ("RubyEventStore version: " ++ model.resVersion)
