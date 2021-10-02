module Tailwind.Breakpoints exposing (..)

import Css
import Css.Media


sm : List Css.Style -> Css.Style
sm =
    Css.Media.withMediaQuery [ "(min-width: 640px)" ]


md : List Css.Style -> Css.Style
md =
    Css.Media.withMediaQuery [ "(min-width: 768px)" ]


lg : List Css.Style -> Css.Style
lg =
    Css.Media.withMediaQuery [ "(min-width: 1024px)" ]


xl : List Css.Style -> Css.Style
xl =
    Css.Media.withMediaQuery [ "(min-width: 1280px)" ]


xxl : List Css.Style -> Css.Style
xxl =
    Css.Media.withMediaQuery [ "(min-width: 1536px)" ]
