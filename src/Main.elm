module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode
    exposing
        ( Decoder
        , field
        , float
        , int
        , list
        , map
        , map2
        , map3
        , map5
        , map6
        , maybe
        , string
        )
import Ports
import String
import Svg
import Svg.Attributes


main : Program ( String, String ) Model Msg
main =
    Browser.document
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = \model -> { title = model.title, body = [ view model ] }
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.receiveScrollData ReceiveScrollDataFromJS



-- Model


type alias Model =
    { title : String
    , dataPath : String
    , loading : Bool
    , error : Maybe String
    , playbackRate : Float
    , inverted : Bool
    , admin : Bool
    , activePage : Maybe Page
    , scrollEnabled : Bool
    , addingAnchor : Bool
    , addingTextAnchor : Bool
    , removingAnchor : Bool
    , movingAnchor : Bool
    , activeTrack : Int
    , bookmarks : List Bookmark
    , pages : List Page
    , tracks : List Track
    }


type alias Track =
    { number : Int
    , title : String
    , path : String
    }


type alias Bookmark =
    { title : String
    , page : Int
    }


type alias Pointer =
    { page : Int
    , height : Float
    }


type alias Page =
    { number : Int
    , path : String
    , aspectRatio : Float
    , height : Float
    , anchors : List Anchor
    }


type alias Anchor =
    { id : String
    , track : Int
    , time : Float
    , top : Float
    , left : Float
    , text : Maybe String
    }


emptyModel : Model
emptyModel =
    { title = "Synchrotron"
    , dataPath = ""
    , loading = True
    , error = Nothing
    , playbackRate = 1
    , inverted = False
    , admin = False
    , activePage = Nothing
    , scrollEnabled = True
    , addingAnchor = False
    , addingTextAnchor = False
    , removingAnchor = False
    , movingAnchor = False
    , activeTrack = 0
    , bookmarks = []
    , pages = []
    , tracks = []
    }


init : ( String, String ) -> ( Model, Cmd Msg )
init ( path, title ) =
    let
        model =
            { emptyModel
                | title = title
                , dataPath = path
            }
    in
    ( model
    , getData model
    )



-- Update


type Msg
    = GotData (Result Http.Error InputData)
    | ReceiveScrollDataFromJS Float
    | Invert
    | SelectBookmark String
    | SelectAnchor Anchor


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotData result ->
            case result of
                Ok data ->
                    ( { model
                        | loading = False
                        , activePage = List.head data.pages
                        , bookmarks = data.bookmarks
                        , pages = data.pages
                        , tracks = data.tracks
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model
                        | loading = False
                        , error = Just "Failed."
                      }
                    , Cmd.none
                    )

        ReceiveScrollDataFromJS rh ->
            ( { model
                | activePage = List.head (List.sortWith (closestToHeight rh) model.pages)
              }
            , Cmd.none
            )

        Invert ->
            ( { model
                | inverted = not model.inverted
              }
            , Cmd.none
            )

        SelectBookmark s ->
            let
                n =
                    String.toInt s

                newActivePage =
                    case n of
                        Just i ->
                            List.head (List.filter (matchingPage i) model.pages)

                        Nothing ->
                            Nothing

                activeHeight =
                    case newActivePage of
                        Just p ->
                            p.height

                        Nothing ->
                            0
            in
            ( { model
                | activePage = newActivePage
              }
            , Ports.sendActiveHeight activeHeight
            )

        SelectAnchor a ->
            let
                track =
                    List.head <| List.filter (matchingTrack a.track) model.tracks

                path =
                    case track of
                        Just t ->
                            t.path

                        Nothing ->
                            ""
            in
            ( model
            , Cmd.batch
                [ Ports.sendPlayback (Ports.PlaybackCommand path a.time model.playbackRate)
                , Ports.sendPath a.id
                ]
            )


matchingPage : Int -> Page -> Bool
matchingPage n p =
    p.number == n


matchingTrack : Int -> Track -> Bool
matchingTrack n t =
    t.number == n


closestToHeight : Float -> Page -> Page -> Order
closestToHeight rh a b =
    case compare (abs <| a.height - rh) (abs <| b.height - rh) of
        LT ->
            LT

        EQ ->
            EQ

        GT ->
            GT



-- HTTP


getData : Model -> Cmd Msg
getData model =
    Http.get
        { url = model.dataPath
        , expect = Http.expectJson GotData inputDataDecoder
        }


type alias InputData =
    { bookmarks : List Bookmark
    , pages : List Page
    , tracks : List Track
    }


inputDataDecoder : Decoder InputData
inputDataDecoder =
    map3 InputData
        (field "bookmarks" <| list bookmarkDecoder)
        (field "pages" <| list pageDecoder)
        (field "tracks" <| list trackDecoder)


bookmarkDecoder : Decoder Bookmark
bookmarkDecoder =
    map2 Bookmark
        (field "title" string)
        (field "page" int)


pageDecoder : Decoder Page
pageDecoder =
    map5 Page
        (field "number" int)
        (field "path" string)
        (field "aspectRatio" float)
        (field "height" float)
        (field "anchors" <| list anchorDecoder)


anchorDecoder : Decoder Anchor
anchorDecoder =
    map6 Anchor
        (field "id" string)
        (field "track" int)
        (field "time" float)
        (field "top" float)
        (field "left" float)
        (maybe <| field "text" string)


trackDecoder : Decoder Track
trackDecoder =
    map3 Track
        (field "number" int)
        (field "title" string)
        (field "path" string)



-- View


view : Model -> Html Msg
view model =
    if model.loading then
        text "Loading..."

    else
        case model.error of
            Just a ->
                text a

            Nothing ->
                mainView model


mainView : Model -> Html Msg
mainView model =
    div
        [ class "synchrotron__inner" ]
        [ pagesView model
        , menuView model
        ]


pagesView : Model -> Html Msg
pagesView model =
    div
        [ id "page-container"
        , class "synchrotron__page-container"
        ]
        (List.indexedMap (pageView model) model.pages)


pageView : Model -> Int -> Page -> Html Msg
pageView model idx page =
    div
        [ id (String.fromInt idx)
        , class <| getInvertedClass "page__container" model.inverted
        , style "padding-top" <| String.concat [ String.fromFloat (page.aspectRatio * 100), "%" ]
        , value (String.fromInt idx)
        ]
        (img
            [ class <| getInvertedClass "page__image" model.inverted
            , src (getPageUri page model.activePage)
            ]
            []
            :: List.map (anchorView model.inverted) page.anchors
        )


getPageUri : Page -> Maybe Page -> String
getPageUri page activePage =
    case activePage of
        Just p ->
            if (abs <| p.number - page.number) < 3 then
                page.path

            else
                "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs="

        Nothing ->
            "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs="


anchorView : Bool -> Anchor -> Html Msg
anchorView _ anchor =
    case anchor.text of
        Just s ->
            a
                [ style "top" <| "calc(" ++ String.fromFloat anchor.top ++ "% - 10px)"
                , style "left" <| String.fromFloat anchor.left ++ "%"
                , attribute "id" anchor.id
                , onClick <| SelectAnchor anchor
                ]
                [ text s ]

        Nothing ->
            div
                [ style "top" <| String.fromFloat anchor.top ++ "%"
                , style "left" <| String.fromFloat anchor.left ++ "%"
                , attribute "id" anchor.id
                , onClick <| SelectAnchor anchor
                ]
                [ Svg.svg
                    [ width 100
                    , height 100
                    ]
                    [ Svg.path
                        [ Svg.Attributes.d "M10,10 L90,10 L90,90" ]
                        []
                    ]
                ]


menuView : Model -> Html Msg
menuView model =
    div
        [ class "synchrotron__menu" ]
        [ invertButtonView model.inverted
        , audioView model
        , bookmarksView model
        ]


invertButtonView : Bool -> Html Msg
invertButtonView i =
    if i then
        button
            [ class "synchrotron__button synchrotron__button--inverted"
            , onClick Invert
            ]
            [ text "Light Mode" ]

    else
        button
            [ class "synchrotron__button"
            , onClick Invert
            ]
            [ text "Dark Mode" ]


audioView : Model -> Html Msg
audioView model =
    audio
        [ id "audio"
        , class <| getInvertedClass "synchrotron__audio" model.inverted
        , controls True
        ]
        []


bookmarksView : Model -> Html Msg
bookmarksView model =
    select
        [ class <| getInvertedClass "synchrotron__dropdown" model.inverted
        , onInput SelectBookmark
        ]
        (List.map bookmarkView model.bookmarks)


bookmarkView : Bookmark -> Html Msg
bookmarkView b =
    option
        [ value (String.fromInt b.page)
        , title b.title
        ]
        [ text b.title ]


getInvertedClass : String -> Bool -> String
getInvertedClass class i =
    if i then
        class ++ " " ++ class ++ "--inverted"

    else
        class
