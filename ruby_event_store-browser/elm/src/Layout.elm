module Layout exposing (Model, buildModel, update, view, viewNotFound)

import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Msg exposing (LayoutMsg(..), Msg)
import Route


type alias Model =
    { goToStream : String
    }


buildModel : Model
buildModel =
    { goToStream = ""
    }


update : LayoutMsg -> Model -> Browser.Navigation.Key -> ( Model, Cmd LayoutMsg )
update msg model key =
    case msg of
        GoToStream ->
            ( { goToStream = "" }, Browser.Navigation.pushUrl key (Route.buildUrl "#streams" model.goToStream) )

        GoToStreamChanged newValue ->
            ( { goToStream = newValue }, Cmd.none )


view : (LayoutMsg -> Msg) -> Model -> Flags -> Html Msg -> Html Msg
view layoutMsgBuilder model flags pageView =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ Html.map layoutMsgBuilder (browserNavigation model flags) ]
        , main_ [ class "frame__body" ] [ pageView ]
        , footer [ class "frame__footer" ] [ Html.map layoutMsgBuilder (browserFooter flags) ]
        ]


viewNotFound : Html Msg
viewNotFound =
    h1 [] [ text "404" ]


browserNavigation : Model -> Flags -> Html LayoutMsg
browserNavigation model flags =
    nav [ class "navigation" ]
        [ div [ class "navigation__brand" ]
            [ a [ href flags.rootUrl, class "navigation__logo" ] [ text "Ruby Event Store" ]
            ]
        , div [ class "navigation__links" ] []
        , div [ class "navigation__go-to-stream" ]
            [ form [ onSubmit GoToStream ]
                [ input [ value model.goToStream, onInput GoToStreamChanged, placeholder "Go to stream..." ] []
                ]
            ]
        ]


browserFooter : Flags -> Html LayoutMsg
browserFooter flags =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text ("RubyEventStore v" ++ flags.resVersion)
            , a [ href "https://railseventstore.org/docs/install/", class "footer__link" ] [ text "Documentation" ]
            , a [ href "https://railseventstore.org/support/", class "footer__link" ] [ text "Support" ]
            ]
        ]
