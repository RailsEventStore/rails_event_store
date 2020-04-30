module Main exposing (main)

import Browser
import Browser.Navigation
import Flags exposing (Flags, RawFlags, buildFlags)
import Html exposing (Html)
import Layout
import Maybe exposing (andThen)
import Page.ShowEvent
import Page.ViewStream
import Route
import Url
import Url.Parser exposing ((</>))
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
    }


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotLayoutMsg Layout.Msg
    | GotShowEventMsg Page.ShowEvent.Msg
    | GotViewStreamMsg Page.ViewStream.Msg


type Page
    = NotFound
    | ShowEvent Page.ShowEvent.Model
    | ViewStream Page.ViewStream.Model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


buildModel : RawFlags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
buildModel rawFlags location key =
    let
        initModel =
            { page = NotFound
            , flags = buildFlags rawFlags
            , key = key
            , layout = Layout.buildModel
            }
    in
    urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ChangeUrl location, _ ) ->
            urlUpdate model location

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

        ( GotViewStreamMsg viewStreamUIMsg, ViewStream viewStreamModel ) ->
            Page.ViewStream.update viewStreamUIMsg viewStreamModel
                |> updateWith ViewStream GotViewStreamMsg model

        ( GotShowEventMsg openedEventUIMsg, ShowEvent showEventModel ) ->
            Page.ShowEvent.update openedEventUIMsg showEventModel
                |> updateWith ShowEvent GotShowEventMsg model

        ( GotLayoutMsg layoutMsg, _ ) ->
            case model.flags of
                Nothing ->
                    ( model, Cmd.none )

                Just flags ->
                    let
                        ( layoutModel, layoutCmd ) =
                            Layout.update layoutMsg (wrapModel model model.layout flags)
                    in
                    ( { model | layout = layoutModel }, Cmd.map GotLayoutMsg layoutCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


updateWith : (subModel -> Page) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toPageModel toMsg model ( subModel, subCmd ) =
    ( { model | page = toPageModel subModel }
    , Cmd.map toMsg subCmd
    )


urlUpdate : Model -> Url.Url -> ( Model, Cmd Msg )
urlUpdate model location =
    case model.flags of
        Nothing ->
            ( model, Cmd.none )

        Just flags ->
            case Route.decodeLocation (Url.toString flags.rootUrl) location of
                Just (Route.BrowseEvents encodedStreamId) ->
                    case Url.percentDecode encodedStreamId of
                        Just streamId ->
                            ( { model | page = ViewStream (Page.ViewStream.initModel flags streamId) }
                            , Cmd.map GotViewStreamMsg (Page.ViewStream.initCmd flags streamId)
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

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.flags of
        Nothing ->
            { title = fullTitle Nothing
            , body = [ Layout.viewIncorrectConfig ]
            }

        Just flags ->
            let
                ( maybePageTitle, pageContent ) =
                    viewPage model.page
            in
            { body = [ Layout.view GotLayoutMsg (wrapModel model model.layout flags) pageContent ]
            , title = fullTitle maybePageTitle
            }


fullTitle : Maybe String -> String
fullTitle maybePageTitle =
    case maybePageTitle of
        Just pageTitle ->
            "RubyEventStore::Browser - " ++ pageTitle

        Nothing ->
            "RubyEventStore::Browser"


viewPage : Page -> ( Maybe String, Html Msg )
viewPage page =
    case page of
        ViewStream viewStreamUIModel ->
            viewOnePage GotViewStreamMsg Page.ViewStream.view viewStreamUIModel

        ShowEvent openedEventUIModel ->
            viewOnePage GotShowEventMsg Page.ShowEvent.view openedEventUIModel

        NotFound ->
            ( Nothing, Layout.viewNotFound )


viewOnePage : (pageMsg -> Msg) -> (model -> ( String, Html pageMsg )) -> model -> ( Maybe String, Html Msg )
viewOnePage pageMsgBuilder pageViewFunction pageModel =
    let
        ( pageTitle, pageContent ) =
            pageViewFunction pageModel
    in
    ( Just pageTitle, Html.map pageMsgBuilder pageContent )


wrapModel : Model -> a -> Flags -> WrappedModel a
wrapModel globalModel internalModel flags =
    { internal = internalModel
    , key = globalModel.key
    , flags = flags
    }
