module Api exposing (Event, PaginatedList, PaginationLink, PaginationLinks, RemoteResource(..), SearchStream, Stream, emptyPaginatedList, eventDecoder, eventsDecoder, getEvent, getEvents, getSearchStreams, getStream, searchStreamsDecoder, Stats, getStats)

import Flags exposing (Flags)
import Http
import Iso8601
import Json.Decode exposing (Decoder, field, list, maybe, string, succeed, value, int)
import Json.Decode.Pipeline exposing (optional, optionalAt, required, requiredAt)
import Json.Encode exposing (encode)
import Maybe.Extra
import Pagination
import Time
import Url
import Url.Builder
import Url.OurExtra
import Url.Parser
import Url.Parser.Query


type RemoteResource a
    = Loading
    | Loaded a
    | NotFound
    | Failure


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : Time.Posix
    , rawData : String
    , rawMetadata : String
    , correlationStreamName : Maybe String
    , causationStreamName : Maybe String
    , typeStreamName : String
    , parentEventId : Maybe String
    , streams : Maybe (List String)
    , validAt : Time.Posix
    }


type alias SearchStream =
    { streamId : String
    }

type alias Stats =
    { eventsInTotal: Int
    }

type alias PaginatedList a =
    { pagination : Pagination.Specification
    , events : List a
    , links : PaginationLinks
    }


type alias PaginationLink =
    { specification : Pagination.Specification
    }


type alias PaginationLinks =
    { next : Maybe PaginationLink
    , prev : Maybe PaginationLink
    , first : Maybe PaginationLink
    , last : Maybe PaginationLink
    }


type alias Stream =
    { eventsRelationshipLink : String
    , relatedStreams : Maybe (List String)
    }


buildUrl : String -> String -> String
buildUrl baseUrl id =
    baseUrl ++ "/" ++ Url.percentEncode id


eventUrl : Flags -> String -> String
eventUrl flags eventId =
    buildUrl (Url.toString flags.apiUrl ++ "/events") eventId


eventsUrl : Flags -> String -> Pagination.Specification -> String
eventsUrl flags streamId pagination =
    Url.toString flags.apiUrl ++ "/streams/" ++ Url.percentEncode streamId ++ "/relationships/events" ++ Url.Builder.toQuery (paginationQueryParameters pagination)


streamUrl : Flags -> String -> String
streamUrl flags streamId =
    buildUrl (Url.toString flags.apiUrl ++ "/streams") streamId


searchStreamsUrl : Flags -> String -> String
searchStreamsUrl flags query =
    buildUrl (Url.toString flags.apiUrl ++ "/search_streams") query

getStatsUrl : Flags -> String
getStatsUrl flags =
    Url.toString flags.apiUrl ++ "/stats"

getEvent : (Result Http.Error Event -> msg) -> Flags -> String -> Cmd msg
getEvent msgBuilder flags eventId =
    Http.get
        { url = eventUrl flags eventId
        , expect = Http.expectJson msgBuilder eventDecoder
        }


getStream : (Result Http.Error Stream -> msg) -> Flags -> String -> Cmd msg
getStream msgBuilder flags streamId =
    Http.get
        { url = streamUrl flags streamId
        , expect = Http.expectJson msgBuilder streamDecoder
        }


getSearchStreams : (Result Http.Error (List SearchStream) -> msg) -> Flags -> String -> Cmd msg
getSearchStreams msgBuilder flags query =
    Http.get
        { url = searchStreamsUrl flags query
        , expect = Http.expectJson msgBuilder searchStreamsDecoder
        }

getStats : (Result Http.Error (Stats) -> msg) -> Flags -> Cmd msg
getStats msgBuilder flags =
    Http.get
        { url = getStatsUrl flags
        , expect = Http.expectJson msgBuilder statsDecoder
        }

eventDecoder : Decoder Event
eventDecoder =
    eventDecoder_
        |> field "data"


eventDecoder_ : Decoder Event
eventDecoder_ =
    let
        inlinedStream =
            field "id" string
    in
    succeed Event
        |> requiredAt [ "attributes", "event_type" ] string
        |> requiredAt [ "id" ] string
        |> requiredAt [ "attributes", "metadata", "timestamp" ] Iso8601.decoder
        |> requiredAt [ "attributes", "data" ] (value |> Json.Decode.map (encode 2))
        |> requiredAt [ "attributes", "metadata" ] (value |> Json.Decode.map (encode 2))
        |> optionalAt [ "attributes", "correlation_stream_name" ] (maybe string) Nothing
        |> optionalAt [ "attributes", "causation_stream_name" ] (maybe string) Nothing
        |> requiredAt [ "attributes", "type_stream_name" ] string
        |> optionalAt [ "attributes", "parent_event_id" ] (maybe string) Nothing
        |> optionalAt [ "relationships", "streams", "data" ] (maybe (list inlinedStream)) Nothing
        |> requiredAt [ "attributes", "metadata", "valid_at" ] Iso8601.decoder


streamDecoder : Decoder Stream
streamDecoder =
    streamDecoder_
        |> field "data"


streamDecoder_ : Decoder Stream
streamDecoder_ =
    succeed Stream
        |> requiredAt [ "relationships", "events", "links", "self" ] string
        |> optionalAt [ "attributes", "related_streams" ] (maybe (list string)) Nothing


getEvents : (Result Http.Error (PaginatedList Event) -> msg) -> Flags -> String -> Pagination.Specification -> Cmd msg
getEvents msgBuilder flags streamId paginationSpecification =
    Http.get
        { url = eventsUrl flags streamId paginationSpecification
        , expect = Http.expectJson msgBuilder (eventsDecoder paginationSpecification)
        }


eventsDecoder : Pagination.Specification -> Decoder (PaginatedList Event)
eventsDecoder pagination =
    succeed (PaginatedList pagination)
        |> required "data" (list eventDecoder_)
        |> required "links" linksDecoder


searchStreamDecoder : Decoder SearchStream
searchStreamDecoder =
    succeed SearchStream
        |> required "id" string


searchStreamsDecoder : Decoder (List SearchStream)
searchStreamsDecoder =
    list searchStreamDecoder
        |> field "data"

statsDecoder : Decoder Stats
statsDecoder =
    statsDecoder_
        |> field "meta"

statsDecoder_ : Decoder Stats
statsDecoder_ =
    succeed Stats
        |> required "events_in_total" int

linksDecoder : Decoder PaginationLinks
linksDecoder =
    succeed PaginationLinks
        |> optional "next" (extractSpecification (maybe string)) Nothing
        |> optional "prev" (extractSpecification (maybe string)) Nothing
        |> optional "first" (extractSpecification (maybe string)) Nothing
        |> optional "last" (extractSpecification (maybe string)) Nothing


extractSpecification : Decoder (Maybe String) -> Decoder (Maybe PaginationLink)
extractSpecification decoder =
    Json.Decode.map (\maybeLink -> Maybe.map (\link -> { specification = specificationFromUrl link }) maybeLink) decoder


emptyPaginatedList : PaginatedList Event
emptyPaginatedList =
    let
        initLinks =
            { prev = Nothing
            , next = Nothing
            , first = Nothing
            , last = Nothing
            }
    in
    PaginatedList Pagination.empty [] initLinks


paginationQueryParameters : Pagination.Specification -> List Url.Builder.QueryParameter
paginationQueryParameters specification =
    Maybe.Extra.values
        [ Url.OurExtra.maybeQueryParameter "page[position]" specification.position
        , Url.OurExtra.maybeQueryParameter "page[direction]" specification.direction
        , Url.OurExtra.maybeQueryParameter "page[count]" specification.count
        ]


extractQueryArgument : String -> Url.Url -> Maybe String
extractQueryArgument key location =
    { location | path = "" }
        -- https://github.com/elm/url/issues/17#issuecomment-482947419
        |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string key))
        |> Maybe.withDefault Nothing


specificationFromUrl : String -> Pagination.Specification
specificationFromUrl stringUrl =
    case Url.fromString stringUrl of
        Just url ->
            Pagination.Specification (extractQueryArgument "page[position]" url) (extractQueryArgument "page[direction]" url) (extractQueryArgument "page[count]" url)

        Nothing ->
            Pagination.empty
