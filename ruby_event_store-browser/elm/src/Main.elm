module Main exposing (main)

import Browser
import Browser.Navigation
import BrowserTime
import Dict
import Flags exposing (Flags, RawFlags, buildFlags)
import Html exposing (..)
import Layout
import LinkedTimezones exposing (mapLinkedTimeZone)
import Page.ShowEvent
import Page.ShowEventTypes
import Page.ShowStream
import Route
import Task
import Time
import TimeZone
import Url
import WrappedModel exposing (..)


main : Program RawFlags Model Msg
main =
    Browser.application
        { init = buildModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangeUrl
        , onUrlRequest = ClickedLink
        }


type alias Model =
    { page : Page
    , flags : Maybe Flags
    , key : Browser.Navigation.Key
    , layout : Layout.Model
    , time :
        { detected : BrowserTime.TimeZone
        , selected : BrowserTime.TimeZone
        }
    }


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotLayoutMsg Layout.Msg
    | GotShowEventMsg Page.ShowEvent.Msg
    | GotShowEventTypesMsg Page.ShowEventTypes.Msg
    | GotShowStreamMsg Page.ShowStream.Msg
    | ReceiveTimeZone (Result String Time.ZoneName)


type Page
    = NotFound
    | ShowEvent Page.ShowEvent.Model
    | ShowEventTypes Page.ShowEventTypes.Model
    | ShowStream Page.ShowStream.Model


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.map GotLayoutMsg Layout.subscriptions


buildModel : RawFlags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
buildModel rawFlags location key =
    let
        initModel =
            { page = NotFound
            , flags = buildFlags rawFlags
            , key = key
            , layout = Layout.buildModel
            , time =
                { detected = BrowserTime.defaultTimeZone
                , selected = BrowserTime.defaultTimeZone
                }
            }

        ( model, cmd ) =
            navigate initModel location
    in
    ( model
    , Cmd.batch
        [ cmd
        , requestBrowserTimeZone
        ]
    )


requestBrowserTimeZone : Cmd Msg
requestBrowserTimeZone =
    Task.attempt ReceiveTimeZone Time.getZoneName


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ChangeUrl location, _ ) ->
            navigate model location

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Browser.Navigation.load url
                    )

        ( GotShowStreamMsg showStreamUIMsg, ShowStream showStreamModel ) ->
            let
                ( subModel, subCmd ) =
                    Page.ShowStream.update showStreamUIMsg showStreamModel
            in
            ( { model | page = ShowStream subModel }
            , Cmd.map GotShowStreamMsg subCmd
            )

        ( GotShowEventMsg openedEventUIMsg, ShowEvent showEventModel ) ->
            let
                ( subModel, subCmd ) =
                    Page.ShowEvent.update openedEventUIMsg showEventModel
            in
            ( { model | page = ShowEvent subModel }
            , Cmd.map GotShowEventMsg subCmd
            )

        ( GotShowEventTypesMsg showEventTypesUIMsg, ShowEventTypes showEventTypesModel ) ->
            let
                ( subModel, subCmd ) =
                    Page.ShowEventTypes.update showEventTypesUIMsg showEventTypesModel
            in
            ( { model | page = ShowEventTypes subModel }
            , Cmd.map GotShowEventTypesMsg subCmd
            )

        ( GotLayoutMsg layoutMsg, _ ) ->
            case model.flags of
                Nothing ->
                    ( model, Cmd.none )

                Just flags ->
                    let
                        ( wrappedModel, layoutCmd ) =
                            Layout.update layoutMsg (WrappedModel model.layout model.key model.time flags)

                        time =
                            model.time

                        newTime =
                            { time | selected = wrappedModel.time.selected }
                    in
                    ( { model | layout = wrappedModel.internal, time = newTime }
                    , Cmd.map GotLayoutMsg layoutCmd
                    )

        ( ReceiveTimeZone result, _ ) ->
            case result of
                Ok zoneName ->
                    case zoneName of
                        Time.Name newZoneName ->
                            let
                                betterZoneName =
                                    mapLinkedTimeZone newZoneName
                            in
                            case Dict.get betterZoneName TimeZone.zones of
                                Just zone ->
                                    let
                                        time =
                                            model.time

                                        detectedTime =
                                            { zone = zone (), zoneName = newZoneName }

                                        newTime =
                                            { time | detected = detectedTime, selected = detectedTime }
                                    in
                                    ( { model | time = newTime }, Cmd.none )

                                Nothing ->
                                    ( model, Cmd.none )

                        Time.Offset _ ->
                            ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


navigate : Model -> Url.Url -> ( Model, Cmd Msg )
navigate model location =
    case model.flags of
        Nothing ->
            ( model, Cmd.none )

        Just flags ->
            case Route.decodeLocation flags.rootUrl location of
                Just (Route.BrowseEvents encodedStreamId paginationSpecification) ->
                    case Url.percentDecode encodedStreamId of
                        Just streamId ->
                            ( { model | page = ShowStream (Page.ShowStream.initModel flags streamId paginationSpecification) }
                            , Cmd.map GotShowStreamMsg (Page.ShowStream.initCmd flags streamId)
                            )

                        Nothing ->
                            ( { model | page = NotFound }, Cmd.none )

                Just (Route.ShowEvent encodedEventId) ->
                    case Url.percentDecode encodedEventId of
                        Just eventId ->
                            ( { model | page = ShowEvent (Page.ShowEvent.initModel flags eventId) }
                            , Cmd.map GotShowEventMsg (Page.ShowEvent.initCmd flags eventId)
                            )

                        Nothing ->
                            ( { model | page = NotFound }, Cmd.none )

                Just Route.ShowEventTypes ->
                    ( { model | page = ShowEventTypes (Page.ShowEventTypes.initModel flags) }
                    , Cmd.map GotShowEventTypesMsg (Page.ShowEventTypes.initCmd flags)
                    )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.flags of
        Nothing ->
            { title = fullTitle Nothing
            , body = [ div [] [ Layout.viewIncorrectConfig ] ]
            }

        Just flags ->
            let
                ( title, content ) =
                    viewPage model.page model.time.selected

                wrappedModel =
                    WrappedModel model.layout model.key model.time flags
            in
            { title = fullTitle title
            , body = [ div [] [ Layout.view GotLayoutMsg wrappedModel content ] ]
            }


fullTitle : Maybe String -> String
fullTitle maybePageTitle =
    case maybePageTitle of
        Just pageTitle ->
            "RubyEventStore::Browser - " ++ pageTitle

        Nothing ->
            "RubyEventStore::Browser"


viewPage : Page -> BrowserTime.TimeZone -> ( Maybe String, Html Msg )
viewPage page selectedTime =
    case page of
        ShowStream pageModel ->
            let
                ( title, content ) =
                    Page.ShowStream.view pageModel selectedTime
            in
            ( Just title, Html.map GotShowStreamMsg content )

        ShowEvent pageModel ->
            let
                ( title, content ) =
                    Page.ShowEvent.view pageModel selectedTime
            in
            ( Just title, Html.map GotShowEventMsg content )

        ShowEventTypes pageModel ->
            let
                ( title, content ) =
                    Page.ShowEventTypes.view pageModel selectedTime
            in
            ( Just title, Html.map GotShowEventTypesMsg content )

        NotFound ->
            ( Nothing, Layout.viewNotFound )
