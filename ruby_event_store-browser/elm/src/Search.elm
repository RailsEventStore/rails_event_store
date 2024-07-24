module Search exposing (..)

import FeatherIcons
import Html exposing (..)
import Html.Attributes exposing (autofocus, class, id, list, placeholder, value)
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


globalStreamName : Stream
globalStreamName =
    "all"


emptyStreamName : Stream
emptyStreamName =
    ""


init : (Stream -> a) -> (Stream -> a) -> Model a
init onSelectMsg onQueryMsg =
    { streams = [ globalStreamName ]
    , value = emptyStreamName
    , onSelectMsg = onSelectMsg
    , onQueryMsg = onQueryMsg
    }


onSelectCmd : (Stream -> a) -> Stream -> Cmd a
onSelectCmd onSelectMsg stream =
    Task.perform onSelectMsg (Task.succeed stream)


onQueryChangedCmd : (Stream -> a) -> Stream -> Cmd a
onQueryChangedCmd onQueryMsg stream =
    Task.perform onQueryMsg (Task.succeed stream)


isExactStream : String -> List String -> Bool
isExactStream stream streams =
    List.any ((==) stream) streams

hasAtLeastThreeChars : Stream -> Bool
hasAtLeastThreeChars stream =
    String.length stream >= 3


update : Msg -> Model a -> ( Model a, Cmd a )
update msg model =
    case msg of
        StreamChanged stream ->
            if isExactStream stream model.streams then
                ( { model | value = emptyStreamName }
                , onSelectCmd model.onSelectMsg stream
                )

            else
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


view : Model msg -> Html Msg
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
                , list "streams"
                , autofocus True
                ]
                []
            , span [ class "absolute top-0 h-full flex items-center right-3 text-[.5rem] pointer-events-none" ]
                [ span [ class "text-gray-500 bg-gray-50 font-bold block p-1 border border-gray-300 rounded " ] [ text "ESC" ]
                ]
            ]
        , datalist
            [ id "streams", class "appearance-none" ]
            (List.map
                (\stream -> option [] [ text stream ])
                model.streams
            )
        ]
