module Page.ViewStream exposing (Model, Msg(..), eventsDecoder, initCmd, initModel, update, view)

import Api
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, Value, at, field, list, maybe, oneOf, string, succeed, value)
import Json.Decode.Pipeline exposing (optional, required, requiredAt)
import Json.Encode exposing (encode)
import Route
import Url



-- MODEL


type alias PaginatedList a =
    { events : List a
    , links : PaginationLinks
    }


type alias PaginationLink =
    String


type alias PaginationLinks =
    { next : Maybe PaginationLink
    , prev : Maybe PaginationLink
    , first : Maybe PaginationLink
    , last : Maybe PaginationLink
    }


type alias Model =
    { events : PaginatedList Api.Event
    , streamName : String
    }


initModel : String -> Model
initModel streamName =
    let
        initLinks =
            { prev = Nothing
            , next = Nothing
            , first = Nothing
            , last = Nothing
            }
    in
    { streamName = streamName
    , events = PaginatedList [] initLinks
    }



-- UPDATE


type Msg
    = GoToPage PaginationLink
    | GetEvents (Result Http.Error (PaginatedList Api.Event))


initCmd : Flags -> String -> Cmd Msg
initCmd flags streamId =
    getEvents (Route.buildUrl flags.streamsUrl streamId)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoToPage paginationLink ->
            ( model, getEvents paginationLink )

        GetEvents (Ok result) ->
            ( { model | events = result }, Cmd.none )

        GetEvents (Err errorMessage) ->
            ( model, Cmd.none )


getEvents : String -> Cmd Msg
getEvents url =
    Http.get url eventsDecoder
        |> Http.send GetEvents


eventsDecoder : Decoder (PaginatedList Api.Event)
eventsDecoder =
    succeed PaginatedList
        |> required "data" (list Api.eventDecoder_)
        |> required "links" linksDecoder


linksDecoder : Decoder PaginationLinks
linksDecoder =
    succeed PaginationLinks
        |> optional "next" (maybe string) Nothing
        |> optional "prev" (maybe string) Nothing
        |> optional "first" (maybe string) Nothing
        |> optional "last" (maybe string) Nothing



-- VIEW


view : Model -> Html Msg
view model =
    browseEvents ("Events in " ++ model.streamName) model.events


browseEvents : String -> PaginatedList Api.Event -> Html Msg
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


renderResults : List Api.Event -> Html Msg
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


itemRow : Api.Event -> Html Msg
itemRow { eventType, createdAt, eventId } =
    tr []
        [ td []
            [ a
                [ class "results__link"
                , href (Route.buildUrl "#events" eventId)
                ]
                [ text eventType ]
            ]
        , td [] [ text eventId ]
        , td [ class "u-align-right" ]
            [ text createdAt
            ]
        ]
