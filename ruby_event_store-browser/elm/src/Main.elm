module Main exposing (main)

import Browser
import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (Html)
import Layout
import Msg exposing (Msg(..))
import Page.ShowEvent
import Page.ViewStream
import Route
import Url
import Url.Parser exposing ((</>))


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
    , goToStream : String
    }


type Page
    = NotFound
    | ShowEvent Page.ShowEvent.Model
    | ViewStream Page.ViewStream.Model


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
            , goToStream = ""
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

        ( GoToStreamChanged newValue, _ ) ->
            ( { model | goToStream = newValue }, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


updateWith : (subModel -> Page) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toPageModel toMsg model ( subModel, subCmd ) =
    ( { model | page = toPageModel subModel }
    , Cmd.map toMsg subCmd
    )


urlUpdate : Model -> Url.Url -> ( Model, Cmd Msg )
urlUpdate model location =
    case Route.decodeLocation location of
        Just (Route.BrowseEvents encodedStreamId) ->
            case Url.percentDecode encodedStreamId of
                Just streamId ->
                    ( { model | page = ViewStream (Page.ViewStream.initModel streamId) }
                    , Cmd.map GotViewStreamMsg (Page.ViewStream.initCmd model.flags streamId)
                    )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )

        Just (Route.ShowEvent encodedEventId) ->
            case Url.percentDecode encodedEventId of
                Just eventId ->
                    ( { model | page = ShowEvent (Page.ShowEvent.initModel model.flags eventId) }
                    , Cmd.map GotShowEventMsg (Page.ShowEvent.initCmd model.flags eventId)
                    )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        ( maybePageTitle, pageContent ) =
            viewPage model.page
    in
    { body = [ Layout.view model.flags pageContent ]
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
