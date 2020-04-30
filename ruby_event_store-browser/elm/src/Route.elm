module Route exposing (Route(..), buildUrl, decodeLocation, eventUrl, streamUrl)

import Url
import Url.Builder
import Url.Parser exposing ((</>))


type Route
    = BrowseEvents String
    | ShowEvent String


decodeLocation : String -> Url.Url -> Maybe Route
decodeLocation baseUrl loc =
    Url.Parser.parse routeParser (urlWithoutBase baseUrl loc)


routeParser : Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map (BrowseEvents "all") Url.Parser.top
        , Url.Parser.map BrowseEvents (Url.Parser.s "streams" </> Url.Parser.string)
        , Url.Parser.map ShowEvent (Url.Parser.s "events" </> Url.Parser.string)
        ]


urlWithoutBase : String -> Url.Url -> Url.Url
urlWithoutBase baseUrl url =
    { url | path = String.dropLeft (basePathLength baseUrl) url.path }


basePathLength : String -> Int
basePathLength stringUrl =
    case Url.fromString stringUrl of
        Just url ->
            String.length url.path

        Nothing ->
            0


buildUrl : String -> String -> String
buildUrl baseUrl id =
    baseUrl ++ "/" ++ Url.percentEncode id


streamUrl : Url.Url -> String -> String
streamUrl baseUrl streamName =
    Url.Builder.absolute ((pathSegments baseUrl) ++ ["streams", streamName]) []


eventUrl : Url.Url -> String -> String
eventUrl baseUrl eventId =
    Url.Builder.absolute ((pathSegments baseUrl) ++ ["events", eventId]) []


pathSegments : Url.Url -> List String
pathSegments baseUrl = List.filter (\e -> e /= "") (String.split "/" baseUrl.path)
