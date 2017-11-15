module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, disabled, href, class)
import Html.Events exposing (onInput, onClick)
import Paginate exposing (..)
import Http
import Json.Decode as Decode exposing (map, field, list, string, at)
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
    { streams : PaginatedList Stream
    , events : PaginatedList Event
    , searchQuery : String
    , perPage : Int
    , page : Page
    }


type Msg
    = Search String
    | NextPage
    | PreviousPage
    | GoToPage Int
    | StreamList (Result Http.Error (List Stream))
    | EventList (Result Http.Error (List Event))
    | UrlChange Navigation.Location


type Page
    = BrowseStreams
    | BrowseEvents String
    | ShowEvent String
    | NotFound


type Stream
    = Stream String


type Event
    = Event String String


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
            nextPageUpdate model

        PreviousPage ->
            prevPageUpdate model

        GoToPage pageNum ->
            goToPageUpdate model pageNum

        StreamList (Ok result) ->
            ( { model | streams = Paginate.fromList model.perPage result }, Cmd.none )

        StreamList (Err msg) ->
            ( model, Cmd.none )

        EventList (Ok result) ->
            ( { model | events = Paginate.fromList model.perPage result }, Cmd.none )

        EventList (Err msg) ->
            ( model, Cmd.none )

        UrlChange location ->
            urlUpdate model location


nextPageUpdate : Model -> ( Model, Cmd Msg )
nextPageUpdate model =
    case model.page of
        BrowseEvents _ ->
            ( { model | events = Paginate.next model.events }, Cmd.none )

        _ ->
            ( { model | streams = Paginate.next model.streams }, Cmd.none )


prevPageUpdate : Model -> ( Model, Cmd Msg )
prevPageUpdate model =
    case model.page of
        BrowseEvents _ ->
            ( { model | events = Paginate.prev model.events }, Cmd.none )

        _ ->
            ( { model | streams = Paginate.next model.streams }, Cmd.none )


goToPageUpdate : Model -> Int -> ( Model, Cmd Msg )
goToPageUpdate model pageNum =
    case model.page of
        BrowseEvents _ ->
            ( { model | events = Paginate.goTo pageNum model.events }, Cmd.none )

        _ ->
            ( { model | streams = Paginate.goTo pageNum model.streams }, Cmd.none )


urlUpdate : Model -> Navigation.Location -> ( Model, Cmd Msg )
urlUpdate model location =
    case decode location of
        Just BrowseStreams ->
            ( { model | page = BrowseStreams }, getStreams )

        Just (BrowseEvents streamId) ->
            ( { model | page = (BrowseEvents streamId) }, getEvents )

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
    browserFrame model


browserFrame : Model -> Html Msg
browserFrame model =
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
            browseStreams model

        BrowseEvents streamName ->
            browseEvents model streamName

        ShowEvent eventId ->
            h1 [] [ text ("Event " ++ eventId) ]

        NotFound ->
            h1 [] [ text "404" ]


browseStreams : Model -> Html Msg
browseStreams model =
    let
        streams =
            filteredStreams model
    in
        div [ class "browser" ]
            [ h1 [ class "browser__title" ] [ text "Streams" ]
            , div [ class "browser__search search" ] [ searchField ]
            , div [ class "browser__pagination" ] [ renderPagination streams ]
            , div [ class "browser__results" ] [ displayStreams streams ]
            ]


browseEvents : Model -> String -> Html Msg
browseEvents model streamName =
    let
        events =
            filteredEvents model
    in
        div [ class "browser" ]
            [ h1 [ class "browser__title" ] [ text ("Events in " ++ streamName) ]
            , div [ class "browser__search search" ] [ searchField ]
            , div [ class "browser__pagination" ] [ renderPagination events ]
            , div [ class "browser__results" ] [ displayEvents events ]
            ]


searchField : Html Msg
searchField =
    input [ class "search__input", placeholder "type to start searching", onInput Search ] []


renderPagination : PaginatedList a -> Html Msg
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


pagerData : PaginatedList a -> List ( Int, Bool )
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


pagerView : PaginatedList a -> List (Html Msg)
pagerView items =
    items
        |> pagerData
        |> List.map (\( pageNum, isCurrentPage ) -> renderPagerButton pageNum isCurrentPage)


prevPage : PaginatedList a -> Html Msg
prevPage items =
    button
        [ onClick PreviousPage
        , class "pagination__page pagination__page--previous"
        , disabled (Paginate.isFirst items)
        ]
        [ text "←" ]


nextPage : PaginatedList a -> Html Msg
nextPage items =
    button
        [ onClick NextPage
        , class "pagination__page pagination__page--next"
        , disabled (Paginate.isLast items)
        ]
        [ text "→" ]


filteredStreams : Model -> PaginatedList Stream
filteredStreams model =
    Paginate.map (List.filter (\(Stream name) -> isMatch model.searchQuery name)) model.streams


filteredEvents : Model -> PaginatedList Event
filteredEvents model =
    Paginate.map (List.filter (\(Event name _) -> isMatch model.searchQuery name)) model.events


displayStream : Stream -> Html Msg
displayStream (Stream name) =
    tr []
        [ td []
            [ a [ class "results__link", href ("#streams/" ++ name) ] [ text name ]
            ]
        ]


displayStreams : PaginatedList Stream -> Html Msg
displayStreams streams =
    table []
        [ thead []
            [ tr []
                [ th [] [ text "Stream name" ]
                ]
            ]
        , tbody [] (List.map displayStream (Paginate.page streams))
        ]


displayEvent : Event -> Html Msg
displayEvent (Event name createdAt) =
    tr []
        [ td []
            [ a [ class "results__link", href ("#events/" ++ name) ] [ text name ]
            ]
        , td [ class "u-align-right" ]
            [ text createdAt
            ]
        ]


displayEvents : PaginatedList Event -> Html Msg
displayEvents events =
    table []
        [ thead []
            [ tr []
                [ th [] [ text "Event name" ]
                , th [ class "u-align-right" ] [ text "Created at" ]
                ]
            ]
        , tbody [] (List.map displayEvent (Paginate.page events))
        ]


getStreams : Cmd Msg
getStreams =
    Http.send StreamList (Http.get "/streams.json" (list streamDecoder))


getEvents : Cmd Msg
getEvents =
    Http.send EventList (Http.get "/events.json" (list eventDecoder))


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.map2 Event
        (field "event_type" string)
        (at [ "metadata", "timestamp" ] string)


streamDecoder : Decode.Decoder Stream
streamDecoder =
    Decode.map Stream
        (field "name" string)
