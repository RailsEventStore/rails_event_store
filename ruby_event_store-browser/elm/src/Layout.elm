port module Layout exposing (Model, Msg, buildModel, subscriptions, update, view, viewIncorrectConfig, viewNotFound)

import Browser.Events
import Browser.Navigation
import BrowserTime
import Dict
import Html exposing (..)
import Html.Attributes exposing (class, href, id, list, placeholder, selected, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Decode
import LinkedTimezones exposing (mapLinkedTimeZone)
import List.Extra
import Route
import Search exposing (..)
import TimeZone exposing (zones)
import Url
import WrappedModel exposing (..)


type Msg
    = TimeZoneSelected String
    | SearchMsg Search.Msg
    | KeyPress String Bool
    | ToggleDialog


type alias Model =
    { search : Search.Model
    }


port toggleDialog : String -> Cmd msg


subscriptions : Sub Msg
subscriptions =
    Browser.Events.onKeyDown keyboardDecoder


keyboardDecoder : Json.Decode.Decoder Msg
keyboardDecoder =
    Json.Decode.map2
        KeyPress
        (Json.Decode.field "key" Json.Decode.string)
        (Json.Decode.field "metaKey" Json.Decode.bool)


buildModel : Model
buildModel =
    { search =
        Search.init
    }


goToStream model stream =
    Browser.Navigation.pushUrl model.key (Route.streamUrl model.flags.rootUrl stream)


update : Msg -> WrappedModel Model -> ( WrappedModel Model, Cmd Msg )
update msg model =
    case msg of
        SearchMsg searchMsg ->
            let
                internal =
                    model.internal

                search =
                    internal.search

                ( newSearchWrapped, cmd ) =
                    Search.update searchMsg (WrappedModel search model.key model.time model.flags) (goToStream model)

                newSearch =
                    newSearchWrapped.internal
            in
            ( { model | internal = Model newSearch }, Cmd.map SearchMsg cmd )

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
                    betterZoneName =
                        mapLinkedTimeZone zoneName

                    maybeZone =
                        Dict.get betterZoneName zones
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

        KeyPress key isDown ->
            case ( key, isDown ) of
                ( "k", True ) ->
                    ( model, toggleDialog searchModalId )

                _ ->
                    ( model, Cmd.none )

        ToggleDialog ->
            ( model, toggleDialog searchModalId )


view : (Msg -> a) -> WrappedModel Model -> Html a -> Html a
view layoutMsgBuilder model pageView =
    div
        [ class "bg-gray-100 flex flex-col min-h-screen w-full text-gray-800 font-sans leading-relaxed antialiased" ]
        [ header []
            [ Html.map layoutMsgBuilder (browserNavigation model)
            ]
        , main_
            [ class "bg-white flex w-full grow" ]
            [ pageView
            , Html.map layoutMsgBuilder (searchModal model)
            ]
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
            [ fakeSearchInput ]
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


fakeSearchInput : Html Msg
fakeSearchInput =
    button
        [ onClick ToggleDialog
        , class "bg-white"
        ]
        [ text "Go to stream..." ]


realSearchInput : WrappedModel Model -> Html Msg
realSearchInput model =
    Html.map SearchMsg (Search.view model.internal.search)


searchModalId =
    "search-modal"


searchModal : WrappedModel Model -> Html Msg
searchModal model =
    node "dialog"
        [ id searchModalId ]
        [ realSearchInput model ]
