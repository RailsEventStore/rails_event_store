module Msg exposing (LayoutMsg(..), Msg(..))

import Browser
import Page.ShowEvent
import Page.ViewStream
import Url


type LayoutMsg
    = GoToStream
    | GoToStreamChanged String


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotLayoutMsg LayoutMsg
    | GotShowEventMsg Page.ShowEvent.Msg
    | GotViewStreamMsg Page.ViewStream.Msg
