port module Page.ShowEvent exposing (Model, Msg(..), initCmd, initModel, showJsonTree, update, view)

import Api
import BrowserTime
import FeatherIcons
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (attribute, class, colspan, href, selected)
import Html.Events exposing (onClick)
import Http
import JsonTree
import Maybe
import Maybe.Extra exposing (values)
import Pagination
import Route
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Time exposing (Posix, posixToMillis)
import Url



-- MODEL


type alias Event =
    { eventType : String
    , eventId : String
    , correlationStreamName : Maybe String
    , causationStreamName : Maybe String
    , createdAt : Posix
    , typeStreamName : String
    , parentEventId : Maybe String
    , rawData : String
    , rawMetadata : String
    , dataTreeState : JsonTree.State
    , metadataTreeState : JsonTree.State
    , streams : Maybe (List String)
    , validAt : Posix
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



-- PORT


port copyToClipboard : String -> Cmd msg



-- UPDATE


type Msg
    = ChangeOpenedEventDataTreeState JsonTree.State
    | ChangeOpenedEventMetadataTreeState JsonTree.State
    | EventFetched (Result Http.Error Api.Event)
    | CausedEventsFetched (Result Http.Error (Api.PaginatedList Api.Event))
    | CausedStreamFetched (Result Http.Error Api.Stream)
    | Copy String


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

        Copy content ->
            ( model, copyToClipboard content )

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
            ( model
            , case causationStreamName model.event of
                Just streamName ->
                    Api.getEvents CausedEventsFetched model.flags streamName Pagination.empty

                Nothing ->
                    Cmd.none
            )

        CausedStreamFetched (Err _) ->
            ( { model | causedEvents = Api.Failure }, Cmd.none )

        CausedEventsFetched (Ok result) ->
            ( { model | causedEvents = Api.Loaded result.events }, Cmd.none )

        CausedEventsFetched (Err _) ->
            ( { model | causedEvents = Api.Failure }, Cmd.none )


apiEventToEvent : Api.Event -> Event
apiEventToEvent e =
    { eventType = e.eventType
    , eventId = e.eventId
    , rawData = e.rawData
    , rawMetadata = e.rawMetadata
    , correlationStreamName = e.correlationStreamName
    , causationStreamName = e.causationStreamName
    , createdAt = e.createdAt
    , typeStreamName = e.typeStreamName
    , parentEventId = e.parentEventId
    , dataTreeState = JsonTree.defaultState
    , metadataTreeState = JsonTree.defaultState
    , streams = e.streams
    , validAt = e.validAt
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


view : Model -> BrowserTime.TimeZone -> ( String, Html Msg )
view model selectedTime =
    ( "Event " ++ model.eventId, view_ model selectedTime )


view_ : Model -> BrowserTime.TimeZone -> Html Msg
view_ model selectedTime =
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
            div
                [ class "grow grid place-items-center"
                , attribute "role" "status"
                ]
                [ svg
                    [ attribute "aria-hidden" "true"
                    , SvgAttr.class "size-20 text-gray-200 animate-spin fill-red-500"
                    , SvgAttr.viewBox "0 0 100 101"
                    , SvgAttr.fill "none"
                    ]
                    [ path
                        [ SvgAttr.d "M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                        , SvgAttr.fill "currentColor"
                        ]
                        []
                    , path
                        [ SvgAttr.d "M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                        , SvgAttr.fill "currentFill"
                        ]
                        []
                    ]
                , span
                    [ class "sr-only"
                    ]
                    [ text "Loading..." ]
                ]

        Api.Loaded event ->
            showEvent model.flags.rootUrl event model.causedEvents selectedTime

        Api.Failure ->
            div
                [ class "py-12"
                ]
                [ h1
                    [ class "font-bold px-8 text-2xl"
                    ]
                    [ text "Unexpected request failure happened when fetching the event" ]
                ]


showEvent : Url.Url -> Event -> Api.RemoteResource (List Api.Event) -> BrowserTime.TimeZone -> Html Msg
showEvent baseUrl event maybeCausedEvents selectedTime =
    div
        [ class "py-8 md:py-12  container mx-auto space-y-10"
        ]
        [ header
            [ class "flex items-start justify-between gap-4 flex-wrap md:flex-nowrap"
            ]
            [ div [ class "flex flex-col"]
                [ h1
                    [ class "font-bold text-2xl break-words min-w-0 mb-2"
                    ]
                    [ text event.eventType ]
                , p [ class "flex gap-2 md:items-center min-w-0 text-sm flex-wrap"]
                    [ 
                        span [ class "whitespace-nowrap text-xs text-gray-500 uppercase font-bold uppercase"] 
                        [ text "Event ID:"
                        ],
                        
                        button [ class "flex items-center text-left gap-2 group font-mono text-gray-800 font-bold text-sm", onClick (Copy event.eventId) ]
                        [ text event.eventId
                        , FeatherIcons.clipboard
                            |> FeatherIcons.withClass "size-4 -translate-y-0.5 opacity-0 group-hover:opacity-100 "
                            |> FeatherIcons.toHtml []
                        ]
                    ]
                ]
            , div
                [ class "space-y-4"
                ]
                [ section [ class "space-y-1 pt-3" ]
                    [ header [ class "flex items-center gap-1  text-xs" ]
                        [ FeatherIcons.clock
                            |> FeatherIcons.withClass "size-3 text-gray-400"
                            |> FeatherIcons.toHtml []
                        , h2 [ class "text-gray-500 uppercase font-bold" ] [ text "Created at" ]
                        ]
                    , div [ class "overflow-auto w-full text-sm font-bold font-mono pl-4 text-gray-700 tracking-tight" ] [ text (BrowserTime.format selectedTime event.createdAt) ]
                    ]
                , section [ class "space-y-1" ]
                    [ header [ class "flex items-center gap-1 text-xs" ]
                        [ FeatherIcons.clock
                            |> FeatherIcons.withClass "size-3 text-gray-400"
                            |> FeatherIcons.toHtml []
                        , h2 [ class "text-gray-500 uppercase font-bold" ] [ text "Valid at" ]
                        ]
                    , div [ class "overflow-auto w-full text-sm font-bold font-mono pl-4 text-gray-700 tracking-tight" ] [ text (BrowserTime.format selectedTime event.validAt) ]
                    ]
                ]
            ]
        
        , div
            [ class "w-full text-left grid md:grid-cols-2 gap-8 overflow-hidden"
            ]
            [ section [ class "space-y-4" ]
                [ header [ class "flex justify-between border-gray-400 border-b text-xs pb-2" ]
                    [ h2 [ class "text-gray-500 uppercase font-bold" ] [ text "Raw Data" ]
                    , button [ class "text-red-700 no-underline", onClick (Copy event.rawData) ]
                        [ FeatherIcons.clipboard
                            |> FeatherIcons.withSize 16
                            |> FeatherIcons.withClass "text-gray-400 hover:text-red-700"
                            |> FeatherIcons.toHtml []
                        ]
                    ]
                , div [ class "overflow-auto w-full" ] [ showJsonTree event.rawData event.dataTreeState (\s -> ChangeOpenedEventDataTreeState s) ]
                ]
            , section [ class "space-y-4" ]
                [ header [ class "flex justify-between border-gray-400 border-b text-xs pb-2" ]
                    [ h2 [ class "text-gray-500 uppercase font-bold" ] [ text "Raw Metadata" ]
                    , button [ class "text-red-700 no-underline", onClick (Copy event.rawMetadata) ]
                        [ FeatherIcons.clipboard
                            |> FeatherIcons.withSize 16
                            |> FeatherIcons.withClass "text-gray-400 hover:text-red-700"
                            |> FeatherIcons.toHtml []
                        ]
                    ]
                , div [ class "overflow-auto w-full" ] [ showJsonTree event.rawMetadata event.metadataTreeState (\s -> ChangeOpenedEventMetadataTreeState s) ]
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
                    [ class "font-bold text-xl mb-4"
                    ]
                    [ text "Event streams" ]
                , ul
                    [ class "list-disc pl-4 space-y-2"
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
                [ class "font-bold text-xl mb-4"
                ]
                [ text "Related" ]
            , ul
                [ class "list-disc pl-4 space-y-2"
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
                [ class "w-full text-left table-fixed"
                ]
                [ thead
                    [ class "align-bottom leading-tight sticky top-0 bg-white/70 backdrop-blur-sm text-gray-500 uppercase text-xs"
                    ]
                    [ tr
                        [ class "border-gray-400 border-b" ]
                        [ th
                            [ class "p-4"
                            ]
                            [ text "Event name" ]
                        , th
                            [ class "py-4 pr-4 lg:w-80"
                            ]
                            [ text "Event id" ]
                        ]
                    ]
                , tbody [ class "align-top" ] (List.map (renderCausedEvent baseUrl) causedEvents)
                , tfoot []
                    [ tr []
                        [ td
                            [ class "text-gray-500 py-4 text-center  text-xs"
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
    tr [ class "border-gray-50 border-b hover:bg-gray-100" ]
        [ td
            []
            [ a
                [ class "text-red-700 no-underline min-h-11 w-full flex items-center px-4"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventType ]
            ]
        , td
            [ class "font-mono text-sm leading-none font-medium align-middle" ]
            [ a
                [ class "no-underline h-full min-h-11 flex items-center"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventId ]
            ]
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


causationStreamName : Api.RemoteResource Event -> Maybe String
causationStreamName remoteResource =
    case remoteResource of
        Api.Loaded event ->
            event.causationStreamName

        _ ->
            Nothing
