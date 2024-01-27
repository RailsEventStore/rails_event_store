module BrowserTime exposing (TimeZone, defaultTimeZone, format)

import DateFormat exposing (dayOfMonthFixed, hourMilitaryFixed, millisecondFixed, minuteFixed, monthFixed, secondFixed, text, yearNumber)
import Time


type alias TimeZone =
    { zone : Time.Zone, zoneName : String }


defaultTimeZone : TimeZone
defaultTimeZone =
    { zone = Time.utc, zoneName = "UTC" }


format : TimeZone -> Time.Posix -> String
format { zone, zoneName } time =
    DateFormat.format
        [ dayOfMonthFixed
        , text "."
        , monthFixed
        , text "."
        , yearNumber
        , text " "
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
