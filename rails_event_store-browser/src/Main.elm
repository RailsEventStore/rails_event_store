module Main exposing (..)

import Html exposing (Html, ul, li, text, div, input)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput)


main : Program Never Model Msg
main =
    Html.beginnerProgram { model = model, view = view, update = update }


type alias Model =
    { streams : List Stream
    , searchQuery : String
    }


type Msg
    = Search String


type Stream
    = Stream String


model : Model
model =
    { streams =
        [ Stream "Inventory::Product$1"
        , Stream "Inventory::Product$2"
        ]
    , searchQuery = ""
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Search inputValue ->
            { model | searchQuery = inputValue }


isMatch : String -> Stream -> Bool
isMatch searchQuery (Stream name) =
    String.contains searchQuery name


view : Model -> Html Msg
view model =
    div []
        [ input [ placeholder "Search", onInput Search ] []
        , ul []
            (List.map
                displayStream
                (List.filter
                    (isMatch model.searchQuery)
                    model.streams
                )
            )
        ]


displayStream : Stream -> Html Msg
displayStream (Stream name) =
    li [] [ text name ]
