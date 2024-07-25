module Search exposing (..)

import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (autofocus, class, href, placeholder, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import List
import Task


type alias Stream =
    String


type alias Model a =
    { searchedStream : Stream
    , onSelectMsg : Stream -> a
    }


type Msg
    = StreamChanged Stream
    | GoToStream Stream


emptyStreamName : Stream
emptyStreamName =
    ""


emptyStreams : List Stream
emptyStreams =
    []


init : (Stream -> a) -> Model a
init onSelectMsg =
    { searchedStream = emptyStreamName
    , onSelectMsg = onSelectMsg
    }


onSelectCmd : (Stream -> a) -> Stream -> Cmd a
onSelectCmd onSelectMsg stream =
    Task.perform onSelectMsg (Task.succeed stream)


update : Msg -> Model a -> ( Model a, Cmd a )
update msg model =
    case msg of
        StreamChanged stream ->
            ( { model | searchedStream = stream }, Cmd.none )

        GoToStream stream ->
            ( { model | searchedStream = emptyStreamName }
            , onSelectCmd model.onSelectMsg stream
            )


view : Model a -> Html Msg
view model =
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
        ]
