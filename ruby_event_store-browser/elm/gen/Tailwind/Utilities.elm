module Tailwind.Utilities exposing (..)

import Css
import Css.Animations
import Css.Global
import Css.Media


globalStyles : List Css.Global.Snippet
globalStyles =
    [ Css.Global.selector "*,\n::before,\n::after"
        [ Css.property "box-sizing" "border-box"
        ]
    , Css.Global.selector "html"
        [ Css.property "-moz-tab-size" "4"
        , Css.property "tab-size" "4"
        ]
    , Css.Global.selector "html"
        [ Css.property "line-height" "1.15"
        , Css.property "-webkit-text-size-adjust" "100%"
        ]
    , Css.Global.selector "body"
        [ Css.property "margin" "0"
        ]
    , Css.Global.selector "body"
        [ Css.property "font-family" "system-ui,\n\t\t-apple-system, \n\t\t'Segoe UI',\n\t\tRoboto,\n\t\tHelvetica,\n\t\tArial,\n\t\tsans-serif,\n\t\t'Apple Color Emoji',\n\t\t'Segoe UI Emoji'"
        ]
    , Css.Global.selector "hr"
        [ Css.property "height" "0"
        , Css.property "color" "inherit"
        ]
    , Css.Global.selector "abbr[title]"
        [ Css.property "text-decoration" "underline dotted"
        ]
    , Css.Global.selector "b,\nstrong"
        [ Css.property "font-weight" "bolder"
        ]
    , Css.Global.selector "code,\nkbd,\nsamp,\npre"
        [ Css.property "font-family" "ui-monospace,\n\t\tSFMono-Regular,\n\t\tConsolas,\n\t\t'Liberation Mono',\n\t\tMenlo,\n\t\tmonospace"
        , Css.property "font-size" "1em"
        ]
    , Css.Global.selector "small"
        [ Css.property "font-size" "80%"
        ]
    , Css.Global.selector "sub,\nsup"
        [ Css.property "font-size" "75%"
        , Css.property "line-height" "0"
        , Css.property "position" "relative"
        , Css.property "vertical-align" "baseline"
        ]
    , Css.Global.selector "sub"
        [ Css.property "bottom" "-0.25em"
        ]
    , Css.Global.selector "sup"
        [ Css.property "top" "-0.5em"
        ]
    , Css.Global.selector "table"
        [ Css.property "text-indent" "0"
        , Css.property "border-color" "inherit"
        ]
    , Css.Global.selector "button,\ninput,\noptgroup,\nselect,\ntextarea"
        [ Css.property "font-family" "inherit"
        , Css.property "font-size" "100%"
        , Css.property "line-height" "1.15"
        , Css.property "margin" "0"
        ]
    , Css.Global.selector "button,\nselect"
        [ Css.property "text-transform" "none"
        ]
    , Css.Global.selector "button,\n[type='button'],\n[type='reset'],\n[type='submit']"
        [ Css.property "-webkit-appearance" "button"
        ]
    , Css.Global.selector "::-moz-focus-inner"
        [ Css.property "border-style" "none"
        , Css.property "padding" "0"
        ]
    , Css.Global.selector ":-moz-focusring"
        [ Css.property "outline" "1px dotted ButtonText"
        ]
    , Css.Global.selector ":-moz-ui-invalid"
        [ Css.property "box-shadow" "none"
        ]
    , Css.Global.selector "legend"
        [ Css.property "padding" "0"
        ]
    , Css.Global.selector "progress"
        [ Css.property "vertical-align" "baseline"
        ]
    , Css.Global.selector "::-webkit-inner-spin-button,\n::-webkit-outer-spin-button"
        [ Css.property "height" "auto"
        ]
    , Css.Global.selector "[type='search']"
        [ Css.property "-webkit-appearance" "textfield"
        , Css.property "outline-offset" "-2px"
        ]
    , Css.Global.selector "::-webkit-search-decoration"
        [ Css.property "-webkit-appearance" "none"
        ]
    , Css.Global.selector "::-webkit-file-upload-button"
        [ Css.property "-webkit-appearance" "button"
        , Css.property "font" "inherit"
        ]
    , Css.Global.selector "summary"
        [ Css.property "display" "list-item"
        ]
    , Css.Global.selector "blockquote,\ndl,\ndd,\nh1,\nh2,\nh3,\nh4,\nh5,\nh6,\nhr,\nfigure,\np,\npre"
        [ Css.property "margin" "0"
        ]
    , Css.Global.selector "button"
        [ Css.property "background-color" "transparent"
        , Css.property "background-image" "none"
        ]
    , Css.Global.selector "fieldset"
        [ Css.property "margin" "0"
        , Css.property "padding" "0"
        ]
    , Css.Global.selector "ol,\nul"
        [ Css.property "list-style" "none"
        , Css.property "margin" "0"
        , Css.property "padding" "0"
        ]
    , Css.Global.selector "html"
        [ Css.property "font-family" "ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, \"Noto Sans\", sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\", \"Noto Color Emoji\""
        , Css.property "line-height" "1.5"
        ]
    , Css.Global.selector "body"
        [ Css.property "font-family" "inherit"
        , Css.property "line-height" "inherit"
        ]
    , Css.Global.selector "*,\n::before,\n::after"
        [ Css.property "box-sizing" "border-box"
        , Css.property "border-width" "0"
        , Css.property "border-style" "solid"
        , Css.property "border-color" "currentColor"
        ]
    , Css.Global.selector "hr"
        [ Css.property "border-top-width" "1px"
        ]
    , Css.Global.selector "img"
        [ Css.property "border-style" "solid"
        ]
    , Css.Global.selector "textarea"
        [ Css.property "resize" "vertical"
        ]
    , Css.Global.selector "input::placeholder,\ntextarea::placeholder"
        [ Css.property "opacity" "1"
        , Css.property "color" "#9ca3af"
        ]
    , Css.Global.selector "button,\n[role=\"button\"]"
        [ Css.property "cursor" "pointer"
        ]
    , Css.Global.selector ":-moz-focusring"
        [ Css.property "outline" "auto"
        ]
    , Css.Global.selector "table"
        [ Css.property "border-collapse" "collapse"
        ]
    , Css.Global.selector "h1,\nh2,\nh3,\nh4,\nh5,\nh6"
        [ Css.property "font-size" "inherit"
        , Css.property "font-weight" "inherit"
        ]
    , Css.Global.selector "a"
        [ Css.property "color" "inherit"
        , Css.property "text-decoration" "inherit"
        ]
    , Css.Global.selector "button,\ninput,\noptgroup,\nselect,\ntextarea"
        [ Css.property "padding" "0"
        , Css.property "line-height" "inherit"
        , Css.property "color" "inherit"
        ]
    , Css.Global.selector "pre,\ncode,\nkbd,\nsamp"
        [ Css.property "font-family" "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", \"Courier New\", monospace"
        ]
    , Css.Global.selector "img,\nsvg,\nvideo,\ncanvas,\naudio,\niframe,\nembed,\nobject"
        [ Css.property "display" "block"
        , Css.property "vertical-align" "middle"
        ]
    , Css.Global.selector "img,\nvideo"
        [ Css.property "max-width" "100%"
        , Css.property "height" "auto"
        ]
    , Css.Global.selector "[hidden]"
        [ Css.property "display" "none"
        ]
    , Css.Global.selector "*, ::before, ::after"
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(229, 231, 235, var(--tw-border-opacity))"
        ]
    , Css.Global.selector "*, ::before, ::after"
        [ Css.property "--tw-shadow" "0 0 #0000"
        ]
    , Css.Global.selector "*, ::before, ::after"
        [ Css.property "--tw-ring-inset" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-ring-offset-width" "0px"
        , Css.property "--tw-ring-offset-color" "#fff"
        , Css.property "--tw-ring-color" "rgba(59, 130, 246, 0.5)"
        , Css.property "--tw-ring-offset-shadow" "0 0 #0000"
        , Css.property "--tw-ring-shadow" "0 0 #0000"
        ]
    ]


absolute : Css.Style
absolute =
    Css.property "position" "absolute"


align_baseline : Css.Style
align_baseline =
    Css.property "vertical-align" "baseline"


align_bottom : Css.Style
align_bottom =
    Css.property "vertical-align" "bottom"


align_middle : Css.Style
align_middle =
    Css.property "vertical-align" "middle"


align_text_bottom : Css.Style
align_text_bottom =
    Css.property "vertical-align" "text-bottom"


align_text_top : Css.Style
align_text_top =
    Css.property "vertical-align" "text-top"


align_top : Css.Style
align_top =
    Css.property "vertical-align" "top"


animate_bounce : Css.Style
animate_bounce =
    Css.batch
        [ Css.property "animation" "1s infinite"
        , Css.animationName
            (Css.Animations.keyframes
                [ ( 0
                  , [ Css.Animations.property "transform" "translateY(-25%)"
                    , Css.Animations.property "animation-timing-function" "cubic-bezier(0.8,0,1,1)"
                    ]
                  )
                , ( 50
                  , [ Css.Animations.property "transform" "none"
                    , Css.Animations.property "animation-timing-function" "cubic-bezier(0,0,0.2,1)"
                    ]
                  )
                ]
            )
        ]


animate_none : Css.Style
animate_none =
    Css.property "animation" "none"


animate_ping : Css.Style
animate_ping =
    Css.batch
        [ Css.property "animation" "1s cubic-bezier(0, 0, 0.2, 1) infinite"
        , Css.animationName
            (Css.Animations.keyframes
                [ ( 75
                  , [ Css.Animations.property "transform" "scale(2)"
                    , Css.Animations.property "opacity" "0"
                    ]
                  )
                ]
            )
        ]


animate_pulse : Css.Style
animate_pulse =
    Css.batch
        [ Css.property "animation" "2s cubic-bezier(0.4, 0, 0.6, 1) infinite"
        , Css.animationName
            (Css.Animations.keyframes
                [ ( 50
                  , [ Css.Animations.property "opacity" ".5"
                    ]
                  )
                ]
            )
        ]


animate_spin : Css.Style
animate_spin =
    Css.batch
        [ Css.property "animation" "1s linear infinite"
        , Css.animationName
            (Css.Animations.keyframes
                [ ( 100
                  , [ Css.Animations.property "transform" "rotate(360deg)"
                    ]
                  )
                ]
            )
        ]


antialiased : Css.Style
antialiased =
    Css.batch
        [ Css.property "-webkit-font-smoothing" "antialiased"
        , Css.property "-moz-osx-font-smoothing" "grayscale"
        ]


appearance_none : Css.Style
appearance_none =
    Css.property "appearance" "none"


auto_cols_auto : Css.Style
auto_cols_auto =
    Css.property "grid-auto-columns" "auto"


auto_cols_fr : Css.Style
auto_cols_fr =
    Css.property "grid-auto-columns" "minmax(0, 1fr)"


auto_cols_max : Css.Style
auto_cols_max =
    Css.property "grid-auto-columns" "max-content"


auto_cols_min : Css.Style
auto_cols_min =
    Css.property "grid-auto-columns" "min-content"


auto_rows_auto : Css.Style
auto_rows_auto =
    Css.property "grid-auto-rows" "auto"


auto_rows_fr : Css.Style
auto_rows_fr =
    Css.property "grid-auto-rows" "minmax(0, 1fr)"


auto_rows_max : Css.Style
auto_rows_max =
    Css.property "grid-auto-rows" "max-content"


auto_rows_min : Css.Style
auto_rows_min =
    Css.property "grid-auto-rows" "min-content"


backdrop_blur : Css.Style
backdrop_blur =
    Css.property "--tw-backdrop-blur" "blur(8px)"


backdrop_blur_0 : Css.Style
backdrop_blur_0 =
    Css.property "--tw-backdrop-blur" "blur(0)"


backdrop_blur_2xl : Css.Style
backdrop_blur_2xl =
    Css.property "--tw-backdrop-blur" "blur(40px)"


backdrop_blur_3xl : Css.Style
backdrop_blur_3xl =
    Css.property "--tw-backdrop-blur" "blur(64px)"


backdrop_blur_lg : Css.Style
backdrop_blur_lg =
    Css.property "--tw-backdrop-blur" "blur(16px)"


backdrop_blur_md : Css.Style
backdrop_blur_md =
    Css.property "--tw-backdrop-blur" "blur(12px)"


backdrop_blur_none : Css.Style
backdrop_blur_none =
    Css.property "--tw-backdrop-blur" "blur(0)"


backdrop_blur_sm : Css.Style
backdrop_blur_sm =
    Css.property "--tw-backdrop-blur" "blur(4px)"


backdrop_blur_xl : Css.Style
backdrop_blur_xl =
    Css.property "--tw-backdrop-blur" "blur(24px)"


backdrop_brightness_0 : Css.Style
backdrop_brightness_0 =
    Css.property "--tw-backdrop-brightness" "brightness(0)"


backdrop_brightness_100 : Css.Style
backdrop_brightness_100 =
    Css.property "--tw-backdrop-brightness" "brightness(1)"


backdrop_brightness_105 : Css.Style
backdrop_brightness_105 =
    Css.property "--tw-backdrop-brightness" "brightness(1.05)"


backdrop_brightness_110 : Css.Style
backdrop_brightness_110 =
    Css.property "--tw-backdrop-brightness" "brightness(1.1)"


backdrop_brightness_125 : Css.Style
backdrop_brightness_125 =
    Css.property "--tw-backdrop-brightness" "brightness(1.25)"


backdrop_brightness_150 : Css.Style
backdrop_brightness_150 =
    Css.property "--tw-backdrop-brightness" "brightness(1.5)"


backdrop_brightness_200 : Css.Style
backdrop_brightness_200 =
    Css.property "--tw-backdrop-brightness" "brightness(2)"


backdrop_brightness_50 : Css.Style
backdrop_brightness_50 =
    Css.property "--tw-backdrop-brightness" "brightness(.5)"


backdrop_brightness_75 : Css.Style
backdrop_brightness_75 =
    Css.property "--tw-backdrop-brightness" "brightness(.75)"


backdrop_brightness_90 : Css.Style
backdrop_brightness_90 =
    Css.property "--tw-backdrop-brightness" "brightness(.9)"


backdrop_brightness_95 : Css.Style
backdrop_brightness_95 =
    Css.property "--tw-backdrop-brightness" "brightness(.95)"


backdrop_contrast_0 : Css.Style
backdrop_contrast_0 =
    Css.property "--tw-backdrop-contrast" "contrast(0)"


backdrop_contrast_100 : Css.Style
backdrop_contrast_100 =
    Css.property "--tw-backdrop-contrast" "contrast(1)"


backdrop_contrast_125 : Css.Style
backdrop_contrast_125 =
    Css.property "--tw-backdrop-contrast" "contrast(1.25)"


backdrop_contrast_150 : Css.Style
backdrop_contrast_150 =
    Css.property "--tw-backdrop-contrast" "contrast(1.5)"


backdrop_contrast_200 : Css.Style
backdrop_contrast_200 =
    Css.property "--tw-backdrop-contrast" "contrast(2)"


backdrop_contrast_50 : Css.Style
backdrop_contrast_50 =
    Css.property "--tw-backdrop-contrast" "contrast(.5)"


backdrop_contrast_75 : Css.Style
backdrop_contrast_75 =
    Css.property "--tw-backdrop-contrast" "contrast(.75)"


backdrop_filter : Css.Style
backdrop_filter =
    Css.batch
        [ Css.property "--tw-backdrop-blur" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-brightness" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-contrast" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-grayscale" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-hue-rotate" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-invert" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-opacity" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-saturate" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-backdrop-sepia" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "backdrop-filter" "var(--tw-backdrop-blur) var(--tw-backdrop-brightness) var(--tw-backdrop-contrast) var(--tw-backdrop-grayscale) var(--tw-backdrop-hue-rotate) var(--tw-backdrop-invert) var(--tw-backdrop-opacity) var(--tw-backdrop-saturate) var(--tw-backdrop-sepia)"
        ]


backdrop_filter_none : Css.Style
backdrop_filter_none =
    Css.property "backdrop-filter" "none"


backdrop_grayscale : Css.Style
backdrop_grayscale =
    Css.property "--tw-backdrop-grayscale" "grayscale(100%)"


backdrop_grayscale_0 : Css.Style
backdrop_grayscale_0 =
    Css.property "--tw-backdrop-grayscale" "grayscale(0)"


backdrop_hue_rotate_0 : Css.Style
backdrop_hue_rotate_0 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(0deg)"


backdrop_hue_rotate_15 : Css.Style
backdrop_hue_rotate_15 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(15deg)"


backdrop_hue_rotate_180 : Css.Style
backdrop_hue_rotate_180 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(180deg)"


backdrop_hue_rotate_30 : Css.Style
backdrop_hue_rotate_30 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(30deg)"


backdrop_hue_rotate_60 : Css.Style
backdrop_hue_rotate_60 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(60deg)"


backdrop_hue_rotate_90 : Css.Style
backdrop_hue_rotate_90 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(90deg)"


backdrop_invert : Css.Style
backdrop_invert =
    Css.property "--tw-backdrop-invert" "invert(100%)"


backdrop_invert_0 : Css.Style
backdrop_invert_0 =
    Css.property "--tw-backdrop-invert" "invert(0)"


backdrop_opacity_0 : Css.Style
backdrop_opacity_0 =
    Css.property "--tw-backdrop-opacity" "opacity(0)"


backdrop_opacity_10 : Css.Style
backdrop_opacity_10 =
    Css.property "--tw-backdrop-opacity" "opacity(0.1)"


backdrop_opacity_100 : Css.Style
backdrop_opacity_100 =
    Css.property "--tw-backdrop-opacity" "opacity(1)"


backdrop_opacity_20 : Css.Style
backdrop_opacity_20 =
    Css.property "--tw-backdrop-opacity" "opacity(0.2)"


backdrop_opacity_25 : Css.Style
backdrop_opacity_25 =
    Css.property "--tw-backdrop-opacity" "opacity(0.25)"


backdrop_opacity_30 : Css.Style
backdrop_opacity_30 =
    Css.property "--tw-backdrop-opacity" "opacity(0.3)"


backdrop_opacity_40 : Css.Style
backdrop_opacity_40 =
    Css.property "--tw-backdrop-opacity" "opacity(0.4)"


backdrop_opacity_5 : Css.Style
backdrop_opacity_5 =
    Css.property "--tw-backdrop-opacity" "opacity(0.05)"


backdrop_opacity_50 : Css.Style
backdrop_opacity_50 =
    Css.property "--tw-backdrop-opacity" "opacity(0.5)"


backdrop_opacity_60 : Css.Style
backdrop_opacity_60 =
    Css.property "--tw-backdrop-opacity" "opacity(0.6)"


backdrop_opacity_70 : Css.Style
backdrop_opacity_70 =
    Css.property "--tw-backdrop-opacity" "opacity(0.7)"


backdrop_opacity_75 : Css.Style
backdrop_opacity_75 =
    Css.property "--tw-backdrop-opacity" "opacity(0.75)"


backdrop_opacity_80 : Css.Style
backdrop_opacity_80 =
    Css.property "--tw-backdrop-opacity" "opacity(0.8)"


backdrop_opacity_90 : Css.Style
backdrop_opacity_90 =
    Css.property "--tw-backdrop-opacity" "opacity(0.9)"


backdrop_opacity_95 : Css.Style
backdrop_opacity_95 =
    Css.property "--tw-backdrop-opacity" "opacity(0.95)"


backdrop_saturate_0 : Css.Style
backdrop_saturate_0 =
    Css.property "--tw-backdrop-saturate" "saturate(0)"


backdrop_saturate_100 : Css.Style
backdrop_saturate_100 =
    Css.property "--tw-backdrop-saturate" "saturate(1)"


backdrop_saturate_150 : Css.Style
backdrop_saturate_150 =
    Css.property "--tw-backdrop-saturate" "saturate(1.5)"


backdrop_saturate_200 : Css.Style
backdrop_saturate_200 =
    Css.property "--tw-backdrop-saturate" "saturate(2)"


backdrop_saturate_50 : Css.Style
backdrop_saturate_50 =
    Css.property "--tw-backdrop-saturate" "saturate(.5)"


backdrop_sepia : Css.Style
backdrop_sepia =
    Css.property "--tw-backdrop-sepia" "sepia(100%)"


backdrop_sepia_0 : Css.Style
backdrop_sepia_0 =
    Css.property "--tw-backdrop-sepia" "sepia(0)"


bg_auto : Css.Style
bg_auto =
    Css.property "background-size" "auto"


bg_black : Css.Style
bg_black =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(0, 0, 0, var(--tw-bg-opacity))"
        ]


bg_blend_color : Css.Style
bg_blend_color =
    Css.property "background-blend-mode" "color"


bg_blend_color_burn : Css.Style
bg_blend_color_burn =
    Css.property "background-blend-mode" "color-burn"


bg_blend_color_dodge : Css.Style
bg_blend_color_dodge =
    Css.property "background-blend-mode" "color-dodge"


bg_blend_darken : Css.Style
bg_blend_darken =
    Css.property "background-blend-mode" "darken"


bg_blend_difference : Css.Style
bg_blend_difference =
    Css.property "background-blend-mode" "difference"


bg_blend_exclusion : Css.Style
bg_blend_exclusion =
    Css.property "background-blend-mode" "exclusion"


bg_blend_hard_light : Css.Style
bg_blend_hard_light =
    Css.property "background-blend-mode" "hard-light"


bg_blend_hue : Css.Style
bg_blend_hue =
    Css.property "background-blend-mode" "hue"


bg_blend_lighten : Css.Style
bg_blend_lighten =
    Css.property "background-blend-mode" "lighten"


bg_blend_luminosity : Css.Style
bg_blend_luminosity =
    Css.property "background-blend-mode" "luminosity"


bg_blend_multiply : Css.Style
bg_blend_multiply =
    Css.property "background-blend-mode" "multiply"


bg_blend_normal : Css.Style
bg_blend_normal =
    Css.property "background-blend-mode" "normal"


bg_blend_overlay : Css.Style
bg_blend_overlay =
    Css.property "background-blend-mode" "overlay"


bg_blend_saturation : Css.Style
bg_blend_saturation =
    Css.property "background-blend-mode" "saturation"


bg_blend_screen : Css.Style
bg_blend_screen =
    Css.property "background-blend-mode" "screen"


bg_blend_soft_light : Css.Style
bg_blend_soft_light =
    Css.property "background-blend-mode" "soft-light"


bg_blue_100 : Css.Style
bg_blue_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(219, 234, 254, var(--tw-bg-opacity))"
        ]


bg_blue_200 : Css.Style
bg_blue_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(191, 219, 254, var(--tw-bg-opacity))"
        ]


bg_blue_300 : Css.Style
bg_blue_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(147, 197, 253, var(--tw-bg-opacity))"
        ]


bg_blue_400 : Css.Style
bg_blue_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(96, 165, 250, var(--tw-bg-opacity))"
        ]


bg_blue_50 : Css.Style
bg_blue_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(239, 246, 255, var(--tw-bg-opacity))"
        ]


bg_blue_500 : Css.Style
bg_blue_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(59, 130, 246, var(--tw-bg-opacity))"
        ]


bg_blue_600 : Css.Style
bg_blue_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(37, 99, 235, var(--tw-bg-opacity))"
        ]


bg_blue_700 : Css.Style
bg_blue_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(29, 78, 216, var(--tw-bg-opacity))"
        ]


bg_blue_800 : Css.Style
bg_blue_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(30, 64, 175, var(--tw-bg-opacity))"
        ]


bg_blue_900 : Css.Style
bg_blue_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(30, 58, 138, var(--tw-bg-opacity))"
        ]


bg_bottom : Css.Style
bg_bottom =
    Css.property "background-position" "bottom"


bg_center : Css.Style
bg_center =
    Css.property "background-position" "center"


bg_clip_border : Css.Style
bg_clip_border =
    Css.property "background-clip" "border-box"


bg_clip_content : Css.Style
bg_clip_content =
    Css.property "background-clip" "content-box"


bg_clip_padding : Css.Style
bg_clip_padding =
    Css.property "background-clip" "padding-box"


bg_clip_text : Css.Style
bg_clip_text =
    Css.property "background-clip" "text"


bg_contain : Css.Style
bg_contain =
    Css.property "background-size" "contain"


bg_cover : Css.Style
bg_cover =
    Css.property "background-size" "cover"


bg_current : Css.Style
bg_current =
    Css.property "background-color" "currentColor"


bg_fixed : Css.Style
bg_fixed =
    Css.property "background-attachment" "fixed"


bg_gradient_to_b : Css.Style
bg_gradient_to_b =
    Css.property "background-image" "linear-gradient(to bottom, var(--tw-gradient-stops))"


bg_gradient_to_bl : Css.Style
bg_gradient_to_bl =
    Css.property "background-image" "linear-gradient(to bottom left, var(--tw-gradient-stops))"


bg_gradient_to_br : Css.Style
bg_gradient_to_br =
    Css.property "background-image" "linear-gradient(to bottom right, var(--tw-gradient-stops))"


bg_gradient_to_l : Css.Style
bg_gradient_to_l =
    Css.property "background-image" "linear-gradient(to left, var(--tw-gradient-stops))"


bg_gradient_to_r : Css.Style
bg_gradient_to_r =
    Css.property "background-image" "linear-gradient(to right, var(--tw-gradient-stops))"


bg_gradient_to_t : Css.Style
bg_gradient_to_t =
    Css.property "background-image" "linear-gradient(to top, var(--tw-gradient-stops))"


bg_gradient_to_tl : Css.Style
bg_gradient_to_tl =
    Css.property "background-image" "linear-gradient(to top left, var(--tw-gradient-stops))"


bg_gradient_to_tr : Css.Style
bg_gradient_to_tr =
    Css.property "background-image" "linear-gradient(to top right, var(--tw-gradient-stops))"


bg_gray_100 : Css.Style
bg_gray_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(243, 244, 246, var(--tw-bg-opacity))"
        ]


bg_gray_200 : Css.Style
bg_gray_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(229, 231, 235, var(--tw-bg-opacity))"
        ]


bg_gray_300 : Css.Style
bg_gray_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(209, 213, 219, var(--tw-bg-opacity))"
        ]


bg_gray_400 : Css.Style
bg_gray_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(156, 163, 175, var(--tw-bg-opacity))"
        ]


bg_gray_50 : Css.Style
bg_gray_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(249, 250, 251, var(--tw-bg-opacity))"
        ]


bg_gray_500 : Css.Style
bg_gray_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(107, 114, 128, var(--tw-bg-opacity))"
        ]


bg_gray_600 : Css.Style
bg_gray_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(75, 85, 99, var(--tw-bg-opacity))"
        ]


bg_gray_700 : Css.Style
bg_gray_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(55, 65, 81, var(--tw-bg-opacity))"
        ]


bg_gray_800 : Css.Style
bg_gray_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(31, 41, 55, var(--tw-bg-opacity))"
        ]


bg_gray_900 : Css.Style
bg_gray_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(17, 24, 39, var(--tw-bg-opacity))"
        ]


bg_green_100 : Css.Style
bg_green_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(209, 250, 229, var(--tw-bg-opacity))"
        ]


bg_green_200 : Css.Style
bg_green_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(167, 243, 208, var(--tw-bg-opacity))"
        ]


bg_green_300 : Css.Style
bg_green_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(110, 231, 183, var(--tw-bg-opacity))"
        ]


bg_green_400 : Css.Style
bg_green_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(52, 211, 153, var(--tw-bg-opacity))"
        ]


bg_green_50 : Css.Style
bg_green_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(236, 253, 245, var(--tw-bg-opacity))"
        ]


bg_green_500 : Css.Style
bg_green_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(16, 185, 129, var(--tw-bg-opacity))"
        ]


bg_green_600 : Css.Style
bg_green_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(5, 150, 105, var(--tw-bg-opacity))"
        ]


bg_green_700 : Css.Style
bg_green_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(4, 120, 87, var(--tw-bg-opacity))"
        ]


bg_green_800 : Css.Style
bg_green_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(6, 95, 70, var(--tw-bg-opacity))"
        ]


bg_green_900 : Css.Style
bg_green_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(6, 78, 59, var(--tw-bg-opacity))"
        ]


bg_indigo_100 : Css.Style
bg_indigo_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(224, 231, 255, var(--tw-bg-opacity))"
        ]


bg_indigo_200 : Css.Style
bg_indigo_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(199, 210, 254, var(--tw-bg-opacity))"
        ]


bg_indigo_300 : Css.Style
bg_indigo_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(165, 180, 252, var(--tw-bg-opacity))"
        ]


bg_indigo_400 : Css.Style
bg_indigo_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(129, 140, 248, var(--tw-bg-opacity))"
        ]


bg_indigo_50 : Css.Style
bg_indigo_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(238, 242, 255, var(--tw-bg-opacity))"
        ]


bg_indigo_500 : Css.Style
bg_indigo_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(99, 102, 241, var(--tw-bg-opacity))"
        ]


bg_indigo_600 : Css.Style
bg_indigo_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(79, 70, 229, var(--tw-bg-opacity))"
        ]


bg_indigo_700 : Css.Style
bg_indigo_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(67, 56, 202, var(--tw-bg-opacity))"
        ]


bg_indigo_800 : Css.Style
bg_indigo_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(55, 48, 163, var(--tw-bg-opacity))"
        ]


bg_indigo_900 : Css.Style
bg_indigo_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(49, 46, 129, var(--tw-bg-opacity))"
        ]


bg_left : Css.Style
bg_left =
    Css.property "background-position" "left"


bg_left_bottom : Css.Style
bg_left_bottom =
    Css.property "background-position" "left bottom"


bg_left_top : Css.Style
bg_left_top =
    Css.property "background-position" "left top"


bg_local : Css.Style
bg_local =
    Css.property "background-attachment" "local"


bg_no_repeat : Css.Style
bg_no_repeat =
    Css.property "background-repeat" "no-repeat"


bg_none : Css.Style
bg_none =
    Css.property "background-image" "none"


bg_opacity_0 : Css.Style
bg_opacity_0 =
    Css.property "--tw-bg-opacity" "0"


bg_opacity_10 : Css.Style
bg_opacity_10 =
    Css.property "--tw-bg-opacity" "0.1"


bg_opacity_100 : Css.Style
bg_opacity_100 =
    Css.property "--tw-bg-opacity" "1"


bg_opacity_20 : Css.Style
bg_opacity_20 =
    Css.property "--tw-bg-opacity" "0.2"


bg_opacity_25 : Css.Style
bg_opacity_25 =
    Css.property "--tw-bg-opacity" "0.25"


bg_opacity_30 : Css.Style
bg_opacity_30 =
    Css.property "--tw-bg-opacity" "0.3"


bg_opacity_40 : Css.Style
bg_opacity_40 =
    Css.property "--tw-bg-opacity" "0.4"


bg_opacity_5 : Css.Style
bg_opacity_5 =
    Css.property "--tw-bg-opacity" "0.05"


bg_opacity_50 : Css.Style
bg_opacity_50 =
    Css.property "--tw-bg-opacity" "0.5"


bg_opacity_60 : Css.Style
bg_opacity_60 =
    Css.property "--tw-bg-opacity" "0.6"


bg_opacity_70 : Css.Style
bg_opacity_70 =
    Css.property "--tw-bg-opacity" "0.7"


bg_opacity_75 : Css.Style
bg_opacity_75 =
    Css.property "--tw-bg-opacity" "0.75"


bg_opacity_80 : Css.Style
bg_opacity_80 =
    Css.property "--tw-bg-opacity" "0.8"


bg_opacity_90 : Css.Style
bg_opacity_90 =
    Css.property "--tw-bg-opacity" "0.9"


bg_opacity_95 : Css.Style
bg_opacity_95 =
    Css.property "--tw-bg-opacity" "0.95"


bg_origin_border : Css.Style
bg_origin_border =
    Css.property "background-origin" "border-box"


bg_origin_content : Css.Style
bg_origin_content =
    Css.property "background-origin" "content-box"


bg_origin_padding : Css.Style
bg_origin_padding =
    Css.property "background-origin" "padding-box"


bg_pink_100 : Css.Style
bg_pink_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(252, 231, 243, var(--tw-bg-opacity))"
        ]


bg_pink_200 : Css.Style
bg_pink_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(251, 207, 232, var(--tw-bg-opacity))"
        ]


bg_pink_300 : Css.Style
bg_pink_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(249, 168, 212, var(--tw-bg-opacity))"
        ]


bg_pink_400 : Css.Style
bg_pink_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(244, 114, 182, var(--tw-bg-opacity))"
        ]


bg_pink_50 : Css.Style
bg_pink_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(253, 242, 248, var(--tw-bg-opacity))"
        ]


bg_pink_500 : Css.Style
bg_pink_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(236, 72, 153, var(--tw-bg-opacity))"
        ]


bg_pink_600 : Css.Style
bg_pink_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(219, 39, 119, var(--tw-bg-opacity))"
        ]


bg_pink_700 : Css.Style
bg_pink_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(190, 24, 93, var(--tw-bg-opacity))"
        ]


bg_pink_800 : Css.Style
bg_pink_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(157, 23, 77, var(--tw-bg-opacity))"
        ]


bg_pink_900 : Css.Style
bg_pink_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(131, 24, 67, var(--tw-bg-opacity))"
        ]


bg_purple_100 : Css.Style
bg_purple_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(237, 233, 254, var(--tw-bg-opacity))"
        ]


bg_purple_200 : Css.Style
bg_purple_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(221, 214, 254, var(--tw-bg-opacity))"
        ]


bg_purple_300 : Css.Style
bg_purple_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(196, 181, 253, var(--tw-bg-opacity))"
        ]


bg_purple_400 : Css.Style
bg_purple_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(167, 139, 250, var(--tw-bg-opacity))"
        ]


bg_purple_50 : Css.Style
bg_purple_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(245, 243, 255, var(--tw-bg-opacity))"
        ]


bg_purple_500 : Css.Style
bg_purple_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(139, 92, 246, var(--tw-bg-opacity))"
        ]


bg_purple_600 : Css.Style
bg_purple_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(124, 58, 237, var(--tw-bg-opacity))"
        ]


bg_purple_700 : Css.Style
bg_purple_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(109, 40, 217, var(--tw-bg-opacity))"
        ]


bg_purple_800 : Css.Style
bg_purple_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(91, 33, 182, var(--tw-bg-opacity))"
        ]


bg_purple_900 : Css.Style
bg_purple_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(76, 29, 149, var(--tw-bg-opacity))"
        ]


bg_red_100 : Css.Style
bg_red_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(254, 226, 226, var(--tw-bg-opacity))"
        ]


bg_red_200 : Css.Style
bg_red_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(254, 202, 202, var(--tw-bg-opacity))"
        ]


bg_red_300 : Css.Style
bg_red_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(252, 165, 165, var(--tw-bg-opacity))"
        ]


bg_red_400 : Css.Style
bg_red_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(248, 113, 113, var(--tw-bg-opacity))"
        ]


bg_red_50 : Css.Style
bg_red_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(254, 242, 242, var(--tw-bg-opacity))"
        ]


bg_red_500 : Css.Style
bg_red_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(239, 68, 68, var(--tw-bg-opacity))"
        ]


bg_red_600 : Css.Style
bg_red_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(220, 38, 38, var(--tw-bg-opacity))"
        ]


bg_red_700 : Css.Style
bg_red_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(185, 28, 28, var(--tw-bg-opacity))"
        ]


bg_red_800 : Css.Style
bg_red_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(153, 27, 27, var(--tw-bg-opacity))"
        ]


bg_red_900 : Css.Style
bg_red_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(127, 29, 29, var(--tw-bg-opacity))"
        ]


bg_repeat : Css.Style
bg_repeat =
    Css.property "background-repeat" "repeat"


bg_repeat_round : Css.Style
bg_repeat_round =
    Css.property "background-repeat" "round"


bg_repeat_space : Css.Style
bg_repeat_space =
    Css.property "background-repeat" "space"


bg_repeat_x : Css.Style
bg_repeat_x =
    Css.property "background-repeat" "repeat-x"


bg_repeat_y : Css.Style
bg_repeat_y =
    Css.property "background-repeat" "repeat-y"


bg_right : Css.Style
bg_right =
    Css.property "background-position" "right"


bg_right_bottom : Css.Style
bg_right_bottom =
    Css.property "background-position" "right bottom"


bg_right_top : Css.Style
bg_right_top =
    Css.property "background-position" "right top"


bg_scroll : Css.Style
bg_scroll =
    Css.property "background-attachment" "scroll"


bg_top : Css.Style
bg_top =
    Css.property "background-position" "top"


bg_transparent : Css.Style
bg_transparent =
    Css.property "background-color" "transparent"


bg_white : Css.Style
bg_white =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(255, 255, 255, var(--tw-bg-opacity))"
        ]


bg_yellow_100 : Css.Style
bg_yellow_100 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(254, 243, 199, var(--tw-bg-opacity))"
        ]


bg_yellow_200 : Css.Style
bg_yellow_200 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(253, 230, 138, var(--tw-bg-opacity))"
        ]


bg_yellow_300 : Css.Style
bg_yellow_300 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(252, 211, 77, var(--tw-bg-opacity))"
        ]


bg_yellow_400 : Css.Style
bg_yellow_400 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(251, 191, 36, var(--tw-bg-opacity))"
        ]


bg_yellow_50 : Css.Style
bg_yellow_50 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(255, 251, 235, var(--tw-bg-opacity))"
        ]


bg_yellow_500 : Css.Style
bg_yellow_500 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(245, 158, 11, var(--tw-bg-opacity))"
        ]


bg_yellow_600 : Css.Style
bg_yellow_600 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(217, 119, 6, var(--tw-bg-opacity))"
        ]


bg_yellow_700 : Css.Style
bg_yellow_700 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(180, 83, 9, var(--tw-bg-opacity))"
        ]


bg_yellow_800 : Css.Style
bg_yellow_800 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(146, 64, 14, var(--tw-bg-opacity))"
        ]


bg_yellow_900 : Css.Style
bg_yellow_900 =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" "rgba(120, 53, 15, var(--tw-bg-opacity))"
        ]


block : Css.Style
block =
    Css.property "display" "block"


blur : Css.Style
blur =
    Css.property "--tw-blur" "blur(8px)"


blur_0 : Css.Style
blur_0 =
    Css.property "--tw-blur" "blur(0)"


blur_2xl : Css.Style
blur_2xl =
    Css.property "--tw-blur" "blur(40px)"


blur_3xl : Css.Style
blur_3xl =
    Css.property "--tw-blur" "blur(64px)"


blur_lg : Css.Style
blur_lg =
    Css.property "--tw-blur" "blur(16px)"


blur_md : Css.Style
blur_md =
    Css.property "--tw-blur" "blur(12px)"


blur_none : Css.Style
blur_none =
    Css.property "--tw-blur" "blur(0)"


blur_sm : Css.Style
blur_sm =
    Css.property "--tw-blur" "blur(4px)"


blur_xl : Css.Style
blur_xl =
    Css.property "--tw-blur" "blur(24px)"


border : Css.Style
border =
    Css.property "border-width" "1px"


border_0 : Css.Style
border_0 =
    Css.property "border-width" "0px"


border_2 : Css.Style
border_2 =
    Css.property "border-width" "2px"


border_4 : Css.Style
border_4 =
    Css.property "border-width" "4px"


border_8 : Css.Style
border_8 =
    Css.property "border-width" "8px"


border_b : Css.Style
border_b =
    Css.property "border-bottom-width" "1px"


border_b_0 : Css.Style
border_b_0 =
    Css.property "border-bottom-width" "0px"


border_b_2 : Css.Style
border_b_2 =
    Css.property "border-bottom-width" "2px"


border_b_4 : Css.Style
border_b_4 =
    Css.property "border-bottom-width" "4px"


border_b_8 : Css.Style
border_b_8 =
    Css.property "border-bottom-width" "8px"


border_black : Css.Style
border_black =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(0, 0, 0, var(--tw-border-opacity))"
        ]


border_blue_100 : Css.Style
border_blue_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(219, 234, 254, var(--tw-border-opacity))"
        ]


border_blue_200 : Css.Style
border_blue_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(191, 219, 254, var(--tw-border-opacity))"
        ]


border_blue_300 : Css.Style
border_blue_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(147, 197, 253, var(--tw-border-opacity))"
        ]


border_blue_400 : Css.Style
border_blue_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(96, 165, 250, var(--tw-border-opacity))"
        ]


border_blue_50 : Css.Style
border_blue_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(239, 246, 255, var(--tw-border-opacity))"
        ]


border_blue_500 : Css.Style
border_blue_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(59, 130, 246, var(--tw-border-opacity))"
        ]


border_blue_600 : Css.Style
border_blue_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(37, 99, 235, var(--tw-border-opacity))"
        ]


border_blue_700 : Css.Style
border_blue_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(29, 78, 216, var(--tw-border-opacity))"
        ]


border_blue_800 : Css.Style
border_blue_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(30, 64, 175, var(--tw-border-opacity))"
        ]


border_blue_900 : Css.Style
border_blue_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(30, 58, 138, var(--tw-border-opacity))"
        ]


border_collapse : Css.Style
border_collapse =
    Css.property "border-collapse" "collapse"


border_current : Css.Style
border_current =
    Css.property "border-color" "currentColor"


border_dashed : Css.Style
border_dashed =
    Css.property "border-style" "dashed"


border_dotted : Css.Style
border_dotted =
    Css.property "border-style" "dotted"


border_double : Css.Style
border_double =
    Css.property "border-style" "double"


border_gray_100 : Css.Style
border_gray_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(243, 244, 246, var(--tw-border-opacity))"
        ]


border_gray_200 : Css.Style
border_gray_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(229, 231, 235, var(--tw-border-opacity))"
        ]


border_gray_300 : Css.Style
border_gray_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(209, 213, 219, var(--tw-border-opacity))"
        ]


border_gray_400 : Css.Style
border_gray_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(156, 163, 175, var(--tw-border-opacity))"
        ]


border_gray_50 : Css.Style
border_gray_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(249, 250, 251, var(--tw-border-opacity))"
        ]


border_gray_500 : Css.Style
border_gray_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(107, 114, 128, var(--tw-border-opacity))"
        ]


border_gray_600 : Css.Style
border_gray_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(75, 85, 99, var(--tw-border-opacity))"
        ]


border_gray_700 : Css.Style
border_gray_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(55, 65, 81, var(--tw-border-opacity))"
        ]


border_gray_800 : Css.Style
border_gray_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(31, 41, 55, var(--tw-border-opacity))"
        ]


border_gray_900 : Css.Style
border_gray_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(17, 24, 39, var(--tw-border-opacity))"
        ]


border_green_100 : Css.Style
border_green_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(209, 250, 229, var(--tw-border-opacity))"
        ]


border_green_200 : Css.Style
border_green_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(167, 243, 208, var(--tw-border-opacity))"
        ]


border_green_300 : Css.Style
border_green_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(110, 231, 183, var(--tw-border-opacity))"
        ]


border_green_400 : Css.Style
border_green_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(52, 211, 153, var(--tw-border-opacity))"
        ]


border_green_50 : Css.Style
border_green_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(236, 253, 245, var(--tw-border-opacity))"
        ]


border_green_500 : Css.Style
border_green_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(16, 185, 129, var(--tw-border-opacity))"
        ]


border_green_600 : Css.Style
border_green_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(5, 150, 105, var(--tw-border-opacity))"
        ]


border_green_700 : Css.Style
border_green_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(4, 120, 87, var(--tw-border-opacity))"
        ]


border_green_800 : Css.Style
border_green_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(6, 95, 70, var(--tw-border-opacity))"
        ]


border_green_900 : Css.Style
border_green_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(6, 78, 59, var(--tw-border-opacity))"
        ]


border_indigo_100 : Css.Style
border_indigo_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(224, 231, 255, var(--tw-border-opacity))"
        ]


border_indigo_200 : Css.Style
border_indigo_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(199, 210, 254, var(--tw-border-opacity))"
        ]


border_indigo_300 : Css.Style
border_indigo_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(165, 180, 252, var(--tw-border-opacity))"
        ]


border_indigo_400 : Css.Style
border_indigo_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(129, 140, 248, var(--tw-border-opacity))"
        ]


border_indigo_50 : Css.Style
border_indigo_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(238, 242, 255, var(--tw-border-opacity))"
        ]


border_indigo_500 : Css.Style
border_indigo_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(99, 102, 241, var(--tw-border-opacity))"
        ]


border_indigo_600 : Css.Style
border_indigo_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(79, 70, 229, var(--tw-border-opacity))"
        ]


border_indigo_700 : Css.Style
border_indigo_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(67, 56, 202, var(--tw-border-opacity))"
        ]


border_indigo_800 : Css.Style
border_indigo_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(55, 48, 163, var(--tw-border-opacity))"
        ]


border_indigo_900 : Css.Style
border_indigo_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(49, 46, 129, var(--tw-border-opacity))"
        ]


border_l : Css.Style
border_l =
    Css.property "border-left-width" "1px"


border_l_0 : Css.Style
border_l_0 =
    Css.property "border-left-width" "0px"


border_l_2 : Css.Style
border_l_2 =
    Css.property "border-left-width" "2px"


border_l_4 : Css.Style
border_l_4 =
    Css.property "border-left-width" "4px"


border_l_8 : Css.Style
border_l_8 =
    Css.property "border-left-width" "8px"


border_none : Css.Style
border_none =
    Css.property "border-style" "none"


border_opacity_0 : Css.Style
border_opacity_0 =
    Css.property "--tw-border-opacity" "0"


border_opacity_10 : Css.Style
border_opacity_10 =
    Css.property "--tw-border-opacity" "0.1"


border_opacity_100 : Css.Style
border_opacity_100 =
    Css.property "--tw-border-opacity" "1"


border_opacity_20 : Css.Style
border_opacity_20 =
    Css.property "--tw-border-opacity" "0.2"


border_opacity_25 : Css.Style
border_opacity_25 =
    Css.property "--tw-border-opacity" "0.25"


border_opacity_30 : Css.Style
border_opacity_30 =
    Css.property "--tw-border-opacity" "0.3"


border_opacity_40 : Css.Style
border_opacity_40 =
    Css.property "--tw-border-opacity" "0.4"


border_opacity_5 : Css.Style
border_opacity_5 =
    Css.property "--tw-border-opacity" "0.05"


border_opacity_50 : Css.Style
border_opacity_50 =
    Css.property "--tw-border-opacity" "0.5"


border_opacity_60 : Css.Style
border_opacity_60 =
    Css.property "--tw-border-opacity" "0.6"


border_opacity_70 : Css.Style
border_opacity_70 =
    Css.property "--tw-border-opacity" "0.7"


border_opacity_75 : Css.Style
border_opacity_75 =
    Css.property "--tw-border-opacity" "0.75"


border_opacity_80 : Css.Style
border_opacity_80 =
    Css.property "--tw-border-opacity" "0.8"


border_opacity_90 : Css.Style
border_opacity_90 =
    Css.property "--tw-border-opacity" "0.9"


border_opacity_95 : Css.Style
border_opacity_95 =
    Css.property "--tw-border-opacity" "0.95"


border_pink_100 : Css.Style
border_pink_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(252, 231, 243, var(--tw-border-opacity))"
        ]


border_pink_200 : Css.Style
border_pink_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(251, 207, 232, var(--tw-border-opacity))"
        ]


border_pink_300 : Css.Style
border_pink_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(249, 168, 212, var(--tw-border-opacity))"
        ]


border_pink_400 : Css.Style
border_pink_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(244, 114, 182, var(--tw-border-opacity))"
        ]


border_pink_50 : Css.Style
border_pink_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(253, 242, 248, var(--tw-border-opacity))"
        ]


border_pink_500 : Css.Style
border_pink_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(236, 72, 153, var(--tw-border-opacity))"
        ]


border_pink_600 : Css.Style
border_pink_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(219, 39, 119, var(--tw-border-opacity))"
        ]


border_pink_700 : Css.Style
border_pink_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(190, 24, 93, var(--tw-border-opacity))"
        ]


border_pink_800 : Css.Style
border_pink_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(157, 23, 77, var(--tw-border-opacity))"
        ]


border_pink_900 : Css.Style
border_pink_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(131, 24, 67, var(--tw-border-opacity))"
        ]


border_purple_100 : Css.Style
border_purple_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(237, 233, 254, var(--tw-border-opacity))"
        ]


border_purple_200 : Css.Style
border_purple_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(221, 214, 254, var(--tw-border-opacity))"
        ]


border_purple_300 : Css.Style
border_purple_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(196, 181, 253, var(--tw-border-opacity))"
        ]


border_purple_400 : Css.Style
border_purple_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(167, 139, 250, var(--tw-border-opacity))"
        ]


border_purple_50 : Css.Style
border_purple_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(245, 243, 255, var(--tw-border-opacity))"
        ]


border_purple_500 : Css.Style
border_purple_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(139, 92, 246, var(--tw-border-opacity))"
        ]


border_purple_600 : Css.Style
border_purple_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(124, 58, 237, var(--tw-border-opacity))"
        ]


border_purple_700 : Css.Style
border_purple_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(109, 40, 217, var(--tw-border-opacity))"
        ]


border_purple_800 : Css.Style
border_purple_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(91, 33, 182, var(--tw-border-opacity))"
        ]


border_purple_900 : Css.Style
border_purple_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(76, 29, 149, var(--tw-border-opacity))"
        ]


border_r : Css.Style
border_r =
    Css.property "border-right-width" "1px"


border_r_0 : Css.Style
border_r_0 =
    Css.property "border-right-width" "0px"


border_r_2 : Css.Style
border_r_2 =
    Css.property "border-right-width" "2px"


border_r_4 : Css.Style
border_r_4 =
    Css.property "border-right-width" "4px"


border_r_8 : Css.Style
border_r_8 =
    Css.property "border-right-width" "8px"


border_red_100 : Css.Style
border_red_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(254, 226, 226, var(--tw-border-opacity))"
        ]


border_red_200 : Css.Style
border_red_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(254, 202, 202, var(--tw-border-opacity))"
        ]


border_red_300 : Css.Style
border_red_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(252, 165, 165, var(--tw-border-opacity))"
        ]


border_red_400 : Css.Style
border_red_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(248, 113, 113, var(--tw-border-opacity))"
        ]


border_red_50 : Css.Style
border_red_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(254, 242, 242, var(--tw-border-opacity))"
        ]


border_red_500 : Css.Style
border_red_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(239, 68, 68, var(--tw-border-opacity))"
        ]


border_red_600 : Css.Style
border_red_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(220, 38, 38, var(--tw-border-opacity))"
        ]


border_red_700 : Css.Style
border_red_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(185, 28, 28, var(--tw-border-opacity))"
        ]


border_red_800 : Css.Style
border_red_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(153, 27, 27, var(--tw-border-opacity))"
        ]


border_red_900 : Css.Style
border_red_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(127, 29, 29, var(--tw-border-opacity))"
        ]


border_separate : Css.Style
border_separate =
    Css.property "border-collapse" "separate"


border_solid : Css.Style
border_solid =
    Css.property "border-style" "solid"


border_t : Css.Style
border_t =
    Css.property "border-top-width" "1px"


border_t_0 : Css.Style
border_t_0 =
    Css.property "border-top-width" "0px"


border_t_2 : Css.Style
border_t_2 =
    Css.property "border-top-width" "2px"


border_t_4 : Css.Style
border_t_4 =
    Css.property "border-top-width" "4px"


border_t_8 : Css.Style
border_t_8 =
    Css.property "border-top-width" "8px"


border_transparent : Css.Style
border_transparent =
    Css.property "border-color" "transparent"


border_white : Css.Style
border_white =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(255, 255, 255, var(--tw-border-opacity))"
        ]


border_yellow_100 : Css.Style
border_yellow_100 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(254, 243, 199, var(--tw-border-opacity))"
        ]


border_yellow_200 : Css.Style
border_yellow_200 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(253, 230, 138, var(--tw-border-opacity))"
        ]


border_yellow_300 : Css.Style
border_yellow_300 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(252, 211, 77, var(--tw-border-opacity))"
        ]


border_yellow_400 : Css.Style
border_yellow_400 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(251, 191, 36, var(--tw-border-opacity))"
        ]


border_yellow_50 : Css.Style
border_yellow_50 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(255, 251, 235, var(--tw-border-opacity))"
        ]


border_yellow_500 : Css.Style
border_yellow_500 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(245, 158, 11, var(--tw-border-opacity))"
        ]


border_yellow_600 : Css.Style
border_yellow_600 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(217, 119, 6, var(--tw-border-opacity))"
        ]


border_yellow_700 : Css.Style
border_yellow_700 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(180, 83, 9, var(--tw-border-opacity))"
        ]


border_yellow_800 : Css.Style
border_yellow_800 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(146, 64, 14, var(--tw-border-opacity))"
        ]


border_yellow_900 : Css.Style
border_yellow_900 =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" "rgba(120, 53, 15, var(--tw-border-opacity))"
        ]


bottom_0 : Css.Style
bottom_0 =
    Css.property "bottom" "0px"


bottom_0_dot_5 : Css.Style
bottom_0_dot_5 =
    Css.property "bottom" "0.125rem"


bottom_1 : Css.Style
bottom_1 =
    Css.property "bottom" "0.25rem"


bottom_10 : Css.Style
bottom_10 =
    Css.property "bottom" "2.5rem"


bottom_11 : Css.Style
bottom_11 =
    Css.property "bottom" "2.75rem"


bottom_12 : Css.Style
bottom_12 =
    Css.property "bottom" "3rem"


bottom_14 : Css.Style
bottom_14 =
    Css.property "bottom" "3.5rem"


bottom_16 : Css.Style
bottom_16 =
    Css.property "bottom" "4rem"


bottom_1_dot_5 : Css.Style
bottom_1_dot_5 =
    Css.property "bottom" "0.375rem"


bottom_1over2 : Css.Style
bottom_1over2 =
    Css.property "bottom" "50%"


bottom_1over3 : Css.Style
bottom_1over3 =
    Css.property "bottom" "33.333333%"


bottom_1over4 : Css.Style
bottom_1over4 =
    Css.property "bottom" "25%"


bottom_2 : Css.Style
bottom_2 =
    Css.property "bottom" "0.5rem"


bottom_20 : Css.Style
bottom_20 =
    Css.property "bottom" "5rem"


bottom_24 : Css.Style
bottom_24 =
    Css.property "bottom" "6rem"


bottom_28 : Css.Style
bottom_28 =
    Css.property "bottom" "7rem"


bottom_2_dot_5 : Css.Style
bottom_2_dot_5 =
    Css.property "bottom" "0.625rem"


bottom_2over3 : Css.Style
bottom_2over3 =
    Css.property "bottom" "66.666667%"


bottom_2over4 : Css.Style
bottom_2over4 =
    Css.property "bottom" "50%"


bottom_3 : Css.Style
bottom_3 =
    Css.property "bottom" "0.75rem"


bottom_32 : Css.Style
bottom_32 =
    Css.property "bottom" "8rem"


bottom_36 : Css.Style
bottom_36 =
    Css.property "bottom" "9rem"


bottom_3_dot_5 : Css.Style
bottom_3_dot_5 =
    Css.property "bottom" "0.875rem"


bottom_3over4 : Css.Style
bottom_3over4 =
    Css.property "bottom" "75%"


bottom_4 : Css.Style
bottom_4 =
    Css.property "bottom" "1rem"


bottom_40 : Css.Style
bottom_40 =
    Css.property "bottom" "10rem"


bottom_44 : Css.Style
bottom_44 =
    Css.property "bottom" "11rem"


bottom_48 : Css.Style
bottom_48 =
    Css.property "bottom" "12rem"


bottom_5 : Css.Style
bottom_5 =
    Css.property "bottom" "1.25rem"


bottom_52 : Css.Style
bottom_52 =
    Css.property "bottom" "13rem"


bottom_56 : Css.Style
bottom_56 =
    Css.property "bottom" "14rem"


bottom_6 : Css.Style
bottom_6 =
    Css.property "bottom" "1.5rem"


bottom_60 : Css.Style
bottom_60 =
    Css.property "bottom" "15rem"


bottom_64 : Css.Style
bottom_64 =
    Css.property "bottom" "16rem"


bottom_7 : Css.Style
bottom_7 =
    Css.property "bottom" "1.75rem"


bottom_72 : Css.Style
bottom_72 =
    Css.property "bottom" "18rem"


bottom_8 : Css.Style
bottom_8 =
    Css.property "bottom" "2rem"


bottom_80 : Css.Style
bottom_80 =
    Css.property "bottom" "20rem"


bottom_9 : Css.Style
bottom_9 =
    Css.property "bottom" "2.25rem"


bottom_96 : Css.Style
bottom_96 =
    Css.property "bottom" "24rem"


bottom_auto : Css.Style
bottom_auto =
    Css.property "bottom" "auto"


bottom_full : Css.Style
bottom_full =
    Css.property "bottom" "100%"


bottom_px : Css.Style
bottom_px =
    Css.property "bottom" "1px"


box_border : Css.Style
box_border =
    Css.property "box-sizing" "border-box"


box_content : Css.Style
box_content =
    Css.property "box-sizing" "content-box"


break_all : Css.Style
break_all =
    Css.property "word-break" "break-all"


break_normal : Css.Style
break_normal =
    Css.batch
        [ Css.property "overflow-wrap" "normal"
        , Css.property "word-break" "normal"
        ]


break_words : Css.Style
break_words =
    Css.property "overflow-wrap" "break-word"


brightness_0 : Css.Style
brightness_0 =
    Css.property "--tw-brightness" "brightness(0)"


brightness_100 : Css.Style
brightness_100 =
    Css.property "--tw-brightness" "brightness(1)"


brightness_105 : Css.Style
brightness_105 =
    Css.property "--tw-brightness" "brightness(1.05)"


brightness_110 : Css.Style
brightness_110 =
    Css.property "--tw-brightness" "brightness(1.1)"


brightness_125 : Css.Style
brightness_125 =
    Css.property "--tw-brightness" "brightness(1.25)"


brightness_150 : Css.Style
brightness_150 =
    Css.property "--tw-brightness" "brightness(1.5)"


brightness_200 : Css.Style
brightness_200 =
    Css.property "--tw-brightness" "brightness(2)"


brightness_50 : Css.Style
brightness_50 =
    Css.property "--tw-brightness" "brightness(.5)"


brightness_75 : Css.Style
brightness_75 =
    Css.property "--tw-brightness" "brightness(.75)"


brightness_90 : Css.Style
brightness_90 =
    Css.property "--tw-brightness" "brightness(.9)"


brightness_95 : Css.Style
brightness_95 =
    Css.property "--tw-brightness" "brightness(.95)"


capitalize : Css.Style
capitalize =
    Css.property "text-transform" "capitalize"


clear_both : Css.Style
clear_both =
    Css.property "clear" "both"


clear_left : Css.Style
clear_left =
    Css.property "clear" "left"


clear_none : Css.Style
clear_none =
    Css.property "clear" "none"


clear_right : Css.Style
clear_right =
    Css.property "clear" "right"


col_auto : Css.Style
col_auto =
    Css.property "grid-column" "auto"


col_end_1 : Css.Style
col_end_1 =
    Css.property "grid-column-end" "1"


col_end_10 : Css.Style
col_end_10 =
    Css.property "grid-column-end" "10"


col_end_11 : Css.Style
col_end_11 =
    Css.property "grid-column-end" "11"


col_end_12 : Css.Style
col_end_12 =
    Css.property "grid-column-end" "12"


col_end_13 : Css.Style
col_end_13 =
    Css.property "grid-column-end" "13"


col_end_2 : Css.Style
col_end_2 =
    Css.property "grid-column-end" "2"


col_end_3 : Css.Style
col_end_3 =
    Css.property "grid-column-end" "3"


col_end_4 : Css.Style
col_end_4 =
    Css.property "grid-column-end" "4"


col_end_5 : Css.Style
col_end_5 =
    Css.property "grid-column-end" "5"


col_end_6 : Css.Style
col_end_6 =
    Css.property "grid-column-end" "6"


col_end_7 : Css.Style
col_end_7 =
    Css.property "grid-column-end" "7"


col_end_8 : Css.Style
col_end_8 =
    Css.property "grid-column-end" "8"


col_end_9 : Css.Style
col_end_9 =
    Css.property "grid-column-end" "9"


col_end_auto : Css.Style
col_end_auto =
    Css.property "grid-column-end" "auto"


col_span_1 : Css.Style
col_span_1 =
    Css.property "grid-column" "span 1 / span 1"


col_span_10 : Css.Style
col_span_10 =
    Css.property "grid-column" "span 10 / span 10"


col_span_11 : Css.Style
col_span_11 =
    Css.property "grid-column" "span 11 / span 11"


col_span_12 : Css.Style
col_span_12 =
    Css.property "grid-column" "span 12 / span 12"


col_span_2 : Css.Style
col_span_2 =
    Css.property "grid-column" "span 2 / span 2"


col_span_3 : Css.Style
col_span_3 =
    Css.property "grid-column" "span 3 / span 3"


col_span_4 : Css.Style
col_span_4 =
    Css.property "grid-column" "span 4 / span 4"


col_span_5 : Css.Style
col_span_5 =
    Css.property "grid-column" "span 5 / span 5"


col_span_6 : Css.Style
col_span_6 =
    Css.property "grid-column" "span 6 / span 6"


col_span_7 : Css.Style
col_span_7 =
    Css.property "grid-column" "span 7 / span 7"


col_span_8 : Css.Style
col_span_8 =
    Css.property "grid-column" "span 8 / span 8"


col_span_9 : Css.Style
col_span_9 =
    Css.property "grid-column" "span 9 / span 9"


col_span_full : Css.Style
col_span_full =
    Css.property "grid-column" "1 / -1"


col_start_1 : Css.Style
col_start_1 =
    Css.property "grid-column-start" "1"


col_start_10 : Css.Style
col_start_10 =
    Css.property "grid-column-start" "10"


col_start_11 : Css.Style
col_start_11 =
    Css.property "grid-column-start" "11"


col_start_12 : Css.Style
col_start_12 =
    Css.property "grid-column-start" "12"


col_start_13 : Css.Style
col_start_13 =
    Css.property "grid-column-start" "13"


col_start_2 : Css.Style
col_start_2 =
    Css.property "grid-column-start" "2"


col_start_3 : Css.Style
col_start_3 =
    Css.property "grid-column-start" "3"


col_start_4 : Css.Style
col_start_4 =
    Css.property "grid-column-start" "4"


col_start_5 : Css.Style
col_start_5 =
    Css.property "grid-column-start" "5"


col_start_6 : Css.Style
col_start_6 =
    Css.property "grid-column-start" "6"


col_start_7 : Css.Style
col_start_7 =
    Css.property "grid-column-start" "7"


col_start_8 : Css.Style
col_start_8 =
    Css.property "grid-column-start" "8"


col_start_9 : Css.Style
col_start_9 =
    Css.property "grid-column-start" "9"


col_start_auto : Css.Style
col_start_auto =
    Css.property "grid-column-start" "auto"


container : Css.Style
container =
    Css.batch
        [ Css.property "width" "100%"
        , Css.Media.withMediaQuery [ "(min-width: 1536px)" ]
            [ Css.property "max-width" "1536px"
            ]
        , Css.Media.withMediaQuery [ "(min-width: 1280px)" ]
            [ Css.property "max-width" "1280px"
            ]
        , Css.Media.withMediaQuery [ "(min-width: 1024px)" ]
            [ Css.property "max-width" "1024px"
            ]
        , Css.Media.withMediaQuery [ "(min-width: 768px)" ]
            [ Css.property "max-width" "768px"
            ]
        , Css.Media.withMediaQuery [ "(min-width: 640px)" ]
            [ Css.property "max-width" "640px"
            ]
        ]


content_around : Css.Style
content_around =
    Css.property "align-content" "space-around"


content_between : Css.Style
content_between =
    Css.property "align-content" "space-between"


content_center : Css.Style
content_center =
    Css.property "align-content" "center"


content_end : Css.Style
content_end =
    Css.property "align-content" "flex-end"


content_evenly : Css.Style
content_evenly =
    Css.property "align-content" "space-evenly"


content_start : Css.Style
content_start =
    Css.property "align-content" "flex-start"


contents : Css.Style
contents =
    Css.property "display" "contents"


contrast_0 : Css.Style
contrast_0 =
    Css.property "--tw-contrast" "contrast(0)"


contrast_100 : Css.Style
contrast_100 =
    Css.property "--tw-contrast" "contrast(1)"


contrast_125 : Css.Style
contrast_125 =
    Css.property "--tw-contrast" "contrast(1.25)"


contrast_150 : Css.Style
contrast_150 =
    Css.property "--tw-contrast" "contrast(1.5)"


contrast_200 : Css.Style
contrast_200 =
    Css.property "--tw-contrast" "contrast(2)"


contrast_50 : Css.Style
contrast_50 =
    Css.property "--tw-contrast" "contrast(.5)"


contrast_75 : Css.Style
contrast_75 =
    Css.property "--tw-contrast" "contrast(.75)"


cursor_auto : Css.Style
cursor_auto =
    Css.property "cursor" "auto"


cursor_default : Css.Style
cursor_default =
    Css.property "cursor" "default"


cursor_help : Css.Style
cursor_help =
    Css.property "cursor" "help"


cursor_move : Css.Style
cursor_move =
    Css.property "cursor" "move"


cursor_not_allowed : Css.Style
cursor_not_allowed =
    Css.property "cursor" "not-allowed"


cursor_pointer : Css.Style
cursor_pointer =
    Css.property "cursor" "pointer"


cursor_text : Css.Style
cursor_text =
    Css.property "cursor" "text"


cursor_wait : Css.Style
cursor_wait =
    Css.property "cursor" "wait"


decoration_clone : Css.Style
decoration_clone =
    Css.property "box-decoration-break" "clone"


decoration_slice : Css.Style
decoration_slice =
    Css.property "box-decoration-break" "slice"


delay_100 : Css.Style
delay_100 =
    Css.property "transition-delay" "100ms"


delay_1000 : Css.Style
delay_1000 =
    Css.property "transition-delay" "1000ms"


delay_150 : Css.Style
delay_150 =
    Css.property "transition-delay" "150ms"


delay_200 : Css.Style
delay_200 =
    Css.property "transition-delay" "200ms"


delay_300 : Css.Style
delay_300 =
    Css.property "transition-delay" "300ms"


delay_500 : Css.Style
delay_500 =
    Css.property "transition-delay" "500ms"


delay_700 : Css.Style
delay_700 =
    Css.property "transition-delay" "700ms"


delay_75 : Css.Style
delay_75 =
    Css.property "transition-delay" "75ms"


diagonal_fractions : Css.Style
diagonal_fractions =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-numeric-fraction" "diagonal-fractions"
        ]


divide_black : Css.Style
divide_black =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(0, 0, 0, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_100 : Css.Style
divide_blue_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(219, 234, 254, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_200 : Css.Style
divide_blue_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(191, 219, 254, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_300 : Css.Style
divide_blue_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(147, 197, 253, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_400 : Css.Style
divide_blue_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(96, 165, 250, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_50 : Css.Style
divide_blue_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(239, 246, 255, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_500 : Css.Style
divide_blue_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(59, 130, 246, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_600 : Css.Style
divide_blue_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(37, 99, 235, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_700 : Css.Style
divide_blue_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(29, 78, 216, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_800 : Css.Style
divide_blue_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(30, 64, 175, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_blue_900 : Css.Style
divide_blue_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(30, 58, 138, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_current : Css.Style
divide_current =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-color" "currentColor"
                ]
            ]
        ]


divide_dashed : Css.Style
divide_dashed =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-style" "dashed"
                ]
            ]
        ]


divide_dotted : Css.Style
divide_dotted =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-style" "dotted"
                ]
            ]
        ]


divide_double : Css.Style
divide_double =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-style" "double"
                ]
            ]
        ]


divide_gray_100 : Css.Style
divide_gray_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(243, 244, 246, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_200 : Css.Style
divide_gray_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(229, 231, 235, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_300 : Css.Style
divide_gray_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(209, 213, 219, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_400 : Css.Style
divide_gray_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(156, 163, 175, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_50 : Css.Style
divide_gray_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(249, 250, 251, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_500 : Css.Style
divide_gray_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(107, 114, 128, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_600 : Css.Style
divide_gray_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(75, 85, 99, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_700 : Css.Style
divide_gray_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(55, 65, 81, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_800 : Css.Style
divide_gray_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(31, 41, 55, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_gray_900 : Css.Style
divide_gray_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(17, 24, 39, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_100 : Css.Style
divide_green_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(209, 250, 229, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_200 : Css.Style
divide_green_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(167, 243, 208, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_300 : Css.Style
divide_green_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(110, 231, 183, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_400 : Css.Style
divide_green_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(52, 211, 153, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_50 : Css.Style
divide_green_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(236, 253, 245, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_500 : Css.Style
divide_green_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(16, 185, 129, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_600 : Css.Style
divide_green_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(5, 150, 105, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_700 : Css.Style
divide_green_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(4, 120, 87, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_800 : Css.Style
divide_green_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(6, 95, 70, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_green_900 : Css.Style
divide_green_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(6, 78, 59, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_100 : Css.Style
divide_indigo_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(224, 231, 255, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_200 : Css.Style
divide_indigo_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(199, 210, 254, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_300 : Css.Style
divide_indigo_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(165, 180, 252, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_400 : Css.Style
divide_indigo_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(129, 140, 248, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_50 : Css.Style
divide_indigo_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(238, 242, 255, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_500 : Css.Style
divide_indigo_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(99, 102, 241, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_600 : Css.Style
divide_indigo_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(79, 70, 229, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_700 : Css.Style
divide_indigo_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(67, 56, 202, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_800 : Css.Style
divide_indigo_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(55, 48, 163, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_indigo_900 : Css.Style
divide_indigo_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(49, 46, 129, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_none : Css.Style
divide_none =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-style" "none"
                ]
            ]
        ]


divide_opacity_0 : Css.Style
divide_opacity_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0"
                ]
            ]
        ]


divide_opacity_10 : Css.Style
divide_opacity_10 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.1"
                ]
            ]
        ]


divide_opacity_100 : Css.Style
divide_opacity_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                ]
            ]
        ]


divide_opacity_20 : Css.Style
divide_opacity_20 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.2"
                ]
            ]
        ]


divide_opacity_25 : Css.Style
divide_opacity_25 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.25"
                ]
            ]
        ]


divide_opacity_30 : Css.Style
divide_opacity_30 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.3"
                ]
            ]
        ]


divide_opacity_40 : Css.Style
divide_opacity_40 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.4"
                ]
            ]
        ]


divide_opacity_5 : Css.Style
divide_opacity_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.05"
                ]
            ]
        ]


divide_opacity_50 : Css.Style
divide_opacity_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.5"
                ]
            ]
        ]


divide_opacity_60 : Css.Style
divide_opacity_60 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.6"
                ]
            ]
        ]


divide_opacity_70 : Css.Style
divide_opacity_70 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.7"
                ]
            ]
        ]


divide_opacity_75 : Css.Style
divide_opacity_75 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.75"
                ]
            ]
        ]


divide_opacity_80 : Css.Style
divide_opacity_80 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.8"
                ]
            ]
        ]


divide_opacity_90 : Css.Style
divide_opacity_90 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.9"
                ]
            ]
        ]


divide_opacity_95 : Css.Style
divide_opacity_95 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "0.95"
                ]
            ]
        ]


divide_pink_100 : Css.Style
divide_pink_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(252, 231, 243, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_200 : Css.Style
divide_pink_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(251, 207, 232, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_300 : Css.Style
divide_pink_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(249, 168, 212, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_400 : Css.Style
divide_pink_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(244, 114, 182, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_50 : Css.Style
divide_pink_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(253, 242, 248, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_500 : Css.Style
divide_pink_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(236, 72, 153, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_600 : Css.Style
divide_pink_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(219, 39, 119, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_700 : Css.Style
divide_pink_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(190, 24, 93, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_800 : Css.Style
divide_pink_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(157, 23, 77, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_pink_900 : Css.Style
divide_pink_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(131, 24, 67, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_100 : Css.Style
divide_purple_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(237, 233, 254, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_200 : Css.Style
divide_purple_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(221, 214, 254, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_300 : Css.Style
divide_purple_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(196, 181, 253, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_400 : Css.Style
divide_purple_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(167, 139, 250, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_50 : Css.Style
divide_purple_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(245, 243, 255, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_500 : Css.Style
divide_purple_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(139, 92, 246, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_600 : Css.Style
divide_purple_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(124, 58, 237, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_700 : Css.Style
divide_purple_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(109, 40, 217, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_800 : Css.Style
divide_purple_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(91, 33, 182, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_purple_900 : Css.Style
divide_purple_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(76, 29, 149, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_100 : Css.Style
divide_red_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(254, 226, 226, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_200 : Css.Style
divide_red_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(254, 202, 202, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_300 : Css.Style
divide_red_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(252, 165, 165, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_400 : Css.Style
divide_red_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(248, 113, 113, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_50 : Css.Style
divide_red_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(254, 242, 242, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_500 : Css.Style
divide_red_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(239, 68, 68, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_600 : Css.Style
divide_red_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(220, 38, 38, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_700 : Css.Style
divide_red_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(185, 28, 28, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_800 : Css.Style
divide_red_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(153, 27, 27, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_red_900 : Css.Style
divide_red_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(127, 29, 29, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_solid : Css.Style
divide_solid =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-style" "solid"
                ]
            ]
        ]


divide_transparent : Css.Style
divide_transparent =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "border-color" "transparent"
                ]
            ]
        ]


divide_white : Css.Style
divide_white =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(255, 255, 255, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_x : Css.Style
divide_x =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-x-reverse" "0"
                , Css.property "border-right-width" "calc(1px * var(--tw-divide-x-reverse))"
                , Css.property "border-left-width" "calc(1px * calc(1 - var(--tw-divide-x-reverse)))"
                ]
            ]
        ]


divide_x_0 : Css.Style
divide_x_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-x-reverse" "0"
                , Css.property "border-right-width" "calc(0px * var(--tw-divide-x-reverse))"
                , Css.property "border-left-width" "calc(0px * calc(1 - var(--tw-divide-x-reverse)))"
                ]
            ]
        ]


divide_x_2 : Css.Style
divide_x_2 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-x-reverse" "0"
                , Css.property "border-right-width" "calc(2px * var(--tw-divide-x-reverse))"
                , Css.property "border-left-width" "calc(2px * calc(1 - var(--tw-divide-x-reverse)))"
                ]
            ]
        ]


divide_x_4 : Css.Style
divide_x_4 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-x-reverse" "0"
                , Css.property "border-right-width" "calc(4px * var(--tw-divide-x-reverse))"
                , Css.property "border-left-width" "calc(4px * calc(1 - var(--tw-divide-x-reverse)))"
                ]
            ]
        ]


divide_x_8 : Css.Style
divide_x_8 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-x-reverse" "0"
                , Css.property "border-right-width" "calc(8px * var(--tw-divide-x-reverse))"
                , Css.property "border-left-width" "calc(8px * calc(1 - var(--tw-divide-x-reverse)))"
                ]
            ]
        ]


divide_x_reverse : Css.Style
divide_x_reverse =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-x-reverse" "1"
                ]
            ]
        ]


divide_y : Css.Style
divide_y =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-y-reverse" "0"
                , Css.property "border-top-width" "calc(1px * calc(1 - var(--tw-divide-y-reverse)))"
                , Css.property "border-bottom-width" "calc(1px * var(--tw-divide-y-reverse))"
                ]
            ]
        ]


divide_y_0 : Css.Style
divide_y_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-y-reverse" "0"
                , Css.property "border-top-width" "calc(0px * calc(1 - var(--tw-divide-y-reverse)))"
                , Css.property "border-bottom-width" "calc(0px * var(--tw-divide-y-reverse))"
                ]
            ]
        ]


divide_y_2 : Css.Style
divide_y_2 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-y-reverse" "0"
                , Css.property "border-top-width" "calc(2px * calc(1 - var(--tw-divide-y-reverse)))"
                , Css.property "border-bottom-width" "calc(2px * var(--tw-divide-y-reverse))"
                ]
            ]
        ]


divide_y_4 : Css.Style
divide_y_4 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-y-reverse" "0"
                , Css.property "border-top-width" "calc(4px * calc(1 - var(--tw-divide-y-reverse)))"
                , Css.property "border-bottom-width" "calc(4px * var(--tw-divide-y-reverse))"
                ]
            ]
        ]


divide_y_8 : Css.Style
divide_y_8 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-y-reverse" "0"
                , Css.property "border-top-width" "calc(8px * calc(1 - var(--tw-divide-y-reverse)))"
                , Css.property "border-bottom-width" "calc(8px * var(--tw-divide-y-reverse))"
                ]
            ]
        ]


divide_y_reverse : Css.Style
divide_y_reverse =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-y-reverse" "1"
                ]
            ]
        ]


divide_yellow_100 : Css.Style
divide_yellow_100 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(254, 243, 199, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_200 : Css.Style
divide_yellow_200 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(253, 230, 138, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_300 : Css.Style
divide_yellow_300 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(252, 211, 77, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_400 : Css.Style
divide_yellow_400 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(251, 191, 36, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_50 : Css.Style
divide_yellow_50 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(255, 251, 235, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_500 : Css.Style
divide_yellow_500 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(245, 158, 11, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_600 : Css.Style
divide_yellow_600 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(217, 119, 6, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_700 : Css.Style
divide_yellow_700 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(180, 83, 9, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_800 : Css.Style
divide_yellow_800 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(146, 64, 14, var(--tw-divide-opacity))"
                ]
            ]
        ]


divide_yellow_900 : Css.Style
divide_yellow_900 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" "rgba(120, 53, 15, var(--tw-divide-opacity))"
                ]
            ]
        ]


drop_shadow : Css.Style
drop_shadow =
    Css.property "--tw-drop-shadow" "drop-shadow(0 1px 2px rgba(0, 0, 0, 0.1)) drop-shadow(0 1px 1px rgba(0, 0, 0, 0.06))"


drop_shadow_2xl : Css.Style
drop_shadow_2xl =
    Css.property "--tw-drop-shadow" "drop-shadow(0 25px 25px rgba(0, 0, 0, 0.15))"


drop_shadow_lg : Css.Style
drop_shadow_lg =
    Css.property "--tw-drop-shadow" "drop-shadow(0 10px 8px rgba(0, 0, 0, 0.04)) drop-shadow(0 4px 3px rgba(0, 0, 0, 0.1))"


drop_shadow_md : Css.Style
drop_shadow_md =
    Css.property "--tw-drop-shadow" "drop-shadow(0 4px 3px rgba(0, 0, 0, 0.07)) drop-shadow(0 2px 2px rgba(0, 0, 0, 0.06))"


drop_shadow_none : Css.Style
drop_shadow_none =
    Css.property "--tw-drop-shadow" "drop-shadow(0 0 #0000)"


drop_shadow_sm : Css.Style
drop_shadow_sm =
    Css.property "--tw-drop-shadow" "drop-shadow(0 1px 1px rgba(0,0,0,0.05))"


drop_shadow_xl : Css.Style
drop_shadow_xl =
    Css.property "--tw-drop-shadow" "drop-shadow(0 20px 13px rgba(0, 0, 0, 0.03)) drop-shadow(0 8px 5px rgba(0, 0, 0, 0.08))"


duration_100 : Css.Style
duration_100 =
    Css.property "transition-duration" "100ms"


duration_1000 : Css.Style
duration_1000 =
    Css.property "transition-duration" "1000ms"


duration_150 : Css.Style
duration_150 =
    Css.property "transition-duration" "150ms"


duration_200 : Css.Style
duration_200 =
    Css.property "transition-duration" "200ms"


duration_300 : Css.Style
duration_300 =
    Css.property "transition-duration" "300ms"


duration_500 : Css.Style
duration_500 =
    Css.property "transition-duration" "500ms"


duration_700 : Css.Style
duration_700 =
    Css.property "transition-duration" "700ms"


duration_75 : Css.Style
duration_75 =
    Css.property "transition-duration" "75ms"


ease_in : Css.Style
ease_in =
    Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 1, 1)"


ease_in_out : Css.Style
ease_in_out =
    Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"


ease_linear : Css.Style
ease_linear =
    Css.property "transition-timing-function" "linear"


ease_out : Css.Style
ease_out =
    Css.property "transition-timing-function" "cubic-bezier(0, 0, 0.2, 1)"


fill_current : Css.Style
fill_current =
    Css.property "fill" "currentColor"


filter : Css.Style
filter =
    Css.batch
        [ Css.property "--tw-blur" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-brightness" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-contrast" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-grayscale" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-hue-rotate" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-invert" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-saturate" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-sepia" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-drop-shadow" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "filter" "var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)"
        ]


filter_none : Css.Style
filter_none =
    Css.property "filter" "none"


fixed : Css.Style
fixed =
    Css.property "position" "fixed"


flex : Css.Style
flex =
    Css.property "display" "flex"


flex_1 : Css.Style
flex_1 =
    Css.property "flex" "1 1 0%"


flex_auto : Css.Style
flex_auto =
    Css.property "flex" "1 1 auto"


flex_col : Css.Style
flex_col =
    Css.property "flex-direction" "column"


flex_col_reverse : Css.Style
flex_col_reverse =
    Css.property "flex-direction" "column-reverse"


flex_grow : Css.Style
flex_grow =
    Css.property "flex-grow" "1"


flex_grow_0 : Css.Style
flex_grow_0 =
    Css.property "flex-grow" "0"


flex_initial : Css.Style
flex_initial =
    Css.property "flex" "0 1 auto"


flex_none : Css.Style
flex_none =
    Css.property "flex" "none"


flex_nowrap : Css.Style
flex_nowrap =
    Css.property "flex-wrap" "nowrap"


flex_row : Css.Style
flex_row =
    Css.property "flex-direction" "row"


flex_row_reverse : Css.Style
flex_row_reverse =
    Css.property "flex-direction" "row-reverse"


flex_shrink : Css.Style
flex_shrink =
    Css.property "flex-shrink" "1"


flex_shrink_0 : Css.Style
flex_shrink_0 =
    Css.property "flex-shrink" "0"


flex_wrap : Css.Style
flex_wrap =
    Css.property "flex-wrap" "wrap"


flex_wrap_reverse : Css.Style
flex_wrap_reverse =
    Css.property "flex-wrap" "wrap-reverse"


float_left : Css.Style
float_left =
    Css.property "float" "left"


float_none : Css.Style
float_none =
    Css.property "float" "none"


float_right : Css.Style
float_right =
    Css.property "float" "right"


flow_root : Css.Style
flow_root =
    Css.property "display" "flow-root"


font_black : Css.Style
font_black =
    Css.property "font-weight" "900"


font_bold : Css.Style
font_bold =
    Css.property "font-weight" "700"


font_extrabold : Css.Style
font_extrabold =
    Css.property "font-weight" "800"


font_extralight : Css.Style
font_extralight =
    Css.property "font-weight" "200"


font_light : Css.Style
font_light =
    Css.property "font-weight" "300"


font_medium : Css.Style
font_medium =
    Css.property "font-weight" "500"


font_mono : Css.Style
font_mono =
    Css.property "font-family" "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", \"Courier New\", monospace"


font_normal : Css.Style
font_normal =
    Css.property "font-weight" "400"


font_sans : Css.Style
font_sans =
    Css.property "font-family" "ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, \"Noto Sans\", sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\", \"Noto Color Emoji\""


font_semibold : Css.Style
font_semibold =
    Css.property "font-weight" "600"


font_serif : Css.Style
font_serif =
    Css.property "font-family" "ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif"


font_thin : Css.Style
font_thin =
    Css.property "font-weight" "100"


from_black : Css.Style
from_black =
    Css.batch
        [ Css.property "--tw-gradient-from" "#000"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(0, 0, 0, 0))"
        ]


from_blue_100 : Css.Style
from_blue_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#dbeafe"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(219, 234, 254, 0))"
        ]


from_blue_200 : Css.Style
from_blue_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#bfdbfe"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(191, 219, 254, 0))"
        ]


from_blue_300 : Css.Style
from_blue_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#93c5fd"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(147, 197, 253, 0))"
        ]


from_blue_400 : Css.Style
from_blue_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#60a5fa"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(96, 165, 250, 0))"
        ]


from_blue_50 : Css.Style
from_blue_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#eff6ff"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(239, 246, 255, 0))"
        ]


from_blue_500 : Css.Style
from_blue_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#3b82f6"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(59, 130, 246, 0))"
        ]


from_blue_600 : Css.Style
from_blue_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#2563eb"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(37, 99, 235, 0))"
        ]


from_blue_700 : Css.Style
from_blue_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#1d4ed8"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(29, 78, 216, 0))"
        ]


from_blue_800 : Css.Style
from_blue_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#1e40af"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(30, 64, 175, 0))"
        ]


from_blue_900 : Css.Style
from_blue_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#1e3a8a"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(30, 58, 138, 0))"
        ]


from_current : Css.Style
from_current =
    Css.batch
        [ Css.property "--tw-gradient-from" "currentColor"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(255, 255, 255, 0))"
        ]


from_gray_100 : Css.Style
from_gray_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f3f4f6"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(243, 244, 246, 0))"
        ]


from_gray_200 : Css.Style
from_gray_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#e5e7eb"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(229, 231, 235, 0))"
        ]


from_gray_300 : Css.Style
from_gray_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#d1d5db"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(209, 213, 219, 0))"
        ]


from_gray_400 : Css.Style
from_gray_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#9ca3af"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(156, 163, 175, 0))"
        ]


from_gray_50 : Css.Style
from_gray_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f9fafb"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(249, 250, 251, 0))"
        ]


from_gray_500 : Css.Style
from_gray_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#6b7280"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(107, 114, 128, 0))"
        ]


from_gray_600 : Css.Style
from_gray_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#4b5563"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(75, 85, 99, 0))"
        ]


from_gray_700 : Css.Style
from_gray_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#374151"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(55, 65, 81, 0))"
        ]


from_gray_800 : Css.Style
from_gray_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#1f2937"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(31, 41, 55, 0))"
        ]


from_gray_900 : Css.Style
from_gray_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#111827"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(17, 24, 39, 0))"
        ]


from_green_100 : Css.Style
from_green_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#d1fae5"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(209, 250, 229, 0))"
        ]


from_green_200 : Css.Style
from_green_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#a7f3d0"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(167, 243, 208, 0))"
        ]


from_green_300 : Css.Style
from_green_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#6ee7b7"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(110, 231, 183, 0))"
        ]


from_green_400 : Css.Style
from_green_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#34d399"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(52, 211, 153, 0))"
        ]


from_green_50 : Css.Style
from_green_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#ecfdf5"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(236, 253, 245, 0))"
        ]


from_green_500 : Css.Style
from_green_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#10b981"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(16, 185, 129, 0))"
        ]


from_green_600 : Css.Style
from_green_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#059669"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(5, 150, 105, 0))"
        ]


from_green_700 : Css.Style
from_green_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#047857"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(4, 120, 87, 0))"
        ]


from_green_800 : Css.Style
from_green_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#065f46"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(6, 95, 70, 0))"
        ]


from_green_900 : Css.Style
from_green_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#064e3b"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(6, 78, 59, 0))"
        ]


from_indigo_100 : Css.Style
from_indigo_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#e0e7ff"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(224, 231, 255, 0))"
        ]


from_indigo_200 : Css.Style
from_indigo_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#c7d2fe"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(199, 210, 254, 0))"
        ]


from_indigo_300 : Css.Style
from_indigo_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#a5b4fc"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(165, 180, 252, 0))"
        ]


from_indigo_400 : Css.Style
from_indigo_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#818cf8"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(129, 140, 248, 0))"
        ]


from_indigo_50 : Css.Style
from_indigo_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#eef2ff"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(238, 242, 255, 0))"
        ]


from_indigo_500 : Css.Style
from_indigo_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#6366f1"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(99, 102, 241, 0))"
        ]


from_indigo_600 : Css.Style
from_indigo_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#4f46e5"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(79, 70, 229, 0))"
        ]


from_indigo_700 : Css.Style
from_indigo_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#4338ca"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(67, 56, 202, 0))"
        ]


from_indigo_800 : Css.Style
from_indigo_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#3730a3"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(55, 48, 163, 0))"
        ]


from_indigo_900 : Css.Style
from_indigo_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#312e81"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(49, 46, 129, 0))"
        ]


from_pink_100 : Css.Style
from_pink_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fce7f3"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(252, 231, 243, 0))"
        ]


from_pink_200 : Css.Style
from_pink_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fbcfe8"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(251, 207, 232, 0))"
        ]


from_pink_300 : Css.Style
from_pink_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f9a8d4"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(249, 168, 212, 0))"
        ]


from_pink_400 : Css.Style
from_pink_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f472b6"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(244, 114, 182, 0))"
        ]


from_pink_50 : Css.Style
from_pink_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fdf2f8"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(253, 242, 248, 0))"
        ]


from_pink_500 : Css.Style
from_pink_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#ec4899"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(236, 72, 153, 0))"
        ]


from_pink_600 : Css.Style
from_pink_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#db2777"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(219, 39, 119, 0))"
        ]


from_pink_700 : Css.Style
from_pink_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#be185d"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(190, 24, 93, 0))"
        ]


from_pink_800 : Css.Style
from_pink_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#9d174d"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(157, 23, 77, 0))"
        ]


from_pink_900 : Css.Style
from_pink_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#831843"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(131, 24, 67, 0))"
        ]


from_purple_100 : Css.Style
from_purple_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#ede9fe"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(237, 233, 254, 0))"
        ]


from_purple_200 : Css.Style
from_purple_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#ddd6fe"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(221, 214, 254, 0))"
        ]


from_purple_300 : Css.Style
from_purple_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#c4b5fd"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(196, 181, 253, 0))"
        ]


from_purple_400 : Css.Style
from_purple_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#a78bfa"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(167, 139, 250, 0))"
        ]


from_purple_50 : Css.Style
from_purple_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f5f3ff"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(245, 243, 255, 0))"
        ]


from_purple_500 : Css.Style
from_purple_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#8b5cf6"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(139, 92, 246, 0))"
        ]


from_purple_600 : Css.Style
from_purple_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#7c3aed"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(124, 58, 237, 0))"
        ]


from_purple_700 : Css.Style
from_purple_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#6d28d9"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(109, 40, 217, 0))"
        ]


from_purple_800 : Css.Style
from_purple_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#5b21b6"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(91, 33, 182, 0))"
        ]


from_purple_900 : Css.Style
from_purple_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#4c1d95"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(76, 29, 149, 0))"
        ]


from_red_100 : Css.Style
from_red_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fee2e2"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(254, 226, 226, 0))"
        ]


from_red_200 : Css.Style
from_red_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fecaca"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(254, 202, 202, 0))"
        ]


from_red_300 : Css.Style
from_red_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fca5a5"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(252, 165, 165, 0))"
        ]


from_red_400 : Css.Style
from_red_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f87171"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(248, 113, 113, 0))"
        ]


from_red_50 : Css.Style
from_red_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fef2f2"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(254, 242, 242, 0))"
        ]


from_red_500 : Css.Style
from_red_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#ef4444"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(239, 68, 68, 0))"
        ]


from_red_600 : Css.Style
from_red_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#dc2626"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(220, 38, 38, 0))"
        ]


from_red_700 : Css.Style
from_red_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#b91c1c"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(185, 28, 28, 0))"
        ]


from_red_800 : Css.Style
from_red_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#991b1b"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(153, 27, 27, 0))"
        ]


from_red_900 : Css.Style
from_red_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#7f1d1d"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(127, 29, 29, 0))"
        ]


from_transparent : Css.Style
from_transparent =
    Css.batch
        [ Css.property "--tw-gradient-from" "transparent"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(0, 0, 0, 0))"
        ]


from_white : Css.Style
from_white =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fff"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(255, 255, 255, 0))"
        ]


from_yellow_100 : Css.Style
from_yellow_100 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fef3c7"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(254, 243, 199, 0))"
        ]


from_yellow_200 : Css.Style
from_yellow_200 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fde68a"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(253, 230, 138, 0))"
        ]


from_yellow_300 : Css.Style
from_yellow_300 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fcd34d"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(252, 211, 77, 0))"
        ]


from_yellow_400 : Css.Style
from_yellow_400 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fbbf24"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(251, 191, 36, 0))"
        ]


from_yellow_50 : Css.Style
from_yellow_50 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#fffbeb"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(255, 251, 235, 0))"
        ]


from_yellow_500 : Css.Style
from_yellow_500 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#f59e0b"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(245, 158, 11, 0))"
        ]


from_yellow_600 : Css.Style
from_yellow_600 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#d97706"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(217, 119, 6, 0))"
        ]


from_yellow_700 : Css.Style
from_yellow_700 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#b45309"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(180, 83, 9, 0))"
        ]


from_yellow_800 : Css.Style
from_yellow_800 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#92400e"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(146, 64, 14, 0))"
        ]


from_yellow_900 : Css.Style
from_yellow_900 =
    Css.batch
        [ Css.property "--tw-gradient-from" "#78350f"
        , Css.property "--tw-gradient-stops" "var(--tw-gradient-from), var(--tw-gradient-to, rgba(120, 53, 15, 0))"
        ]


gap_0 : Css.Style
gap_0 =
    Css.property "gap" "0px"


gap_0_dot_5 : Css.Style
gap_0_dot_5 =
    Css.property "gap" "0.125rem"


gap_1 : Css.Style
gap_1 =
    Css.property "gap" "0.25rem"


gap_10 : Css.Style
gap_10 =
    Css.property "gap" "2.5rem"


gap_11 : Css.Style
gap_11 =
    Css.property "gap" "2.75rem"


gap_12 : Css.Style
gap_12 =
    Css.property "gap" "3rem"


gap_14 : Css.Style
gap_14 =
    Css.property "gap" "3.5rem"


gap_16 : Css.Style
gap_16 =
    Css.property "gap" "4rem"


gap_1_dot_5 : Css.Style
gap_1_dot_5 =
    Css.property "gap" "0.375rem"


gap_2 : Css.Style
gap_2 =
    Css.property "gap" "0.5rem"


gap_20 : Css.Style
gap_20 =
    Css.property "gap" "5rem"


gap_24 : Css.Style
gap_24 =
    Css.property "gap" "6rem"


gap_28 : Css.Style
gap_28 =
    Css.property "gap" "7rem"


gap_2_dot_5 : Css.Style
gap_2_dot_5 =
    Css.property "gap" "0.625rem"


gap_3 : Css.Style
gap_3 =
    Css.property "gap" "0.75rem"


gap_32 : Css.Style
gap_32 =
    Css.property "gap" "8rem"


gap_36 : Css.Style
gap_36 =
    Css.property "gap" "9rem"


gap_3_dot_5 : Css.Style
gap_3_dot_5 =
    Css.property "gap" "0.875rem"


gap_4 : Css.Style
gap_4 =
    Css.property "gap" "1rem"


gap_40 : Css.Style
gap_40 =
    Css.property "gap" "10rem"


gap_44 : Css.Style
gap_44 =
    Css.property "gap" "11rem"


gap_48 : Css.Style
gap_48 =
    Css.property "gap" "12rem"


gap_5 : Css.Style
gap_5 =
    Css.property "gap" "1.25rem"


gap_52 : Css.Style
gap_52 =
    Css.property "gap" "13rem"


gap_56 : Css.Style
gap_56 =
    Css.property "gap" "14rem"


gap_6 : Css.Style
gap_6 =
    Css.property "gap" "1.5rem"


gap_60 : Css.Style
gap_60 =
    Css.property "gap" "15rem"


gap_64 : Css.Style
gap_64 =
    Css.property "gap" "16rem"


gap_7 : Css.Style
gap_7 =
    Css.property "gap" "1.75rem"


gap_72 : Css.Style
gap_72 =
    Css.property "gap" "18rem"


gap_8 : Css.Style
gap_8 =
    Css.property "gap" "2rem"


gap_80 : Css.Style
gap_80 =
    Css.property "gap" "20rem"


gap_9 : Css.Style
gap_9 =
    Css.property "gap" "2.25rem"


gap_96 : Css.Style
gap_96 =
    Css.property "gap" "24rem"


gap_px : Css.Style
gap_px =
    Css.property "gap" "1px"


gap_x_0 : Css.Style
gap_x_0 =
    Css.property "column-gap" "0px"


gap_x_0_dot_5 : Css.Style
gap_x_0_dot_5 =
    Css.property "column-gap" "0.125rem"


gap_x_1 : Css.Style
gap_x_1 =
    Css.property "column-gap" "0.25rem"


gap_x_10 : Css.Style
gap_x_10 =
    Css.property "column-gap" "2.5rem"


gap_x_11 : Css.Style
gap_x_11 =
    Css.property "column-gap" "2.75rem"


gap_x_12 : Css.Style
gap_x_12 =
    Css.property "column-gap" "3rem"


gap_x_14 : Css.Style
gap_x_14 =
    Css.property "column-gap" "3.5rem"


gap_x_16 : Css.Style
gap_x_16 =
    Css.property "column-gap" "4rem"


gap_x_1_dot_5 : Css.Style
gap_x_1_dot_5 =
    Css.property "column-gap" "0.375rem"


gap_x_2 : Css.Style
gap_x_2 =
    Css.property "column-gap" "0.5rem"


gap_x_20 : Css.Style
gap_x_20 =
    Css.property "column-gap" "5rem"


gap_x_24 : Css.Style
gap_x_24 =
    Css.property "column-gap" "6rem"


gap_x_28 : Css.Style
gap_x_28 =
    Css.property "column-gap" "7rem"


gap_x_2_dot_5 : Css.Style
gap_x_2_dot_5 =
    Css.property "column-gap" "0.625rem"


gap_x_3 : Css.Style
gap_x_3 =
    Css.property "column-gap" "0.75rem"


gap_x_32 : Css.Style
gap_x_32 =
    Css.property "column-gap" "8rem"


gap_x_36 : Css.Style
gap_x_36 =
    Css.property "column-gap" "9rem"


gap_x_3_dot_5 : Css.Style
gap_x_3_dot_5 =
    Css.property "column-gap" "0.875rem"


gap_x_4 : Css.Style
gap_x_4 =
    Css.property "column-gap" "1rem"


gap_x_40 : Css.Style
gap_x_40 =
    Css.property "column-gap" "10rem"


gap_x_44 : Css.Style
gap_x_44 =
    Css.property "column-gap" "11rem"


gap_x_48 : Css.Style
gap_x_48 =
    Css.property "column-gap" "12rem"


gap_x_5 : Css.Style
gap_x_5 =
    Css.property "column-gap" "1.25rem"


gap_x_52 : Css.Style
gap_x_52 =
    Css.property "column-gap" "13rem"


gap_x_56 : Css.Style
gap_x_56 =
    Css.property "column-gap" "14rem"


gap_x_6 : Css.Style
gap_x_6 =
    Css.property "column-gap" "1.5rem"


gap_x_60 : Css.Style
gap_x_60 =
    Css.property "column-gap" "15rem"


gap_x_64 : Css.Style
gap_x_64 =
    Css.property "column-gap" "16rem"


gap_x_7 : Css.Style
gap_x_7 =
    Css.property "column-gap" "1.75rem"


gap_x_72 : Css.Style
gap_x_72 =
    Css.property "column-gap" "18rem"


gap_x_8 : Css.Style
gap_x_8 =
    Css.property "column-gap" "2rem"


gap_x_80 : Css.Style
gap_x_80 =
    Css.property "column-gap" "20rem"


gap_x_9 : Css.Style
gap_x_9 =
    Css.property "column-gap" "2.25rem"


gap_x_96 : Css.Style
gap_x_96 =
    Css.property "column-gap" "24rem"


gap_x_px : Css.Style
gap_x_px =
    Css.property "column-gap" "1px"


gap_y_0 : Css.Style
gap_y_0 =
    Css.property "row-gap" "0px"


gap_y_0_dot_5 : Css.Style
gap_y_0_dot_5 =
    Css.property "row-gap" "0.125rem"


gap_y_1 : Css.Style
gap_y_1 =
    Css.property "row-gap" "0.25rem"


gap_y_10 : Css.Style
gap_y_10 =
    Css.property "row-gap" "2.5rem"


gap_y_11 : Css.Style
gap_y_11 =
    Css.property "row-gap" "2.75rem"


gap_y_12 : Css.Style
gap_y_12 =
    Css.property "row-gap" "3rem"


gap_y_14 : Css.Style
gap_y_14 =
    Css.property "row-gap" "3.5rem"


gap_y_16 : Css.Style
gap_y_16 =
    Css.property "row-gap" "4rem"


gap_y_1_dot_5 : Css.Style
gap_y_1_dot_5 =
    Css.property "row-gap" "0.375rem"


gap_y_2 : Css.Style
gap_y_2 =
    Css.property "row-gap" "0.5rem"


gap_y_20 : Css.Style
gap_y_20 =
    Css.property "row-gap" "5rem"


gap_y_24 : Css.Style
gap_y_24 =
    Css.property "row-gap" "6rem"


gap_y_28 : Css.Style
gap_y_28 =
    Css.property "row-gap" "7rem"


gap_y_2_dot_5 : Css.Style
gap_y_2_dot_5 =
    Css.property "row-gap" "0.625rem"


gap_y_3 : Css.Style
gap_y_3 =
    Css.property "row-gap" "0.75rem"


gap_y_32 : Css.Style
gap_y_32 =
    Css.property "row-gap" "8rem"


gap_y_36 : Css.Style
gap_y_36 =
    Css.property "row-gap" "9rem"


gap_y_3_dot_5 : Css.Style
gap_y_3_dot_5 =
    Css.property "row-gap" "0.875rem"


gap_y_4 : Css.Style
gap_y_4 =
    Css.property "row-gap" "1rem"


gap_y_40 : Css.Style
gap_y_40 =
    Css.property "row-gap" "10rem"


gap_y_44 : Css.Style
gap_y_44 =
    Css.property "row-gap" "11rem"


gap_y_48 : Css.Style
gap_y_48 =
    Css.property "row-gap" "12rem"


gap_y_5 : Css.Style
gap_y_5 =
    Css.property "row-gap" "1.25rem"


gap_y_52 : Css.Style
gap_y_52 =
    Css.property "row-gap" "13rem"


gap_y_56 : Css.Style
gap_y_56 =
    Css.property "row-gap" "14rem"


gap_y_6 : Css.Style
gap_y_6 =
    Css.property "row-gap" "1.5rem"


gap_y_60 : Css.Style
gap_y_60 =
    Css.property "row-gap" "15rem"


gap_y_64 : Css.Style
gap_y_64 =
    Css.property "row-gap" "16rem"


gap_y_7 : Css.Style
gap_y_7 =
    Css.property "row-gap" "1.75rem"


gap_y_72 : Css.Style
gap_y_72 =
    Css.property "row-gap" "18rem"


gap_y_8 : Css.Style
gap_y_8 =
    Css.property "row-gap" "2rem"


gap_y_80 : Css.Style
gap_y_80 =
    Css.property "row-gap" "20rem"


gap_y_9 : Css.Style
gap_y_9 =
    Css.property "row-gap" "2.25rem"


gap_y_96 : Css.Style
gap_y_96 =
    Css.property "row-gap" "24rem"


gap_y_px : Css.Style
gap_y_px =
    Css.property "row-gap" "1px"


grayscale : Css.Style
grayscale =
    Css.property "--tw-grayscale" "grayscale(100%)"


grayscale_0 : Css.Style
grayscale_0 =
    Css.property "--tw-grayscale" "grayscale(0)"


grid : Css.Style
grid =
    Css.property "display" "grid"


grid_cols_1 : Css.Style
grid_cols_1 =
    Css.property "grid-template-columns" "repeat(1, minmax(0, 1fr))"


grid_cols_10 : Css.Style
grid_cols_10 =
    Css.property "grid-template-columns" "repeat(10, minmax(0, 1fr))"


grid_cols_11 : Css.Style
grid_cols_11 =
    Css.property "grid-template-columns" "repeat(11, minmax(0, 1fr))"


grid_cols_12 : Css.Style
grid_cols_12 =
    Css.property "grid-template-columns" "repeat(12, minmax(0, 1fr))"


grid_cols_2 : Css.Style
grid_cols_2 =
    Css.property "grid-template-columns" "repeat(2, minmax(0, 1fr))"


grid_cols_3 : Css.Style
grid_cols_3 =
    Css.property "grid-template-columns" "repeat(3, minmax(0, 1fr))"


grid_cols_4 : Css.Style
grid_cols_4 =
    Css.property "grid-template-columns" "repeat(4, minmax(0, 1fr))"


grid_cols_5 : Css.Style
grid_cols_5 =
    Css.property "grid-template-columns" "repeat(5, minmax(0, 1fr))"


grid_cols_6 : Css.Style
grid_cols_6 =
    Css.property "grid-template-columns" "repeat(6, minmax(0, 1fr))"


grid_cols_7 : Css.Style
grid_cols_7 =
    Css.property "grid-template-columns" "repeat(7, minmax(0, 1fr))"


grid_cols_8 : Css.Style
grid_cols_8 =
    Css.property "grid-template-columns" "repeat(8, minmax(0, 1fr))"


grid_cols_9 : Css.Style
grid_cols_9 =
    Css.property "grid-template-columns" "repeat(9, minmax(0, 1fr))"


grid_cols_none : Css.Style
grid_cols_none =
    Css.property "grid-template-columns" "none"


grid_flow_col : Css.Style
grid_flow_col =
    Css.property "grid-auto-flow" "column"


grid_flow_col_dense : Css.Style
grid_flow_col_dense =
    Css.property "grid-auto-flow" "column dense"


grid_flow_row : Css.Style
grid_flow_row =
    Css.property "grid-auto-flow" "row"


grid_flow_row_dense : Css.Style
grid_flow_row_dense =
    Css.property "grid-auto-flow" "row dense"


grid_rows_1 : Css.Style
grid_rows_1 =
    Css.property "grid-template-rows" "repeat(1, minmax(0, 1fr))"


grid_rows_2 : Css.Style
grid_rows_2 =
    Css.property "grid-template-rows" "repeat(2, minmax(0, 1fr))"


grid_rows_3 : Css.Style
grid_rows_3 =
    Css.property "grid-template-rows" "repeat(3, minmax(0, 1fr))"


grid_rows_4 : Css.Style
grid_rows_4 =
    Css.property "grid-template-rows" "repeat(4, minmax(0, 1fr))"


grid_rows_5 : Css.Style
grid_rows_5 =
    Css.property "grid-template-rows" "repeat(5, minmax(0, 1fr))"


grid_rows_6 : Css.Style
grid_rows_6 =
    Css.property "grid-template-rows" "repeat(6, minmax(0, 1fr))"


grid_rows_none : Css.Style
grid_rows_none =
    Css.property "grid-template-rows" "none"


h_0 : Css.Style
h_0 =
    Css.property "height" "0px"


h_0_dot_5 : Css.Style
h_0_dot_5 =
    Css.property "height" "0.125rem"


h_1 : Css.Style
h_1 =
    Css.property "height" "0.25rem"


h_10 : Css.Style
h_10 =
    Css.property "height" "2.5rem"


h_11 : Css.Style
h_11 =
    Css.property "height" "2.75rem"


h_12 : Css.Style
h_12 =
    Css.property "height" "3rem"


h_14 : Css.Style
h_14 =
    Css.property "height" "3.5rem"


h_16 : Css.Style
h_16 =
    Css.property "height" "4rem"


h_1_dot_5 : Css.Style
h_1_dot_5 =
    Css.property "height" "0.375rem"


h_1over2 : Css.Style
h_1over2 =
    Css.property "height" "50%"


h_1over3 : Css.Style
h_1over3 =
    Css.property "height" "33.333333%"


h_1over4 : Css.Style
h_1over4 =
    Css.property "height" "25%"


h_1over5 : Css.Style
h_1over5 =
    Css.property "height" "20%"


h_1over6 : Css.Style
h_1over6 =
    Css.property "height" "16.666667%"


h_2 : Css.Style
h_2 =
    Css.property "height" "0.5rem"


h_20 : Css.Style
h_20 =
    Css.property "height" "5rem"


h_24 : Css.Style
h_24 =
    Css.property "height" "6rem"


h_28 : Css.Style
h_28 =
    Css.property "height" "7rem"


h_2_dot_5 : Css.Style
h_2_dot_5 =
    Css.property "height" "0.625rem"


h_2over3 : Css.Style
h_2over3 =
    Css.property "height" "66.666667%"


h_2over4 : Css.Style
h_2over4 =
    Css.property "height" "50%"


h_2over5 : Css.Style
h_2over5 =
    Css.property "height" "40%"


h_2over6 : Css.Style
h_2over6 =
    Css.property "height" "33.333333%"


h_3 : Css.Style
h_3 =
    Css.property "height" "0.75rem"


h_32 : Css.Style
h_32 =
    Css.property "height" "8rem"


h_36 : Css.Style
h_36 =
    Css.property "height" "9rem"


h_3_dot_5 : Css.Style
h_3_dot_5 =
    Css.property "height" "0.875rem"


h_3over4 : Css.Style
h_3over4 =
    Css.property "height" "75%"


h_3over5 : Css.Style
h_3over5 =
    Css.property "height" "60%"


h_3over6 : Css.Style
h_3over6 =
    Css.property "height" "50%"


h_4 : Css.Style
h_4 =
    Css.property "height" "1rem"


h_40 : Css.Style
h_40 =
    Css.property "height" "10rem"


h_44 : Css.Style
h_44 =
    Css.property "height" "11rem"


h_48 : Css.Style
h_48 =
    Css.property "height" "12rem"


h_4over5 : Css.Style
h_4over5 =
    Css.property "height" "80%"


h_4over6 : Css.Style
h_4over6 =
    Css.property "height" "66.666667%"


h_5 : Css.Style
h_5 =
    Css.property "height" "1.25rem"


h_52 : Css.Style
h_52 =
    Css.property "height" "13rem"


h_56 : Css.Style
h_56 =
    Css.property "height" "14rem"


h_5over6 : Css.Style
h_5over6 =
    Css.property "height" "83.333333%"


h_6 : Css.Style
h_6 =
    Css.property "height" "1.5rem"


h_60 : Css.Style
h_60 =
    Css.property "height" "15rem"


h_64 : Css.Style
h_64 =
    Css.property "height" "16rem"


h_7 : Css.Style
h_7 =
    Css.property "height" "1.75rem"


h_72 : Css.Style
h_72 =
    Css.property "height" "18rem"


h_8 : Css.Style
h_8 =
    Css.property "height" "2rem"


h_80 : Css.Style
h_80 =
    Css.property "height" "20rem"


h_9 : Css.Style
h_9 =
    Css.property "height" "2.25rem"


h_96 : Css.Style
h_96 =
    Css.property "height" "24rem"


h_auto : Css.Style
h_auto =
    Css.property "height" "auto"


h_full : Css.Style
h_full =
    Css.property "height" "100%"


h_px : Css.Style
h_px =
    Css.property "height" "1px"


h_screen : Css.Style
h_screen =
    Css.property "height" "100vh"


hidden : Css.Style
hidden =
    Css.property "display" "none"


hue_rotate_0 : Css.Style
hue_rotate_0 =
    Css.property "--tw-hue-rotate" "hue-rotate(0deg)"


hue_rotate_15 : Css.Style
hue_rotate_15 =
    Css.property "--tw-hue-rotate" "hue-rotate(15deg)"


hue_rotate_180 : Css.Style
hue_rotate_180 =
    Css.property "--tw-hue-rotate" "hue-rotate(180deg)"


hue_rotate_30 : Css.Style
hue_rotate_30 =
    Css.property "--tw-hue-rotate" "hue-rotate(30deg)"


hue_rotate_60 : Css.Style
hue_rotate_60 =
    Css.property "--tw-hue-rotate" "hue-rotate(60deg)"


hue_rotate_90 : Css.Style
hue_rotate_90 =
    Css.property "--tw-hue-rotate" "hue-rotate(90deg)"


inline : Css.Style
inline =
    Css.property "display" "inline"


inline_block : Css.Style
inline_block =
    Css.property "display" "inline-block"


inline_flex : Css.Style
inline_flex =
    Css.property "display" "inline-flex"


inline_grid : Css.Style
inline_grid =
    Css.property "display" "inline-grid"


inline_table : Css.Style
inline_table =
    Css.property "display" "inline-table"


inset_0 : Css.Style
inset_0 =
    Css.batch
        [ Css.property "top" "0px"
        , Css.property "right" "0px"
        , Css.property "bottom" "0px"
        , Css.property "left" "0px"
        ]


inset_0_dot_5 : Css.Style
inset_0_dot_5 =
    Css.batch
        [ Css.property "top" "0.125rem"
        , Css.property "right" "0.125rem"
        , Css.property "bottom" "0.125rem"
        , Css.property "left" "0.125rem"
        ]


inset_1 : Css.Style
inset_1 =
    Css.batch
        [ Css.property "top" "0.25rem"
        , Css.property "right" "0.25rem"
        , Css.property "bottom" "0.25rem"
        , Css.property "left" "0.25rem"
        ]


inset_10 : Css.Style
inset_10 =
    Css.batch
        [ Css.property "top" "2.5rem"
        , Css.property "right" "2.5rem"
        , Css.property "bottom" "2.5rem"
        , Css.property "left" "2.5rem"
        ]


inset_11 : Css.Style
inset_11 =
    Css.batch
        [ Css.property "top" "2.75rem"
        , Css.property "right" "2.75rem"
        , Css.property "bottom" "2.75rem"
        , Css.property "left" "2.75rem"
        ]


inset_12 : Css.Style
inset_12 =
    Css.batch
        [ Css.property "top" "3rem"
        , Css.property "right" "3rem"
        , Css.property "bottom" "3rem"
        , Css.property "left" "3rem"
        ]


inset_14 : Css.Style
inset_14 =
    Css.batch
        [ Css.property "top" "3.5rem"
        , Css.property "right" "3.5rem"
        , Css.property "bottom" "3.5rem"
        , Css.property "left" "3.5rem"
        ]


inset_16 : Css.Style
inset_16 =
    Css.batch
        [ Css.property "top" "4rem"
        , Css.property "right" "4rem"
        , Css.property "bottom" "4rem"
        , Css.property "left" "4rem"
        ]


inset_1_dot_5 : Css.Style
inset_1_dot_5 =
    Css.batch
        [ Css.property "top" "0.375rem"
        , Css.property "right" "0.375rem"
        , Css.property "bottom" "0.375rem"
        , Css.property "left" "0.375rem"
        ]


inset_1over2 : Css.Style
inset_1over2 =
    Css.batch
        [ Css.property "top" "50%"
        , Css.property "right" "50%"
        , Css.property "bottom" "50%"
        , Css.property "left" "50%"
        ]


inset_1over3 : Css.Style
inset_1over3 =
    Css.batch
        [ Css.property "top" "33.333333%"
        , Css.property "right" "33.333333%"
        , Css.property "bottom" "33.333333%"
        , Css.property "left" "33.333333%"
        ]


inset_1over4 : Css.Style
inset_1over4 =
    Css.batch
        [ Css.property "top" "25%"
        , Css.property "right" "25%"
        , Css.property "bottom" "25%"
        , Css.property "left" "25%"
        ]


inset_2 : Css.Style
inset_2 =
    Css.batch
        [ Css.property "top" "0.5rem"
        , Css.property "right" "0.5rem"
        , Css.property "bottom" "0.5rem"
        , Css.property "left" "0.5rem"
        ]


inset_20 : Css.Style
inset_20 =
    Css.batch
        [ Css.property "top" "5rem"
        , Css.property "right" "5rem"
        , Css.property "bottom" "5rem"
        , Css.property "left" "5rem"
        ]


inset_24 : Css.Style
inset_24 =
    Css.batch
        [ Css.property "top" "6rem"
        , Css.property "right" "6rem"
        , Css.property "bottom" "6rem"
        , Css.property "left" "6rem"
        ]


inset_28 : Css.Style
inset_28 =
    Css.batch
        [ Css.property "top" "7rem"
        , Css.property "right" "7rem"
        , Css.property "bottom" "7rem"
        , Css.property "left" "7rem"
        ]


inset_2_dot_5 : Css.Style
inset_2_dot_5 =
    Css.batch
        [ Css.property "top" "0.625rem"
        , Css.property "right" "0.625rem"
        , Css.property "bottom" "0.625rem"
        , Css.property "left" "0.625rem"
        ]


inset_2over3 : Css.Style
inset_2over3 =
    Css.batch
        [ Css.property "top" "66.666667%"
        , Css.property "right" "66.666667%"
        , Css.property "bottom" "66.666667%"
        , Css.property "left" "66.666667%"
        ]


inset_2over4 : Css.Style
inset_2over4 =
    Css.batch
        [ Css.property "top" "50%"
        , Css.property "right" "50%"
        , Css.property "bottom" "50%"
        , Css.property "left" "50%"
        ]


inset_3 : Css.Style
inset_3 =
    Css.batch
        [ Css.property "top" "0.75rem"
        , Css.property "right" "0.75rem"
        , Css.property "bottom" "0.75rem"
        , Css.property "left" "0.75rem"
        ]


inset_32 : Css.Style
inset_32 =
    Css.batch
        [ Css.property "top" "8rem"
        , Css.property "right" "8rem"
        , Css.property "bottom" "8rem"
        , Css.property "left" "8rem"
        ]


inset_36 : Css.Style
inset_36 =
    Css.batch
        [ Css.property "top" "9rem"
        , Css.property "right" "9rem"
        , Css.property "bottom" "9rem"
        , Css.property "left" "9rem"
        ]


inset_3_dot_5 : Css.Style
inset_3_dot_5 =
    Css.batch
        [ Css.property "top" "0.875rem"
        , Css.property "right" "0.875rem"
        , Css.property "bottom" "0.875rem"
        , Css.property "left" "0.875rem"
        ]


inset_3over4 : Css.Style
inset_3over4 =
    Css.batch
        [ Css.property "top" "75%"
        , Css.property "right" "75%"
        , Css.property "bottom" "75%"
        , Css.property "left" "75%"
        ]


inset_4 : Css.Style
inset_4 =
    Css.batch
        [ Css.property "top" "1rem"
        , Css.property "right" "1rem"
        , Css.property "bottom" "1rem"
        , Css.property "left" "1rem"
        ]


inset_40 : Css.Style
inset_40 =
    Css.batch
        [ Css.property "top" "10rem"
        , Css.property "right" "10rem"
        , Css.property "bottom" "10rem"
        , Css.property "left" "10rem"
        ]


inset_44 : Css.Style
inset_44 =
    Css.batch
        [ Css.property "top" "11rem"
        , Css.property "right" "11rem"
        , Css.property "bottom" "11rem"
        , Css.property "left" "11rem"
        ]


inset_48 : Css.Style
inset_48 =
    Css.batch
        [ Css.property "top" "12rem"
        , Css.property "right" "12rem"
        , Css.property "bottom" "12rem"
        , Css.property "left" "12rem"
        ]


inset_5 : Css.Style
inset_5 =
    Css.batch
        [ Css.property "top" "1.25rem"
        , Css.property "right" "1.25rem"
        , Css.property "bottom" "1.25rem"
        , Css.property "left" "1.25rem"
        ]


inset_52 : Css.Style
inset_52 =
    Css.batch
        [ Css.property "top" "13rem"
        , Css.property "right" "13rem"
        , Css.property "bottom" "13rem"
        , Css.property "left" "13rem"
        ]


inset_56 : Css.Style
inset_56 =
    Css.batch
        [ Css.property "top" "14rem"
        , Css.property "right" "14rem"
        , Css.property "bottom" "14rem"
        , Css.property "left" "14rem"
        ]


inset_6 : Css.Style
inset_6 =
    Css.batch
        [ Css.property "top" "1.5rem"
        , Css.property "right" "1.5rem"
        , Css.property "bottom" "1.5rem"
        , Css.property "left" "1.5rem"
        ]


inset_60 : Css.Style
inset_60 =
    Css.batch
        [ Css.property "top" "15rem"
        , Css.property "right" "15rem"
        , Css.property "bottom" "15rem"
        , Css.property "left" "15rem"
        ]


inset_64 : Css.Style
inset_64 =
    Css.batch
        [ Css.property "top" "16rem"
        , Css.property "right" "16rem"
        , Css.property "bottom" "16rem"
        , Css.property "left" "16rem"
        ]


inset_7 : Css.Style
inset_7 =
    Css.batch
        [ Css.property "top" "1.75rem"
        , Css.property "right" "1.75rem"
        , Css.property "bottom" "1.75rem"
        , Css.property "left" "1.75rem"
        ]


inset_72 : Css.Style
inset_72 =
    Css.batch
        [ Css.property "top" "18rem"
        , Css.property "right" "18rem"
        , Css.property "bottom" "18rem"
        , Css.property "left" "18rem"
        ]


inset_8 : Css.Style
inset_8 =
    Css.batch
        [ Css.property "top" "2rem"
        , Css.property "right" "2rem"
        , Css.property "bottom" "2rem"
        , Css.property "left" "2rem"
        ]


inset_80 : Css.Style
inset_80 =
    Css.batch
        [ Css.property "top" "20rem"
        , Css.property "right" "20rem"
        , Css.property "bottom" "20rem"
        , Css.property "left" "20rem"
        ]


inset_9 : Css.Style
inset_9 =
    Css.batch
        [ Css.property "top" "2.25rem"
        , Css.property "right" "2.25rem"
        , Css.property "bottom" "2.25rem"
        , Css.property "left" "2.25rem"
        ]


inset_96 : Css.Style
inset_96 =
    Css.batch
        [ Css.property "top" "24rem"
        , Css.property "right" "24rem"
        , Css.property "bottom" "24rem"
        , Css.property "left" "24rem"
        ]


inset_auto : Css.Style
inset_auto =
    Css.batch
        [ Css.property "top" "auto"
        , Css.property "right" "auto"
        , Css.property "bottom" "auto"
        , Css.property "left" "auto"
        ]


inset_full : Css.Style
inset_full =
    Css.batch
        [ Css.property "top" "100%"
        , Css.property "right" "100%"
        , Css.property "bottom" "100%"
        , Css.property "left" "100%"
        ]


inset_px : Css.Style
inset_px =
    Css.batch
        [ Css.property "top" "1px"
        , Css.property "right" "1px"
        , Css.property "bottom" "1px"
        , Css.property "left" "1px"
        ]


inset_x_0 : Css.Style
inset_x_0 =
    Css.batch
        [ Css.property "left" "0px"
        , Css.property "right" "0px"
        ]


inset_x_0_dot_5 : Css.Style
inset_x_0_dot_5 =
    Css.batch
        [ Css.property "left" "0.125rem"
        , Css.property "right" "0.125rem"
        ]


inset_x_1 : Css.Style
inset_x_1 =
    Css.batch
        [ Css.property "left" "0.25rem"
        , Css.property "right" "0.25rem"
        ]


inset_x_10 : Css.Style
inset_x_10 =
    Css.batch
        [ Css.property "left" "2.5rem"
        , Css.property "right" "2.5rem"
        ]


inset_x_11 : Css.Style
inset_x_11 =
    Css.batch
        [ Css.property "left" "2.75rem"
        , Css.property "right" "2.75rem"
        ]


inset_x_12 : Css.Style
inset_x_12 =
    Css.batch
        [ Css.property "left" "3rem"
        , Css.property "right" "3rem"
        ]


inset_x_14 : Css.Style
inset_x_14 =
    Css.batch
        [ Css.property "left" "3.5rem"
        , Css.property "right" "3.5rem"
        ]


inset_x_16 : Css.Style
inset_x_16 =
    Css.batch
        [ Css.property "left" "4rem"
        , Css.property "right" "4rem"
        ]


inset_x_1_dot_5 : Css.Style
inset_x_1_dot_5 =
    Css.batch
        [ Css.property "left" "0.375rem"
        , Css.property "right" "0.375rem"
        ]


inset_x_1over2 : Css.Style
inset_x_1over2 =
    Css.batch
        [ Css.property "left" "50%"
        , Css.property "right" "50%"
        ]


inset_x_1over3 : Css.Style
inset_x_1over3 =
    Css.batch
        [ Css.property "left" "33.333333%"
        , Css.property "right" "33.333333%"
        ]


inset_x_1over4 : Css.Style
inset_x_1over4 =
    Css.batch
        [ Css.property "left" "25%"
        , Css.property "right" "25%"
        ]


inset_x_2 : Css.Style
inset_x_2 =
    Css.batch
        [ Css.property "left" "0.5rem"
        , Css.property "right" "0.5rem"
        ]


inset_x_20 : Css.Style
inset_x_20 =
    Css.batch
        [ Css.property "left" "5rem"
        , Css.property "right" "5rem"
        ]


inset_x_24 : Css.Style
inset_x_24 =
    Css.batch
        [ Css.property "left" "6rem"
        , Css.property "right" "6rem"
        ]


inset_x_28 : Css.Style
inset_x_28 =
    Css.batch
        [ Css.property "left" "7rem"
        , Css.property "right" "7rem"
        ]


inset_x_2_dot_5 : Css.Style
inset_x_2_dot_5 =
    Css.batch
        [ Css.property "left" "0.625rem"
        , Css.property "right" "0.625rem"
        ]


inset_x_2over3 : Css.Style
inset_x_2over3 =
    Css.batch
        [ Css.property "left" "66.666667%"
        , Css.property "right" "66.666667%"
        ]


inset_x_2over4 : Css.Style
inset_x_2over4 =
    Css.batch
        [ Css.property "left" "50%"
        , Css.property "right" "50%"
        ]


inset_x_3 : Css.Style
inset_x_3 =
    Css.batch
        [ Css.property "left" "0.75rem"
        , Css.property "right" "0.75rem"
        ]


inset_x_32 : Css.Style
inset_x_32 =
    Css.batch
        [ Css.property "left" "8rem"
        , Css.property "right" "8rem"
        ]


inset_x_36 : Css.Style
inset_x_36 =
    Css.batch
        [ Css.property "left" "9rem"
        , Css.property "right" "9rem"
        ]


inset_x_3_dot_5 : Css.Style
inset_x_3_dot_5 =
    Css.batch
        [ Css.property "left" "0.875rem"
        , Css.property "right" "0.875rem"
        ]


inset_x_3over4 : Css.Style
inset_x_3over4 =
    Css.batch
        [ Css.property "left" "75%"
        , Css.property "right" "75%"
        ]


inset_x_4 : Css.Style
inset_x_4 =
    Css.batch
        [ Css.property "left" "1rem"
        , Css.property "right" "1rem"
        ]


inset_x_40 : Css.Style
inset_x_40 =
    Css.batch
        [ Css.property "left" "10rem"
        , Css.property "right" "10rem"
        ]


inset_x_44 : Css.Style
inset_x_44 =
    Css.batch
        [ Css.property "left" "11rem"
        , Css.property "right" "11rem"
        ]


inset_x_48 : Css.Style
inset_x_48 =
    Css.batch
        [ Css.property "left" "12rem"
        , Css.property "right" "12rem"
        ]


inset_x_5 : Css.Style
inset_x_5 =
    Css.batch
        [ Css.property "left" "1.25rem"
        , Css.property "right" "1.25rem"
        ]


inset_x_52 : Css.Style
inset_x_52 =
    Css.batch
        [ Css.property "left" "13rem"
        , Css.property "right" "13rem"
        ]


inset_x_56 : Css.Style
inset_x_56 =
    Css.batch
        [ Css.property "left" "14rem"
        , Css.property "right" "14rem"
        ]


inset_x_6 : Css.Style
inset_x_6 =
    Css.batch
        [ Css.property "left" "1.5rem"
        , Css.property "right" "1.5rem"
        ]


inset_x_60 : Css.Style
inset_x_60 =
    Css.batch
        [ Css.property "left" "15rem"
        , Css.property "right" "15rem"
        ]


inset_x_64 : Css.Style
inset_x_64 =
    Css.batch
        [ Css.property "left" "16rem"
        , Css.property "right" "16rem"
        ]


inset_x_7 : Css.Style
inset_x_7 =
    Css.batch
        [ Css.property "left" "1.75rem"
        , Css.property "right" "1.75rem"
        ]


inset_x_72 : Css.Style
inset_x_72 =
    Css.batch
        [ Css.property "left" "18rem"
        , Css.property "right" "18rem"
        ]


inset_x_8 : Css.Style
inset_x_8 =
    Css.batch
        [ Css.property "left" "2rem"
        , Css.property "right" "2rem"
        ]


inset_x_80 : Css.Style
inset_x_80 =
    Css.batch
        [ Css.property "left" "20rem"
        , Css.property "right" "20rem"
        ]


inset_x_9 : Css.Style
inset_x_9 =
    Css.batch
        [ Css.property "left" "2.25rem"
        , Css.property "right" "2.25rem"
        ]


inset_x_96 : Css.Style
inset_x_96 =
    Css.batch
        [ Css.property "left" "24rem"
        , Css.property "right" "24rem"
        ]


inset_x_auto : Css.Style
inset_x_auto =
    Css.batch
        [ Css.property "left" "auto"
        , Css.property "right" "auto"
        ]


inset_x_full : Css.Style
inset_x_full =
    Css.batch
        [ Css.property "left" "100%"
        , Css.property "right" "100%"
        ]


inset_x_px : Css.Style
inset_x_px =
    Css.batch
        [ Css.property "left" "1px"
        , Css.property "right" "1px"
        ]


inset_y_0 : Css.Style
inset_y_0 =
    Css.batch
        [ Css.property "top" "0px"
        , Css.property "bottom" "0px"
        ]


inset_y_0_dot_5 : Css.Style
inset_y_0_dot_5 =
    Css.batch
        [ Css.property "top" "0.125rem"
        , Css.property "bottom" "0.125rem"
        ]


inset_y_1 : Css.Style
inset_y_1 =
    Css.batch
        [ Css.property "top" "0.25rem"
        , Css.property "bottom" "0.25rem"
        ]


inset_y_10 : Css.Style
inset_y_10 =
    Css.batch
        [ Css.property "top" "2.5rem"
        , Css.property "bottom" "2.5rem"
        ]


inset_y_11 : Css.Style
inset_y_11 =
    Css.batch
        [ Css.property "top" "2.75rem"
        , Css.property "bottom" "2.75rem"
        ]


inset_y_12 : Css.Style
inset_y_12 =
    Css.batch
        [ Css.property "top" "3rem"
        , Css.property "bottom" "3rem"
        ]


inset_y_14 : Css.Style
inset_y_14 =
    Css.batch
        [ Css.property "top" "3.5rem"
        , Css.property "bottom" "3.5rem"
        ]


inset_y_16 : Css.Style
inset_y_16 =
    Css.batch
        [ Css.property "top" "4rem"
        , Css.property "bottom" "4rem"
        ]


inset_y_1_dot_5 : Css.Style
inset_y_1_dot_5 =
    Css.batch
        [ Css.property "top" "0.375rem"
        , Css.property "bottom" "0.375rem"
        ]


inset_y_1over2 : Css.Style
inset_y_1over2 =
    Css.batch
        [ Css.property "top" "50%"
        , Css.property "bottom" "50%"
        ]


inset_y_1over3 : Css.Style
inset_y_1over3 =
    Css.batch
        [ Css.property "top" "33.333333%"
        , Css.property "bottom" "33.333333%"
        ]


inset_y_1over4 : Css.Style
inset_y_1over4 =
    Css.batch
        [ Css.property "top" "25%"
        , Css.property "bottom" "25%"
        ]


inset_y_2 : Css.Style
inset_y_2 =
    Css.batch
        [ Css.property "top" "0.5rem"
        , Css.property "bottom" "0.5rem"
        ]


inset_y_20 : Css.Style
inset_y_20 =
    Css.batch
        [ Css.property "top" "5rem"
        , Css.property "bottom" "5rem"
        ]


inset_y_24 : Css.Style
inset_y_24 =
    Css.batch
        [ Css.property "top" "6rem"
        , Css.property "bottom" "6rem"
        ]


inset_y_28 : Css.Style
inset_y_28 =
    Css.batch
        [ Css.property "top" "7rem"
        , Css.property "bottom" "7rem"
        ]


inset_y_2_dot_5 : Css.Style
inset_y_2_dot_5 =
    Css.batch
        [ Css.property "top" "0.625rem"
        , Css.property "bottom" "0.625rem"
        ]


inset_y_2over3 : Css.Style
inset_y_2over3 =
    Css.batch
        [ Css.property "top" "66.666667%"
        , Css.property "bottom" "66.666667%"
        ]


inset_y_2over4 : Css.Style
inset_y_2over4 =
    Css.batch
        [ Css.property "top" "50%"
        , Css.property "bottom" "50%"
        ]


inset_y_3 : Css.Style
inset_y_3 =
    Css.batch
        [ Css.property "top" "0.75rem"
        , Css.property "bottom" "0.75rem"
        ]


inset_y_32 : Css.Style
inset_y_32 =
    Css.batch
        [ Css.property "top" "8rem"
        , Css.property "bottom" "8rem"
        ]


inset_y_36 : Css.Style
inset_y_36 =
    Css.batch
        [ Css.property "top" "9rem"
        , Css.property "bottom" "9rem"
        ]


inset_y_3_dot_5 : Css.Style
inset_y_3_dot_5 =
    Css.batch
        [ Css.property "top" "0.875rem"
        , Css.property "bottom" "0.875rem"
        ]


inset_y_3over4 : Css.Style
inset_y_3over4 =
    Css.batch
        [ Css.property "top" "75%"
        , Css.property "bottom" "75%"
        ]


inset_y_4 : Css.Style
inset_y_4 =
    Css.batch
        [ Css.property "top" "1rem"
        , Css.property "bottom" "1rem"
        ]


inset_y_40 : Css.Style
inset_y_40 =
    Css.batch
        [ Css.property "top" "10rem"
        , Css.property "bottom" "10rem"
        ]


inset_y_44 : Css.Style
inset_y_44 =
    Css.batch
        [ Css.property "top" "11rem"
        , Css.property "bottom" "11rem"
        ]


inset_y_48 : Css.Style
inset_y_48 =
    Css.batch
        [ Css.property "top" "12rem"
        , Css.property "bottom" "12rem"
        ]


inset_y_5 : Css.Style
inset_y_5 =
    Css.batch
        [ Css.property "top" "1.25rem"
        , Css.property "bottom" "1.25rem"
        ]


inset_y_52 : Css.Style
inset_y_52 =
    Css.batch
        [ Css.property "top" "13rem"
        , Css.property "bottom" "13rem"
        ]


inset_y_56 : Css.Style
inset_y_56 =
    Css.batch
        [ Css.property "top" "14rem"
        , Css.property "bottom" "14rem"
        ]


inset_y_6 : Css.Style
inset_y_6 =
    Css.batch
        [ Css.property "top" "1.5rem"
        , Css.property "bottom" "1.5rem"
        ]


inset_y_60 : Css.Style
inset_y_60 =
    Css.batch
        [ Css.property "top" "15rem"
        , Css.property "bottom" "15rem"
        ]


inset_y_64 : Css.Style
inset_y_64 =
    Css.batch
        [ Css.property "top" "16rem"
        , Css.property "bottom" "16rem"
        ]


inset_y_7 : Css.Style
inset_y_7 =
    Css.batch
        [ Css.property "top" "1.75rem"
        , Css.property "bottom" "1.75rem"
        ]


inset_y_72 : Css.Style
inset_y_72 =
    Css.batch
        [ Css.property "top" "18rem"
        , Css.property "bottom" "18rem"
        ]


inset_y_8 : Css.Style
inset_y_8 =
    Css.batch
        [ Css.property "top" "2rem"
        , Css.property "bottom" "2rem"
        ]


inset_y_80 : Css.Style
inset_y_80 =
    Css.batch
        [ Css.property "top" "20rem"
        , Css.property "bottom" "20rem"
        ]


inset_y_9 : Css.Style
inset_y_9 =
    Css.batch
        [ Css.property "top" "2.25rem"
        , Css.property "bottom" "2.25rem"
        ]


inset_y_96 : Css.Style
inset_y_96 =
    Css.batch
        [ Css.property "top" "24rem"
        , Css.property "bottom" "24rem"
        ]


inset_y_auto : Css.Style
inset_y_auto =
    Css.batch
        [ Css.property "top" "auto"
        , Css.property "bottom" "auto"
        ]


inset_y_full : Css.Style
inset_y_full =
    Css.batch
        [ Css.property "top" "100%"
        , Css.property "bottom" "100%"
        ]


inset_y_px : Css.Style
inset_y_px =
    Css.batch
        [ Css.property "top" "1px"
        , Css.property "bottom" "1px"
        ]


invert : Css.Style
invert =
    Css.property "--tw-invert" "invert(100%)"


invert_0 : Css.Style
invert_0 =
    Css.property "--tw-invert" "invert(0)"


invisible : Css.Style
invisible =
    Css.property "visibility" "hidden"


isolate : Css.Style
isolate =
    Css.property "isolation" "isolate"


isolation_auto : Css.Style
isolation_auto =
    Css.property "isolation" "auto"


italic : Css.Style
italic =
    Css.property "font-style" "italic"


items_baseline : Css.Style
items_baseline =
    Css.property "align-items" "baseline"


items_center : Css.Style
items_center =
    Css.property "align-items" "center"


items_end : Css.Style
items_end =
    Css.property "align-items" "flex-end"


items_start : Css.Style
items_start =
    Css.property "align-items" "flex-start"


items_stretch : Css.Style
items_stretch =
    Css.property "align-items" "stretch"


justify_around : Css.Style
justify_around =
    Css.property "justify-content" "space-around"


justify_between : Css.Style
justify_between =
    Css.property "justify-content" "space-between"


justify_center : Css.Style
justify_center =
    Css.property "justify-content" "center"


justify_end : Css.Style
justify_end =
    Css.property "justify-content" "flex-end"


justify_evenly : Css.Style
justify_evenly =
    Css.property "justify-content" "space-evenly"


justify_items_center : Css.Style
justify_items_center =
    Css.property "justify-items" "center"


justify_items_end : Css.Style
justify_items_end =
    Css.property "justify-items" "end"


justify_items_start : Css.Style
justify_items_start =
    Css.property "justify-items" "start"


justify_items_stretch : Css.Style
justify_items_stretch =
    Css.property "justify-items" "stretch"


justify_self_auto : Css.Style
justify_self_auto =
    Css.property "justify-self" "auto"


justify_self_center : Css.Style
justify_self_center =
    Css.property "justify-self" "center"


justify_self_end : Css.Style
justify_self_end =
    Css.property "justify-self" "end"


justify_self_start : Css.Style
justify_self_start =
    Css.property "justify-self" "start"


justify_self_stretch : Css.Style
justify_self_stretch =
    Css.property "justify-self" "stretch"


justify_start : Css.Style
justify_start =
    Css.property "justify-content" "flex-start"


leading_10 : Css.Style
leading_10 =
    Css.property "line-height" "2.5rem"


leading_3 : Css.Style
leading_3 =
    Css.property "line-height" ".75rem"


leading_4 : Css.Style
leading_4 =
    Css.property "line-height" "1rem"


leading_5 : Css.Style
leading_5 =
    Css.property "line-height" "1.25rem"


leading_6 : Css.Style
leading_6 =
    Css.property "line-height" "1.5rem"


leading_7 : Css.Style
leading_7 =
    Css.property "line-height" "1.75rem"


leading_8 : Css.Style
leading_8 =
    Css.property "line-height" "2rem"


leading_9 : Css.Style
leading_9 =
    Css.property "line-height" "2.25rem"


leading_loose : Css.Style
leading_loose =
    Css.property "line-height" "2"


leading_none : Css.Style
leading_none =
    Css.property "line-height" "1"


leading_normal : Css.Style
leading_normal =
    Css.property "line-height" "1.5"


leading_relaxed : Css.Style
leading_relaxed =
    Css.property "line-height" "1.625"


leading_snug : Css.Style
leading_snug =
    Css.property "line-height" "1.375"


leading_tight : Css.Style
leading_tight =
    Css.property "line-height" "1.25"


left_0 : Css.Style
left_0 =
    Css.property "left" "0px"


left_0_dot_5 : Css.Style
left_0_dot_5 =
    Css.property "left" "0.125rem"


left_1 : Css.Style
left_1 =
    Css.property "left" "0.25rem"


left_10 : Css.Style
left_10 =
    Css.property "left" "2.5rem"


left_11 : Css.Style
left_11 =
    Css.property "left" "2.75rem"


left_12 : Css.Style
left_12 =
    Css.property "left" "3rem"


left_14 : Css.Style
left_14 =
    Css.property "left" "3.5rem"


left_16 : Css.Style
left_16 =
    Css.property "left" "4rem"


left_1_dot_5 : Css.Style
left_1_dot_5 =
    Css.property "left" "0.375rem"


left_1over2 : Css.Style
left_1over2 =
    Css.property "left" "50%"


left_1over3 : Css.Style
left_1over3 =
    Css.property "left" "33.333333%"


left_1over4 : Css.Style
left_1over4 =
    Css.property "left" "25%"


left_2 : Css.Style
left_2 =
    Css.property "left" "0.5rem"


left_20 : Css.Style
left_20 =
    Css.property "left" "5rem"


left_24 : Css.Style
left_24 =
    Css.property "left" "6rem"


left_28 : Css.Style
left_28 =
    Css.property "left" "7rem"


left_2_dot_5 : Css.Style
left_2_dot_5 =
    Css.property "left" "0.625rem"


left_2over3 : Css.Style
left_2over3 =
    Css.property "left" "66.666667%"


left_2over4 : Css.Style
left_2over4 =
    Css.property "left" "50%"


left_3 : Css.Style
left_3 =
    Css.property "left" "0.75rem"


left_32 : Css.Style
left_32 =
    Css.property "left" "8rem"


left_36 : Css.Style
left_36 =
    Css.property "left" "9rem"


left_3_dot_5 : Css.Style
left_3_dot_5 =
    Css.property "left" "0.875rem"


left_3over4 : Css.Style
left_3over4 =
    Css.property "left" "75%"


left_4 : Css.Style
left_4 =
    Css.property "left" "1rem"


left_40 : Css.Style
left_40 =
    Css.property "left" "10rem"


left_44 : Css.Style
left_44 =
    Css.property "left" "11rem"


left_48 : Css.Style
left_48 =
    Css.property "left" "12rem"


left_5 : Css.Style
left_5 =
    Css.property "left" "1.25rem"


left_52 : Css.Style
left_52 =
    Css.property "left" "13rem"


left_56 : Css.Style
left_56 =
    Css.property "left" "14rem"


left_6 : Css.Style
left_6 =
    Css.property "left" "1.5rem"


left_60 : Css.Style
left_60 =
    Css.property "left" "15rem"


left_64 : Css.Style
left_64 =
    Css.property "left" "16rem"


left_7 : Css.Style
left_7 =
    Css.property "left" "1.75rem"


left_72 : Css.Style
left_72 =
    Css.property "left" "18rem"


left_8 : Css.Style
left_8 =
    Css.property "left" "2rem"


left_80 : Css.Style
left_80 =
    Css.property "left" "20rem"


left_9 : Css.Style
left_9 =
    Css.property "left" "2.25rem"


left_96 : Css.Style
left_96 =
    Css.property "left" "24rem"


left_auto : Css.Style
left_auto =
    Css.property "left" "auto"


left_full : Css.Style
left_full =
    Css.property "left" "100%"


left_px : Css.Style
left_px =
    Css.property "left" "1px"


line_through : Css.Style
line_through =
    Css.property "text-decoration" "line-through"


lining_nums : Css.Style
lining_nums =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-numeric-figure" "lining-nums"
        ]


list_decimal : Css.Style
list_decimal =
    Css.property "list-style-type" "decimal"


list_disc : Css.Style
list_disc =
    Css.property "list-style-type" "disc"


list_inside : Css.Style
list_inside =
    Css.property "list-style-position" "inside"


list_item : Css.Style
list_item =
    Css.property "display" "list-item"


list_none : Css.Style
list_none =
    Css.property "list-style-type" "none"


list_outside : Css.Style
list_outside =
    Css.property "list-style-position" "outside"


lowercase : Css.Style
lowercase =
    Css.property "text-transform" "lowercase"


m_0 : Css.Style
m_0 =
    Css.property "margin" "0px"


m_0_dot_5 : Css.Style
m_0_dot_5 =
    Css.property "margin" "0.125rem"


m_1 : Css.Style
m_1 =
    Css.property "margin" "0.25rem"


m_10 : Css.Style
m_10 =
    Css.property "margin" "2.5rem"


m_11 : Css.Style
m_11 =
    Css.property "margin" "2.75rem"


m_12 : Css.Style
m_12 =
    Css.property "margin" "3rem"


m_14 : Css.Style
m_14 =
    Css.property "margin" "3.5rem"


m_16 : Css.Style
m_16 =
    Css.property "margin" "4rem"


m_1_dot_5 : Css.Style
m_1_dot_5 =
    Css.property "margin" "0.375rem"


m_2 : Css.Style
m_2 =
    Css.property "margin" "0.5rem"


m_20 : Css.Style
m_20 =
    Css.property "margin" "5rem"


m_24 : Css.Style
m_24 =
    Css.property "margin" "6rem"


m_28 : Css.Style
m_28 =
    Css.property "margin" "7rem"


m_2_dot_5 : Css.Style
m_2_dot_5 =
    Css.property "margin" "0.625rem"


m_3 : Css.Style
m_3 =
    Css.property "margin" "0.75rem"


m_32 : Css.Style
m_32 =
    Css.property "margin" "8rem"


m_36 : Css.Style
m_36 =
    Css.property "margin" "9rem"


m_3_dot_5 : Css.Style
m_3_dot_5 =
    Css.property "margin" "0.875rem"


m_4 : Css.Style
m_4 =
    Css.property "margin" "1rem"


m_40 : Css.Style
m_40 =
    Css.property "margin" "10rem"


m_44 : Css.Style
m_44 =
    Css.property "margin" "11rem"


m_48 : Css.Style
m_48 =
    Css.property "margin" "12rem"


m_5 : Css.Style
m_5 =
    Css.property "margin" "1.25rem"


m_52 : Css.Style
m_52 =
    Css.property "margin" "13rem"


m_56 : Css.Style
m_56 =
    Css.property "margin" "14rem"


m_6 : Css.Style
m_6 =
    Css.property "margin" "1.5rem"


m_60 : Css.Style
m_60 =
    Css.property "margin" "15rem"


m_64 : Css.Style
m_64 =
    Css.property "margin" "16rem"


m_7 : Css.Style
m_7 =
    Css.property "margin" "1.75rem"


m_72 : Css.Style
m_72 =
    Css.property "margin" "18rem"


m_8 : Css.Style
m_8 =
    Css.property "margin" "2rem"


m_80 : Css.Style
m_80 =
    Css.property "margin" "20rem"


m_9 : Css.Style
m_9 =
    Css.property "margin" "2.25rem"


m_96 : Css.Style
m_96 =
    Css.property "margin" "24rem"


m_auto : Css.Style
m_auto =
    Css.property "margin" "auto"


m_px : Css.Style
m_px =
    Css.property "margin" "1px"


max_h_0 : Css.Style
max_h_0 =
    Css.property "max-height" "0px"


max_h_0_dot_5 : Css.Style
max_h_0_dot_5 =
    Css.property "max-height" "0.125rem"


max_h_1 : Css.Style
max_h_1 =
    Css.property "max-height" "0.25rem"


max_h_10 : Css.Style
max_h_10 =
    Css.property "max-height" "2.5rem"


max_h_11 : Css.Style
max_h_11 =
    Css.property "max-height" "2.75rem"


max_h_12 : Css.Style
max_h_12 =
    Css.property "max-height" "3rem"


max_h_14 : Css.Style
max_h_14 =
    Css.property "max-height" "3.5rem"


max_h_16 : Css.Style
max_h_16 =
    Css.property "max-height" "4rem"


max_h_1_dot_5 : Css.Style
max_h_1_dot_5 =
    Css.property "max-height" "0.375rem"


max_h_2 : Css.Style
max_h_2 =
    Css.property "max-height" "0.5rem"


max_h_20 : Css.Style
max_h_20 =
    Css.property "max-height" "5rem"


max_h_24 : Css.Style
max_h_24 =
    Css.property "max-height" "6rem"


max_h_28 : Css.Style
max_h_28 =
    Css.property "max-height" "7rem"


max_h_2_dot_5 : Css.Style
max_h_2_dot_5 =
    Css.property "max-height" "0.625rem"


max_h_3 : Css.Style
max_h_3 =
    Css.property "max-height" "0.75rem"


max_h_32 : Css.Style
max_h_32 =
    Css.property "max-height" "8rem"


max_h_36 : Css.Style
max_h_36 =
    Css.property "max-height" "9rem"


max_h_3_dot_5 : Css.Style
max_h_3_dot_5 =
    Css.property "max-height" "0.875rem"


max_h_4 : Css.Style
max_h_4 =
    Css.property "max-height" "1rem"


max_h_40 : Css.Style
max_h_40 =
    Css.property "max-height" "10rem"


max_h_44 : Css.Style
max_h_44 =
    Css.property "max-height" "11rem"


max_h_48 : Css.Style
max_h_48 =
    Css.property "max-height" "12rem"


max_h_5 : Css.Style
max_h_5 =
    Css.property "max-height" "1.25rem"


max_h_52 : Css.Style
max_h_52 =
    Css.property "max-height" "13rem"


max_h_56 : Css.Style
max_h_56 =
    Css.property "max-height" "14rem"


max_h_6 : Css.Style
max_h_6 =
    Css.property "max-height" "1.5rem"


max_h_60 : Css.Style
max_h_60 =
    Css.property "max-height" "15rem"


max_h_64 : Css.Style
max_h_64 =
    Css.property "max-height" "16rem"


max_h_7 : Css.Style
max_h_7 =
    Css.property "max-height" "1.75rem"


max_h_72 : Css.Style
max_h_72 =
    Css.property "max-height" "18rem"


max_h_8 : Css.Style
max_h_8 =
    Css.property "max-height" "2rem"


max_h_80 : Css.Style
max_h_80 =
    Css.property "max-height" "20rem"


max_h_9 : Css.Style
max_h_9 =
    Css.property "max-height" "2.25rem"


max_h_96 : Css.Style
max_h_96 =
    Css.property "max-height" "24rem"


max_h_full : Css.Style
max_h_full =
    Css.property "max-height" "100%"


max_h_px : Css.Style
max_h_px =
    Css.property "max-height" "1px"


max_h_screen : Css.Style
max_h_screen =
    Css.property "max-height" "100vh"


max_w_0 : Css.Style
max_w_0 =
    Css.property "max-width" "0rem"


max_w_2xl : Css.Style
max_w_2xl =
    Css.property "max-width" "42rem"


max_w_3xl : Css.Style
max_w_3xl =
    Css.property "max-width" "48rem"


max_w_4xl : Css.Style
max_w_4xl =
    Css.property "max-width" "56rem"


max_w_5xl : Css.Style
max_w_5xl =
    Css.property "max-width" "64rem"


max_w_6xl : Css.Style
max_w_6xl =
    Css.property "max-width" "72rem"


max_w_7xl : Css.Style
max_w_7xl =
    Css.property "max-width" "80rem"


max_w_full : Css.Style
max_w_full =
    Css.property "max-width" "100%"


max_w_lg : Css.Style
max_w_lg =
    Css.property "max-width" "32rem"


max_w_max : Css.Style
max_w_max =
    Css.property "max-width" "max-content"


max_w_md : Css.Style
max_w_md =
    Css.property "max-width" "28rem"


max_w_min : Css.Style
max_w_min =
    Css.property "max-width" "min-content"


max_w_none : Css.Style
max_w_none =
    Css.property "max-width" "none"


max_w_prose : Css.Style
max_w_prose =
    Css.property "max-width" "65ch"


max_w_screen_2xl : Css.Style
max_w_screen_2xl =
    Css.property "max-width" "1536px"


max_w_screen_lg : Css.Style
max_w_screen_lg =
    Css.property "max-width" "1024px"


max_w_screen_md : Css.Style
max_w_screen_md =
    Css.property "max-width" "768px"


max_w_screen_sm : Css.Style
max_w_screen_sm =
    Css.property "max-width" "640px"


max_w_screen_xl : Css.Style
max_w_screen_xl =
    Css.property "max-width" "1280px"


max_w_sm : Css.Style
max_w_sm =
    Css.property "max-width" "24rem"


max_w_xl : Css.Style
max_w_xl =
    Css.property "max-width" "36rem"


max_w_xs : Css.Style
max_w_xs =
    Css.property "max-width" "20rem"


mb_0 : Css.Style
mb_0 =
    Css.property "margin-bottom" "0px"


mb_0_dot_5 : Css.Style
mb_0_dot_5 =
    Css.property "margin-bottom" "0.125rem"


mb_1 : Css.Style
mb_1 =
    Css.property "margin-bottom" "0.25rem"


mb_10 : Css.Style
mb_10 =
    Css.property "margin-bottom" "2.5rem"


mb_11 : Css.Style
mb_11 =
    Css.property "margin-bottom" "2.75rem"


mb_12 : Css.Style
mb_12 =
    Css.property "margin-bottom" "3rem"


mb_14 : Css.Style
mb_14 =
    Css.property "margin-bottom" "3.5rem"


mb_16 : Css.Style
mb_16 =
    Css.property "margin-bottom" "4rem"


mb_1_dot_5 : Css.Style
mb_1_dot_5 =
    Css.property "margin-bottom" "0.375rem"


mb_2 : Css.Style
mb_2 =
    Css.property "margin-bottom" "0.5rem"


mb_20 : Css.Style
mb_20 =
    Css.property "margin-bottom" "5rem"


mb_24 : Css.Style
mb_24 =
    Css.property "margin-bottom" "6rem"


mb_28 : Css.Style
mb_28 =
    Css.property "margin-bottom" "7rem"


mb_2_dot_5 : Css.Style
mb_2_dot_5 =
    Css.property "margin-bottom" "0.625rem"


mb_3 : Css.Style
mb_3 =
    Css.property "margin-bottom" "0.75rem"


mb_32 : Css.Style
mb_32 =
    Css.property "margin-bottom" "8rem"


mb_36 : Css.Style
mb_36 =
    Css.property "margin-bottom" "9rem"


mb_3_dot_5 : Css.Style
mb_3_dot_5 =
    Css.property "margin-bottom" "0.875rem"


mb_4 : Css.Style
mb_4 =
    Css.property "margin-bottom" "1rem"


mb_40 : Css.Style
mb_40 =
    Css.property "margin-bottom" "10rem"


mb_44 : Css.Style
mb_44 =
    Css.property "margin-bottom" "11rem"


mb_48 : Css.Style
mb_48 =
    Css.property "margin-bottom" "12rem"


mb_5 : Css.Style
mb_5 =
    Css.property "margin-bottom" "1.25rem"


mb_52 : Css.Style
mb_52 =
    Css.property "margin-bottom" "13rem"


mb_56 : Css.Style
mb_56 =
    Css.property "margin-bottom" "14rem"


mb_6 : Css.Style
mb_6 =
    Css.property "margin-bottom" "1.5rem"


mb_60 : Css.Style
mb_60 =
    Css.property "margin-bottom" "15rem"


mb_64 : Css.Style
mb_64 =
    Css.property "margin-bottom" "16rem"


mb_7 : Css.Style
mb_7 =
    Css.property "margin-bottom" "1.75rem"


mb_72 : Css.Style
mb_72 =
    Css.property "margin-bottom" "18rem"


mb_8 : Css.Style
mb_8 =
    Css.property "margin-bottom" "2rem"


mb_80 : Css.Style
mb_80 =
    Css.property "margin-bottom" "20rem"


mb_9 : Css.Style
mb_9 =
    Css.property "margin-bottom" "2.25rem"


mb_96 : Css.Style
mb_96 =
    Css.property "margin-bottom" "24rem"


mb_auto : Css.Style
mb_auto =
    Css.property "margin-bottom" "auto"


mb_px : Css.Style
mb_px =
    Css.property "margin-bottom" "1px"


min_h_0 : Css.Style
min_h_0 =
    Css.property "min-height" "0px"


min_h_full : Css.Style
min_h_full =
    Css.property "min-height" "100%"


min_h_screen : Css.Style
min_h_screen =
    Css.property "min-height" "100vh"


min_w_0 : Css.Style
min_w_0 =
    Css.property "min-width" "0px"


min_w_full : Css.Style
min_w_full =
    Css.property "min-width" "100%"


min_w_max : Css.Style
min_w_max =
    Css.property "min-width" "max-content"


min_w_min : Css.Style
min_w_min =
    Css.property "min-width" "min-content"


mix_blend_color : Css.Style
mix_blend_color =
    Css.property "mix-blend-mode" "color"


mix_blend_color_burn : Css.Style
mix_blend_color_burn =
    Css.property "mix-blend-mode" "color-burn"


mix_blend_color_dodge : Css.Style
mix_blend_color_dodge =
    Css.property "mix-blend-mode" "color-dodge"


mix_blend_darken : Css.Style
mix_blend_darken =
    Css.property "mix-blend-mode" "darken"


mix_blend_difference : Css.Style
mix_blend_difference =
    Css.property "mix-blend-mode" "difference"


mix_blend_exclusion : Css.Style
mix_blend_exclusion =
    Css.property "mix-blend-mode" "exclusion"


mix_blend_hard_light : Css.Style
mix_blend_hard_light =
    Css.property "mix-blend-mode" "hard-light"


mix_blend_hue : Css.Style
mix_blend_hue =
    Css.property "mix-blend-mode" "hue"


mix_blend_lighten : Css.Style
mix_blend_lighten =
    Css.property "mix-blend-mode" "lighten"


mix_blend_luminosity : Css.Style
mix_blend_luminosity =
    Css.property "mix-blend-mode" "luminosity"


mix_blend_multiply : Css.Style
mix_blend_multiply =
    Css.property "mix-blend-mode" "multiply"


mix_blend_normal : Css.Style
mix_blend_normal =
    Css.property "mix-blend-mode" "normal"


mix_blend_overlay : Css.Style
mix_blend_overlay =
    Css.property "mix-blend-mode" "overlay"


mix_blend_saturation : Css.Style
mix_blend_saturation =
    Css.property "mix-blend-mode" "saturation"


mix_blend_screen : Css.Style
mix_blend_screen =
    Css.property "mix-blend-mode" "screen"


mix_blend_soft_light : Css.Style
mix_blend_soft_light =
    Css.property "mix-blend-mode" "soft-light"


ml_0 : Css.Style
ml_0 =
    Css.property "margin-left" "0px"


ml_0_dot_5 : Css.Style
ml_0_dot_5 =
    Css.property "margin-left" "0.125rem"


ml_1 : Css.Style
ml_1 =
    Css.property "margin-left" "0.25rem"


ml_10 : Css.Style
ml_10 =
    Css.property "margin-left" "2.5rem"


ml_11 : Css.Style
ml_11 =
    Css.property "margin-left" "2.75rem"


ml_12 : Css.Style
ml_12 =
    Css.property "margin-left" "3rem"


ml_14 : Css.Style
ml_14 =
    Css.property "margin-left" "3.5rem"


ml_16 : Css.Style
ml_16 =
    Css.property "margin-left" "4rem"


ml_1_dot_5 : Css.Style
ml_1_dot_5 =
    Css.property "margin-left" "0.375rem"


ml_2 : Css.Style
ml_2 =
    Css.property "margin-left" "0.5rem"


ml_20 : Css.Style
ml_20 =
    Css.property "margin-left" "5rem"


ml_24 : Css.Style
ml_24 =
    Css.property "margin-left" "6rem"


ml_28 : Css.Style
ml_28 =
    Css.property "margin-left" "7rem"


ml_2_dot_5 : Css.Style
ml_2_dot_5 =
    Css.property "margin-left" "0.625rem"


ml_3 : Css.Style
ml_3 =
    Css.property "margin-left" "0.75rem"


ml_32 : Css.Style
ml_32 =
    Css.property "margin-left" "8rem"


ml_36 : Css.Style
ml_36 =
    Css.property "margin-left" "9rem"


ml_3_dot_5 : Css.Style
ml_3_dot_5 =
    Css.property "margin-left" "0.875rem"


ml_4 : Css.Style
ml_4 =
    Css.property "margin-left" "1rem"


ml_40 : Css.Style
ml_40 =
    Css.property "margin-left" "10rem"


ml_44 : Css.Style
ml_44 =
    Css.property "margin-left" "11rem"


ml_48 : Css.Style
ml_48 =
    Css.property "margin-left" "12rem"


ml_5 : Css.Style
ml_5 =
    Css.property "margin-left" "1.25rem"


ml_52 : Css.Style
ml_52 =
    Css.property "margin-left" "13rem"


ml_56 : Css.Style
ml_56 =
    Css.property "margin-left" "14rem"


ml_6 : Css.Style
ml_6 =
    Css.property "margin-left" "1.5rem"


ml_60 : Css.Style
ml_60 =
    Css.property "margin-left" "15rem"


ml_64 : Css.Style
ml_64 =
    Css.property "margin-left" "16rem"


ml_7 : Css.Style
ml_7 =
    Css.property "margin-left" "1.75rem"


ml_72 : Css.Style
ml_72 =
    Css.property "margin-left" "18rem"


ml_8 : Css.Style
ml_8 =
    Css.property "margin-left" "2rem"


ml_80 : Css.Style
ml_80 =
    Css.property "margin-left" "20rem"


ml_9 : Css.Style
ml_9 =
    Css.property "margin-left" "2.25rem"


ml_96 : Css.Style
ml_96 =
    Css.property "margin-left" "24rem"


ml_auto : Css.Style
ml_auto =
    Css.property "margin-left" "auto"


ml_px : Css.Style
ml_px =
    Css.property "margin-left" "1px"


mr_0 : Css.Style
mr_0 =
    Css.property "margin-right" "0px"


mr_0_dot_5 : Css.Style
mr_0_dot_5 =
    Css.property "margin-right" "0.125rem"


mr_1 : Css.Style
mr_1 =
    Css.property "margin-right" "0.25rem"


mr_10 : Css.Style
mr_10 =
    Css.property "margin-right" "2.5rem"


mr_11 : Css.Style
mr_11 =
    Css.property "margin-right" "2.75rem"


mr_12 : Css.Style
mr_12 =
    Css.property "margin-right" "3rem"


mr_14 : Css.Style
mr_14 =
    Css.property "margin-right" "3.5rem"


mr_16 : Css.Style
mr_16 =
    Css.property "margin-right" "4rem"


mr_1_dot_5 : Css.Style
mr_1_dot_5 =
    Css.property "margin-right" "0.375rem"


mr_2 : Css.Style
mr_2 =
    Css.property "margin-right" "0.5rem"


mr_20 : Css.Style
mr_20 =
    Css.property "margin-right" "5rem"


mr_24 : Css.Style
mr_24 =
    Css.property "margin-right" "6rem"


mr_28 : Css.Style
mr_28 =
    Css.property "margin-right" "7rem"


mr_2_dot_5 : Css.Style
mr_2_dot_5 =
    Css.property "margin-right" "0.625rem"


mr_3 : Css.Style
mr_3 =
    Css.property "margin-right" "0.75rem"


mr_32 : Css.Style
mr_32 =
    Css.property "margin-right" "8rem"


mr_36 : Css.Style
mr_36 =
    Css.property "margin-right" "9rem"


mr_3_dot_5 : Css.Style
mr_3_dot_5 =
    Css.property "margin-right" "0.875rem"


mr_4 : Css.Style
mr_4 =
    Css.property "margin-right" "1rem"


mr_40 : Css.Style
mr_40 =
    Css.property "margin-right" "10rem"


mr_44 : Css.Style
mr_44 =
    Css.property "margin-right" "11rem"


mr_48 : Css.Style
mr_48 =
    Css.property "margin-right" "12rem"


mr_5 : Css.Style
mr_5 =
    Css.property "margin-right" "1.25rem"


mr_52 : Css.Style
mr_52 =
    Css.property "margin-right" "13rem"


mr_56 : Css.Style
mr_56 =
    Css.property "margin-right" "14rem"


mr_6 : Css.Style
mr_6 =
    Css.property "margin-right" "1.5rem"


mr_60 : Css.Style
mr_60 =
    Css.property "margin-right" "15rem"


mr_64 : Css.Style
mr_64 =
    Css.property "margin-right" "16rem"


mr_7 : Css.Style
mr_7 =
    Css.property "margin-right" "1.75rem"


mr_72 : Css.Style
mr_72 =
    Css.property "margin-right" "18rem"


mr_8 : Css.Style
mr_8 =
    Css.property "margin-right" "2rem"


mr_80 : Css.Style
mr_80 =
    Css.property "margin-right" "20rem"


mr_9 : Css.Style
mr_9 =
    Css.property "margin-right" "2.25rem"


mr_96 : Css.Style
mr_96 =
    Css.property "margin-right" "24rem"


mr_auto : Css.Style
mr_auto =
    Css.property "margin-right" "auto"


mr_px : Css.Style
mr_px =
    Css.property "margin-right" "1px"


mt_0 : Css.Style
mt_0 =
    Css.property "margin-top" "0px"


mt_0_dot_5 : Css.Style
mt_0_dot_5 =
    Css.property "margin-top" "0.125rem"


mt_1 : Css.Style
mt_1 =
    Css.property "margin-top" "0.25rem"


mt_10 : Css.Style
mt_10 =
    Css.property "margin-top" "2.5rem"


mt_11 : Css.Style
mt_11 =
    Css.property "margin-top" "2.75rem"


mt_12 : Css.Style
mt_12 =
    Css.property "margin-top" "3rem"


mt_14 : Css.Style
mt_14 =
    Css.property "margin-top" "3.5rem"


mt_16 : Css.Style
mt_16 =
    Css.property "margin-top" "4rem"


mt_1_dot_5 : Css.Style
mt_1_dot_5 =
    Css.property "margin-top" "0.375rem"


mt_2 : Css.Style
mt_2 =
    Css.property "margin-top" "0.5rem"


mt_20 : Css.Style
mt_20 =
    Css.property "margin-top" "5rem"


mt_24 : Css.Style
mt_24 =
    Css.property "margin-top" "6rem"


mt_28 : Css.Style
mt_28 =
    Css.property "margin-top" "7rem"


mt_2_dot_5 : Css.Style
mt_2_dot_5 =
    Css.property "margin-top" "0.625rem"


mt_3 : Css.Style
mt_3 =
    Css.property "margin-top" "0.75rem"


mt_32 : Css.Style
mt_32 =
    Css.property "margin-top" "8rem"


mt_36 : Css.Style
mt_36 =
    Css.property "margin-top" "9rem"


mt_3_dot_5 : Css.Style
mt_3_dot_5 =
    Css.property "margin-top" "0.875rem"


mt_4 : Css.Style
mt_4 =
    Css.property "margin-top" "1rem"


mt_40 : Css.Style
mt_40 =
    Css.property "margin-top" "10rem"


mt_44 : Css.Style
mt_44 =
    Css.property "margin-top" "11rem"


mt_48 : Css.Style
mt_48 =
    Css.property "margin-top" "12rem"


mt_5 : Css.Style
mt_5 =
    Css.property "margin-top" "1.25rem"


mt_52 : Css.Style
mt_52 =
    Css.property "margin-top" "13rem"


mt_56 : Css.Style
mt_56 =
    Css.property "margin-top" "14rem"


mt_6 : Css.Style
mt_6 =
    Css.property "margin-top" "1.5rem"


mt_60 : Css.Style
mt_60 =
    Css.property "margin-top" "15rem"


mt_64 : Css.Style
mt_64 =
    Css.property "margin-top" "16rem"


mt_7 : Css.Style
mt_7 =
    Css.property "margin-top" "1.75rem"


mt_72 : Css.Style
mt_72 =
    Css.property "margin-top" "18rem"


mt_8 : Css.Style
mt_8 =
    Css.property "margin-top" "2rem"


mt_80 : Css.Style
mt_80 =
    Css.property "margin-top" "20rem"


mt_9 : Css.Style
mt_9 =
    Css.property "margin-top" "2.25rem"


mt_96 : Css.Style
mt_96 =
    Css.property "margin-top" "24rem"


mt_auto : Css.Style
mt_auto =
    Css.property "margin-top" "auto"


mt_px : Css.Style
mt_px =
    Css.property "margin-top" "1px"


mx_0 : Css.Style
mx_0 =
    Css.batch
        [ Css.property "margin-left" "0px"
        , Css.property "margin-right" "0px"
        ]


mx_0_dot_5 : Css.Style
mx_0_dot_5 =
    Css.batch
        [ Css.property "margin-left" "0.125rem"
        , Css.property "margin-right" "0.125rem"
        ]


mx_1 : Css.Style
mx_1 =
    Css.batch
        [ Css.property "margin-left" "0.25rem"
        , Css.property "margin-right" "0.25rem"
        ]


mx_10 : Css.Style
mx_10 =
    Css.batch
        [ Css.property "margin-left" "2.5rem"
        , Css.property "margin-right" "2.5rem"
        ]


mx_11 : Css.Style
mx_11 =
    Css.batch
        [ Css.property "margin-left" "2.75rem"
        , Css.property "margin-right" "2.75rem"
        ]


mx_12 : Css.Style
mx_12 =
    Css.batch
        [ Css.property "margin-left" "3rem"
        , Css.property "margin-right" "3rem"
        ]


mx_14 : Css.Style
mx_14 =
    Css.batch
        [ Css.property "margin-left" "3.5rem"
        , Css.property "margin-right" "3.5rem"
        ]


mx_16 : Css.Style
mx_16 =
    Css.batch
        [ Css.property "margin-left" "4rem"
        , Css.property "margin-right" "4rem"
        ]


mx_1_dot_5 : Css.Style
mx_1_dot_5 =
    Css.batch
        [ Css.property "margin-left" "0.375rem"
        , Css.property "margin-right" "0.375rem"
        ]


mx_2 : Css.Style
mx_2 =
    Css.batch
        [ Css.property "margin-left" "0.5rem"
        , Css.property "margin-right" "0.5rem"
        ]


mx_20 : Css.Style
mx_20 =
    Css.batch
        [ Css.property "margin-left" "5rem"
        , Css.property "margin-right" "5rem"
        ]


mx_24 : Css.Style
mx_24 =
    Css.batch
        [ Css.property "margin-left" "6rem"
        , Css.property "margin-right" "6rem"
        ]


mx_28 : Css.Style
mx_28 =
    Css.batch
        [ Css.property "margin-left" "7rem"
        , Css.property "margin-right" "7rem"
        ]


mx_2_dot_5 : Css.Style
mx_2_dot_5 =
    Css.batch
        [ Css.property "margin-left" "0.625rem"
        , Css.property "margin-right" "0.625rem"
        ]


mx_3 : Css.Style
mx_3 =
    Css.batch
        [ Css.property "margin-left" "0.75rem"
        , Css.property "margin-right" "0.75rem"
        ]


mx_32 : Css.Style
mx_32 =
    Css.batch
        [ Css.property "margin-left" "8rem"
        , Css.property "margin-right" "8rem"
        ]


mx_36 : Css.Style
mx_36 =
    Css.batch
        [ Css.property "margin-left" "9rem"
        , Css.property "margin-right" "9rem"
        ]


mx_3_dot_5 : Css.Style
mx_3_dot_5 =
    Css.batch
        [ Css.property "margin-left" "0.875rem"
        , Css.property "margin-right" "0.875rem"
        ]


mx_4 : Css.Style
mx_4 =
    Css.batch
        [ Css.property "margin-left" "1rem"
        , Css.property "margin-right" "1rem"
        ]


mx_40 : Css.Style
mx_40 =
    Css.batch
        [ Css.property "margin-left" "10rem"
        , Css.property "margin-right" "10rem"
        ]


mx_44 : Css.Style
mx_44 =
    Css.batch
        [ Css.property "margin-left" "11rem"
        , Css.property "margin-right" "11rem"
        ]


mx_48 : Css.Style
mx_48 =
    Css.batch
        [ Css.property "margin-left" "12rem"
        , Css.property "margin-right" "12rem"
        ]


mx_5 : Css.Style
mx_5 =
    Css.batch
        [ Css.property "margin-left" "1.25rem"
        , Css.property "margin-right" "1.25rem"
        ]


mx_52 : Css.Style
mx_52 =
    Css.batch
        [ Css.property "margin-left" "13rem"
        , Css.property "margin-right" "13rem"
        ]


mx_56 : Css.Style
mx_56 =
    Css.batch
        [ Css.property "margin-left" "14rem"
        , Css.property "margin-right" "14rem"
        ]


mx_6 : Css.Style
mx_6 =
    Css.batch
        [ Css.property "margin-left" "1.5rem"
        , Css.property "margin-right" "1.5rem"
        ]


mx_60 : Css.Style
mx_60 =
    Css.batch
        [ Css.property "margin-left" "15rem"
        , Css.property "margin-right" "15rem"
        ]


mx_64 : Css.Style
mx_64 =
    Css.batch
        [ Css.property "margin-left" "16rem"
        , Css.property "margin-right" "16rem"
        ]


mx_7 : Css.Style
mx_7 =
    Css.batch
        [ Css.property "margin-left" "1.75rem"
        , Css.property "margin-right" "1.75rem"
        ]


mx_72 : Css.Style
mx_72 =
    Css.batch
        [ Css.property "margin-left" "18rem"
        , Css.property "margin-right" "18rem"
        ]


mx_8 : Css.Style
mx_8 =
    Css.batch
        [ Css.property "margin-left" "2rem"
        , Css.property "margin-right" "2rem"
        ]


mx_80 : Css.Style
mx_80 =
    Css.batch
        [ Css.property "margin-left" "20rem"
        , Css.property "margin-right" "20rem"
        ]


mx_9 : Css.Style
mx_9 =
    Css.batch
        [ Css.property "margin-left" "2.25rem"
        , Css.property "margin-right" "2.25rem"
        ]


mx_96 : Css.Style
mx_96 =
    Css.batch
        [ Css.property "margin-left" "24rem"
        , Css.property "margin-right" "24rem"
        ]


mx_auto : Css.Style
mx_auto =
    Css.batch
        [ Css.property "margin-left" "auto"
        , Css.property "margin-right" "auto"
        ]


mx_px : Css.Style
mx_px =
    Css.batch
        [ Css.property "margin-left" "1px"
        , Css.property "margin-right" "1px"
        ]


my_0 : Css.Style
my_0 =
    Css.batch
        [ Css.property "margin-top" "0px"
        , Css.property "margin-bottom" "0px"
        ]


my_0_dot_5 : Css.Style
my_0_dot_5 =
    Css.batch
        [ Css.property "margin-top" "0.125rem"
        , Css.property "margin-bottom" "0.125rem"
        ]


my_1 : Css.Style
my_1 =
    Css.batch
        [ Css.property "margin-top" "0.25rem"
        , Css.property "margin-bottom" "0.25rem"
        ]


my_10 : Css.Style
my_10 =
    Css.batch
        [ Css.property "margin-top" "2.5rem"
        , Css.property "margin-bottom" "2.5rem"
        ]


my_11 : Css.Style
my_11 =
    Css.batch
        [ Css.property "margin-top" "2.75rem"
        , Css.property "margin-bottom" "2.75rem"
        ]


my_12 : Css.Style
my_12 =
    Css.batch
        [ Css.property "margin-top" "3rem"
        , Css.property "margin-bottom" "3rem"
        ]


my_14 : Css.Style
my_14 =
    Css.batch
        [ Css.property "margin-top" "3.5rem"
        , Css.property "margin-bottom" "3.5rem"
        ]


my_16 : Css.Style
my_16 =
    Css.batch
        [ Css.property "margin-top" "4rem"
        , Css.property "margin-bottom" "4rem"
        ]


my_1_dot_5 : Css.Style
my_1_dot_5 =
    Css.batch
        [ Css.property "margin-top" "0.375rem"
        , Css.property "margin-bottom" "0.375rem"
        ]


my_2 : Css.Style
my_2 =
    Css.batch
        [ Css.property "margin-top" "0.5rem"
        , Css.property "margin-bottom" "0.5rem"
        ]


my_20 : Css.Style
my_20 =
    Css.batch
        [ Css.property "margin-top" "5rem"
        , Css.property "margin-bottom" "5rem"
        ]


my_24 : Css.Style
my_24 =
    Css.batch
        [ Css.property "margin-top" "6rem"
        , Css.property "margin-bottom" "6rem"
        ]


my_28 : Css.Style
my_28 =
    Css.batch
        [ Css.property "margin-top" "7rem"
        , Css.property "margin-bottom" "7rem"
        ]


my_2_dot_5 : Css.Style
my_2_dot_5 =
    Css.batch
        [ Css.property "margin-top" "0.625rem"
        , Css.property "margin-bottom" "0.625rem"
        ]


my_3 : Css.Style
my_3 =
    Css.batch
        [ Css.property "margin-top" "0.75rem"
        , Css.property "margin-bottom" "0.75rem"
        ]


my_32 : Css.Style
my_32 =
    Css.batch
        [ Css.property "margin-top" "8rem"
        , Css.property "margin-bottom" "8rem"
        ]


my_36 : Css.Style
my_36 =
    Css.batch
        [ Css.property "margin-top" "9rem"
        , Css.property "margin-bottom" "9rem"
        ]


my_3_dot_5 : Css.Style
my_3_dot_5 =
    Css.batch
        [ Css.property "margin-top" "0.875rem"
        , Css.property "margin-bottom" "0.875rem"
        ]


my_4 : Css.Style
my_4 =
    Css.batch
        [ Css.property "margin-top" "1rem"
        , Css.property "margin-bottom" "1rem"
        ]


my_40 : Css.Style
my_40 =
    Css.batch
        [ Css.property "margin-top" "10rem"
        , Css.property "margin-bottom" "10rem"
        ]


my_44 : Css.Style
my_44 =
    Css.batch
        [ Css.property "margin-top" "11rem"
        , Css.property "margin-bottom" "11rem"
        ]


my_48 : Css.Style
my_48 =
    Css.batch
        [ Css.property "margin-top" "12rem"
        , Css.property "margin-bottom" "12rem"
        ]


my_5 : Css.Style
my_5 =
    Css.batch
        [ Css.property "margin-top" "1.25rem"
        , Css.property "margin-bottom" "1.25rem"
        ]


my_52 : Css.Style
my_52 =
    Css.batch
        [ Css.property "margin-top" "13rem"
        , Css.property "margin-bottom" "13rem"
        ]


my_56 : Css.Style
my_56 =
    Css.batch
        [ Css.property "margin-top" "14rem"
        , Css.property "margin-bottom" "14rem"
        ]


my_6 : Css.Style
my_6 =
    Css.batch
        [ Css.property "margin-top" "1.5rem"
        , Css.property "margin-bottom" "1.5rem"
        ]


my_60 : Css.Style
my_60 =
    Css.batch
        [ Css.property "margin-top" "15rem"
        , Css.property "margin-bottom" "15rem"
        ]


my_64 : Css.Style
my_64 =
    Css.batch
        [ Css.property "margin-top" "16rem"
        , Css.property "margin-bottom" "16rem"
        ]


my_7 : Css.Style
my_7 =
    Css.batch
        [ Css.property "margin-top" "1.75rem"
        , Css.property "margin-bottom" "1.75rem"
        ]


my_72 : Css.Style
my_72 =
    Css.batch
        [ Css.property "margin-top" "18rem"
        , Css.property "margin-bottom" "18rem"
        ]


my_8 : Css.Style
my_8 =
    Css.batch
        [ Css.property "margin-top" "2rem"
        , Css.property "margin-bottom" "2rem"
        ]


my_80 : Css.Style
my_80 =
    Css.batch
        [ Css.property "margin-top" "20rem"
        , Css.property "margin-bottom" "20rem"
        ]


my_9 : Css.Style
my_9 =
    Css.batch
        [ Css.property "margin-top" "2.25rem"
        , Css.property "margin-bottom" "2.25rem"
        ]


my_96 : Css.Style
my_96 =
    Css.batch
        [ Css.property "margin-top" "24rem"
        , Css.property "margin-bottom" "24rem"
        ]


my_auto : Css.Style
my_auto =
    Css.batch
        [ Css.property "margin-top" "auto"
        , Css.property "margin-bottom" "auto"
        ]


my_px : Css.Style
my_px =
    Css.batch
        [ Css.property "margin-top" "1px"
        , Css.property "margin-bottom" "1px"
        ]


neg_backdrop_hue_rotate_15 : Css.Style
neg_backdrop_hue_rotate_15 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(-15deg)"


neg_backdrop_hue_rotate_180 : Css.Style
neg_backdrop_hue_rotate_180 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(-180deg)"


neg_backdrop_hue_rotate_30 : Css.Style
neg_backdrop_hue_rotate_30 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(-30deg)"


neg_backdrop_hue_rotate_60 : Css.Style
neg_backdrop_hue_rotate_60 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(-60deg)"


neg_backdrop_hue_rotate_90 : Css.Style
neg_backdrop_hue_rotate_90 =
    Css.property "--tw-backdrop-hue-rotate" "hue-rotate(-90deg)"


neg_bottom_0 : Css.Style
neg_bottom_0 =
    Css.property "bottom" "0px"


neg_bottom_0_dot_5 : Css.Style
neg_bottom_0_dot_5 =
    Css.property "bottom" "-0.125rem"


neg_bottom_1 : Css.Style
neg_bottom_1 =
    Css.property "bottom" "-0.25rem"


neg_bottom_10 : Css.Style
neg_bottom_10 =
    Css.property "bottom" "-2.5rem"


neg_bottom_11 : Css.Style
neg_bottom_11 =
    Css.property "bottom" "-2.75rem"


neg_bottom_12 : Css.Style
neg_bottom_12 =
    Css.property "bottom" "-3rem"


neg_bottom_14 : Css.Style
neg_bottom_14 =
    Css.property "bottom" "-3.5rem"


neg_bottom_16 : Css.Style
neg_bottom_16 =
    Css.property "bottom" "-4rem"


neg_bottom_1_dot_5 : Css.Style
neg_bottom_1_dot_5 =
    Css.property "bottom" "-0.375rem"


neg_bottom_1over2 : Css.Style
neg_bottom_1over2 =
    Css.property "bottom" "-50%"


neg_bottom_1over3 : Css.Style
neg_bottom_1over3 =
    Css.property "bottom" "-33.333333%"


neg_bottom_1over4 : Css.Style
neg_bottom_1over4 =
    Css.property "bottom" "-25%"


neg_bottom_2 : Css.Style
neg_bottom_2 =
    Css.property "bottom" "-0.5rem"


neg_bottom_20 : Css.Style
neg_bottom_20 =
    Css.property "bottom" "-5rem"


neg_bottom_24 : Css.Style
neg_bottom_24 =
    Css.property "bottom" "-6rem"


neg_bottom_28 : Css.Style
neg_bottom_28 =
    Css.property "bottom" "-7rem"


neg_bottom_2_dot_5 : Css.Style
neg_bottom_2_dot_5 =
    Css.property "bottom" "-0.625rem"


neg_bottom_2over3 : Css.Style
neg_bottom_2over3 =
    Css.property "bottom" "-66.666667%"


neg_bottom_2over4 : Css.Style
neg_bottom_2over4 =
    Css.property "bottom" "-50%"


neg_bottom_3 : Css.Style
neg_bottom_3 =
    Css.property "bottom" "-0.75rem"


neg_bottom_32 : Css.Style
neg_bottom_32 =
    Css.property "bottom" "-8rem"


neg_bottom_36 : Css.Style
neg_bottom_36 =
    Css.property "bottom" "-9rem"


neg_bottom_3_dot_5 : Css.Style
neg_bottom_3_dot_5 =
    Css.property "bottom" "-0.875rem"


neg_bottom_3over4 : Css.Style
neg_bottom_3over4 =
    Css.property "bottom" "-75%"


neg_bottom_4 : Css.Style
neg_bottom_4 =
    Css.property "bottom" "-1rem"


neg_bottom_40 : Css.Style
neg_bottom_40 =
    Css.property "bottom" "-10rem"


neg_bottom_44 : Css.Style
neg_bottom_44 =
    Css.property "bottom" "-11rem"


neg_bottom_48 : Css.Style
neg_bottom_48 =
    Css.property "bottom" "-12rem"


neg_bottom_5 : Css.Style
neg_bottom_5 =
    Css.property "bottom" "-1.25rem"


neg_bottom_52 : Css.Style
neg_bottom_52 =
    Css.property "bottom" "-13rem"


neg_bottom_56 : Css.Style
neg_bottom_56 =
    Css.property "bottom" "-14rem"


neg_bottom_6 : Css.Style
neg_bottom_6 =
    Css.property "bottom" "-1.5rem"


neg_bottom_60 : Css.Style
neg_bottom_60 =
    Css.property "bottom" "-15rem"


neg_bottom_64 : Css.Style
neg_bottom_64 =
    Css.property "bottom" "-16rem"


neg_bottom_7 : Css.Style
neg_bottom_7 =
    Css.property "bottom" "-1.75rem"


neg_bottom_72 : Css.Style
neg_bottom_72 =
    Css.property "bottom" "-18rem"


neg_bottom_8 : Css.Style
neg_bottom_8 =
    Css.property "bottom" "-2rem"


neg_bottom_80 : Css.Style
neg_bottom_80 =
    Css.property "bottom" "-20rem"


neg_bottom_9 : Css.Style
neg_bottom_9 =
    Css.property "bottom" "-2.25rem"


neg_bottom_96 : Css.Style
neg_bottom_96 =
    Css.property "bottom" "-24rem"


neg_bottom_full : Css.Style
neg_bottom_full =
    Css.property "bottom" "-100%"


neg_bottom_px : Css.Style
neg_bottom_px =
    Css.property "bottom" "-1px"


neg_hue_rotate_15 : Css.Style
neg_hue_rotate_15 =
    Css.property "--tw-hue-rotate" "hue-rotate(-15deg)"


neg_hue_rotate_180 : Css.Style
neg_hue_rotate_180 =
    Css.property "--tw-hue-rotate" "hue-rotate(-180deg)"


neg_hue_rotate_30 : Css.Style
neg_hue_rotate_30 =
    Css.property "--tw-hue-rotate" "hue-rotate(-30deg)"


neg_hue_rotate_60 : Css.Style
neg_hue_rotate_60 =
    Css.property "--tw-hue-rotate" "hue-rotate(-60deg)"


neg_hue_rotate_90 : Css.Style
neg_hue_rotate_90 =
    Css.property "--tw-hue-rotate" "hue-rotate(-90deg)"


neg_inset_0 : Css.Style
neg_inset_0 =
    Css.batch
        [ Css.property "top" "0px"
        , Css.property "right" "0px"
        , Css.property "bottom" "0px"
        , Css.property "left" "0px"
        ]


neg_inset_0_dot_5 : Css.Style
neg_inset_0_dot_5 =
    Css.batch
        [ Css.property "top" "-0.125rem"
        , Css.property "right" "-0.125rem"
        , Css.property "bottom" "-0.125rem"
        , Css.property "left" "-0.125rem"
        ]


neg_inset_1 : Css.Style
neg_inset_1 =
    Css.batch
        [ Css.property "top" "-0.25rem"
        , Css.property "right" "-0.25rem"
        , Css.property "bottom" "-0.25rem"
        , Css.property "left" "-0.25rem"
        ]


neg_inset_10 : Css.Style
neg_inset_10 =
    Css.batch
        [ Css.property "top" "-2.5rem"
        , Css.property "right" "-2.5rem"
        , Css.property "bottom" "-2.5rem"
        , Css.property "left" "-2.5rem"
        ]


neg_inset_11 : Css.Style
neg_inset_11 =
    Css.batch
        [ Css.property "top" "-2.75rem"
        , Css.property "right" "-2.75rem"
        , Css.property "bottom" "-2.75rem"
        , Css.property "left" "-2.75rem"
        ]


neg_inset_12 : Css.Style
neg_inset_12 =
    Css.batch
        [ Css.property "top" "-3rem"
        , Css.property "right" "-3rem"
        , Css.property "bottom" "-3rem"
        , Css.property "left" "-3rem"
        ]


neg_inset_14 : Css.Style
neg_inset_14 =
    Css.batch
        [ Css.property "top" "-3.5rem"
        , Css.property "right" "-3.5rem"
        , Css.property "bottom" "-3.5rem"
        , Css.property "left" "-3.5rem"
        ]


neg_inset_16 : Css.Style
neg_inset_16 =
    Css.batch
        [ Css.property "top" "-4rem"
        , Css.property "right" "-4rem"
        , Css.property "bottom" "-4rem"
        , Css.property "left" "-4rem"
        ]


neg_inset_1_dot_5 : Css.Style
neg_inset_1_dot_5 =
    Css.batch
        [ Css.property "top" "-0.375rem"
        , Css.property "right" "-0.375rem"
        , Css.property "bottom" "-0.375rem"
        , Css.property "left" "-0.375rem"
        ]


neg_inset_1over2 : Css.Style
neg_inset_1over2 =
    Css.batch
        [ Css.property "top" "-50%"
        , Css.property "right" "-50%"
        , Css.property "bottom" "-50%"
        , Css.property "left" "-50%"
        ]


neg_inset_1over3 : Css.Style
neg_inset_1over3 =
    Css.batch
        [ Css.property "top" "-33.333333%"
        , Css.property "right" "-33.333333%"
        , Css.property "bottom" "-33.333333%"
        , Css.property "left" "-33.333333%"
        ]


neg_inset_1over4 : Css.Style
neg_inset_1over4 =
    Css.batch
        [ Css.property "top" "-25%"
        , Css.property "right" "-25%"
        , Css.property "bottom" "-25%"
        , Css.property "left" "-25%"
        ]


neg_inset_2 : Css.Style
neg_inset_2 =
    Css.batch
        [ Css.property "top" "-0.5rem"
        , Css.property "right" "-0.5rem"
        , Css.property "bottom" "-0.5rem"
        , Css.property "left" "-0.5rem"
        ]


neg_inset_20 : Css.Style
neg_inset_20 =
    Css.batch
        [ Css.property "top" "-5rem"
        , Css.property "right" "-5rem"
        , Css.property "bottom" "-5rem"
        , Css.property "left" "-5rem"
        ]


neg_inset_24 : Css.Style
neg_inset_24 =
    Css.batch
        [ Css.property "top" "-6rem"
        , Css.property "right" "-6rem"
        , Css.property "bottom" "-6rem"
        , Css.property "left" "-6rem"
        ]


neg_inset_28 : Css.Style
neg_inset_28 =
    Css.batch
        [ Css.property "top" "-7rem"
        , Css.property "right" "-7rem"
        , Css.property "bottom" "-7rem"
        , Css.property "left" "-7rem"
        ]


neg_inset_2_dot_5 : Css.Style
neg_inset_2_dot_5 =
    Css.batch
        [ Css.property "top" "-0.625rem"
        , Css.property "right" "-0.625rem"
        , Css.property "bottom" "-0.625rem"
        , Css.property "left" "-0.625rem"
        ]


neg_inset_2over3 : Css.Style
neg_inset_2over3 =
    Css.batch
        [ Css.property "top" "-66.666667%"
        , Css.property "right" "-66.666667%"
        , Css.property "bottom" "-66.666667%"
        , Css.property "left" "-66.666667%"
        ]


neg_inset_2over4 : Css.Style
neg_inset_2over4 =
    Css.batch
        [ Css.property "top" "-50%"
        , Css.property "right" "-50%"
        , Css.property "bottom" "-50%"
        , Css.property "left" "-50%"
        ]


neg_inset_3 : Css.Style
neg_inset_3 =
    Css.batch
        [ Css.property "top" "-0.75rem"
        , Css.property "right" "-0.75rem"
        , Css.property "bottom" "-0.75rem"
        , Css.property "left" "-0.75rem"
        ]


neg_inset_32 : Css.Style
neg_inset_32 =
    Css.batch
        [ Css.property "top" "-8rem"
        , Css.property "right" "-8rem"
        , Css.property "bottom" "-8rem"
        , Css.property "left" "-8rem"
        ]


neg_inset_36 : Css.Style
neg_inset_36 =
    Css.batch
        [ Css.property "top" "-9rem"
        , Css.property "right" "-9rem"
        , Css.property "bottom" "-9rem"
        , Css.property "left" "-9rem"
        ]


neg_inset_3_dot_5 : Css.Style
neg_inset_3_dot_5 =
    Css.batch
        [ Css.property "top" "-0.875rem"
        , Css.property "right" "-0.875rem"
        , Css.property "bottom" "-0.875rem"
        , Css.property "left" "-0.875rem"
        ]


neg_inset_3over4 : Css.Style
neg_inset_3over4 =
    Css.batch
        [ Css.property "top" "-75%"
        , Css.property "right" "-75%"
        , Css.property "bottom" "-75%"
        , Css.property "left" "-75%"
        ]


neg_inset_4 : Css.Style
neg_inset_4 =
    Css.batch
        [ Css.property "top" "-1rem"
        , Css.property "right" "-1rem"
        , Css.property "bottom" "-1rem"
        , Css.property "left" "-1rem"
        ]


neg_inset_40 : Css.Style
neg_inset_40 =
    Css.batch
        [ Css.property "top" "-10rem"
        , Css.property "right" "-10rem"
        , Css.property "bottom" "-10rem"
        , Css.property "left" "-10rem"
        ]


neg_inset_44 : Css.Style
neg_inset_44 =
    Css.batch
        [ Css.property "top" "-11rem"
        , Css.property "right" "-11rem"
        , Css.property "bottom" "-11rem"
        , Css.property "left" "-11rem"
        ]


neg_inset_48 : Css.Style
neg_inset_48 =
    Css.batch
        [ Css.property "top" "-12rem"
        , Css.property "right" "-12rem"
        , Css.property "bottom" "-12rem"
        , Css.property "left" "-12rem"
        ]


neg_inset_5 : Css.Style
neg_inset_5 =
    Css.batch
        [ Css.property "top" "-1.25rem"
        , Css.property "right" "-1.25rem"
        , Css.property "bottom" "-1.25rem"
        , Css.property "left" "-1.25rem"
        ]


neg_inset_52 : Css.Style
neg_inset_52 =
    Css.batch
        [ Css.property "top" "-13rem"
        , Css.property "right" "-13rem"
        , Css.property "bottom" "-13rem"
        , Css.property "left" "-13rem"
        ]


neg_inset_56 : Css.Style
neg_inset_56 =
    Css.batch
        [ Css.property "top" "-14rem"
        , Css.property "right" "-14rem"
        , Css.property "bottom" "-14rem"
        , Css.property "left" "-14rem"
        ]


neg_inset_6 : Css.Style
neg_inset_6 =
    Css.batch
        [ Css.property "top" "-1.5rem"
        , Css.property "right" "-1.5rem"
        , Css.property "bottom" "-1.5rem"
        , Css.property "left" "-1.5rem"
        ]


neg_inset_60 : Css.Style
neg_inset_60 =
    Css.batch
        [ Css.property "top" "-15rem"
        , Css.property "right" "-15rem"
        , Css.property "bottom" "-15rem"
        , Css.property "left" "-15rem"
        ]


neg_inset_64 : Css.Style
neg_inset_64 =
    Css.batch
        [ Css.property "top" "-16rem"
        , Css.property "right" "-16rem"
        , Css.property "bottom" "-16rem"
        , Css.property "left" "-16rem"
        ]


neg_inset_7 : Css.Style
neg_inset_7 =
    Css.batch
        [ Css.property "top" "-1.75rem"
        , Css.property "right" "-1.75rem"
        , Css.property "bottom" "-1.75rem"
        , Css.property "left" "-1.75rem"
        ]


neg_inset_72 : Css.Style
neg_inset_72 =
    Css.batch
        [ Css.property "top" "-18rem"
        , Css.property "right" "-18rem"
        , Css.property "bottom" "-18rem"
        , Css.property "left" "-18rem"
        ]


neg_inset_8 : Css.Style
neg_inset_8 =
    Css.batch
        [ Css.property "top" "-2rem"
        , Css.property "right" "-2rem"
        , Css.property "bottom" "-2rem"
        , Css.property "left" "-2rem"
        ]


neg_inset_80 : Css.Style
neg_inset_80 =
    Css.batch
        [ Css.property "top" "-20rem"
        , Css.property "right" "-20rem"
        , Css.property "bottom" "-20rem"
        , Css.property "left" "-20rem"
        ]


neg_inset_9 : Css.Style
neg_inset_9 =
    Css.batch
        [ Css.property "top" "-2.25rem"
        , Css.property "right" "-2.25rem"
        , Css.property "bottom" "-2.25rem"
        , Css.property "left" "-2.25rem"
        ]


neg_inset_96 : Css.Style
neg_inset_96 =
    Css.batch
        [ Css.property "top" "-24rem"
        , Css.property "right" "-24rem"
        , Css.property "bottom" "-24rem"
        , Css.property "left" "-24rem"
        ]


neg_inset_full : Css.Style
neg_inset_full =
    Css.batch
        [ Css.property "top" "-100%"
        , Css.property "right" "-100%"
        , Css.property "bottom" "-100%"
        , Css.property "left" "-100%"
        ]


neg_inset_px : Css.Style
neg_inset_px =
    Css.batch
        [ Css.property "top" "-1px"
        , Css.property "right" "-1px"
        , Css.property "bottom" "-1px"
        , Css.property "left" "-1px"
        ]


neg_inset_x_0 : Css.Style
neg_inset_x_0 =
    Css.batch
        [ Css.property "left" "0px"
        , Css.property "right" "0px"
        ]


neg_inset_x_0_dot_5 : Css.Style
neg_inset_x_0_dot_5 =
    Css.batch
        [ Css.property "left" "-0.125rem"
        , Css.property "right" "-0.125rem"
        ]


neg_inset_x_1 : Css.Style
neg_inset_x_1 =
    Css.batch
        [ Css.property "left" "-0.25rem"
        , Css.property "right" "-0.25rem"
        ]


neg_inset_x_10 : Css.Style
neg_inset_x_10 =
    Css.batch
        [ Css.property "left" "-2.5rem"
        , Css.property "right" "-2.5rem"
        ]


neg_inset_x_11 : Css.Style
neg_inset_x_11 =
    Css.batch
        [ Css.property "left" "-2.75rem"
        , Css.property "right" "-2.75rem"
        ]


neg_inset_x_12 : Css.Style
neg_inset_x_12 =
    Css.batch
        [ Css.property "left" "-3rem"
        , Css.property "right" "-3rem"
        ]


neg_inset_x_14 : Css.Style
neg_inset_x_14 =
    Css.batch
        [ Css.property "left" "-3.5rem"
        , Css.property "right" "-3.5rem"
        ]


neg_inset_x_16 : Css.Style
neg_inset_x_16 =
    Css.batch
        [ Css.property "left" "-4rem"
        , Css.property "right" "-4rem"
        ]


neg_inset_x_1_dot_5 : Css.Style
neg_inset_x_1_dot_5 =
    Css.batch
        [ Css.property "left" "-0.375rem"
        , Css.property "right" "-0.375rem"
        ]


neg_inset_x_1over2 : Css.Style
neg_inset_x_1over2 =
    Css.batch
        [ Css.property "left" "-50%"
        , Css.property "right" "-50%"
        ]


neg_inset_x_1over3 : Css.Style
neg_inset_x_1over3 =
    Css.batch
        [ Css.property "left" "-33.333333%"
        , Css.property "right" "-33.333333%"
        ]


neg_inset_x_1over4 : Css.Style
neg_inset_x_1over4 =
    Css.batch
        [ Css.property "left" "-25%"
        , Css.property "right" "-25%"
        ]


neg_inset_x_2 : Css.Style
neg_inset_x_2 =
    Css.batch
        [ Css.property "left" "-0.5rem"
        , Css.property "right" "-0.5rem"
        ]


neg_inset_x_20 : Css.Style
neg_inset_x_20 =
    Css.batch
        [ Css.property "left" "-5rem"
        , Css.property "right" "-5rem"
        ]


neg_inset_x_24 : Css.Style
neg_inset_x_24 =
    Css.batch
        [ Css.property "left" "-6rem"
        , Css.property "right" "-6rem"
        ]


neg_inset_x_28 : Css.Style
neg_inset_x_28 =
    Css.batch
        [ Css.property "left" "-7rem"
        , Css.property "right" "-7rem"
        ]


neg_inset_x_2_dot_5 : Css.Style
neg_inset_x_2_dot_5 =
    Css.batch
        [ Css.property "left" "-0.625rem"
        , Css.property "right" "-0.625rem"
        ]


neg_inset_x_2over3 : Css.Style
neg_inset_x_2over3 =
    Css.batch
        [ Css.property "left" "-66.666667%"
        , Css.property "right" "-66.666667%"
        ]


neg_inset_x_2over4 : Css.Style
neg_inset_x_2over4 =
    Css.batch
        [ Css.property "left" "-50%"
        , Css.property "right" "-50%"
        ]


neg_inset_x_3 : Css.Style
neg_inset_x_3 =
    Css.batch
        [ Css.property "left" "-0.75rem"
        , Css.property "right" "-0.75rem"
        ]


neg_inset_x_32 : Css.Style
neg_inset_x_32 =
    Css.batch
        [ Css.property "left" "-8rem"
        , Css.property "right" "-8rem"
        ]


neg_inset_x_36 : Css.Style
neg_inset_x_36 =
    Css.batch
        [ Css.property "left" "-9rem"
        , Css.property "right" "-9rem"
        ]


neg_inset_x_3_dot_5 : Css.Style
neg_inset_x_3_dot_5 =
    Css.batch
        [ Css.property "left" "-0.875rem"
        , Css.property "right" "-0.875rem"
        ]


neg_inset_x_3over4 : Css.Style
neg_inset_x_3over4 =
    Css.batch
        [ Css.property "left" "-75%"
        , Css.property "right" "-75%"
        ]


neg_inset_x_4 : Css.Style
neg_inset_x_4 =
    Css.batch
        [ Css.property "left" "-1rem"
        , Css.property "right" "-1rem"
        ]


neg_inset_x_40 : Css.Style
neg_inset_x_40 =
    Css.batch
        [ Css.property "left" "-10rem"
        , Css.property "right" "-10rem"
        ]


neg_inset_x_44 : Css.Style
neg_inset_x_44 =
    Css.batch
        [ Css.property "left" "-11rem"
        , Css.property "right" "-11rem"
        ]


neg_inset_x_48 : Css.Style
neg_inset_x_48 =
    Css.batch
        [ Css.property "left" "-12rem"
        , Css.property "right" "-12rem"
        ]


neg_inset_x_5 : Css.Style
neg_inset_x_5 =
    Css.batch
        [ Css.property "left" "-1.25rem"
        , Css.property "right" "-1.25rem"
        ]


neg_inset_x_52 : Css.Style
neg_inset_x_52 =
    Css.batch
        [ Css.property "left" "-13rem"
        , Css.property "right" "-13rem"
        ]


neg_inset_x_56 : Css.Style
neg_inset_x_56 =
    Css.batch
        [ Css.property "left" "-14rem"
        , Css.property "right" "-14rem"
        ]


neg_inset_x_6 : Css.Style
neg_inset_x_6 =
    Css.batch
        [ Css.property "left" "-1.5rem"
        , Css.property "right" "-1.5rem"
        ]


neg_inset_x_60 : Css.Style
neg_inset_x_60 =
    Css.batch
        [ Css.property "left" "-15rem"
        , Css.property "right" "-15rem"
        ]


neg_inset_x_64 : Css.Style
neg_inset_x_64 =
    Css.batch
        [ Css.property "left" "-16rem"
        , Css.property "right" "-16rem"
        ]


neg_inset_x_7 : Css.Style
neg_inset_x_7 =
    Css.batch
        [ Css.property "left" "-1.75rem"
        , Css.property "right" "-1.75rem"
        ]


neg_inset_x_72 : Css.Style
neg_inset_x_72 =
    Css.batch
        [ Css.property "left" "-18rem"
        , Css.property "right" "-18rem"
        ]


neg_inset_x_8 : Css.Style
neg_inset_x_8 =
    Css.batch
        [ Css.property "left" "-2rem"
        , Css.property "right" "-2rem"
        ]


neg_inset_x_80 : Css.Style
neg_inset_x_80 =
    Css.batch
        [ Css.property "left" "-20rem"
        , Css.property "right" "-20rem"
        ]


neg_inset_x_9 : Css.Style
neg_inset_x_9 =
    Css.batch
        [ Css.property "left" "-2.25rem"
        , Css.property "right" "-2.25rem"
        ]


neg_inset_x_96 : Css.Style
neg_inset_x_96 =
    Css.batch
        [ Css.property "left" "-24rem"
        , Css.property "right" "-24rem"
        ]


neg_inset_x_full : Css.Style
neg_inset_x_full =
    Css.batch
        [ Css.property "left" "-100%"
        , Css.property "right" "-100%"
        ]


neg_inset_x_px : Css.Style
neg_inset_x_px =
    Css.batch
        [ Css.property "left" "-1px"
        , Css.property "right" "-1px"
        ]


neg_inset_y_0 : Css.Style
neg_inset_y_0 =
    Css.batch
        [ Css.property "top" "0px"
        , Css.property "bottom" "0px"
        ]


neg_inset_y_0_dot_5 : Css.Style
neg_inset_y_0_dot_5 =
    Css.batch
        [ Css.property "top" "-0.125rem"
        , Css.property "bottom" "-0.125rem"
        ]


neg_inset_y_1 : Css.Style
neg_inset_y_1 =
    Css.batch
        [ Css.property "top" "-0.25rem"
        , Css.property "bottom" "-0.25rem"
        ]


neg_inset_y_10 : Css.Style
neg_inset_y_10 =
    Css.batch
        [ Css.property "top" "-2.5rem"
        , Css.property "bottom" "-2.5rem"
        ]


neg_inset_y_11 : Css.Style
neg_inset_y_11 =
    Css.batch
        [ Css.property "top" "-2.75rem"
        , Css.property "bottom" "-2.75rem"
        ]


neg_inset_y_12 : Css.Style
neg_inset_y_12 =
    Css.batch
        [ Css.property "top" "-3rem"
        , Css.property "bottom" "-3rem"
        ]


neg_inset_y_14 : Css.Style
neg_inset_y_14 =
    Css.batch
        [ Css.property "top" "-3.5rem"
        , Css.property "bottom" "-3.5rem"
        ]


neg_inset_y_16 : Css.Style
neg_inset_y_16 =
    Css.batch
        [ Css.property "top" "-4rem"
        , Css.property "bottom" "-4rem"
        ]


neg_inset_y_1_dot_5 : Css.Style
neg_inset_y_1_dot_5 =
    Css.batch
        [ Css.property "top" "-0.375rem"
        , Css.property "bottom" "-0.375rem"
        ]


neg_inset_y_1over2 : Css.Style
neg_inset_y_1over2 =
    Css.batch
        [ Css.property "top" "-50%"
        , Css.property "bottom" "-50%"
        ]


neg_inset_y_1over3 : Css.Style
neg_inset_y_1over3 =
    Css.batch
        [ Css.property "top" "-33.333333%"
        , Css.property "bottom" "-33.333333%"
        ]


neg_inset_y_1over4 : Css.Style
neg_inset_y_1over4 =
    Css.batch
        [ Css.property "top" "-25%"
        , Css.property "bottom" "-25%"
        ]


neg_inset_y_2 : Css.Style
neg_inset_y_2 =
    Css.batch
        [ Css.property "top" "-0.5rem"
        , Css.property "bottom" "-0.5rem"
        ]


neg_inset_y_20 : Css.Style
neg_inset_y_20 =
    Css.batch
        [ Css.property "top" "-5rem"
        , Css.property "bottom" "-5rem"
        ]


neg_inset_y_24 : Css.Style
neg_inset_y_24 =
    Css.batch
        [ Css.property "top" "-6rem"
        , Css.property "bottom" "-6rem"
        ]


neg_inset_y_28 : Css.Style
neg_inset_y_28 =
    Css.batch
        [ Css.property "top" "-7rem"
        , Css.property "bottom" "-7rem"
        ]


neg_inset_y_2_dot_5 : Css.Style
neg_inset_y_2_dot_5 =
    Css.batch
        [ Css.property "top" "-0.625rem"
        , Css.property "bottom" "-0.625rem"
        ]


neg_inset_y_2over3 : Css.Style
neg_inset_y_2over3 =
    Css.batch
        [ Css.property "top" "-66.666667%"
        , Css.property "bottom" "-66.666667%"
        ]


neg_inset_y_2over4 : Css.Style
neg_inset_y_2over4 =
    Css.batch
        [ Css.property "top" "-50%"
        , Css.property "bottom" "-50%"
        ]


neg_inset_y_3 : Css.Style
neg_inset_y_3 =
    Css.batch
        [ Css.property "top" "-0.75rem"
        , Css.property "bottom" "-0.75rem"
        ]


neg_inset_y_32 : Css.Style
neg_inset_y_32 =
    Css.batch
        [ Css.property "top" "-8rem"
        , Css.property "bottom" "-8rem"
        ]


neg_inset_y_36 : Css.Style
neg_inset_y_36 =
    Css.batch
        [ Css.property "top" "-9rem"
        , Css.property "bottom" "-9rem"
        ]


neg_inset_y_3_dot_5 : Css.Style
neg_inset_y_3_dot_5 =
    Css.batch
        [ Css.property "top" "-0.875rem"
        , Css.property "bottom" "-0.875rem"
        ]


neg_inset_y_3over4 : Css.Style
neg_inset_y_3over4 =
    Css.batch
        [ Css.property "top" "-75%"
        , Css.property "bottom" "-75%"
        ]


neg_inset_y_4 : Css.Style
neg_inset_y_4 =
    Css.batch
        [ Css.property "top" "-1rem"
        , Css.property "bottom" "-1rem"
        ]


neg_inset_y_40 : Css.Style
neg_inset_y_40 =
    Css.batch
        [ Css.property "top" "-10rem"
        , Css.property "bottom" "-10rem"
        ]


neg_inset_y_44 : Css.Style
neg_inset_y_44 =
    Css.batch
        [ Css.property "top" "-11rem"
        , Css.property "bottom" "-11rem"
        ]


neg_inset_y_48 : Css.Style
neg_inset_y_48 =
    Css.batch
        [ Css.property "top" "-12rem"
        , Css.property "bottom" "-12rem"
        ]


neg_inset_y_5 : Css.Style
neg_inset_y_5 =
    Css.batch
        [ Css.property "top" "-1.25rem"
        , Css.property "bottom" "-1.25rem"
        ]


neg_inset_y_52 : Css.Style
neg_inset_y_52 =
    Css.batch
        [ Css.property "top" "-13rem"
        , Css.property "bottom" "-13rem"
        ]


neg_inset_y_56 : Css.Style
neg_inset_y_56 =
    Css.batch
        [ Css.property "top" "-14rem"
        , Css.property "bottom" "-14rem"
        ]


neg_inset_y_6 : Css.Style
neg_inset_y_6 =
    Css.batch
        [ Css.property "top" "-1.5rem"
        , Css.property "bottom" "-1.5rem"
        ]


neg_inset_y_60 : Css.Style
neg_inset_y_60 =
    Css.batch
        [ Css.property "top" "-15rem"
        , Css.property "bottom" "-15rem"
        ]


neg_inset_y_64 : Css.Style
neg_inset_y_64 =
    Css.batch
        [ Css.property "top" "-16rem"
        , Css.property "bottom" "-16rem"
        ]


neg_inset_y_7 : Css.Style
neg_inset_y_7 =
    Css.batch
        [ Css.property "top" "-1.75rem"
        , Css.property "bottom" "-1.75rem"
        ]


neg_inset_y_72 : Css.Style
neg_inset_y_72 =
    Css.batch
        [ Css.property "top" "-18rem"
        , Css.property "bottom" "-18rem"
        ]


neg_inset_y_8 : Css.Style
neg_inset_y_8 =
    Css.batch
        [ Css.property "top" "-2rem"
        , Css.property "bottom" "-2rem"
        ]


neg_inset_y_80 : Css.Style
neg_inset_y_80 =
    Css.batch
        [ Css.property "top" "-20rem"
        , Css.property "bottom" "-20rem"
        ]


neg_inset_y_9 : Css.Style
neg_inset_y_9 =
    Css.batch
        [ Css.property "top" "-2.25rem"
        , Css.property "bottom" "-2.25rem"
        ]


neg_inset_y_96 : Css.Style
neg_inset_y_96 =
    Css.batch
        [ Css.property "top" "-24rem"
        , Css.property "bottom" "-24rem"
        ]


neg_inset_y_full : Css.Style
neg_inset_y_full =
    Css.batch
        [ Css.property "top" "-100%"
        , Css.property "bottom" "-100%"
        ]


neg_inset_y_px : Css.Style
neg_inset_y_px =
    Css.batch
        [ Css.property "top" "-1px"
        , Css.property "bottom" "-1px"
        ]


neg_left_0 : Css.Style
neg_left_0 =
    Css.property "left" "0px"


neg_left_0_dot_5 : Css.Style
neg_left_0_dot_5 =
    Css.property "left" "-0.125rem"


neg_left_1 : Css.Style
neg_left_1 =
    Css.property "left" "-0.25rem"


neg_left_10 : Css.Style
neg_left_10 =
    Css.property "left" "-2.5rem"


neg_left_11 : Css.Style
neg_left_11 =
    Css.property "left" "-2.75rem"


neg_left_12 : Css.Style
neg_left_12 =
    Css.property "left" "-3rem"


neg_left_14 : Css.Style
neg_left_14 =
    Css.property "left" "-3.5rem"


neg_left_16 : Css.Style
neg_left_16 =
    Css.property "left" "-4rem"


neg_left_1_dot_5 : Css.Style
neg_left_1_dot_5 =
    Css.property "left" "-0.375rem"


neg_left_1over2 : Css.Style
neg_left_1over2 =
    Css.property "left" "-50%"


neg_left_1over3 : Css.Style
neg_left_1over3 =
    Css.property "left" "-33.333333%"


neg_left_1over4 : Css.Style
neg_left_1over4 =
    Css.property "left" "-25%"


neg_left_2 : Css.Style
neg_left_2 =
    Css.property "left" "-0.5rem"


neg_left_20 : Css.Style
neg_left_20 =
    Css.property "left" "-5rem"


neg_left_24 : Css.Style
neg_left_24 =
    Css.property "left" "-6rem"


neg_left_28 : Css.Style
neg_left_28 =
    Css.property "left" "-7rem"


neg_left_2_dot_5 : Css.Style
neg_left_2_dot_5 =
    Css.property "left" "-0.625rem"


neg_left_2over3 : Css.Style
neg_left_2over3 =
    Css.property "left" "-66.666667%"


neg_left_2over4 : Css.Style
neg_left_2over4 =
    Css.property "left" "-50%"


neg_left_3 : Css.Style
neg_left_3 =
    Css.property "left" "-0.75rem"


neg_left_32 : Css.Style
neg_left_32 =
    Css.property "left" "-8rem"


neg_left_36 : Css.Style
neg_left_36 =
    Css.property "left" "-9rem"


neg_left_3_dot_5 : Css.Style
neg_left_3_dot_5 =
    Css.property "left" "-0.875rem"


neg_left_3over4 : Css.Style
neg_left_3over4 =
    Css.property "left" "-75%"


neg_left_4 : Css.Style
neg_left_4 =
    Css.property "left" "-1rem"


neg_left_40 : Css.Style
neg_left_40 =
    Css.property "left" "-10rem"


neg_left_44 : Css.Style
neg_left_44 =
    Css.property "left" "-11rem"


neg_left_48 : Css.Style
neg_left_48 =
    Css.property "left" "-12rem"


neg_left_5 : Css.Style
neg_left_5 =
    Css.property "left" "-1.25rem"


neg_left_52 : Css.Style
neg_left_52 =
    Css.property "left" "-13rem"


neg_left_56 : Css.Style
neg_left_56 =
    Css.property "left" "-14rem"


neg_left_6 : Css.Style
neg_left_6 =
    Css.property "left" "-1.5rem"


neg_left_60 : Css.Style
neg_left_60 =
    Css.property "left" "-15rem"


neg_left_64 : Css.Style
neg_left_64 =
    Css.property "left" "-16rem"


neg_left_7 : Css.Style
neg_left_7 =
    Css.property "left" "-1.75rem"


neg_left_72 : Css.Style
neg_left_72 =
    Css.property "left" "-18rem"


neg_left_8 : Css.Style
neg_left_8 =
    Css.property "left" "-2rem"


neg_left_80 : Css.Style
neg_left_80 =
    Css.property "left" "-20rem"


neg_left_9 : Css.Style
neg_left_9 =
    Css.property "left" "-2.25rem"


neg_left_96 : Css.Style
neg_left_96 =
    Css.property "left" "-24rem"


neg_left_full : Css.Style
neg_left_full =
    Css.property "left" "-100%"


neg_left_px : Css.Style
neg_left_px =
    Css.property "left" "-1px"


neg_m_0 : Css.Style
neg_m_0 =
    Css.property "margin" "0px"


neg_m_0_dot_5 : Css.Style
neg_m_0_dot_5 =
    Css.property "margin" "-0.125rem"


neg_m_1 : Css.Style
neg_m_1 =
    Css.property "margin" "-0.25rem"


neg_m_10 : Css.Style
neg_m_10 =
    Css.property "margin" "-2.5rem"


neg_m_11 : Css.Style
neg_m_11 =
    Css.property "margin" "-2.75rem"


neg_m_12 : Css.Style
neg_m_12 =
    Css.property "margin" "-3rem"


neg_m_14 : Css.Style
neg_m_14 =
    Css.property "margin" "-3.5rem"


neg_m_16 : Css.Style
neg_m_16 =
    Css.property "margin" "-4rem"


neg_m_1_dot_5 : Css.Style
neg_m_1_dot_5 =
    Css.property "margin" "-0.375rem"


neg_m_2 : Css.Style
neg_m_2 =
    Css.property "margin" "-0.5rem"


neg_m_20 : Css.Style
neg_m_20 =
    Css.property "margin" "-5rem"


neg_m_24 : Css.Style
neg_m_24 =
    Css.property "margin" "-6rem"


neg_m_28 : Css.Style
neg_m_28 =
    Css.property "margin" "-7rem"


neg_m_2_dot_5 : Css.Style
neg_m_2_dot_5 =
    Css.property "margin" "-0.625rem"


neg_m_3 : Css.Style
neg_m_3 =
    Css.property "margin" "-0.75rem"


neg_m_32 : Css.Style
neg_m_32 =
    Css.property "margin" "-8rem"


neg_m_36 : Css.Style
neg_m_36 =
    Css.property "margin" "-9rem"


neg_m_3_dot_5 : Css.Style
neg_m_3_dot_5 =
    Css.property "margin" "-0.875rem"


neg_m_4 : Css.Style
neg_m_4 =
    Css.property "margin" "-1rem"


neg_m_40 : Css.Style
neg_m_40 =
    Css.property "margin" "-10rem"


neg_m_44 : Css.Style
neg_m_44 =
    Css.property "margin" "-11rem"


neg_m_48 : Css.Style
neg_m_48 =
    Css.property "margin" "-12rem"


neg_m_5 : Css.Style
neg_m_5 =
    Css.property "margin" "-1.25rem"


neg_m_52 : Css.Style
neg_m_52 =
    Css.property "margin" "-13rem"


neg_m_56 : Css.Style
neg_m_56 =
    Css.property "margin" "-14rem"


neg_m_6 : Css.Style
neg_m_6 =
    Css.property "margin" "-1.5rem"


neg_m_60 : Css.Style
neg_m_60 =
    Css.property "margin" "-15rem"


neg_m_64 : Css.Style
neg_m_64 =
    Css.property "margin" "-16rem"


neg_m_7 : Css.Style
neg_m_7 =
    Css.property "margin" "-1.75rem"


neg_m_72 : Css.Style
neg_m_72 =
    Css.property "margin" "-18rem"


neg_m_8 : Css.Style
neg_m_8 =
    Css.property "margin" "-2rem"


neg_m_80 : Css.Style
neg_m_80 =
    Css.property "margin" "-20rem"


neg_m_9 : Css.Style
neg_m_9 =
    Css.property "margin" "-2.25rem"


neg_m_96 : Css.Style
neg_m_96 =
    Css.property "margin" "-24rem"


neg_m_px : Css.Style
neg_m_px =
    Css.property "margin" "-1px"


neg_mb_0 : Css.Style
neg_mb_0 =
    Css.property "margin-bottom" "0px"


neg_mb_0_dot_5 : Css.Style
neg_mb_0_dot_5 =
    Css.property "margin-bottom" "-0.125rem"


neg_mb_1 : Css.Style
neg_mb_1 =
    Css.property "margin-bottom" "-0.25rem"


neg_mb_10 : Css.Style
neg_mb_10 =
    Css.property "margin-bottom" "-2.5rem"


neg_mb_11 : Css.Style
neg_mb_11 =
    Css.property "margin-bottom" "-2.75rem"


neg_mb_12 : Css.Style
neg_mb_12 =
    Css.property "margin-bottom" "-3rem"


neg_mb_14 : Css.Style
neg_mb_14 =
    Css.property "margin-bottom" "-3.5rem"


neg_mb_16 : Css.Style
neg_mb_16 =
    Css.property "margin-bottom" "-4rem"


neg_mb_1_dot_5 : Css.Style
neg_mb_1_dot_5 =
    Css.property "margin-bottom" "-0.375rem"


neg_mb_2 : Css.Style
neg_mb_2 =
    Css.property "margin-bottom" "-0.5rem"


neg_mb_20 : Css.Style
neg_mb_20 =
    Css.property "margin-bottom" "-5rem"


neg_mb_24 : Css.Style
neg_mb_24 =
    Css.property "margin-bottom" "-6rem"


neg_mb_28 : Css.Style
neg_mb_28 =
    Css.property "margin-bottom" "-7rem"


neg_mb_2_dot_5 : Css.Style
neg_mb_2_dot_5 =
    Css.property "margin-bottom" "-0.625rem"


neg_mb_3 : Css.Style
neg_mb_3 =
    Css.property "margin-bottom" "-0.75rem"


neg_mb_32 : Css.Style
neg_mb_32 =
    Css.property "margin-bottom" "-8rem"


neg_mb_36 : Css.Style
neg_mb_36 =
    Css.property "margin-bottom" "-9rem"


neg_mb_3_dot_5 : Css.Style
neg_mb_3_dot_5 =
    Css.property "margin-bottom" "-0.875rem"


neg_mb_4 : Css.Style
neg_mb_4 =
    Css.property "margin-bottom" "-1rem"


neg_mb_40 : Css.Style
neg_mb_40 =
    Css.property "margin-bottom" "-10rem"


neg_mb_44 : Css.Style
neg_mb_44 =
    Css.property "margin-bottom" "-11rem"


neg_mb_48 : Css.Style
neg_mb_48 =
    Css.property "margin-bottom" "-12rem"


neg_mb_5 : Css.Style
neg_mb_5 =
    Css.property "margin-bottom" "-1.25rem"


neg_mb_52 : Css.Style
neg_mb_52 =
    Css.property "margin-bottom" "-13rem"


neg_mb_56 : Css.Style
neg_mb_56 =
    Css.property "margin-bottom" "-14rem"


neg_mb_6 : Css.Style
neg_mb_6 =
    Css.property "margin-bottom" "-1.5rem"


neg_mb_60 : Css.Style
neg_mb_60 =
    Css.property "margin-bottom" "-15rem"


neg_mb_64 : Css.Style
neg_mb_64 =
    Css.property "margin-bottom" "-16rem"


neg_mb_7 : Css.Style
neg_mb_7 =
    Css.property "margin-bottom" "-1.75rem"


neg_mb_72 : Css.Style
neg_mb_72 =
    Css.property "margin-bottom" "-18rem"


neg_mb_8 : Css.Style
neg_mb_8 =
    Css.property "margin-bottom" "-2rem"


neg_mb_80 : Css.Style
neg_mb_80 =
    Css.property "margin-bottom" "-20rem"


neg_mb_9 : Css.Style
neg_mb_9 =
    Css.property "margin-bottom" "-2.25rem"


neg_mb_96 : Css.Style
neg_mb_96 =
    Css.property "margin-bottom" "-24rem"


neg_mb_px : Css.Style
neg_mb_px =
    Css.property "margin-bottom" "-1px"


neg_ml_0 : Css.Style
neg_ml_0 =
    Css.property "margin-left" "0px"


neg_ml_0_dot_5 : Css.Style
neg_ml_0_dot_5 =
    Css.property "margin-left" "-0.125rem"


neg_ml_1 : Css.Style
neg_ml_1 =
    Css.property "margin-left" "-0.25rem"


neg_ml_10 : Css.Style
neg_ml_10 =
    Css.property "margin-left" "-2.5rem"


neg_ml_11 : Css.Style
neg_ml_11 =
    Css.property "margin-left" "-2.75rem"


neg_ml_12 : Css.Style
neg_ml_12 =
    Css.property "margin-left" "-3rem"


neg_ml_14 : Css.Style
neg_ml_14 =
    Css.property "margin-left" "-3.5rem"


neg_ml_16 : Css.Style
neg_ml_16 =
    Css.property "margin-left" "-4rem"


neg_ml_1_dot_5 : Css.Style
neg_ml_1_dot_5 =
    Css.property "margin-left" "-0.375rem"


neg_ml_2 : Css.Style
neg_ml_2 =
    Css.property "margin-left" "-0.5rem"


neg_ml_20 : Css.Style
neg_ml_20 =
    Css.property "margin-left" "-5rem"


neg_ml_24 : Css.Style
neg_ml_24 =
    Css.property "margin-left" "-6rem"


neg_ml_28 : Css.Style
neg_ml_28 =
    Css.property "margin-left" "-7rem"


neg_ml_2_dot_5 : Css.Style
neg_ml_2_dot_5 =
    Css.property "margin-left" "-0.625rem"


neg_ml_3 : Css.Style
neg_ml_3 =
    Css.property "margin-left" "-0.75rem"


neg_ml_32 : Css.Style
neg_ml_32 =
    Css.property "margin-left" "-8rem"


neg_ml_36 : Css.Style
neg_ml_36 =
    Css.property "margin-left" "-9rem"


neg_ml_3_dot_5 : Css.Style
neg_ml_3_dot_5 =
    Css.property "margin-left" "-0.875rem"


neg_ml_4 : Css.Style
neg_ml_4 =
    Css.property "margin-left" "-1rem"


neg_ml_40 : Css.Style
neg_ml_40 =
    Css.property "margin-left" "-10rem"


neg_ml_44 : Css.Style
neg_ml_44 =
    Css.property "margin-left" "-11rem"


neg_ml_48 : Css.Style
neg_ml_48 =
    Css.property "margin-left" "-12rem"


neg_ml_5 : Css.Style
neg_ml_5 =
    Css.property "margin-left" "-1.25rem"


neg_ml_52 : Css.Style
neg_ml_52 =
    Css.property "margin-left" "-13rem"


neg_ml_56 : Css.Style
neg_ml_56 =
    Css.property "margin-left" "-14rem"


neg_ml_6 : Css.Style
neg_ml_6 =
    Css.property "margin-left" "-1.5rem"


neg_ml_60 : Css.Style
neg_ml_60 =
    Css.property "margin-left" "-15rem"


neg_ml_64 : Css.Style
neg_ml_64 =
    Css.property "margin-left" "-16rem"


neg_ml_7 : Css.Style
neg_ml_7 =
    Css.property "margin-left" "-1.75rem"


neg_ml_72 : Css.Style
neg_ml_72 =
    Css.property "margin-left" "-18rem"


neg_ml_8 : Css.Style
neg_ml_8 =
    Css.property "margin-left" "-2rem"


neg_ml_80 : Css.Style
neg_ml_80 =
    Css.property "margin-left" "-20rem"


neg_ml_9 : Css.Style
neg_ml_9 =
    Css.property "margin-left" "-2.25rem"


neg_ml_96 : Css.Style
neg_ml_96 =
    Css.property "margin-left" "-24rem"


neg_ml_px : Css.Style
neg_ml_px =
    Css.property "margin-left" "-1px"


neg_mr_0 : Css.Style
neg_mr_0 =
    Css.property "margin-right" "0px"


neg_mr_0_dot_5 : Css.Style
neg_mr_0_dot_5 =
    Css.property "margin-right" "-0.125rem"


neg_mr_1 : Css.Style
neg_mr_1 =
    Css.property "margin-right" "-0.25rem"


neg_mr_10 : Css.Style
neg_mr_10 =
    Css.property "margin-right" "-2.5rem"


neg_mr_11 : Css.Style
neg_mr_11 =
    Css.property "margin-right" "-2.75rem"


neg_mr_12 : Css.Style
neg_mr_12 =
    Css.property "margin-right" "-3rem"


neg_mr_14 : Css.Style
neg_mr_14 =
    Css.property "margin-right" "-3.5rem"


neg_mr_16 : Css.Style
neg_mr_16 =
    Css.property "margin-right" "-4rem"


neg_mr_1_dot_5 : Css.Style
neg_mr_1_dot_5 =
    Css.property "margin-right" "-0.375rem"


neg_mr_2 : Css.Style
neg_mr_2 =
    Css.property "margin-right" "-0.5rem"


neg_mr_20 : Css.Style
neg_mr_20 =
    Css.property "margin-right" "-5rem"


neg_mr_24 : Css.Style
neg_mr_24 =
    Css.property "margin-right" "-6rem"


neg_mr_28 : Css.Style
neg_mr_28 =
    Css.property "margin-right" "-7rem"


neg_mr_2_dot_5 : Css.Style
neg_mr_2_dot_5 =
    Css.property "margin-right" "-0.625rem"


neg_mr_3 : Css.Style
neg_mr_3 =
    Css.property "margin-right" "-0.75rem"


neg_mr_32 : Css.Style
neg_mr_32 =
    Css.property "margin-right" "-8rem"


neg_mr_36 : Css.Style
neg_mr_36 =
    Css.property "margin-right" "-9rem"


neg_mr_3_dot_5 : Css.Style
neg_mr_3_dot_5 =
    Css.property "margin-right" "-0.875rem"


neg_mr_4 : Css.Style
neg_mr_4 =
    Css.property "margin-right" "-1rem"


neg_mr_40 : Css.Style
neg_mr_40 =
    Css.property "margin-right" "-10rem"


neg_mr_44 : Css.Style
neg_mr_44 =
    Css.property "margin-right" "-11rem"


neg_mr_48 : Css.Style
neg_mr_48 =
    Css.property "margin-right" "-12rem"


neg_mr_5 : Css.Style
neg_mr_5 =
    Css.property "margin-right" "-1.25rem"


neg_mr_52 : Css.Style
neg_mr_52 =
    Css.property "margin-right" "-13rem"


neg_mr_56 : Css.Style
neg_mr_56 =
    Css.property "margin-right" "-14rem"


neg_mr_6 : Css.Style
neg_mr_6 =
    Css.property "margin-right" "-1.5rem"


neg_mr_60 : Css.Style
neg_mr_60 =
    Css.property "margin-right" "-15rem"


neg_mr_64 : Css.Style
neg_mr_64 =
    Css.property "margin-right" "-16rem"


neg_mr_7 : Css.Style
neg_mr_7 =
    Css.property "margin-right" "-1.75rem"


neg_mr_72 : Css.Style
neg_mr_72 =
    Css.property "margin-right" "-18rem"


neg_mr_8 : Css.Style
neg_mr_8 =
    Css.property "margin-right" "-2rem"


neg_mr_80 : Css.Style
neg_mr_80 =
    Css.property "margin-right" "-20rem"


neg_mr_9 : Css.Style
neg_mr_9 =
    Css.property "margin-right" "-2.25rem"


neg_mr_96 : Css.Style
neg_mr_96 =
    Css.property "margin-right" "-24rem"


neg_mr_px : Css.Style
neg_mr_px =
    Css.property "margin-right" "-1px"


neg_mt_0 : Css.Style
neg_mt_0 =
    Css.property "margin-top" "0px"


neg_mt_0_dot_5 : Css.Style
neg_mt_0_dot_5 =
    Css.property "margin-top" "-0.125rem"


neg_mt_1 : Css.Style
neg_mt_1 =
    Css.property "margin-top" "-0.25rem"


neg_mt_10 : Css.Style
neg_mt_10 =
    Css.property "margin-top" "-2.5rem"


neg_mt_11 : Css.Style
neg_mt_11 =
    Css.property "margin-top" "-2.75rem"


neg_mt_12 : Css.Style
neg_mt_12 =
    Css.property "margin-top" "-3rem"


neg_mt_14 : Css.Style
neg_mt_14 =
    Css.property "margin-top" "-3.5rem"


neg_mt_16 : Css.Style
neg_mt_16 =
    Css.property "margin-top" "-4rem"


neg_mt_1_dot_5 : Css.Style
neg_mt_1_dot_5 =
    Css.property "margin-top" "-0.375rem"


neg_mt_2 : Css.Style
neg_mt_2 =
    Css.property "margin-top" "-0.5rem"


neg_mt_20 : Css.Style
neg_mt_20 =
    Css.property "margin-top" "-5rem"


neg_mt_24 : Css.Style
neg_mt_24 =
    Css.property "margin-top" "-6rem"


neg_mt_28 : Css.Style
neg_mt_28 =
    Css.property "margin-top" "-7rem"


neg_mt_2_dot_5 : Css.Style
neg_mt_2_dot_5 =
    Css.property "margin-top" "-0.625rem"


neg_mt_3 : Css.Style
neg_mt_3 =
    Css.property "margin-top" "-0.75rem"


neg_mt_32 : Css.Style
neg_mt_32 =
    Css.property "margin-top" "-8rem"


neg_mt_36 : Css.Style
neg_mt_36 =
    Css.property "margin-top" "-9rem"


neg_mt_3_dot_5 : Css.Style
neg_mt_3_dot_5 =
    Css.property "margin-top" "-0.875rem"


neg_mt_4 : Css.Style
neg_mt_4 =
    Css.property "margin-top" "-1rem"


neg_mt_40 : Css.Style
neg_mt_40 =
    Css.property "margin-top" "-10rem"


neg_mt_44 : Css.Style
neg_mt_44 =
    Css.property "margin-top" "-11rem"


neg_mt_48 : Css.Style
neg_mt_48 =
    Css.property "margin-top" "-12rem"


neg_mt_5 : Css.Style
neg_mt_5 =
    Css.property "margin-top" "-1.25rem"


neg_mt_52 : Css.Style
neg_mt_52 =
    Css.property "margin-top" "-13rem"


neg_mt_56 : Css.Style
neg_mt_56 =
    Css.property "margin-top" "-14rem"


neg_mt_6 : Css.Style
neg_mt_6 =
    Css.property "margin-top" "-1.5rem"


neg_mt_60 : Css.Style
neg_mt_60 =
    Css.property "margin-top" "-15rem"


neg_mt_64 : Css.Style
neg_mt_64 =
    Css.property "margin-top" "-16rem"


neg_mt_7 : Css.Style
neg_mt_7 =
    Css.property "margin-top" "-1.75rem"


neg_mt_72 : Css.Style
neg_mt_72 =
    Css.property "margin-top" "-18rem"


neg_mt_8 : Css.Style
neg_mt_8 =
    Css.property "margin-top" "-2rem"


neg_mt_80 : Css.Style
neg_mt_80 =
    Css.property "margin-top" "-20rem"


neg_mt_9 : Css.Style
neg_mt_9 =
    Css.property "margin-top" "-2.25rem"


neg_mt_96 : Css.Style
neg_mt_96 =
    Css.property "margin-top" "-24rem"


neg_mt_px : Css.Style
neg_mt_px =
    Css.property "margin-top" "-1px"


neg_mx_0 : Css.Style
neg_mx_0 =
    Css.batch
        [ Css.property "margin-left" "0px"
        , Css.property "margin-right" "0px"
        ]


neg_mx_0_dot_5 : Css.Style
neg_mx_0_dot_5 =
    Css.batch
        [ Css.property "margin-left" "-0.125rem"
        , Css.property "margin-right" "-0.125rem"
        ]


neg_mx_1 : Css.Style
neg_mx_1 =
    Css.batch
        [ Css.property "margin-left" "-0.25rem"
        , Css.property "margin-right" "-0.25rem"
        ]


neg_mx_10 : Css.Style
neg_mx_10 =
    Css.batch
        [ Css.property "margin-left" "-2.5rem"
        , Css.property "margin-right" "-2.5rem"
        ]


neg_mx_11 : Css.Style
neg_mx_11 =
    Css.batch
        [ Css.property "margin-left" "-2.75rem"
        , Css.property "margin-right" "-2.75rem"
        ]


neg_mx_12 : Css.Style
neg_mx_12 =
    Css.batch
        [ Css.property "margin-left" "-3rem"
        , Css.property "margin-right" "-3rem"
        ]


neg_mx_14 : Css.Style
neg_mx_14 =
    Css.batch
        [ Css.property "margin-left" "-3.5rem"
        , Css.property "margin-right" "-3.5rem"
        ]


neg_mx_16 : Css.Style
neg_mx_16 =
    Css.batch
        [ Css.property "margin-left" "-4rem"
        , Css.property "margin-right" "-4rem"
        ]


neg_mx_1_dot_5 : Css.Style
neg_mx_1_dot_5 =
    Css.batch
        [ Css.property "margin-left" "-0.375rem"
        , Css.property "margin-right" "-0.375rem"
        ]


neg_mx_2 : Css.Style
neg_mx_2 =
    Css.batch
        [ Css.property "margin-left" "-0.5rem"
        , Css.property "margin-right" "-0.5rem"
        ]


neg_mx_20 : Css.Style
neg_mx_20 =
    Css.batch
        [ Css.property "margin-left" "-5rem"
        , Css.property "margin-right" "-5rem"
        ]


neg_mx_24 : Css.Style
neg_mx_24 =
    Css.batch
        [ Css.property "margin-left" "-6rem"
        , Css.property "margin-right" "-6rem"
        ]


neg_mx_28 : Css.Style
neg_mx_28 =
    Css.batch
        [ Css.property "margin-left" "-7rem"
        , Css.property "margin-right" "-7rem"
        ]


neg_mx_2_dot_5 : Css.Style
neg_mx_2_dot_5 =
    Css.batch
        [ Css.property "margin-left" "-0.625rem"
        , Css.property "margin-right" "-0.625rem"
        ]


neg_mx_3 : Css.Style
neg_mx_3 =
    Css.batch
        [ Css.property "margin-left" "-0.75rem"
        , Css.property "margin-right" "-0.75rem"
        ]


neg_mx_32 : Css.Style
neg_mx_32 =
    Css.batch
        [ Css.property "margin-left" "-8rem"
        , Css.property "margin-right" "-8rem"
        ]


neg_mx_36 : Css.Style
neg_mx_36 =
    Css.batch
        [ Css.property "margin-left" "-9rem"
        , Css.property "margin-right" "-9rem"
        ]


neg_mx_3_dot_5 : Css.Style
neg_mx_3_dot_5 =
    Css.batch
        [ Css.property "margin-left" "-0.875rem"
        , Css.property "margin-right" "-0.875rem"
        ]


neg_mx_4 : Css.Style
neg_mx_4 =
    Css.batch
        [ Css.property "margin-left" "-1rem"
        , Css.property "margin-right" "-1rem"
        ]


neg_mx_40 : Css.Style
neg_mx_40 =
    Css.batch
        [ Css.property "margin-left" "-10rem"
        , Css.property "margin-right" "-10rem"
        ]


neg_mx_44 : Css.Style
neg_mx_44 =
    Css.batch
        [ Css.property "margin-left" "-11rem"
        , Css.property "margin-right" "-11rem"
        ]


neg_mx_48 : Css.Style
neg_mx_48 =
    Css.batch
        [ Css.property "margin-left" "-12rem"
        , Css.property "margin-right" "-12rem"
        ]


neg_mx_5 : Css.Style
neg_mx_5 =
    Css.batch
        [ Css.property "margin-left" "-1.25rem"
        , Css.property "margin-right" "-1.25rem"
        ]


neg_mx_52 : Css.Style
neg_mx_52 =
    Css.batch
        [ Css.property "margin-left" "-13rem"
        , Css.property "margin-right" "-13rem"
        ]


neg_mx_56 : Css.Style
neg_mx_56 =
    Css.batch
        [ Css.property "margin-left" "-14rem"
        , Css.property "margin-right" "-14rem"
        ]


neg_mx_6 : Css.Style
neg_mx_6 =
    Css.batch
        [ Css.property "margin-left" "-1.5rem"
        , Css.property "margin-right" "-1.5rem"
        ]


neg_mx_60 : Css.Style
neg_mx_60 =
    Css.batch
        [ Css.property "margin-left" "-15rem"
        , Css.property "margin-right" "-15rem"
        ]


neg_mx_64 : Css.Style
neg_mx_64 =
    Css.batch
        [ Css.property "margin-left" "-16rem"
        , Css.property "margin-right" "-16rem"
        ]


neg_mx_7 : Css.Style
neg_mx_7 =
    Css.batch
        [ Css.property "margin-left" "-1.75rem"
        , Css.property "margin-right" "-1.75rem"
        ]


neg_mx_72 : Css.Style
neg_mx_72 =
    Css.batch
        [ Css.property "margin-left" "-18rem"
        , Css.property "margin-right" "-18rem"
        ]


neg_mx_8 : Css.Style
neg_mx_8 =
    Css.batch
        [ Css.property "margin-left" "-2rem"
        , Css.property "margin-right" "-2rem"
        ]


neg_mx_80 : Css.Style
neg_mx_80 =
    Css.batch
        [ Css.property "margin-left" "-20rem"
        , Css.property "margin-right" "-20rem"
        ]


neg_mx_9 : Css.Style
neg_mx_9 =
    Css.batch
        [ Css.property "margin-left" "-2.25rem"
        , Css.property "margin-right" "-2.25rem"
        ]


neg_mx_96 : Css.Style
neg_mx_96 =
    Css.batch
        [ Css.property "margin-left" "-24rem"
        , Css.property "margin-right" "-24rem"
        ]


neg_mx_px : Css.Style
neg_mx_px =
    Css.batch
        [ Css.property "margin-left" "-1px"
        , Css.property "margin-right" "-1px"
        ]


neg_my_0 : Css.Style
neg_my_0 =
    Css.batch
        [ Css.property "margin-top" "0px"
        , Css.property "margin-bottom" "0px"
        ]


neg_my_0_dot_5 : Css.Style
neg_my_0_dot_5 =
    Css.batch
        [ Css.property "margin-top" "-0.125rem"
        , Css.property "margin-bottom" "-0.125rem"
        ]


neg_my_1 : Css.Style
neg_my_1 =
    Css.batch
        [ Css.property "margin-top" "-0.25rem"
        , Css.property "margin-bottom" "-0.25rem"
        ]


neg_my_10 : Css.Style
neg_my_10 =
    Css.batch
        [ Css.property "margin-top" "-2.5rem"
        , Css.property "margin-bottom" "-2.5rem"
        ]


neg_my_11 : Css.Style
neg_my_11 =
    Css.batch
        [ Css.property "margin-top" "-2.75rem"
        , Css.property "margin-bottom" "-2.75rem"
        ]


neg_my_12 : Css.Style
neg_my_12 =
    Css.batch
        [ Css.property "margin-top" "-3rem"
        , Css.property "margin-bottom" "-3rem"
        ]


neg_my_14 : Css.Style
neg_my_14 =
    Css.batch
        [ Css.property "margin-top" "-3.5rem"
        , Css.property "margin-bottom" "-3.5rem"
        ]


neg_my_16 : Css.Style
neg_my_16 =
    Css.batch
        [ Css.property "margin-top" "-4rem"
        , Css.property "margin-bottom" "-4rem"
        ]


neg_my_1_dot_5 : Css.Style
neg_my_1_dot_5 =
    Css.batch
        [ Css.property "margin-top" "-0.375rem"
        , Css.property "margin-bottom" "-0.375rem"
        ]


neg_my_2 : Css.Style
neg_my_2 =
    Css.batch
        [ Css.property "margin-top" "-0.5rem"
        , Css.property "margin-bottom" "-0.5rem"
        ]


neg_my_20 : Css.Style
neg_my_20 =
    Css.batch
        [ Css.property "margin-top" "-5rem"
        , Css.property "margin-bottom" "-5rem"
        ]


neg_my_24 : Css.Style
neg_my_24 =
    Css.batch
        [ Css.property "margin-top" "-6rem"
        , Css.property "margin-bottom" "-6rem"
        ]


neg_my_28 : Css.Style
neg_my_28 =
    Css.batch
        [ Css.property "margin-top" "-7rem"
        , Css.property "margin-bottom" "-7rem"
        ]


neg_my_2_dot_5 : Css.Style
neg_my_2_dot_5 =
    Css.batch
        [ Css.property "margin-top" "-0.625rem"
        , Css.property "margin-bottom" "-0.625rem"
        ]


neg_my_3 : Css.Style
neg_my_3 =
    Css.batch
        [ Css.property "margin-top" "-0.75rem"
        , Css.property "margin-bottom" "-0.75rem"
        ]


neg_my_32 : Css.Style
neg_my_32 =
    Css.batch
        [ Css.property "margin-top" "-8rem"
        , Css.property "margin-bottom" "-8rem"
        ]


neg_my_36 : Css.Style
neg_my_36 =
    Css.batch
        [ Css.property "margin-top" "-9rem"
        , Css.property "margin-bottom" "-9rem"
        ]


neg_my_3_dot_5 : Css.Style
neg_my_3_dot_5 =
    Css.batch
        [ Css.property "margin-top" "-0.875rem"
        , Css.property "margin-bottom" "-0.875rem"
        ]


neg_my_4 : Css.Style
neg_my_4 =
    Css.batch
        [ Css.property "margin-top" "-1rem"
        , Css.property "margin-bottom" "-1rem"
        ]


neg_my_40 : Css.Style
neg_my_40 =
    Css.batch
        [ Css.property "margin-top" "-10rem"
        , Css.property "margin-bottom" "-10rem"
        ]


neg_my_44 : Css.Style
neg_my_44 =
    Css.batch
        [ Css.property "margin-top" "-11rem"
        , Css.property "margin-bottom" "-11rem"
        ]


neg_my_48 : Css.Style
neg_my_48 =
    Css.batch
        [ Css.property "margin-top" "-12rem"
        , Css.property "margin-bottom" "-12rem"
        ]


neg_my_5 : Css.Style
neg_my_5 =
    Css.batch
        [ Css.property "margin-top" "-1.25rem"
        , Css.property "margin-bottom" "-1.25rem"
        ]


neg_my_52 : Css.Style
neg_my_52 =
    Css.batch
        [ Css.property "margin-top" "-13rem"
        , Css.property "margin-bottom" "-13rem"
        ]


neg_my_56 : Css.Style
neg_my_56 =
    Css.batch
        [ Css.property "margin-top" "-14rem"
        , Css.property "margin-bottom" "-14rem"
        ]


neg_my_6 : Css.Style
neg_my_6 =
    Css.batch
        [ Css.property "margin-top" "-1.5rem"
        , Css.property "margin-bottom" "-1.5rem"
        ]


neg_my_60 : Css.Style
neg_my_60 =
    Css.batch
        [ Css.property "margin-top" "-15rem"
        , Css.property "margin-bottom" "-15rem"
        ]


neg_my_64 : Css.Style
neg_my_64 =
    Css.batch
        [ Css.property "margin-top" "-16rem"
        , Css.property "margin-bottom" "-16rem"
        ]


neg_my_7 : Css.Style
neg_my_7 =
    Css.batch
        [ Css.property "margin-top" "-1.75rem"
        , Css.property "margin-bottom" "-1.75rem"
        ]


neg_my_72 : Css.Style
neg_my_72 =
    Css.batch
        [ Css.property "margin-top" "-18rem"
        , Css.property "margin-bottom" "-18rem"
        ]


neg_my_8 : Css.Style
neg_my_8 =
    Css.batch
        [ Css.property "margin-top" "-2rem"
        , Css.property "margin-bottom" "-2rem"
        ]


neg_my_80 : Css.Style
neg_my_80 =
    Css.batch
        [ Css.property "margin-top" "-20rem"
        , Css.property "margin-bottom" "-20rem"
        ]


neg_my_9 : Css.Style
neg_my_9 =
    Css.batch
        [ Css.property "margin-top" "-2.25rem"
        , Css.property "margin-bottom" "-2.25rem"
        ]


neg_my_96 : Css.Style
neg_my_96 =
    Css.batch
        [ Css.property "margin-top" "-24rem"
        , Css.property "margin-bottom" "-24rem"
        ]


neg_my_px : Css.Style
neg_my_px =
    Css.batch
        [ Css.property "margin-top" "-1px"
        , Css.property "margin-bottom" "-1px"
        ]


neg_right_0 : Css.Style
neg_right_0 =
    Css.property "right" "0px"


neg_right_0_dot_5 : Css.Style
neg_right_0_dot_5 =
    Css.property "right" "-0.125rem"


neg_right_1 : Css.Style
neg_right_1 =
    Css.property "right" "-0.25rem"


neg_right_10 : Css.Style
neg_right_10 =
    Css.property "right" "-2.5rem"


neg_right_11 : Css.Style
neg_right_11 =
    Css.property "right" "-2.75rem"


neg_right_12 : Css.Style
neg_right_12 =
    Css.property "right" "-3rem"


neg_right_14 : Css.Style
neg_right_14 =
    Css.property "right" "-3.5rem"


neg_right_16 : Css.Style
neg_right_16 =
    Css.property "right" "-4rem"


neg_right_1_dot_5 : Css.Style
neg_right_1_dot_5 =
    Css.property "right" "-0.375rem"


neg_right_1over2 : Css.Style
neg_right_1over2 =
    Css.property "right" "-50%"


neg_right_1over3 : Css.Style
neg_right_1over3 =
    Css.property "right" "-33.333333%"


neg_right_1over4 : Css.Style
neg_right_1over4 =
    Css.property "right" "-25%"


neg_right_2 : Css.Style
neg_right_2 =
    Css.property "right" "-0.5rem"


neg_right_20 : Css.Style
neg_right_20 =
    Css.property "right" "-5rem"


neg_right_24 : Css.Style
neg_right_24 =
    Css.property "right" "-6rem"


neg_right_28 : Css.Style
neg_right_28 =
    Css.property "right" "-7rem"


neg_right_2_dot_5 : Css.Style
neg_right_2_dot_5 =
    Css.property "right" "-0.625rem"


neg_right_2over3 : Css.Style
neg_right_2over3 =
    Css.property "right" "-66.666667%"


neg_right_2over4 : Css.Style
neg_right_2over4 =
    Css.property "right" "-50%"


neg_right_3 : Css.Style
neg_right_3 =
    Css.property "right" "-0.75rem"


neg_right_32 : Css.Style
neg_right_32 =
    Css.property "right" "-8rem"


neg_right_36 : Css.Style
neg_right_36 =
    Css.property "right" "-9rem"


neg_right_3_dot_5 : Css.Style
neg_right_3_dot_5 =
    Css.property "right" "-0.875rem"


neg_right_3over4 : Css.Style
neg_right_3over4 =
    Css.property "right" "-75%"


neg_right_4 : Css.Style
neg_right_4 =
    Css.property "right" "-1rem"


neg_right_40 : Css.Style
neg_right_40 =
    Css.property "right" "-10rem"


neg_right_44 : Css.Style
neg_right_44 =
    Css.property "right" "-11rem"


neg_right_48 : Css.Style
neg_right_48 =
    Css.property "right" "-12rem"


neg_right_5 : Css.Style
neg_right_5 =
    Css.property "right" "-1.25rem"


neg_right_52 : Css.Style
neg_right_52 =
    Css.property "right" "-13rem"


neg_right_56 : Css.Style
neg_right_56 =
    Css.property "right" "-14rem"


neg_right_6 : Css.Style
neg_right_6 =
    Css.property "right" "-1.5rem"


neg_right_60 : Css.Style
neg_right_60 =
    Css.property "right" "-15rem"


neg_right_64 : Css.Style
neg_right_64 =
    Css.property "right" "-16rem"


neg_right_7 : Css.Style
neg_right_7 =
    Css.property "right" "-1.75rem"


neg_right_72 : Css.Style
neg_right_72 =
    Css.property "right" "-18rem"


neg_right_8 : Css.Style
neg_right_8 =
    Css.property "right" "-2rem"


neg_right_80 : Css.Style
neg_right_80 =
    Css.property "right" "-20rem"


neg_right_9 : Css.Style
neg_right_9 =
    Css.property "right" "-2.25rem"


neg_right_96 : Css.Style
neg_right_96 =
    Css.property "right" "-24rem"


neg_right_full : Css.Style
neg_right_full =
    Css.property "right" "-100%"


neg_right_px : Css.Style
neg_right_px =
    Css.property "right" "-1px"


neg_rotate_1 : Css.Style
neg_rotate_1 =
    Css.property "--tw-rotate" "-1deg"


neg_rotate_12 : Css.Style
neg_rotate_12 =
    Css.property "--tw-rotate" "-12deg"


neg_rotate_180 : Css.Style
neg_rotate_180 =
    Css.property "--tw-rotate" "-180deg"


neg_rotate_2 : Css.Style
neg_rotate_2 =
    Css.property "--tw-rotate" "-2deg"


neg_rotate_3 : Css.Style
neg_rotate_3 =
    Css.property "--tw-rotate" "-3deg"


neg_rotate_45 : Css.Style
neg_rotate_45 =
    Css.property "--tw-rotate" "-45deg"


neg_rotate_6 : Css.Style
neg_rotate_6 =
    Css.property "--tw-rotate" "-6deg"


neg_rotate_90 : Css.Style
neg_rotate_90 =
    Css.property "--tw-rotate" "-90deg"


neg_skew_x_1 : Css.Style
neg_skew_x_1 =
    Css.property "--tw-skew-x" "-1deg"


neg_skew_x_12 : Css.Style
neg_skew_x_12 =
    Css.property "--tw-skew-x" "-12deg"


neg_skew_x_2 : Css.Style
neg_skew_x_2 =
    Css.property "--tw-skew-x" "-2deg"


neg_skew_x_3 : Css.Style
neg_skew_x_3 =
    Css.property "--tw-skew-x" "-3deg"


neg_skew_x_6 : Css.Style
neg_skew_x_6 =
    Css.property "--tw-skew-x" "-6deg"


neg_skew_y_1 : Css.Style
neg_skew_y_1 =
    Css.property "--tw-skew-y" "-1deg"


neg_skew_y_12 : Css.Style
neg_skew_y_12 =
    Css.property "--tw-skew-y" "-12deg"


neg_skew_y_2 : Css.Style
neg_skew_y_2 =
    Css.property "--tw-skew-y" "-2deg"


neg_skew_y_3 : Css.Style
neg_skew_y_3 =
    Css.property "--tw-skew-y" "-3deg"


neg_skew_y_6 : Css.Style
neg_skew_y_6 =
    Css.property "--tw-skew-y" "-6deg"


neg_space_x_0 : Css.Style
neg_space_x_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0px * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0px * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_0_dot_5 : Css.Style
neg_space_x_0_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.125rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.125rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_1 : Css.Style
neg_space_x_1 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.25rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.25rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_10 : Css.Style
neg_space_x_10 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-2.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-2.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_11 : Css.Style
neg_space_x_11 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-2.75rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-2.75rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_12 : Css.Style
neg_space_x_12 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-3rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-3rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_14 : Css.Style
neg_space_x_14 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-3.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-3.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_16 : Css.Style
neg_space_x_16 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-4rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-4rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_1_dot_5 : Css.Style
neg_space_x_1_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.375rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.375rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_2 : Css.Style
neg_space_x_2 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_20 : Css.Style
neg_space_x_20 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_24 : Css.Style
neg_space_x_24 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-6rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-6rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_28 : Css.Style
neg_space_x_28 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-7rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-7rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_2_dot_5 : Css.Style
neg_space_x_2_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.625rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.625rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_3 : Css.Style
neg_space_x_3 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.75rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.75rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_32 : Css.Style
neg_space_x_32 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-8rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-8rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_36 : Css.Style
neg_space_x_36 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-9rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-9rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_3_dot_5 : Css.Style
neg_space_x_3_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-0.875rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-0.875rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_4 : Css.Style
neg_space_x_4 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-1rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-1rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_40 : Css.Style
neg_space_x_40 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-10rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-10rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_44 : Css.Style
neg_space_x_44 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-11rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-11rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_48 : Css.Style
neg_space_x_48 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-12rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-12rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_5 : Css.Style
neg_space_x_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-1.25rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-1.25rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_52 : Css.Style
neg_space_x_52 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-13rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-13rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_56 : Css.Style
neg_space_x_56 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-14rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-14rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_6 : Css.Style
neg_space_x_6 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-1.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-1.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_60 : Css.Style
neg_space_x_60 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-15rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-15rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_64 : Css.Style
neg_space_x_64 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-16rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-16rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_7 : Css.Style
neg_space_x_7 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-1.75rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-1.75rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_72 : Css.Style
neg_space_x_72 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-18rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-18rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_8 : Css.Style
neg_space_x_8 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-2rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-2rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_80 : Css.Style
neg_space_x_80 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-20rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-20rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_9 : Css.Style
neg_space_x_9 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-2.25rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-2.25rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_96 : Css.Style
neg_space_x_96 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-24rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-24rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_x_px : Css.Style
neg_space_x_px =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(-1px * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(-1px * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


neg_space_y_0 : Css.Style
neg_space_y_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0px * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0px * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_0_dot_5 : Css.Style
neg_space_y_0_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.125rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.125rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_1 : Css.Style
neg_space_y_1 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.25rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.25rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_10 : Css.Style
neg_space_y_10 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-2.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-2.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_11 : Css.Style
neg_space_y_11 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-2.75rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-2.75rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_12 : Css.Style
neg_space_y_12 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-3rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-3rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_14 : Css.Style
neg_space_y_14 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-3.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-3.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_16 : Css.Style
neg_space_y_16 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-4rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-4rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_1_dot_5 : Css.Style
neg_space_y_1_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.375rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.375rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_2 : Css.Style
neg_space_y_2 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_20 : Css.Style
neg_space_y_20 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_24 : Css.Style
neg_space_y_24 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-6rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-6rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_28 : Css.Style
neg_space_y_28 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-7rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-7rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_2_dot_5 : Css.Style
neg_space_y_2_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.625rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.625rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_3 : Css.Style
neg_space_y_3 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.75rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.75rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_32 : Css.Style
neg_space_y_32 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-8rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-8rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_36 : Css.Style
neg_space_y_36 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-9rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-9rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_3_dot_5 : Css.Style
neg_space_y_3_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-0.875rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-0.875rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_4 : Css.Style
neg_space_y_4 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-1rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-1rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_40 : Css.Style
neg_space_y_40 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-10rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-10rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_44 : Css.Style
neg_space_y_44 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-11rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-11rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_48 : Css.Style
neg_space_y_48 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-12rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-12rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_5 : Css.Style
neg_space_y_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-1.25rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-1.25rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_52 : Css.Style
neg_space_y_52 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-13rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-13rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_56 : Css.Style
neg_space_y_56 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-14rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-14rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_6 : Css.Style
neg_space_y_6 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-1.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-1.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_60 : Css.Style
neg_space_y_60 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-15rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-15rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_64 : Css.Style
neg_space_y_64 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-16rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-16rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_7 : Css.Style
neg_space_y_7 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-1.75rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-1.75rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_72 : Css.Style
neg_space_y_72 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-18rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-18rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_8 : Css.Style
neg_space_y_8 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-2rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-2rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_80 : Css.Style
neg_space_y_80 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-20rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-20rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_9 : Css.Style
neg_space_y_9 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-2.25rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-2.25rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_96 : Css.Style
neg_space_y_96 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-24rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-24rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_space_y_px : Css.Style
neg_space_y_px =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(-1px * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(-1px * var(--tw-space-y-reverse))"
                ]
            ]
        ]


neg_top_0 : Css.Style
neg_top_0 =
    Css.property "top" "0px"


neg_top_0_dot_5 : Css.Style
neg_top_0_dot_5 =
    Css.property "top" "-0.125rem"


neg_top_1 : Css.Style
neg_top_1 =
    Css.property "top" "-0.25rem"


neg_top_10 : Css.Style
neg_top_10 =
    Css.property "top" "-2.5rem"


neg_top_11 : Css.Style
neg_top_11 =
    Css.property "top" "-2.75rem"


neg_top_12 : Css.Style
neg_top_12 =
    Css.property "top" "-3rem"


neg_top_14 : Css.Style
neg_top_14 =
    Css.property "top" "-3.5rem"


neg_top_16 : Css.Style
neg_top_16 =
    Css.property "top" "-4rem"


neg_top_1_dot_5 : Css.Style
neg_top_1_dot_5 =
    Css.property "top" "-0.375rem"


neg_top_1over2 : Css.Style
neg_top_1over2 =
    Css.property "top" "-50%"


neg_top_1over3 : Css.Style
neg_top_1over3 =
    Css.property "top" "-33.333333%"


neg_top_1over4 : Css.Style
neg_top_1over4 =
    Css.property "top" "-25%"


neg_top_2 : Css.Style
neg_top_2 =
    Css.property "top" "-0.5rem"


neg_top_20 : Css.Style
neg_top_20 =
    Css.property "top" "-5rem"


neg_top_24 : Css.Style
neg_top_24 =
    Css.property "top" "-6rem"


neg_top_28 : Css.Style
neg_top_28 =
    Css.property "top" "-7rem"


neg_top_2_dot_5 : Css.Style
neg_top_2_dot_5 =
    Css.property "top" "-0.625rem"


neg_top_2over3 : Css.Style
neg_top_2over3 =
    Css.property "top" "-66.666667%"


neg_top_2over4 : Css.Style
neg_top_2over4 =
    Css.property "top" "-50%"


neg_top_3 : Css.Style
neg_top_3 =
    Css.property "top" "-0.75rem"


neg_top_32 : Css.Style
neg_top_32 =
    Css.property "top" "-8rem"


neg_top_36 : Css.Style
neg_top_36 =
    Css.property "top" "-9rem"


neg_top_3_dot_5 : Css.Style
neg_top_3_dot_5 =
    Css.property "top" "-0.875rem"


neg_top_3over4 : Css.Style
neg_top_3over4 =
    Css.property "top" "-75%"


neg_top_4 : Css.Style
neg_top_4 =
    Css.property "top" "-1rem"


neg_top_40 : Css.Style
neg_top_40 =
    Css.property "top" "-10rem"


neg_top_44 : Css.Style
neg_top_44 =
    Css.property "top" "-11rem"


neg_top_48 : Css.Style
neg_top_48 =
    Css.property "top" "-12rem"


neg_top_5 : Css.Style
neg_top_5 =
    Css.property "top" "-1.25rem"


neg_top_52 : Css.Style
neg_top_52 =
    Css.property "top" "-13rem"


neg_top_56 : Css.Style
neg_top_56 =
    Css.property "top" "-14rem"


neg_top_6 : Css.Style
neg_top_6 =
    Css.property "top" "-1.5rem"


neg_top_60 : Css.Style
neg_top_60 =
    Css.property "top" "-15rem"


neg_top_64 : Css.Style
neg_top_64 =
    Css.property "top" "-16rem"


neg_top_7 : Css.Style
neg_top_7 =
    Css.property "top" "-1.75rem"


neg_top_72 : Css.Style
neg_top_72 =
    Css.property "top" "-18rem"


neg_top_8 : Css.Style
neg_top_8 =
    Css.property "top" "-2rem"


neg_top_80 : Css.Style
neg_top_80 =
    Css.property "top" "-20rem"


neg_top_9 : Css.Style
neg_top_9 =
    Css.property "top" "-2.25rem"


neg_top_96 : Css.Style
neg_top_96 =
    Css.property "top" "-24rem"


neg_top_full : Css.Style
neg_top_full =
    Css.property "top" "-100%"


neg_top_px : Css.Style
neg_top_px =
    Css.property "top" "-1px"


neg_translate_x_0 : Css.Style
neg_translate_x_0 =
    Css.property "--tw-translate-x" "0px"


neg_translate_x_0_dot_5 : Css.Style
neg_translate_x_0_dot_5 =
    Css.property "--tw-translate-x" "-0.125rem"


neg_translate_x_1 : Css.Style
neg_translate_x_1 =
    Css.property "--tw-translate-x" "-0.25rem"


neg_translate_x_10 : Css.Style
neg_translate_x_10 =
    Css.property "--tw-translate-x" "-2.5rem"


neg_translate_x_11 : Css.Style
neg_translate_x_11 =
    Css.property "--tw-translate-x" "-2.75rem"


neg_translate_x_12 : Css.Style
neg_translate_x_12 =
    Css.property "--tw-translate-x" "-3rem"


neg_translate_x_14 : Css.Style
neg_translate_x_14 =
    Css.property "--tw-translate-x" "-3.5rem"


neg_translate_x_16 : Css.Style
neg_translate_x_16 =
    Css.property "--tw-translate-x" "-4rem"


neg_translate_x_1_dot_5 : Css.Style
neg_translate_x_1_dot_5 =
    Css.property "--tw-translate-x" "-0.375rem"


neg_translate_x_1over2 : Css.Style
neg_translate_x_1over2 =
    Css.property "--tw-translate-x" "-50%"


neg_translate_x_1over3 : Css.Style
neg_translate_x_1over3 =
    Css.property "--tw-translate-x" "-33.333333%"


neg_translate_x_1over4 : Css.Style
neg_translate_x_1over4 =
    Css.property "--tw-translate-x" "-25%"


neg_translate_x_2 : Css.Style
neg_translate_x_2 =
    Css.property "--tw-translate-x" "-0.5rem"


neg_translate_x_20 : Css.Style
neg_translate_x_20 =
    Css.property "--tw-translate-x" "-5rem"


neg_translate_x_24 : Css.Style
neg_translate_x_24 =
    Css.property "--tw-translate-x" "-6rem"


neg_translate_x_28 : Css.Style
neg_translate_x_28 =
    Css.property "--tw-translate-x" "-7rem"


neg_translate_x_2_dot_5 : Css.Style
neg_translate_x_2_dot_5 =
    Css.property "--tw-translate-x" "-0.625rem"


neg_translate_x_2over3 : Css.Style
neg_translate_x_2over3 =
    Css.property "--tw-translate-x" "-66.666667%"


neg_translate_x_2over4 : Css.Style
neg_translate_x_2over4 =
    Css.property "--tw-translate-x" "-50%"


neg_translate_x_3 : Css.Style
neg_translate_x_3 =
    Css.property "--tw-translate-x" "-0.75rem"


neg_translate_x_32 : Css.Style
neg_translate_x_32 =
    Css.property "--tw-translate-x" "-8rem"


neg_translate_x_36 : Css.Style
neg_translate_x_36 =
    Css.property "--tw-translate-x" "-9rem"


neg_translate_x_3_dot_5 : Css.Style
neg_translate_x_3_dot_5 =
    Css.property "--tw-translate-x" "-0.875rem"


neg_translate_x_3over4 : Css.Style
neg_translate_x_3over4 =
    Css.property "--tw-translate-x" "-75%"


neg_translate_x_4 : Css.Style
neg_translate_x_4 =
    Css.property "--tw-translate-x" "-1rem"


neg_translate_x_40 : Css.Style
neg_translate_x_40 =
    Css.property "--tw-translate-x" "-10rem"


neg_translate_x_44 : Css.Style
neg_translate_x_44 =
    Css.property "--tw-translate-x" "-11rem"


neg_translate_x_48 : Css.Style
neg_translate_x_48 =
    Css.property "--tw-translate-x" "-12rem"


neg_translate_x_5 : Css.Style
neg_translate_x_5 =
    Css.property "--tw-translate-x" "-1.25rem"


neg_translate_x_52 : Css.Style
neg_translate_x_52 =
    Css.property "--tw-translate-x" "-13rem"


neg_translate_x_56 : Css.Style
neg_translate_x_56 =
    Css.property "--tw-translate-x" "-14rem"


neg_translate_x_6 : Css.Style
neg_translate_x_6 =
    Css.property "--tw-translate-x" "-1.5rem"


neg_translate_x_60 : Css.Style
neg_translate_x_60 =
    Css.property "--tw-translate-x" "-15rem"


neg_translate_x_64 : Css.Style
neg_translate_x_64 =
    Css.property "--tw-translate-x" "-16rem"


neg_translate_x_7 : Css.Style
neg_translate_x_7 =
    Css.property "--tw-translate-x" "-1.75rem"


neg_translate_x_72 : Css.Style
neg_translate_x_72 =
    Css.property "--tw-translate-x" "-18rem"


neg_translate_x_8 : Css.Style
neg_translate_x_8 =
    Css.property "--tw-translate-x" "-2rem"


neg_translate_x_80 : Css.Style
neg_translate_x_80 =
    Css.property "--tw-translate-x" "-20rem"


neg_translate_x_9 : Css.Style
neg_translate_x_9 =
    Css.property "--tw-translate-x" "-2.25rem"


neg_translate_x_96 : Css.Style
neg_translate_x_96 =
    Css.property "--tw-translate-x" "-24rem"


neg_translate_x_full : Css.Style
neg_translate_x_full =
    Css.property "--tw-translate-x" "-100%"


neg_translate_x_px : Css.Style
neg_translate_x_px =
    Css.property "--tw-translate-x" "-1px"


neg_translate_y_0 : Css.Style
neg_translate_y_0 =
    Css.property "--tw-translate-y" "0px"


neg_translate_y_0_dot_5 : Css.Style
neg_translate_y_0_dot_5 =
    Css.property "--tw-translate-y" "-0.125rem"


neg_translate_y_1 : Css.Style
neg_translate_y_1 =
    Css.property "--tw-translate-y" "-0.25rem"


neg_translate_y_10 : Css.Style
neg_translate_y_10 =
    Css.property "--tw-translate-y" "-2.5rem"


neg_translate_y_11 : Css.Style
neg_translate_y_11 =
    Css.property "--tw-translate-y" "-2.75rem"


neg_translate_y_12 : Css.Style
neg_translate_y_12 =
    Css.property "--tw-translate-y" "-3rem"


neg_translate_y_14 : Css.Style
neg_translate_y_14 =
    Css.property "--tw-translate-y" "-3.5rem"


neg_translate_y_16 : Css.Style
neg_translate_y_16 =
    Css.property "--tw-translate-y" "-4rem"


neg_translate_y_1_dot_5 : Css.Style
neg_translate_y_1_dot_5 =
    Css.property "--tw-translate-y" "-0.375rem"


neg_translate_y_1over2 : Css.Style
neg_translate_y_1over2 =
    Css.property "--tw-translate-y" "-50%"


neg_translate_y_1over3 : Css.Style
neg_translate_y_1over3 =
    Css.property "--tw-translate-y" "-33.333333%"


neg_translate_y_1over4 : Css.Style
neg_translate_y_1over4 =
    Css.property "--tw-translate-y" "-25%"


neg_translate_y_2 : Css.Style
neg_translate_y_2 =
    Css.property "--tw-translate-y" "-0.5rem"


neg_translate_y_20 : Css.Style
neg_translate_y_20 =
    Css.property "--tw-translate-y" "-5rem"


neg_translate_y_24 : Css.Style
neg_translate_y_24 =
    Css.property "--tw-translate-y" "-6rem"


neg_translate_y_28 : Css.Style
neg_translate_y_28 =
    Css.property "--tw-translate-y" "-7rem"


neg_translate_y_2_dot_5 : Css.Style
neg_translate_y_2_dot_5 =
    Css.property "--tw-translate-y" "-0.625rem"


neg_translate_y_2over3 : Css.Style
neg_translate_y_2over3 =
    Css.property "--tw-translate-y" "-66.666667%"


neg_translate_y_2over4 : Css.Style
neg_translate_y_2over4 =
    Css.property "--tw-translate-y" "-50%"


neg_translate_y_3 : Css.Style
neg_translate_y_3 =
    Css.property "--tw-translate-y" "-0.75rem"


neg_translate_y_32 : Css.Style
neg_translate_y_32 =
    Css.property "--tw-translate-y" "-8rem"


neg_translate_y_36 : Css.Style
neg_translate_y_36 =
    Css.property "--tw-translate-y" "-9rem"


neg_translate_y_3_dot_5 : Css.Style
neg_translate_y_3_dot_5 =
    Css.property "--tw-translate-y" "-0.875rem"


neg_translate_y_3over4 : Css.Style
neg_translate_y_3over4 =
    Css.property "--tw-translate-y" "-75%"


neg_translate_y_4 : Css.Style
neg_translate_y_4 =
    Css.property "--tw-translate-y" "-1rem"


neg_translate_y_40 : Css.Style
neg_translate_y_40 =
    Css.property "--tw-translate-y" "-10rem"


neg_translate_y_44 : Css.Style
neg_translate_y_44 =
    Css.property "--tw-translate-y" "-11rem"


neg_translate_y_48 : Css.Style
neg_translate_y_48 =
    Css.property "--tw-translate-y" "-12rem"


neg_translate_y_5 : Css.Style
neg_translate_y_5 =
    Css.property "--tw-translate-y" "-1.25rem"


neg_translate_y_52 : Css.Style
neg_translate_y_52 =
    Css.property "--tw-translate-y" "-13rem"


neg_translate_y_56 : Css.Style
neg_translate_y_56 =
    Css.property "--tw-translate-y" "-14rem"


neg_translate_y_6 : Css.Style
neg_translate_y_6 =
    Css.property "--tw-translate-y" "-1.5rem"


neg_translate_y_60 : Css.Style
neg_translate_y_60 =
    Css.property "--tw-translate-y" "-15rem"


neg_translate_y_64 : Css.Style
neg_translate_y_64 =
    Css.property "--tw-translate-y" "-16rem"


neg_translate_y_7 : Css.Style
neg_translate_y_7 =
    Css.property "--tw-translate-y" "-1.75rem"


neg_translate_y_72 : Css.Style
neg_translate_y_72 =
    Css.property "--tw-translate-y" "-18rem"


neg_translate_y_8 : Css.Style
neg_translate_y_8 =
    Css.property "--tw-translate-y" "-2rem"


neg_translate_y_80 : Css.Style
neg_translate_y_80 =
    Css.property "--tw-translate-y" "-20rem"


neg_translate_y_9 : Css.Style
neg_translate_y_9 =
    Css.property "--tw-translate-y" "-2.25rem"


neg_translate_y_96 : Css.Style
neg_translate_y_96 =
    Css.property "--tw-translate-y" "-24rem"


neg_translate_y_full : Css.Style
neg_translate_y_full =
    Css.property "--tw-translate-y" "-100%"


neg_translate_y_px : Css.Style
neg_translate_y_px =
    Css.property "--tw-translate-y" "-1px"


no_underline : Css.Style
no_underline =
    Css.property "text-decoration" "none"


normal_case : Css.Style
normal_case =
    Css.property "text-transform" "none"


normal_nums : Css.Style
normal_nums =
    Css.property "font-variant-numeric" "normal"


not_italic : Css.Style
not_italic =
    Css.property "font-style" "normal"


not_sr_only : Css.Style
not_sr_only =
    Css.batch
        [ Css.property "position" "static"
        , Css.property "width" "auto"
        , Css.property "height" "auto"
        , Css.property "padding" "0"
        , Css.property "margin" "0"
        , Css.property "overflow" "visible"
        , Css.property "clip" "auto"
        , Css.property "white-space" "normal"
        ]


object_bottom : Css.Style
object_bottom =
    Css.property "object-position" "bottom"


object_center : Css.Style
object_center =
    Css.property "object-position" "center"


object_contain : Css.Style
object_contain =
    Css.property "object-fit" "contain"


object_cover : Css.Style
object_cover =
    Css.property "object-fit" "cover"


object_fill : Css.Style
object_fill =
    Css.property "object-fit" "fill"


object_left : Css.Style
object_left =
    Css.property "object-position" "left"


object_left_bottom : Css.Style
object_left_bottom =
    Css.property "object-position" "left bottom"


object_left_top : Css.Style
object_left_top =
    Css.property "object-position" "left top"


object_none : Css.Style
object_none =
    Css.property "object-fit" "none"


object_right : Css.Style
object_right =
    Css.property "object-position" "right"


object_right_bottom : Css.Style
object_right_bottom =
    Css.property "object-position" "right bottom"


object_right_top : Css.Style
object_right_top =
    Css.property "object-position" "right top"


object_scale_down : Css.Style
object_scale_down =
    Css.property "object-fit" "scale-down"


object_top : Css.Style
object_top =
    Css.property "object-position" "top"


oldstyle_nums : Css.Style
oldstyle_nums =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-numeric-figure" "oldstyle-nums"
        ]


opacity_0 : Css.Style
opacity_0 =
    Css.property "opacity" "0"


opacity_10 : Css.Style
opacity_10 =
    Css.property "opacity" "0.1"


opacity_100 : Css.Style
opacity_100 =
    Css.property "opacity" "1"


opacity_20 : Css.Style
opacity_20 =
    Css.property "opacity" "0.2"


opacity_25 : Css.Style
opacity_25 =
    Css.property "opacity" "0.25"


opacity_30 : Css.Style
opacity_30 =
    Css.property "opacity" "0.3"


opacity_40 : Css.Style
opacity_40 =
    Css.property "opacity" "0.4"


opacity_5 : Css.Style
opacity_5 =
    Css.property "opacity" "0.05"


opacity_50 : Css.Style
opacity_50 =
    Css.property "opacity" "0.5"


opacity_60 : Css.Style
opacity_60 =
    Css.property "opacity" "0.6"


opacity_70 : Css.Style
opacity_70 =
    Css.property "opacity" "0.7"


opacity_75 : Css.Style
opacity_75 =
    Css.property "opacity" "0.75"


opacity_80 : Css.Style
opacity_80 =
    Css.property "opacity" "0.8"


opacity_90 : Css.Style
opacity_90 =
    Css.property "opacity" "0.9"


opacity_95 : Css.Style
opacity_95 =
    Css.property "opacity" "0.95"


order_1 : Css.Style
order_1 =
    Css.property "order" "1"


order_10 : Css.Style
order_10 =
    Css.property "order" "10"


order_11 : Css.Style
order_11 =
    Css.property "order" "11"


order_12 : Css.Style
order_12 =
    Css.property "order" "12"


order_2 : Css.Style
order_2 =
    Css.property "order" "2"


order_3 : Css.Style
order_3 =
    Css.property "order" "3"


order_4 : Css.Style
order_4 =
    Css.property "order" "4"


order_5 : Css.Style
order_5 =
    Css.property "order" "5"


order_6 : Css.Style
order_6 =
    Css.property "order" "6"


order_7 : Css.Style
order_7 =
    Css.property "order" "7"


order_8 : Css.Style
order_8 =
    Css.property "order" "8"


order_9 : Css.Style
order_9 =
    Css.property "order" "9"


order_first : Css.Style
order_first =
    Css.property "order" "-9999"


order_last : Css.Style
order_last =
    Css.property "order" "9999"


order_none : Css.Style
order_none =
    Css.property "order" "0"


ordinal : Css.Style
ordinal =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-ordinal" "ordinal"
        ]


origin_bottom : Css.Style
origin_bottom =
    Css.property "transform-origin" "bottom"


origin_bottom_left : Css.Style
origin_bottom_left =
    Css.property "transform-origin" "bottom left"


origin_bottom_right : Css.Style
origin_bottom_right =
    Css.property "transform-origin" "bottom right"


origin_center : Css.Style
origin_center =
    Css.property "transform-origin" "center"


origin_left : Css.Style
origin_left =
    Css.property "transform-origin" "left"


origin_right : Css.Style
origin_right =
    Css.property "transform-origin" "right"


origin_top : Css.Style
origin_top =
    Css.property "transform-origin" "top"


origin_top_left : Css.Style
origin_top_left =
    Css.property "transform-origin" "top left"


origin_top_right : Css.Style
origin_top_right =
    Css.property "transform-origin" "top right"


outline_black : Css.Style
outline_black =
    Css.batch
        [ Css.property "outline" "2px dotted black"
        , Css.property "outline-offset" "2px"
        ]


outline_none : Css.Style
outline_none =
    Css.batch
        [ Css.property "outline" "2px solid transparent"
        , Css.property "outline-offset" "2px"
        ]


outline_white : Css.Style
outline_white =
    Css.batch
        [ Css.property "outline" "2px dotted white"
        , Css.property "outline-offset" "2px"
        ]


overflow_auto : Css.Style
overflow_auto =
    Css.property "overflow" "auto"


overflow_clip : Css.Style
overflow_clip =
    Css.property "text-overflow" "clip"


overflow_ellipsis : Css.Style
overflow_ellipsis =
    Css.property "text-overflow" "ellipsis"


overflow_hidden : Css.Style
overflow_hidden =
    Css.property "overflow" "hidden"


overflow_scroll : Css.Style
overflow_scroll =
    Css.property "overflow" "scroll"


overflow_visible : Css.Style
overflow_visible =
    Css.property "overflow" "visible"


overflow_x_auto : Css.Style
overflow_x_auto =
    Css.property "overflow-x" "auto"


overflow_x_hidden : Css.Style
overflow_x_hidden =
    Css.property "overflow-x" "hidden"


overflow_x_scroll : Css.Style
overflow_x_scroll =
    Css.property "overflow-x" "scroll"


overflow_x_visible : Css.Style
overflow_x_visible =
    Css.property "overflow-x" "visible"


overflow_y_auto : Css.Style
overflow_y_auto =
    Css.property "overflow-y" "auto"


overflow_y_hidden : Css.Style
overflow_y_hidden =
    Css.property "overflow-y" "hidden"


overflow_y_scroll : Css.Style
overflow_y_scroll =
    Css.property "overflow-y" "scroll"


overflow_y_visible : Css.Style
overflow_y_visible =
    Css.property "overflow-y" "visible"


overscroll_auto : Css.Style
overscroll_auto =
    Css.property "overscroll-behavior" "auto"


overscroll_contain : Css.Style
overscroll_contain =
    Css.property "overscroll-behavior" "contain"


overscroll_none : Css.Style
overscroll_none =
    Css.property "overscroll-behavior" "none"


overscroll_x_auto : Css.Style
overscroll_x_auto =
    Css.property "overscroll-behavior-x" "auto"


overscroll_x_contain : Css.Style
overscroll_x_contain =
    Css.property "overscroll-behavior-x" "contain"


overscroll_x_none : Css.Style
overscroll_x_none =
    Css.property "overscroll-behavior-x" "none"


overscroll_y_auto : Css.Style
overscroll_y_auto =
    Css.property "overscroll-behavior-y" "auto"


overscroll_y_contain : Css.Style
overscroll_y_contain =
    Css.property "overscroll-behavior-y" "contain"


overscroll_y_none : Css.Style
overscroll_y_none =
    Css.property "overscroll-behavior-y" "none"


p_0 : Css.Style
p_0 =
    Css.property "padding" "0px"


p_0_dot_5 : Css.Style
p_0_dot_5 =
    Css.property "padding" "0.125rem"


p_1 : Css.Style
p_1 =
    Css.property "padding" "0.25rem"


p_10 : Css.Style
p_10 =
    Css.property "padding" "2.5rem"


p_11 : Css.Style
p_11 =
    Css.property "padding" "2.75rem"


p_12 : Css.Style
p_12 =
    Css.property "padding" "3rem"


p_14 : Css.Style
p_14 =
    Css.property "padding" "3.5rem"


p_16 : Css.Style
p_16 =
    Css.property "padding" "4rem"


p_1_dot_5 : Css.Style
p_1_dot_5 =
    Css.property "padding" "0.375rem"


p_2 : Css.Style
p_2 =
    Css.property "padding" "0.5rem"


p_20 : Css.Style
p_20 =
    Css.property "padding" "5rem"


p_24 : Css.Style
p_24 =
    Css.property "padding" "6rem"


p_28 : Css.Style
p_28 =
    Css.property "padding" "7rem"


p_2_dot_5 : Css.Style
p_2_dot_5 =
    Css.property "padding" "0.625rem"


p_3 : Css.Style
p_3 =
    Css.property "padding" "0.75rem"


p_32 : Css.Style
p_32 =
    Css.property "padding" "8rem"


p_36 : Css.Style
p_36 =
    Css.property "padding" "9rem"


p_3_dot_5 : Css.Style
p_3_dot_5 =
    Css.property "padding" "0.875rem"


p_4 : Css.Style
p_4 =
    Css.property "padding" "1rem"


p_40 : Css.Style
p_40 =
    Css.property "padding" "10rem"


p_44 : Css.Style
p_44 =
    Css.property "padding" "11rem"


p_48 : Css.Style
p_48 =
    Css.property "padding" "12rem"


p_5 : Css.Style
p_5 =
    Css.property "padding" "1.25rem"


p_52 : Css.Style
p_52 =
    Css.property "padding" "13rem"


p_56 : Css.Style
p_56 =
    Css.property "padding" "14rem"


p_6 : Css.Style
p_6 =
    Css.property "padding" "1.5rem"


p_60 : Css.Style
p_60 =
    Css.property "padding" "15rem"


p_64 : Css.Style
p_64 =
    Css.property "padding" "16rem"


p_7 : Css.Style
p_7 =
    Css.property "padding" "1.75rem"


p_72 : Css.Style
p_72 =
    Css.property "padding" "18rem"


p_8 : Css.Style
p_8 =
    Css.property "padding" "2rem"


p_80 : Css.Style
p_80 =
    Css.property "padding" "20rem"


p_9 : Css.Style
p_9 =
    Css.property "padding" "2.25rem"


p_96 : Css.Style
p_96 =
    Css.property "padding" "24rem"


p_px : Css.Style
p_px =
    Css.property "padding" "1px"


pb_0 : Css.Style
pb_0 =
    Css.property "padding-bottom" "0px"


pb_0_dot_5 : Css.Style
pb_0_dot_5 =
    Css.property "padding-bottom" "0.125rem"


pb_1 : Css.Style
pb_1 =
    Css.property "padding-bottom" "0.25rem"


pb_10 : Css.Style
pb_10 =
    Css.property "padding-bottom" "2.5rem"


pb_11 : Css.Style
pb_11 =
    Css.property "padding-bottom" "2.75rem"


pb_12 : Css.Style
pb_12 =
    Css.property "padding-bottom" "3rem"


pb_14 : Css.Style
pb_14 =
    Css.property "padding-bottom" "3.5rem"


pb_16 : Css.Style
pb_16 =
    Css.property "padding-bottom" "4rem"


pb_1_dot_5 : Css.Style
pb_1_dot_5 =
    Css.property "padding-bottom" "0.375rem"


pb_2 : Css.Style
pb_2 =
    Css.property "padding-bottom" "0.5rem"


pb_20 : Css.Style
pb_20 =
    Css.property "padding-bottom" "5rem"


pb_24 : Css.Style
pb_24 =
    Css.property "padding-bottom" "6rem"


pb_28 : Css.Style
pb_28 =
    Css.property "padding-bottom" "7rem"


pb_2_dot_5 : Css.Style
pb_2_dot_5 =
    Css.property "padding-bottom" "0.625rem"


pb_3 : Css.Style
pb_3 =
    Css.property "padding-bottom" "0.75rem"


pb_32 : Css.Style
pb_32 =
    Css.property "padding-bottom" "8rem"


pb_36 : Css.Style
pb_36 =
    Css.property "padding-bottom" "9rem"


pb_3_dot_5 : Css.Style
pb_3_dot_5 =
    Css.property "padding-bottom" "0.875rem"


pb_4 : Css.Style
pb_4 =
    Css.property "padding-bottom" "1rem"


pb_40 : Css.Style
pb_40 =
    Css.property "padding-bottom" "10rem"


pb_44 : Css.Style
pb_44 =
    Css.property "padding-bottom" "11rem"


pb_48 : Css.Style
pb_48 =
    Css.property "padding-bottom" "12rem"


pb_5 : Css.Style
pb_5 =
    Css.property "padding-bottom" "1.25rem"


pb_52 : Css.Style
pb_52 =
    Css.property "padding-bottom" "13rem"


pb_56 : Css.Style
pb_56 =
    Css.property "padding-bottom" "14rem"


pb_6 : Css.Style
pb_6 =
    Css.property "padding-bottom" "1.5rem"


pb_60 : Css.Style
pb_60 =
    Css.property "padding-bottom" "15rem"


pb_64 : Css.Style
pb_64 =
    Css.property "padding-bottom" "16rem"


pb_7 : Css.Style
pb_7 =
    Css.property "padding-bottom" "1.75rem"


pb_72 : Css.Style
pb_72 =
    Css.property "padding-bottom" "18rem"


pb_8 : Css.Style
pb_8 =
    Css.property "padding-bottom" "2rem"


pb_80 : Css.Style
pb_80 =
    Css.property "padding-bottom" "20rem"


pb_9 : Css.Style
pb_9 =
    Css.property "padding-bottom" "2.25rem"


pb_96 : Css.Style
pb_96 =
    Css.property "padding-bottom" "24rem"


pb_px : Css.Style
pb_px =
    Css.property "padding-bottom" "1px"


pl_0 : Css.Style
pl_0 =
    Css.property "padding-left" "0px"


pl_0_dot_5 : Css.Style
pl_0_dot_5 =
    Css.property "padding-left" "0.125rem"


pl_1 : Css.Style
pl_1 =
    Css.property "padding-left" "0.25rem"


pl_10 : Css.Style
pl_10 =
    Css.property "padding-left" "2.5rem"


pl_11 : Css.Style
pl_11 =
    Css.property "padding-left" "2.75rem"


pl_12 : Css.Style
pl_12 =
    Css.property "padding-left" "3rem"


pl_14 : Css.Style
pl_14 =
    Css.property "padding-left" "3.5rem"


pl_16 : Css.Style
pl_16 =
    Css.property "padding-left" "4rem"


pl_1_dot_5 : Css.Style
pl_1_dot_5 =
    Css.property "padding-left" "0.375rem"


pl_2 : Css.Style
pl_2 =
    Css.property "padding-left" "0.5rem"


pl_20 : Css.Style
pl_20 =
    Css.property "padding-left" "5rem"


pl_24 : Css.Style
pl_24 =
    Css.property "padding-left" "6rem"


pl_28 : Css.Style
pl_28 =
    Css.property "padding-left" "7rem"


pl_2_dot_5 : Css.Style
pl_2_dot_5 =
    Css.property "padding-left" "0.625rem"


pl_3 : Css.Style
pl_3 =
    Css.property "padding-left" "0.75rem"


pl_32 : Css.Style
pl_32 =
    Css.property "padding-left" "8rem"


pl_36 : Css.Style
pl_36 =
    Css.property "padding-left" "9rem"


pl_3_dot_5 : Css.Style
pl_3_dot_5 =
    Css.property "padding-left" "0.875rem"


pl_4 : Css.Style
pl_4 =
    Css.property "padding-left" "1rem"


pl_40 : Css.Style
pl_40 =
    Css.property "padding-left" "10rem"


pl_44 : Css.Style
pl_44 =
    Css.property "padding-left" "11rem"


pl_48 : Css.Style
pl_48 =
    Css.property "padding-left" "12rem"


pl_5 : Css.Style
pl_5 =
    Css.property "padding-left" "1.25rem"


pl_52 : Css.Style
pl_52 =
    Css.property "padding-left" "13rem"


pl_56 : Css.Style
pl_56 =
    Css.property "padding-left" "14rem"


pl_6 : Css.Style
pl_6 =
    Css.property "padding-left" "1.5rem"


pl_60 : Css.Style
pl_60 =
    Css.property "padding-left" "15rem"


pl_64 : Css.Style
pl_64 =
    Css.property "padding-left" "16rem"


pl_7 : Css.Style
pl_7 =
    Css.property "padding-left" "1.75rem"


pl_72 : Css.Style
pl_72 =
    Css.property "padding-left" "18rem"


pl_8 : Css.Style
pl_8 =
    Css.property "padding-left" "2rem"


pl_80 : Css.Style
pl_80 =
    Css.property "padding-left" "20rem"


pl_9 : Css.Style
pl_9 =
    Css.property "padding-left" "2.25rem"


pl_96 : Css.Style
pl_96 =
    Css.property "padding-left" "24rem"


pl_px : Css.Style
pl_px =
    Css.property "padding-left" "1px"


place_content_around : Css.Style
place_content_around =
    Css.property "place-content" "space-around"


place_content_between : Css.Style
place_content_between =
    Css.property "place-content" "space-between"


place_content_center : Css.Style
place_content_center =
    Css.property "place-content" "center"


place_content_end : Css.Style
place_content_end =
    Css.property "place-content" "end"


place_content_evenly : Css.Style
place_content_evenly =
    Css.property "place-content" "space-evenly"


place_content_start : Css.Style
place_content_start =
    Css.property "place-content" "start"


place_content_stretch : Css.Style
place_content_stretch =
    Css.property "place-content" "stretch"


place_items_center : Css.Style
place_items_center =
    Css.property "place-items" "center"


place_items_end : Css.Style
place_items_end =
    Css.property "place-items" "end"


place_items_start : Css.Style
place_items_start =
    Css.property "place-items" "start"


place_items_stretch : Css.Style
place_items_stretch =
    Css.property "place-items" "stretch"


place_self_auto : Css.Style
place_self_auto =
    Css.property "place-self" "auto"


place_self_center : Css.Style
place_self_center =
    Css.property "place-self" "center"


place_self_end : Css.Style
place_self_end =
    Css.property "place-self" "end"


place_self_start : Css.Style
place_self_start =
    Css.property "place-self" "start"


place_self_stretch : Css.Style
place_self_stretch =
    Css.property "place-self" "stretch"


placeholder_black : Css.Style
placeholder_black =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(0, 0, 0, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_100 : Css.Style
placeholder_blue_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(219, 234, 254, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_200 : Css.Style
placeholder_blue_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(191, 219, 254, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_300 : Css.Style
placeholder_blue_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(147, 197, 253, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_400 : Css.Style
placeholder_blue_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(96, 165, 250, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_50 : Css.Style
placeholder_blue_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(239, 246, 255, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_500 : Css.Style
placeholder_blue_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(59, 130, 246, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_600 : Css.Style
placeholder_blue_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(37, 99, 235, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_700 : Css.Style
placeholder_blue_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(29, 78, 216, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_800 : Css.Style
placeholder_blue_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(30, 64, 175, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_blue_900 : Css.Style
placeholder_blue_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(30, 58, 138, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_current : Css.Style
placeholder_current =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "color" "currentColor"
            ]
        ]


placeholder_gray_100 : Css.Style
placeholder_gray_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(243, 244, 246, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_200 : Css.Style
placeholder_gray_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(229, 231, 235, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_300 : Css.Style
placeholder_gray_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(209, 213, 219, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_400 : Css.Style
placeholder_gray_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(156, 163, 175, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_50 : Css.Style
placeholder_gray_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(249, 250, 251, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_500 : Css.Style
placeholder_gray_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(107, 114, 128, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_600 : Css.Style
placeholder_gray_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(75, 85, 99, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_700 : Css.Style
placeholder_gray_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(55, 65, 81, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_800 : Css.Style
placeholder_gray_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(31, 41, 55, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_gray_900 : Css.Style
placeholder_gray_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(17, 24, 39, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_100 : Css.Style
placeholder_green_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(209, 250, 229, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_200 : Css.Style
placeholder_green_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(167, 243, 208, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_300 : Css.Style
placeholder_green_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(110, 231, 183, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_400 : Css.Style
placeholder_green_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(52, 211, 153, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_50 : Css.Style
placeholder_green_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(236, 253, 245, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_500 : Css.Style
placeholder_green_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(16, 185, 129, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_600 : Css.Style
placeholder_green_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(5, 150, 105, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_700 : Css.Style
placeholder_green_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(4, 120, 87, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_800 : Css.Style
placeholder_green_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(6, 95, 70, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_green_900 : Css.Style
placeholder_green_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(6, 78, 59, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_100 : Css.Style
placeholder_indigo_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(224, 231, 255, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_200 : Css.Style
placeholder_indigo_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(199, 210, 254, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_300 : Css.Style
placeholder_indigo_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(165, 180, 252, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_400 : Css.Style
placeholder_indigo_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(129, 140, 248, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_50 : Css.Style
placeholder_indigo_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(238, 242, 255, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_500 : Css.Style
placeholder_indigo_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(99, 102, 241, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_600 : Css.Style
placeholder_indigo_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(79, 70, 229, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_700 : Css.Style
placeholder_indigo_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(67, 56, 202, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_800 : Css.Style
placeholder_indigo_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(55, 48, 163, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_indigo_900 : Css.Style
placeholder_indigo_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(49, 46, 129, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_opacity_0 : Css.Style
placeholder_opacity_0 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0"
            ]
        ]


placeholder_opacity_10 : Css.Style
placeholder_opacity_10 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.1"
            ]
        ]


placeholder_opacity_100 : Css.Style
placeholder_opacity_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            ]
        ]


placeholder_opacity_20 : Css.Style
placeholder_opacity_20 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.2"
            ]
        ]


placeholder_opacity_25 : Css.Style
placeholder_opacity_25 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.25"
            ]
        ]


placeholder_opacity_30 : Css.Style
placeholder_opacity_30 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.3"
            ]
        ]


placeholder_opacity_40 : Css.Style
placeholder_opacity_40 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.4"
            ]
        ]


placeholder_opacity_5 : Css.Style
placeholder_opacity_5 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.05"
            ]
        ]


placeholder_opacity_50 : Css.Style
placeholder_opacity_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.5"
            ]
        ]


placeholder_opacity_60 : Css.Style
placeholder_opacity_60 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.6"
            ]
        ]


placeholder_opacity_70 : Css.Style
placeholder_opacity_70 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.7"
            ]
        ]


placeholder_opacity_75 : Css.Style
placeholder_opacity_75 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.75"
            ]
        ]


placeholder_opacity_80 : Css.Style
placeholder_opacity_80 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.8"
            ]
        ]


placeholder_opacity_90 : Css.Style
placeholder_opacity_90 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.9"
            ]
        ]


placeholder_opacity_95 : Css.Style
placeholder_opacity_95 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "0.95"
            ]
        ]


placeholder_pink_100 : Css.Style
placeholder_pink_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(252, 231, 243, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_200 : Css.Style
placeholder_pink_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(251, 207, 232, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_300 : Css.Style
placeholder_pink_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(249, 168, 212, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_400 : Css.Style
placeholder_pink_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(244, 114, 182, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_50 : Css.Style
placeholder_pink_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(253, 242, 248, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_500 : Css.Style
placeholder_pink_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(236, 72, 153, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_600 : Css.Style
placeholder_pink_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(219, 39, 119, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_700 : Css.Style
placeholder_pink_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(190, 24, 93, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_800 : Css.Style
placeholder_pink_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(157, 23, 77, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_pink_900 : Css.Style
placeholder_pink_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(131, 24, 67, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_100 : Css.Style
placeholder_purple_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(237, 233, 254, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_200 : Css.Style
placeholder_purple_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(221, 214, 254, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_300 : Css.Style
placeholder_purple_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(196, 181, 253, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_400 : Css.Style
placeholder_purple_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(167, 139, 250, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_50 : Css.Style
placeholder_purple_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(245, 243, 255, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_500 : Css.Style
placeholder_purple_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(139, 92, 246, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_600 : Css.Style
placeholder_purple_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(124, 58, 237, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_700 : Css.Style
placeholder_purple_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(109, 40, 217, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_800 : Css.Style
placeholder_purple_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(91, 33, 182, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_purple_900 : Css.Style
placeholder_purple_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(76, 29, 149, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_100 : Css.Style
placeholder_red_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(254, 226, 226, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_200 : Css.Style
placeholder_red_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(254, 202, 202, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_300 : Css.Style
placeholder_red_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(252, 165, 165, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_400 : Css.Style
placeholder_red_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(248, 113, 113, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_50 : Css.Style
placeholder_red_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(254, 242, 242, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_500 : Css.Style
placeholder_red_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(239, 68, 68, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_600 : Css.Style
placeholder_red_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(220, 38, 38, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_700 : Css.Style
placeholder_red_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(185, 28, 28, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_800 : Css.Style
placeholder_red_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(153, 27, 27, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_red_900 : Css.Style
placeholder_red_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(127, 29, 29, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_transparent : Css.Style
placeholder_transparent =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "color" "transparent"
            ]
        ]


placeholder_white : Css.Style
placeholder_white =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(255, 255, 255, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_100 : Css.Style
placeholder_yellow_100 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(254, 243, 199, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_200 : Css.Style
placeholder_yellow_200 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(253, 230, 138, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_300 : Css.Style
placeholder_yellow_300 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(252, 211, 77, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_400 : Css.Style
placeholder_yellow_400 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(251, 191, 36, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_50 : Css.Style
placeholder_yellow_50 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(255, 251, 235, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_500 : Css.Style
placeholder_yellow_500 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(245, 158, 11, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_600 : Css.Style
placeholder_yellow_600 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(217, 119, 6, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_700 : Css.Style
placeholder_yellow_700 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(180, 83, 9, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_800 : Css.Style
placeholder_yellow_800 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(146, 64, 14, var(--tw-placeholder-opacity))"
            ]
        ]


placeholder_yellow_900 : Css.Style
placeholder_yellow_900 =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" "rgba(120, 53, 15, var(--tw-placeholder-opacity))"
            ]
        ]


pointer_events_auto : Css.Style
pointer_events_auto =
    Css.property "pointer-events" "auto"


pointer_events_none : Css.Style
pointer_events_none =
    Css.property "pointer-events" "none"


pr_0 : Css.Style
pr_0 =
    Css.property "padding-right" "0px"


pr_0_dot_5 : Css.Style
pr_0_dot_5 =
    Css.property "padding-right" "0.125rem"


pr_1 : Css.Style
pr_1 =
    Css.property "padding-right" "0.25rem"


pr_10 : Css.Style
pr_10 =
    Css.property "padding-right" "2.5rem"


pr_11 : Css.Style
pr_11 =
    Css.property "padding-right" "2.75rem"


pr_12 : Css.Style
pr_12 =
    Css.property "padding-right" "3rem"


pr_14 : Css.Style
pr_14 =
    Css.property "padding-right" "3.5rem"


pr_16 : Css.Style
pr_16 =
    Css.property "padding-right" "4rem"


pr_1_dot_5 : Css.Style
pr_1_dot_5 =
    Css.property "padding-right" "0.375rem"


pr_2 : Css.Style
pr_2 =
    Css.property "padding-right" "0.5rem"


pr_20 : Css.Style
pr_20 =
    Css.property "padding-right" "5rem"


pr_24 : Css.Style
pr_24 =
    Css.property "padding-right" "6rem"


pr_28 : Css.Style
pr_28 =
    Css.property "padding-right" "7rem"


pr_2_dot_5 : Css.Style
pr_2_dot_5 =
    Css.property "padding-right" "0.625rem"


pr_3 : Css.Style
pr_3 =
    Css.property "padding-right" "0.75rem"


pr_32 : Css.Style
pr_32 =
    Css.property "padding-right" "8rem"


pr_36 : Css.Style
pr_36 =
    Css.property "padding-right" "9rem"


pr_3_dot_5 : Css.Style
pr_3_dot_5 =
    Css.property "padding-right" "0.875rem"


pr_4 : Css.Style
pr_4 =
    Css.property "padding-right" "1rem"


pr_40 : Css.Style
pr_40 =
    Css.property "padding-right" "10rem"


pr_44 : Css.Style
pr_44 =
    Css.property "padding-right" "11rem"


pr_48 : Css.Style
pr_48 =
    Css.property "padding-right" "12rem"


pr_5 : Css.Style
pr_5 =
    Css.property "padding-right" "1.25rem"


pr_52 : Css.Style
pr_52 =
    Css.property "padding-right" "13rem"


pr_56 : Css.Style
pr_56 =
    Css.property "padding-right" "14rem"


pr_6 : Css.Style
pr_6 =
    Css.property "padding-right" "1.5rem"


pr_60 : Css.Style
pr_60 =
    Css.property "padding-right" "15rem"


pr_64 : Css.Style
pr_64 =
    Css.property "padding-right" "16rem"


pr_7 : Css.Style
pr_7 =
    Css.property "padding-right" "1.75rem"


pr_72 : Css.Style
pr_72 =
    Css.property "padding-right" "18rem"


pr_8 : Css.Style
pr_8 =
    Css.property "padding-right" "2rem"


pr_80 : Css.Style
pr_80 =
    Css.property "padding-right" "20rem"


pr_9 : Css.Style
pr_9 =
    Css.property "padding-right" "2.25rem"


pr_96 : Css.Style
pr_96 =
    Css.property "padding-right" "24rem"


pr_px : Css.Style
pr_px =
    Css.property "padding-right" "1px"


proportional_nums : Css.Style
proportional_nums =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-numeric-spacing" "proportional-nums"
        ]


pt_0 : Css.Style
pt_0 =
    Css.property "padding-top" "0px"


pt_0_dot_5 : Css.Style
pt_0_dot_5 =
    Css.property "padding-top" "0.125rem"


pt_1 : Css.Style
pt_1 =
    Css.property "padding-top" "0.25rem"


pt_10 : Css.Style
pt_10 =
    Css.property "padding-top" "2.5rem"


pt_11 : Css.Style
pt_11 =
    Css.property "padding-top" "2.75rem"


pt_12 : Css.Style
pt_12 =
    Css.property "padding-top" "3rem"


pt_14 : Css.Style
pt_14 =
    Css.property "padding-top" "3.5rem"


pt_16 : Css.Style
pt_16 =
    Css.property "padding-top" "4rem"


pt_1_dot_5 : Css.Style
pt_1_dot_5 =
    Css.property "padding-top" "0.375rem"


pt_2 : Css.Style
pt_2 =
    Css.property "padding-top" "0.5rem"


pt_20 : Css.Style
pt_20 =
    Css.property "padding-top" "5rem"


pt_24 : Css.Style
pt_24 =
    Css.property "padding-top" "6rem"


pt_28 : Css.Style
pt_28 =
    Css.property "padding-top" "7rem"


pt_2_dot_5 : Css.Style
pt_2_dot_5 =
    Css.property "padding-top" "0.625rem"


pt_3 : Css.Style
pt_3 =
    Css.property "padding-top" "0.75rem"


pt_32 : Css.Style
pt_32 =
    Css.property "padding-top" "8rem"


pt_36 : Css.Style
pt_36 =
    Css.property "padding-top" "9rem"


pt_3_dot_5 : Css.Style
pt_3_dot_5 =
    Css.property "padding-top" "0.875rem"


pt_4 : Css.Style
pt_4 =
    Css.property "padding-top" "1rem"


pt_40 : Css.Style
pt_40 =
    Css.property "padding-top" "10rem"


pt_44 : Css.Style
pt_44 =
    Css.property "padding-top" "11rem"


pt_48 : Css.Style
pt_48 =
    Css.property "padding-top" "12rem"


pt_5 : Css.Style
pt_5 =
    Css.property "padding-top" "1.25rem"


pt_52 : Css.Style
pt_52 =
    Css.property "padding-top" "13rem"


pt_56 : Css.Style
pt_56 =
    Css.property "padding-top" "14rem"


pt_6 : Css.Style
pt_6 =
    Css.property "padding-top" "1.5rem"


pt_60 : Css.Style
pt_60 =
    Css.property "padding-top" "15rem"


pt_64 : Css.Style
pt_64 =
    Css.property "padding-top" "16rem"


pt_7 : Css.Style
pt_7 =
    Css.property "padding-top" "1.75rem"


pt_72 : Css.Style
pt_72 =
    Css.property "padding-top" "18rem"


pt_8 : Css.Style
pt_8 =
    Css.property "padding-top" "2rem"


pt_80 : Css.Style
pt_80 =
    Css.property "padding-top" "20rem"


pt_9 : Css.Style
pt_9 =
    Css.property "padding-top" "2.25rem"


pt_96 : Css.Style
pt_96 =
    Css.property "padding-top" "24rem"


pt_px : Css.Style
pt_px =
    Css.property "padding-top" "1px"


px_0 : Css.Style
px_0 =
    Css.batch
        [ Css.property "padding-left" "0px"
        , Css.property "padding-right" "0px"
        ]


px_0_dot_5 : Css.Style
px_0_dot_5 =
    Css.batch
        [ Css.property "padding-left" "0.125rem"
        , Css.property "padding-right" "0.125rem"
        ]


px_1 : Css.Style
px_1 =
    Css.batch
        [ Css.property "padding-left" "0.25rem"
        , Css.property "padding-right" "0.25rem"
        ]


px_10 : Css.Style
px_10 =
    Css.batch
        [ Css.property "padding-left" "2.5rem"
        , Css.property "padding-right" "2.5rem"
        ]


px_11 : Css.Style
px_11 =
    Css.batch
        [ Css.property "padding-left" "2.75rem"
        , Css.property "padding-right" "2.75rem"
        ]


px_12 : Css.Style
px_12 =
    Css.batch
        [ Css.property "padding-left" "3rem"
        , Css.property "padding-right" "3rem"
        ]


px_14 : Css.Style
px_14 =
    Css.batch
        [ Css.property "padding-left" "3.5rem"
        , Css.property "padding-right" "3.5rem"
        ]


px_16 : Css.Style
px_16 =
    Css.batch
        [ Css.property "padding-left" "4rem"
        , Css.property "padding-right" "4rem"
        ]


px_1_dot_5 : Css.Style
px_1_dot_5 =
    Css.batch
        [ Css.property "padding-left" "0.375rem"
        , Css.property "padding-right" "0.375rem"
        ]


px_2 : Css.Style
px_2 =
    Css.batch
        [ Css.property "padding-left" "0.5rem"
        , Css.property "padding-right" "0.5rem"
        ]


px_20 : Css.Style
px_20 =
    Css.batch
        [ Css.property "padding-left" "5rem"
        , Css.property "padding-right" "5rem"
        ]


px_24 : Css.Style
px_24 =
    Css.batch
        [ Css.property "padding-left" "6rem"
        , Css.property "padding-right" "6rem"
        ]


px_28 : Css.Style
px_28 =
    Css.batch
        [ Css.property "padding-left" "7rem"
        , Css.property "padding-right" "7rem"
        ]


px_2_dot_5 : Css.Style
px_2_dot_5 =
    Css.batch
        [ Css.property "padding-left" "0.625rem"
        , Css.property "padding-right" "0.625rem"
        ]


px_3 : Css.Style
px_3 =
    Css.batch
        [ Css.property "padding-left" "0.75rem"
        , Css.property "padding-right" "0.75rem"
        ]


px_32 : Css.Style
px_32 =
    Css.batch
        [ Css.property "padding-left" "8rem"
        , Css.property "padding-right" "8rem"
        ]


px_36 : Css.Style
px_36 =
    Css.batch
        [ Css.property "padding-left" "9rem"
        , Css.property "padding-right" "9rem"
        ]


px_3_dot_5 : Css.Style
px_3_dot_5 =
    Css.batch
        [ Css.property "padding-left" "0.875rem"
        , Css.property "padding-right" "0.875rem"
        ]


px_4 : Css.Style
px_4 =
    Css.batch
        [ Css.property "padding-left" "1rem"
        , Css.property "padding-right" "1rem"
        ]


px_40 : Css.Style
px_40 =
    Css.batch
        [ Css.property "padding-left" "10rem"
        , Css.property "padding-right" "10rem"
        ]


px_44 : Css.Style
px_44 =
    Css.batch
        [ Css.property "padding-left" "11rem"
        , Css.property "padding-right" "11rem"
        ]


px_48 : Css.Style
px_48 =
    Css.batch
        [ Css.property "padding-left" "12rem"
        , Css.property "padding-right" "12rem"
        ]


px_5 : Css.Style
px_5 =
    Css.batch
        [ Css.property "padding-left" "1.25rem"
        , Css.property "padding-right" "1.25rem"
        ]


px_52 : Css.Style
px_52 =
    Css.batch
        [ Css.property "padding-left" "13rem"
        , Css.property "padding-right" "13rem"
        ]


px_56 : Css.Style
px_56 =
    Css.batch
        [ Css.property "padding-left" "14rem"
        , Css.property "padding-right" "14rem"
        ]


px_6 : Css.Style
px_6 =
    Css.batch
        [ Css.property "padding-left" "1.5rem"
        , Css.property "padding-right" "1.5rem"
        ]


px_60 : Css.Style
px_60 =
    Css.batch
        [ Css.property "padding-left" "15rem"
        , Css.property "padding-right" "15rem"
        ]


px_64 : Css.Style
px_64 =
    Css.batch
        [ Css.property "padding-left" "16rem"
        , Css.property "padding-right" "16rem"
        ]


px_7 : Css.Style
px_7 =
    Css.batch
        [ Css.property "padding-left" "1.75rem"
        , Css.property "padding-right" "1.75rem"
        ]


px_72 : Css.Style
px_72 =
    Css.batch
        [ Css.property "padding-left" "18rem"
        , Css.property "padding-right" "18rem"
        ]


px_8 : Css.Style
px_8 =
    Css.batch
        [ Css.property "padding-left" "2rem"
        , Css.property "padding-right" "2rem"
        ]


px_80 : Css.Style
px_80 =
    Css.batch
        [ Css.property "padding-left" "20rem"
        , Css.property "padding-right" "20rem"
        ]


px_9 : Css.Style
px_9 =
    Css.batch
        [ Css.property "padding-left" "2.25rem"
        , Css.property "padding-right" "2.25rem"
        ]


px_96 : Css.Style
px_96 =
    Css.batch
        [ Css.property "padding-left" "24rem"
        , Css.property "padding-right" "24rem"
        ]


px_px : Css.Style
px_px =
    Css.batch
        [ Css.property "padding-left" "1px"
        , Css.property "padding-right" "1px"
        ]


py_0 : Css.Style
py_0 =
    Css.batch
        [ Css.property "padding-top" "0px"
        , Css.property "padding-bottom" "0px"
        ]


py_0_dot_5 : Css.Style
py_0_dot_5 =
    Css.batch
        [ Css.property "padding-top" "0.125rem"
        , Css.property "padding-bottom" "0.125rem"
        ]


py_1 : Css.Style
py_1 =
    Css.batch
        [ Css.property "padding-top" "0.25rem"
        , Css.property "padding-bottom" "0.25rem"
        ]


py_10 : Css.Style
py_10 =
    Css.batch
        [ Css.property "padding-top" "2.5rem"
        , Css.property "padding-bottom" "2.5rem"
        ]


py_11 : Css.Style
py_11 =
    Css.batch
        [ Css.property "padding-top" "2.75rem"
        , Css.property "padding-bottom" "2.75rem"
        ]


py_12 : Css.Style
py_12 =
    Css.batch
        [ Css.property "padding-top" "3rem"
        , Css.property "padding-bottom" "3rem"
        ]


py_14 : Css.Style
py_14 =
    Css.batch
        [ Css.property "padding-top" "3.5rem"
        , Css.property "padding-bottom" "3.5rem"
        ]


py_16 : Css.Style
py_16 =
    Css.batch
        [ Css.property "padding-top" "4rem"
        , Css.property "padding-bottom" "4rem"
        ]


py_1_dot_5 : Css.Style
py_1_dot_5 =
    Css.batch
        [ Css.property "padding-top" "0.375rem"
        , Css.property "padding-bottom" "0.375rem"
        ]


py_2 : Css.Style
py_2 =
    Css.batch
        [ Css.property "padding-top" "0.5rem"
        , Css.property "padding-bottom" "0.5rem"
        ]


py_20 : Css.Style
py_20 =
    Css.batch
        [ Css.property "padding-top" "5rem"
        , Css.property "padding-bottom" "5rem"
        ]


py_24 : Css.Style
py_24 =
    Css.batch
        [ Css.property "padding-top" "6rem"
        , Css.property "padding-bottom" "6rem"
        ]


py_28 : Css.Style
py_28 =
    Css.batch
        [ Css.property "padding-top" "7rem"
        , Css.property "padding-bottom" "7rem"
        ]


py_2_dot_5 : Css.Style
py_2_dot_5 =
    Css.batch
        [ Css.property "padding-top" "0.625rem"
        , Css.property "padding-bottom" "0.625rem"
        ]


py_3 : Css.Style
py_3 =
    Css.batch
        [ Css.property "padding-top" "0.75rem"
        , Css.property "padding-bottom" "0.75rem"
        ]


py_32 : Css.Style
py_32 =
    Css.batch
        [ Css.property "padding-top" "8rem"
        , Css.property "padding-bottom" "8rem"
        ]


py_36 : Css.Style
py_36 =
    Css.batch
        [ Css.property "padding-top" "9rem"
        , Css.property "padding-bottom" "9rem"
        ]


py_3_dot_5 : Css.Style
py_3_dot_5 =
    Css.batch
        [ Css.property "padding-top" "0.875rem"
        , Css.property "padding-bottom" "0.875rem"
        ]


py_4 : Css.Style
py_4 =
    Css.batch
        [ Css.property "padding-top" "1rem"
        , Css.property "padding-bottom" "1rem"
        ]


py_40 : Css.Style
py_40 =
    Css.batch
        [ Css.property "padding-top" "10rem"
        , Css.property "padding-bottom" "10rem"
        ]


py_44 : Css.Style
py_44 =
    Css.batch
        [ Css.property "padding-top" "11rem"
        , Css.property "padding-bottom" "11rem"
        ]


py_48 : Css.Style
py_48 =
    Css.batch
        [ Css.property "padding-top" "12rem"
        , Css.property "padding-bottom" "12rem"
        ]


py_5 : Css.Style
py_5 =
    Css.batch
        [ Css.property "padding-top" "1.25rem"
        , Css.property "padding-bottom" "1.25rem"
        ]


py_52 : Css.Style
py_52 =
    Css.batch
        [ Css.property "padding-top" "13rem"
        , Css.property "padding-bottom" "13rem"
        ]


py_56 : Css.Style
py_56 =
    Css.batch
        [ Css.property "padding-top" "14rem"
        , Css.property "padding-bottom" "14rem"
        ]


py_6 : Css.Style
py_6 =
    Css.batch
        [ Css.property "padding-top" "1.5rem"
        , Css.property "padding-bottom" "1.5rem"
        ]


py_60 : Css.Style
py_60 =
    Css.batch
        [ Css.property "padding-top" "15rem"
        , Css.property "padding-bottom" "15rem"
        ]


py_64 : Css.Style
py_64 =
    Css.batch
        [ Css.property "padding-top" "16rem"
        , Css.property "padding-bottom" "16rem"
        ]


py_7 : Css.Style
py_7 =
    Css.batch
        [ Css.property "padding-top" "1.75rem"
        , Css.property "padding-bottom" "1.75rem"
        ]


py_72 : Css.Style
py_72 =
    Css.batch
        [ Css.property "padding-top" "18rem"
        , Css.property "padding-bottom" "18rem"
        ]


py_8 : Css.Style
py_8 =
    Css.batch
        [ Css.property "padding-top" "2rem"
        , Css.property "padding-bottom" "2rem"
        ]


py_80 : Css.Style
py_80 =
    Css.batch
        [ Css.property "padding-top" "20rem"
        , Css.property "padding-bottom" "20rem"
        ]


py_9 : Css.Style
py_9 =
    Css.batch
        [ Css.property "padding-top" "2.25rem"
        , Css.property "padding-bottom" "2.25rem"
        ]


py_96 : Css.Style
py_96 =
    Css.batch
        [ Css.property "padding-top" "24rem"
        , Css.property "padding-bottom" "24rem"
        ]


py_px : Css.Style
py_px =
    Css.batch
        [ Css.property "padding-top" "1px"
        , Css.property "padding-bottom" "1px"
        ]


relative : Css.Style
relative =
    Css.property "position" "relative"


resize : Css.Style
resize =
    Css.property "resize" "both"


resize_none : Css.Style
resize_none =
    Css.property "resize" "none"


resize_x : Css.Style
resize_x =
    Css.property "resize" "horizontal"


resize_y : Css.Style
resize_y =
    Css.property "resize" "vertical"


right_0 : Css.Style
right_0 =
    Css.property "right" "0px"


right_0_dot_5 : Css.Style
right_0_dot_5 =
    Css.property "right" "0.125rem"


right_1 : Css.Style
right_1 =
    Css.property "right" "0.25rem"


right_10 : Css.Style
right_10 =
    Css.property "right" "2.5rem"


right_11 : Css.Style
right_11 =
    Css.property "right" "2.75rem"


right_12 : Css.Style
right_12 =
    Css.property "right" "3rem"


right_14 : Css.Style
right_14 =
    Css.property "right" "3.5rem"


right_16 : Css.Style
right_16 =
    Css.property "right" "4rem"


right_1_dot_5 : Css.Style
right_1_dot_5 =
    Css.property "right" "0.375rem"


right_1over2 : Css.Style
right_1over2 =
    Css.property "right" "50%"


right_1over3 : Css.Style
right_1over3 =
    Css.property "right" "33.333333%"


right_1over4 : Css.Style
right_1over4 =
    Css.property "right" "25%"


right_2 : Css.Style
right_2 =
    Css.property "right" "0.5rem"


right_20 : Css.Style
right_20 =
    Css.property "right" "5rem"


right_24 : Css.Style
right_24 =
    Css.property "right" "6rem"


right_28 : Css.Style
right_28 =
    Css.property "right" "7rem"


right_2_dot_5 : Css.Style
right_2_dot_5 =
    Css.property "right" "0.625rem"


right_2over3 : Css.Style
right_2over3 =
    Css.property "right" "66.666667%"


right_2over4 : Css.Style
right_2over4 =
    Css.property "right" "50%"


right_3 : Css.Style
right_3 =
    Css.property "right" "0.75rem"


right_32 : Css.Style
right_32 =
    Css.property "right" "8rem"


right_36 : Css.Style
right_36 =
    Css.property "right" "9rem"


right_3_dot_5 : Css.Style
right_3_dot_5 =
    Css.property "right" "0.875rem"


right_3over4 : Css.Style
right_3over4 =
    Css.property "right" "75%"


right_4 : Css.Style
right_4 =
    Css.property "right" "1rem"


right_40 : Css.Style
right_40 =
    Css.property "right" "10rem"


right_44 : Css.Style
right_44 =
    Css.property "right" "11rem"


right_48 : Css.Style
right_48 =
    Css.property "right" "12rem"


right_5 : Css.Style
right_5 =
    Css.property "right" "1.25rem"


right_52 : Css.Style
right_52 =
    Css.property "right" "13rem"


right_56 : Css.Style
right_56 =
    Css.property "right" "14rem"


right_6 : Css.Style
right_6 =
    Css.property "right" "1.5rem"


right_60 : Css.Style
right_60 =
    Css.property "right" "15rem"


right_64 : Css.Style
right_64 =
    Css.property "right" "16rem"


right_7 : Css.Style
right_7 =
    Css.property "right" "1.75rem"


right_72 : Css.Style
right_72 =
    Css.property "right" "18rem"


right_8 : Css.Style
right_8 =
    Css.property "right" "2rem"


right_80 : Css.Style
right_80 =
    Css.property "right" "20rem"


right_9 : Css.Style
right_9 =
    Css.property "right" "2.25rem"


right_96 : Css.Style
right_96 =
    Css.property "right" "24rem"


right_auto : Css.Style
right_auto =
    Css.property "right" "auto"


right_full : Css.Style
right_full =
    Css.property "right" "100%"


right_px : Css.Style
right_px =
    Css.property "right" "1px"


ring : Css.Style
ring =
    Css.batch
        [ Css.property "--tw-ring-offset-shadow" "var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color)"
        , Css.property "--tw-ring-shadow" "var(--tw-ring-inset) 0 0 0 calc(3px + var(--tw-ring-offset-width)) var(--tw-ring-color)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)"
        ]


ring_0 : Css.Style
ring_0 =
    Css.batch
        [ Css.property "--tw-ring-offset-shadow" "var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color)"
        , Css.property "--tw-ring-shadow" "var(--tw-ring-inset) 0 0 0 calc(0px + var(--tw-ring-offset-width)) var(--tw-ring-color)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)"
        ]


ring_1 : Css.Style
ring_1 =
    Css.batch
        [ Css.property "--tw-ring-offset-shadow" "var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color)"
        , Css.property "--tw-ring-shadow" "var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)"
        ]


ring_2 : Css.Style
ring_2 =
    Css.batch
        [ Css.property "--tw-ring-offset-shadow" "var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color)"
        , Css.property "--tw-ring-shadow" "var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)"
        ]


ring_4 : Css.Style
ring_4 =
    Css.batch
        [ Css.property "--tw-ring-offset-shadow" "var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color)"
        , Css.property "--tw-ring-shadow" "var(--tw-ring-inset) 0 0 0 calc(4px + var(--tw-ring-offset-width)) var(--tw-ring-color)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)"
        ]


ring_8 : Css.Style
ring_8 =
    Css.batch
        [ Css.property "--tw-ring-offset-shadow" "var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color)"
        , Css.property "--tw-ring-shadow" "var(--tw-ring-inset) 0 0 0 calc(8px + var(--tw-ring-offset-width)) var(--tw-ring-color)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)"
        ]


ring_black : Css.Style
ring_black =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(0, 0, 0, var(--tw-ring-opacity))"
        ]


ring_blue_100 : Css.Style
ring_blue_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(219, 234, 254, var(--tw-ring-opacity))"
        ]


ring_blue_200 : Css.Style
ring_blue_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(191, 219, 254, var(--tw-ring-opacity))"
        ]


ring_blue_300 : Css.Style
ring_blue_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(147, 197, 253, var(--tw-ring-opacity))"
        ]


ring_blue_400 : Css.Style
ring_blue_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(96, 165, 250, var(--tw-ring-opacity))"
        ]


ring_blue_50 : Css.Style
ring_blue_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(239, 246, 255, var(--tw-ring-opacity))"
        ]


ring_blue_500 : Css.Style
ring_blue_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(59, 130, 246, var(--tw-ring-opacity))"
        ]


ring_blue_600 : Css.Style
ring_blue_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(37, 99, 235, var(--tw-ring-opacity))"
        ]


ring_blue_700 : Css.Style
ring_blue_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(29, 78, 216, var(--tw-ring-opacity))"
        ]


ring_blue_800 : Css.Style
ring_blue_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(30, 64, 175, var(--tw-ring-opacity))"
        ]


ring_blue_900 : Css.Style
ring_blue_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(30, 58, 138, var(--tw-ring-opacity))"
        ]


ring_current : Css.Style
ring_current =
    Css.property "--tw-ring-color" "currentColor"


ring_gray_100 : Css.Style
ring_gray_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(243, 244, 246, var(--tw-ring-opacity))"
        ]


ring_gray_200 : Css.Style
ring_gray_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(229, 231, 235, var(--tw-ring-opacity))"
        ]


ring_gray_300 : Css.Style
ring_gray_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(209, 213, 219, var(--tw-ring-opacity))"
        ]


ring_gray_400 : Css.Style
ring_gray_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(156, 163, 175, var(--tw-ring-opacity))"
        ]


ring_gray_50 : Css.Style
ring_gray_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(249, 250, 251, var(--tw-ring-opacity))"
        ]


ring_gray_500 : Css.Style
ring_gray_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(107, 114, 128, var(--tw-ring-opacity))"
        ]


ring_gray_600 : Css.Style
ring_gray_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(75, 85, 99, var(--tw-ring-opacity))"
        ]


ring_gray_700 : Css.Style
ring_gray_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(55, 65, 81, var(--tw-ring-opacity))"
        ]


ring_gray_800 : Css.Style
ring_gray_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(31, 41, 55, var(--tw-ring-opacity))"
        ]


ring_gray_900 : Css.Style
ring_gray_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(17, 24, 39, var(--tw-ring-opacity))"
        ]


ring_green_100 : Css.Style
ring_green_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(209, 250, 229, var(--tw-ring-opacity))"
        ]


ring_green_200 : Css.Style
ring_green_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(167, 243, 208, var(--tw-ring-opacity))"
        ]


ring_green_300 : Css.Style
ring_green_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(110, 231, 183, var(--tw-ring-opacity))"
        ]


ring_green_400 : Css.Style
ring_green_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(52, 211, 153, var(--tw-ring-opacity))"
        ]


ring_green_50 : Css.Style
ring_green_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(236, 253, 245, var(--tw-ring-opacity))"
        ]


ring_green_500 : Css.Style
ring_green_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(16, 185, 129, var(--tw-ring-opacity))"
        ]


ring_green_600 : Css.Style
ring_green_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(5, 150, 105, var(--tw-ring-opacity))"
        ]


ring_green_700 : Css.Style
ring_green_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(4, 120, 87, var(--tw-ring-opacity))"
        ]


ring_green_800 : Css.Style
ring_green_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(6, 95, 70, var(--tw-ring-opacity))"
        ]


ring_green_900 : Css.Style
ring_green_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(6, 78, 59, var(--tw-ring-opacity))"
        ]


ring_indigo_100 : Css.Style
ring_indigo_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(224, 231, 255, var(--tw-ring-opacity))"
        ]


ring_indigo_200 : Css.Style
ring_indigo_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(199, 210, 254, var(--tw-ring-opacity))"
        ]


ring_indigo_300 : Css.Style
ring_indigo_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(165, 180, 252, var(--tw-ring-opacity))"
        ]


ring_indigo_400 : Css.Style
ring_indigo_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(129, 140, 248, var(--tw-ring-opacity))"
        ]


ring_indigo_50 : Css.Style
ring_indigo_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(238, 242, 255, var(--tw-ring-opacity))"
        ]


ring_indigo_500 : Css.Style
ring_indigo_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(99, 102, 241, var(--tw-ring-opacity))"
        ]


ring_indigo_600 : Css.Style
ring_indigo_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(79, 70, 229, var(--tw-ring-opacity))"
        ]


ring_indigo_700 : Css.Style
ring_indigo_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(67, 56, 202, var(--tw-ring-opacity))"
        ]


ring_indigo_800 : Css.Style
ring_indigo_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(55, 48, 163, var(--tw-ring-opacity))"
        ]


ring_indigo_900 : Css.Style
ring_indigo_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(49, 46, 129, var(--tw-ring-opacity))"
        ]


ring_inset : Css.Style
ring_inset =
    Css.property "--tw-ring-inset" "inset"


ring_offset_0 : Css.Style
ring_offset_0 =
    Css.property "--tw-ring-offset-width" "0px"


ring_offset_1 : Css.Style
ring_offset_1 =
    Css.property "--tw-ring-offset-width" "1px"


ring_offset_2 : Css.Style
ring_offset_2 =
    Css.property "--tw-ring-offset-width" "2px"


ring_offset_4 : Css.Style
ring_offset_4 =
    Css.property "--tw-ring-offset-width" "4px"


ring_offset_8 : Css.Style
ring_offset_8 =
    Css.property "--tw-ring-offset-width" "8px"


ring_offset_black : Css.Style
ring_offset_black =
    Css.property "--tw-ring-offset-color" "#000"


ring_offset_blue_100 : Css.Style
ring_offset_blue_100 =
    Css.property "--tw-ring-offset-color" "#dbeafe"


ring_offset_blue_200 : Css.Style
ring_offset_blue_200 =
    Css.property "--tw-ring-offset-color" "#bfdbfe"


ring_offset_blue_300 : Css.Style
ring_offset_blue_300 =
    Css.property "--tw-ring-offset-color" "#93c5fd"


ring_offset_blue_400 : Css.Style
ring_offset_blue_400 =
    Css.property "--tw-ring-offset-color" "#60a5fa"


ring_offset_blue_50 : Css.Style
ring_offset_blue_50 =
    Css.property "--tw-ring-offset-color" "#eff6ff"


ring_offset_blue_500 : Css.Style
ring_offset_blue_500 =
    Css.property "--tw-ring-offset-color" "#3b82f6"


ring_offset_blue_600 : Css.Style
ring_offset_blue_600 =
    Css.property "--tw-ring-offset-color" "#2563eb"


ring_offset_blue_700 : Css.Style
ring_offset_blue_700 =
    Css.property "--tw-ring-offset-color" "#1d4ed8"


ring_offset_blue_800 : Css.Style
ring_offset_blue_800 =
    Css.property "--tw-ring-offset-color" "#1e40af"


ring_offset_blue_900 : Css.Style
ring_offset_blue_900 =
    Css.property "--tw-ring-offset-color" "#1e3a8a"


ring_offset_current : Css.Style
ring_offset_current =
    Css.property "--tw-ring-offset-color" "currentColor"


ring_offset_gray_100 : Css.Style
ring_offset_gray_100 =
    Css.property "--tw-ring-offset-color" "#f3f4f6"


ring_offset_gray_200 : Css.Style
ring_offset_gray_200 =
    Css.property "--tw-ring-offset-color" "#e5e7eb"


ring_offset_gray_300 : Css.Style
ring_offset_gray_300 =
    Css.property "--tw-ring-offset-color" "#d1d5db"


ring_offset_gray_400 : Css.Style
ring_offset_gray_400 =
    Css.property "--tw-ring-offset-color" "#9ca3af"


ring_offset_gray_50 : Css.Style
ring_offset_gray_50 =
    Css.property "--tw-ring-offset-color" "#f9fafb"


ring_offset_gray_500 : Css.Style
ring_offset_gray_500 =
    Css.property "--tw-ring-offset-color" "#6b7280"


ring_offset_gray_600 : Css.Style
ring_offset_gray_600 =
    Css.property "--tw-ring-offset-color" "#4b5563"


ring_offset_gray_700 : Css.Style
ring_offset_gray_700 =
    Css.property "--tw-ring-offset-color" "#374151"


ring_offset_gray_800 : Css.Style
ring_offset_gray_800 =
    Css.property "--tw-ring-offset-color" "#1f2937"


ring_offset_gray_900 : Css.Style
ring_offset_gray_900 =
    Css.property "--tw-ring-offset-color" "#111827"


ring_offset_green_100 : Css.Style
ring_offset_green_100 =
    Css.property "--tw-ring-offset-color" "#d1fae5"


ring_offset_green_200 : Css.Style
ring_offset_green_200 =
    Css.property "--tw-ring-offset-color" "#a7f3d0"


ring_offset_green_300 : Css.Style
ring_offset_green_300 =
    Css.property "--tw-ring-offset-color" "#6ee7b7"


ring_offset_green_400 : Css.Style
ring_offset_green_400 =
    Css.property "--tw-ring-offset-color" "#34d399"


ring_offset_green_50 : Css.Style
ring_offset_green_50 =
    Css.property "--tw-ring-offset-color" "#ecfdf5"


ring_offset_green_500 : Css.Style
ring_offset_green_500 =
    Css.property "--tw-ring-offset-color" "#10b981"


ring_offset_green_600 : Css.Style
ring_offset_green_600 =
    Css.property "--tw-ring-offset-color" "#059669"


ring_offset_green_700 : Css.Style
ring_offset_green_700 =
    Css.property "--tw-ring-offset-color" "#047857"


ring_offset_green_800 : Css.Style
ring_offset_green_800 =
    Css.property "--tw-ring-offset-color" "#065f46"


ring_offset_green_900 : Css.Style
ring_offset_green_900 =
    Css.property "--tw-ring-offset-color" "#064e3b"


ring_offset_indigo_100 : Css.Style
ring_offset_indigo_100 =
    Css.property "--tw-ring-offset-color" "#e0e7ff"


ring_offset_indigo_200 : Css.Style
ring_offset_indigo_200 =
    Css.property "--tw-ring-offset-color" "#c7d2fe"


ring_offset_indigo_300 : Css.Style
ring_offset_indigo_300 =
    Css.property "--tw-ring-offset-color" "#a5b4fc"


ring_offset_indigo_400 : Css.Style
ring_offset_indigo_400 =
    Css.property "--tw-ring-offset-color" "#818cf8"


ring_offset_indigo_50 : Css.Style
ring_offset_indigo_50 =
    Css.property "--tw-ring-offset-color" "#eef2ff"


ring_offset_indigo_500 : Css.Style
ring_offset_indigo_500 =
    Css.property "--tw-ring-offset-color" "#6366f1"


ring_offset_indigo_600 : Css.Style
ring_offset_indigo_600 =
    Css.property "--tw-ring-offset-color" "#4f46e5"


ring_offset_indigo_700 : Css.Style
ring_offset_indigo_700 =
    Css.property "--tw-ring-offset-color" "#4338ca"


ring_offset_indigo_800 : Css.Style
ring_offset_indigo_800 =
    Css.property "--tw-ring-offset-color" "#3730a3"


ring_offset_indigo_900 : Css.Style
ring_offset_indigo_900 =
    Css.property "--tw-ring-offset-color" "#312e81"


ring_offset_pink_100 : Css.Style
ring_offset_pink_100 =
    Css.property "--tw-ring-offset-color" "#fce7f3"


ring_offset_pink_200 : Css.Style
ring_offset_pink_200 =
    Css.property "--tw-ring-offset-color" "#fbcfe8"


ring_offset_pink_300 : Css.Style
ring_offset_pink_300 =
    Css.property "--tw-ring-offset-color" "#f9a8d4"


ring_offset_pink_400 : Css.Style
ring_offset_pink_400 =
    Css.property "--tw-ring-offset-color" "#f472b6"


ring_offset_pink_50 : Css.Style
ring_offset_pink_50 =
    Css.property "--tw-ring-offset-color" "#fdf2f8"


ring_offset_pink_500 : Css.Style
ring_offset_pink_500 =
    Css.property "--tw-ring-offset-color" "#ec4899"


ring_offset_pink_600 : Css.Style
ring_offset_pink_600 =
    Css.property "--tw-ring-offset-color" "#db2777"


ring_offset_pink_700 : Css.Style
ring_offset_pink_700 =
    Css.property "--tw-ring-offset-color" "#be185d"


ring_offset_pink_800 : Css.Style
ring_offset_pink_800 =
    Css.property "--tw-ring-offset-color" "#9d174d"


ring_offset_pink_900 : Css.Style
ring_offset_pink_900 =
    Css.property "--tw-ring-offset-color" "#831843"


ring_offset_purple_100 : Css.Style
ring_offset_purple_100 =
    Css.property "--tw-ring-offset-color" "#ede9fe"


ring_offset_purple_200 : Css.Style
ring_offset_purple_200 =
    Css.property "--tw-ring-offset-color" "#ddd6fe"


ring_offset_purple_300 : Css.Style
ring_offset_purple_300 =
    Css.property "--tw-ring-offset-color" "#c4b5fd"


ring_offset_purple_400 : Css.Style
ring_offset_purple_400 =
    Css.property "--tw-ring-offset-color" "#a78bfa"


ring_offset_purple_50 : Css.Style
ring_offset_purple_50 =
    Css.property "--tw-ring-offset-color" "#f5f3ff"


ring_offset_purple_500 : Css.Style
ring_offset_purple_500 =
    Css.property "--tw-ring-offset-color" "#8b5cf6"


ring_offset_purple_600 : Css.Style
ring_offset_purple_600 =
    Css.property "--tw-ring-offset-color" "#7c3aed"


ring_offset_purple_700 : Css.Style
ring_offset_purple_700 =
    Css.property "--tw-ring-offset-color" "#6d28d9"


ring_offset_purple_800 : Css.Style
ring_offset_purple_800 =
    Css.property "--tw-ring-offset-color" "#5b21b6"


ring_offset_purple_900 : Css.Style
ring_offset_purple_900 =
    Css.property "--tw-ring-offset-color" "#4c1d95"


ring_offset_red_100 : Css.Style
ring_offset_red_100 =
    Css.property "--tw-ring-offset-color" "#fee2e2"


ring_offset_red_200 : Css.Style
ring_offset_red_200 =
    Css.property "--tw-ring-offset-color" "#fecaca"


ring_offset_red_300 : Css.Style
ring_offset_red_300 =
    Css.property "--tw-ring-offset-color" "#fca5a5"


ring_offset_red_400 : Css.Style
ring_offset_red_400 =
    Css.property "--tw-ring-offset-color" "#f87171"


ring_offset_red_50 : Css.Style
ring_offset_red_50 =
    Css.property "--tw-ring-offset-color" "#fef2f2"


ring_offset_red_500 : Css.Style
ring_offset_red_500 =
    Css.property "--tw-ring-offset-color" "#ef4444"


ring_offset_red_600 : Css.Style
ring_offset_red_600 =
    Css.property "--tw-ring-offset-color" "#dc2626"


ring_offset_red_700 : Css.Style
ring_offset_red_700 =
    Css.property "--tw-ring-offset-color" "#b91c1c"


ring_offset_red_800 : Css.Style
ring_offset_red_800 =
    Css.property "--tw-ring-offset-color" "#991b1b"


ring_offset_red_900 : Css.Style
ring_offset_red_900 =
    Css.property "--tw-ring-offset-color" "#7f1d1d"


ring_offset_transparent : Css.Style
ring_offset_transparent =
    Css.property "--tw-ring-offset-color" "transparent"


ring_offset_white : Css.Style
ring_offset_white =
    Css.property "--tw-ring-offset-color" "#fff"


ring_offset_yellow_100 : Css.Style
ring_offset_yellow_100 =
    Css.property "--tw-ring-offset-color" "#fef3c7"


ring_offset_yellow_200 : Css.Style
ring_offset_yellow_200 =
    Css.property "--tw-ring-offset-color" "#fde68a"


ring_offset_yellow_300 : Css.Style
ring_offset_yellow_300 =
    Css.property "--tw-ring-offset-color" "#fcd34d"


ring_offset_yellow_400 : Css.Style
ring_offset_yellow_400 =
    Css.property "--tw-ring-offset-color" "#fbbf24"


ring_offset_yellow_50 : Css.Style
ring_offset_yellow_50 =
    Css.property "--tw-ring-offset-color" "#fffbeb"


ring_offset_yellow_500 : Css.Style
ring_offset_yellow_500 =
    Css.property "--tw-ring-offset-color" "#f59e0b"


ring_offset_yellow_600 : Css.Style
ring_offset_yellow_600 =
    Css.property "--tw-ring-offset-color" "#d97706"


ring_offset_yellow_700 : Css.Style
ring_offset_yellow_700 =
    Css.property "--tw-ring-offset-color" "#b45309"


ring_offset_yellow_800 : Css.Style
ring_offset_yellow_800 =
    Css.property "--tw-ring-offset-color" "#92400e"


ring_offset_yellow_900 : Css.Style
ring_offset_yellow_900 =
    Css.property "--tw-ring-offset-color" "#78350f"


ring_opacity_0 : Css.Style
ring_opacity_0 =
    Css.property "--tw-ring-opacity" "0"


ring_opacity_10 : Css.Style
ring_opacity_10 =
    Css.property "--tw-ring-opacity" "0.1"


ring_opacity_100 : Css.Style
ring_opacity_100 =
    Css.property "--tw-ring-opacity" "1"


ring_opacity_20 : Css.Style
ring_opacity_20 =
    Css.property "--tw-ring-opacity" "0.2"


ring_opacity_25 : Css.Style
ring_opacity_25 =
    Css.property "--tw-ring-opacity" "0.25"


ring_opacity_30 : Css.Style
ring_opacity_30 =
    Css.property "--tw-ring-opacity" "0.3"


ring_opacity_40 : Css.Style
ring_opacity_40 =
    Css.property "--tw-ring-opacity" "0.4"


ring_opacity_5 : Css.Style
ring_opacity_5 =
    Css.property "--tw-ring-opacity" "0.05"


ring_opacity_50 : Css.Style
ring_opacity_50 =
    Css.property "--tw-ring-opacity" "0.5"


ring_opacity_60 : Css.Style
ring_opacity_60 =
    Css.property "--tw-ring-opacity" "0.6"


ring_opacity_70 : Css.Style
ring_opacity_70 =
    Css.property "--tw-ring-opacity" "0.7"


ring_opacity_75 : Css.Style
ring_opacity_75 =
    Css.property "--tw-ring-opacity" "0.75"


ring_opacity_80 : Css.Style
ring_opacity_80 =
    Css.property "--tw-ring-opacity" "0.8"


ring_opacity_90 : Css.Style
ring_opacity_90 =
    Css.property "--tw-ring-opacity" "0.9"


ring_opacity_95 : Css.Style
ring_opacity_95 =
    Css.property "--tw-ring-opacity" "0.95"


ring_pink_100 : Css.Style
ring_pink_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(252, 231, 243, var(--tw-ring-opacity))"
        ]


ring_pink_200 : Css.Style
ring_pink_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(251, 207, 232, var(--tw-ring-opacity))"
        ]


ring_pink_300 : Css.Style
ring_pink_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(249, 168, 212, var(--tw-ring-opacity))"
        ]


ring_pink_400 : Css.Style
ring_pink_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(244, 114, 182, var(--tw-ring-opacity))"
        ]


ring_pink_50 : Css.Style
ring_pink_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(253, 242, 248, var(--tw-ring-opacity))"
        ]


ring_pink_500 : Css.Style
ring_pink_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(236, 72, 153, var(--tw-ring-opacity))"
        ]


ring_pink_600 : Css.Style
ring_pink_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(219, 39, 119, var(--tw-ring-opacity))"
        ]


ring_pink_700 : Css.Style
ring_pink_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(190, 24, 93, var(--tw-ring-opacity))"
        ]


ring_pink_800 : Css.Style
ring_pink_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(157, 23, 77, var(--tw-ring-opacity))"
        ]


ring_pink_900 : Css.Style
ring_pink_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(131, 24, 67, var(--tw-ring-opacity))"
        ]


ring_purple_100 : Css.Style
ring_purple_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(237, 233, 254, var(--tw-ring-opacity))"
        ]


ring_purple_200 : Css.Style
ring_purple_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(221, 214, 254, var(--tw-ring-opacity))"
        ]


ring_purple_300 : Css.Style
ring_purple_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(196, 181, 253, var(--tw-ring-opacity))"
        ]


ring_purple_400 : Css.Style
ring_purple_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(167, 139, 250, var(--tw-ring-opacity))"
        ]


ring_purple_50 : Css.Style
ring_purple_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(245, 243, 255, var(--tw-ring-opacity))"
        ]


ring_purple_500 : Css.Style
ring_purple_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(139, 92, 246, var(--tw-ring-opacity))"
        ]


ring_purple_600 : Css.Style
ring_purple_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(124, 58, 237, var(--tw-ring-opacity))"
        ]


ring_purple_700 : Css.Style
ring_purple_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(109, 40, 217, var(--tw-ring-opacity))"
        ]


ring_purple_800 : Css.Style
ring_purple_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(91, 33, 182, var(--tw-ring-opacity))"
        ]


ring_purple_900 : Css.Style
ring_purple_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(76, 29, 149, var(--tw-ring-opacity))"
        ]


ring_red_100 : Css.Style
ring_red_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(254, 226, 226, var(--tw-ring-opacity))"
        ]


ring_red_200 : Css.Style
ring_red_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(254, 202, 202, var(--tw-ring-opacity))"
        ]


ring_red_300 : Css.Style
ring_red_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(252, 165, 165, var(--tw-ring-opacity))"
        ]


ring_red_400 : Css.Style
ring_red_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(248, 113, 113, var(--tw-ring-opacity))"
        ]


ring_red_50 : Css.Style
ring_red_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(254, 242, 242, var(--tw-ring-opacity))"
        ]


ring_red_500 : Css.Style
ring_red_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(239, 68, 68, var(--tw-ring-opacity))"
        ]


ring_red_600 : Css.Style
ring_red_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(220, 38, 38, var(--tw-ring-opacity))"
        ]


ring_red_700 : Css.Style
ring_red_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(185, 28, 28, var(--tw-ring-opacity))"
        ]


ring_red_800 : Css.Style
ring_red_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(153, 27, 27, var(--tw-ring-opacity))"
        ]


ring_red_900 : Css.Style
ring_red_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(127, 29, 29, var(--tw-ring-opacity))"
        ]


ring_transparent : Css.Style
ring_transparent =
    Css.property "--tw-ring-color" "transparent"


ring_white : Css.Style
ring_white =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(255, 255, 255, var(--tw-ring-opacity))"
        ]


ring_yellow_100 : Css.Style
ring_yellow_100 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(254, 243, 199, var(--tw-ring-opacity))"
        ]


ring_yellow_200 : Css.Style
ring_yellow_200 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(253, 230, 138, var(--tw-ring-opacity))"
        ]


ring_yellow_300 : Css.Style
ring_yellow_300 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(252, 211, 77, var(--tw-ring-opacity))"
        ]


ring_yellow_400 : Css.Style
ring_yellow_400 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(251, 191, 36, var(--tw-ring-opacity))"
        ]


ring_yellow_50 : Css.Style
ring_yellow_50 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(255, 251, 235, var(--tw-ring-opacity))"
        ]


ring_yellow_500 : Css.Style
ring_yellow_500 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(245, 158, 11, var(--tw-ring-opacity))"
        ]


ring_yellow_600 : Css.Style
ring_yellow_600 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(217, 119, 6, var(--tw-ring-opacity))"
        ]


ring_yellow_700 : Css.Style
ring_yellow_700 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(180, 83, 9, var(--tw-ring-opacity))"
        ]


ring_yellow_800 : Css.Style
ring_yellow_800 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(146, 64, 14, var(--tw-ring-opacity))"
        ]


ring_yellow_900 : Css.Style
ring_yellow_900 =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" "rgba(120, 53, 15, var(--tw-ring-opacity))"
        ]


rotate_0 : Css.Style
rotate_0 =
    Css.property "--tw-rotate" "0deg"


rotate_1 : Css.Style
rotate_1 =
    Css.property "--tw-rotate" "1deg"


rotate_12 : Css.Style
rotate_12 =
    Css.property "--tw-rotate" "12deg"


rotate_180 : Css.Style
rotate_180 =
    Css.property "--tw-rotate" "180deg"


rotate_2 : Css.Style
rotate_2 =
    Css.property "--tw-rotate" "2deg"


rotate_3 : Css.Style
rotate_3 =
    Css.property "--tw-rotate" "3deg"


rotate_45 : Css.Style
rotate_45 =
    Css.property "--tw-rotate" "45deg"


rotate_6 : Css.Style
rotate_6 =
    Css.property "--tw-rotate" "6deg"


rotate_90 : Css.Style
rotate_90 =
    Css.property "--tw-rotate" "90deg"


rounded : Css.Style
rounded =
    Css.property "border-radius" "0.25rem"


rounded_2xl : Css.Style
rounded_2xl =
    Css.property "border-radius" "1rem"


rounded_3xl : Css.Style
rounded_3xl =
    Css.property "border-radius" "1.5rem"


rounded_b : Css.Style
rounded_b =
    Css.batch
        [ Css.property "border-bottom-right-radius" "0.25rem"
        , Css.property "border-bottom-left-radius" "0.25rem"
        ]


rounded_b_2xl : Css.Style
rounded_b_2xl =
    Css.batch
        [ Css.property "border-bottom-right-radius" "1rem"
        , Css.property "border-bottom-left-radius" "1rem"
        ]


rounded_b_3xl : Css.Style
rounded_b_3xl =
    Css.batch
        [ Css.property "border-bottom-right-radius" "1.5rem"
        , Css.property "border-bottom-left-radius" "1.5rem"
        ]


rounded_b_full : Css.Style
rounded_b_full =
    Css.batch
        [ Css.property "border-bottom-right-radius" "9999px"
        , Css.property "border-bottom-left-radius" "9999px"
        ]


rounded_b_lg : Css.Style
rounded_b_lg =
    Css.batch
        [ Css.property "border-bottom-right-radius" "0.5rem"
        , Css.property "border-bottom-left-radius" "0.5rem"
        ]


rounded_b_md : Css.Style
rounded_b_md =
    Css.batch
        [ Css.property "border-bottom-right-radius" "0.375rem"
        , Css.property "border-bottom-left-radius" "0.375rem"
        ]


rounded_b_none : Css.Style
rounded_b_none =
    Css.batch
        [ Css.property "border-bottom-right-radius" "0px"
        , Css.property "border-bottom-left-radius" "0px"
        ]


rounded_b_sm : Css.Style
rounded_b_sm =
    Css.batch
        [ Css.property "border-bottom-right-radius" "0.125rem"
        , Css.property "border-bottom-left-radius" "0.125rem"
        ]


rounded_b_xl : Css.Style
rounded_b_xl =
    Css.batch
        [ Css.property "border-bottom-right-radius" "0.75rem"
        , Css.property "border-bottom-left-radius" "0.75rem"
        ]


rounded_bl : Css.Style
rounded_bl =
    Css.property "border-bottom-left-radius" "0.25rem"


rounded_bl_2xl : Css.Style
rounded_bl_2xl =
    Css.property "border-bottom-left-radius" "1rem"


rounded_bl_3xl : Css.Style
rounded_bl_3xl =
    Css.property "border-bottom-left-radius" "1.5rem"


rounded_bl_full : Css.Style
rounded_bl_full =
    Css.property "border-bottom-left-radius" "9999px"


rounded_bl_lg : Css.Style
rounded_bl_lg =
    Css.property "border-bottom-left-radius" "0.5rem"


rounded_bl_md : Css.Style
rounded_bl_md =
    Css.property "border-bottom-left-radius" "0.375rem"


rounded_bl_none : Css.Style
rounded_bl_none =
    Css.property "border-bottom-left-radius" "0px"


rounded_bl_sm : Css.Style
rounded_bl_sm =
    Css.property "border-bottom-left-radius" "0.125rem"


rounded_bl_xl : Css.Style
rounded_bl_xl =
    Css.property "border-bottom-left-radius" "0.75rem"


rounded_br : Css.Style
rounded_br =
    Css.property "border-bottom-right-radius" "0.25rem"


rounded_br_2xl : Css.Style
rounded_br_2xl =
    Css.property "border-bottom-right-radius" "1rem"


rounded_br_3xl : Css.Style
rounded_br_3xl =
    Css.property "border-bottom-right-radius" "1.5rem"


rounded_br_full : Css.Style
rounded_br_full =
    Css.property "border-bottom-right-radius" "9999px"


rounded_br_lg : Css.Style
rounded_br_lg =
    Css.property "border-bottom-right-radius" "0.5rem"


rounded_br_md : Css.Style
rounded_br_md =
    Css.property "border-bottom-right-radius" "0.375rem"


rounded_br_none : Css.Style
rounded_br_none =
    Css.property "border-bottom-right-radius" "0px"


rounded_br_sm : Css.Style
rounded_br_sm =
    Css.property "border-bottom-right-radius" "0.125rem"


rounded_br_xl : Css.Style
rounded_br_xl =
    Css.property "border-bottom-right-radius" "0.75rem"


rounded_full : Css.Style
rounded_full =
    Css.property "border-radius" "9999px"


rounded_l : Css.Style
rounded_l =
    Css.batch
        [ Css.property "border-top-left-radius" "0.25rem"
        , Css.property "border-bottom-left-radius" "0.25rem"
        ]


rounded_l_2xl : Css.Style
rounded_l_2xl =
    Css.batch
        [ Css.property "border-top-left-radius" "1rem"
        , Css.property "border-bottom-left-radius" "1rem"
        ]


rounded_l_3xl : Css.Style
rounded_l_3xl =
    Css.batch
        [ Css.property "border-top-left-radius" "1.5rem"
        , Css.property "border-bottom-left-radius" "1.5rem"
        ]


rounded_l_full : Css.Style
rounded_l_full =
    Css.batch
        [ Css.property "border-top-left-radius" "9999px"
        , Css.property "border-bottom-left-radius" "9999px"
        ]


rounded_l_lg : Css.Style
rounded_l_lg =
    Css.batch
        [ Css.property "border-top-left-radius" "0.5rem"
        , Css.property "border-bottom-left-radius" "0.5rem"
        ]


rounded_l_md : Css.Style
rounded_l_md =
    Css.batch
        [ Css.property "border-top-left-radius" "0.375rem"
        , Css.property "border-bottom-left-radius" "0.375rem"
        ]


rounded_l_none : Css.Style
rounded_l_none =
    Css.batch
        [ Css.property "border-top-left-radius" "0px"
        , Css.property "border-bottom-left-radius" "0px"
        ]


rounded_l_sm : Css.Style
rounded_l_sm =
    Css.batch
        [ Css.property "border-top-left-radius" "0.125rem"
        , Css.property "border-bottom-left-radius" "0.125rem"
        ]


rounded_l_xl : Css.Style
rounded_l_xl =
    Css.batch
        [ Css.property "border-top-left-radius" "0.75rem"
        , Css.property "border-bottom-left-radius" "0.75rem"
        ]


rounded_lg : Css.Style
rounded_lg =
    Css.property "border-radius" "0.5rem"


rounded_md : Css.Style
rounded_md =
    Css.property "border-radius" "0.375rem"


rounded_none : Css.Style
rounded_none =
    Css.property "border-radius" "0px"


rounded_r : Css.Style
rounded_r =
    Css.batch
        [ Css.property "border-top-right-radius" "0.25rem"
        , Css.property "border-bottom-right-radius" "0.25rem"
        ]


rounded_r_2xl : Css.Style
rounded_r_2xl =
    Css.batch
        [ Css.property "border-top-right-radius" "1rem"
        , Css.property "border-bottom-right-radius" "1rem"
        ]


rounded_r_3xl : Css.Style
rounded_r_3xl =
    Css.batch
        [ Css.property "border-top-right-radius" "1.5rem"
        , Css.property "border-bottom-right-radius" "1.5rem"
        ]


rounded_r_full : Css.Style
rounded_r_full =
    Css.batch
        [ Css.property "border-top-right-radius" "9999px"
        , Css.property "border-bottom-right-radius" "9999px"
        ]


rounded_r_lg : Css.Style
rounded_r_lg =
    Css.batch
        [ Css.property "border-top-right-radius" "0.5rem"
        , Css.property "border-bottom-right-radius" "0.5rem"
        ]


rounded_r_md : Css.Style
rounded_r_md =
    Css.batch
        [ Css.property "border-top-right-radius" "0.375rem"
        , Css.property "border-bottom-right-radius" "0.375rem"
        ]


rounded_r_none : Css.Style
rounded_r_none =
    Css.batch
        [ Css.property "border-top-right-radius" "0px"
        , Css.property "border-bottom-right-radius" "0px"
        ]


rounded_r_sm : Css.Style
rounded_r_sm =
    Css.batch
        [ Css.property "border-top-right-radius" "0.125rem"
        , Css.property "border-bottom-right-radius" "0.125rem"
        ]


rounded_r_xl : Css.Style
rounded_r_xl =
    Css.batch
        [ Css.property "border-top-right-radius" "0.75rem"
        , Css.property "border-bottom-right-radius" "0.75rem"
        ]


rounded_sm : Css.Style
rounded_sm =
    Css.property "border-radius" "0.125rem"


rounded_t : Css.Style
rounded_t =
    Css.batch
        [ Css.property "border-top-left-radius" "0.25rem"
        , Css.property "border-top-right-radius" "0.25rem"
        ]


rounded_t_2xl : Css.Style
rounded_t_2xl =
    Css.batch
        [ Css.property "border-top-left-radius" "1rem"
        , Css.property "border-top-right-radius" "1rem"
        ]


rounded_t_3xl : Css.Style
rounded_t_3xl =
    Css.batch
        [ Css.property "border-top-left-radius" "1.5rem"
        , Css.property "border-top-right-radius" "1.5rem"
        ]


rounded_t_full : Css.Style
rounded_t_full =
    Css.batch
        [ Css.property "border-top-left-radius" "9999px"
        , Css.property "border-top-right-radius" "9999px"
        ]


rounded_t_lg : Css.Style
rounded_t_lg =
    Css.batch
        [ Css.property "border-top-left-radius" "0.5rem"
        , Css.property "border-top-right-radius" "0.5rem"
        ]


rounded_t_md : Css.Style
rounded_t_md =
    Css.batch
        [ Css.property "border-top-left-radius" "0.375rem"
        , Css.property "border-top-right-radius" "0.375rem"
        ]


rounded_t_none : Css.Style
rounded_t_none =
    Css.batch
        [ Css.property "border-top-left-radius" "0px"
        , Css.property "border-top-right-radius" "0px"
        ]


rounded_t_sm : Css.Style
rounded_t_sm =
    Css.batch
        [ Css.property "border-top-left-radius" "0.125rem"
        , Css.property "border-top-right-radius" "0.125rem"
        ]


rounded_t_xl : Css.Style
rounded_t_xl =
    Css.batch
        [ Css.property "border-top-left-radius" "0.75rem"
        , Css.property "border-top-right-radius" "0.75rem"
        ]


rounded_tl : Css.Style
rounded_tl =
    Css.property "border-top-left-radius" "0.25rem"


rounded_tl_2xl : Css.Style
rounded_tl_2xl =
    Css.property "border-top-left-radius" "1rem"


rounded_tl_3xl : Css.Style
rounded_tl_3xl =
    Css.property "border-top-left-radius" "1.5rem"


rounded_tl_full : Css.Style
rounded_tl_full =
    Css.property "border-top-left-radius" "9999px"


rounded_tl_lg : Css.Style
rounded_tl_lg =
    Css.property "border-top-left-radius" "0.5rem"


rounded_tl_md : Css.Style
rounded_tl_md =
    Css.property "border-top-left-radius" "0.375rem"


rounded_tl_none : Css.Style
rounded_tl_none =
    Css.property "border-top-left-radius" "0px"


rounded_tl_sm : Css.Style
rounded_tl_sm =
    Css.property "border-top-left-radius" "0.125rem"


rounded_tl_xl : Css.Style
rounded_tl_xl =
    Css.property "border-top-left-radius" "0.75rem"


rounded_tr : Css.Style
rounded_tr =
    Css.property "border-top-right-radius" "0.25rem"


rounded_tr_2xl : Css.Style
rounded_tr_2xl =
    Css.property "border-top-right-radius" "1rem"


rounded_tr_3xl : Css.Style
rounded_tr_3xl =
    Css.property "border-top-right-radius" "1.5rem"


rounded_tr_full : Css.Style
rounded_tr_full =
    Css.property "border-top-right-radius" "9999px"


rounded_tr_lg : Css.Style
rounded_tr_lg =
    Css.property "border-top-right-radius" "0.5rem"


rounded_tr_md : Css.Style
rounded_tr_md =
    Css.property "border-top-right-radius" "0.375rem"


rounded_tr_none : Css.Style
rounded_tr_none =
    Css.property "border-top-right-radius" "0px"


rounded_tr_sm : Css.Style
rounded_tr_sm =
    Css.property "border-top-right-radius" "0.125rem"


rounded_tr_xl : Css.Style
rounded_tr_xl =
    Css.property "border-top-right-radius" "0.75rem"


rounded_xl : Css.Style
rounded_xl =
    Css.property "border-radius" "0.75rem"


row_auto : Css.Style
row_auto =
    Css.property "grid-row" "auto"


row_end_1 : Css.Style
row_end_1 =
    Css.property "grid-row-end" "1"


row_end_2 : Css.Style
row_end_2 =
    Css.property "grid-row-end" "2"


row_end_3 : Css.Style
row_end_3 =
    Css.property "grid-row-end" "3"


row_end_4 : Css.Style
row_end_4 =
    Css.property "grid-row-end" "4"


row_end_5 : Css.Style
row_end_5 =
    Css.property "grid-row-end" "5"


row_end_6 : Css.Style
row_end_6 =
    Css.property "grid-row-end" "6"


row_end_7 : Css.Style
row_end_7 =
    Css.property "grid-row-end" "7"


row_end_auto : Css.Style
row_end_auto =
    Css.property "grid-row-end" "auto"


row_span_1 : Css.Style
row_span_1 =
    Css.property "grid-row" "span 1 / span 1"


row_span_2 : Css.Style
row_span_2 =
    Css.property "grid-row" "span 2 / span 2"


row_span_3 : Css.Style
row_span_3 =
    Css.property "grid-row" "span 3 / span 3"


row_span_4 : Css.Style
row_span_4 =
    Css.property "grid-row" "span 4 / span 4"


row_span_5 : Css.Style
row_span_5 =
    Css.property "grid-row" "span 5 / span 5"


row_span_6 : Css.Style
row_span_6 =
    Css.property "grid-row" "span 6 / span 6"


row_span_full : Css.Style
row_span_full =
    Css.property "grid-row" "1 / -1"


row_start_1 : Css.Style
row_start_1 =
    Css.property "grid-row-start" "1"


row_start_2 : Css.Style
row_start_2 =
    Css.property "grid-row-start" "2"


row_start_3 : Css.Style
row_start_3 =
    Css.property "grid-row-start" "3"


row_start_4 : Css.Style
row_start_4 =
    Css.property "grid-row-start" "4"


row_start_5 : Css.Style
row_start_5 =
    Css.property "grid-row-start" "5"


row_start_6 : Css.Style
row_start_6 =
    Css.property "grid-row-start" "6"


row_start_7 : Css.Style
row_start_7 =
    Css.property "grid-row-start" "7"


row_start_auto : Css.Style
row_start_auto =
    Css.property "grid-row-start" "auto"


saturate_0 : Css.Style
saturate_0 =
    Css.property "--tw-saturate" "saturate(0)"


saturate_100 : Css.Style
saturate_100 =
    Css.property "--tw-saturate" "saturate(1)"


saturate_150 : Css.Style
saturate_150 =
    Css.property "--tw-saturate" "saturate(1.5)"


saturate_200 : Css.Style
saturate_200 =
    Css.property "--tw-saturate" "saturate(2)"


saturate_50 : Css.Style
saturate_50 =
    Css.property "--tw-saturate" "saturate(.5)"


scale_0 : Css.Style
scale_0 =
    Css.batch
        [ Css.property "--tw-scale-x" "0"
        , Css.property "--tw-scale-y" "0"
        ]


scale_100 : Css.Style
scale_100 =
    Css.batch
        [ Css.property "--tw-scale-x" "1"
        , Css.property "--tw-scale-y" "1"
        ]


scale_105 : Css.Style
scale_105 =
    Css.batch
        [ Css.property "--tw-scale-x" "1.05"
        , Css.property "--tw-scale-y" "1.05"
        ]


scale_110 : Css.Style
scale_110 =
    Css.batch
        [ Css.property "--tw-scale-x" "1.1"
        , Css.property "--tw-scale-y" "1.1"
        ]


scale_125 : Css.Style
scale_125 =
    Css.batch
        [ Css.property "--tw-scale-x" "1.25"
        , Css.property "--tw-scale-y" "1.25"
        ]


scale_150 : Css.Style
scale_150 =
    Css.batch
        [ Css.property "--tw-scale-x" "1.5"
        , Css.property "--tw-scale-y" "1.5"
        ]


scale_50 : Css.Style
scale_50 =
    Css.batch
        [ Css.property "--tw-scale-x" ".5"
        , Css.property "--tw-scale-y" ".5"
        ]


scale_75 : Css.Style
scale_75 =
    Css.batch
        [ Css.property "--tw-scale-x" ".75"
        , Css.property "--tw-scale-y" ".75"
        ]


scale_90 : Css.Style
scale_90 =
    Css.batch
        [ Css.property "--tw-scale-x" ".9"
        , Css.property "--tw-scale-y" ".9"
        ]


scale_95 : Css.Style
scale_95 =
    Css.batch
        [ Css.property "--tw-scale-x" ".95"
        , Css.property "--tw-scale-y" ".95"
        ]


scale_x_0 : Css.Style
scale_x_0 =
    Css.property "--tw-scale-x" "0"


scale_x_100 : Css.Style
scale_x_100 =
    Css.property "--tw-scale-x" "1"


scale_x_105 : Css.Style
scale_x_105 =
    Css.property "--tw-scale-x" "1.05"


scale_x_110 : Css.Style
scale_x_110 =
    Css.property "--tw-scale-x" "1.1"


scale_x_125 : Css.Style
scale_x_125 =
    Css.property "--tw-scale-x" "1.25"


scale_x_150 : Css.Style
scale_x_150 =
    Css.property "--tw-scale-x" "1.5"


scale_x_50 : Css.Style
scale_x_50 =
    Css.property "--tw-scale-x" ".5"


scale_x_75 : Css.Style
scale_x_75 =
    Css.property "--tw-scale-x" ".75"


scale_x_90 : Css.Style
scale_x_90 =
    Css.property "--tw-scale-x" ".9"


scale_x_95 : Css.Style
scale_x_95 =
    Css.property "--tw-scale-x" ".95"


scale_y_0 : Css.Style
scale_y_0 =
    Css.property "--tw-scale-y" "0"


scale_y_100 : Css.Style
scale_y_100 =
    Css.property "--tw-scale-y" "1"


scale_y_105 : Css.Style
scale_y_105 =
    Css.property "--tw-scale-y" "1.05"


scale_y_110 : Css.Style
scale_y_110 =
    Css.property "--tw-scale-y" "1.1"


scale_y_125 : Css.Style
scale_y_125 =
    Css.property "--tw-scale-y" "1.25"


scale_y_150 : Css.Style
scale_y_150 =
    Css.property "--tw-scale-y" "1.5"


scale_y_50 : Css.Style
scale_y_50 =
    Css.property "--tw-scale-y" ".5"


scale_y_75 : Css.Style
scale_y_75 =
    Css.property "--tw-scale-y" ".75"


scale_y_90 : Css.Style
scale_y_90 =
    Css.property "--tw-scale-y" ".9"


scale_y_95 : Css.Style
scale_y_95 =
    Css.property "--tw-scale-y" ".95"


select_all : Css.Style
select_all =
    Css.property "user-select" "all"


select_auto : Css.Style
select_auto =
    Css.property "user-select" "auto"


select_none : Css.Style
select_none =
    Css.property "user-select" "none"


select_text : Css.Style
select_text =
    Css.property "user-select" "text"


self_auto : Css.Style
self_auto =
    Css.property "align-self" "auto"


self_baseline : Css.Style
self_baseline =
    Css.property "align-self" "baseline"


self_center : Css.Style
self_center =
    Css.property "align-self" "center"


self_end : Css.Style
self_end =
    Css.property "align-self" "flex-end"


self_start : Css.Style
self_start =
    Css.property "align-self" "flex-start"


self_stretch : Css.Style
self_stretch =
    Css.property "align-self" "stretch"


sepia : Css.Style
sepia =
    Css.property "--tw-sepia" "sepia(100%)"


sepia_0 : Css.Style
sepia_0 =
    Css.property "--tw-sepia" "sepia(0)"


shadow : Css.Style
shadow =
    Css.batch
        [ Css.property "--tw-shadow" "0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_2xl : Css.Style
shadow_2xl =
    Css.batch
        [ Css.property "--tw-shadow" "0 25px 50px -12px rgba(0, 0, 0, 0.25)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_inner : Css.Style
shadow_inner =
    Css.batch
        [ Css.property "--tw-shadow" "inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_lg : Css.Style
shadow_lg =
    Css.batch
        [ Css.property "--tw-shadow" "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_md : Css.Style
shadow_md =
    Css.batch
        [ Css.property "--tw-shadow" "0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_none : Css.Style
shadow_none =
    Css.batch
        [ Css.property "--tw-shadow" "0 0 #0000"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_sm : Css.Style
shadow_sm =
    Css.batch
        [ Css.property "--tw-shadow" "0 1px 2px 0 rgba(0, 0, 0, 0.05)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


shadow_xl : Css.Style
shadow_xl =
    Css.batch
        [ Css.property "--tw-shadow" "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)"
        , Css.property "box-shadow" "var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow)"
        ]


skew_x_0 : Css.Style
skew_x_0 =
    Css.property "--tw-skew-x" "0deg"


skew_x_1 : Css.Style
skew_x_1 =
    Css.property "--tw-skew-x" "1deg"


skew_x_12 : Css.Style
skew_x_12 =
    Css.property "--tw-skew-x" "12deg"


skew_x_2 : Css.Style
skew_x_2 =
    Css.property "--tw-skew-x" "2deg"


skew_x_3 : Css.Style
skew_x_3 =
    Css.property "--tw-skew-x" "3deg"


skew_x_6 : Css.Style
skew_x_6 =
    Css.property "--tw-skew-x" "6deg"


skew_y_0 : Css.Style
skew_y_0 =
    Css.property "--tw-skew-y" "0deg"


skew_y_1 : Css.Style
skew_y_1 =
    Css.property "--tw-skew-y" "1deg"


skew_y_12 : Css.Style
skew_y_12 =
    Css.property "--tw-skew-y" "12deg"


skew_y_2 : Css.Style
skew_y_2 =
    Css.property "--tw-skew-y" "2deg"


skew_y_3 : Css.Style
skew_y_3 =
    Css.property "--tw-skew-y" "3deg"


skew_y_6 : Css.Style
skew_y_6 =
    Css.property "--tw-skew-y" "6deg"


slashed_zero : Css.Style
slashed_zero =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-slashed-zero" "slashed-zero"
        ]


space_x_0 : Css.Style
space_x_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0px * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0px * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_0_dot_5 : Css.Style
space_x_0_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.125rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.125rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_1 : Css.Style
space_x_1 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.25rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.25rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_10 : Css.Style
space_x_10 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(2.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(2.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_11 : Css.Style
space_x_11 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(2.75rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(2.75rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_12 : Css.Style
space_x_12 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(3rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(3rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_14 : Css.Style
space_x_14 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(3.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(3.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_16 : Css.Style
space_x_16 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(4rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(4rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_1_dot_5 : Css.Style
space_x_1_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.375rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.375rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_2 : Css.Style
space_x_2 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_20 : Css.Style
space_x_20 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_24 : Css.Style
space_x_24 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(6rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(6rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_28 : Css.Style
space_x_28 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(7rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(7rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_2_dot_5 : Css.Style
space_x_2_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.625rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.625rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_3 : Css.Style
space_x_3 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.75rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.75rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_32 : Css.Style
space_x_32 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(8rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(8rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_36 : Css.Style
space_x_36 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(9rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(9rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_3_dot_5 : Css.Style
space_x_3_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(0.875rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(0.875rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_4 : Css.Style
space_x_4 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(1rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(1rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_40 : Css.Style
space_x_40 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(10rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(10rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_44 : Css.Style
space_x_44 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(11rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(11rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_48 : Css.Style
space_x_48 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(12rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(12rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_5 : Css.Style
space_x_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(1.25rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(1.25rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_52 : Css.Style
space_x_52 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(13rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(13rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_56 : Css.Style
space_x_56 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(14rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(14rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_6 : Css.Style
space_x_6 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(1.5rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(1.5rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_60 : Css.Style
space_x_60 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(15rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(15rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_64 : Css.Style
space_x_64 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(16rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(16rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_7 : Css.Style
space_x_7 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(1.75rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(1.75rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_72 : Css.Style
space_x_72 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(18rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(18rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_8 : Css.Style
space_x_8 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(2rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(2rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_80 : Css.Style
space_x_80 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(20rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(20rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_9 : Css.Style
space_x_9 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(2.25rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(2.25rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_96 : Css.Style
space_x_96 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(24rem * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(24rem * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_px : Css.Style
space_x_px =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "0"
                , Css.property "margin-right" "calc(1px * var(--tw-space-x-reverse))"
                , Css.property "margin-left" "calc(1px * calc(1 - var(--tw-space-x-reverse)))"
                ]
            ]
        ]


space_x_reverse : Css.Style
space_x_reverse =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-x-reverse" "1"
                ]
            ]
        ]


space_y_0 : Css.Style
space_y_0 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0px * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0px * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_0_dot_5 : Css.Style
space_y_0_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.125rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.125rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_1 : Css.Style
space_y_1 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.25rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.25rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_10 : Css.Style
space_y_10 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(2.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(2.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_11 : Css.Style
space_y_11 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(2.75rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(2.75rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_12 : Css.Style
space_y_12 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(3rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(3rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_14 : Css.Style
space_y_14 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(3.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(3.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_16 : Css.Style
space_y_16 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(4rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(4rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_1_dot_5 : Css.Style
space_y_1_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.375rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.375rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_2 : Css.Style
space_y_2 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_20 : Css.Style
space_y_20 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_24 : Css.Style
space_y_24 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(6rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(6rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_28 : Css.Style
space_y_28 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(7rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(7rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_2_dot_5 : Css.Style
space_y_2_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.625rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.625rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_3 : Css.Style
space_y_3 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.75rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.75rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_32 : Css.Style
space_y_32 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(8rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(8rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_36 : Css.Style
space_y_36 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(9rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(9rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_3_dot_5 : Css.Style
space_y_3_dot_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(0.875rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(0.875rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_4 : Css.Style
space_y_4 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(1rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(1rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_40 : Css.Style
space_y_40 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(10rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(10rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_44 : Css.Style
space_y_44 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(11rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(11rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_48 : Css.Style
space_y_48 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(12rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(12rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_5 : Css.Style
space_y_5 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(1.25rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(1.25rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_52 : Css.Style
space_y_52 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(13rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(13rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_56 : Css.Style
space_y_56 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(14rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(14rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_6 : Css.Style
space_y_6 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(1.5rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(1.5rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_60 : Css.Style
space_y_60 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(15rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(15rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_64 : Css.Style
space_y_64 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(16rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(16rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_7 : Css.Style
space_y_7 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(1.75rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(1.75rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_72 : Css.Style
space_y_72 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(18rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(18rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_8 : Css.Style
space_y_8 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(2rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(2rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_80 : Css.Style
space_y_80 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(20rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(20rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_9 : Css.Style
space_y_9 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(2.25rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(2.25rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_96 : Css.Style
space_y_96 =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(24rem * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(24rem * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_px : Css.Style
space_y_px =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "0"
                , Css.property "margin-top" "calc(1px * calc(1 - var(--tw-space-y-reverse)))"
                , Css.property "margin-bottom" "calc(1px * var(--tw-space-y-reverse))"
                ]
            ]
        ]


space_y_reverse : Css.Style
space_y_reverse =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-space-y-reverse" "1"
                ]
            ]
        ]


sr_only : Css.Style
sr_only =
    Css.batch
        [ Css.property "position" "absolute"
        , Css.property "width" "1px"
        , Css.property "height" "1px"
        , Css.property "padding" "0"
        , Css.property "margin" "-1px"
        , Css.property "overflow" "hidden"
        , Css.property "clip" "rect(0, 0, 0, 0)"
        , Css.property "white-space" "nowrap"
        , Css.property "border-width" "0"
        ]


stacked_fractions : Css.Style
stacked_fractions =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-numeric-fraction" "stacked-fractions"
        ]


static : Css.Style
static =
    Css.property "position" "static"


sticky : Css.Style
sticky =
    Css.property "position" "sticky"


stroke_0 : Css.Style
stroke_0 =
    Css.property "stroke-width" "0"


stroke_1 : Css.Style
stroke_1 =
    Css.property "stroke-width" "1"


stroke_2 : Css.Style
stroke_2 =
    Css.property "stroke-width" "2"


stroke_current : Css.Style
stroke_current =
    Css.property "stroke" "currentColor"


subpixel_antialiased : Css.Style
subpixel_antialiased =
    Css.batch
        [ Css.property "-webkit-font-smoothing" "auto"
        , Css.property "-moz-osx-font-smoothing" "auto"
        ]


table : Css.Style
table =
    Css.property "display" "table"


table_auto : Css.Style
table_auto =
    Css.property "table-layout" "auto"


table_caption : Css.Style
table_caption =
    Css.property "display" "table-caption"


table_cell : Css.Style
table_cell =
    Css.property "display" "table-cell"


table_column : Css.Style
table_column =
    Css.property "display" "table-column"


table_column_group : Css.Style
table_column_group =
    Css.property "display" "table-column-group"


table_fixed : Css.Style
table_fixed =
    Css.property "table-layout" "fixed"


table_footer_group : Css.Style
table_footer_group =
    Css.property "display" "table-footer-group"


table_header_group : Css.Style
table_header_group =
    Css.property "display" "table-header-group"


table_row : Css.Style
table_row =
    Css.property "display" "table-row"


table_row_group : Css.Style
table_row_group =
    Css.property "display" "table-row-group"


tabular_nums : Css.Style
tabular_nums =
    Css.batch
        [ Css.property "--tw-ordinal" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-slashed-zero" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-figure" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-spacing" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "--tw-numeric-fraction" "var(--tw-empty,/*!*/ /*!*/)"
        , Css.property "font-variant-numeric" "var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)"
        , Css.property "--tw-numeric-spacing" "tabular-nums"
        ]


text_2xl : Css.Style
text_2xl =
    Css.batch
        [ Css.property "font-size" "1.5rem"
        , Css.property "line-height" "2rem"
        ]


text_3xl : Css.Style
text_3xl =
    Css.batch
        [ Css.property "font-size" "1.875rem"
        , Css.property "line-height" "2.25rem"
        ]


text_4xl : Css.Style
text_4xl =
    Css.batch
        [ Css.property "font-size" "2.25rem"
        , Css.property "line-height" "2.5rem"
        ]


text_5xl : Css.Style
text_5xl =
    Css.batch
        [ Css.property "font-size" "3rem"
        , Css.property "line-height" "1"
        ]


text_6xl : Css.Style
text_6xl =
    Css.batch
        [ Css.property "font-size" "3.75rem"
        , Css.property "line-height" "1"
        ]


text_7xl : Css.Style
text_7xl =
    Css.batch
        [ Css.property "font-size" "4.5rem"
        , Css.property "line-height" "1"
        ]


text_8xl : Css.Style
text_8xl =
    Css.batch
        [ Css.property "font-size" "6rem"
        , Css.property "line-height" "1"
        ]


text_9xl : Css.Style
text_9xl =
    Css.batch
        [ Css.property "font-size" "8rem"
        , Css.property "line-height" "1"
        ]


text_base : Css.Style
text_base =
    Css.batch
        [ Css.property "font-size" "1rem"
        , Css.property "line-height" "1.5rem"
        ]


text_black : Css.Style
text_black =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(0, 0, 0, var(--tw-text-opacity))"
        ]


text_blue_100 : Css.Style
text_blue_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(219, 234, 254, var(--tw-text-opacity))"
        ]


text_blue_200 : Css.Style
text_blue_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(191, 219, 254, var(--tw-text-opacity))"
        ]


text_blue_300 : Css.Style
text_blue_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(147, 197, 253, var(--tw-text-opacity))"
        ]


text_blue_400 : Css.Style
text_blue_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(96, 165, 250, var(--tw-text-opacity))"
        ]


text_blue_50 : Css.Style
text_blue_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(239, 246, 255, var(--tw-text-opacity))"
        ]


text_blue_500 : Css.Style
text_blue_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(59, 130, 246, var(--tw-text-opacity))"
        ]


text_blue_600 : Css.Style
text_blue_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(37, 99, 235, var(--tw-text-opacity))"
        ]


text_blue_700 : Css.Style
text_blue_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(29, 78, 216, var(--tw-text-opacity))"
        ]


text_blue_800 : Css.Style
text_blue_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(30, 64, 175, var(--tw-text-opacity))"
        ]


text_blue_900 : Css.Style
text_blue_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(30, 58, 138, var(--tw-text-opacity))"
        ]


text_center : Css.Style
text_center =
    Css.property "text-align" "center"


text_current : Css.Style
text_current =
    Css.property "color" "currentColor"


text_gray_100 : Css.Style
text_gray_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(243, 244, 246, var(--tw-text-opacity))"
        ]


text_gray_200 : Css.Style
text_gray_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(229, 231, 235, var(--tw-text-opacity))"
        ]


text_gray_300 : Css.Style
text_gray_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(209, 213, 219, var(--tw-text-opacity))"
        ]


text_gray_400 : Css.Style
text_gray_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(156, 163, 175, var(--tw-text-opacity))"
        ]


text_gray_50 : Css.Style
text_gray_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(249, 250, 251, var(--tw-text-opacity))"
        ]


text_gray_500 : Css.Style
text_gray_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(107, 114, 128, var(--tw-text-opacity))"
        ]


text_gray_600 : Css.Style
text_gray_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(75, 85, 99, var(--tw-text-opacity))"
        ]


text_gray_700 : Css.Style
text_gray_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(55, 65, 81, var(--tw-text-opacity))"
        ]


text_gray_800 : Css.Style
text_gray_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(31, 41, 55, var(--tw-text-opacity))"
        ]


text_gray_900 : Css.Style
text_gray_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(17, 24, 39, var(--tw-text-opacity))"
        ]


text_green_100 : Css.Style
text_green_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(209, 250, 229, var(--tw-text-opacity))"
        ]


text_green_200 : Css.Style
text_green_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(167, 243, 208, var(--tw-text-opacity))"
        ]


text_green_300 : Css.Style
text_green_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(110, 231, 183, var(--tw-text-opacity))"
        ]


text_green_400 : Css.Style
text_green_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(52, 211, 153, var(--tw-text-opacity))"
        ]


text_green_50 : Css.Style
text_green_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(236, 253, 245, var(--tw-text-opacity))"
        ]


text_green_500 : Css.Style
text_green_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(16, 185, 129, var(--tw-text-opacity))"
        ]


text_green_600 : Css.Style
text_green_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(5, 150, 105, var(--tw-text-opacity))"
        ]


text_green_700 : Css.Style
text_green_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(4, 120, 87, var(--tw-text-opacity))"
        ]


text_green_800 : Css.Style
text_green_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(6, 95, 70, var(--tw-text-opacity))"
        ]


text_green_900 : Css.Style
text_green_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(6, 78, 59, var(--tw-text-opacity))"
        ]


text_indigo_100 : Css.Style
text_indigo_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(224, 231, 255, var(--tw-text-opacity))"
        ]


text_indigo_200 : Css.Style
text_indigo_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(199, 210, 254, var(--tw-text-opacity))"
        ]


text_indigo_300 : Css.Style
text_indigo_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(165, 180, 252, var(--tw-text-opacity))"
        ]


text_indigo_400 : Css.Style
text_indigo_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(129, 140, 248, var(--tw-text-opacity))"
        ]


text_indigo_50 : Css.Style
text_indigo_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(238, 242, 255, var(--tw-text-opacity))"
        ]


text_indigo_500 : Css.Style
text_indigo_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(99, 102, 241, var(--tw-text-opacity))"
        ]


text_indigo_600 : Css.Style
text_indigo_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(79, 70, 229, var(--tw-text-opacity))"
        ]


text_indigo_700 : Css.Style
text_indigo_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(67, 56, 202, var(--tw-text-opacity))"
        ]


text_indigo_800 : Css.Style
text_indigo_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(55, 48, 163, var(--tw-text-opacity))"
        ]


text_indigo_900 : Css.Style
text_indigo_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(49, 46, 129, var(--tw-text-opacity))"
        ]


text_justify : Css.Style
text_justify =
    Css.property "text-align" "justify"


text_left : Css.Style
text_left =
    Css.property "text-align" "left"


text_lg : Css.Style
text_lg =
    Css.batch
        [ Css.property "font-size" "1.125rem"
        , Css.property "line-height" "1.75rem"
        ]


text_opacity_0 : Css.Style
text_opacity_0 =
    Css.property "--tw-text-opacity" "0"


text_opacity_10 : Css.Style
text_opacity_10 =
    Css.property "--tw-text-opacity" "0.1"


text_opacity_100 : Css.Style
text_opacity_100 =
    Css.property "--tw-text-opacity" "1"


text_opacity_20 : Css.Style
text_opacity_20 =
    Css.property "--tw-text-opacity" "0.2"


text_opacity_25 : Css.Style
text_opacity_25 =
    Css.property "--tw-text-opacity" "0.25"


text_opacity_30 : Css.Style
text_opacity_30 =
    Css.property "--tw-text-opacity" "0.3"


text_opacity_40 : Css.Style
text_opacity_40 =
    Css.property "--tw-text-opacity" "0.4"


text_opacity_5 : Css.Style
text_opacity_5 =
    Css.property "--tw-text-opacity" "0.05"


text_opacity_50 : Css.Style
text_opacity_50 =
    Css.property "--tw-text-opacity" "0.5"


text_opacity_60 : Css.Style
text_opacity_60 =
    Css.property "--tw-text-opacity" "0.6"


text_opacity_70 : Css.Style
text_opacity_70 =
    Css.property "--tw-text-opacity" "0.7"


text_opacity_75 : Css.Style
text_opacity_75 =
    Css.property "--tw-text-opacity" "0.75"


text_opacity_80 : Css.Style
text_opacity_80 =
    Css.property "--tw-text-opacity" "0.8"


text_opacity_90 : Css.Style
text_opacity_90 =
    Css.property "--tw-text-opacity" "0.9"


text_opacity_95 : Css.Style
text_opacity_95 =
    Css.property "--tw-text-opacity" "0.95"


text_pink_100 : Css.Style
text_pink_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(252, 231, 243, var(--tw-text-opacity))"
        ]


text_pink_200 : Css.Style
text_pink_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(251, 207, 232, var(--tw-text-opacity))"
        ]


text_pink_300 : Css.Style
text_pink_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(249, 168, 212, var(--tw-text-opacity))"
        ]


text_pink_400 : Css.Style
text_pink_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(244, 114, 182, var(--tw-text-opacity))"
        ]


text_pink_50 : Css.Style
text_pink_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(253, 242, 248, var(--tw-text-opacity))"
        ]


text_pink_500 : Css.Style
text_pink_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(236, 72, 153, var(--tw-text-opacity))"
        ]


text_pink_600 : Css.Style
text_pink_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(219, 39, 119, var(--tw-text-opacity))"
        ]


text_pink_700 : Css.Style
text_pink_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(190, 24, 93, var(--tw-text-opacity))"
        ]


text_pink_800 : Css.Style
text_pink_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(157, 23, 77, var(--tw-text-opacity))"
        ]


text_pink_900 : Css.Style
text_pink_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(131, 24, 67, var(--tw-text-opacity))"
        ]


text_purple_100 : Css.Style
text_purple_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(237, 233, 254, var(--tw-text-opacity))"
        ]


text_purple_200 : Css.Style
text_purple_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(221, 214, 254, var(--tw-text-opacity))"
        ]


text_purple_300 : Css.Style
text_purple_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(196, 181, 253, var(--tw-text-opacity))"
        ]


text_purple_400 : Css.Style
text_purple_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(167, 139, 250, var(--tw-text-opacity))"
        ]


text_purple_50 : Css.Style
text_purple_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(245, 243, 255, var(--tw-text-opacity))"
        ]


text_purple_500 : Css.Style
text_purple_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(139, 92, 246, var(--tw-text-opacity))"
        ]


text_purple_600 : Css.Style
text_purple_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(124, 58, 237, var(--tw-text-opacity))"
        ]


text_purple_700 : Css.Style
text_purple_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(109, 40, 217, var(--tw-text-opacity))"
        ]


text_purple_800 : Css.Style
text_purple_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(91, 33, 182, var(--tw-text-opacity))"
        ]


text_purple_900 : Css.Style
text_purple_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(76, 29, 149, var(--tw-text-opacity))"
        ]


text_red_100 : Css.Style
text_red_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(254, 226, 226, var(--tw-text-opacity))"
        ]


text_red_200 : Css.Style
text_red_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(254, 202, 202, var(--tw-text-opacity))"
        ]


text_red_300 : Css.Style
text_red_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(252, 165, 165, var(--tw-text-opacity))"
        ]


text_red_400 : Css.Style
text_red_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(248, 113, 113, var(--tw-text-opacity))"
        ]


text_red_50 : Css.Style
text_red_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(254, 242, 242, var(--tw-text-opacity))"
        ]


text_red_500 : Css.Style
text_red_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(239, 68, 68, var(--tw-text-opacity))"
        ]


text_red_600 : Css.Style
text_red_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(220, 38, 38, var(--tw-text-opacity))"
        ]


text_red_700 : Css.Style
text_red_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(185, 28, 28, var(--tw-text-opacity))"
        ]


text_red_800 : Css.Style
text_red_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(153, 27, 27, var(--tw-text-opacity))"
        ]


text_red_900 : Css.Style
text_red_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(127, 29, 29, var(--tw-text-opacity))"
        ]


text_right : Css.Style
text_right =
    Css.property "text-align" "right"


text_sm : Css.Style
text_sm =
    Css.batch
        [ Css.property "font-size" "0.875rem"
        , Css.property "line-height" "1.25rem"
        ]


text_transparent : Css.Style
text_transparent =
    Css.property "color" "transparent"


text_white : Css.Style
text_white =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(255, 255, 255, var(--tw-text-opacity))"
        ]


text_xl : Css.Style
text_xl =
    Css.batch
        [ Css.property "font-size" "1.25rem"
        , Css.property "line-height" "1.75rem"
        ]


text_xs : Css.Style
text_xs =
    Css.batch
        [ Css.property "font-size" "0.75rem"
        , Css.property "line-height" "1rem"
        ]


text_yellow_100 : Css.Style
text_yellow_100 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(254, 243, 199, var(--tw-text-opacity))"
        ]


text_yellow_200 : Css.Style
text_yellow_200 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(253, 230, 138, var(--tw-text-opacity))"
        ]


text_yellow_300 : Css.Style
text_yellow_300 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(252, 211, 77, var(--tw-text-opacity))"
        ]


text_yellow_400 : Css.Style
text_yellow_400 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(251, 191, 36, var(--tw-text-opacity))"
        ]


text_yellow_50 : Css.Style
text_yellow_50 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(255, 251, 235, var(--tw-text-opacity))"
        ]


text_yellow_500 : Css.Style
text_yellow_500 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(245, 158, 11, var(--tw-text-opacity))"
        ]


text_yellow_600 : Css.Style
text_yellow_600 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(217, 119, 6, var(--tw-text-opacity))"
        ]


text_yellow_700 : Css.Style
text_yellow_700 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(180, 83, 9, var(--tw-text-opacity))"
        ]


text_yellow_800 : Css.Style
text_yellow_800 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(146, 64, 14, var(--tw-text-opacity))"
        ]


text_yellow_900 : Css.Style
text_yellow_900 =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" "rgba(120, 53, 15, var(--tw-text-opacity))"
        ]


to_black : Css.Style
to_black =
    Css.property "--tw-gradient-to" "#000"


to_blue_100 : Css.Style
to_blue_100 =
    Css.property "--tw-gradient-to" "#dbeafe"


to_blue_200 : Css.Style
to_blue_200 =
    Css.property "--tw-gradient-to" "#bfdbfe"


to_blue_300 : Css.Style
to_blue_300 =
    Css.property "--tw-gradient-to" "#93c5fd"


to_blue_400 : Css.Style
to_blue_400 =
    Css.property "--tw-gradient-to" "#60a5fa"


to_blue_50 : Css.Style
to_blue_50 =
    Css.property "--tw-gradient-to" "#eff6ff"


to_blue_500 : Css.Style
to_blue_500 =
    Css.property "--tw-gradient-to" "#3b82f6"


to_blue_600 : Css.Style
to_blue_600 =
    Css.property "--tw-gradient-to" "#2563eb"


to_blue_700 : Css.Style
to_blue_700 =
    Css.property "--tw-gradient-to" "#1d4ed8"


to_blue_800 : Css.Style
to_blue_800 =
    Css.property "--tw-gradient-to" "#1e40af"


to_blue_900 : Css.Style
to_blue_900 =
    Css.property "--tw-gradient-to" "#1e3a8a"


to_current : Css.Style
to_current =
    Css.property "--tw-gradient-to" "currentColor"


to_gray_100 : Css.Style
to_gray_100 =
    Css.property "--tw-gradient-to" "#f3f4f6"


to_gray_200 : Css.Style
to_gray_200 =
    Css.property "--tw-gradient-to" "#e5e7eb"


to_gray_300 : Css.Style
to_gray_300 =
    Css.property "--tw-gradient-to" "#d1d5db"


to_gray_400 : Css.Style
to_gray_400 =
    Css.property "--tw-gradient-to" "#9ca3af"


to_gray_50 : Css.Style
to_gray_50 =
    Css.property "--tw-gradient-to" "#f9fafb"


to_gray_500 : Css.Style
to_gray_500 =
    Css.property "--tw-gradient-to" "#6b7280"


to_gray_600 : Css.Style
to_gray_600 =
    Css.property "--tw-gradient-to" "#4b5563"


to_gray_700 : Css.Style
to_gray_700 =
    Css.property "--tw-gradient-to" "#374151"


to_gray_800 : Css.Style
to_gray_800 =
    Css.property "--tw-gradient-to" "#1f2937"


to_gray_900 : Css.Style
to_gray_900 =
    Css.property "--tw-gradient-to" "#111827"


to_green_100 : Css.Style
to_green_100 =
    Css.property "--tw-gradient-to" "#d1fae5"


to_green_200 : Css.Style
to_green_200 =
    Css.property "--tw-gradient-to" "#a7f3d0"


to_green_300 : Css.Style
to_green_300 =
    Css.property "--tw-gradient-to" "#6ee7b7"


to_green_400 : Css.Style
to_green_400 =
    Css.property "--tw-gradient-to" "#34d399"


to_green_50 : Css.Style
to_green_50 =
    Css.property "--tw-gradient-to" "#ecfdf5"


to_green_500 : Css.Style
to_green_500 =
    Css.property "--tw-gradient-to" "#10b981"


to_green_600 : Css.Style
to_green_600 =
    Css.property "--tw-gradient-to" "#059669"


to_green_700 : Css.Style
to_green_700 =
    Css.property "--tw-gradient-to" "#047857"


to_green_800 : Css.Style
to_green_800 =
    Css.property "--tw-gradient-to" "#065f46"


to_green_900 : Css.Style
to_green_900 =
    Css.property "--tw-gradient-to" "#064e3b"


to_indigo_100 : Css.Style
to_indigo_100 =
    Css.property "--tw-gradient-to" "#e0e7ff"


to_indigo_200 : Css.Style
to_indigo_200 =
    Css.property "--tw-gradient-to" "#c7d2fe"


to_indigo_300 : Css.Style
to_indigo_300 =
    Css.property "--tw-gradient-to" "#a5b4fc"


to_indigo_400 : Css.Style
to_indigo_400 =
    Css.property "--tw-gradient-to" "#818cf8"


to_indigo_50 : Css.Style
to_indigo_50 =
    Css.property "--tw-gradient-to" "#eef2ff"


to_indigo_500 : Css.Style
to_indigo_500 =
    Css.property "--tw-gradient-to" "#6366f1"


to_indigo_600 : Css.Style
to_indigo_600 =
    Css.property "--tw-gradient-to" "#4f46e5"


to_indigo_700 : Css.Style
to_indigo_700 =
    Css.property "--tw-gradient-to" "#4338ca"


to_indigo_800 : Css.Style
to_indigo_800 =
    Css.property "--tw-gradient-to" "#3730a3"


to_indigo_900 : Css.Style
to_indigo_900 =
    Css.property "--tw-gradient-to" "#312e81"


to_pink_100 : Css.Style
to_pink_100 =
    Css.property "--tw-gradient-to" "#fce7f3"


to_pink_200 : Css.Style
to_pink_200 =
    Css.property "--tw-gradient-to" "#fbcfe8"


to_pink_300 : Css.Style
to_pink_300 =
    Css.property "--tw-gradient-to" "#f9a8d4"


to_pink_400 : Css.Style
to_pink_400 =
    Css.property "--tw-gradient-to" "#f472b6"


to_pink_50 : Css.Style
to_pink_50 =
    Css.property "--tw-gradient-to" "#fdf2f8"


to_pink_500 : Css.Style
to_pink_500 =
    Css.property "--tw-gradient-to" "#ec4899"


to_pink_600 : Css.Style
to_pink_600 =
    Css.property "--tw-gradient-to" "#db2777"


to_pink_700 : Css.Style
to_pink_700 =
    Css.property "--tw-gradient-to" "#be185d"


to_pink_800 : Css.Style
to_pink_800 =
    Css.property "--tw-gradient-to" "#9d174d"


to_pink_900 : Css.Style
to_pink_900 =
    Css.property "--tw-gradient-to" "#831843"


to_purple_100 : Css.Style
to_purple_100 =
    Css.property "--tw-gradient-to" "#ede9fe"


to_purple_200 : Css.Style
to_purple_200 =
    Css.property "--tw-gradient-to" "#ddd6fe"


to_purple_300 : Css.Style
to_purple_300 =
    Css.property "--tw-gradient-to" "#c4b5fd"


to_purple_400 : Css.Style
to_purple_400 =
    Css.property "--tw-gradient-to" "#a78bfa"


to_purple_50 : Css.Style
to_purple_50 =
    Css.property "--tw-gradient-to" "#f5f3ff"


to_purple_500 : Css.Style
to_purple_500 =
    Css.property "--tw-gradient-to" "#8b5cf6"


to_purple_600 : Css.Style
to_purple_600 =
    Css.property "--tw-gradient-to" "#7c3aed"


to_purple_700 : Css.Style
to_purple_700 =
    Css.property "--tw-gradient-to" "#6d28d9"


to_purple_800 : Css.Style
to_purple_800 =
    Css.property "--tw-gradient-to" "#5b21b6"


to_purple_900 : Css.Style
to_purple_900 =
    Css.property "--tw-gradient-to" "#4c1d95"


to_red_100 : Css.Style
to_red_100 =
    Css.property "--tw-gradient-to" "#fee2e2"


to_red_200 : Css.Style
to_red_200 =
    Css.property "--tw-gradient-to" "#fecaca"


to_red_300 : Css.Style
to_red_300 =
    Css.property "--tw-gradient-to" "#fca5a5"


to_red_400 : Css.Style
to_red_400 =
    Css.property "--tw-gradient-to" "#f87171"


to_red_50 : Css.Style
to_red_50 =
    Css.property "--tw-gradient-to" "#fef2f2"


to_red_500 : Css.Style
to_red_500 =
    Css.property "--tw-gradient-to" "#ef4444"


to_red_600 : Css.Style
to_red_600 =
    Css.property "--tw-gradient-to" "#dc2626"


to_red_700 : Css.Style
to_red_700 =
    Css.property "--tw-gradient-to" "#b91c1c"


to_red_800 : Css.Style
to_red_800 =
    Css.property "--tw-gradient-to" "#991b1b"


to_red_900 : Css.Style
to_red_900 =
    Css.property "--tw-gradient-to" "#7f1d1d"


to_transparent : Css.Style
to_transparent =
    Css.property "--tw-gradient-to" "transparent"


to_white : Css.Style
to_white =
    Css.property "--tw-gradient-to" "#fff"


to_yellow_100 : Css.Style
to_yellow_100 =
    Css.property "--tw-gradient-to" "#fef3c7"


to_yellow_200 : Css.Style
to_yellow_200 =
    Css.property "--tw-gradient-to" "#fde68a"


to_yellow_300 : Css.Style
to_yellow_300 =
    Css.property "--tw-gradient-to" "#fcd34d"


to_yellow_400 : Css.Style
to_yellow_400 =
    Css.property "--tw-gradient-to" "#fbbf24"


to_yellow_50 : Css.Style
to_yellow_50 =
    Css.property "--tw-gradient-to" "#fffbeb"


to_yellow_500 : Css.Style
to_yellow_500 =
    Css.property "--tw-gradient-to" "#f59e0b"


to_yellow_600 : Css.Style
to_yellow_600 =
    Css.property "--tw-gradient-to" "#d97706"


to_yellow_700 : Css.Style
to_yellow_700 =
    Css.property "--tw-gradient-to" "#b45309"


to_yellow_800 : Css.Style
to_yellow_800 =
    Css.property "--tw-gradient-to" "#92400e"


to_yellow_900 : Css.Style
to_yellow_900 =
    Css.property "--tw-gradient-to" "#78350f"


top_0 : Css.Style
top_0 =
    Css.property "top" "0px"


top_0_dot_5 : Css.Style
top_0_dot_5 =
    Css.property "top" "0.125rem"


top_1 : Css.Style
top_1 =
    Css.property "top" "0.25rem"


top_10 : Css.Style
top_10 =
    Css.property "top" "2.5rem"


top_11 : Css.Style
top_11 =
    Css.property "top" "2.75rem"


top_12 : Css.Style
top_12 =
    Css.property "top" "3rem"


top_14 : Css.Style
top_14 =
    Css.property "top" "3.5rem"


top_16 : Css.Style
top_16 =
    Css.property "top" "4rem"


top_1_dot_5 : Css.Style
top_1_dot_5 =
    Css.property "top" "0.375rem"


top_1over2 : Css.Style
top_1over2 =
    Css.property "top" "50%"


top_1over3 : Css.Style
top_1over3 =
    Css.property "top" "33.333333%"


top_1over4 : Css.Style
top_1over4 =
    Css.property "top" "25%"


top_2 : Css.Style
top_2 =
    Css.property "top" "0.5rem"


top_20 : Css.Style
top_20 =
    Css.property "top" "5rem"


top_24 : Css.Style
top_24 =
    Css.property "top" "6rem"


top_28 : Css.Style
top_28 =
    Css.property "top" "7rem"


top_2_dot_5 : Css.Style
top_2_dot_5 =
    Css.property "top" "0.625rem"


top_2over3 : Css.Style
top_2over3 =
    Css.property "top" "66.666667%"


top_2over4 : Css.Style
top_2over4 =
    Css.property "top" "50%"


top_3 : Css.Style
top_3 =
    Css.property "top" "0.75rem"


top_32 : Css.Style
top_32 =
    Css.property "top" "8rem"


top_36 : Css.Style
top_36 =
    Css.property "top" "9rem"


top_3_dot_5 : Css.Style
top_3_dot_5 =
    Css.property "top" "0.875rem"


top_3over4 : Css.Style
top_3over4 =
    Css.property "top" "75%"


top_4 : Css.Style
top_4 =
    Css.property "top" "1rem"


top_40 : Css.Style
top_40 =
    Css.property "top" "10rem"


top_44 : Css.Style
top_44 =
    Css.property "top" "11rem"


top_48 : Css.Style
top_48 =
    Css.property "top" "12rem"


top_5 : Css.Style
top_5 =
    Css.property "top" "1.25rem"


top_52 : Css.Style
top_52 =
    Css.property "top" "13rem"


top_56 : Css.Style
top_56 =
    Css.property "top" "14rem"


top_6 : Css.Style
top_6 =
    Css.property "top" "1.5rem"


top_60 : Css.Style
top_60 =
    Css.property "top" "15rem"


top_64 : Css.Style
top_64 =
    Css.property "top" "16rem"


top_7 : Css.Style
top_7 =
    Css.property "top" "1.75rem"


top_72 : Css.Style
top_72 =
    Css.property "top" "18rem"


top_8 : Css.Style
top_8 =
    Css.property "top" "2rem"


top_80 : Css.Style
top_80 =
    Css.property "top" "20rem"


top_9 : Css.Style
top_9 =
    Css.property "top" "2.25rem"


top_96 : Css.Style
top_96 =
    Css.property "top" "24rem"


top_auto : Css.Style
top_auto =
    Css.property "top" "auto"


top_full : Css.Style
top_full =
    Css.property "top" "100%"


top_px : Css.Style
top_px =
    Css.property "top" "1px"


tracking_normal : Css.Style
tracking_normal =
    Css.property "letter-spacing" "0em"


tracking_tight : Css.Style
tracking_tight =
    Css.property "letter-spacing" "-0.025em"


tracking_tighter : Css.Style
tracking_tighter =
    Css.property "letter-spacing" "-0.05em"


tracking_wide : Css.Style
tracking_wide =
    Css.property "letter-spacing" "0.025em"


tracking_wider : Css.Style
tracking_wider =
    Css.property "letter-spacing" "0.05em"


tracking_widest : Css.Style
tracking_widest =
    Css.property "letter-spacing" "0.1em"


transform : Css.Style
transform =
    Css.batch
        [ Css.property "--tw-translate-x" "0"
        , Css.property "--tw-translate-y" "0"
        , Css.property "--tw-rotate" "0"
        , Css.property "--tw-skew-x" "0"
        , Css.property "--tw-skew-y" "0"
        , Css.property "--tw-scale-x" "1"
        , Css.property "--tw-scale-y" "1"
        , Css.property "transform" "translateX(var(--tw-translate-x)) translateY(var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))"
        ]


transform_gpu : Css.Style
transform_gpu =
    Css.batch
        [ Css.property "--tw-translate-x" "0"
        , Css.property "--tw-translate-y" "0"
        , Css.property "--tw-rotate" "0"
        , Css.property "--tw-skew-x" "0"
        , Css.property "--tw-skew-y" "0"
        , Css.property "--tw-scale-x" "1"
        , Css.property "--tw-scale-y" "1"
        , Css.property "transform" "translate3d(var(--tw-translate-x), var(--tw-translate-y), 0) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))"
        ]


transform_none : Css.Style
transform_none =
    Css.property "transform" "none"


transition : Css.Style
transition =
    Css.batch
        [ Css.property "transition-property" "background-color, border-color, color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter"
        , Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"
        , Css.property "transition-duration" "150ms"
        ]


transition_all : Css.Style
transition_all =
    Css.batch
        [ Css.property "transition-property" "all"
        , Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"
        , Css.property "transition-duration" "150ms"
        ]


transition_colors : Css.Style
transition_colors =
    Css.batch
        [ Css.property "transition-property" "background-color, border-color, color, fill, stroke"
        , Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"
        , Css.property "transition-duration" "150ms"
        ]


transition_none : Css.Style
transition_none =
    Css.property "transition-property" "none"


transition_opacity : Css.Style
transition_opacity =
    Css.batch
        [ Css.property "transition-property" "opacity"
        , Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"
        , Css.property "transition-duration" "150ms"
        ]


transition_shadow : Css.Style
transition_shadow =
    Css.batch
        [ Css.property "transition-property" "box-shadow"
        , Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"
        , Css.property "transition-duration" "150ms"
        ]


transition_transform : Css.Style
transition_transform =
    Css.batch
        [ Css.property "transition-property" "transform"
        , Css.property "transition-timing-function" "cubic-bezier(0.4, 0, 0.2, 1)"
        , Css.property "transition-duration" "150ms"
        ]


translate_x_0 : Css.Style
translate_x_0 =
    Css.property "--tw-translate-x" "0px"


translate_x_0_dot_5 : Css.Style
translate_x_0_dot_5 =
    Css.property "--tw-translate-x" "0.125rem"


translate_x_1 : Css.Style
translate_x_1 =
    Css.property "--tw-translate-x" "0.25rem"


translate_x_10 : Css.Style
translate_x_10 =
    Css.property "--tw-translate-x" "2.5rem"


translate_x_11 : Css.Style
translate_x_11 =
    Css.property "--tw-translate-x" "2.75rem"


translate_x_12 : Css.Style
translate_x_12 =
    Css.property "--tw-translate-x" "3rem"


translate_x_14 : Css.Style
translate_x_14 =
    Css.property "--tw-translate-x" "3.5rem"


translate_x_16 : Css.Style
translate_x_16 =
    Css.property "--tw-translate-x" "4rem"


translate_x_1_dot_5 : Css.Style
translate_x_1_dot_5 =
    Css.property "--tw-translate-x" "0.375rem"


translate_x_1over2 : Css.Style
translate_x_1over2 =
    Css.property "--tw-translate-x" "50%"


translate_x_1over3 : Css.Style
translate_x_1over3 =
    Css.property "--tw-translate-x" "33.333333%"


translate_x_1over4 : Css.Style
translate_x_1over4 =
    Css.property "--tw-translate-x" "25%"


translate_x_2 : Css.Style
translate_x_2 =
    Css.property "--tw-translate-x" "0.5rem"


translate_x_20 : Css.Style
translate_x_20 =
    Css.property "--tw-translate-x" "5rem"


translate_x_24 : Css.Style
translate_x_24 =
    Css.property "--tw-translate-x" "6rem"


translate_x_28 : Css.Style
translate_x_28 =
    Css.property "--tw-translate-x" "7rem"


translate_x_2_dot_5 : Css.Style
translate_x_2_dot_5 =
    Css.property "--tw-translate-x" "0.625rem"


translate_x_2over3 : Css.Style
translate_x_2over3 =
    Css.property "--tw-translate-x" "66.666667%"


translate_x_2over4 : Css.Style
translate_x_2over4 =
    Css.property "--tw-translate-x" "50%"


translate_x_3 : Css.Style
translate_x_3 =
    Css.property "--tw-translate-x" "0.75rem"


translate_x_32 : Css.Style
translate_x_32 =
    Css.property "--tw-translate-x" "8rem"


translate_x_36 : Css.Style
translate_x_36 =
    Css.property "--tw-translate-x" "9rem"


translate_x_3_dot_5 : Css.Style
translate_x_3_dot_5 =
    Css.property "--tw-translate-x" "0.875rem"


translate_x_3over4 : Css.Style
translate_x_3over4 =
    Css.property "--tw-translate-x" "75%"


translate_x_4 : Css.Style
translate_x_4 =
    Css.property "--tw-translate-x" "1rem"


translate_x_40 : Css.Style
translate_x_40 =
    Css.property "--tw-translate-x" "10rem"


translate_x_44 : Css.Style
translate_x_44 =
    Css.property "--tw-translate-x" "11rem"


translate_x_48 : Css.Style
translate_x_48 =
    Css.property "--tw-translate-x" "12rem"


translate_x_5 : Css.Style
translate_x_5 =
    Css.property "--tw-translate-x" "1.25rem"


translate_x_52 : Css.Style
translate_x_52 =
    Css.property "--tw-translate-x" "13rem"


translate_x_56 : Css.Style
translate_x_56 =
    Css.property "--tw-translate-x" "14rem"


translate_x_6 : Css.Style
translate_x_6 =
    Css.property "--tw-translate-x" "1.5rem"


translate_x_60 : Css.Style
translate_x_60 =
    Css.property "--tw-translate-x" "15rem"


translate_x_64 : Css.Style
translate_x_64 =
    Css.property "--tw-translate-x" "16rem"


translate_x_7 : Css.Style
translate_x_7 =
    Css.property "--tw-translate-x" "1.75rem"


translate_x_72 : Css.Style
translate_x_72 =
    Css.property "--tw-translate-x" "18rem"


translate_x_8 : Css.Style
translate_x_8 =
    Css.property "--tw-translate-x" "2rem"


translate_x_80 : Css.Style
translate_x_80 =
    Css.property "--tw-translate-x" "20rem"


translate_x_9 : Css.Style
translate_x_9 =
    Css.property "--tw-translate-x" "2.25rem"


translate_x_96 : Css.Style
translate_x_96 =
    Css.property "--tw-translate-x" "24rem"


translate_x_full : Css.Style
translate_x_full =
    Css.property "--tw-translate-x" "100%"


translate_x_px : Css.Style
translate_x_px =
    Css.property "--tw-translate-x" "1px"


translate_y_0 : Css.Style
translate_y_0 =
    Css.property "--tw-translate-y" "0px"


translate_y_0_dot_5 : Css.Style
translate_y_0_dot_5 =
    Css.property "--tw-translate-y" "0.125rem"


translate_y_1 : Css.Style
translate_y_1 =
    Css.property "--tw-translate-y" "0.25rem"


translate_y_10 : Css.Style
translate_y_10 =
    Css.property "--tw-translate-y" "2.5rem"


translate_y_11 : Css.Style
translate_y_11 =
    Css.property "--tw-translate-y" "2.75rem"


translate_y_12 : Css.Style
translate_y_12 =
    Css.property "--tw-translate-y" "3rem"


translate_y_14 : Css.Style
translate_y_14 =
    Css.property "--tw-translate-y" "3.5rem"


translate_y_16 : Css.Style
translate_y_16 =
    Css.property "--tw-translate-y" "4rem"


translate_y_1_dot_5 : Css.Style
translate_y_1_dot_5 =
    Css.property "--tw-translate-y" "0.375rem"


translate_y_1over2 : Css.Style
translate_y_1over2 =
    Css.property "--tw-translate-y" "50%"


translate_y_1over3 : Css.Style
translate_y_1over3 =
    Css.property "--tw-translate-y" "33.333333%"


translate_y_1over4 : Css.Style
translate_y_1over4 =
    Css.property "--tw-translate-y" "25%"


translate_y_2 : Css.Style
translate_y_2 =
    Css.property "--tw-translate-y" "0.5rem"


translate_y_20 : Css.Style
translate_y_20 =
    Css.property "--tw-translate-y" "5rem"


translate_y_24 : Css.Style
translate_y_24 =
    Css.property "--tw-translate-y" "6rem"


translate_y_28 : Css.Style
translate_y_28 =
    Css.property "--tw-translate-y" "7rem"


translate_y_2_dot_5 : Css.Style
translate_y_2_dot_5 =
    Css.property "--tw-translate-y" "0.625rem"


translate_y_2over3 : Css.Style
translate_y_2over3 =
    Css.property "--tw-translate-y" "66.666667%"


translate_y_2over4 : Css.Style
translate_y_2over4 =
    Css.property "--tw-translate-y" "50%"


translate_y_3 : Css.Style
translate_y_3 =
    Css.property "--tw-translate-y" "0.75rem"


translate_y_32 : Css.Style
translate_y_32 =
    Css.property "--tw-translate-y" "8rem"


translate_y_36 : Css.Style
translate_y_36 =
    Css.property "--tw-translate-y" "9rem"


translate_y_3_dot_5 : Css.Style
translate_y_3_dot_5 =
    Css.property "--tw-translate-y" "0.875rem"


translate_y_3over4 : Css.Style
translate_y_3over4 =
    Css.property "--tw-translate-y" "75%"


translate_y_4 : Css.Style
translate_y_4 =
    Css.property "--tw-translate-y" "1rem"


translate_y_40 : Css.Style
translate_y_40 =
    Css.property "--tw-translate-y" "10rem"


translate_y_44 : Css.Style
translate_y_44 =
    Css.property "--tw-translate-y" "11rem"


translate_y_48 : Css.Style
translate_y_48 =
    Css.property "--tw-translate-y" "12rem"


translate_y_5 : Css.Style
translate_y_5 =
    Css.property "--tw-translate-y" "1.25rem"


translate_y_52 : Css.Style
translate_y_52 =
    Css.property "--tw-translate-y" "13rem"


translate_y_56 : Css.Style
translate_y_56 =
    Css.property "--tw-translate-y" "14rem"


translate_y_6 : Css.Style
translate_y_6 =
    Css.property "--tw-translate-y" "1.5rem"


translate_y_60 : Css.Style
translate_y_60 =
    Css.property "--tw-translate-y" "15rem"


translate_y_64 : Css.Style
translate_y_64 =
    Css.property "--tw-translate-y" "16rem"


translate_y_7 : Css.Style
translate_y_7 =
    Css.property "--tw-translate-y" "1.75rem"


translate_y_72 : Css.Style
translate_y_72 =
    Css.property "--tw-translate-y" "18rem"


translate_y_8 : Css.Style
translate_y_8 =
    Css.property "--tw-translate-y" "2rem"


translate_y_80 : Css.Style
translate_y_80 =
    Css.property "--tw-translate-y" "20rem"


translate_y_9 : Css.Style
translate_y_9 =
    Css.property "--tw-translate-y" "2.25rem"


translate_y_96 : Css.Style
translate_y_96 =
    Css.property "--tw-translate-y" "24rem"


translate_y_full : Css.Style
translate_y_full =
    Css.property "--tw-translate-y" "100%"


translate_y_px : Css.Style
translate_y_px =
    Css.property "--tw-translate-y" "1px"


truncate : Css.Style
truncate =
    Css.batch
        [ Css.property "overflow" "hidden"
        , Css.property "text-overflow" "ellipsis"
        , Css.property "white-space" "nowrap"
        ]


underline : Css.Style
underline =
    Css.property "text-decoration" "underline"


uppercase : Css.Style
uppercase =
    Css.property "text-transform" "uppercase"


via_black : Css.Style
via_black =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #000, var(--tw-gradient-to, rgba(0, 0, 0, 0))"


via_blue_100 : Css.Style
via_blue_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #dbeafe, var(--tw-gradient-to, rgba(219, 234, 254, 0))"


via_blue_200 : Css.Style
via_blue_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #bfdbfe, var(--tw-gradient-to, rgba(191, 219, 254, 0))"


via_blue_300 : Css.Style
via_blue_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #93c5fd, var(--tw-gradient-to, rgba(147, 197, 253, 0))"


via_blue_400 : Css.Style
via_blue_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #60a5fa, var(--tw-gradient-to, rgba(96, 165, 250, 0))"


via_blue_50 : Css.Style
via_blue_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #eff6ff, var(--tw-gradient-to, rgba(239, 246, 255, 0))"


via_blue_500 : Css.Style
via_blue_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #3b82f6, var(--tw-gradient-to, rgba(59, 130, 246, 0))"


via_blue_600 : Css.Style
via_blue_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #2563eb, var(--tw-gradient-to, rgba(37, 99, 235, 0))"


via_blue_700 : Css.Style
via_blue_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #1d4ed8, var(--tw-gradient-to, rgba(29, 78, 216, 0))"


via_blue_800 : Css.Style
via_blue_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #1e40af, var(--tw-gradient-to, rgba(30, 64, 175, 0))"


via_blue_900 : Css.Style
via_blue_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #1e3a8a, var(--tw-gradient-to, rgba(30, 58, 138, 0))"


via_current : Css.Style
via_current =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), currentColor, var(--tw-gradient-to, rgba(255, 255, 255, 0))"


via_gray_100 : Css.Style
via_gray_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f3f4f6, var(--tw-gradient-to, rgba(243, 244, 246, 0))"


via_gray_200 : Css.Style
via_gray_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #e5e7eb, var(--tw-gradient-to, rgba(229, 231, 235, 0))"


via_gray_300 : Css.Style
via_gray_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #d1d5db, var(--tw-gradient-to, rgba(209, 213, 219, 0))"


via_gray_400 : Css.Style
via_gray_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #9ca3af, var(--tw-gradient-to, rgba(156, 163, 175, 0))"


via_gray_50 : Css.Style
via_gray_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f9fafb, var(--tw-gradient-to, rgba(249, 250, 251, 0))"


via_gray_500 : Css.Style
via_gray_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #6b7280, var(--tw-gradient-to, rgba(107, 114, 128, 0))"


via_gray_600 : Css.Style
via_gray_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #4b5563, var(--tw-gradient-to, rgba(75, 85, 99, 0))"


via_gray_700 : Css.Style
via_gray_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #374151, var(--tw-gradient-to, rgba(55, 65, 81, 0))"


via_gray_800 : Css.Style
via_gray_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #1f2937, var(--tw-gradient-to, rgba(31, 41, 55, 0))"


via_gray_900 : Css.Style
via_gray_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #111827, var(--tw-gradient-to, rgba(17, 24, 39, 0))"


via_green_100 : Css.Style
via_green_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #d1fae5, var(--tw-gradient-to, rgba(209, 250, 229, 0))"


via_green_200 : Css.Style
via_green_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #a7f3d0, var(--tw-gradient-to, rgba(167, 243, 208, 0))"


via_green_300 : Css.Style
via_green_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #6ee7b7, var(--tw-gradient-to, rgba(110, 231, 183, 0))"


via_green_400 : Css.Style
via_green_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #34d399, var(--tw-gradient-to, rgba(52, 211, 153, 0))"


via_green_50 : Css.Style
via_green_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #ecfdf5, var(--tw-gradient-to, rgba(236, 253, 245, 0))"


via_green_500 : Css.Style
via_green_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #10b981, var(--tw-gradient-to, rgba(16, 185, 129, 0))"


via_green_600 : Css.Style
via_green_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #059669, var(--tw-gradient-to, rgba(5, 150, 105, 0))"


via_green_700 : Css.Style
via_green_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #047857, var(--tw-gradient-to, rgba(4, 120, 87, 0))"


via_green_800 : Css.Style
via_green_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #065f46, var(--tw-gradient-to, rgba(6, 95, 70, 0))"


via_green_900 : Css.Style
via_green_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #064e3b, var(--tw-gradient-to, rgba(6, 78, 59, 0))"


via_indigo_100 : Css.Style
via_indigo_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #e0e7ff, var(--tw-gradient-to, rgba(224, 231, 255, 0))"


via_indigo_200 : Css.Style
via_indigo_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #c7d2fe, var(--tw-gradient-to, rgba(199, 210, 254, 0))"


via_indigo_300 : Css.Style
via_indigo_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #a5b4fc, var(--tw-gradient-to, rgba(165, 180, 252, 0))"


via_indigo_400 : Css.Style
via_indigo_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #818cf8, var(--tw-gradient-to, rgba(129, 140, 248, 0))"


via_indigo_50 : Css.Style
via_indigo_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #eef2ff, var(--tw-gradient-to, rgba(238, 242, 255, 0))"


via_indigo_500 : Css.Style
via_indigo_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #6366f1, var(--tw-gradient-to, rgba(99, 102, 241, 0))"


via_indigo_600 : Css.Style
via_indigo_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #4f46e5, var(--tw-gradient-to, rgba(79, 70, 229, 0))"


via_indigo_700 : Css.Style
via_indigo_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #4338ca, var(--tw-gradient-to, rgba(67, 56, 202, 0))"


via_indigo_800 : Css.Style
via_indigo_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #3730a3, var(--tw-gradient-to, rgba(55, 48, 163, 0))"


via_indigo_900 : Css.Style
via_indigo_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #312e81, var(--tw-gradient-to, rgba(49, 46, 129, 0))"


via_pink_100 : Css.Style
via_pink_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fce7f3, var(--tw-gradient-to, rgba(252, 231, 243, 0))"


via_pink_200 : Css.Style
via_pink_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fbcfe8, var(--tw-gradient-to, rgba(251, 207, 232, 0))"


via_pink_300 : Css.Style
via_pink_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f9a8d4, var(--tw-gradient-to, rgba(249, 168, 212, 0))"


via_pink_400 : Css.Style
via_pink_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f472b6, var(--tw-gradient-to, rgba(244, 114, 182, 0))"


via_pink_50 : Css.Style
via_pink_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fdf2f8, var(--tw-gradient-to, rgba(253, 242, 248, 0))"


via_pink_500 : Css.Style
via_pink_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #ec4899, var(--tw-gradient-to, rgba(236, 72, 153, 0))"


via_pink_600 : Css.Style
via_pink_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #db2777, var(--tw-gradient-to, rgba(219, 39, 119, 0))"


via_pink_700 : Css.Style
via_pink_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #be185d, var(--tw-gradient-to, rgba(190, 24, 93, 0))"


via_pink_800 : Css.Style
via_pink_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #9d174d, var(--tw-gradient-to, rgba(157, 23, 77, 0))"


via_pink_900 : Css.Style
via_pink_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #831843, var(--tw-gradient-to, rgba(131, 24, 67, 0))"


via_purple_100 : Css.Style
via_purple_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #ede9fe, var(--tw-gradient-to, rgba(237, 233, 254, 0))"


via_purple_200 : Css.Style
via_purple_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #ddd6fe, var(--tw-gradient-to, rgba(221, 214, 254, 0))"


via_purple_300 : Css.Style
via_purple_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #c4b5fd, var(--tw-gradient-to, rgba(196, 181, 253, 0))"


via_purple_400 : Css.Style
via_purple_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #a78bfa, var(--tw-gradient-to, rgba(167, 139, 250, 0))"


via_purple_50 : Css.Style
via_purple_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f5f3ff, var(--tw-gradient-to, rgba(245, 243, 255, 0))"


via_purple_500 : Css.Style
via_purple_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #8b5cf6, var(--tw-gradient-to, rgba(139, 92, 246, 0))"


via_purple_600 : Css.Style
via_purple_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #7c3aed, var(--tw-gradient-to, rgba(124, 58, 237, 0))"


via_purple_700 : Css.Style
via_purple_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #6d28d9, var(--tw-gradient-to, rgba(109, 40, 217, 0))"


via_purple_800 : Css.Style
via_purple_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #5b21b6, var(--tw-gradient-to, rgba(91, 33, 182, 0))"


via_purple_900 : Css.Style
via_purple_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #4c1d95, var(--tw-gradient-to, rgba(76, 29, 149, 0))"


via_red_100 : Css.Style
via_red_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fee2e2, var(--tw-gradient-to, rgba(254, 226, 226, 0))"


via_red_200 : Css.Style
via_red_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fecaca, var(--tw-gradient-to, rgba(254, 202, 202, 0))"


via_red_300 : Css.Style
via_red_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fca5a5, var(--tw-gradient-to, rgba(252, 165, 165, 0))"


via_red_400 : Css.Style
via_red_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f87171, var(--tw-gradient-to, rgba(248, 113, 113, 0))"


via_red_50 : Css.Style
via_red_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fef2f2, var(--tw-gradient-to, rgba(254, 242, 242, 0))"


via_red_500 : Css.Style
via_red_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #ef4444, var(--tw-gradient-to, rgba(239, 68, 68, 0))"


via_red_600 : Css.Style
via_red_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #dc2626, var(--tw-gradient-to, rgba(220, 38, 38, 0))"


via_red_700 : Css.Style
via_red_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #b91c1c, var(--tw-gradient-to, rgba(185, 28, 28, 0))"


via_red_800 : Css.Style
via_red_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #991b1b, var(--tw-gradient-to, rgba(153, 27, 27, 0))"


via_red_900 : Css.Style
via_red_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #7f1d1d, var(--tw-gradient-to, rgba(127, 29, 29, 0))"


via_transparent : Css.Style
via_transparent =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), transparent, var(--tw-gradient-to, rgba(0, 0, 0, 0))"


via_white : Css.Style
via_white =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fff, var(--tw-gradient-to, rgba(255, 255, 255, 0))"


via_yellow_100 : Css.Style
via_yellow_100 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fef3c7, var(--tw-gradient-to, rgba(254, 243, 199, 0))"


via_yellow_200 : Css.Style
via_yellow_200 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fde68a, var(--tw-gradient-to, rgba(253, 230, 138, 0))"


via_yellow_300 : Css.Style
via_yellow_300 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fcd34d, var(--tw-gradient-to, rgba(252, 211, 77, 0))"


via_yellow_400 : Css.Style
via_yellow_400 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fbbf24, var(--tw-gradient-to, rgba(251, 191, 36, 0))"


via_yellow_50 : Css.Style
via_yellow_50 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #fffbeb, var(--tw-gradient-to, rgba(255, 251, 235, 0))"


via_yellow_500 : Css.Style
via_yellow_500 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #f59e0b, var(--tw-gradient-to, rgba(245, 158, 11, 0))"


via_yellow_600 : Css.Style
via_yellow_600 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #d97706, var(--tw-gradient-to, rgba(217, 119, 6, 0))"


via_yellow_700 : Css.Style
via_yellow_700 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #b45309, var(--tw-gradient-to, rgba(180, 83, 9, 0))"


via_yellow_800 : Css.Style
via_yellow_800 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #92400e, var(--tw-gradient-to, rgba(146, 64, 14, 0))"


via_yellow_900 : Css.Style
via_yellow_900 =
    Css.property "--tw-gradient-stops" "var(--tw-gradient-from), #78350f, var(--tw-gradient-to, rgba(120, 53, 15, 0))"


visible : Css.Style
visible =
    Css.property "visibility" "visible"


w_0 : Css.Style
w_0 =
    Css.property "width" "0px"


w_0_dot_5 : Css.Style
w_0_dot_5 =
    Css.property "width" "0.125rem"


w_1 : Css.Style
w_1 =
    Css.property "width" "0.25rem"


w_10 : Css.Style
w_10 =
    Css.property "width" "2.5rem"


w_10over12 : Css.Style
w_10over12 =
    Css.property "width" "83.333333%"


w_11 : Css.Style
w_11 =
    Css.property "width" "2.75rem"


w_11over12 : Css.Style
w_11over12 =
    Css.property "width" "91.666667%"


w_12 : Css.Style
w_12 =
    Css.property "width" "3rem"


w_14 : Css.Style
w_14 =
    Css.property "width" "3.5rem"


w_16 : Css.Style
w_16 =
    Css.property "width" "4rem"


w_1_dot_5 : Css.Style
w_1_dot_5 =
    Css.property "width" "0.375rem"


w_1over12 : Css.Style
w_1over12 =
    Css.property "width" "8.333333%"


w_1over2 : Css.Style
w_1over2 =
    Css.property "width" "50%"


w_1over3 : Css.Style
w_1over3 =
    Css.property "width" "33.333333%"


w_1over4 : Css.Style
w_1over4 =
    Css.property "width" "25%"


w_1over5 : Css.Style
w_1over5 =
    Css.property "width" "20%"


w_1over6 : Css.Style
w_1over6 =
    Css.property "width" "16.666667%"


w_2 : Css.Style
w_2 =
    Css.property "width" "0.5rem"


w_20 : Css.Style
w_20 =
    Css.property "width" "5rem"


w_24 : Css.Style
w_24 =
    Css.property "width" "6rem"


w_28 : Css.Style
w_28 =
    Css.property "width" "7rem"


w_2_dot_5 : Css.Style
w_2_dot_5 =
    Css.property "width" "0.625rem"


w_2over12 : Css.Style
w_2over12 =
    Css.property "width" "16.666667%"


w_2over3 : Css.Style
w_2over3 =
    Css.property "width" "66.666667%"


w_2over4 : Css.Style
w_2over4 =
    Css.property "width" "50%"


w_2over5 : Css.Style
w_2over5 =
    Css.property "width" "40%"


w_2over6 : Css.Style
w_2over6 =
    Css.property "width" "33.333333%"


w_3 : Css.Style
w_3 =
    Css.property "width" "0.75rem"


w_32 : Css.Style
w_32 =
    Css.property "width" "8rem"


w_36 : Css.Style
w_36 =
    Css.property "width" "9rem"


w_3_dot_5 : Css.Style
w_3_dot_5 =
    Css.property "width" "0.875rem"


w_3over12 : Css.Style
w_3over12 =
    Css.property "width" "25%"


w_3over4 : Css.Style
w_3over4 =
    Css.property "width" "75%"


w_3over5 : Css.Style
w_3over5 =
    Css.property "width" "60%"


w_3over6 : Css.Style
w_3over6 =
    Css.property "width" "50%"


w_4 : Css.Style
w_4 =
    Css.property "width" "1rem"


w_40 : Css.Style
w_40 =
    Css.property "width" "10rem"


w_44 : Css.Style
w_44 =
    Css.property "width" "11rem"


w_48 : Css.Style
w_48 =
    Css.property "width" "12rem"


w_4over12 : Css.Style
w_4over12 =
    Css.property "width" "33.333333%"


w_4over5 : Css.Style
w_4over5 =
    Css.property "width" "80%"


w_4over6 : Css.Style
w_4over6 =
    Css.property "width" "66.666667%"


w_5 : Css.Style
w_5 =
    Css.property "width" "1.25rem"


w_52 : Css.Style
w_52 =
    Css.property "width" "13rem"


w_56 : Css.Style
w_56 =
    Css.property "width" "14rem"


w_5over12 : Css.Style
w_5over12 =
    Css.property "width" "41.666667%"


w_5over6 : Css.Style
w_5over6 =
    Css.property "width" "83.333333%"


w_6 : Css.Style
w_6 =
    Css.property "width" "1.5rem"


w_60 : Css.Style
w_60 =
    Css.property "width" "15rem"


w_64 : Css.Style
w_64 =
    Css.property "width" "16rem"


w_6over12 : Css.Style
w_6over12 =
    Css.property "width" "50%"


w_7 : Css.Style
w_7 =
    Css.property "width" "1.75rem"


w_72 : Css.Style
w_72 =
    Css.property "width" "18rem"


w_7over12 : Css.Style
w_7over12 =
    Css.property "width" "58.333333%"


w_8 : Css.Style
w_8 =
    Css.property "width" "2rem"


w_80 : Css.Style
w_80 =
    Css.property "width" "20rem"


w_8over12 : Css.Style
w_8over12 =
    Css.property "width" "66.666667%"


w_9 : Css.Style
w_9 =
    Css.property "width" "2.25rem"


w_96 : Css.Style
w_96 =
    Css.property "width" "24rem"


w_9over12 : Css.Style
w_9over12 =
    Css.property "width" "75%"


w_auto : Css.Style
w_auto =
    Css.property "width" "auto"


w_full : Css.Style
w_full =
    Css.property "width" "100%"


w_max : Css.Style
w_max =
    Css.property "width" "max-content"


w_min : Css.Style
w_min =
    Css.property "width" "min-content"


w_px : Css.Style
w_px =
    Css.property "width" "1px"


w_screen : Css.Style
w_screen =
    Css.property "width" "100vw"


whitespace_normal : Css.Style
whitespace_normal =
    Css.property "white-space" "normal"


whitespace_nowrap : Css.Style
whitespace_nowrap =
    Css.property "white-space" "nowrap"


whitespace_pre : Css.Style
whitespace_pre =
    Css.property "white-space" "pre"


whitespace_pre_line : Css.Style
whitespace_pre_line =
    Css.property "white-space" "pre-line"


whitespace_pre_wrap : Css.Style
whitespace_pre_wrap =
    Css.property "white-space" "pre-wrap"


z_0 : Css.Style
z_0 =
    Css.property "z-index" "0"


z_10 : Css.Style
z_10 =
    Css.property "z-index" "10"


z_20 : Css.Style
z_20 =
    Css.property "z-index" "20"


z_30 : Css.Style
z_30 =
    Css.property "z-index" "30"


z_40 : Css.Style
z_40 =
    Css.property "z-index" "40"


z_50 : Css.Style
z_50 =
    Css.property "z-index" "50"


z_auto : Css.Style
z_auto =
    Css.property "z-index" "auto"
