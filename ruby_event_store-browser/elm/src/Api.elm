module Api exposing (Event, PaginatedList, PaginationLink, PaginationLinks, emptyPaginatedList, eventDecoder, eventsDecoder, getEvent, getEvents)

import Flags exposing (Flags)
import Http
import Iso8601
import Json.Decode exposing (Decoder, Value, at, field, list, maybe, nullable, oneOf, string, succeed, value)
import Json.Decode.Pipeline exposing (optional, optionalAt, required, requiredAt)
import Json.Encode exposing (encode)
import Route exposing (buildUrl)
import Time


type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : Time.Posix
    , rawData : String
    , rawMetadata : String
    , correlationStreamName : Maybe String
    , causationStreamName : Maybe String
    , parentEventId : Maybe String
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


getEvent : (Result Http.Error Event -> msg) -> Flags -> String -> Cmd msg
getEvent msgBuilder flags eventId =
    Http.get
        { url = Route.buildUrl flags.eventsUrl eventId
        , expect = Http.expectJson msgBuilder eventDecoder
        }


eventDecoder : Decoder Event
eventDecoder =
    eventDecoder_
        |> field "data"


eventDecoder_ : Decoder Event
eventDecoder_ =
    succeed Event
        |> requiredAt [ "attributes", "event_type" ] string
        |> requiredAt [ "id" ] string
        |> requiredAt [ "attributes", "metadata", "timestamp" ] Iso8601.decoder
        |> requiredAt [ "attributes", "data" ] (value |> Json.Decode.map (encode 2))
        |> requiredAt [ "attributes", "metadata" ] (value |> Json.Decode.map (encode 2))
        |> optionalAt [ "attributes", "correlation_stream_name" ] (maybe string) Nothing
        |> optionalAt [ "attributes", "causation_stream_name" ] (maybe string) Nothing
        |> optionalAt [ "attributes", "parent_event_id" ] (maybe string) Nothing


getEvents : (Result Http.Error (PaginatedList Event) -> msg) -> String -> Cmd msg
getEvents msgBuilder url =
    Http.get
        { url = url
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
