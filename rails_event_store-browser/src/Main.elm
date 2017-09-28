module Main exposing (..)

import Html exposing (Html, ul, li, text, div, input, button, h1, a)
import Html.Attributes exposing (placeholder, disabled, href)
import Html.Events exposing (onInput, onClick)
import Paginate exposing (..)
import Http
import Json.Decode as Decode exposing (map, field, list, string)
import Navigation
import UrlParser exposing ((</>))


main : Program Never Model Msg
main =
    Navigation.program UrlChange { init = model, view = view, update = update, subscriptions = subscriptions }


type alias Model =
    { streams : PaginatedList Stream
    , searchQuery : String
    , perPage : Int
    , page : Page
    }


type Msg
    = Search String
    | NextPage
    | PreviousPage
    | StreamList (Result Http.Error (List Stream))
    | UrlChange Navigation.Location


type Page
    = BrowseStreams
    | BrowseEvents String
    | ShowEvent String
    | NotFound


type Stream
    = Stream String


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

        StreamList (Ok result) ->
            ( { model | streams = Paginate.fromList model.perPage result }, Cmd.none )

        StreamList (Err msg) ->
            ( model, Cmd.none )

        UrlChange location ->
            urlUpdate model location


urlUpdate : Model -> Navigation.Location -> ( Model, Cmd Msg )
urlUpdate model location =
    case decode location of
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
    case model.page of
        BrowseStreams ->
            browseStreams model

        BrowseEvents streamName ->
            h1 [] [ text ("Events in " ++ streamName) ]

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
        div []
            [ searchField
            , prevPage streams
            , nextPage streams
            , displayStreams streams
            ]


searchField : Html Msg
searchField =
    input [ placeholder "Search", onInput Search ] []


prevPage : PaginatedList Stream -> Html Msg
prevPage streams =
    button
        [ onClick PreviousPage
        , disabled (Paginate.isFirst streams)
        ]
        [ text "Previous" ]


nextPage : PaginatedList Stream -> Html Msg
nextPage streams =
    button
        [ onClick NextPage
        , disabled (Paginate.isLast streams)
        ]
        [ text "Next" ]


filteredStreams : Model -> PaginatedList Stream
filteredStreams model =
    Paginate.map (List.filter (isMatch model.searchQuery)) model.streams


displayStream : Stream -> Html Msg
displayStream (Stream name) =
    li [] [ a [ href ("#streams/" ++ name) ] [ text name ] ]


displayStreams : PaginatedList Stream -> Html Msg
displayStreams streams =
    ul [] (List.map displayStream (Paginate.page streams))


getStreams : Cmd Msg
getStreams =
    Http.send StreamList (Http.get "/streams.json" (list streamDecoder))


streamDecoder : Decode.Decoder Stream
streamDecoder =
    Decode.map Stream
        (field "name" string)
