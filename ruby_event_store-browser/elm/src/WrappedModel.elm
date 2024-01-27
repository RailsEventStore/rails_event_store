module WrappedModel exposing (WrappedModel)

import Browser.Navigation
import Flags exposing (Flags)
import Time


type alias WrappedModel a =
    { internal : a
    , key : Browser.Navigation.Key
    , flags : Flags
    }
