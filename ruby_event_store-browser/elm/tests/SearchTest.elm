module SearchTest exposing (suite)

import Expect
import Search exposing (filterStreams)
import Test exposing (..)


suite : Test
suite =
    describe "Suite"
        [ describe "filter streams" <|
            [ test "filterStreams starting with" <|
                \_ ->
                    Expect.equal
                        [ "DummyStream$78", "DummyStream$79" ]
                        (filterStreams "Dum" [ "DummyStream$78", "DummyStream$79" ])
            , test "filterStreams empty" <|
                \_ ->
                    Expect.equal
                        []
                        (filterStreams "" [ "DummyStream$78", "DummyStream$79" ])
            , test "filterStreams non matching" <|
                \_ ->
                    Expect.equal
                        []
                        (filterStreams "foo" [ "DummyStream$78", "DummyStream$79" ])
            , test "filterStreams ending with" <|
                \_ ->
                    Expect.equal
                        [ "DummyStream$78" ]
                        (filterStreams "78" [ "DummyStream$78", "DummyStream$79" ])
            , test "filterStreams is case insensitive" <|
                \_ ->
                    Expect.equal
                        [ "DummyStream$78", "DummyStream$79" ]
                        (filterStreams "stream" [ "DummyStream$78", "DummyStream$79" ])
            ]
        ]
