module Page.ShowStream exposing (Model, Msg(..), initCmd, initModel, update, view)

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
import TimeHelpers exposing (formatTimestamp)
import Url



-- MODEL


type alias Model =
    { events : Api.PaginatedList Api.Event
    , streamName : String
    , flags : Flags
    , relatedStreams : Maybe (List String)
    }


initModel : Flags -> String -> Model
initModel flags streamName =
    { streamName = streamName
    , events = Api.emptyPaginatedList
    , relatedStreams = Nothing
    , flags = flags
    }



-- UPDATE


type Msg
    = GoToPage Api.PaginationLink
    | EventsFetched (Result Http.Error (Api.PaginatedList Api.Event))
    | StreamFetched (Result Http.Error Api.Stream)


initCmd : Flags -> String -> Cmd Msg
initCmd flags streamId =
    Api.getStream StreamFetched flags streamId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoToPage paginationLink ->
            ( model, Api.getEvents EventsFetched paginationLink )

        EventsFetched (Ok result) ->
            ( { model | events = result }, Cmd.none )

        EventsFetched (Err errorMessage) ->
            ( model, Cmd.none )

        StreamFetched (Ok streamResource) ->
            ( { model | relatedStreams = streamResource.relatedStreams }, Api.getEvents EventsFetched streamResource.eventsRelationshipLink )

        StreamFetched (Err errorMessage) ->
            ( model, Cmd.none )



-- VIEW


view : Model -> ( String, Html Msg )
view model =
    ( "Stream " ++ model.streamName, browseEvents model.flags.rootUrl ("Events in " ++ model.streamName) model.events model.relatedStreams )


browseEvents : Url.Url -> String -> Api.PaginatedList Api.Event -> Maybe (List String) -> Html Msg
browseEvents baseUrl title { links, events } relatedStreams =
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text title ]
        , div [ class "browser__pagination" ] [ displayPagination links ]
        , div [ class "browser__results" ] [ renderResults baseUrl events ]
        , div [] [ renderRelatedStreams baseUrl relatedStreams ]
        ]


renderRelatedStreams : Url.Url -> Maybe (List String) -> Html Msg
renderRelatedStreams baseUrl relatedStreams_ =
    case relatedStreams_ of
        Just relatedStreams ->
            div [ class "event__related-streams" ]
                [ h2 [] [ text "Related streams:" ]
                , ul [] (List.map (\relatedStream -> li [] [ streamLink baseUrl relatedStream ]) relatedStreams)
                ]

        Nothing ->
            emptyHtml


emptyHtml : Html a
emptyHtml =
    text ""


streamLink : Url.Url -> String -> Html Msg
streamLink baseUrl streamName =
    a [ class "event__stream-link", href (Route.streamUrl baseUrl streamName) ] [ text streamName ]


displayPagination : Api.PaginationLinks -> Html Msg
displayPagination { first, last, next, prev } =
    ul [ class "pagination" ]
        [ li [] [ firstPageButton first ]
        , li [] [ prevPageButton prev ]
        , li [] [ nextPageButton next ]
        , li [] [ lastPageButton last ]
        ]


maybeHref : Maybe Api.PaginationLink -> List (Attribute Msg)
maybeHref link =
    case link of
        Just url ->
            [ href url
            , onClick (GoToPage url)
            ]

        Nothing ->
            [ disabled True
            ]


nextPageButton : Maybe Api.PaginationLink -> Html Msg
nextPageButton link =
    button
        ([ class "pagination__page"
         ]
            ++ maybeHref link
        )
        [ text "next" ]


prevPageButton : Maybe Api.PaginationLink -> Html Msg
prevPageButton link =
    button
        ([ class "pagination__page"
         ]
            ++ maybeHref link
        )
        [ text "previous" ]


lastPageButton : Maybe Api.PaginationLink -> Html Msg
lastPageButton link =
    button
        ([ class "pagination__page"
         ]
            ++ maybeHref link
        )
        [ text "last" ]


firstPageButton : Maybe Api.PaginationLink -> Html Msg
firstPageButton link =
    button
        ([ class "pagination__page"
         ]
            ++ maybeHref link
        )
        [ text "first" ]


renderResults : Url.Url -> List Api.Event -> Html Msg
renderResults baseUrl events =
    case events of
        [] ->
            p [ class "results__empty" ] [ text "No items" ]

        _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Event name" ]
                        , th [] [ text "Event id" ]
                        , th [ class "text-right" ] [ text "Created at" ]
                        ]
                    ]
                , tbody [] (List.map (itemRow baseUrl) events)
                ]


itemRow : Url.Url -> Api.Event -> Html Msg
itemRow baseUrl { eventType, createdAt, eventId } =
    tr []
        [ td []
            [ a
                [ class "results__link"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventType ]
            ]
        , td [] [ text eventId ]
        , td [ class "text-right" ]
            [ text (formatTimestamp createdAt)
            ]
        ]
