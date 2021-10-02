module Page.ShowStream exposing (Model, Msg(..), initCmd, initModel, update, view)

import Api
import Css
import Flags exposing (Flags)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, disabled, href)
import Html.Styled.Events exposing (onClick)
import Http
import Route
import Tailwind.Utilities as Tw
import TimeHelpers exposing (formatTimestamp)
import Url



-- MODEL


type alias Model =
    { events : Api.PaginatedList Api.Event
    , streamName : String
    , flags : Flags
    , relatedStreams : Maybe (List String)
    , problems : List Problem
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


view : Model -> ( String, Html Msg )
view { streamName, events, relatedStreams, problems, flags } =
    let
        title =
            "Stream " ++ streamName

        header =
            "Events in " ++ streamName
    in
    case problems of
        [] ->
            ( title
            , browseEvents flags.rootUrl header events relatedStreams
            )

        _ ->
            ( title
            , div [ css [ Tw.py_8 ] ]
                [ div [ css [ Tw.px_8 ] ]
                    [ ul
                        [ css
                            [ Tw.flex
                            , Tw.items_center
                            , Tw.justify_center
                            , Tw.py_24
                            ]
                        ]
                        (List.map viewProblem problems)
                    ]
                ]
            )


browseEvents : Url.Url -> String -> Api.PaginatedList Api.Event -> Maybe (List String) -> Html Msg
browseEvents baseUrl title { links, events } relatedStreams =
    div [ css [ Tw.py_8 ] ]
        [ div
            [ css
                [ Tw.flex
                , Tw.px_8
                , Tw.justify_between
                ]
            ]
            [ h1
                [ css
                    [ Tw.font_bold
                    , Tw.text_2xl
                    ]
                ]
                [ text title ]
            , div [] [ displayPagination links ]
            ]
        , div [ css [ Tw.px_8 ] ] [ renderResults baseUrl events ]
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
                [ css [ Tw.px_8 ]
                ]
                [ h2
                    [ css
                        [ Tw.font_bold
                        , Tw.text_xl
                        ]
                    ]
                    [ text "Related streams:" ]
                , ul
                    [ css
                        [ Tw.list_disc
                        , Tw.pl_8
                        ]
                    ]
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
        [ css
            [ Tw.text_red_700
            , Tw.no_underline
            ]
        , href (Route.streamUrl baseUrl streamName)
        ]
        [ text streamName ]


displayPagination : Api.PaginationLinks -> Html Msg
displayPagination { first, last, next, prev } =
    ul [ css [ Tw.flex ] ]
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


paginationStyle =
    [ Tw.text_center
    , Tw.text_sm
    , Tw.border_red_700
    , Tw.text_red_700
    , Tw.border
    , Tw.rounded
    , Tw.px_2
    , Tw.py_1
    , Tw.mr_1
    , Css.disabled [ Tw.opacity_50, Tw.cursor_not_allowed ]
    ]


nextPageButton : Maybe Api.PaginationLink -> Html Msg
nextPageButton link =
    button
        (css paginationStyle :: maybeHref link)
        [ text "next" ]


prevPageButton : Maybe Api.PaginationLink -> Html Msg
prevPageButton link =
    button
        (css paginationStyle :: maybeHref link)
        [ text "previous" ]


lastPageButton : Maybe Api.PaginationLink -> Html Msg
lastPageButton link =
    button
        (css paginationStyle :: maybeHref link)
        [ text "last" ]


firstPageButton : Maybe Api.PaginationLink -> Html Msg
firstPageButton link =
    button
        (css paginationStyle :: maybeHref link)
        [ text "first" ]


renderResults : Url.Url -> List Api.Event -> Html Msg
renderResults baseUrl events =
    case events of
        [] ->
            p
                [ css
                    [ Tw.flex
                    , Tw.items_center
                    , Tw.justify_center
                    , Tw.py_24
                    ]
                ]
                [ text "No items" ]

        _ ->
            table
                [ css
                    [ Tw.my_10
                    , Tw.w_full
                    , Tw.text_left
                    , Tw.table_fixed
                    , Tw.border_collapse
                    ]
                ]
                [ thead
                    [ css
                        [ Tw.align_bottom
                        , Tw.leading_tight
                        ]
                    ]
                    [ tr []
                        [ th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.pb_4
                                , Tw.p_0
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Event name" ]
                        , th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                ]
                            ]
                            [ text "Event id" ]
                        , th
                            [ css
                                [ Tw.border_gray_400
                                , Tw.border_b
                                , Tw.text_gray_500
                                , Tw.uppercase
                                , Tw.p_0
                                , Tw.pb_4
                                , Tw.text_xs
                                , Tw.text_right
                                ]
                            ]
                            [ text "Created at" ]
                        ]
                    ]
                , tbody
                    [ css
                        [ Tw.align_top
                        ]
                    ]
                    (List.map (itemRow baseUrl) events)
                ]


itemRow : Url.Url -> Api.Event -> Html Msg
itemRow baseUrl { eventType, createdAt, eventId } =
    tr []
        [ td
            [ css
                [ Tw.p_0
                , Tw.pt_2
                ]
            ]
            [ a
                [ css
                    [ Tw.text_red_700
                    , Tw.no_underline
                    ]
                , href (Route.eventUrl baseUrl eventId)
                ]
                [ text eventType ]
            ]
        , td
            [ css
                [ Tw.p_0
                , Tw.pt_2
                ]
            ]
            [ text eventId ]
        , td
            [ css
                [ Tw.p_0
                , Tw.pt_2
                , Tw.text_right
                ]
            ]
            [ text (formatTimestamp createdAt)
            ]
        ]
