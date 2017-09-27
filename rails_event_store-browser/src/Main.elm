module Main exposing (..)

import Html exposing (Html, h1, text)


main : Program Never Model Msg
main =
    Html.beginnerProgram { model = model, view = view, update = update }


type alias Model =
    String


type Msg
    = None


model : Model
model =
    "Siemandero"


update : Msg -> Model -> Model
update _ model =
    model


view : Model -> Html Msg
view model =
    h1 [] [ text model ]
