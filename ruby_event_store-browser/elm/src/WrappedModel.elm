module WrappedModel exposing (WrappedModel)

import Browser.Navigation
import Flags exposing (Flags)


type alias WrappedModel a =
    { internal : a
    , key : Browser.Navigation.Key
    , flags : Flags
    }
