module OpenedEventUI exposing (..)

import JsonTree
import Html exposing (..)
import Html.Attributes exposing (placeholder, disabled, href, class)


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
    }


type alias Model =
    { event : Event
    , dataTreeState : JsonTree.State
    , metadataTreeState : JsonTree.State
    }


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State


initModel : Event -> Model
initModel e =
    { event = e
    , dataTreeState = JsonTree.defaultState
    , metadataTreeState = JsonTree.defaultState
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeOpenedEventDataTreeState newState ->
            ( { model | dataTreeState = newState }, Cmd.none )

        ChangeOpenedEventMetadataTreeState newState ->
            ( { model | metadataTreeState = newState }, Cmd.none )


showEvent : Model -> Html Msg
showEvent model =
    div [ class "event" ]
        [ h1 [ class "event__title" ] [ text model.event.eventType ]
        , div [ class "event__body" ]
            [ table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event id" ]
                        , th [] [ text "Raw Data" ]
                        , th [] [ text "Raw Metadata" ]
                        ]
                    ]
                , tbody []
                    [ tr []
                        [ td [] [ text model.event.eventId ]
                        , td [] [ showJsonTree model.event.rawData model.dataTreeState (\s -> (ChangeOpenedEventDataTreeState s)) ]
                        , td [] [ showJsonTree model.event.rawMetadata model.metadataTreeState (\s -> (ChangeOpenedEventMetadataTreeState s)) ]
                        ]
                    ]
                ]
            ]
        ]


showJsonTree : String -> JsonTree.State -> (JsonTree.State -> msg) -> Html msg
showJsonTree rawJson treeState changeState =
    JsonTree.parseString rawJson
        |> Result.map (\tree -> JsonTree.view tree ({ onSelect = Nothing, toMsg = changeState }) treeState)
        |> Result.withDefault (pre [] [ text rawJson ])
