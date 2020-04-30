module Flags exposing (Flags, RawFlags, buildFlags)

import Url


type alias RawFlags =
    { rootUrl : String
    , streamsUrl : String
    , eventsUrl : String
    , resVersion : String
    }


type alias Flags =
    { rootUrl : Url.Url
    , streamsUrl : Url.Url
    , eventsUrl : Url.Url
    , resVersion : String
    }


buildFlags : RawFlags -> Maybe Flags
buildFlags { rootUrl, streamsUrl, eventsUrl, resVersion } =
    Maybe.map4 Flags (Url.fromString rootUrl) (Url.fromString streamsUrl) (Url.fromString eventsUrl) (Just resVersion)
