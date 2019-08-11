module Tests exposing (..)

import Expect
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
import Test exposing (..)
import Tuple exposing (first, second)


suite =
    describe "Main"
        [ describe "init"
            [ test "should pass the title and path to the model" <|
                \_ ->
                    ( "foo", "bar" )
                        |> init
                        |> first
                        |> Expect.equal
                            { emptyModel
                                | title = "bar"
                                , dataPath = "foo"
                            }
            ]
        , describe "getInvertedClass"
            [ test "should be the input string if not inverted" <|
                \_ ->
                    False
                        |> getInvertedClass "foobar"
                        |> Expect.equal
                            "foobar"
            , test "should be the proper inverted BEM class if inverted" <|
                \_ ->
                    True
                        |> getInvertedClass "foobar"
                        |> Expect.equal
                            ("foobar" ++ " " ++ "foobar" ++ "--inverted")
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
            [ test "should be True if the page number matches" <|
                \_ ->
                    Page 8 "" 1.0 1.0 []
                        |> matchingPage 8
                        |> Expect.equal
                            True
            , test "should be False if the page number doesn't match" <|
                \_ ->
                    Page 12 "" 1.0 1.0 []
                        |> matchingPage 8
                        |> Expect.equal
                            False
            ]
        , describe "matchingTrack"
            [ test "should be True if the track number matches" <|
                \_ ->
                    Track 8 "" ""
                        |> matchingTrack 8
                        |> Expect.equal
                            True
            , test "should be False if the track number doesn't match" <|
                \_ ->
                    Track 12 "" ""
                        |> matchingTrack 8
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
                , test "should flip 'inverted' to True if False" <|
                    \_ ->
                        emptyModel
                            |> update Invert
                            |> first
                            |> Expect.equal
                                { emptyModel
                                    | inverted = True
                                }
                , test "should flip 'inverted' to False if True" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | inverted = True
                                }
                        in
                        model
                            |> update Invert
                            |> first
                            |> Expect.equal
                                { model
                                    | inverted = False
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
                , test "should set the activePage if there's a match" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | pages = [ Page 8 "" 1.0 1.0 [] ]
                                }
                        in
                        model
                            |> update (SelectBookmark "8")
                            |> first
                            |> Expect.equal
                                { model
                                    | activePage = Just <| Page 8 "" 1.0 1.0 []
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
                [ test "should send the PlaybackCommand to JS" <|
                    \_ ->
                        let
                            model =
                                { emptyModel
                                    | tracks = [ Track 12 "foo" "bar" ]
                                }
                        in
                        model
                            |> update (SelectAnchor <| Anchor "abc" 12 4.2 12.12 8.8 Nothing)
                            |> second
                            |> Expect.equal
                                (Ports.sendPlayback <| Ports.PlaybackCommand "bar" 4.2 1)
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
