module ViewStreamUI exposing (Event, Model, Msg(..), PaginatedList, PaginationLink, PaginationLinks, view)

import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Html.Events exposing (onClick)
import Url
import Route


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
    }


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
    { events : PaginatedList Event
    , streamName : String
    }


type Msg
    = GoToPage PaginationLink


view : Model -> Html Msg
view model =
    browseEvents ("Events in " ++ model.streamName) model.events


browseEvents : String -> PaginatedList Event -> Html Msg
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


renderResults : List Event -> Html Msg
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


itemRow : Event -> Html Msg
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
