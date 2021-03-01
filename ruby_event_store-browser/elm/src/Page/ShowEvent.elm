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
import Url



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
    , event : Api.RemoteResource Event
    , flags : Flags
    , causedEvents : Api.RemoteResource (List Api.Event)
    }


initModel : Flags -> String -> Model
initModel flags eventId =
    { eventId = eventId
    , event = Api.Loading
    , flags = flags
    , causedEvents = Api.Loading
    }



-- UPDATE


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State
    | EventFetched (Result Http.Error Api.Event)
    | CausedEventsFetched (Result Http.Error (Api.PaginatedList Api.Event))
    | CausedStreamFetched (Result Http.Error Api.Stream)


initCmd : Flags -> String -> Cmd Msg
initCmd flags eventId =
    getEvent flags eventId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeOpenedEventDataTreeState newState ->
            case model.event of
                Api.Loaded event ->
                    ( { model | event = Api.Loaded { event | dataTreeState = newState } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ChangeOpenedEventMetadataTreeState newState ->
            case model.event of
                Api.Loaded event ->
                    ( { model | event = Api.Loaded { event | metadataTreeState = newState } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EventFetched (Ok result) ->
            let
                event =
                    apiEventToEvent result
            in
            ( { model | event = Api.Loaded event }, getCausedEvents model.flags event )

        EventFetched (Err (Http.BadStatus 404)) ->
            ( { model | event = Api.NotFound }, Cmd.none )

        EventFetched (Err _) ->
            ( { model | event = Api.Failure }, Cmd.none )

        CausedStreamFetched (Ok streamResource) ->
            ( model, Api.getEvents CausedEventsFetched streamResource.eventsRelationshipLink )

        CausedStreamFetched (Err errorMessage) ->
            ( { model | causedEvents = Api.Failure }, Cmd.none )

        CausedEventsFetched (Ok result) ->
            ( { model | causedEvents = Api.Loaded result.events }, Cmd.none )

        CausedEventsFetched (Err errorMessage) ->
            ( { model | causedEvents = Api.Failure }, Cmd.none )


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
            Api.getStream CausedStreamFetched flags streamName

        Nothing ->
            Cmd.none



-- VIEW


view : Model -> ( String, Html Msg )
view model =
    ( "Event " ++ model.eventId, view_ model )


centralSpinner : Html Msg
centralSpinner =
    div [ class "central-spinner" ] [ spinner ]


spinner : Html Msg
spinner =
    div [ class "lds-dual-ring" ] []


view_ : Model -> Html Msg
view_ model =
    case model.event of
        Api.NotFound ->
            div [ class "event" ]
                [ h1 [ class "event__missing" ] [ text "There's no event with given ID" ] ]

        Api.Loading ->
            centralSpinner

        Api.Loaded event ->
            showEvent model.flags.rootUrl event model.causedEvents

        Api.Failure ->
            div [ class "event" ]
                [ h1 [ class "event__missing" ] [ text "Unexpected request failure happened when fetching the event" ] ]


showEvent : Url.Url -> Event -> Api.RemoteResource (List Api.Event) -> Html Msg
showEvent baseUrl event maybeCausedEvents =
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
        , relatedStreams baseUrl event
        , case maybeCausedEvents of
            Api.Loading ->
                div [ class "event__caused-events" ]
                    [ h2 [] [ text "Events caused by this event:" ]
                    , text "Loading..."
                    ]

            Api.Loaded causedEvents ->
                case causedEvents of
                    [] ->
                        div [ class "event__caused-events" ]
                            [ h2 [] [ text "Events caused by this event: none" ]
                            ]

                    _ ->
                        div [ class "event__caused-events" ]
                            [ h2 [] [ text "Events caused by this event:" ]
                            , renderCausedEvents baseUrl causedEvents
                            ]

            _ ->
                text ""
        ]


relatedStreams : Url.Url -> Event -> Html Msg
relatedStreams baseUrl event =
    let
        links =
            relatedStreamsList baseUrl event
    in
    if links == [] then
        text ""

    else
        div [ class "event__related-streams" ]
            [ h2 [] [ text "Related streams / events:" ]
            , ul [] (relatedStreamsList baseUrl event)
            ]


relatedStreamsList : Url.Url -> Event -> List (Html Msg)
relatedStreamsList baseUrl event =
    values
        [ parentEventLink baseUrl event
        , Just (typeStreamLink baseUrl event)
        , correlationStreamLink baseUrl event
        , causationStreamLink baseUrl event
        ]


correlationStreamLink : Url.Url -> Event -> Maybe (Html Msg)
correlationStreamLink baseUrl event =
    Maybe.map
        (\streamName ->
            li []
                [ text "Correlation stream: "
                , streamLink baseUrl streamName
                ]
        )
        event.correlationStreamName


typeStreamLink : Url.Url -> Event -> Html Msg
typeStreamLink baseUrl event =
    li []
        [ text "Type stream: "
        , streamLink baseUrl event.typeStreamName
        ]


causationStreamLink : Url.Url -> Event -> Maybe (Html Msg)
causationStreamLink baseUrl event =
    Maybe.map
        (\streamName ->
            li []
                [ text "Causation stream: "
                , streamLink baseUrl streamName
                ]
        )
        event.causationStreamName


parentEventLink : Url.Url -> Event -> Maybe (Html Msg)
parentEventLink baseUrl event =
    Maybe.map
        (\parentEventId ->
            li []
                [ text "Parent event: "
                , eventLink baseUrl parentEventId
                ]
        )
        event.parentEventId


streamLink : Url.Url -> String -> Html Msg
streamLink baseUrl streamName =
    a [ class "event__stream-link", href (Route.streamUrl baseUrl streamName) ] [ text streamName ]


eventLink : Url.Url -> String -> Html Msg
eventLink baseUrl eventId =
    a [ class "event__event-link", href (Route.eventUrl baseUrl eventId) ] [ text eventId ]


renderCausedEvents : Url.Url -> List Api.Event -> Html Msg
renderCausedEvents baseUrl causedEvents =
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
                , tbody [] (List.map (renderCausedEvent baseUrl) causedEvents)
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


renderCausedEvent : Url.Url -> Api.Event -> Html Msg
renderCausedEvent baseUrl { eventType, eventId } =
    tr []
        [ td []
            [ a
                [ class "results__link"
                , href (Route.eventUrl baseUrl eventId)
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
