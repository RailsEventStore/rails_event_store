module BrowserTime exposing (TimeZone, defaultTimeZone, format)

import DateFormat exposing (dayOfMonthFixed, hourMilitaryFixed, millisecondFixed, minuteFixed, monthFixed, secondFixed, text, yearNumber)
import Time


type alias TimeZone =
    { zone : Time.Zone, zoneName : String }


defaultTimeZone : TimeZone
defaultTimeZone =
    { zone = Time.utc, zoneName = "UTC" }


format : TimeZone -> Time.Posix -> String
format { zone } time =
    DateFormat.format
        [ yearNumber
        , text "-"
        , monthFixed
        , text "-"
        , dayOfMonthFixed
        , text "T"
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
