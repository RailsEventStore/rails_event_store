module Route exposing (Route(..), buildUrl, decodeLocation, eventUrl, streamUrl, paginatedStreamUrl)

import Maybe.Extra
import Pagination
import Url
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query as Query


type Route
    = BrowseEvents String Pagination.Specification
    | ShowEvent String

decodeLocation : Url.Url -> Url.Url -> Maybe Route
decodeLocation baseUrl loc =
    Url.Parser.parse routeParser (urlWithoutBase baseUrl loc)


routeParser : Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map (BrowseEvents "all" Pagination.empty) Url.Parser.top
        , Url.Parser.map browseEvents (Url.Parser.s "streams" </> Url.Parser.string <?> Query.string "page[position]" <?> Query.string "page[direction]" <?> Query.string "page[count]")
        , Url.Parser.map ShowEvent (Url.Parser.s "events" </> Url.Parser.string)
        ]


urlWithoutBase : Url.Url -> Url.Url -> Url.Url
urlWithoutBase baseUrl url =
    { url | path = String.dropLeft (String.length baseUrl.path) url.path }


buildUrl : Url.Url -> List String -> List Url.Builder.QueryParameter -> String
buildUrl baseUrl segments query =
    Url.Builder.absolute (pathSegments baseUrl ++ segments) query


streamUrl : Url.Url -> String -> String
streamUrl baseUrl streamName =
    paginatedStreamUrl baseUrl streamName Pagination.empty


paginatedStreamUrl : Url.Url -> String -> Pagination.Specification -> String
paginatedStreamUrl baseUrl streamName pagination =
    buildUrl baseUrl [ "streams", Url.percentEncode streamName ] (paginationQueryParameters pagination)


eventUrl : Url.Url -> String -> String
eventUrl baseUrl eventId =
    buildUrl baseUrl [ "events", Url.percentEncode eventId ] []


pathSegments : Url.Url -> List String
pathSegments baseUrl =
    List.filter (\e -> e /= "") (String.split "/" baseUrl.path)


browseEvents : String -> Maybe String -> Maybe String -> Maybe String -> Route
browseEvents streamName maybePosition maybeDirection maybeCount =
    BrowseEvents streamName (Pagination.Specification maybePosition maybeDirection maybeCount)


maybeQueryParameter : String -> Maybe String -> Maybe Url.Builder.QueryParameter
maybeQueryParameter name maybeValue =
    Maybe.map (\val -> Url.Builder.string name val) maybeValue


positionQueryParameter : Pagination.Specification -> Maybe Url.Builder.QueryParameter
positionQueryParameter specification =
    maybeQueryParameter "page[position]" specification.position


directionQueryParameter : Pagination.Specification -> Maybe Url.Builder.QueryParameter
directionQueryParameter specification =
    maybeQueryParameter "page[direction]" specification.direction


countQueryParameter : Pagination.Specification -> Maybe Url.Builder.QueryParameter
countQueryParameter specification =
    maybeQueryParameter "page[count]" specification.count


paginationQueryParameters : Pagination.Specification -> List Url.Builder.QueryParameter
paginationQueryParameters specification =
    Maybe.Extra.values
        [ positionQueryParameter specification
        , directionQueryParameter specification
        , countQueryParameter specification
        ]
