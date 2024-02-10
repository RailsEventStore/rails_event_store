module Api exposing (Event, PaginatedList, PaginationLink, PaginationLinks, RemoteResource(..), Stream, emptyPaginatedList, eventDecoder, eventsDecoder, getEvent, getEvents, getStream)

import Flags exposing (Flags)
import Http
import Iso8601
import Json.Decode exposing (Decoder, field, list, maybe, string, succeed, value)
import Json.Decode.Pipeline exposing (optional, optionalAt, required, requiredAt)
import Json.Encode exposing (encode)
import Route exposing (PaginationSpecification)
import Time
import Url


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
    }


type alias PaginatedList a =
    { events : List a
    , links : PaginationLinks
    }


type alias PaginationLink =
    String


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


eventsUrl : Flags -> String -> PaginationSpecification -> String
eventsUrl flags streamId pagination =
    case pagination.position of
        -- Temporary assumption that if one parameter is there, all are there
        Just position -> 
            Url.toString flags.apiUrl ++ "/streams/" ++ (Url.percentEncode streamId) ++ "/relationships/events" ++ "?page%5Bposition%5D=" ++ (Maybe.withDefault "" pagination.position) ++ "&page%5Bdirection%5D=" ++ (Maybe.withDefault "" pagination.direction) ++ "&page%5Bcount%5D=" ++ (Maybe.withDefault "" pagination.count)
        Nothing -> 
            Url.toString flags.apiUrl ++ "/streams/" ++ (Url.percentEncode streamId) ++ "/relationships/events"


streamUrl : Flags -> String -> String
streamUrl flags streamId =
    buildUrl (Url.toString flags.apiUrl ++ "/streams") streamId


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


streamDecoder : Decoder Stream
streamDecoder =
    streamDecoder_
        |> field "data"


streamDecoder_ : Decoder Stream
streamDecoder_ =
    succeed Stream
        |> requiredAt [ "relationships", "events", "links", "self" ] string
        |> optionalAt [ "attributes", "related_streams" ] (maybe (list string)) Nothing


getEvents : (Result Http.Error (PaginatedList Event) -> msg) -> Flags -> String -> PaginationSpecification -> Cmd msg
getEvents msgBuilder flags streamId paginationSpecification =
    Http.get
        { url = eventsUrl flags streamId paginationSpecification
        , expect = Http.expectJson msgBuilder eventsDecoder
        }


eventsDecoder : Decoder (PaginatedList Event)
eventsDecoder =
    succeed PaginatedList
        |> required "data" (list eventDecoder_)
        |> required "links" linksDecoder


linksDecoder : Decoder PaginationLinks
linksDecoder =
    succeed PaginationLinks
        |> optional "next" (maybe string) Nothing
        |> optional "prev" (maybe string) Nothing
        |> optional "first" (maybe string) Nothing
        |> optional "last" (maybe string) Nothing


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
    PaginatedList [] initLinks
