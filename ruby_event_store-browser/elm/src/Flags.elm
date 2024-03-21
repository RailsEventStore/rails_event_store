module Flags exposing (Flags, RawFlags, buildFlags)

import Url


type alias RawFlags =
    { rootUrl : String
    , apiUrl : String
    , resVersion : String
    , repositoryAdapter : String
    , platform : String
    }


type alias Flags =
    { rootUrl : Url.Url
    , apiUrl : Url.Url
    , resVersion : String
    , repositoryAdapter : String
    , platform : String
    }


buildFlags : RawFlags -> Maybe Flags
buildFlags { rootUrl, apiUrl, resVersion, repositoryAdapter, platform } =
    Maybe.map5 Flags (Url.fromString rootUrl) (Url.fromString apiUrl) (Just resVersion) (Just repositoryAdapter) (Just platform)
