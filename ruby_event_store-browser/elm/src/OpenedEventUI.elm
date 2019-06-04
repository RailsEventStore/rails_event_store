module OpenedEventUI exposing (Event, Model, Msg(..), getEvent, initCmd, initModel, showEvent, showJsonTree, update)

import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Http
import Json.Decode exposing (Decoder, Value, at, field, list, maybe, oneOf, string, succeed, value)
import Json.Decode.Pipeline exposing (optional, required, requiredAt)
import Json.Encode exposing (encode)
import JsonTree
import Route


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
    }


type alias TreedEvent =
    { event : Event
    , dataTreeState : JsonTree.State
    , metadataTreeState : JsonTree.State
    }


type alias Model =
    { eventId : String
    , treedEvent : Maybe TreedEvent
    }


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State
    | GetEvent (Result Http.Error Event)


initModel : String -> Model
initModel eventId =
    { eventId = eventId
    , treedEvent = Nothing
    }


initTreedEvent : Event -> TreedEvent
initTreedEvent e =
    { event = e
    , dataTreeState = JsonTree.defaultState
    , metadataTreeState = JsonTree.defaultState
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeOpenedEventDataTreeState newState ->
            case model.treedEvent of
                Just treedEvent ->
                    ( { model | treedEvent = Just { treedEvent | dataTreeState = newState } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ChangeOpenedEventMetadataTreeState newState ->
            case model.treedEvent of
                Just treedEvent ->
                    ( { model | treedEvent = Just { treedEvent | metadataTreeState = newState } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GetEvent (Ok result) ->
            ( { model | treedEvent = Just (initTreedEvent result) }, Cmd.none )

        GetEvent (Err errorMessage) ->
            ( model, Cmd.none )


initCmd : Flags -> String -> Cmd Msg
initCmd flags eventId =
    getEvent (Route.buildUrl flags.eventsUrl eventId)


getEvent : String -> Cmd Msg
getEvent url =
    Http.get url eventDecoder
        |> Http.send GetEvent


eventDecoder : Decoder Event
eventDecoder =
    eventDecoder_
        |> field "data"


eventDecoder_ : Decoder Event
eventDecoder_ =
    succeed Event
        |> requiredAt [ "attributes", "event_type" ] string
        |> requiredAt [ "id" ] string
        |> requiredAt [ "attributes", "metadata", "timestamp" ] string
        |> requiredAt [ "attributes", "data" ] (value |> Json.Decode.map (encode 2))
        |> requiredAt [ "attributes", "metadata" ] (value |> Json.Decode.map (encode 2))


showEvent : Model -> Html Msg
showEvent model =
    case model.treedEvent of
        Just treedEvent ->
            showEvent_ treedEvent

        Nothing ->
            div [ class "event" ] []


showEvent_ : TreedEvent -> Html Msg
showEvent_ treedEvent =
    div [ class "event" ]
        [ h1 [ class "event__title" ] [ text treedEvent.event.eventType ]
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
                        [ td [] [ text treedEvent.event.eventId ]
                        , td [] [ showJsonTree treedEvent.event.rawData treedEvent.dataTreeState (\s -> ChangeOpenedEventDataTreeState s) ]
                        , td [] [ showJsonTree treedEvent.event.rawMetadata treedEvent.metadataTreeState (\s -> ChangeOpenedEventMetadataTreeState s) ]
                        ]
                    ]
                ]
            ]
        ]


showJsonTree : String -> JsonTree.State -> (JsonTree.State -> msg) -> Html msg
showJsonTree rawJson treeState changeState =
    JsonTree.parseString rawJson
        |> Result.map (\tree -> JsonTree.view tree { onSelect = Nothing, toMsg = changeState } treeState)
        |> Result.withDefault (pre [] [ text rawJson ])
