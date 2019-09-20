module Page.ViewStream exposing (Model, Msg(..), initCmd, initModel, update, view)

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
    }


initModel : String -> Model
initModel streamName =
    { streamName = streamName
    , events = Api.emptyPaginatedList
    }



-- UPDATE


type Msg
    = GoToPage Api.PaginationLink
    | EventsFetched (Result Http.Error (Api.PaginatedList Api.Event))


initCmd : Flags -> String -> Cmd Msg
initCmd flags streamId =
    Api.getEvents EventsFetched (Route.buildUrl flags.streamsUrl streamId)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoToPage paginationLink ->
            ( model, Api.getEvents EventsFetched paginationLink )

        EventsFetched (Ok result) ->
            ( { model | events = result }, Cmd.none )

        EventsFetched (Err errorMessage) ->
            ( model, Cmd.none )



-- VIEW


view : Model -> ( String, Html Msg )
view model =
    ( "Stream " ++ model.streamName, browseEvents ("Events in " ++ model.streamName) model.events )


browseEvents : String -> Api.PaginatedList Api.Event -> Html Msg
browseEvents title { links, events } =
    div [ class "browser" ]
        [ h1 [ class "browser__title" ] [ text title ]
        , div [ class "browser__pagination" ] [ displayPagination links ]
        , div [ class "browser__results" ] [ renderResults events ]
        ]


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
                        , th [ class "text-right" ] [ text "Created at" ]
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
                , href (Route.eventUrl eventId)
                ]
                [ text eventType ]
            ]
        , td [] [ text eventId ]
        , td [ class "text-right" ]
            [ text (formatTimestamp createdAt)
            ]
        ]
