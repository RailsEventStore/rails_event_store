module Route exposing (Route(..), buildUrl, decodeLocation, eventUrl, streamUrl)

import Url
import Url.Parser exposing ((</>))


type Route
    = BrowseEvents String
    | ShowEvent String


decodeLocation : Url.Url -> Maybe Route
decodeLocation loc =
    Url.Parser.parse routeParser (urlFragmentToPath loc)


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


buildUrl : String -> String -> String
buildUrl baseUrl id =
    baseUrl ++ "/" ++ Url.percentEncode id


streamUrl : String -> String
streamUrl streamName =
    buildUrl "#streams" streamName


eventUrl : String -> String
eventUrl eventId =
    buildUrl "#events" eventId
