module Layout exposing (Model, Msg, buildModel, update, view, viewIncorrectConfig, viewNotFound)

import Browser.Navigation
import Flags exposing (Flags)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, href, placeholder, value)
import Html.Styled.Events exposing (onInput, onSubmit)
import Route
import Tailwind.Utilities as Tw
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
        [ css
            [ Tw.bg_gray_100
            , Tw.min_h_screen
            , Tw.w_full
            , Tw.text_gray_800
            , Tw.font_sans
            , Tw.leading_relaxed
            , Tw.antialiased
            ]
        ]
        [ header []
            [ Html.Styled.map layoutMsgBuilder (browserNavigation model)
            ]
        , main_
            [ css
                [ Tw.bg_white
                ]
            ]
            [ pageView ]
        , footer []
            [ Html.Styled.map layoutMsgBuilder (browserFooter model.flags)
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
        [ css
            [ Tw.flex
            , Tw.bg_red_700
            , Tw.px_8
            , Tw.h_16
            ]
        ]
        [ div
            [ css
                [ Tw.flex
                , Tw.items_center
                ]
            ]
            [ a
                [ href (Url.toString model.flags.rootUrl)
                , css
                    [ Tw.text_gray_100
                    , Tw.font_semibold
                    ]
                ]
                [ text "Ruby Event Store" ]
            ]
        , div
            [ css [ Tw.flex_1 ]
            ]
            []
        , div
            [ css
                [ Tw.flex
                , Tw.items_center
                ]
            ]
            [ form [ onSubmit GoToStream ]
                [ input
                    [ css
                        [ Tw.rounded
                        , Tw.px_4
                        , Tw.py_2
                        ]
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
        [ css
            [ Tw.border_gray_400
            , Tw.border_t
            , Tw.py_4
            ]
        ]
        [ div
            [ css
                [ Tw.flex
                , Tw.justify_center
                , Tw.text_gray_500
                , Tw.text_sm
                ]
            ]
            [ text ("RubyEventStore v" ++ flags.resVersion)
            , span
                [ css
                    [ Tw.font_bold
                    , Tw.text_gray_400
                    , Tw.inline_block
                    , Tw.ml_4
                    ]
                ]
                [ text "•" ]
            , a
                [ href "https://railseventstore.org/docs/install/"
                , css
                    [ Tw.text_gray_500
                    , Tw.ml_4
                    ]
                ]
                [ text "Documentation" ]
            , span
                [ css
                    [ Tw.font_bold
                    , Tw.text_gray_400
                    , Tw.inline_block
                    , Tw.ml_4
                    ]
                ]
                [ text "•" ]
            , a
                [ href "https://railseventstore.org/support/"
                , css
                    [ Tw.text_gray_500
                    , Tw.ml_4
                    ]
                ]
                [ text "Support" ]
            ]
        ]
