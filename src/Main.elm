module Main exposing (main)

import Browser
import Browser.Navigation
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Decode.Field as Field
import Json.Encode as Encode
import Maybe.Extra
import Process
import Regex
import Task
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query


type alias Query =
    { fulltext : List String
    , must : List ( String, String )
    , mustNot : List ( String, String )
    , comparisons : List ( String, Comparison, Int )
    }


type QueryPart
    = Fulltext String
    | Must String String
    | MustNot String String
    | Comparison String Comparison Int


type alias Hit a =
    { id : String
    , score : Float
    , source : a
    }


type alias Document =
    { id : Int
    , category : Category
    , name : String
    , level : Maybe Int
    , type_ : String
    , traits : List String
    , breadcrumbs : Maybe String
    }


type Comparison
    = GT
    | GE
    | LT
    | LE


type alias Flags =
    ()


type Category
    = Equipment
    | Feat
    | Rules
    | Spell
    | Trait
    | Unknown


type Msg
    = NoOp
    | QueryChanged String
    | GotSearchResult (Result Http.Error (List (Hit Document)))
    | UrlRequested Browser.UrlRequest
    | DebouncePassed Int


type alias Model =
    { query : String
    , searchResult : Maybe (Result Http.Error (List (Hit Document)))
    , navKey : Browser.Navigation.Key
    , debounce : Int
    , url : Url
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = \_ -> NoOp
        }


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        query =
            url
                |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string "q"))
                |> Maybe.Extra.join
                |> Maybe.withDefault ""
    in
    ( { query = query
      , searchResult = Nothing
      , navKey = navKey
      , debounce = 0
      , url = url
      }
    , if query /= "" then
        search query

      else
        Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        QueryChanged str ->
            if String.isEmpty str then
                ( { model
                    | query = str
                    , searchResult = Nothing
                  }
                , setQueryParam "" model.url
                    |> Url.toString
                    |> Browser.Navigation.pushUrl model.navKey
                )

            else
                ( { model
                    | query = str
                    , debounce = model.debounce + 1
                  }
                , Process.sleep 150
                    |> Task.perform (\_ -> DebouncePassed (model.debounce + 1))
                )

        DebouncePassed debounce ->
            if model.debounce == debounce then
                ( model
                , Cmd.batch
                    [ search model.query
                    , setQueryParam model.query model.url
                        |> Url.toString
                        |> Browser.Navigation.pushUrl model.navKey
                    ]
                )
            else
                ( model, Cmd.none )

        GotSearchResult result ->
            -- let
            --     _ = Debug.log "result" result
            -- in
            ( { model | searchResult = Just result }
            , Cmd.none
            )

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Browser.Navigation.load url
                    )


parseQueryParts : String -> List QueryPart
parseQueryParts str =
    List.map
        (\part ->
            if String.contains ">=" part then
                case String.split ">=" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field GE int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains "<=" part then
                case String.split "<=" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field LE int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains ">" part then
                case String.split ">" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field GT int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains "<" part then
                case String.split "<" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field LT int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains "=" part then
                case String.split "=" part of
                    [ field, value ] ->
                        Must field value

                    _ ->
                        Fulltext part

            else
                Fulltext part
        )
        (String.split " " str)


buildQuery : List QueryPart -> Query
buildQuery parts =
    List.foldl
        (\part query ->
            case part of
                Fulltext str ->
                    { query | fulltext = List.append query.fulltext [str] }

                Must field value ->
                    { query | must =  ( field, value ) :: query.must }

                MustNot field value ->
                    { query | mustNot = ( field, value ) :: query.mustNot }

                Comparison field operator value ->
                    { query | comparisons = ( field, operator, value ) :: query.comparisons }

        )
        { fulltext = []
        , must = []
        , mustNot = []
        , comparisons = []
        }
        parts


setQueryParam : String -> Url -> Url
setQueryParam value url =
    { url
        | query =
            if value /= "" then
                Just ("q=" ++ Url.percentEncode value)

            else
                Nothing
    }


search : String -> Cmd Msg
search queryString =
    let
        query =
            parseQueryParts queryString
                |> buildQuery
                |> Debug.log "query"
    in
    Http.request
        { method = "POST"
        , url = "http://localhost:9200/aon/_search"
        , headers = []
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "query"
                      , Encode.object
                            [ ( "bool"
                              , encodeObjectMaybe
                                    [ Just
                                        ( "must"
                                        , Encode.object
                                            [ ( "multi_match"
                                              , Encode.object
                                                    [ ( "query", Encode.string (String.join " " query.fulltext) )
                                                    , ( "fuzziness", Encode.string "auto" )
                                                    , ( "type", Encode.string "most_fields" )
                                                    , ( "fields"
                                                      , Encode.list
                                                            Encode.string
                                                            [ "*"
                                                            , "description^0.2"
                                                            , "type^4"
                                                            , "name^5"
                                                            , "traits^2"
                                                            ]
                                                      )
                                                    ]
                                              )
                                            ]
                                        )

                                    , if List.isEmpty query.must && List.isEmpty query.comparisons then
                                        Nothing

                                      else
                                        Just
                                            ( "filter"
                                            , Encode.list Encode.object
                                                (List.append
                                                    (List.map
                                                        (\( field, value ) ->
                                                            ( "term"
                                                            , Encode.object [ ( field, Encode.string value ) ]
                                                            )
                                                        )
                                                        query.must
                                                    )
                                                    (List.map
                                                        (\( field, comparison, value ) ->
                                                            ( "range"
                                                            , Encode.object
                                                                [ ( field
                                                                  , Encode.object
                                                                        [ ( comparisonToString comparison, Encode.int value ) ]
                                                                  )
                                                                ]
                                                            )
                                                        )
                                                        query.comparisons
                                                    )
                                                    |> List.map List.singleton
                                                )
                                            )

                                    , if List.isEmpty query.mustNot then
                                        Nothing

                                      else
                                        Just
                                            ( "must_not"
                                            , Encode.list Encode.object
                                                (List.map
                                                      (\( field, value ) ->
                                                          ( "term"
                                                          , Encode.object [ ( field, Encode.string value ) ]
                                                          )
                                                      )
                                                      query.mustNot
                                                      |> List.map List.singleton
                                                )
                                            )
                                    ]
                              )
                            ]
                      )
                    , ( "size", Encode.int 100 )
                    ]
                )
        , expect = Http.expectJson GotSearchResult esResultDecoder
        , timeout = Just 10000
        , tracker = Nothing
        }


encodeObjectMaybe : List (Maybe ( String, Encode.Value )) -> Encode.Value
encodeObjectMaybe list =
    List.filterMap identity list
        |> Encode.object


esResultDecoder : Decode.Decoder (List (Hit Document))
esResultDecoder =
    Decode.at [ "hits", "hits" ] (Decode.list (hitDecoder documentDecoder))


hitDecoder : Decode.Decoder a -> Decode.Decoder (Hit a)
hitDecoder decoder =
    Field.require "_id" Decode.string <| \id ->
    Field.require "_score" Decode.float <| \score ->
    Field.require "_source" decoder <| \source ->
    Decode.succeed
        { id = id
        , score = score
        , source = source
        }


documentDecoder : Decode.Decoder Document
documentDecoder =
    Field.require "id" Decode.int <| \id ->
    Field.require "category" categoryDecoder <| \category ->
    Field.require "name" Decode.string <| \name ->
    Field.require "type" Decode.string <| \type_ ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "traits" (Decode.list Decode.string) <| \maybeTraits ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Decode.succeed
        { id = id
        , category = category
        , type_ = type_
        , name = name
        , level = level
        , traits = Maybe.withDefault [] maybeTraits
        , breadcrumbs = breadcrumbs
        }


categoryDecoder : Decode.Decoder Category
categoryDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "equipment" ->
                        Decode.succeed Equipment

                    "feat" ->
                        Decode.succeed Feat

                    "spell" ->
                        Decode.succeed Spell

                    "rules" ->
                        Decode.succeed Rules

                    "trait" ->
                        Decode.succeed Trait

                    _ ->
                        Decode.succeed Unknown
            )


getUrl : Document -> String
getUrl doc =
    case doc.category of
        Equipment ->
            buildUrl "Equipment" doc.id

        Feat ->
            buildUrl "Feats" doc.id

        Rules ->
            buildUrl "Rules" doc.id

        Spell ->
            buildUrl "Spells" doc.id

        Trait ->
            buildUrl "Traits" doc.id

        Unknown ->
            ""


buildUrl : String -> Int -> String
buildUrl category id =
    "https://2e.aonprd.com/" ++ category ++ ".aspx?ID=" ++ String.fromInt id


comparisonToString : Comparison -> String
comparisonToString comparison =
    case comparison of
        GT -> "gt"
        GE -> "gte"
        LT -> "lt"
        LE -> "lte"


view : Model -> Browser.Document Msg
view model =
    { title = "AoN Search"
    , body =
        [ Html.div
            []
            [ Html.text "Search"
            , Html.input
                [ HE.onInput QueryChanged
                , HA.value model.query
                , HA.style "width" "90%"
                ]
                [ Html.text model.query ]
            ]
        , case model.searchResult of
            Just (Ok hits) ->
                Html.ul
                    []
                    (List.map
                        (\hit ->
                            Html.li
                                [ HA.style "display" "block"
                                , HA.style "margin-bottom" "5px"
                                ]
                                [ Html.a
                                    [ HA.href (getUrl hit.source)
                                    , HA.target "_blank"
                                    ]
                                    [ Html.text hit.source.name ]
                                , Html.div
                                    []
                                    [ Html.text hit.source.type_
                                    , Html.text " "
                                    , case hit.source.level of
                                        Just level ->
                                            Html.text (String.fromInt level)

                                        Nothing ->
                                            Html.text ""
                                    , if List.isEmpty hit.source.traits then
                                        Html.text ""

                                      else
                                        Html.span
                                            []
                                            [ Html.text " - "
                                            , Html.span
                                                []
                                                (List.map
                                                    (\trait ->
                                                        Html.text ("[" ++ trait ++ "] ")
                                                    )
                                                    hit.source.traits
                                                )
                                            ]
                                    , case hit.source.breadcrumbs of
                                        Just breadcrumbs ->
                                            Html.span
                                                []
                                                [ Html.text " - "
                                                , Html.text breadcrumbs
                                                ]

                                        Nothing ->
                                            Html.text ""
                                    ]
                                ]
                        )
                        hits
                    )

            _ ->
                Html.text ""
        ]
    }
