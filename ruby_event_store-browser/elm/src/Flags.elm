module Flags exposing (Flags, RawFlags, buildFlags)

import Url


type alias RawFlags =
    { rootUrl : String
    , apiUrl : String
    , resVersion : String
    , repositoryAdapter : String
    }


type alias Flags =
    { rootUrl : Url.Url
    , apiUrl : Url.Url
    , resVersion : String
    , repositoryAdapter : String
    }


buildFlags : RawFlags -> Maybe Flags
buildFlags { rootUrl, apiUrl, resVersion, repositoryAdapter } =
    Maybe.map4 Flags (Url.fromString rootUrl) (Url.fromString apiUrl) (Just resVersion) (Just repositoryAdapter)
