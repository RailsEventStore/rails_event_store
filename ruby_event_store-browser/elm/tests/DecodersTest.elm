module DecodersTest exposing (suite)

import Api exposing (eventDecoder, eventsDecoder)
import Expect
import Json.Decode
import Pagination
import Test exposing (..)
import Time


suite : Test
suite =
    describe "Suite"
        [ describe "JSONAPI decoders"
            [ test "events decoder" <|
                \_ ->
                    let
                        input =
                            """
                            {
                            "links": {
                                "last": "http://localhost:9393/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
                                "next": "http://localhost:9393/api/streams/all/relationships/events?page%5Bposition%5D=664ada1e-2f01-4ed0-9c16-63dbc82269d2&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
                            },
                            "data": [
                                {
                                "id": "664ada1e-2f01-4ed0-9c16-63dbc82269d2",
                                "type": "events",
                                "attributes": {
                                    "event_type": "DummyEvent",
                                    "data": {
                                        "foo": 1,
                                        "bar": 2.0,
                                        "baz": "3"
                                    },
                                    "metadata": {
                                        "timestamp": "2017-12-20T23:49:45.273Z",
                                        "valid_at": "2017-12-20T23:49:45.273Z"
                                    },
                                    "parent_event_id": null,
                                    "type_stream_name": "$by_type_DummyEvent"
                                }
                                }
                            ]
                            }
                            """

                        output =
                            Json.Decode.decodeString (eventsDecoder Pagination.empty) input
                    in
                    Expect.equal output
                        (Ok
                            { events =
                                [ { eventType = "DummyEvent"
                                  , eventId = "664ada1e-2f01-4ed0-9c16-63dbc82269d2"
                                  , createdAt = Time.millisToPosix 1513813785273
                                  , rawData = "{\n  \"foo\": 1,\n  \"bar\": 2,\n  \"baz\": \"3\"\n}"
                                  , rawMetadata = "{\n  \"timestamp\": \"2017-12-20T23:49:45.273Z\",\n  \"valid_at\": \"2017-12-20T23:49:45.273Z\"\n}"
                                  , correlationStreamName = Nothing
                                  , causationStreamName = Nothing
                                  , typeStreamName = "$by_type_DummyEvent"
                                  , parentEventId = Nothing
                                  , streams = Nothing
                                  , validAt = Time.millisToPosix 1513813785273
                                  }
                                ]
                            , pagination =
                                Pagination.empty
                            , links =
                                { next = Just { specification = Pagination.Specification (Just "664ada1e-2f01-4ed0-9c16-63dbc82269d2") (Just "backward") (Just "20") }
                                , prev = Nothing
                                , first = Nothing
                                , last = Just { specification = Pagination.Specification (Just "head") (Just "forward") (Just "20") }
                                }
                            }
                        )
            , test "event decoder" <|
                \_ ->
                    let
                        input =
                            """
                            {
                            "data": {
                                "id": "664ada1e-2f01-4ed0-9c16-63dbc82269d2",
                                "type": "events",
                                "attributes": {
                                    "event_type": "DummyEvent",
                                    "data": {
                                        "foo": 1,
                                        "bar": 3.4,
                                        "baz": "3"
                                    },
                                    "metadata": {
                                        "timestamp": "2017-12-20T23:49:45.273Z",
                                        "valid_at": "2017-12-20T23:49:45.273Z"
                                    },
                                    "correlation_stream_name": "$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad",
                                    "causation_stream_name": "$by_causation_id_664ada1e-2f01-4ed0-9c16-63dbc82269d2",
                                    "type_stream_name": "$by_type_DummyEvent",
                                    "parent_event_id": "cb12f84b-b9e4-439b-8442-50fae6244dc9"
                                },
                                "relationships": {
                                    "streams": {
                                        "data": [
                                            {
                                                "id": "dummy",
                                                "type": "streams"
                                            },
                                            {
                                                "id": "$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad",
                                                "type": "streams"
                                            },
                                            {
                                                "id": "$by_causation_id_664ada1e-2f01-4ed0-9c16-63dbc82269d2",
                                                "type": "streams"
                                            },
                                            {
                                                "id": "$by_type_DummyEvent",
                                                "type": "streams"
                                            }
                                        ]
                                    }
                                }
                            }
                            }
                            """

                        output =
                            Json.Decode.decodeString eventDecoder input
                    in
                    Expect.equal output
                        (Ok
                            { eventType = "DummyEvent"
                            , eventId = "664ada1e-2f01-4ed0-9c16-63dbc82269d2"
                            , createdAt = Time.millisToPosix 1513813785273
                            , rawData = "{\n  \"foo\": 1,\n  \"bar\": 3.4,\n  \"baz\": \"3\"\n}"
                            , rawMetadata = "{\n  \"timestamp\": \"2017-12-20T23:49:45.273Z\",\n  \"valid_at\": \"2017-12-20T23:49:45.273Z\"\n}"
                            , correlationStreamName = Just "$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad"
                            , causationStreamName = Just "$by_causation_id_664ada1e-2f01-4ed0-9c16-63dbc82269d2"
                            , typeStreamName = "$by_type_DummyEvent"
                            , parentEventId = Just "cb12f84b-b9e4-439b-8442-50fae6244dc9"
                            , streams = Just [ "dummy", "$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad", "$by_causation_id_664ada1e-2f01-4ed0-9c16-63dbc82269d2", "$by_type_DummyEvent" ]
                            , validAt = Time.millisToPosix 1513813785273
                            }
                        )
            ]
        ]
