port module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Http
import Task
import Json.Decode exposing
    ( Decoder
    , field
    , string
    , int
    , map2
    , map3
    , map4
    , map6
    , list
    , float
    , maybe
    )


main : Program (Maybe Model) Model Msg
main =
    Browser.document
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = \model -> { title = "LambdaLingo", body = [view model] }
        }


-- Model


type alias Model = 
    { loading: Bool
    , error: Maybe String
    , playbackRate: Float
    , inverted: Bool
    , admin: Bool
    , activePage: Int
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
    { path: String
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
    , activePage = 0
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotData result ->
            case result of
                Ok data ->
                    ( { model
                        | loading = False
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
                    div []
                        [ h3 [] [ text "Tracks" ]
                        , ul [] (List.map viewTrack model.tracks)
                        ]


viewTrack : Track -> Html Msg
viewTrack track =
    li [] [ text track.title ]


-- HTTP


getData : Cmd Msg
getData =
  Http.get
    { url = "/courses/vietnamese/fsi/data.json"
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
    map4 Page
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
