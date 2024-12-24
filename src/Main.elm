module Main exposing (main)

import Array exposing (Array)
import Base
import Browser
import Browser.Dom
import Browser.Events as Events
import Browser.Navigation as Nav
import Element exposing (Element, centerX, padding, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Task
import Url



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , device : Element.Device
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , url = url
      , device = { class = Element.Phone, orientation = Element.Portrait }
      }
    , Cmd.batch
        [ Nav.pushUrl key "#"
        , Task.perform GotViewport Browser.Dom.getViewport
        ]
    )



-- UPDATE


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | GotViewport Browser.Dom.Viewport
    | SetScreenSize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        GotViewport viewport ->
            ( { model
                | device =
                    Element.classifyDevice
                        { width = floor viewport.viewport.width
                        , height = floor viewport.viewport.height
                        }
              }
            , Cmd.none
            )

        SetScreenSize width height ->
            ( { model
                | device =
                    Element.classifyDevice
                        { width = width
                        , height = height
                        }
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Events.onResize SetScreenSize ]



-- VIEW


black : Element.Color
black =
    Element.rgb255 0 0 0


cardinal : Element.Color
cardinal =
    Element.rgb255 196 30 58


white : Element.Color
white =
    Element.rgb255 255 255 255


bluegreen : Element.Color
bluegreen =
    Element.rgb255 8 143 143


crimson : Element.Color
crimson =
    Element.rgb255 129 65 65


darkgreen : Element.Color
darkgreen =
    Element.rgb255 2 48 32


grey : Element.Color
grey =
    Element.rgb255 128 128 128


view : Model -> Browser.Document Msg
view model =
    { title = "UTS Booking QR Code Generator"
    , body =
        [ Element.column
            [ centerX
            , padding 20
            , Element.spacing 20
            , Region.mainContent
            ]
            [ viewHeader model.device
            , viewFooter
            ]
            |> Element.layout []
        ]
    }


viewHeader : Element.Device -> Element Msg
viewHeader device =
    let
        attrs =
            [ Element.spacing 5
            , Element.padding 20
            , Element.centerX
            ]

        children =
            [ Element.image [ Element.centerX ]
                { src = "favicon-96x96.png"
                , description = "Logo"
                }
            , text "UTS Booking QR Code Generator"
                |> Element.el
                    [ Region.heading 1
                    , Font.size 24
                    , Font.bold
                    , Font.color black
                    ]
            ]
    in
    case device.class of
        Element.Phone ->
            Element.column attrs children

        _ ->
            Element.row attrs children


viewFooter : Element Msg
viewFooter =
    let
        linkAttrs =
            [ Font.color darkgreen
            , Font.underline
            ]
    in
    Element.column
        [ Region.footer
        , Element.spacing 5
        , Element.padding 20
        , Font.size 14
        , Font.color grey
        , Font.light
        ]
        [ Element.row []
            [ text "Made with ❤️ by "
            , Element.newTabLink
                linkAttrs
                { url = "https://devhuman.net"
                , label = text "Ananth"
                }
            , text "."
            ]
        , Element.row []
            [ text "View the source at "
            , Element.newTabLink
                linkAttrs
                { url = "https://github.com/ananthb/uts-qr"
                , label = text "github.com/ananthb/uts-qr"
                }
            , text "."
            ]
        ]
