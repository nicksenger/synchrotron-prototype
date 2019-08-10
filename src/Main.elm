port module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Http
import Ports
import String
import Task
import Json.Decode exposing
    ( Decoder
    , field
    , string
    , int
    , map
    , map2
    , map3
    , map5
    , map6
    , list
    , float
    , maybe
    )


main : Program (Maybe Model) Model Msg
main =
    Browser.document
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = \model -> { title = "Synchrotron", body = [view model] }
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.receiveScrollData ReceiveScrollDataFromJS


-- Model


type alias Model = 
    { loading: Bool
    , error: Maybe String
    , playbackRate: Float
    , inverted: Bool
    , admin: Bool
    , activePage: Maybe Page
    , scrollEnabled: Bool
    , addingAnchor: Bool
    , addingTextAnchor: Bool
    , removingAnchor: Bool
    , movingAnchor: Bool
    , activeTrack: Int
    , bookmarks: List Bookmark
    , pages: List Page
    , tracks: List Track
    }


type alias Track =
    { title: String
    , path: String
    }


type alias Bookmark =
    { title: String
    , page: Int
    }


type alias Pointer =
    { page: Int
    , height: Float
    }


type alias Page =
    { number: Int
    , path: String
    , aspectRatio: Float
    , height: Float
    , anchors: List Anchor
    }

type alias Anchor =
    { id: String
    , track: Int
    , time: Float
    , top: Float
    , left: Float
    , text: Maybe String
    }


emptyModel : Model
emptyModel =
    { loading = True
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


init : Maybe Model -> ( Model, Cmd Msg )
init maybeModel =
  ( Maybe.withDefault emptyModel maybeModel
  , getData
  )


-- Update


type Msg
    = GotData (Result Http.Error InputData)
    | ReceiveScrollDataFromJS Float
    | Invert
    | SelectBookmark String


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
                n = String.toInt s
                newActivePage =
                    case n of
                        Just i ->
                            List.head (List.filter (isPage i) model.pages)
                        
                        Nothing ->
                            Nothing

                activeHeight =
                    case newActivePage of
                        Just p ->
                            p.height
                        
                        Nothing ->
                            0

                aspectRatio =
                    case newActivePage of
                        Just p ->
                            p.aspectRatio
                        
                        Nothing ->
                            0
            in
            ( { model
                | activePage = newActivePage
            }
            , Ports.sendActiveHeight activeHeight
            )


isPage: Int -> Page -> Bool
isPage n p =
    p.number == n


closestToHeight: Float -> Page -> Page -> Order
closestToHeight rh a b =
    case compare (abs (a.height - rh)) (abs(b.height - rh)) of
        LT -> LT
        EQ -> EQ
        GT -> GT


-- View


view : Model -> Html Msg
view model =
    case model.loading of
        True ->
            text "Loading..."

        False ->
            case model.error of
                Just a ->
                    text a
                Nothing ->
                    mainView model

mainView : Model -> Html Msg
mainView model =
    div
        [ class "fsi__inner" ]
        [ pagesView model
        , menuView model
        ]


pagesView : Model -> Html Msg
pagesView model =
    div
        [ id "page-container"
        , class "fsi__page-container"
        ]
        (List.indexedMap (pageView model) model.pages)


pageView : Model -> Int -> Page -> Html Msg
pageView model idx page =
    div
        [ id (String.fromInt idx)
        , class (getPageClass model.inverted)
        , style "padding-top" (String.concat [String.fromFloat (page.aspectRatio * 100), "%"])
        , value (String.fromInt idx)
        ]
        [ img
            [ class (getImageClass model.inverted)
            , src (getPageUri page model.activePage)
            ]
            []
        ]


getPageClass : Bool -> String
getPageClass i =
    if i then
        "page__container page__container--inverted"
    else
        "page__container"


getPageUri : Page -> Maybe Page -> String
getPageUri page activePage =
    case activePage of
        Just p ->
            if (abs (p.number - page.number)) < 3 then
                page.path
            else
                "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs="

        Nothing ->
            "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs="


getImageClass : Bool -> String
getImageClass i =
    if i then
        "page__image page__image--inverted"
    else
        "page__image"


menuView : Model -> Html Msg
menuView model =
    div
        [ class "fsi__menu" ]
        [ invertButtonView model.inverted
        , audioView model
        , bookmarksView model
        ]

invertButtonView : Bool -> Html Msg
invertButtonView i =
    if i then
        button
            [ class "fsi__button fsi__button--inverted"
            , onClick Invert ]
            [ text "Light Mode" ]
    else
        button
            [ class "fsi__button"
            , onClick Invert ]
            [ text "Dark Mode" ]


audioView : Model -> Html Msg
audioView model =
    audio
        [ id "audio"
        , class (getAudioViewClass model.inverted)
        , src "courses/vietnamese/dli/audio/1.mp3"
        , controls True
        ]
        []


getAudioViewClass : Bool -> String
getAudioViewClass i =
    if i then 
        "fsi__audio fsi__audio--inverted"
    else
        "fsi__audio"


bookmarksView : Model -> Html Msg
bookmarksView model =
    select
        [ class (getBookmarksViewclass model.inverted)
        , onInput SelectBookmark
        ]
        (List.map bookmarkView model.bookmarks)


getBookmarksViewclass : Bool -> String
getBookmarksViewclass i =
    if i then
        "fsi__dropdown fsi__dropdown--inverted"
    else
        "fsi__dropdown"


bookmarkView : Bookmark -> Html Msg
bookmarkView b =
    option
        [ value (String.fromInt b.page)
        , title b.title
        ]
        [ text b.title ]


-- HTTP


getData : Cmd Msg
getData =
  Http.get
    { url = "/courses/vietnamese/dli/data.json"
    , expect = Http.expectJson GotData inputDataDecoder
    }


type alias InputData =
    { bookmarks: List Bookmark
    , pages: List Page
    , tracks: List Track
    }


inputDataDecoder : Decoder InputData
inputDataDecoder =
    map3 InputData
        (field "bookmarks" (list bookmarkDecoder))
        (field "pages" (list pageDecoder))
        (field "tracks" (list trackDecoder))


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
        (field "anchors" (list anchorDecoder))


anchorDecoder : Decoder Anchor
anchorDecoder =
    map6 Anchor
        (field "id" string)
        (field "track" int)
        (field "time" float)
        (field "top" float)
        (field "left" float)
        (maybe (field "text" string))


trackDecoder : Decoder Track
trackDecoder =
    map2 Track
        (field "title" string)
        (field "path" string)
