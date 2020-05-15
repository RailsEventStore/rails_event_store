module Flags exposing (Flags, RawFlags, buildFlags)

import Url


type alias RawFlags =
    { rootUrl : String
    , apiUrl : String
    , streamsUrl : String
    , eventsUrl : String
    , resVersion : String
    }


type alias Flags =
    { rootUrl : Url.Url
    , apiUrl : Url.Url
    , streamsUrl : Url.Url
    , eventsUrl : Url.Url
    , resVersion : String
    }


buildFlags : RawFlags -> Maybe Flags
buildFlags { rootUrl, apiUrl, streamsUrl, eventsUrl, resVersion } =
    Maybe.map5 Flags (Url.fromString rootUrl) (Url.fromString apiUrl) (Url.fromString streamsUrl) (Url.fromString eventsUrl) (Just resVersion)
