module Page.ShowStream exposing (Model, Msg(..), initCmd, initModel, update, view)

import Api
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href)
import Html.Events exposing (onClick)
import Http
import Route
import Task exposing (Task)
import Time
import TimeHelpers exposing (formatTimestamp)
import TimeZone
import Url



-- MODEL


type alias Model =
    { events : Api.PaginatedList Api.Event
    , streamName : String
    , flags : Flags
    , relatedStreams : Maybe (List String)
    , problems : List Problem
    , zone : Time.Zone
    , zoneName : String
    }


type Problem
    = ServerError String


initModel : Flags -> String -> Model
initModel flags streamName =
    { streamName = streamName
    , events = Api.emptyPaginatedList
    , relatedStreams = Nothing
    , flags = flags
    , problems = []
    , zone = Time.utc
    , zoneName = "UTC"
    }



-- UPDATE


type Msg
    = GoToPage Api.PaginationLink
    | EventsFetched (Result Http.Error (Api.PaginatedList Api.Event))
    | StreamFetched (Result Http.Error Api.Stream)
    | ReceiveTimeZone (Result TimeZone.Error ( String, Time.Zone ))


initCmd : Flags -> String -> Cmd Msg
initCmd flags streamId =
    Cmd.batch
        [ Api.getStream StreamFetched flags streamId
        , TimeZone.getZone |> Task.attempt ReceiveTimeZone
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoToPage paginationLink ->
            ( model, Api.getEvents EventsFetched paginationLink )

        EventsFetched (Ok result) ->
            ( { model | events = result }, Cmd.none )

        EventsFetched (Err _) ->
            let
                serverErrors =
                    [ ServerError "Server error, please check backend logs for details" ]
            in
            ( { model | problems = serverErrors }, Cmd.none )

        StreamFetched (Ok streamResource) ->
            ( { model | relatedStreams = streamResource.relatedStreams }, Api.getEvents EventsFetched streamResource.eventsRelationshipLink )

        StreamFetched (Err _) ->
            let
                serverErrors =
                    [ ServerError "Server error, please check backend logs for details" ]
            in
            ( { model | problems = serverErrors }, Cmd.none )

        ReceiveTimeZone (Ok ( zoneName, zone )) ->
            ( { model | zone = zone, zoneName = zoneName }, Cmd.none )

        ReceiveTimeZone (Err error) ->
            ( model, Cmd.none )


view : Model -> ( String, Html Msg )
view { streamName, events, relatedStreams, problems, flags, zone, zoneName } =
    let
        title =
            "Stream " ++ streamName

        header =
            "Events in " ++ streamName
    in
    case problems of
        [] ->
            ( title
            , browseEvents flags.rootUrl header events relatedStreams zone zoneName
            )

        _ ->
            ( title
            , div [ class "py-8" ]
                [ div [ class "px-8" ]
                    [ ul
                        [ class "flex items-center justify-center py-24"
                        ]
                        (List.map viewProblem problems)
                    ]
                ]
            )


browseEvents : Url.Url -> String -> Api.PaginatedList Api.Event -> Maybe (List String) -> Time.Zone -> String -> Html Msg
browseEvents baseUrl title { links, events } relatedStreams zone zoneName =
    div [ class "py-8" ]
        [ div
            [ class "flex px-8 justify-between" ]
            [ h1
                [ class "font-bold text-2xl" ]
                [ text title ]
            , div [] [ displayPagination links ]
            ]
        , div [ class "px-8" ] [ renderResults baseUrl events zone zoneName ]
        , div [] [ renderRelatedStreams baseUrl relatedStreams ]
        ]


viewProblem : Problem -> Html msg
viewProblem problem =
    let
        errorMessage =
            case problem of
                ServerError str ->
                    str
    in
    li [] [ text errorMessage ]


renderRelatedStreams : Url.Url -> Maybe (List String) -> Html Msg
renderRelatedStreams baseUrl relatedStreams_ =
    case relatedStreams_ of
        Just relatedStreams ->
            div
                [ class "px-8"
                ]
                [ h2
                    [ class "font-bold text-xl" ]
                    [ text "Related streams:" ]
                , ul
                    [ class "list-disc pl-8" ]
                    (List.map (\relatedStream -> li [] [ streamLink baseUrl relatedStream ]) relatedStreams)
                ]

        Nothing ->
            emptyHtml


emptyHtml : Html a
emptyHtml =
    text ""


streamLink : Url.Url -> String -> Html Msg
streamLink baseUrl streamName =
    a
        [ class "text-red-700 no-underline"
        , href (Route.streamUrl baseUrl streamName)
        ]
        [ text streamName ]


displayPagination : Api.PaginationLinks -> Html Msg
displayPagination { first, last, next, prev } =
    ul [ class "flex" ]
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


paginationStyle : String
paginationStyle =
    "text-center text-sm border-red-700 text-red-700 border rounded px-2 py-1 mr-1 disabled:text-red-700/50 disabled:border-red-700/50 disabled:cursor-not-allowed"


nextPageButton : Maybe Api.PaginationLink -> Html Msg
nextPageButton link =
    button
        (class paginationStyle :: maybeHref link)
        [ text "next" ]


prevPageButton : Maybe Api.PaginationLink -> Html Msg
prevPageButton link =
    button
        (class paginationStyle :: maybeHref link)
        [ text "previous" ]


lastPageButton : Maybe Api.PaginationLink -> Html Msg
lastPageButton link =
    button
        (class paginationStyle :: maybeHref link)
        [ text "last" ]


firstPageButton : Maybe Api.PaginationLink -> Html Msg
firstPageButton link =
    button
        (class paginationStyle :: maybeHref link)
        [ text "first" ]


renderResults : Url.Url -> List Api.Event -> Time.Zone -> String -> Html Msg
renderResults baseUrl events zone zoneName =
    case events of
        [] ->
            p
                [ class "flex items-center justify-center py-24" ]
                [ text "No items" ]

        _ ->
            table
                [ class "my-10 w-full text-left border-collapse"
                ]
                [ thead
                    [ class "align-bottom leading-tight"
                    ]
                    [ tr []
                        [ th
                            [ class "border-gray-400 border-b text-gray-500 uppercase pb-4 px-4 text-xs" ]
                            [ text "Event name" ]
                        , th
                            [ class "border-gray-400 border-b text-gray-500 uppercase pb-4 pr-4 text-xs" ]
                            [ text "Event id" ]
                        , th
                            [ class "border-gray-400 border-b text-gray-500 uppercase pb-4 pr-4 text-xs text-right" ]
                            [ text "Created at" ]
                        ]
                    ]
                , tbody
                    [ class "align-top" ]
                    (List.map (itemRow baseUrl zone zoneName) events)
                ]


itemRow : Url.Url -> Time.Zone -> String -> Api.Event -> Html Msg
itemRow baseUrl zone zoneName { eventType, createdAt, eventId } =
    tr [ class "border-gray-50 border-b hover:bg-gray-100" ]
        [ td
            [ class "py-2 px-4 align-middle" ]
            [ a
                [ class "text-red-700 no-underline"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventType ]
            ]
        , td
            [ class "py-2  pr-4 font-mono text-sm leading-none font-medium align-middle" ]
            [ text eventId ]
        , td
            [ class "py-2  pr-4 font-mono text-sm leading-none font-medium text-right align-middle" ]
            [ text (formatTimestamp createdAt zone zoneName) ]
        ]
