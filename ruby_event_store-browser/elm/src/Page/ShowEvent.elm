module Page.ShowEvent exposing (Model, Msg(..), initCmd, initModel, showJsonTree, subscriptions, update, view)

import Api
import Flags exposing (Flags)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, colspan, css, href)
import Http
import JsonTree
import Maybe
import Maybe.Extra exposing (values)
import Route
import Spinner
import Tailwind.Utilities as Tw
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
subscriptions model =
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
                [ css
                    [ Tw.py_12
                    ]
                ]
                [ h1
                    [ css
                        [ Tw.font_bold
                        , Tw.px_8
                        , Tw.text_2xl
                        ]
                    ]
                    [ text "There's no event with given ID" ]
                ]

        Api.Loading ->
            div [ css [ Tw.min_h_screen ] ]
                [ fromUnstyled <|
                    Spinner.view Spinner.defaultConfig model.spinner
                ]

        Api.Loaded event ->
            showEvent model.flags.rootUrl event model.causedEvents

        Api.Failure ->
            div
                [ css
                    [ Tw.py_12
                    ]
                ]
                [ h1
                    [ css
                        [ Tw.font_bold
                        , Tw.px_8
                        , Tw.text_2xl
                        ]
                    ]
                    [ text "Unexpected request failure happened when fetching the event" ]
                ]


showEvent : Url.Url -> Event -> Api.RemoteResource (List Api.Event) -> Html Msg
showEvent baseUrl event maybeCausedEvents =
    div
        [ css
            [ Tw.py_12
            ]
        ]
        [ h1
            [ css
                [ Tw.font_bold
                , Tw.px_8
                , Tw.text_2xl
                ]
            ]
            [ text event.eventType ]
        , div
            [ css
                [ Tw.px_8
                ]
            ]
            [ table
                [ css
                    [ Tw.my_10
                    , Tw.w_full
                    , Tw.text_left
                    , Tw.table_fixed
                    , Tw.border_collapse
                    ]
                ]
                [ thead
                    [ css
                        [ Tw.align_bottom
                        , Tw.leading_tight
                        ]
                    ]
                    [ tr []
                        [ th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Event id" ]
                        , th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Raw Data" ]
                        , th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Raw Metadata" ]
                        ]
                    ]
                , tbody [ css [ Tw.align_top ] ]
                    [ tr []
                        [ td
                            [ css
                                [ Tw.p_0
                                , Tw.pt_2
                                ]
                            ]
                            [ text event.eventId ]
                        , td
                            [ css
                                [ Tw.p_0
                                , Tw.pt_2
                                ]
                            ]
                            [ showJsonTree event.rawData event.dataTreeState (\s -> ChangeOpenedEventDataTreeState s) ]
                        , td
                            [ css
                                [ Tw.p_0
                                , Tw.pt_2
                                ]
                            ]
                            [ showJsonTree event.rawMetadata event.metadataTreeState (\s -> ChangeOpenedEventMetadataTreeState s) ]
                        ]
                    ]
                ]
            ]
        , relatedStreams baseUrl event
        , case maybeCausedEvents of
            Api.Loading ->
                div
                    [ css
                        [ Tw.px_8
                        , Tw.mt_8
                        ]
                    ]
                    [ h2
                        [ css
                            [ Tw.font_bold
                            , Tw.text_xl
                            ]
                        ]
                        [ text "Events caused by this event:" ]
                    , text "Loading..."
                    ]

            Api.Loaded causedEvents ->
                case causedEvents of
                    [] ->
                        div
                            [ css
                                [ Tw.px_8
                                , Tw.mt_8
                                ]
                            ]
                            [ h2
                                [ css
                                    [ Tw.font_bold
                                    , Tw.text_xl
                                    ]
                                ]
                                [ text "Events caused by this event: none" ]
                            ]

                    _ ->
                        div
                            [ css
                                [ Tw.px_8
                                , Tw.mt_8
                                ]
                            ]
                            [ h2
                                [ css
                                    [ Tw.font_bold
                                    , Tw.text_xl
                                    ]
                                ]
                                [ text "Events caused by this event:" ]
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
        div
            [ css
                [ Tw.px_8
                ]
            ]
            [ h2
                [ css
                    [ Tw.font_bold
                    , Tw.text_xl
                    ]
                ]
                [ text "Related streams / events:" ]
            , ul
                [ css
                    [ Tw.list_disc
                    , Tw.pl_8
                    ]
                ]
                (relatedStreamsList baseUrl event)
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
    a
        [ css
            [ Tw.text_red_700
            , Tw.no_underline
            ]
        , href (Route.streamUrl baseUrl streamName)
        ]
        [ text streamName ]


eventLink : Url.Url -> String -> Html Msg
eventLink baseUrl eventId =
    a
        [ css
            [ Tw.text_red_700
            , Tw.no_underline
            ]
        , href (Route.eventUrl baseUrl eventId)
        ]
        [ text eventId ]


renderCausedEvents : Url.Url -> List Api.Event -> Html Msg
renderCausedEvents baseUrl causedEvents =
    case causedEvents of
        [] ->
            p
                [ css
                    [ Tw.flex
                    , Tw.items_center
                    , Tw.justify_center
                    , Tw.py_24
                    ]
                ]
                [ text "No items" ]

        _ ->
            table
                [ css
                    [ Tw.my_10
                    , Tw.w_full
                    , Tw.text_left
                    , Tw.table_fixed
                    , Tw.border_collapse
                    ]
                ]
                [ thead
                    [ css
                        [ Tw.align_bottom
                        , Tw.leading_tight
                        ]
                    ]
                    [ tr []
                        [ th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Event name" ]
                        , th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Event id" ]
                        ]
                    ]
                , tbody [ css [ Tw.align_top ] ] (List.map (renderCausedEvent baseUrl) causedEvents)
                , tfoot []
                    [ tr []
                        [ td
                            [ css
                                [ Tw.text_gray_500
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
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
            [ css
                [ Tw.p_0
                , Tw.pt_2
                ]
            ]
            [ a
                [ css
                    [ Tw.text_red_700
                    , Tw.no_underline
                    ]
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventType ]
            ]
        , td
            [ css
                [ Tw.p_0
                , Tw.pt_2
                ]
            ]
            [ text eventId ]
        ]


showJsonTree : String -> JsonTree.State -> (JsonTree.State -> msg) -> Html msg
showJsonTree rawJson treeState changeState =
    fromUnstyled <|
        (JsonTree.parseString rawJson
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
                (toUnstyled <| pre [] [ text rawJson ])
        )
