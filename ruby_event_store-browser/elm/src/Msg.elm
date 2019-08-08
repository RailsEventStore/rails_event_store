module Msg exposing (Msg(..))

import Browser
import Page.ShowEvent
import Page.ViewStream
import Url


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotShowEventMsg Page.ShowEvent.Msg
    | GotViewStreamMsg Page.ViewStream.Msg
