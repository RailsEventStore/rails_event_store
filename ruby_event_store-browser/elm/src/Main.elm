module Main exposing (Model, Msg(..), buildModel, main, subscriptions, update, urlUpdate, view)

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
    | GotShowEventMsg OpenedEventUI.Msg
    | GotViewStreamMsg ViewStreamUI.Msg


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
            ViewStreamUI.update viewStreamUIMsg viewStreamModel
                |> updateWith ViewStream GotViewStreamMsg model

        ( GotShowEventMsg openedEventUIMsg, ShowEvent showEventModel ) ->
            OpenedEventUI.update openedEventUIMsg showEventModel
                |> updateWith ShowEvent GotShowEventMsg model

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
                    ( { model | page = ViewStream (ViewStreamUI.initModel streamId) }
                    , Cmd.map GotViewStreamMsg (ViewStreamUI.initCmd model.flags streamId)
                    )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )

        Just (Route.ShowEvent encodedEventId) ->
            case Url.percentDecode encodedEventId of
                Just eventId ->
                    ( { model | page = ShowEvent (OpenedEventUI.initModel eventId) }
                    , Cmd.map GotShowEventMsg (OpenedEventUI.initCmd model.flags eventId)
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
            Html.map GotViewStreamMsg (ViewStreamUI.view viewStreamUIModel)

        ShowEvent openedEventUIModel ->
            Html.map GotShowEventMsg (OpenedEventUI.view openedEventUIModel)

        NotFound ->
            Layout.viewNotFound
