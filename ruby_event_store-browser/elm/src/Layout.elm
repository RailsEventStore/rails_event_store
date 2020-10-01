module Layout exposing (Model, Msg, buildModel, update, view, viewIncorrectConfig, viewNotFound)

import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Route
import Url
import WrappedModel exposing (..)


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


update : Msg -> WrappedModel Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoToStream ->
            ( { goToStream = "" }, Browser.Navigation.pushUrl model.key (Route.streamUrl model.flags.rootUrl model.internal.goToStream) )

        GoToStreamChanged newValue ->
            ( { goToStream = newValue }, Cmd.none )


view : (Msg -> a) -> WrappedModel Model -> Html a -> Html a
view layoutMsgBuilder model pageView =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ Html.map layoutMsgBuilder (browserNavigation model) ]
        , main_ [ class "frame__body" ] [ pageView ]
        , footer [ class "frame__footer" ] [ Html.map layoutMsgBuilder (browserFooter model.flags) ]
        ]


viewNotFound : Html a
viewNotFound =
    h1 [] [ text "404" ]


viewIncorrectConfig : Html a
viewIncorrectConfig =
    h1 [] [ text "Incorrect RES Browser config" ]


browserNavigation : WrappedModel Model -> Html Msg
browserNavigation model =
    nav [ class "navigation" ]
        [ div [ class "navigation__brand" ]
            [ a [ href (Url.toString model.flags.rootUrl), class "navigation__logo" ] [ text "Ruby Event Store" ]
            ]
        , div [ class "navigation__links" ] []
        , div [ class "navigation__go-to-stream" ]
            [ form [ onSubmit GoToStream ]
                [ input [ value model.internal.goToStream, onInput GoToStreamChanged, placeholder "Go to stream..." ] []
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
