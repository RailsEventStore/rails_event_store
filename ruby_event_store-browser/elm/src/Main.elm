module Main exposing (Model, Msg(..), buildModel, buildUrl, main, subscriptions, update, urlUpdate, view)

import Browser
import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (Html)
import Layout
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
    { page : Page
    , flags : Flags
    , key : Browser.Navigation.Key
    }


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | OpenedEventUIChanged OpenedEventUI.Msg
    | ViewStreamUIChanged ViewStreamUI.Msg


type Page
    = NotFound
    | ShowEvent OpenedEventUI.Model
    | ViewStream ViewStreamUI.Model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


buildModel : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
buildModel flags location key =
    let
        initModel =
            { page = NotFound
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
            case model.page of
                ViewStream viewStreamModel ->
                    let
                        ( newViewStreamModel, cmd ) =
                            ViewStreamUI.update viewStreamUIMsg viewStreamModel
                    in
                    ( { model | page = ViewStream newViewStreamModel }, Cmd.map ViewStreamUIChanged cmd )

                _ ->
                    ( model, Cmd.none )

        OpenedEventUIChanged openedEventUIMsg ->
            case model.page of
                ShowEvent showEventModel ->
                    let
                        ( newShowEventModel, cmd ) =
                            OpenedEventUI.update openedEventUIMsg showEventModel
                    in
                    ( { model | page = ShowEvent newShowEventModel }, Cmd.map OpenedEventUIChanged cmd )

                _ ->
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
                    ( { model | page = ViewStream (ViewStreamUI.initModel streamId) }
                    , Cmd.map ViewStreamUIChanged (ViewStreamUI.initCmd model.flags streamId)
                    )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )

        Just (Route.ShowEvent encodedEventId) ->
            case Url.percentDecode encodedEventId of
                Just eventId ->
                    ( { model | page = ShowEvent (OpenedEventUI.initModel eventId) }
                    , Cmd.map OpenedEventUIChanged (OpenedEventUI.initCmd model.flags eventId)
                    )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { body = [ Layout.view model.flags (viewPage model.page) ]
    , title = "RubyEventStore::Browser"
    }


viewPage : Page -> Html Msg
viewPage page =
    case page of
        ViewStream viewStreamUIModel ->
            Html.map ViewStreamUIChanged (ViewStreamUI.view viewStreamUIModel)

        ShowEvent openedEventUIModel ->
            Html.map OpenedEventUIChanged (OpenedEventUI.view openedEventUIModel)

        NotFound ->
            Layout.viewNotFound
