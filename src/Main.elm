port module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Json.Decode as Json
import Task


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
    { playbackRate: Float
    , inverted: Bool
    , admin: Bool
    , activePage: Int
    , scrollEnabled: Bool
    , allPages: List String
    , allTracks: List Track
    , bookmarks: List Bookmark
    , pageHeights: List Float
    , sizePointers: List Pointer
    , addingAnchor: Bool
    , addingTextAnchor: Bool
    , removingAnchor: Bool
    , movingAnchor: Bool
    , activeTrack: Int
    , anchors: List PageAnchors
    }


type alias Track =
    { title: String
    , path: String
    }


type alias Bookmark =
    { title: String
    , index: Int
    }


type alias Pointer =
    { page: Int
    , height: Float
    }


type alias PageAnchors =
    { page: Int
    , anchors: List Anchor
    }

type alias Anchor =
    { id: String
    , track: String
    , time: Float
    , top: Float
    , left: Float
    , text: Maybe String
    }


emptyModel : Model
emptyModel =
    { playbackRate = 1
    , inverted = False
    , admin = False
    , activePage = 0
    , scrollEnabled = True
    , allPages = []
    , allTracks = []
    , bookmarks = []
    , pageHeights = []
    , sizePointers = []
    , addingAnchor = False
    , addingTextAnchor = False
    , removingAnchor = False
    , movingAnchor = False
    , activeTrack = 0
    , anchors = []
    }


init : Maybe Model -> ( Model, Cmd Msg )
init maybeModel =
  ( Maybe.withDefault emptyModel maybeModel
  , Cmd.none
  )


-- Update


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


-- View


view : Model -> Html Msg
view model =
    div [] []
