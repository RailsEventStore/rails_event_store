module Flags exposing (Flags, RawFlags, buildFlags)

import Url


type alias RawFlags =
    { rootUrl : String
    , apiUrl : String
    , resVersion : String
    }


type alias Flags =
    { rootUrl : Url.Url
    , apiUrl : Url.Url
    , resVersion : String
    }


buildFlags : RawFlags -> Maybe Flags
buildFlags { rootUrl, apiUrl, resVersion } =
    Maybe.map3 Flags (Url.fromString rootUrl) (Url.fromString apiUrl) (Just resVersion)
