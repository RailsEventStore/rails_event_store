module Layout exposing (view, viewNotFound)

import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, disabled, href, placeholder)
import Html.Events exposing (onClick)


view : Flags -> Html a -> Html a
view flags pageView =
    div [ class "frame" ]
        [ header [ class "frame__header" ] [ browserNavigation flags ]
        , main_ [ class "frame__body" ] [ pageView ]
        , footer [ class "frame__footer" ] [ browserFooter flags ]
        ]


viewNotFound : Html a
viewNotFound =
    h1 [] [ text "404" ]


browserNavigation : Flags -> Html a
browserNavigation flags =
    nav [ class "navigation" ]
        [ div [ class "navigation__brand" ]
            [ a [ href flags.rootUrl, class "navigation__logo" ] [ text "Ruby Event Store" ]
            ]
        , div [ class "navigation__links" ] []
        ]


browserFooter : Flags -> Html a
browserFooter flags =
    footer [ class "footer" ]
        [ div [ class "footer__links" ]
            [ text ("RubyEventStore v" ++ flags.resVersion)
            , a [ href "https://railseventstore.org/docs/install/", class "footer__link" ] [ text "Documentation" ]
            , a [ href "https://railseventstore.org/support/", class "footer__link" ] [ text "Support" ]
            ]
        ]
