module Layout exposing (Model, buildModel, view, viewNotFound)

import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Html.Events exposing (onClick, onInput, onSubmit)
import Msg exposing (Msg)


type alias Model =
    { goToStream : String
    }


buildModel : Model
buildModel =
    { goToStream = ""
    }


view : Model -> Flags -> Html Msg -> Html Msg
view model flags pageView =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ browserNavigation model flags ]
        , main_ [ class "frame__body" ] [ pageView ]
        , footer [ class "frame__footer" ] [ browserFooter flags ]
        ]


viewNotFound : Html Msg
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
            [ form [ onSubmit Msg.GoToStream ]
                [ input [ onInput Msg.GoToStreamChanged, placeholder "Go to stream..." ] []
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
