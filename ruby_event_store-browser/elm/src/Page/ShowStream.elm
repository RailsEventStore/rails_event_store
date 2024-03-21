module Page.ShowStream exposing (Model, Msg(..), initCmd, initModel, update, view)

import Api
import BrowserTime
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, href, title)
import Http
import Pagination
import Route
import Url



-- MODEL


type alias Model =
    { events : Api.PaginatedList Api.Event
    , streamName : String
    , flags : Flags
    , relatedStreams : Maybe (List String)
    , problems : List Problem
    , pagination : Pagination.Specification
    }


type Problem
    = ServerError String


initModel : Flags -> String -> Pagination.Specification -> Model
initModel flags streamName paginationSpecification =
    { streamName = streamName
    , events = Api.emptyPaginatedList
    , relatedStreams = Nothing
    , flags = flags
    , problems = []
    , pagination = paginationSpecification
    }



-- UPDATE


type Msg
    = EventsFetched (Result Http.Error (Api.PaginatedList Api.Event))
    | StreamFetched (Result Http.Error Api.Stream)


initCmd : Flags -> String -> Cmd Msg
initCmd flags streamId =
    Api.getStream StreamFetched flags streamId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventsFetched (Ok result) ->
            ( { model | events = result }, Cmd.none )

        EventsFetched (Err _) ->
            let
                serverErrors =
                    [ ServerError "Server error, please check backend logs for details" ]
            in
            ( { model | problems = serverErrors }, Cmd.none )

        StreamFetched (Ok streamResource) ->
            ( { model | relatedStreams = streamResource.relatedStreams }, Api.getEvents EventsFetched model.flags model.streamName model.pagination )

        StreamFetched (Err _) ->
            let
                serverErrors =
                    [ ServerError "Server error, please check backend logs for details" ]
            in
            ( { model | problems = serverErrors }, Cmd.none )


view : Model -> BrowserTime.TimeZone -> ( String, Html Msg )
view { streamName, events, relatedStreams, problems, flags, pagination } selectedTime =
    let
        title =
            "Stream " ++ streamName

        header =
            "Events in " ++ streamName
    in
    case problems of
        [] ->
            ( title
            , browseEvents flags.rootUrl header streamName events relatedStreams selectedTime
            )

        _ ->
            ( title
            , div [ class "py-8" ]
                [ div []
                    [ ul
                        [ class "flex items-center justify-center py-24"
                        ]
                        (List.map viewProblem problems)
                    ]
                ]
            )


browseEvents : Url.Url -> String -> String -> Api.PaginatedList Api.Event -> Maybe (List String) -> BrowserTime.TimeZone -> Html Msg
browseEvents baseUrl title streamName { links, events } relatedStreams timeZone =
    div [ class "py-8 container mx-auto" ]
        [ div
            [ class "flex justify-between" ]
            [ h1
                [ class "font-bold text-2xl" ]
                [ text title ]
            , div [] [ displayPagination streamName baseUrl links ]
            ]
        , div [] [ renderResults baseUrl events timeZone ]
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
                []
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


displayPagination : String -> Url.Url -> Api.PaginationLinks -> Html Msg
displayPagination streamName baseUrl { first, last, next, prev } =
    ul [ class "flex" ]
        [ li [] [ firstPageButton streamName baseUrl first ]
        , li [] [ prevPageButton streamName baseUrl prev ]
        , li [] [ nextPageButton streamName baseUrl next ]
        , li [] [ lastPageButton streamName baseUrl last ]
        ]


maybeHref : String -> Url.Url -> Maybe Api.PaginationLink -> List (Attribute Msg)
maybeHref streamName baseUrl link =
    case link of
        Just url ->
            [ href (Route.paginatedStreamUrl baseUrl streamName url.specification)
            ]

        Nothing ->
            []


paginationStyle : Maybe Api.PaginationLink -> String
paginationStyle link =
    case link of
        Just _ ->
            "text-center text-sm border-red-700 text-red-700 border rounded px-2 py-1 mr-1"

        Nothing ->
            "text-center text-sm border rounded px-2 py-1 mr-1 text-red-700/50 border-red-700/50 cursor-not-allowed"


nextPageButton : String -> Url.Url -> Maybe Api.PaginationLink -> Html Msg
nextPageButton streamName baseUrl link =
    a
        (class (paginationStyle link) :: maybeHref streamName baseUrl link)
        [ text "next" ]


prevPageButton : String -> Url.Url -> Maybe Api.PaginationLink -> Html Msg
prevPageButton streamName baseUrl link =
    a
        (class (paginationStyle link) :: maybeHref streamName baseUrl link)
        [ text "previous" ]


lastPageButton : String -> Url.Url -> Maybe Api.PaginationLink -> Html Msg
lastPageButton streamName baseUrl link =
    a
        (class (paginationStyle link) :: maybeHref streamName baseUrl link)
        [ text "last" ]


firstPageButton : String -> Url.Url -> Maybe Api.PaginationLink -> Html Msg
firstPageButton streamName baseUrl link =
    a
        (class (paginationStyle link) :: maybeHref streamName baseUrl link)
        [ text "first" ]


renderResults : Url.Url -> List Api.Event -> BrowserTime.TimeZone -> Html Msg
renderResults baseUrl events timeZone =
    case events of
        [] ->
            p
                [ class "flex items-center justify-center py-24" ]
                [ text "No items" ]

        _ ->
            div
                [ class "overflow-x-scroll sm:overflow-visible w-full" ]
                [ table
                    [ class "my-10 w-full lg:table-fixed text-left"
                    ]
                    [ thead
                        [ class "align-bottom leading-tight sticky top-0 bg-white/70 backdrop-blur-sm text-gray-500 uppercase text-xs"
                        ]
                        [ tr
                            [ class "border-gray-400 border-b" ]
                            [ th
                                [ class "p-4" ]
                                [ text "Event name" ]
                            , th
                                [ class "py-4  pr-4 lg:w-80" ]
                                [ text "Event id" ]
                            , th
                                [ class "py-4  pr-4  text-right lg:w-60" ]
                                [ span
                                    [ class "cursor-help", title timeZone.zoneName ]
                                    [ text "Created at" ]
                                ]
                            ]
                        ]
                    , tbody
                        [ class "align-top" ]
                        (List.map (itemRow baseUrl timeZone) events)
                    ]
                ]


itemRow : Url.Url -> BrowserTime.TimeZone -> Api.Event -> Html Msg
itemRow baseUrl timeZone { eventType, createdAt, eventId } =
    tr [ class "border-gray-50 border-b hover:bg-gray-100" ]
        [ td
            []
            [ a
                [ class "text-red-700 no-underline min-h-11 w-full flex items-center px-4"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ span
                    [ class "break-words min-w-0" ]
                    [ text eventType ]
                ]
            ]
        , td
            [ class "font-mono text-sm leading-none font-medium align-middle" ]
            [ a
                [ class "no-underline h-full min-h-11 flex items-center"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventId ]
            ]
        , td
            [ class "font-mono text-sm leading-none font-medium" ]
            [ a
                [ class "no-underline min-h-11 flex items-center justify-end px-4"
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ span
                    [ title timeZone.zoneName ]
                    [ text (BrowserTime.format timeZone createdAt) ]
                ]
            ]
        ]
