module Layout exposing (Model, Msg, buildModel, update, view, viewIncorrectConfig, viewNotFound)

import Browser.Navigation
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
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
    div
        [ class "bg-gray-100 min-h-screen w-full text-gray-800 font-sans leading-relaxed antialiased" ]
        [ header []
            [ Html.map layoutMsgBuilder (browserNavigation model)
            ]
        , main_
            [ class "bg-white" ]
            [ pageView ]
        , footer []
            [ Html.map layoutMsgBuilder (browserFooter model.flags)
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
        [ class "flex bg-red-700 px-8 h-16" ]
        [ div
            [ class "flex items-center" ]
            [ a
                [ href (Url.toString model.flags.rootUrl)
                , class "text-gray-100 font-semibold"
                ]
                [ text "Ruby Event Store" ]
            ]
        , div
            [ class "flex-1" ]
            []
        , div
            [ class "flex items-center" ]
            [ form [ onSubmit GoToStream ]
                [ input
                    [ class "rounded px-4 py-2"
                    , value model.internal.goToStream
                    , onInput GoToStreamChanged
                    , placeholder "Go to stream..."
                    ]
                    []
                ]
            ]
        ]


browserFooter : Flags -> Html Msg
browserFooter flags =
    footer
        [ class "border-gray-400 border-t py-4" ]
        [ div
            [ class "flex justify-center text-gray-500 text-sm" ]
            [ text ("RubyEventStore v" ++ flags.resVersion)
            , span
                [ class "font-bold text-gray-400 inline-block ml-4" ]
                [ text "•" ]
            , a
                [ href "https://railseventstore.org/docs/install/"
                , class "text-gray-500 ml-4"
                ]
                [ text "Documentation" ]
            , span
                [ class "font-bold text-gray-400 inline-block ml-4" ]
                [ text "•" ]
            , a
                [ href "https://railseventstore.org/support/"
                , class "text-gray-800 ml-4"
                ]
                [ text "Support" ]
            ]
        ]
