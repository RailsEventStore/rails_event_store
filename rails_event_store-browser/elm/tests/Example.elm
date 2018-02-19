module Example exposing (..)

import Expect
import Test exposing (..)
import Json.Decode exposing (list)
import Main exposing (..)


suite : Test
suite =
    describe "JSONAPI decoders"
        [ test "streams decoder" <|
            \_ ->
                let
                    input =
                        """
                        {
                          "links": {
                            "last": "/streams/head/forward/20",
                            "next": "/streams/all/backward/20"
                          },
                          "data": [
                            {
                              "id": "all",
                              "type": "streams"
                            }
                          ]
                        }
                        """

                    output =
                        Json.Decode.decodeString itemsDecoder input
                in
                    Expect.equal output
                        (Ok
                            ({ items = [ StreamItem (Stream "all") ]
                             , links =
                                { prev = Nothing
                                , next = Just "/streams/all/backward/20"
                                , first = Nothing
                                , last = Just "/streams/head/forward/20"
                                }
                             }
                            )
                        )
        , test "events decoder" <|
            \_ ->
                let
                    input =
                        """
                        {
                          "links": {
                            "last": "/streams/all/head/forward/20",
                            "next": "/streams/all/004ada1e-2f01-4ed0-9c16-63dbc82269d2/backward/20"
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
                                  "timestamp": "2017-12-20T23:49:45.273Z"
                                }
                              }
                            }
                          ]
                        }
                        """

                    output =
                        Json.Decode.decodeString itemsDecoder input
                in
                    Expect.equal output
                        (Ok
                            ({ items =
                                [ EventItem
                                    { eventType = "DummyEvent"
                                    , eventId = "664ada1e-2f01-4ed0-9c16-63dbc82269d2"
                                    , createdAt = "2017-12-20T23:49:45.273Z"
                                    , rawData = "{\n  \"foo\": 1,\n  \"bar\": 2,\n  \"baz\": \"3\"\n}"
                                    , rawMetadata = "{\n  \"timestamp\": \"2017-12-20T23:49:45.273Z\"\n}"
                                    }
                                ]
                             , links =
                                { next = Just "/streams/all/004ada1e-2f01-4ed0-9c16-63dbc82269d2/backward/20"
                                , prev = Nothing
                                , first = Nothing
                                , last = Just "/streams/all/head/forward/20"
                                }
                             }
                            )
                        )
        , test "handles slashes properly in urls" <|
            \_ ->
                Expect.equal
                    (buildUrl "https://example.org" "resource/uuid")
                    "https://example.org/resource%2Fuuid"
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
                                "timestamp": "2017-12-20T23:49:45.273Z"
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
                            , createdAt = "2017-12-20T23:49:45.273Z"
                            , rawData = "{\n  \"foo\": 1,\n  \"bar\": 3.4,\n  \"baz\": \"3\"\n}"
                            , rawMetadata = "{\n  \"timestamp\": \"2017-12-20T23:49:45.273Z\"\n}"
                            }
                        )
        ]
