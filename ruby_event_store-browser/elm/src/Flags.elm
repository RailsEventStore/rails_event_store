module Flags exposing (Flags, RawFlags, buildFlags)

import Url


type alias RawFlags =
    { rootUrl : String
    , apiUrl : String
    , resVersion : String
    , platform : String
    }


type alias Flags =
    { rootUrl : Url.Url
    , apiUrl : Url.Url
    , resVersion : String
    , platform : String
    }


buildFlags : RawFlags -> Maybe Flags
buildFlags { rootUrl, apiUrl, resVersion, platform } =
    Maybe.map4 Flags (Url.fromString rootUrl) (Url.fromString apiUrl) (Just resVersion) (Just platform)
