module Page.ShowEvent exposing (Model, Msg(..), initCmd, initModel, showJsonTree, update, view)

import Api
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, colspan, disabled, href, placeholder)
import Http
import JsonTree
import Maybe exposing (withDefault)
import Maybe.Extra exposing (values)
import Route



-- MODEL


type alias Event =
    { eventType : String
    , eventId : String
    , correlationStreamName : Maybe String
    , causationStreamName : Maybe String
    , typeStreamName : String
    , parentEventId : Maybe String
    , rawData : String
    , rawMetadata : String
    , dataTreeState : JsonTree.State
    , metadataTreeState : JsonTree.State
    }


type alias Model =
    { eventId : String
    , event : Maybe Event
    , flags : Flags
    , causedEvents : Maybe (List Api.Event)
    }


initModel : Flags -> String -> Model
initModel flags eventId =
    { eventId = eventId
    , event = Nothing
    , flags = flags
    , causedEvents = Nothing
    }



-- UPDATE


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State
    | EventFetched (Result Http.Error Api.Event)
    | CausedEventsFetched (Result Http.Error (Api.PaginatedList Api.Event))


initCmd : Flags -> String -> Cmd Msg
initCmd flags eventId =
    getEvent flags eventId


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

        EventFetched (Ok result) ->
            let
                event =
                    apiEventToEvent result
            in
            ( { model | event = Just event }, getCausedEvents model.flags event )

        EventFetched (Err errorMessage) ->
            ( model, Cmd.none )

        CausedEventsFetched (Ok result) ->
            ( { model | causedEvents = Just result.events }, Cmd.none )

        CausedEventsFetched (Err errorMessage) ->
            ( model, Cmd.none )


apiEventToEvent : Api.Event -> Event
apiEventToEvent e =
    { eventType = e.eventType
    , eventId = e.eventId
    , rawData = e.rawData
    , rawMetadata = e.rawMetadata
    , correlationStreamName = e.correlationStreamName
    , causationStreamName = e.causationStreamName
    , typeStreamName = e.typeStreamName
    , parentEventId = e.parentEventId
    , dataTreeState = JsonTree.defaultState
    , metadataTreeState = JsonTree.defaultState
    }


getEvent : Flags -> String -> Cmd Msg
getEvent flags eventId =
    Api.getEvent EventFetched flags eventId


getCausedEvents : Flags -> Event -> Cmd Msg
getCausedEvents flags event =
    case event.causationStreamName of
        Just streamName ->
            Api.getEvents CausedEventsFetched (Route.buildUrl flags.streamsUrl streamName)

        Nothing ->
            Cmd.none



-- VIEW


view : Model -> ( String, Html Msg )
view model =
    ( "Event " ++ model.eventId, view_ model )


view_ : Model -> Html Msg
view_ model =
    case model.event of
        Just event ->
            showEvent event model.causedEvents

        Nothing ->
            div [ class "event" ]
                [ h1 [ class "event__missing" ] [ text "There's no event with given ID" ] ]


showEvent : Event -> Maybe (List Api.Event) -> Html Msg
showEvent event maybeCausedEvents =
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
        , case maybeCausedEvents of
            Just causedEvents ->
                case causedEvents of
                    [] ->
                        div [ class "event__caused-events" ]
                            [ h2 [] [ text "Events caused by this event: none" ]
                            ]

                    _ ->
                        div [ class "event__caused-events" ]
                            [ h2 [] [ text "Events caused by this event:" ]
                            , renderCausedEvents causedEvents
                            ]

            Nothing ->
                text ""
        ]


relatedStreams : Event -> Html Msg
relatedStreams event =
    let
        links =
            relatedStreamsList event
    in
    if links == [] then
        text ""

    else
        div [ class "event__related-streams" ]
            [ h2 [] [ text "Related streams / events:" ]
            , ul [] (relatedStreamsList event)
            ]


relatedStreamsList : Event -> List (Html Msg)
relatedStreamsList event =
    values
        [ parentEventLink event
        , Just (typeStreamLink event)
        , correlationStreamLink event
        , causationStreamLink event
        ]


correlationStreamLink : Event -> Maybe (Html Msg)
correlationStreamLink event =
    Maybe.map
        (\streamName ->
            li []
                [ text "Correlation stream: "
                , streamLink streamName
                ]
        )
        event.correlationStreamName


typeStreamLink : Event -> Html Msg
typeStreamLink event =
    li []
        [ text "Type stream: "
        , streamLink event.typeStreamName
        ]


causationStreamLink : Event -> Maybe (Html Msg)
causationStreamLink event =
    Maybe.map
        (\streamName ->
            li []
                [ text "Causation stream: "
                , streamLink streamName
                ]
        )
        event.causationStreamName


parentEventLink : Event -> Maybe (Html Msg)
parentEventLink event =
    Maybe.map
        (\parentEventId ->
            li []
                [ text "Parent event: "
                , eventLink parentEventId
                ]
        )
        event.parentEventId


streamLink : String -> Html Msg
streamLink streamName =
    a [ class "event__stream-link", href (Route.buildUrl "#streams" streamName) ] [ text streamName ]


eventLink : String -> Html Msg
eventLink eventId =
    a [ class "event__event-link", href (Route.buildUrl "#events" eventId) ] [ text eventId ]


renderCausedEvents : List Api.Event -> Html Msg
renderCausedEvents causedEvents =
    case causedEvents of
        [] ->
            p [ class "results__empty" ] [ text "No items" ]

        _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event name" ]
                        , th [] [ text "Event id" ]
                        ]
                    ]
                , tbody [] (List.map renderCausedEvent causedEvents)
                , tfoot []
                    [ tr []
                        [ td [ colspan 2 ]
                            [ if List.length causedEvents == 20 then
                                text "The results may be truncated, check stream for full information."

                              else
                                text ""
                            ]
                        ]
                    ]
                ]


renderCausedEvent : Api.Event -> Html Msg
renderCausedEvent { eventType, eventId } =
    tr []
        [ td []
            [ a
                [ class "results__link"
                , href (Route.buildUrl "#events" eventId)
                ]
                [ text eventType ]
            ]
        , td [] [ text eventId ]
        ]


showJsonTree : String -> JsonTree.State -> (JsonTree.State -> msg) -> Html msg
showJsonTree rawJson treeState changeState =
    JsonTree.parseString rawJson
        |> Result.map (\tree -> JsonTree.view tree { onSelect = Nothing, toMsg = changeState, colors = JsonTree.defaultColors } treeState)
        |> Result.withDefault (pre [] [ text rawJson ])
