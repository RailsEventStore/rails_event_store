module Main exposing (..)

import Html exposing (Html, ul, li, text, div, input, button)
import Html.Attributes exposing (placeholder, disabled)
import Html.Events exposing (onInput, onClick)
import Paginate exposing (..)
import Http
import Json.Decode as Decode exposing (map, field, list, string)


main : Program Never Model Msg
main =
    Html.program { init = model, view = view, update = update, subscriptions = subscriptions }


type alias Model =
    { streams : PaginatedList Stream
    , searchQuery : String
    }


type Msg
    = Search String
    | NextPage
    | PreviousPage
    | StreamList (Result Http.Error (List Stream))


type Stream
    = Stream String


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


model : ( Model, Cmd Msg )
model =
    ( { streams = Paginate.fromList 10 []
      , searchQuery = ""
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
            ( { model | streams = Paginate.fromList 10 result }, Cmd.none )

        StreamList (Err msg) ->
            ( model, Cmd.none )


isMatch : String -> Stream -> Bool
isMatch searchQuery (Stream name) =
    String.contains searchQuery name


view : Model -> Html Msg
view model =
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
    li [] [ text name ]


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
