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
    , events : List Event
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
    in
        ( { streams = Paginate.fromList perPage []
          , events = []
          , searchQuery = ""
          , perPage = perPage
          , page = BrowseStreams
          }
        , getStreams
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search inputValue ->
            ( { model | searchQuery = inputValue }, Cmd.none )

        NextPage ->
            ( { model | streams = Paginate.next model.streams }, Cmd.none )

        PreviousPage ->
            ( { model | streams = Paginate.prev model.streams }, Cmd.none )

        GoToPage pageNum ->
            ( { model | streams = Paginate.goTo pageNum model.streams }, Cmd.none )

        StreamList (Ok result) ->
            ( { model | streams = Paginate.fromList model.perPage result }, Cmd.none )

        StreamList (Err msg) ->
            ( model, Cmd.none )

        EventList (Ok result) ->
            ( { model | events = result }, Cmd.none )

        EventList (Err msg) ->
            ( model, Cmd.none )

        UrlChange location ->
            urlUpdate model location


urlUpdate : Model -> Navigation.Location -> ( Model, Cmd Msg )
urlUpdate model location =
    case decode location of
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


isMatch : String -> Stream -> Bool
isMatch searchQuery (Stream name) =
    String.contains searchQuery name


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
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text ("Events in " ++ streamName) ]
        , div [ class "browser__results" ] [ displayEvents model.events ]
        ]


searchField : Html Msg
searchField =
    input [ class "search__input", placeholder "type to start searching", onInput Search ] []


renderPagination : PaginatedList Stream -> Html Msg
renderPagination streams =
    let
        pageListItems =
            (List.map
                (\l -> li [] [ l ])
                (pagerView streams)
            )
    in
        ul [ class "pagination" ]
            (List.concat
                [ [ li [] [ prevPage streams ] ]
                , pageListItems
                , [ li [] [ nextPage streams ] ]
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


pagerData : PaginatedList Stream -> List ( Int, Bool )
pagerData streams =
    let
        currentPage =
            Paginate.currentPage streams

        pagesAround =
            2

        overflow =
            ( List.minimum [ 0, currentPage - pagesAround - 1 ]
            , List.maximum
                [ 0
                , currentPage
                    + pagesAround
                    - (Paginate.totalPages streams)
                ]
            )

        visiblePages =
            case overflow of
                ( Just overflowBefore, Just overflowAfter ) ->
                    List.range (currentPage - pagesAround - overflowAfter) (currentPage + pagesAround - overflowBefore)

                ( _, _ ) ->
                    List.range (currentPage - pagesAround) (currentPage + pagesAround)
    in
        streams
            |> pager (,)
            |> List.filter (\( pageNum, _ ) -> List.member pageNum visiblePages)


pagerView : PaginatedList Stream -> List (Html Msg)
pagerView streams =
    streams
        |> pagerData
        |> List.map (\( pageNum, isCurrentPage ) -> renderPagerButton pageNum isCurrentPage)


prevPage : PaginatedList Stream -> Html Msg
prevPage streams =
    button
        [ onClick PreviousPage
        , class "pagination__page pagination__page--previous"
        , disabled (Paginate.isFirst streams)
        ]
        [ text "←" ]


nextPage : PaginatedList Stream -> Html Msg
nextPage streams =
    button
        [ onClick NextPage
        , class "pagination__page pagination__page--next"
        , disabled (Paginate.isLast streams)
        ]
        [ text "→" ]


filteredStreams : Model -> PaginatedList Stream
filteredStreams model =
    Paginate.map (List.filter (isMatch model.searchQuery)) model.streams


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
        , td []
            [ text createdAt
            ]
        ]


displayEvents : List Event -> Html Msg
displayEvents events =
    table []
        [ thead []
            [ tr []
                [ th [] [ text "Event name" ]
                , th [] [ text "Created at" ]
                ]
            ]
        , tbody [] (List.map displayEvent events)
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
