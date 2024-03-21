port module Layout exposing (Model, Msg, buildModel, subscriptions, update, view, viewIncorrectConfig, viewNotFound)

import Api exposing (SearchStream, getSearchStreams)
import Browser.Events
import Browser.Navigation
import BrowserTime
import Dict
import FeatherIcons
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, href, id, list, placeholder, selected, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
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
    | KeyPress String Bool Bool
    | ToggleBookmarksMenu
    | ToggleDialog
    | SearchedStreamsFetched (Result Http.Error (List SearchStream))
    | OnSelect Search.Stream
    | OnQueryChanged Search.Stream
    | RequestSearch String


type alias Model =
    { search : Search.Model Msg
    , displayBookmarksMenu : Bool
    , bookmarks : List Bookmark
    }


type alias Bookmark =
    { label : String
    , link : String
    , itemType : String
    }


port toggleDialog : String -> Cmd msg


port requestSearch : (String -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    requestSearch RequestSearch


buildModel : Model
buildModel =
    { search =
        Search.init OnSelect OnQueryChanged
    , displayBookmarksMenu = False
    , bookmarks = [ { itemType = "Stream", label = "Bookmark 1", link = "/" }, { itemType = "Stream", label = "Bookmark 2", link = "/" } ]
    }


goToStream : WrappedModel Model -> String -> Cmd msg
goToStream { key, flags } stream =
    Browser.Navigation.pushUrl key (Route.streamUrl flags.rootUrl stream)


searchStreams : WrappedModel Model -> String -> Cmd Msg
searchStreams { flags } stream =
    getSearchStreams SearchedStreamsFetched flags stream


update : Msg -> WrappedModel Model -> ( WrappedModel Model, Cmd Msg )
update msg model =
    case msg of
        SearchMsg searchMsg ->
            let
                ( newSearch, cmd ) =
                    Search.update searchMsg model.internal.search
            in
            ( { model | internal = Model newSearch model.internal.displayBookmarksMenu model.internal.bookmarks }, cmd )

        OnSelect streamName ->
            ( model
            , Cmd.batch
                [ toggleDialog searchModalId
                , goToStream model streamName
                ]
            )

        OnQueryChanged streamName ->
            ( model, searchStreams model streamName )

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

        RequestSearch _ ->
            ( model, toggleDialog searchModalId )

        ToggleBookmarksMenu ->
            ( { model | internal = Model model.internal.search (not model.internal.displayBookmarksMenu) model.internal.bookmarks }, Cmd.none )

        KeyPress key isMetaDown isCtrlDown ->
            case ( key, isMetaDown, isCtrlDown ) of
                ( "k", True, False ) ->
                    ( model, toggleDialog searchModalId )

                ( "k", False, True ) ->
                    ( model, toggleDialog searchModalId )

                _ ->
                    ( model, Cmd.none )

        ToggleDialog ->
            ( model, toggleDialog searchModalId )

        SearchedStreamsFetched (Ok streams) ->
            let
                streams_ =
                    List.map .streamId streams

                searchModel =
                    model.internal.search

                newModel =
                    { searchModel | streams = streams_ }
            in
            ( { model | internal = Model newModel model.internal.displayBookmarksMenu model.internal.bookmarks }, Cmd.none )

        SearchedStreamsFetched (Err _) ->
            let
                searchModel =
                    model.internal.search

                newModel =
                    { searchModel | streams = [] }
            in
            ( { model | internal = Model newModel model.internal.displayBookmarksMenu model.internal.bookmarks }, Cmd.none )


view : (Msg -> a) -> WrappedModel Model -> Html a -> Html a
view layoutMsgBuilder model pageView =
    div
        [ class "bg-gray-100 flex flex-col min-h-screen w-full text-gray-800 font-sans leading-relaxed antialiased" ]
        [ header []
            [ Html.map layoutMsgBuilder (browserNavigation model)
            ]
        , main_
            [ class "bg-white flex w-full grow px-4" ]
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
        [ class "flex bg-red-700 px-8 h-16 justify-between sticky" ]
        [ div
            [ class "flex items-center" ]
            [ a
                [ href (Url.toString model.flags.rootUrl)
                , class "text-gray-100 font-semibold"
                ]
                [ text "Ruby Event Store" ]
            ]
        , div
            [ class "flex items-center gap-2" ]
            [ fakeSearchInput, bookmarksMenu model ]
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
            , spacer
            , a
                [ href (Route.debugUrl flags.rootUrl)
                , class "ml-4"
                ]
                [ text "Debug" ]
            ]
        , div
            [ class "text-gray-500 text-sm flex item-center gap-2" ]
            [ text "Display times in timezone:"
            , timeZoneSelect time
            ]
        ]


timeZoneSelect time =
    Html.select
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


visibleBookmarksMenu : Bool -> String
visibleBookmarksMenu displayBookmarksMenu =
    if displayBookmarksMenu then
        "block"

    else
        "hidden"


bookmarkToHtml : Bookmark -> Html Msg
bookmarkToHtml bookmark =
    li []
        [ a [ href bookmark.link, class "whitespace-nowrap p-4 hover:bg-gray-100" ] [ text bookmark.label ]
        ]


bookmarksMenu : WrappedModel Model -> Html Msg
bookmarksMenu model =
    div [ class "relative" ]
        [ button
            [ onClick ToggleBookmarksMenu
            , class "text-red-100 outline-none text-sm flex gap-2 items-center bg-red-800 hover:bg-red-900 h-9 px-3 rounded"
            ]
            [ FeatherIcons.bookmark
                |> FeatherIcons.withClass "size-4"
                |> FeatherIcons.toHtml []
            ]
        , div [ class ("absolute translate-y-4 right-0 top-full bg-white shadow rounded-lg " ++ visibleBookmarksMenu model.internal.displayBookmarksMenu) ]
            [ model.internal.bookmarks
                |> List.map bookmarkToHtml
                |> ul [ class "text-gray-800 text-sm space-y-4" ]
            ]
        ]


fakeSearchInput : Html Msg
fakeSearchInput =
    button
        [ onClick ToggleDialog
        , class "text-red-100 outline-none text-sm flex gap-2 items-center bg-red-800 hover:bg-red-900 h-9 px-3 rounded"
        ]
        [ FeatherIcons.search
            |> FeatherIcons.withClass "size-4"
            |> FeatherIcons.toHtml []
        , text "Quick search…"
        , span [ class "text-xs" ] [ text "⌘K" ]
        ]


realSearchInput : WrappedModel Model -> Html Msg
realSearchInput model =
    Html.map SearchMsg (Search.view model.internal.search)


searchModalId =
    "search-modal"


searchModal : WrappedModel Model -> Html Msg
searchModal model =
    node "dialog"
        [ id searchModalId, class "backdrop:bg-gray-400/50 backdrop:backdrop-blur max-w-96 p-4 rounded-lg bg-white shadow w-full" ]
        [ button [ onClick ToggleDialog, class "inset-0 fixed z-0" ]
            [ text ""
            ]
        , div [ class "isolate" ]
            [ realSearchInput model
            ]
        ]
