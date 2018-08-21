module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, disabled, href, class)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, Value, field, list, string, at, value, maybe, oneOf)
import Json.Decode.Pipeline exposing (decode, required, requiredAt, optional)
import Json.Encode exposing (encode)
import Navigation
import UrlParser exposing ((</>))
import OpenedEventUI


main : Program Flags Model Msg
main =
    Navigation.programWithFlags ChangeUrl
        { init = model
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { events : PaginatedList Event
    , event : Maybe OpenedEventUI.Model
    , page : Page
    , flags : Flags
    }


type Msg
    = GetEvents (Result Http.Error (PaginatedList Event))
    | GetEvent (Result Http.Error Event)
    | ChangeUrl Navigation.Location
    | GoToPage PaginationLink
    | OpenedEventUIChanged OpenedEventUI.Msg


type Page
    = BrowseEvents String
    | ShowEvent String
    | NotFound


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
    }


type alias PaginationLink =
    String


type alias PaginationLinks =
    { next : Maybe PaginationLink
    , prev : Maybe PaginationLink
    , first : Maybe PaginationLink
    , last : Maybe PaginationLink
    }


type alias PaginatedList a =
    { events : List a
    , links : PaginationLinks
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
        initLinks =
            { prev = Nothing
            , next = Nothing
            , first = Nothing
            , last = Nothing
            }

        initModel =
            { events = PaginatedList [] initLinks
            , page = NotFound
            , event = Nothing
            , flags = flags
            }
    in
        urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetEvents (Ok result) ->
            ( { model | events = result }, Cmd.none )

        GetEvents (Err msg) ->
            ( model, Cmd.none )

        GetEvent (Ok result) ->
            ( { model | event = Just (OpenedEventUI.initModel result) }, Cmd.none )

        GetEvent (Err msg) ->
            ( model, Cmd.none )

        ChangeUrl location ->
            urlUpdate model location

        GoToPage paginationLink ->
            ( model, getEvents paginationLink )

        OpenedEventUIChanged openedEventUIMsg ->
            case model.event of
                Just openedEvent ->
                    let
                        ( newModel, cmd ) =
                            OpenedEventUI.update openedEventUIMsg openedEvent
                    in
                        ( { model | event = Just newModel }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


buildUrl : String -> String -> String
buildUrl baseUrl id =
    baseUrl ++ "/" ++ (Http.encodeUri id)


urlUpdate : Model -> Navigation.Location -> ( Model, Cmd Msg )
urlUpdate model location =
    let
        decodeLocation location =
            UrlParser.parseHash routeParser location
    in
        case decodeLocation location of
            Just (BrowseEvents encodedStreamId) ->
                case (Http.decodeUri encodedStreamId) of
                    Just streamId ->
                        ( { model | page = (BrowseEvents streamId) }, getEvents (buildUrl model.flags.streamsUrl streamId) )

                    Nothing ->
                        ( { model | page = NotFound }, Cmd.none )

            Just (ShowEvent encodedEventId) ->
                case (Http.decodeUri encodedEventId) of
                    Just eventId ->
                        ( { model | page = (ShowEvent eventId) }, getEvent (buildUrl model.flags.eventsUrl eventId) )

                    Nothing ->
                        ( { model | page = NotFound }, Cmd.none )

            Just page ->
                ( { model | page = page }, Cmd.none )

            Nothing ->
                ( { model | page = NotFound }, Cmd.none )


routeParser : UrlParser.Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map (BrowseEvents "all") UrlParser.top
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
            [ a [ href model.flags.rootUrl, class "navigation__logo" ] [ text "Ruby Event Store" ]
            ]
        , div [ class "navigation__links" ]
            [ a [ href model.flags.rootUrl, class "navigation__link" ] [ text "Stream Browser" ]
            ]
        ]


browserFooter : Model -> Html Msg
browserFooter model =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text ("RubyEventStore v" ++ model.flags.resVersion)
            , a [ href "https://railseventstore.org/docs/install/", class "footer__link" ] [ text "Documentation" ]
            , a [ href "https://railseventstore.org/support/", class "footer__link" ] [ text "Support" ]
            ]
        ]


browserBody : Model -> Html Msg
browserBody model =
    case model.page of
        BrowseEvents streamName ->
            browseEvents ("Events in " ++ streamName) model.events

        ShowEvent eventId ->
            showEvent model.event

        NotFound ->
            h1 [] [ text "404" ]


showEvent : Maybe OpenedEventUI.Model -> Html Msg
showEvent event =
    case event of
        Just event ->
            Html.map (\msg -> OpenedEventUIChanged msg) (OpenedEventUI.showEvent event)

        Nothing ->
            div [ class "event" ] []


browseEvents : String -> PaginatedList Event -> Html Msg
browseEvents title { links, events } =
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text title ]
        , div [ class "browser__pagination" ] [ displayPagination links ]
        , div [ class "browser__results" ] [ renderResults events ]
        ]


displayPagination : PaginationLinks -> Html Msg
displayPagination { first, last, next, prev } =
    ul [ class "pagination" ]
        [ paginationItem firstPageButton first
        , paginationItem lastPageButton last
        , paginationItem nextPageButton next
        , paginationItem prevPageButton prev
        ]


paginationItem : (PaginationLink -> Html Msg) -> Maybe PaginationLink -> Html Msg
paginationItem button link =
    case link of
        Just url ->
            li [] [ button url ]

        Nothing ->
            li [] []


nextPageButton : PaginationLink -> Html Msg
nextPageButton url =
    button
        [ href url
        , onClick (GoToPage url)
        , class "pagination__page pagination__page--next"
        ]
        [ text "next" ]


prevPageButton : PaginationLink -> Html Msg
prevPageButton url =
    button
        [ href url
        , onClick (GoToPage url)
        , class "pagination__page pagination__page--prev"
        ]
        [ text "previous" ]


lastPageButton : PaginationLink -> Html Msg
lastPageButton url =
    button
        [ href url
        , onClick (GoToPage url)
        , class "pagination__page pagination__page--last"
        ]
        [ text "last" ]


firstPageButton : PaginationLink -> Html Msg
firstPageButton url =
    button
        [ href url
        , onClick (GoToPage url)
        , class "pagination__page pagination__page--first"
        ]
        [ text "first" ]


renderResults : List Event -> Html Msg
renderResults events =
    case events of
        [] ->
            p [ class "results__empty" ] [ text "No items" ]

        _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event name" ]
                        , th [] [ text "Event id" ]
                        , th [ class "u-align-right" ] [ text "Created at" ]
                        ]
                    ]
                , tbody [] (List.map itemRow events)
                ]


itemRow : Event -> Html Msg
itemRow { eventType, createdAt, eventId } =
    tr []
        [ td []
            [ a
                [ class "results__link"
                , href (buildUrl "#events" eventId)
                ]
                [ text eventType ]
            ]
        , td [] [ text eventId ]
        , td [ class "u-align-right" ]
            [ text createdAt
            ]
        ]


getEvent : String -> Cmd Msg
getEvent url =
    Http.get url eventDecoder
        |> Http.send GetEvent


getEvents : String -> Cmd Msg
getEvents url =
    Http.get url eventsDecoder
        |> Http.send GetEvents


eventsDecoder : Decoder (PaginatedList Event)
eventsDecoder =
    decode PaginatedList
        |> required "data" (list eventDecoder_)
        |> required "links" linksDecoder


linksDecoder : Decoder PaginationLinks
linksDecoder =
    decode PaginationLinks
        |> optional "next" (maybe string) Nothing
        |> optional "prev" (maybe string) Nothing
        |> optional "first" (maybe string) Nothing
        |> optional "last" (maybe string) Nothing


eventDecoder : Decoder Event
eventDecoder =
    eventDecoder_
        |> field "data"


eventDecoder_ : Decoder Event
eventDecoder_ =
    decode Event
        |> requiredAt [ "attributes", "event_type" ] string
        |> requiredAt [ "id" ] string
        |> requiredAt [ "attributes", "metadata", "timestamp" ] string
        |> requiredAt [ "attributes", "data" ] (value |> Json.Decode.map (encode 2))
        |> requiredAt [ "attributes", "metadata" ] (value |> Json.Decode.map (encode 2))
