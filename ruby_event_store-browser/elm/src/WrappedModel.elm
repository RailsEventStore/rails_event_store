module WrappedModel exposing (WrappedModel)

import Browser.Navigation
import BrowserTime
import Flags exposing (Flags)


type alias WrappedModel a =
    { internal : a
    , key : Browser.Navigation.Key
    , time :
        { selected : BrowserTime.TimeZone
        , detected : BrowserTime.TimeZone
        }
    , flags : Flags
    }
