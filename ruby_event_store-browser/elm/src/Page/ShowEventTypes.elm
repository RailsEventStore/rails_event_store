module Page.ShowEventTypes exposing (Model, Msg(..), initCmd, initModel, update, view)

import Api
import BrowserTime
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, href, title)
import Http
import Route
import Url


-- MODEL


type alias Model =
    { eventTypes : List Api.EventType
    , flags : Flags
    , problems : List Problem
    }


type Problem
    = ServerError String


initModel : Flags -> Model
initModel flags =
    { eventTypes = []
    , flags = flags
    , problems = []
    }


-- UPDATE


type Msg
    = EventTypesFetched (Result Http.Error (List Api.EventType))


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getEventTypes EventTypesFetched flags


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventTypesFetched (Ok result) ->
            ( { model | eventTypes = result }, Cmd.none )

        EventTypesFetched (Err _) ->
            let
                serverErrors =
                    [ ServerError "Server error, please check backend logs for details" ]
            in
            ( { model | problems = serverErrors }, Cmd.none )


-- VIEW


view : Model -> BrowserTime.TimeZone -> ( String, Html Msg )
view { eventTypes, problems, flags } _ =
    let
        title =
            "Event Types"

        header =
            "Event Types"
    in
    case problems of
        [] ->
            ( title
            , viewEventTypes flags.rootUrl header eventTypes
            )

        _ ->
            ( title
            , div [ class "py-8" ]
                [ div []
                    [ ul []
                        (List.map
                            (\problem ->
                                case problem of
                                    ServerError error ->
                                        li [] [ text error ]
                            )
                            problems
                        )
                    ]
                ]
            )


viewEventTypes : Url.Url -> String -> List Api.EventType -> Html Msg
viewEventTypes rootUrl header eventTypes =
    div [ class "py-8" ]
        [ h1 [ class "font-semibold text-2xl mb-4" ] [ text header ]
        , if List.isEmpty eventTypes then
            p [ class "text-gray-500" ] [ text "No event types found" ]

          else
            ul [ class "space-y-2" ]
                (List.map (viewEventType rootUrl) eventTypes)
        ]


viewEventType : Url.Url -> Api.EventType -> Html Msg
viewEventType rootUrl eventType =
    li [ class "border-b border-gray-200 py-2" ]
        [ a
            [ href (Route.streamUrl rootUrl eventType.streamName)
            , class "text-blue-600 hover:text-blue-800 font-medium"
            , title ("View " ++ eventType.eventType ++ " events")
            ]
            [ text eventType.eventType ]
        , span [ class "text-gray-500 text-sm ml-2" ]
            [ text ("→ " ++ eventType.streamName) ]
        ]
