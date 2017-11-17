module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, disabled, href, class)
import Html.Events exposing (onInput, onClick)
import Paginate exposing (..)
import Http
import Json.Decode as D exposing (Decoder, Value, field, list, string, at, value)
import Navigation
import UrlParser exposing ((</>))


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = model
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { streams : PaginatedList Item
    , events : PaginatedList Item
    , event : EventWithDetails
    , searchQuery : String
    , perPage : Int
    , page : Page
    }


type Msg
    = Search String
    | NextPage
    | PreviousPage
    | GoToPage Int
    | StreamList (Result Http.Error (List Item))
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
    | Event String String


type alias EventWithDetails =
    { eventType : String
    , eventId : String
    , data : String
    , metadata : String
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


model : Navigation.Location -> ( Model, Cmd Msg )
model location =
    let
        perPage =
            10

        emptyList =
            Paginate.fromList perPage []

        initModel =
            { streams = emptyList
            , events = emptyList
            , event = EventWithDetails "" "" "" ""
            , searchQuery = ""
            , perPage = perPage
            , page = NotFound
            }
    in
        urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search inputValue ->
            ( { model | searchQuery = inputValue }, Cmd.none )

        NextPage ->
            itemsUpdate model Paginate.next

        PreviousPage ->
            itemsUpdate model Paginate.prev

        GoToPage pageNum ->
            itemsUpdate model (Paginate.goTo pageNum)

        StreamList (Ok result) ->
            ( { model | streams = Paginate.fromList model.perPage result }, Cmd.none )

        StreamList (Err msg) ->
            ( model, Cmd.none )

        EventList (Ok result) ->
            ( { model | events = Paginate.fromList model.perPage result }, Cmd.none )

        EventList (Err msg) ->
            ( model, Cmd.none )

        EventDetails (Ok result) ->
            ( { model | event = result }, Cmd.none )

        EventDetails (Err msg) ->
            ( model, Cmd.none )

        UrlChange location ->
            urlUpdate model location


itemsUpdate : Model -> (PaginatedList Item -> PaginatedList Item) -> ( Model, Cmd Msg )
itemsUpdate model f =
    case model.page of
        BrowseEvents _ ->
            ( { model | events = f model.events }, Cmd.none )

        BrowseStreams ->
            ( { model | streams = f model.streams }, Cmd.none )

        _ ->
            ( model, Cmd.none )


urlUpdate : Model -> Navigation.Location -> ( Model, Cmd Msg )
urlUpdate model location =
    case decode location of
        Just BrowseStreams ->
            ( { model | page = BrowseStreams }, getStreams )

        Just (BrowseEvents streamId) ->
            ( { model | page = (BrowseEvents streamId) }, getEvents )

        Just (ShowEvent eventId) ->
            ( { model | page = (ShowEvent eventId) }, getEvent eventId )

        Just page ->
            ( { model | page = page }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


decode : Navigation.Location -> Maybe Page
decode location =
    UrlParser.parseHash routeParser location


routeParser : UrlParser.Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map BrowseStreams UrlParser.top
        , UrlParser.map BrowseEvents (UrlParser.s "streams" </> UrlParser.string)
        , UrlParser.map ShowEvent (UrlParser.s "events" </> UrlParser.string)
        ]


isMatch : String -> String -> Bool
isMatch searchQuery name =
    String.contains (String.toLower searchQuery) (String.toLower name)


view : Model -> Html Msg
view model =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ browserNavigation ]
        , main_ [ class "frame__body" ] [ browserBody model ]
        , footer [ class "frame__footer" ] [ browserFooter ]
        ]


browserNavigation : Html Msg
browserNavigation =
    nav [ class "navigation" ]
        [ div [ class "navigation__brand" ]
            [ a [ href "/", class "navigation__logo" ] [ text "Rails Event Store" ]
            ]
        , div [ class "navigation__links" ]
            [ a [ href "/", class "navigation__link" ] [ text "Stream Browser" ]
            ]
        ]


browserFooter : Html Msg
browserFooter =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text "RailsEventStore v0.18.0"
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
                (filteredItems model.searchQuery model.streams)

        BrowseEvents streamName ->
            browseItems
                ("Events in " ++ streamName)
                (filteredItems model.searchQuery model.events)

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


browseItems : String -> PaginatedList Item -> Html Msg
browseItems title items =
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text title ]
        , div [ class "browser__search search" ] [ searchField ]
        , div [ class "browser__pagination" ] [ renderPagination items ]
        , div [ class "browser__results" ] [ displayItems (Paginate.page items) ]
        ]


searchField : Html Msg
searchField =
    input [ class "search__input", placeholder "type to start searching", onInput Search ] []


renderPagination : PaginatedList item -> Html Msg
renderPagination items =
    let
        pageListItems =
            (List.map
                (\l -> li [] [ l ])
                (pagerView items)
            )
    in
        ul [ class "pagination" ]
            (List.concat
                [ [ li [] [ prevPage items ] ]
                , pageListItems
                , [ li [] [ nextPage items ] ]
                ]
            )


renderPagerButton : Int -> Bool -> Html Msg
renderPagerButton pageNum isCurrentPage =
    button
        [ onClick (GoToPage pageNum)
        , class "pagination__page"
        , disabled isCurrentPage
        ]
        [ text (toString pageNum) ]


pagerData : PaginatedList item -> List ( Int, Bool )
pagerData items =
    let
        currentPage =
            Paginate.currentPage items

        pagesAround =
            2

        overflow =
            ( List.minimum [ 0, currentPage - pagesAround - 1 ]
            , List.maximum
                [ 0
                , currentPage
                    + pagesAround
                    - (Paginate.totalPages items)
                ]
            )

        visiblePages =
            case overflow of
                ( Just overflowBefore, Just overflowAfter ) ->
                    List.range (currentPage - pagesAround - overflowAfter) (currentPage + pagesAround - overflowBefore)

                ( _, _ ) ->
                    List.range (currentPage - pagesAround) (currentPage + pagesAround)
    in
        items
            |> pager (,)
            |> List.filter (\( pageNum, _ ) -> List.member pageNum visiblePages)


pagerView : PaginatedList item -> List (Html Msg)
pagerView items =
    items
        |> pagerData
        |> List.map (\( pageNum, isCurrentPage ) -> renderPagerButton pageNum isCurrentPage)


prevPage : PaginatedList item -> Html Msg
prevPage items =
    button
        [ onClick PreviousPage
        , class "pagination__page pagination__page--previous"
        , disabled (Paginate.isFirst items)
        ]
        [ text "←" ]


nextPage : PaginatedList item -> Html Msg
nextPage items =
    button
        [ onClick NextPage
        , class "pagination__page pagination__page--next"
        , disabled (Paginate.isLast items)
        ]
        [ text "→" ]


filteredItems : String -> PaginatedList Item -> PaginatedList Item
filteredItems searchQuery items =
    let
        predicate item =
            case item of
                Stream name ->
                    isMatch searchQuery name

                Event name _ ->
                    isMatch searchQuery name
    in
        Paginate.map (List.filter predicate) items


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

        (Event _ _) :: _ ->
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
        Event name createdAt ->
            tr []
                [ td []
                    [ a [ class "results__link", href ("#events/" ++ name) ] [ text name ]
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


getStreams : Cmd Msg
getStreams =
    Http.send StreamList (Http.get "/streams.json" (list streamDecoder))


getEvents : Cmd Msg
getEvents =
    Http.send EventList (Http.get "/events.json" (list eventDecoder))


getEvent : String -> Cmd Msg
getEvent eventId =
    let
        decoder =
            D.andThen eventWithDetailsDecoder rawEventDecoder
    in
        Http.send EventDetails (Http.get "/event.json" decoder)


eventDecoder : Decoder Item
eventDecoder =
    D.map2 Event
        (field "event_type" string)
        (at [ "metadata", "timestamp" ] string)


streamDecoder : Decoder Item
streamDecoder =
    D.map Stream
        (field "name" string)


rawEventDecoder : Decoder ( Value, Value )
rawEventDecoder =
    D.map2 (,)
        (field "data" value)
        (field "metadata" value)


eventWithDetailsDecoder : ( Value, Value ) -> Decoder EventWithDetails
eventWithDetailsDecoder ( data, metadata ) =
    D.map4 EventWithDetails
        (field "event_type" string)
        (field "event_id" string)
        (field "data" (D.succeed (toString data)))
        (field "metadata" (D.succeed (toString metadata)))
