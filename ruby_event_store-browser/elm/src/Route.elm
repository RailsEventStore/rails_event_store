module Route exposing (Route(..), routeParser, urlFragmentToPath)

import Url
import Url.Parser exposing ((</>))


type Route
    = BrowseEvents String
    | ShowEvent String
    | NotFound


routeParser : Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map (BrowseEvents "all") Url.Parser.top
        , Url.Parser.map BrowseEvents (Url.Parser.s "streams" </> Url.Parser.string)
        , Url.Parser.map ShowEvent (Url.Parser.s "events" </> Url.Parser.string)
        ]


urlFragmentToPath : Url.Url -> Url.Url
urlFragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
