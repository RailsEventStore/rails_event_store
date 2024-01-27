module Layout exposing (Model, Msg, buildModel, update, view, viewIncorrectConfig, viewNotFound)

import Browser.Navigation
import BrowserTime
import Dict
import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, selected, value)
import Html.Events exposing (onInput, onSubmit)
import List.Extra
import Route
import TimeZone exposing (zones)
import Url
import WrappedModel exposing (..)


type Msg
    = GoToStream
    | GoToStreamChanged String
    | TimeZoneSelected String


type alias Model =
    { goToStream : String
    }


buildModel : Model
buildModel =
    { goToStream = ""
    }


update : Msg -> WrappedModel Model -> ( WrappedModel Model, Cmd Msg )
update msg model =
    case msg of
        GoToStream ->
            ( { model | internal = Model "" }, Browser.Navigation.pushUrl model.key (Route.streamUrl model.flags.rootUrl model.internal.goToStream) )

        GoToStreamChanged newValue ->
            ( { model | internal = Model newValue }, Cmd.none )

        TimeZoneSelected zoneName ->
            let
                defaultTimeZone =
                    BrowserTime.defaultTimeZone
            in
            if zoneName == defaultTimeZone.zoneName then
                let
                    time =
                        model.time

                    newTime =
                        { time | selected = defaultTimeZone }
                in
                ( { model | time = newTime }, Cmd.none )

            else
                let
                    maybeZone =
                        Dict.get zoneName zones
                in
                case maybeZone of
                    Just zone ->
                        let
                            time =
                                model.time

                            newTime =
                                { time | selected = BrowserTime.TimeZone (zone ()) zoneName }
                        in
                        ( { model | time = newTime }, Cmd.none )

                    Nothing ->
                        ( model, Cmd.none )


view : (Msg -> a) -> WrappedModel Model -> Html a -> Html a
view layoutMsgBuilder model pageView =
    div
        [ class "bg-gray-100 min-h-screen w-full text-gray-800 font-sans leading-relaxed antialiased" ]
        [ header []
            [ Html.map layoutMsgBuilder (browserNavigation model)
            ]
        , main_
            [ class "bg-white" ]
            [ pageView ]
        , footer []
            [ Html.map layoutMsgBuilder (browserFooter model)
            ]
        ]


viewNotFound : Html a
viewNotFound =
    h1 [] [ text "404" ]


viewIncorrectConfig : Html a
viewIncorrectConfig =
    h1 [] [ text "Incorrect RES Browser config" ]


browserNavigation : WrappedModel Model -> Html Msg
browserNavigation model =
    nav
        [ class "flex bg-red-700 px-8 h-16" ]
        [ div
            [ class "flex items-center" ]
            [ a
                [ href (Url.toString model.flags.rootUrl)
                , class "text-gray-100 font-semibold"
                ]
                [ text "Ruby Event Store" ]
            ]
        , div
            [ class "flex-1" ]
            []
        , div
            [ class "flex items-center" ]
            [ form [ onSubmit GoToStream ]
                [ input
                    [ class "rounded px-4 py-2"
                    , value model.internal.goToStream
                    , onInput GoToStreamChanged
                    , placeholder "Go to stream..."
                    ]
                    []
                ]
            ]
        ]


availableTimeZones : BrowserTime.TimeZone -> List BrowserTime.TimeZone
availableTimeZones detectedTime =
    List.Extra.unique [ BrowserTime.defaultTimeZone, detectedTime ]


browserFooter : WrappedModel Model -> Html Msg
browserFooter { flags, time } =
    let
        spacer =
            span
                [ class "ml-4 font-bold inline-block text-gray-400" ]
                [ text "•" ]
    in
    footer
        [ class "border-gray-400 border-t py-4 px-8 flex justify-between" ]
        [ div
            [ class "text-gray-500 text-sm" ]
            [ text ("RubyEventStore v" ++ flags.resVersion)
            , spacer
            , a
                [ href "https://railseventstore.org/docs/install/"
                , class "ml-4"
                ]
                [ text "Documentation" ]
            , spacer
            , a
                [ href "https://railseventstore.org/support/"
                , class "ml-4"
                ]
                [ text "Support" ]
            ]
        , div
            [ class "text-gray-500 text-sm" ]
            [ Html.select
                [ onInput TimeZoneSelected ]
                (List.map
                    (\timeZone ->
                        option
                            [ value timeZone.zoneName
                            , selected (timeZone == time.selected)
                            ]
                            [ text timeZone.zoneName
                            ]
                    )
                    (availableTimeZones time.detected)
                )
            ]
        ]
