module Msg exposing (Msg(..))

import Browser
import Page.ShowEvent
import Page.ViewStream
import Url


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GoToStream
    | GoToStreamChanged String
    | GotShowEventMsg Page.ShowEvent.Msg
    | GotViewStreamMsg Page.ViewStream.Msg
