module Page.Debug exposing (..)

import Html exposing (..)
import Flags exposing (Flags)
import Api exposing (getStats, Stats)
import Http

type alias Model = { resVersion : String, repositoryAdapter : String, eventsInTotal : String }

type Msg
  = GotStats (Result Http.Error Stats)

init : Flags -> Model
init flags  =
    { resVersion = flags.resVersion, repositoryAdapter = flags.repositoryAdapter, eventsInTotal = "" }

initCmd : Flags -> Cmd Msg
initCmd flags =
    getStats GotStats flags

view: Model -> Html a
view model =
    div [] [
        p [] [text ("RubyEventStore version: " ++ model.resVersion)],
        p [] [text ("RubyEventStore adapter: " ++ model.repositoryAdapter)],
        p [] [text ("Events in total: " ++ model.eventsInTotal)]
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotStats result ->
      case result of
        Ok stats ->
          ({ model | eventsInTotal = String.fromInt stats.eventsInTotal }, Cmd.none)
        Err _ ->
          (model, Cmd.none)