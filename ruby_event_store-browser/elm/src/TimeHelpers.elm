module TimeHelpers exposing (formatTimestamp)

import DateFormat exposing (..)
import Time


formatTimestamp : Time.Posix -> String
formatTimestamp time =
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
        Time.utc
        time
