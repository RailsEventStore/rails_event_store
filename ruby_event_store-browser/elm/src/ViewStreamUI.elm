module ViewStreamUI exposing (Event, PaginatedList, PaginationLink, PaginationLinks, Model)

type alias Event =
    { eventType : String
    , eventId : String
    , createdAt : String
    , rawData : String
    , rawMetadata : String
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


type alias Model =
    { events : PaginatedList Event
    }
