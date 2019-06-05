module ChangingTreeStateTest exposing (suite)

import JsonTree
import Page.ShowEvent exposing (showJsonTree)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (tag, text)


suite : Test
suite =
    describe "Suite"
        [ describe "Changing tree state"
            [ test "showJsonTree fallbacks to regular html if parsing went wrong" <|
                \_ ->
                    let
                        faultyJsonResult =
                            showJsonTree "{ its not correct }" JsonTree.defaultState (always ())
                    in
                    faultyJsonResult
                        |> Query.fromHtml
                        |> Query.has [ text "{ its not correct }" ]
            ]
        ]
