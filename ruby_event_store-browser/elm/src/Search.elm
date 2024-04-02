module Search exposing (..)

import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (autofocus, class, href, placeholder, value)
import Html.Events exposing (onInput, onSubmit, onClick)
import List
import Task


type alias Stream =
    String


type alias Model a =
    { streams : List Stream
    , searchedStream : Stream
    , onSelectMsg : Stream -> a
    , onQueryMsg : Stream -> a
    }


type Msg
    = StreamChanged Stream
    | GoToStream Stream


init : (Stream -> a) -> (Stream -> a) -> Model a
init onSelectMsg onQueryMsg =
    { streams = emptyStreams
    , searchedStream = emptyStreamName
    , onSelectMsg = onSelectMsg
    , onQueryMsg = onQueryMsg
    }


update : Msg -> Model a -> ( Model a, Cmd a )
update msg model =
    case msg of
        StreamChanged stream ->
            if hasAtLeastThreeChars stream then
                ( { model | searchedStream = stream }
                , onQueryChangedCmd model.onQueryMsg stream
                )

            else
                ( { model | searchedStream = stream }, Cmd.none )

        GoToStream stream ->
            ( { model | searchedStream = emptyStreamName }
            , onSelectCmd model.onSelectMsg stream
            )


view : Model a -> Html Msg
view model =
    let
        streams_ =
            filterStreams model.searchedStream model.streams
    in
    form [ onSubmit (GoToStream model.searchedStream) ]
        [ div [ class "relative" ]
            [ FeatherIcons.search
                |> FeatherIcons.withClass "size-4 text-gray-400 absolute pointer-events-none top-3.5 left-2"
                |> FeatherIcons.toHtml []
            , input
                [ class "rounded text-gray-800 cursor-pointer pl-8 pr-12 py-2 w-full appearance-none outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50"
                , value model.searchedStream
                , onInput StreamChanged
                , placeholder "Quick search…"
                , autofocus True
                ]
                []
            , span [ class "absolute top-0 h-full flex items-center right-3 text-[.5rem] pointer-events-none" ]
                [ span [ class "text-gray-500 bg-gray-50 font-bold block p-1 border border-gray-300 rounded " ] [ text "ESC" ]
                ]
            ]
        , viewStreamList streams_
        ]


viewStreamList : List Stream -> Html Msg
viewStreamList streams =
    if streams |> streamsPresent then
        div
            []
            [ ul
                [ class "mt-4 overflow-auto space-y-2 w-full" ]
                (List.map viewStreamListItem streams)
            ]

    else
        text ""


viewStreamListItem : Stream -> Html Msg
viewStreamListItem stream =
    li []
        [ a
            [ class "p-3 block rounded hover:bg-red-200 w-full bg-gray-100 break-words text-xs font-bold font-mono"
            , href ("/streams/" ++ stream)
            , onClick (GoToStream stream)
            ]
            [ text stream ]
        ]


emptyStreamName : Stream
emptyStreamName =
    ""


emptyStreams : List Stream
emptyStreams =
    []


onSelectCmd : (Stream -> a) -> Stream -> Cmd a
onSelectCmd onSelectMsg stream =
    Task.perform onSelectMsg (Task.succeed stream)


onQueryChangedCmd : (Stream -> a) -> Stream -> Cmd a
onQueryChangedCmd onQueryMsg stream =
    Task.perform onQueryMsg (Task.succeed stream)


hasAtLeastThreeChars : Stream -> Bool
hasAtLeastThreeChars stream =
    String.length stream >= 3


streamsPresent : List Stream -> Bool
streamsPresent streams =
    not <| List.isEmpty streams


filterStreams : Stream -> List Stream -> List Stream
filterStreams stream streams =
    if String.isEmpty stream then
        emptyStreams

    else
        List.filterMap (caseInsensitiveContains stream) streams


caseInsensitiveContains : Stream -> Stream -> Maybe Stream
caseInsensitiveContains needle haystack =
    let
        needleLower =
            String.toLower needle

        haystackLower =
            String.toLower haystack
    in
    if String.contains needleLower haystackLower then
        Just haystack

    else
        Nothing
