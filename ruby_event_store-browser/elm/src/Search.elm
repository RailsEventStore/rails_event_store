module Search exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, id, list, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import WrappedModel exposing (WrappedModel)


type alias Stream =
    String


type alias Model =
    { streams : List Stream
    , value : Stream
    }


type Msg
    = StreamChanged Stream
    | GoToStream Stream


init : Model
init =
    { streams = []
    , value = ""
    }


update : Msg -> WrappedModel Model -> (String -> Cmd Msg) -> ( WrappedModel Model, Cmd Msg )
update msg model onSubmit =
    case msg of
        StreamChanged stream ->
            let
                internal =
                    model.internal

                updatedInternal =
                    { internal | value = stream }

                wrappedModel =
                    { model | internal = updatedInternal }
            in
            ( wrappedModel, Cmd.none )

        GoToStream stream ->
            ( model, onSubmit stream )


view : Model -> Html Msg
view model =
    form [ onSubmit (GoToStream model.value) ]
        [ input
            [ class "rounded px-4 py-2"
            , value model.value
            , onInput StreamChanged
            , placeholder "Go to stream..."
            , list "streams"
            ]
            []
        , datalist
            [ id "streams" ]
            []
        ]
