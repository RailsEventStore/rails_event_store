module Search exposing (..)

import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (autofocus, class, href, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import List
import Task


type alias Stream =
    String


type alias Model a =
    { streams : List Stream
    , value : Stream
    , onSelectMsg : Stream -> a
    , onQueryMsg : Stream -> a
    }


type Msg
    = StreamChanged Stream
    | GoToStream Stream


init : (Stream -> a) -> (Stream -> a) -> Model a
init onSelectMsg onQueryMsg =
    { streams = []
    , value = emptyStreamName
    , onSelectMsg = onSelectMsg
    , onQueryMsg = onQueryMsg
    }


update : Msg -> Model a -> ( Model a, Cmd a )
update msg model =
    case msg of
        StreamChanged stream ->
            if hasAtLeastThreeChars stream then
                ( { model | value = stream }
                , onQueryChangedCmd model.onQueryMsg stream
                )

            else
                ( { model | value = stream }, Cmd.none )

        GoToStream stream ->
            ( { model | value = emptyStreamName }
            , onSelectCmd model.onSelectMsg stream
            )


view : Model a -> Html Msg
view model =
    form [ onSubmit (GoToStream model.value) ]
        [ div [ class "relative" ]
            [ FeatherIcons.search
                |> FeatherIcons.withClass "size-4 text-gray-400 absolute pointer-events-none top-3.5 left-2"
                |> FeatherIcons.toHtml []
            , input
                [ class "rounded text-gray-800 cursor-pointer pl-8 pr-12 py-2 w-full appearance-none outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50"
                , value model.value
                , onInput StreamChanged
                , placeholder "Quick search…"
                , autofocus True
                ]
                []
            , span [ class "absolute top-0 h-full flex items-center right-3 text-[.5rem] pointer-events-none" ]
                [ span [ class "text-gray-500 bg-gray-50 font-bold block p-1 border border-gray-300 rounded " ] [ text "ESC" ]
                ]
            ]
        , if model |> streamsPresent then
            viewStreamList model

          else
            text ""
        ]


viewStreamList : Model a -> Html Msg
viewStreamList { value, streams } =
    div
        []
        [ ul
            [ class "mt-4 overflow-auto space-y-2 w-full" ]
            (streams
                |> filterStreams value
                |> List.map viewStreamListItem
            )
        ]


viewStreamListItem : Stream -> Html Msg
viewStreamListItem stream =
    li []
        [ a
            [ class "p-3 block rounded hover:bg-red-200 w-full bg-gray-100 break-words text-xs font-bold font-mono"
            , href ("/streams/" ++ stream)
            ]
            [ text stream ]
        ]


emptyStreamName : Stream
emptyStreamName =
    ""


onSelectCmd : (Stream -> a) -> Stream -> Cmd a
onSelectCmd onSelectMsg stream =
    Task.perform onSelectMsg (Task.succeed stream)


onQueryChangedCmd : (Stream -> a) -> Stream -> Cmd a
onQueryChangedCmd onQueryMsg stream =
    Task.perform onQueryMsg (Task.succeed stream)


hasAtLeastThreeChars : Stream -> Bool
hasAtLeastThreeChars stream =
    String.length stream >= 3


streamsPresent : Model a -> Bool
streamsPresent { streams } =
    not <| List.isEmpty streams


filterStreams : Stream -> List Stream -> List Stream
filterStreams stream streams =
    if String.isEmpty stream then
        []

    else
        List.filter (String.contains stream) streams
