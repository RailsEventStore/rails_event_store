module Page.ShowEvent exposing (Model, Msg(..), initCmd, initModel, showJsonTree, subscriptions, update, view)

import Api
import BrowserTime
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, colspan, href)
import Http
import JsonTree
import Maybe
import Maybe.Extra exposing (values)
import Route
import Spinner
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
    , streams : Maybe (List String)
    }


type alias Model =
    { eventId : String
    , event : Api.RemoteResource Event
    , flags : Flags
    , causedEvents : Api.RemoteResource (List Api.Event)
    , spinner : Spinner.Model
    }


initModel : Flags -> String -> Model
initModel flags eventId =
    { eventId = eventId
    , event = Api.Loading
    , flags = flags
    , causedEvents = Api.Loading
    , spinner = Spinner.init
    }



-- UPDATE


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.map SpinnerTicked Spinner.subscription


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State
    | EventFetched (Result Http.Error Api.Event)
    | CausedEventsFetched (Result Http.Error (Api.PaginatedList Api.Event))
    | CausedStreamFetched (Result Http.Error Api.Stream)
    | SpinnerTicked Spinner.Msg


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

        CausedStreamFetched (Err _) ->
            ( { model | causedEvents = Api.Failure }, Cmd.none )

        CausedEventsFetched (Ok result) ->
            ( { model | causedEvents = Api.Loaded result.events }, Cmd.none )

        CausedEventsFetched (Err _) ->
            ( { model | causedEvents = Api.Failure }, Cmd.none )

        SpinnerTicked spinnerMsg ->
            let
                spinnerModel =
                    Spinner.update spinnerMsg model.spinner
            in
            ( { model | spinner = spinnerModel }, Cmd.none )


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
    , streams = e.streams
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


view_ : Model -> Html Msg
view_ model =
    case model.event of
        Api.NotFound ->
            div
                [ class "py-12"
                ]
                [ h1
                    [ class "font-bold px-8 text-2xl"
                    ]
                    [ text "There's no event with given ID" ]
                ]

        Api.Loading ->
            div [ class "min-h-screen" ]
                [ Spinner.view Spinner.defaultConfig model.spinner
                ]

        Api.Loaded event ->
            showEvent model.flags.rootUrl event model.causedEvents

        Api.Failure ->
            div
                [ class "py-12"
                ]
                [ h1
                    [ class "font-bold px-8 text-2xl"
                    ]
                    [ text "Unexpected request failure happened when fetching the event" ]
                ]


showEvent : Url.Url -> Event -> Api.RemoteResource (List Api.Event) -> Html Msg
showEvent baseUrl event maybeCausedEvents =
    div
        [ class "py-12 px-4 lg:px-8 space-y-10"
        ]
        [ h1
            [ class "font-bold text-2xl"
            ]
            [ text event.eventType ]
        , div
            []
            [ div
                [ class "w-full text-left grid md:grid-cols-3 gap-8 overflow-hidden"
                ]
                [ section [ class "space-y-4" ]
                    [ h2 [ class "border-gray-400 border-b text-gray-500 uppercase font-bold text-xs pb-2" ] [ text "Event ID" ]
                    , div [ class "text-sm font-medium font-mono" ] [ text event.eventId ]
                    ]
                , section [ class "space-y-4" ]
                    [ h2 [ class "border-gray-400 border-b text-gray-500 uppercase font-bold text-xs pb-2" ] [ text "Raw Data" ]
                    , div [ class "overflow-auto w-full" ] [ showJsonTree event.rawData event.dataTreeState (\s -> ChangeOpenedEventDataTreeState s) ]
                    ]
                , section [ class "space-y-4" ]
                    [ h2 [ class "border-gray-400 border-b text-gray-500 uppercase font-bold text-xs pb-2" ] [ text "Raw Metadata" ]
                    , div [ class "overflow-auto w-full" ] [ showJsonTree event.rawMetadata event.metadataTreeState (\s -> ChangeOpenedEventMetadataTreeState s) ]
                    ]
                ]
            ]
        , streamsOfEvent baseUrl event
        , relatedStreams baseUrl event
        , case maybeCausedEvents of
            Api.Loading ->
                div
                    []
                    [ h2
                        [ class "font-bold text-xl"
                        ]
                        [ text "Events caused by this event:" ]
                    , text "Loading..."
                    ]

            Api.Loaded causedEvents ->
                case causedEvents of
                    [] ->
                        div
                            []
                            [ h2
                                [ class "font-bold text-xl"
                                ]
                                [ text "Events caused by this event: none" ]
                            ]

                    _ ->
                        div
                            [ class "space-y-4" ]
                            [ h2
                                [ class "font-bold text-xl"
                                ]
                                [ text "Events caused by this event:" ]
                            , renderCausedEvents baseUrl causedEvents
                            ]

            _ ->
                text ""
        ]


streamsOfEvent : Url.Url -> Event -> Html Msg
streamsOfEvent baseUrl event =
    case event.streams of
        Just streams ->
            div
                []
                [ h2
                    [ class "font-bold text-xl"
                    ]
                    [ text "Event streams" ]
                , ul
                    [ class "list-disc pl-8"
                    ]
                    (List.map (\id -> li [] [ streamLink baseUrl id ]) (List.sort streams))
                ]

        Nothing ->
            text ""


relatedStreams : Url.Url -> Event -> Html Msg
relatedStreams baseUrl event =
    let
        links =
            relatedStreamsList baseUrl event
    in
    if links == [] then
        text ""

    else
        div
            []
            [ h2
                [ class "font-bold text-xl"
                ]
                [ text "Related" ]
            , ul
                [ class "list-disc pl-8"
                ]
                (relatedStreamsList baseUrl event)
            ]


relatedStreamsList : Url.Url -> Event -> List (Html Msg)
relatedStreamsList baseUrl event =
    values
        [ parentEventLink baseUrl event
        ]


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
    a
        [ class "text-red-700 no-underline"
        , href (Route.streamUrl baseUrl streamName)
        ]
        [ text streamName ]


eventLink : Url.Url -> String -> Html Msg
eventLink baseUrl eventId =
    a
        [ class "text-red-700 no-underline"
        , href (Route.eventUrl baseUrl eventId)
        ]
        [ text eventId ]


renderCausedEvents : Url.Url -> List Api.Event -> Html Msg
renderCausedEvents baseUrl causedEvents =
    case causedEvents of
        [] ->
            p
                [ class "flex items-center justify-center py-24"
                ]
                [ text "No items" ]

        _ ->
            table
                [ class "w-full text-left table-fixed border-collapse"
                ]
                [ thead
                    [ class "align-bottom leading-tight"
                    ]
                    [ tr []
                        [ th
                            [ class "border-gray-400 border-b text-gray-500 uppercase p-0 pb-2 text-xs"
                            ]
                            [ text "Event name" ]
                        , th
                            [ class "border-gray-400 border-b text-gray-500 uppercase p-0 pb-2 text-xs"
                            ]
                            [ text "Event id" ]
                        ]
                    ]
                , tbody [ class "align-top" ] (List.map (renderCausedEvent baseUrl) causedEvents)
                , tfoot []
                    [ tr []
                        [ td
                            [ class "text-gray-500 p-0 pb-4 text-xs"
                            , colspan 2
                            ]
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
        [ td
            [ class "p-0 pt-2"
            ]
            [ a
                [ class "text-red-700 no-underline"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventType ]
            ]
        , td
            [ class "p-0 pt-2"
            ]
            [ text eventId ]
        ]


showJsonTree : String -> JsonTree.State -> (JsonTree.State -> msg) -> Html msg
showJsonTree rawJson treeState changeState =
    JsonTree.parseString rawJson
        |> Result.map
            (\tree ->
                JsonTree.view tree
                    { onSelect = Nothing
                    , toMsg = changeState
                    , colors = JsonTree.defaultColors
                    }
                    treeState
            )
        |> Result.withDefault
            (pre [] [ text rawJson ])
