module Search exposing (..)

import Api exposing (SearchStream, getSearchStreams)
import FeatherIcons
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (autofocus, class, id, list, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import List exposing (any)
import Page.ShowStream exposing (Msg(..))
import Task


type alias Stream =
    String


type alias Model =
    { streams : List Stream
    , value : Stream
    }


type Msg
    = StreamChanged Stream
    | GoToStream Stream
    | SearchedStreamsFetched (Result Http.Error (List SearchStream))
    | OnSelect Stream


init : Model
init =
    { streams = [ "all" ]
    , value = ""
    }


hackWithInternalOnSelectMsg : Stream -> Cmd Msg
hackWithInternalOnSelectMsg stream =
    Task.perform OnSelect (Task.succeed stream)


searchStreams : Flags -> Stream -> Cmd Msg
searchStreams flags stream =
    getSearchStreams SearchedStreamsFetched flags stream


isExactStream : String -> List String -> Bool
isExactStream stream streams =
    List.any (\s -> s == stream) streams


update : Msg -> Model -> Flags -> (String -> Cmd Msg) -> ( Model, Cmd Msg )
update msg model flags onSubmit =
    case msg of
        StreamChanged stream ->
            if isExactStream stream model.streams then
                ( { model | value = "" }
                , Cmd.batch
                    [ onSubmit stream
                    , hackWithInternalOnSelectMsg stream
                    ]
                )

            else
                ( { model | value = stream }, searchStreams flags stream )

        GoToStream stream ->
            ( { model | value = "" }
            , Cmd.batch
                [ onSubmit stream
                , hackWithInternalOnSelectMsg stream
                ]
            )

        SearchedStreamsFetched (Ok streams) ->
            ( { model | streams = "all" :: List.map .streamId streams }, Cmd.none )

        SearchedStreamsFetched (Err _) ->
            ( { model | streams = [] }, Cmd.none )

        OnSelect _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
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
