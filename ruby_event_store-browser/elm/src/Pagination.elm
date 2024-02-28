module Pagination exposing (Specification, empty)

import Url

type alias Specification =
    { position : Maybe String
    , direction : Maybe String
    , count : Maybe String
    }


empty : Specification
empty = Specification Nothing Nothing Nothing
