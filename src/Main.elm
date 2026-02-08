module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Events as Events
import Browser.Navigation as Nav
import Element exposing (Element, centerX, fill, padding, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Task
import Url
import Url.Builder
import Url.Parser exposing (Parser)
import Url.Parser.Query as Query



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
    , name : String
    , code : String
    , latitude : String
    , longitude : String
    }


type alias QueryParams =
    { name : Maybe String
    , code : Maybe String
    , latitude : Maybe String
    , longitude : Maybe String
    }


parseQuery : Url.Url -> QueryParams
parseQuery url =
    let
        parser =
            Query.map4 QueryParams
                (Query.string "name")
                (Query.string "code")
                (Query.string "latitude")
                (Query.string "longitude")

        -- Url.Parser needs a path, so we parse from the root with query
        fullParser =
            Url.Parser.query parser
    in
    -- Parse the URL, treating the query string
    Url.Parser.parse fullParser { url | path = "" }
        |> Maybe.withDefault (QueryParams Nothing Nothing Nothing Nothing)


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        params =
            parseQuery url
    in
    ( { key = key
      , url = url
      , device = { class = Element.Phone, orientation = Element.Portrait }
      , name = Maybe.withDefault "" params.name
      , code = Maybe.withDefault "" params.code
      , latitude = Maybe.withDefault "" params.latitude
      , longitude = Maybe.withDefault "" params.longitude
      }
    , Task.perform GotViewport Browser.Dom.getViewport
    )



-- UPDATE


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | GotViewport Browser.Dom.Viewport
    | SetScreenSize Int Int
    | SetName String
    | SetCode String
    | SetLatitude String
    | SetLongitude String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            let
                params =
                    parseQuery url
            in
            ( { model
                | url = url
                , name = Maybe.withDefault model.name params.name
                , code = Maybe.withDefault model.code params.code
                , latitude = Maybe.withDefault model.latitude params.latitude
                , longitude = Maybe.withDefault model.longitude params.longitude
              }
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

        SetScreenSize w h ->
            ( { model
                | device =
                    Element.classifyDevice
                        { width = w
                        , height = h
                        }
              }
            , Cmd.none
            )

        SetName name ->
            let
                newModel =
                    { model | name = name }
            in
            ( newModel, updateUrl newModel )

        SetCode code ->
            let
                newModel =
                    { model | code = code }
            in
            ( newModel, updateUrl newModel )

        SetLatitude latitude ->
            let
                newModel =
                    { model | latitude = latitude }
            in
            ( newModel, updateUrl newModel )

        SetLongitude longitude ->
            let
                newModel =
                    { model | longitude = longitude }
            in
            ( newModel, updateUrl newModel )


updateUrl : Model -> Cmd Msg
updateUrl model =
    let
        queryParams =
            List.filterMap identity
                [ if String.isEmpty model.name then
                    Nothing

                  else
                    Just (Url.Builder.string "name" model.name)
                , if String.isEmpty model.code then
                    Nothing

                  else
                    Just (Url.Builder.string "code" model.code)
                , if String.isEmpty model.latitude then
                    Nothing

                  else
                    Just (Url.Builder.string "latitude" model.latitude)
                , if String.isEmpty model.longitude then
                    Nothing

                  else
                    Just (Url.Builder.string "longitude" model.longitude)
                ]

        newUrl =
            Url.Builder.relative [] queryParams
    in
    Nav.replaceUrl model.key newUrl



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Events.onResize SetScreenSize



-- VIEW


black : Element.Color
black =
    Element.rgb255 0 0 0


darkgreen : Element.Color
darkgreen =
    Element.rgb255 2 48 32


grey : Element.Color
grey =
    Element.rgb255 128 128 128


lightgrey : Element.Color
lightgrey =
    Element.rgb255 240 240 240


view : Model -> Browser.Document Msg
view model =
    { title = "UTS Booking QR Code Generator"
    , body =
        [ Element.column
            [ centerX
            , padding 20
            , Element.spacing 20
            , Region.mainContent
            , width (Element.maximum 600 fill)
            ]
            [ viewHeader model.device
            , viewDisclaimer
            , viewForm model
            , viewQrCode model
            , viewFooter
            ]
            |> Element.layout []
        ]
    }


viewHeader : Element.Device -> Element Msg
viewHeader device =
    let
        attrs =
            [ Element.spacing 10
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
                    , Font.center
                    ]
            ]
    in
    case device.class of
        Element.Phone ->
            Element.column attrs children

        _ ->
            Element.row attrs children


viewDisclaimer : Element Msg
viewDisclaimer =
    Element.paragraph
        [ Background.color (Element.rgb255 255 243 205)
        , Border.rounded 4
        , Border.width 1
        , Border.color (Element.rgb255 255 193 7)
        , padding 15
        , Font.size 14
        , Font.color (Element.rgb255 133 100 4)
        , width fill
        ]
        [ text "Disclaimer: The QR codes generated are only for representative purposes. This app is purely for educational purposes." ]


viewForm : Model -> Element Msg
viewForm model =
    let
        inputStyle =
            [ Border.width 1
            , Border.color grey
            , Border.rounded 4
            , padding 10
            , width fill
            , Background.color lightgrey
            ]

        labelStyle =
            [ Font.size 14
            , Font.color darkgreen
            ]
    in
    Element.column
        [ Element.spacing 15
        , width fill
        ]
        [ Input.text inputStyle
            { onChange = SetName
            , text = model.name
            , placeholder = Just (Input.placeholder [] (text "e.g. MUMBAI CENTRAL"))
            , label = Input.labelAbove labelStyle (text "Station Name")
            }
        , Input.text inputStyle
            { onChange = SetCode
            , text = model.code
            , placeholder = Just (Input.placeholder [] (text "e.g. BCT"))
            , label = Input.labelAbove labelStyle (text "Station Code")
            }
        , Input.text inputStyle
            { onChange = SetLatitude
            , text = model.latitude
            , placeholder = Just (Input.placeholder [] (text "e.g. 18.9690"))
            , label = Input.labelAbove labelStyle (text "Latitude")
            }
        , Input.text inputStyle
            { onChange = SetLongitude
            , text = model.longitude
            , placeholder = Just (Input.placeholder [] (text "e.g. 72.8193"))
            , label = Input.labelAbove labelStyle (text "Longitude")
            }
        ]


viewQrCode : Model -> Element Msg
viewQrCode model =
    let
        hasAllParams =
            not (String.isEmpty model.name)
                && not (String.isEmpty model.code)
                && not (String.isEmpty model.latitude)
                && not (String.isEmpty model.longitude)
    in
    if hasAllParams then
        let
            qrUrl =
                Url.Builder.absolute [ "genqr" ]
                    [ Url.Builder.string "name" model.name
                    , Url.Builder.string "code" model.code
                    , Url.Builder.string "latitude" model.latitude
                    , Url.Builder.string "longitude" model.longitude
                    ]
        in
        Element.column
            [ Element.spacing 10
            , centerX
            , padding 20
            ]
            [ Element.image
                [ Element.width (Element.px 200)
                , Element.height (Element.px 200)
                , centerX
                ]
                { src = qrUrl
                , description = "QR Code for " ++ model.name ++ " (" ++ model.code ++ ")"
                }
            , Element.paragraph
                [ Font.size 12
                , Font.color grey
                , Font.center
                , centerX
                ]
                [ text ("Scan this QR code in the UTS app to book tickets from " ++ model.name ++ ".") ]
            ]

    else
        Element.paragraph
            [ Font.size 14
            , Font.color grey
            , Font.center
            , padding 20
            ]
            [ text "Fill in all fields above to generate a QR code." ]


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
        , centerX
        ]
        [ Element.row [ centerX ]
            [ text "Made with ❤️ by "
            , Element.newTabLink
                linkAttrs
                { url = "https://devhuman.net"
                , label = text "Ananth"
                }
            , text "."
            ]
        , Element.row [ centerX ]
            [ text "View the source at "
            , Element.newTabLink
                linkAttrs
                { url = "https://github.com/ananthb/uts-qr"
                , label = text "github.com/ananthb/uts-qr"
                }
            , text "."
            ]
        ]
