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
    , correlationStreamName : Maybe String
    , rawData : String
    , rawMetadata : String
    , dataTreeState : JsonTree.State
    , metadataTreeState : JsonTree.State
    }


type alias Model =
    { eventId : String
    , event : Maybe Event
    }


initModel : String -> Model
initModel eventId =
    { eventId = eventId
    , event = Nothing
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
            case model.event of
                Just event ->
                    ( { model | event = Just { event | dataTreeState = newState } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ChangeOpenedEventMetadataTreeState newState ->
            case model.event of
                Just event ->
                    ( { model | event = Just { event | metadataTreeState = newState } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        GetEvent (Ok result) ->
            ( { model | event = Just (apiEventToEvent result) }, Cmd.none )

        GetEvent (Err errorMessage) ->
            ( model, Cmd.none )


apiEventToEvent : Api.Event -> Event
apiEventToEvent e =
    { eventType = e.eventType
    , eventId = e.eventId
    , createdAt = e.createdAt
    , rawData = e.rawData
    , rawMetadata = e.rawMetadata
    , correlationStreamName = e.correlationStreamName
    , dataTreeState = JsonTree.defaultState
    , metadataTreeState = JsonTree.defaultState
    }



-- VIEW


view : Model -> Html Msg
view model =
    case model.event of
        Just event ->
            showEvent event

        Nothing ->
            div [ class "event" ]
                [ text "There's no event of given ID" ]


showEvent : Event -> Html Msg
showEvent event =
    div [ class "event" ]
        [ h1 [ class "event__title" ] [ text event.eventType ]
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
                        [ td [] [ text event.eventId ]
                        , td [] [ showJsonTree event.rawData event.dataTreeState (\s -> ChangeOpenedEventDataTreeState s) ]
                        , td [] [ showJsonTree event.rawMetadata event.metadataTreeState (\s -> ChangeOpenedEventMetadataTreeState s) ]
                        ]
                    ]
                ]
            ]
        , relatedStreams event
        ]

relatedStreams : Event -> Html Msg
relatedStreams event =
    let
        links = relatedStreamsList event
    in
        if links == []
        then text ""
        else
            div [ class "event__related-streams" ]
                [ h2 [] [ text "Related streams" ]
                , ul [] (relatedStreamsList event)
                ]

relatedStreamsList : Event -> List (Html Msg)
relatedStreamsList event =
    case event.correlationStreamName of
        Just streamName ->
            [ li []
                [ text "Correlation stream: "
                , a [ href ("/#streams/" ++ streamName) ] [ text streamName ] ]
            ]
        Nothing -> []


showJsonTree : String -> JsonTree.State -> (JsonTree.State -> msg) -> Html msg
showJsonTree rawJson treeState changeState =
    JsonTree.parseString rawJson
        |> Result.map (\tree -> JsonTree.view tree { onSelect = Nothing, toMsg = changeState } treeState)
        |> Result.withDefault (pre [] [ text rawJson ])
