module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, disabled, href, class)
import Http
import Json.Decode exposing (Decoder, Value, field, list, string, at, value)
import Json.Decode.Pipeline exposing (decode, required, requiredAt)
import Json.Encode exposing (encode)
import Navigation
import UrlParser exposing ((</>))


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = model
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { streams : List Item
    , events : List Item
    , event : EventWithDetails
    , page : Page
    , flags : Flags
    }


type Msg
    = StreamList (Result Http.Error (List Item))
    | EventList (Result Http.Error (List Item))
    | EventDetails (Result Http.Error EventWithDetails)
    | UrlChange Navigation.Location


type Page
    = BrowseStreams
    | BrowseEvents String
    | ShowEvent String
    | NotFound


type Item
    = Stream String
    | Event String String String


type alias EventWithDetails =
    { eventType : String
    , eventId : String
    , data : String
    , metadata : String
    }


type alias Flags =
    { rootUrl : String
    , streamsUrl : String
    , eventsUrl : String
    , resVersion : String
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


model : Flags -> Navigation.Location -> ( Model, Cmd Msg )
model flags location =
    let
        initModel =
            { streams = []
            , events = []
            , event = EventWithDetails "" "" "" ""
            , page = NotFound
            , flags = flags
            }
    in
        urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StreamList (Ok result) ->
            ( { model | streams = result }, Cmd.none )

        StreamList (Err msg) ->
            ( model, Cmd.none )

        EventList (Ok result) ->
            ( { model | events = result }, Cmd.none )

        EventList (Err msg) ->
            ( model, Cmd.none )

        EventDetails (Ok result) ->
            ( { model | event = result }, Cmd.none )

        EventDetails (Err msg) ->
            ( model, Cmd.none )

        UrlChange location ->
            urlUpdate model location


urlUpdate : Model -> Navigation.Location -> ( Model, Cmd Msg )
urlUpdate model location =
    case decodeLocation location of
        Just BrowseStreams ->
            ( { model | page = BrowseStreams }, getStreams model.flags.streamsUrl )

        Just (BrowseEvents streamId) ->
            ( { model | page = (BrowseEvents streamId) }, getEvents model.flags.streamsUrl streamId )

        Just (ShowEvent eventId) ->
            ( { model | page = (ShowEvent eventId) }, getEvent model.flags.eventsUrl eventId )

        Just page ->
            ( { model | page = page }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


decodeLocation : Navigation.Location -> Maybe Page
decodeLocation location =
    UrlParser.parseHash routeParser location


routeParser : UrlParser.Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map BrowseStreams UrlParser.top
        , UrlParser.map BrowseEvents (UrlParser.s "streams" </> UrlParser.string)
        , UrlParser.map ShowEvent (UrlParser.s "events" </> UrlParser.string)
        ]


view : Model -> Html Msg
view model =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ browserNavigation model ]
        , main_ [ class "frame__body" ] [ browserBody model ]
        , footer [ class "frame__footer" ] [ browserFooter model ]
        ]


browserNavigation : Model -> Html Msg
browserNavigation model =
    nav [ class "navigation" ]
        [ div [ class "navigation__brand" ]
            [ a [ href model.flags.rootUrl, class "navigation__logo" ] [ text "Rails Event Store" ]
            ]
        , div [ class "navigation__links" ]
            [ a [ href model.flags.rootUrl, class "navigation__link" ] [ text "Stream Browser" ]
            ]
        ]


browserFooter : Model -> Html Msg
browserFooter model =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text ("RailsEventStore v" ++ model.flags.resVersion)
            , a [ href "http://railseventstore.org/docs/install/", class "footer__link" ] [ text "Documentation" ]
            , a [ href "http://railseventstore.org/support/", class "footer__link" ] [ text "Support" ]
            ]
        ]


browserBody : Model -> Html Msg
browserBody model =
    case model.page of
        BrowseStreams ->
            browseItems
                "Streams"
                model.streams

        BrowseEvents streamName ->
            browseItems
                ("Events in " ++ streamName)
                model.events

        ShowEvent eventId ->
            showEvent model

        NotFound ->
            h1 [] [ text "404" ]


showEvent : Model -> Html Msg
showEvent model =
    div [ class "event" ]
        [ h1 [ class "event__title" ] [ text model.event.eventType ]
        , div [ class "event__body" ]
            [ table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event id" ]
                        , th [] [ text "Metadata" ]
                        , th [] [ text "Data" ]
                        ]
                    ]
                , tbody []
                    [ tr []
                        [ td [] [ text model.event.eventId ]
                        , td [] [ text model.event.metadata ]
                        , td [] [ text model.event.data ]
                        ]
                    ]
                ]
            ]
        ]


browseItems : String -> List Item -> Html Msg
browseItems title items =
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text title ]
        , div [ class "browser__pagination" ] []
        , div [ class "browser__results" ] [ displayItems items ]
        ]


displayItems : List Item -> Html Msg
displayItems items =
    case items of
        [] ->
            p [ class "results__empty" ] [ text "No items" ]

        (Stream _) :: _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Stream name" ]
                        ]
                    ]
                , tbody [] (List.map displayItem (items))
                ]

        (Event _ _ _) :: _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event name" ]
                        , th [ class "u-align-right" ] [ text "Created at" ]
                        ]
                    ]
                , tbody [] (List.map displayItem items)
                ]


displayItem : Item -> Html Msg
displayItem item =
    case item of
        Event name createdAt eventId ->
            tr []
                [ td []
                    [ a [ class "results__link", href ("#events/" ++ eventId) ] [ text name ]
                    ]
                , td [ class "u-align-right" ]
                    [ text createdAt
                    ]
                ]

        Stream name ->
            tr []
                [ td []
                    [ a [ class "results__link", href ("#streams/" ++ name) ] [ text name ]
                    ]
                ]


getStreams : String -> Cmd Msg
getStreams url =
    Http.get url streamsDecoder
        |> Http.send StreamList


getEvents : String -> String -> Cmd Msg
getEvents url streamName =
    Http.get (url ++ "/" ++ streamName) eventsDecoder
        |> Http.send EventList


getEvent : String -> String -> Cmd Msg
getEvent url eventId =
    Http.get (url ++ "/" ++ eventId) eventWithDetailsDecoder
        |> Http.send EventDetails


eventsDecoder : Decoder (List Item)
eventsDecoder =
    let
        eventDecoder =
            decode Event
                |> requiredAt [ "attributes", "event_type" ] string
                |> requiredAt [ "attributes", "metadata", "timestamp" ] string
                |> required "id" string
    in
        eventDecoder
            |> list
            |> field "data"


streamsDecoder : Decoder (List Item)
streamsDecoder =
    let
        streamDecoder =
            decode Stream
                |> required "id" string
    in
        streamDecoder
            |> list
            |> field "data"


rawEventDecoder : Decoder ( Value, Value )
rawEventDecoder =
    decode (,)
        |> requiredAt [ "data", "attributes", "data" ] value
        |> requiredAt [ "data", "attributes", "metadata" ] value


eventWithDetailsDecoder : Decoder EventWithDetails
eventWithDetailsDecoder =
    let
        eventDecoder =
            decode EventWithDetails
                |> requiredAt [ "data", "attributes", "event_type" ] string
                |> requiredAt [ "data", "id" ] string
                |> requiredAt [ "data", "attributes", "data" ] (value |> Json.Decode.map (encode 2))
                |> requiredAt [ "data", "attributes", "metadata" ] (value |> Json.Decode.map (encode 2))
    in
        rawEventDecoder
            |> Json.Decode.andThen (\_ -> eventDecoder)
