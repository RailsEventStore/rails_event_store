module TimeHelpers exposing (Model, formatTimestamp)

import DateFormat exposing (..)
import Time


type alias Model =
    { zone : Time.Zone, zoneName : String }


formatTimestamp : Time.Posix -> Time.Zone -> String -> String
formatTimestamp time zone zoneName =
    format
        [ dayOfMonthFixed
        , text "."
        , monthFixed
        , text "."
        , yearNumber
        , text ", "
        , hourMilitaryFixed
        , text ":"
        , minuteFixed
        , text ":"
        , secondFixed
        , text "."
        , millisecondFixed
        , text " "
        , text zoneName
        ]
        zone
        time
