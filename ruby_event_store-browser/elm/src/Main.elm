module Main exposing (Model, Msg(..), browserBody, browserFooter, browserNavigation, buildModel, buildUrl, main, showEvent, subscriptions, update, urlUpdate, view)

import Browser
import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, Value, at, field, list, maybe, oneOf, string, succeed, value)
import Json.Decode.Pipeline exposing (optional, required, requiredAt)
import Json.Encode exposing (encode)
import OpenedEventUI
import Route
import Url
import Url.Parser exposing ((</>))
import ViewStreamUI


main : Program Flags Model Msg
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
    { events : ViewStreamUI.Model
    , event : Maybe OpenedEventUI.Model
    , page : Route.Route
    , flags : Flags
    , key : Browser.Navigation.Key
    }


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | OpenedEventUIChanged OpenedEventUI.Msg
    | ViewStreamUIChanged ViewStreamUI.Msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


buildModel : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
buildModel flags location key =
    let
        initLinks =
            { prev = Nothing
            , next = Nothing
            , first = Nothing
            , last = Nothing
            }

        initModel =
            { events = { streamName = "none", events = ViewStreamUI.PaginatedList [] initLinks }
            , page = Route.NotFound
            , event = Nothing
            , flags = flags
            , key = key
            }
    in
    urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeUrl location ->
            urlUpdate model location

        ClickedLink urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Browser.Navigation.load url
                    )

        ViewStreamUIChanged viewStreamUIMsg ->
            let
                ( newModel, cmd ) =
                    ViewStreamUI.update viewStreamUIMsg model.events
            in
            ( { model | events = newModel }, Cmd.map ViewStreamUIChanged cmd )

        OpenedEventUIChanged openedEventUIMsg ->
            case model.event of
                Just openedEvent ->
                    let
                        ( newModel, cmd ) =
                            OpenedEventUI.update openedEventUIMsg openedEvent
                    in
                    ( { model | event = Just newModel }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


buildUrl : String -> String -> String
buildUrl baseUrl id =
    baseUrl ++ "/" ++ Url.percentEncode id


urlUpdate : Model -> Url.Url -> ( Model, Cmd Msg )
urlUpdate model location =
    case Route.decodeLocation location of
        Just (Route.BrowseEvents encodedStreamId) ->
            case Url.percentDecode encodedStreamId of
                Just streamId ->
                    ( { model | page = Route.BrowseEvents streamId, events = { events = model.events.events, streamName = streamId } }, Cmd.map ViewStreamUIChanged (ViewStreamUI.initCmd model.flags streamId) )

                Nothing ->
                    ( { model | page = Route.NotFound }, Cmd.none )

        Just (Route.ShowEvent encodedEventId) ->
            case Url.percentDecode encodedEventId of
                Just eventId ->
                    ( { model | page = Route.ShowEvent eventId, event = Just (OpenedEventUI.initModel eventId) }
                    , Cmd.map OpenedEventUIChanged (OpenedEventUI.initCmd model.flags eventId)
                    )

                Nothing ->
                    ( { model | page = Route.NotFound }, Cmd.none )

        Just page ->
            ( { model | page = page }, Cmd.none )

        Nothing ->
            ( { model | page = Route.NotFound }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        body =
            div [ class "frame" ]
                [ header [ class "frame__header" ] [ browserNavigation model ]
                , main_ [ class "frame__body" ] [ browserBody model ]
                , footer [ class "frame__footer" ] [ browserFooter model ]
                ]
    in
    { body = [ body ]
    , title = "RubyEventStore::Browser"
    }


browserNavigation : Model -> Html Msg
browserNavigation model =
    nav [ class "navigation" ]
        [ div [ class "navigation__brand" ]
            [ a [ href model.flags.rootUrl, class "navigation__logo" ] [ text "Ruby Event Store" ]
            ]
        , div [ class "navigation__links" ]
            [ a [ href model.flags.rootUrl, class "navigation__link" ] [ text "Stream Browser" ]
            ]
        ]


browserFooter : Model -> Html Msg
browserFooter model =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text ("RubyEventStore v" ++ model.flags.resVersion)
            , a [ href "https://railseventstore.org/docs/install/", class "footer__link" ] [ text "Documentation" ]
            , a [ href "https://railseventstore.org/support/", class "footer__link" ] [ text "Support" ]
            ]
        ]


browserBody : Model -> Html Msg
browserBody model =
    case model.page of
        Route.BrowseEvents streamName ->
            Html.map (\msg -> ViewStreamUIChanged msg) (ViewStreamUI.view model.events)

        Route.ShowEvent eventId ->
            showEvent model.event

        Route.NotFound ->
            h1 [] [ text "404" ]


showEvent : Maybe OpenedEventUI.Model -> Html Msg
showEvent maybeEvent =
    case maybeEvent of
        Just event ->
            Html.map (\msg -> OpenedEventUIChanged msg) (OpenedEventUI.showEvent event)

        Nothing ->
            div [ class "event" ]
                [ text "There's no event of given ID" ]
