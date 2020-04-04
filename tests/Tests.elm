module Tests exposing (..)

import Expect
import Fuzz
import Http
import Main
    exposing
        ( Anchor
        , Bookmark
        , InputData
        , Msg(..)
        , Page
        , Track
        , closestToHeight
        , emptyModel
        , getData
        , getInvertedClass
        , init
        , matchingPage
        , matchingTrack
        , update
        )
import Ports
import String
import Test exposing (..)
import Tuple exposing (first, second)


initializationFuzzer : Fuzz.Fuzzer ( String, String )
initializationFuzzer =
    Fuzz.tuple ( Fuzz.string, Fuzz.string )


suite =
    describe "Main"
        [ describe "init"
            [ fuzz initializationFuzzer "should pass the title and path to the model" <|
                \( a, b ) ->
                    ( a, b )
                        |> init
                        |> first
                        |> Expect.equal
                            { emptyModel
                                | title = b
                                , dataPath = a
                            }
            ]
        , describe "getInvertedClass"
            [ fuzz Fuzz.string "should be the input string if not inverted" <|
                \s ->
                    False
                        |> getInvertedClass s
                        |> Expect.equal
                            s
            , fuzz Fuzz.string "should be the proper inverted BEM class if inverted" <|
                \s ->
                    True
                        |> getInvertedClass s
                        |> Expect.equal
                            (s ++ " " ++ s ++ "--inverted")
            ]
        , describe "closestToHeight"
            [ test "should be GT if the first page is closer" <|
                \_ ->
                    Page 12 "" 1 5.0 []
                        |> closestToHeight 6.0 (Page 13 "" 1 8.0 [])
                        |> Expect.equal
                            GT
            , test "should be LT if the second page is closer" <|
                \_ ->
                    Page 13 "" 1 8.0 []
                        |> closestToHeight 6.0 (Page 12 "" 1 5.0 [])
                        |> Expect.equal
                            LT
            ]
        , describe "matchingPage"
            [ fuzz Fuzz.int "should be True if the page number matches" <|
                \n ->
                    Page n "" 1.0 1.0 []
                        |> matchingPage n
                        |> Expect.equal
                            True
            , fuzz Fuzz.int "should be False if the page number doesn't match" <|
                \n ->
                    Page n "" 1.0 1.0 []
                        |> matchingPage (n - 4)
                        |> Expect.equal
                            False
            ]
        , describe "matchingTrack"
            [ fuzz Fuzz.int "should be True if the track number matches" <|
                \n ->
                    Track n "" ""
                        |> matchingTrack n
                        |> Expect.equal
                            True
            , fuzz Fuzz.int "should be False if the track number doesn't match" <|
                \n ->
                    Track n "" ""
                        |> matchingTrack (n - 4)
                        |> Expect.equal
                            False
            ]
        , describe "update"
            [ describe "GotData"
                [ describe "the request fails"
                    [ test "should have no side effects" <|
                        \_ ->
                            emptyModel
                                |> update (GotData (Result.Err (Http.BadUrl "")))
                                |> second
                                |> Expect.equal
                                    Cmd.none
                    , test "should set loading and error state" <|
                        \_ ->
                            emptyModel
                                |> update (GotData (Result.Err (Http.BadUrl "")))
                                |> first
                                |> Expect.equal
                                    { emptyModel
                                        | loading = False
                                        , error = Just "Failed."
                                    }
                    ]
                , describe "the request succeeds"
                    [ test "should have no side effects" <|
                        \_ ->
                            emptyModel
                                |> update (GotData <| Result.Ok <| InputData [] [] [])
                                |> second
                                |> Expect.equal
                                    Cmd.none
                    , test "should set the loading state" <|
                        \_ ->
                            emptyModel
                                |> update (GotData <| Result.Ok <| InputData [] [] [])
                                |> first
                                |> Expect.equal
                                    { emptyModel
                                        | loading = False
                                    }
                    , test "should set the bookmarks" <|
                        \_ ->
                            emptyModel
                                |> update (GotData <| Result.Ok <| InputData [ Bookmark "foo" 1 ] [] [])
                                |> first
                                |> Expect.equal
                                    { emptyModel
                                        | loading = False
                                        , bookmarks = [ Bookmark "foo" 1 ]
                                    }
                    , test "should set the pages & active page" <|
                        \_ ->
                            emptyModel
                                |> update (GotData <| Result.Ok <| InputData [] [ Page 1 "" 1.0 1.0 [] ] [])
                                |> first
                                |> Expect.equal
                                    { emptyModel
                                        | loading = False
                                        , activePage = Just <| Page 1 "" 1.0 1.0 []
                                        , pages = [ Page 1 "" 1.0 1.0 [] ]
                                    }
                    , test "should set the tracks" <|
                        \_ ->
                            emptyModel
                                |> update (GotData <| Result.Ok <| InputData [] [] [ Track 1 "bar" "baz" ])
                                |> first
                                |> Expect.equal
                                    { emptyModel
                                        | loading = False
                                        , tracks = [ Track 1 "bar" "baz" ]
                                    }
                    ]
                ]
            , describe "ReceiveScrollDataFromJS"
                [ test "should have no side effects" <|
                    \_ ->
                        emptyModel
                            |> update (ReceiveScrollDataFromJS 1.6)
                            |> second
                            |> Expect.equal
                                Cmd.none
                , test "should set the activePage equal to the closest page" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | pages =
                                        [ Page 1 "" 1.0 1.0 []
                                        , Page 2 "" 1.0 2.0 []
                                        , Page 3 "" 1.0 3.0 []
                                        ]
                                }
                        in
                        model
                            |> update (ReceiveScrollDataFromJS 1.6)
                            |> first
                            |> Expect.equal
                                { model
                                    | activePage = Just <| Page 2 "" 1.0 2.0 []
                                }
                , test "should set activePage to nothing if there are no pages" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | activePage = Just <| Page 2 "" 1.0 2.0 []
                                    , pages = []
                                }
                        in
                        model
                            |> update (ReceiveScrollDataFromJS 1.6)
                            |> first
                            |> Expect.equal
                                { model
                                    | activePage = Nothing
                                }
                ]
            , describe "Invert"
                [ test "should have no side effects" <|
                    \_ ->
                        emptyModel
                            |> update Invert
                            |> second
                            |> Expect.equal
                                Cmd.none
                , fuzz Fuzz.bool "should flip 'inverted' to False if True" <|
                    \b ->
                        let
                            model =
                                { emptyModel
                                    | inverted = b
                                }
                        in
                        model
                            |> update Invert
                            |> first
                            |> Expect.equal
                                { model
                                    | inverted = not b
                                }
                ]
            , describe "SelectBookmark"
                [ test "should send the new activeHeight to JS" <|
                    \_ ->
                        emptyModel
                            |> update (SelectBookmark "8")
                            |> second
                            |> Expect.equal
                                (Ports.sendActiveHeight 0)
                , fuzz Fuzz.int "should set the activePage if there's a match" <|
                    \n ->
                        let
                            model =
                                { emptyModel
                                    | pages = [ Page n "" 1.0 1.0 [] ]
                                }
                        in
                        model
                            |> update (SelectBookmark (String.fromInt n))
                            |> first
                            |> Expect.equal
                                { model
                                    | activePage = Just <| Page n "" 1.0 1.0 []
                                }
                , test "should set the activePage to nothing if there's no match" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | activePage = Just <| Page 8 "" 1.0 1.0 []
                                }
                        in
                        model
                            |> update (SelectBookmark "8")
                            |> first
                            |> Expect.equal
                                { model
                                    | activePage = Nothing
                                }
                ]
            , describe "SelectAnchor"
                [ fuzz Fuzz.float "should send the PlaybackCommand to JS" <|
                    \f ->
                        let
                            model =
                                { emptyModel
                                    | tracks = [ Track 12 "foo" "bar" ]
                                    , playbackRate = f
                                }
                        in
                        model
                            |> update (SelectAnchor <| Anchor "abc" 12 4.2 12.12 8.8 Nothing)
                            |> second
                            |> Expect.equal
                                (Cmd.batch <| [ Ports.sendPlayback <| Ports.PlaybackCommand "bar" 4.2 f, Ports.sendClipboard "abc" ])
                , test "should not alter the state" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | tracks = [ Track 12 "foo" "bar" ]
                                }
                        in
                        model
                            |> update (SelectAnchor <| Anchor "abc" 12 4.2 12.12 8.8 Nothing)
                            |> first
                            |> Expect.equal
                                model
                ]
            ]
        ]
