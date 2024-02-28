module Pagination exposing (Specification, empty, specificationFromUrl)

import Regex
import Url

type alias Specification =
    { position : Maybe String
    , direction : Maybe String
    , count : Maybe String
    }


empty : Specification
empty = Specification Nothing Nothing Nothing


extractStringFromMatch : Regex.Match -> String
extractStringFromMatch match =
    Maybe.withDefault "" (Maybe.withDefault (Just "") (List.head match.submatches))


extractPaginationPart : String -> String -> Maybe String
extractPaginationPart regexString link = 
    List.head (List.map extractStringFromMatch (Regex.find (Maybe.withDefault Regex.never (Regex.fromString regexString)) link))


specificationFromUrl : String -> Specification
specificationFromUrl link =
    Specification (extractPaginationPart "page%5Bposition%5D=([a-zA-Z0-9-]+)" link) (extractPaginationPart "page%5Bdirection%5D=([a-zA-Z0-9-]+)" link) (extractPaginationPart "page%5Bcount%5D=([a-zA-Z0-9-]+)" link)
