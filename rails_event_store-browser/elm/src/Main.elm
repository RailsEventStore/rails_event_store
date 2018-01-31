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
    Navigation.programWithFlags ChangeUrl
        { init = model
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { items : List Item
    , event : Maybe Event
    , page : Page
    , flags : Flags
    }


type Msg
    = GetStreams (Result Http.Error (List Stream))
    | GetEvents (Result Http.Error (List Event))
    | GetEvent (Result Http.Error Event)
    | ChangeUrl Navigation.Location


type Page
    = BrowseStreams
    | BrowseEvents String
    | ShowEvent String
    | NotFound


type Item
    = StreamItem Stream
    | EventItem Event


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
    }


type alias Stream =
    { name : String
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
            { items = []
            , page = NotFound
            , event = Nothing
            , flags = flags
            }
    in
        urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetStreams (Ok result) ->
            ( { model | items = List.map StreamItem result }, Cmd.none )

        GetStreams (Err msg) ->
            ( model, Cmd.none )

        GetEvents (Ok result) ->
            ( { model | items = List.map EventItem result }, Cmd.none )

        GetEvents (Err msg) ->
            ( model, Cmd.none )

        GetEvent (Ok result) ->
            ( { model | event = Just result }, Cmd.none )

        GetEvent (Err msg) ->
            ( model, Cmd.none )

        ChangeUrl location ->
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
            browseItems "Streams" model.items

        BrowseEvents streamName ->
            browseItems ("Events in " ++ streamName) model.items

        ShowEvent eventId ->
            showEvent model.event

        NotFound ->
            h1 [] [ text "404" ]


showEvent : Maybe Event -> Html Msg
showEvent event =
    case event of
        Just event ->
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
                                , td [] [ pre [] [ text event.rawData ] ]
                                , td [] [ pre [] [ text event.rawMetadata ] ]
                                ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            div [ class "event" ] []


browseItems : String -> List Item -> Html Msg
browseItems title items =
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text title ]
        , div [ class "browser__pagination" ] []
        , div [ class "browser__results" ] [ renderResults items ]
        ]


renderResults : List Item -> Html Msg
renderResults items =
    case items of
        [] ->
            p [ class "results__empty" ] [ text "No items" ]

        (StreamItem _) :: _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Stream name" ]
                        ]
                    ]
                , tbody [] (List.map itemRow (items))
                ]

        (EventItem _) :: _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event name" ]
                        , th [ class "u-align-right" ] [ text "Created at" ]
                        ]
                    ]
                , tbody [] (List.map itemRow items)
                ]


itemRow : Item -> Html Msg
itemRow item =
    case item of
        EventItem { eventType, createdAt, eventId } ->
            tr []
                [ td []
                    [ a
                        [ class "results__link"
                        , href ("#events/" ++ eventId)
                        ]
                        [ text eventType ]
                    ]
                , td [ class "u-align-right" ]
                    [ text createdAt
                    ]
                ]

        StreamItem { name } ->
            tr []
                [ td []
                    [ a
                        [ class "results__link"
                        , href ("#streams/" ++ name)
                        ]
                        [ text name ]
                    ]
                ]


getStreams : String -> Cmd Msg
getStreams url =
    Http.get url streamsDecoder
        |> Http.send GetStreams


getEvents : String -> String -> Cmd Msg
getEvents url streamName =
    Http.get (url ++ "/" ++ streamName) eventsDecoder
        |> Http.send GetEvents


getEvent : String -> String -> Cmd Msg
getEvent url eventId =
    Http.get (url ++ "/" ++ eventId) eventDecoder
        |> Http.send GetEvent


eventsDecoder : Decoder (List Event)
eventsDecoder =
    eventDecoder_
        |> list
        |> field "data"


streamsDecoder : Decoder (List Stream)
streamsDecoder =
    let
        streamDecoder =
            decode Stream
                |> required "id" string
    in
        streamDecoder
            |> list
            |> field "data"


eventDecoder : Decoder Event
eventDecoder =
    eventDecoder_
        |> field "data"


eventDecoder_ : Decoder Event
eventDecoder_ =
    let
        rawEventDecoder =
            decode (,)
                |> requiredAt [ "attributes", "data" ] value
                |> requiredAt [ "attributes", "metadata" ] value

        eventDecoder =
            decode Event
                |> requiredAt [ "attributes", "event_type" ] string
                |> requiredAt [ "id" ] string
                |> requiredAt [ "attributes", "metadata", "timestamp" ] string
                |> requiredAt [ "attributes", "data" ] (value |> Json.Decode.map (encode 2))
                |> requiredAt [ "attributes", "metadata" ] (value |> Json.Decode.map (encode 2))
    in
        rawEventDecoder
            |> Json.Decode.andThen (\_ -> eventDecoder)
