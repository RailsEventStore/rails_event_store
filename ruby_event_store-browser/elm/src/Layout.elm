module Layout exposing (Model, Msg, buildModel, update, view, viewNotFound)

import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Route


type Msg
    = GoToStream
    | GoToStreamChanged String


type alias Model =
    { goToStream : String
    }


buildModel : Model
buildModel =
    { goToStream = ""
    }


update : Msg -> Model -> Browser.Navigation.Key -> ( Model, Cmd Msg )
update msg model key =
    case msg of
        GoToStream ->
            ( { goToStream = "" }, Browser.Navigation.pushUrl key (Route.buildUrl "#streams" model.goToStream) )

        GoToStreamChanged newValue ->
            ( { goToStream = newValue }, Cmd.none )


view : (Msg -> a) -> Model -> Flags -> Html a -> Html a
view layoutMsgBuilder model flags pageView =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ Html.map layoutMsgBuilder (browserNavigation model flags) ]
        , main_ [ class "frame__body" ] [ pageView ]
        , footer [ class "frame__footer" ] [ Html.map layoutMsgBuilder (browserFooter flags) ]
        ]


viewNotFound : Html a
viewNotFound =
    h1 [] [ text "404" ]


browserNavigation : Model -> Flags -> Html Msg
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


browserFooter : Flags -> Html Msg
browserFooter flags =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text ("RubyEventStore v" ++ flags.resVersion)
            , a [ href "https://railseventstore.org/docs/install/", class "footer__link" ] [ text "Documentation" ]
            , a [ href "https://railseventstore.org/support/", class "footer__link" ] [ text "Support" ]
            ]
        ]
