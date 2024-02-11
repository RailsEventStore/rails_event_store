module Url.OurExtra exposing (maybeQueryParameter)

import Maybe
import Url.Builder


maybeQueryParameter : String -> Maybe String -> Maybe Url.Builder.QueryParameter
maybeQueryParameter name maybeValue =
    Maybe.map (\val -> Url.Builder.string name val) maybeValue
