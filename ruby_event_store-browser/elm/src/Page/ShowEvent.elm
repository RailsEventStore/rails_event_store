module Page.ShowEvent exposing (Model, Msg(..), initCmd, initModel, showJsonTree, update, view)

import Api
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Http
import JsonTree
import Route



-- MODEL


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
    , dataTreeState : JsonTree.State
    , metadataTreeState : JsonTree.State
    }


type alias Model =
    { eventId : String
    , treedEvent : Maybe Event
    }


initModel : String -> Model
initModel eventId =
    { eventId = eventId
    , treedEvent = Nothing
    }



-- UPDATE


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State
    | GetEvent (Result Http.Error Api.Event)


initCmd : Flags -> String -> Cmd Msg
initCmd flags eventId =
    Api.getEvent GetEvent flags eventId


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
            ( { model | treedEvent = Just (apiEventToEvent result) }, Cmd.none )

        GetEvent (Err errorMessage) ->
            ( model, Cmd.none )


apiEventToEvent : Api.Event -> Event
apiEventToEvent e =
    { eventType = e.eventType
    , eventId = e.eventId
    , createdAt = e.createdAt
    , rawData = e.rawData
    , rawMetadata = e.rawMetadata
    , dataTreeState = JsonTree.defaultState
    , metadataTreeState = JsonTree.defaultState
    }



-- VIEW


view : Model -> Html Msg
view model =
    case model.treedEvent of
        Just treedEvent ->
            showEvent treedEvent

        Nothing ->
            div [ class "event" ]
                [ text "There's no event of given ID" ]


showEvent : Event -> Html Msg
showEvent treedEvent =
    div [ class "event" ]
        [ h1 [ class "event__title" ] [ text treedEvent.eventType ]
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
                        [ td [] [ text treedEvent.eventId ]
                        , td [] [ showJsonTree treedEvent.rawData treedEvent.dataTreeState (\s -> ChangeOpenedEventDataTreeState s) ]
                        , td [] [ showJsonTree treedEvent.rawMetadata treedEvent.metadataTreeState (\s -> ChangeOpenedEventMetadataTreeState s) ]
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
