module TimeHelpers exposing (formatTimestamp)

import DateFormat exposing (..)
import Time


formatTimestamp : Time.Posix -> Time.Zone -> String
formatTimestamp time zone =
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
        ]
        zone
        time
