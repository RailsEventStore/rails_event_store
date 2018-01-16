module Example exposing (..)

import Expect
import Test exposing (..)
import Json.Decode
import Main exposing (streamDecoder, eventDecoder, eventWithDetailsDecoder, rawEventDecoder, Item(..))


suite : Test
suite =
    describe "JSONAPI decoders"
        [ test "Stream decoder" <|
            \_ ->
                let
                    input =
                        """
                        { "name": "all" }
                        """

                    output =
                        Json.Decode.decodeString streamDecoder input
                in
                    Expect.equal output (Ok (Stream "all"))
        , test "Event decoder" <|
            \_ ->
                let
                    input =
                        """
                        {
                          "event_id": "664ada1e-2f01-4ed0-9c16-63dbc82269d2",
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
                        """

                    output =
                        Json.Decode.decodeString eventDecoder input
                in
                    Expect.equal output (Ok (Event "DummyEvent" "2017-12-20T23:49:45.273Z" "664ada1e-2f01-4ed0-9c16-63dbc82269d2"))
        , test "detailed Event decoder" <|
            \_ ->
                let
                    input =
                        """
                        {
                          "event_id": "664ada1e-2f01-4ed0-9c16-63dbc82269d2",
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
                        """

                    output =
                        Json.Decode.decodeString
                            (Json.Decode.andThen eventWithDetailsDecoder rawEventDecoder)
                            input
                in
                    Expect.equal output
                        (Ok
                            { eventType = "DummyEvent"
                            , eventId = "664ada1e-2f01-4ed0-9c16-63dbc82269d2"
                            , data = "{\n  \"foo\": 1,\n  \"bar\": 3.4,\n  \"baz\": \"3\"\n}"
                            , metadata = "{\n  \"timestamp\": \"2017-12-20T23:49:45.273Z\"\n}"
                            }
                        )
        ]
