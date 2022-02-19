port module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Data
import FontAwesome.Attributes
import FontAwesome.Icon
import FontAwesome.Solid
import FontAwesome.Styles
import Html exposing (Html)
import Html.Attributes as HA
import Html.Attributes.Extra as HAE
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Decode.Field as Field
import Json.Encode as Encode
import List.Extra
import Maybe.Extra
import Process
import Regex
import Result.Extra
import Set exposing (Set)
import String.Extra
import Task
import Url exposing (Url)
import Url.Builder
import Url.Parser
import Url.Parser.Query


type alias SearchResult =
    { hits : List (Hit Document)
    , total : Int
    }


type alias Hit a =
    { id : String
    , score : Float
    , sort : Encode.Value
    , source : a
    }


type alias Document =
    { id : Int
    , category : String
    , name : String
    , type_ : String
    , url : String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , alignment : Maybe String
    , ammunition : Maybe String
    , area : Maybe String
    , aspect : Maybe String
    , breadcrumbs : Maybe String
    , bulk : Maybe String
    , cast : Maybe String
    , components : List String
    , cost : Maybe String
    , creatureFamily : Maybe String
    , damage : Maybe String
    , duration : Maybe String
    , familiarAbilities : List String
    , fort : Maybe Int
    , frequency : Maybe String
    , hands : Maybe String
    , heighten : List String
    , hp : Maybe Int
    , lessonType : Maybe String
    , level : Maybe Int
    , perception : Maybe Int
    , prerequisites : Maybe String
    , price : Maybe String
    , primaryCheck : Maybe String
    , range : Maybe String
    , ref : Maybe Int
    , reload : Maybe String
    , requiredAbilities : Maybe String
    , requirements : Maybe String
    , savingThrow : Maybe String
    , secondaryCasters : Maybe String
    , secondaryChecks : Maybe String
    , source : Maybe String
    , spellList : Maybe String
    , spoilers : Maybe String
    , targets : Maybe String
    , traditions : List String
    , traits : List String
    , trigger : Maybe String
    , usage : Maybe String
    , weaponCategory : Maybe String
    , weaponGroup : Maybe String
    , will : Maybe Int
    }


type alias Flags =
    { elasticUrl : String
    }


type QueryType
    = Standard
    | ElasticsearchQueryString


type SortDir
    = Asc
    | Desc


type SortField
    = AC
    | Bulk
    | Fortitude
    | HP
    | Level
    | Name
    | Perception
    | Price
    | Range
    | Reflex
    | Type
    | Will
    | Str
    | Dex
    | Con
    | Int
    | Wis
    | Cha


type Theme
    = Dark
    | Light
    | Paper


type Msg
    = DebouncePassed Int
    | GotQueryOptionsHeight Int
    | GotSearchResult (Result Http.Error SearchResult)
    | IncludeFilteredTraitsChanged Bool
    | IncludeFilteredTypesChanged Bool
    | LoadMorePressed
    | LocalStorageValueReceived Decode.Value
    | MenuOpenDelayPassed
    | NoOp
    | QueryChanged String
    | QueryTypeSelected QueryType
    | RemoveAllSortsPressed
    | RemoveAllTraitFiltersPressed
    | RemoveAllTypeFiltersPressed
    | SearchTraitsChanged String
    | SearchTypesChanged String
    | ScrollToTopPressed
    | ShowAdditionalInfoChanged Bool
    | ShowEqsHelpPressed Bool
    | ShowMenuPressed Bool
    | ShowQueryOptionsPressed Bool
    | ShowSpoilersChanged Bool
    | ShowTraitsChanged Bool
    | SortAdded SortField SortDir
    | SortRemoved SortField
    | ThemeSelected Theme
    | TraitFilterAdded String
    | TraitFilterRemoved String
    | TypeFilterAdded String
    | TypeFilterRemoved String
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | WindowResized Int Int


port localStorage_set : Encode.Value -> Cmd msg
port localStorage_get : String -> Cmd msg
port localStorage_receive : (Decode.Value -> msg) -> Sub msg


type alias Model =
    { debounce : Int
    , elasticUrl : String
    , eqsHelpOpen : Bool
    , filteredTraits : Set String
    , filteredTypes : Set String
    , includeFilteredTraits : Bool
    , includeFilteredTypes : Bool
    , menuOpen : Bool
    , navKey : Browser.Navigation.Key
    , overlayActive : Bool
    , query : String
    , queryOptionsHeight : Int
    , queryOptionsOpen : Bool
    , queryType : QueryType
    , searchResults : List (Result Http.Error SearchResult)
    , searchTraits : String
    , searchTypes : String
    , showResultAdditionalInfo : Bool
    , showResultSpoilers : Bool
    , showResultTraits : Bool
    , sort : List ( SortField, SortDir )
    , theme : Theme
    , tracker : Maybe Int
    , url : Url
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( { debounce = 0
      , elasticUrl = flags.elasticUrl
      , eqsHelpOpen = False
      , filteredTraits = Set.empty
      , filteredTypes = Set.empty
      , includeFilteredTraits = True
      , includeFilteredTypes = True
      , menuOpen = False
      , navKey = navKey
      , overlayActive = False
      , query = ""
      , queryOptionsHeight = 0
      , queryOptionsOpen = False
      , queryType = Standard
      , searchResults = []
      , searchTraits = ""
      , searchTypes = ""
      , sort = []
      , showResultAdditionalInfo = True
      , showResultSpoilers = True
      , showResultTraits = True
      , theme = Dark
      , tracker = Nothing
      , url = url
      }
        |> updateModelFromQueryString url
    , Cmd.batch
        [ localStorage_get "show-additional-info"
        , localStorage_get "show-spoilers"
        , localStorage_get "show-traits"
        , localStorage_get "theme"
        , getQueryOptionsHeight
        ]
    )
        |> searchWithCurrentQuery


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize WindowResized
        , localStorage_receive LocalStorageValueReceived
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DebouncePassed debounce ->
            if model.debounce == debounce then
                ( model
                , updateUrl model
                )

            else
                ( model, Cmd.none )

        GotQueryOptionsHeight height ->
            ( { model | queryOptionsHeight = height }
            , Cmd.none
            )

        GotSearchResult result ->
            ( { model
                | searchResults =
                    List.append
                        (List.filter Result.Extra.isOk model.searchResults)
                        [ result ]
                , tracker = Nothing
              }
            , Cmd.none
            )

        IncludeFilteredTraitsChanged value ->
            ( { model | includeFilteredTraits = value }
            , updateUrl { model | includeFilteredTraits = value }
            )

        IncludeFilteredTypesChanged value ->
            ( { model | includeFilteredTypes = value }
            , updateUrl { model | includeFilteredTypes = value }
            )

        LoadMorePressed ->
            ( model
            , Cmd.none
            )
                |> searchWithCurrentQuery

        LocalStorageValueReceived value ->
            ( case Decode.decodeValue (Decode.field "key" Decode.string) value of
                Ok "theme" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "dark" ->
                            { model | theme = Dark }

                        Ok "light" ->
                            { model | theme = Light }

                        Ok "paper" ->
                            { model | theme = Paper }

                        _ ->
                            model

                Ok "show-additional-info" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "1" ->
                            { model | showResultAdditionalInfo = True }

                        Ok "0" ->
                            { model | showResultAdditionalInfo = False }

                        _ ->
                            model

                Ok "show-spoilers" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "1" ->
                            { model | showResultSpoilers = True }

                        Ok "0" ->
                            { model | showResultSpoilers = False }

                        _ ->
                            model

                Ok "show-traits" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "1" ->
                            { model | showResultTraits = True }

                        Ok "0" ->
                            { model | showResultTraits = False }

                        _ ->
                            model

                _ ->
                    model
            , Cmd.none
            )

        MenuOpenDelayPassed ->
            ( { model | overlayActive = True }
            , Cmd.none
            )

        NoOp ->
            ( model
            , Cmd.none
            )

        QueryChanged str ->
            ( { model
                | query = str
                , debounce = model.debounce + 1
              }
            , Process.sleep 250
                |> Task.perform (\_ -> DebouncePassed (model.debounce + 1))
            )

        QueryTypeSelected queryType ->
            ( model
            , updateUrl { model | queryType = queryType }
            )

        RemoveAllSortsPressed ->
            ( model
            , updateUrl { model | sort = [] }
            )

        RemoveAllTraitFiltersPressed ->
            ( model
            , updateUrl { model | filteredTraits = Set.empty }
            )

        RemoveAllTypeFiltersPressed ->
            ( model
            , updateUrl { model | filteredTypes = Set.empty }
            )

        SearchTraitsChanged value ->
            ( { model | searchTraits = value }
            , getQueryOptionsHeight
            )

        SearchTypesChanged value ->
            ( { model | searchTypes = value }
            , getQueryOptionsHeight
            )

        ScrollToTopPressed  ->
            ( model
            , Task.perform (\_ -> NoOp) (Browser.Dom.setViewport 0 0)
            )

        ShowAdditionalInfoChanged value ->
            ( { model | showResultAdditionalInfo = value }
            , saveToLocalStorage
                "show-additional-info"
                (if value then "1" else "0")
            )

        ShowEqsHelpPressed show ->
            ( { model | eqsHelpOpen = show }
            , getQueryOptionsHeight
            )

        ShowMenuPressed show ->
            ( { model
                | menuOpen = show
                , overlayActive = False
              }
            , if show then
                Process.sleep 250
                    |> Task.perform (\_ -> MenuOpenDelayPassed)
              else
                Cmd.none
            )

        ShowQueryOptionsPressed show ->
            ( { model | queryOptionsOpen = show }
            , getQueryOptionsHeight
            )

        ShowSpoilersChanged value ->
            ( { model | showResultSpoilers = value }
            , saveToLocalStorage
                "show-spoilers"
                (if value then "1" else "0")
            )

        ShowTraitsChanged value ->
            ( { model | showResultTraits = value }
            , saveToLocalStorage
                "show-traits"
                (if value then "1" else "0")
            )

        SortAdded field dir ->
            ( model
            , updateUrl
                { model
                    | sort =
                        model.sort
                            |> List.filter (Tuple.first >> (/=) field)
                            |> (\list -> List.append list [ ( field, dir ) ])
                }
            )

        SortRemoved field ->
            ( model
            , updateUrl { model | sort = List.filter (Tuple.first >> (/=) field) model.sort }
            )

        ThemeSelected theme ->
            ( { model | theme = theme }
            , saveToLocalStorage
                "theme"
                (case theme of
                    Dark ->
                        "dark"

                    Light ->
                        "light"

                    Paper ->
                        "paper"
                )
            )

        TraitFilterAdded type_ ->
            let
                set =
                    Set.insert type_ model.filteredTraits
            in
            ( model
            , updateUrl { model | filteredTraits = set }
            )

        TraitFilterRemoved type_ ->
            let
                set =
                    Set.remove type_ model.filteredTraits
            in
            ( model
            , updateUrl { model | filteredTraits = set }
            )

        TypeFilterAdded type_ ->
            let
                set =
                    Set.insert type_ model.filteredTypes
            in
            ( model
            , updateUrl { model | filteredTypes = set }
            )

        TypeFilterRemoved type_ ->
            let
                set =
                    Set.remove type_ model.filteredTypes
            in
            ( model
            , updateUrl { model | filteredTypes = set }
            )

        UrlChanged url ->
            ( updateModelFromQueryString url model
            , Cmd.none
            )
                |> searchWithCurrentQuery

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

        WindowResized width height ->
            ( model
            , getQueryOptionsHeight
            )


getQueryOptionsHeight : Cmd Msg
getQueryOptionsHeight =
    Browser.Dom.getViewportOf "query-options-dummy"
        |> Task.map .scene
        |> Task.map .height
        |> Task.map round
        |> Task.attempt (Result.withDefault 0 >> GotQueryOptionsHeight)


saveToLocalStorage : String -> String -> Cmd msg
saveToLocalStorage key value =
    localStorage_set
        (Encode.object
            [ ( "key", Encode.string key )
            , ( "value", Encode.string value )
            ]
        )



updateUrl : Model -> Cmd Msg
updateUrl ({ url } as model) =
    { url
        | query =
            [ ( "q", model.query )
            , ( "type"
              , case model.queryType of
                    Standard ->
                        ""

                    ElasticsearchQueryString ->
                        "eqs"
              )
            , ( if model.includeFilteredTypes then
                    "include-types"

                else
                    "exclude-types"
              , model.filteredTypes
                |> Set.toList
                |> String.join ","
              )
            , ( if model.includeFilteredTraits then
                    "include-traits"

                else
                    "exclude-traits"
              , model.filteredTraits
                |> Set.toList
                |> String.join ","
              )
            , ( "sort"
              , model.sort
                    |> List.map
                        (\( field, dir ) ->
                            sortFieldToString field ++ "-" ++ sortDirToString dir
                        )
                    |> String.join ","
              )
            ]
                |> List.filter (Tuple.second >> String.isEmpty >> not)
                |> List.map (\(key, val) -> Url.Builder.string key val)
                |> Url.Builder.toQuery
                |> String.dropLeft 1
                |> String.Extra.nonEmpty
    }
        |> Url.toString
        |> Browser.Navigation.pushUrl model.navKey


searchFields : List String
searchFields =
    [ "name"
    , "text^0.1"
    , "trait_raw"
    , "type"
    ]


buildSearchBody : Model -> Encode.Value
buildSearchBody model =
    encodeObjectMaybe
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , encodeObjectMaybe
                        [ if String.isEmpty model.query then
                            Nothing

                          else
                            Just
                                ( "should"
                                , Encode.list Encode.object
                                    (case model.queryType of
                                        Standard ->
                                            buildStandardQueryBody model.query

                                        ElasticsearchQueryString ->
                                            buildElasticsearchQueryStringQueryBody model.query
                                    )
                                )

                        , if List.isEmpty (buildSearchFilterTerms model) then
                            Nothing

                          else
                            Just
                                ( "filter"
                                , Encode.list Encode.object
                                    (List.map List.singleton (buildSearchFilterTerms model))
                                )

                        , if List.isEmpty (buildSearchMustNotTerms model) then
                            Nothing

                          else
                            Just
                                ( "must_not"
                                , Encode.list Encode.object
                                    (List.map List.singleton (buildSearchMustNotTerms model))
                                )

                        , if String.isEmpty model.query then
                            Nothing

                          else
                            Just ( "minimum_should_match", Encode.int 1 )
                        ]
                  )
                ]
          )
            |> Just
        , Just ( "size", Encode.int 50 )
        , ( "sort"
          , Encode.list identity
                (if List.isEmpty model.sort then
                    [ Encode.string "_score"
                    , Encode.string "_doc"
                    ]

                 else
                     List.append
                        (List.map
                            (\( field, dir ) ->
                                Encode.object
                                    [ ( sortFieldToQueryField field
                                      , Encode.object
                                            [ ( "order", Encode.string (sortDirToString dir) )
                                            ]
                                      )
                                    ]
                            )
                            model.sort
                        )
                        [ Encode.string "id" ]
                )
          )
            |> Just
        , model.searchResults
            |> List.Extra.last
            |> Maybe.andThen (Result.toMaybe)
            |> Maybe.map .hits
            |> Maybe.andThen List.Extra.last
            |> Maybe.map .sort
            |> Maybe.map (Tuple.pair "search_after")
        ]


sortFieldToString : SortField -> String
sortFieldToString field =
    case field of
        AC ->
            "AC"

        Bulk ->
            "Bulk"

        Cha ->
            "Charisma"

        Con ->
            "Constitution"

        Dex ->
            "Dexterity"

        Fortitude ->
            "Fortitude"

        HP ->
            "HP"

        Int ->
            "Intelligence"

        Level ->
            "Level"

        Name ->
            "Name"

        Perception ->
            "Perception"

        Price ->
            "Price"

        Range ->
            "Range"

        Reflex ->
            "Reflex"

        Str ->
            "Strength"

        Type ->
            "Type"

        Wis ->
            "Wisdom"

        Will ->
            "Will"


sortFieldToQueryField : SortField -> String
sortFieldToQueryField field =
    case field of
        AC ->
            "ac"

        Bulk ->
            "bulk"

        Cha ->
            "charisma"

        Con ->
            "constitution"

        Dex ->
            "dexterity"

        Fortitude ->
            "fortitude_save"

        HP ->
            "hp"

        Int ->
            "intelligence"

        Level ->
            "level"

        Name ->
            "name.keyword"

        Perception ->
            "perception"

        Price ->
            "price"

        Range ->
            "range"

        Reflex ->
            "reflex_save"

        Str ->
            "strength"

        Type ->
            "type"

        Will ->
            "will_save"

        Wis ->
            "wisdom"


sortFieldFromString : String -> Maybe SortField
sortFieldFromString str =
    case str of
        "AC" ->
            Just AC

        "Bulk" ->
            Just Bulk

        "Charisma" ->
            Just Cha

        "Constitution" ->
            Just Con

        "Dexterity" ->
            Just Dex

        "Fortitude" ->
            Just Fortitude

        "HP" ->
            Just HP

        "Intelligence" ->
            Just Int

        "Level" ->
            Just Level

        "Name" ->
            Just Name

        "Perception" ->
            Just Perception

        "Price" ->
            Just Price

        "Range" ->
            Just Range

        "Reflex" ->
            Just Reflex

        "Strength" ->
            Just Str

        "Type" ->
            Just Type

        "Will" ->
            Just Will

        "Wisdom" ->
            Just Wis

        _ ->
            Nothing


sortDirToString : SortDir -> String
sortDirToString dir =
    case dir of
        Asc ->
            "asc"

        Desc ->
            "desc"


sortDirFromString : String -> Maybe SortDir
sortDirFromString str =
    case str of
        "asc" ->
            Just Asc

        "desc" ->
            Just Desc

        _ ->
            Nothing


buildSearchFilterTerms : Model -> List ( String, Encode.Value )
buildSearchFilterTerms model =
    [ if Set.isEmpty model.filteredTraits || not model.includeFilteredTraits then
        Nothing

      else
        Just
            ( "terms"
            , Encode.object
                [ ( "trait"
                  , Encode.list Encode.string (Set.toList model.filteredTraits)
                  )
                ]
            )

    , if Set.isEmpty model.filteredTypes || not model.includeFilteredTypes then
        Nothing

      else
        Just
            ( "terms"
            , Encode.object
                [ ( "type"
                  , Encode.list Encode.string (Set.toList model.filteredTypes)
                  )
                ]
            )
    ]
        |> List.filterMap identity


buildSearchMustNotTerms : Model -> List ( String, Encode.Value )
buildSearchMustNotTerms model =
    [ if Set.isEmpty model.filteredTraits || model.includeFilteredTraits then
        Nothing

      else
        Just
            ( "terms"
            , Encode.object
                [ ( "trait"
                  , Encode.list Encode.string (Set.toList model.filteredTraits)
                  )
                ]
            )

    , if Set.isEmpty model.filteredTypes || model.includeFilteredTypes then
        Nothing

      else
        Just
            ( "terms"
            , Encode.object
                [ ( "type"
                  , Encode.list Encode.string (Set.toList model.filteredTypes)
                  )
                ]
            )
    ]
        |> List.filterMap identity


buildStandardQueryBody : String -> List (List ( String, Encode.Value ))
buildStandardQueryBody queryString =
    [ [ ( "match_phrase_prefix"
        , Encode.object
            [ ( "name"
              , Encode.object
                    [ ( "query", Encode.string queryString )
                    ]
              )
            ]
        )
      ]
    , [ ( "bool"
        , Encode.object
            [ ( "must"
              , Encode.list Encode.object
                    (List.map
                        (\word ->
                            [ ( "multi_match"
                              , Encode.object
                                    [ ( "query", Encode.string word )
                                    , ( "type", Encode.string "best_fields" )
                                    , ( "fields", Encode.list Encode.string searchFields )
                                    , ( "fuzziness", Encode.string "auto" )
                                    ]
                              )
                            ]
                        )
                        (String.words queryString)
                    )
              )
            ]
        )
      ]
    ]


buildElasticsearchQueryStringQueryBody : String -> List (List ( String, Encode.Value ))
buildElasticsearchQueryStringQueryBody queryString =
    [ [ ( "query_string"
        , Encode.object
            [ ( "query", Encode.string queryString )
            , ( "default_operator", Encode.string "AND" )
            , ( "fields", Encode.list Encode.string searchFields )
            ]
        )
      ]
    ]


updateModelFromQueryString : Url -> Model -> Model
updateModelFromQueryString url model =
    { model
        | query = getQueryParam url "q"
        , queryType =
            case getQueryParam url "type" of
                "eqs" ->
                    ElasticsearchQueryString

                _ ->
                    Standard
        , filteredTypes =
            Maybe.Extra.or
                (getQueryParam url "include-types"
                    |> String.Extra.nonEmpty
                )
                (getQueryParam url "exclude-types"
                    |> String.Extra.nonEmpty
                )
                |> Maybe.map (String.split ",")
                |> Maybe.map Set.fromList
                |> Maybe.map (Set.filter (\v -> List.member v Data.types))
                |> Maybe.withDefault Set.empty
        , filteredTraits =
            Maybe.Extra.or
                (getQueryParam url "include-traits"
                    |> String.Extra.nonEmpty
                )
                (getQueryParam url "exclude-traits"
                    |> String.Extra.nonEmpty
                )
                |> Maybe.map (String.split ",")
                |> Maybe.map Set.fromList
                |> Maybe.map (Set.filter (\v -> List.member v Data.traits))
                |> Maybe.withDefault Set.empty
        , includeFilteredTypes =
            Maybe.Extra.or
                (getQueryParam url "include-types"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (\_ -> True)
                )
                (getQueryParam url "exclude-types"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (\_ -> False)
                )
            |> Maybe.withDefault model.includeFilteredTypes
        , includeFilteredTraits =
            Maybe.Extra.or
                (getQueryParam url "include-traits"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (\_ -> True)
                )
                (getQueryParam url "exclude-traits"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (\_ -> False)
                )
            |> Maybe.withDefault model.includeFilteredTraits
        , searchResults = []
        , sort =
            getQueryParam url "sort"
                |> String.Extra.nonEmpty
                |> Maybe.map (String.split ",")
                |> Maybe.map
                    (List.filterMap
                        (\str ->
                            case String.split "-" str of
                                [ field, dir ] ->
                                    Maybe.map2
                                        Tuple.pair
                                        (sortFieldFromString field)
                                        (sortDirFromString dir)

                                _ ->
                                    Nothing
                        )
                    )
                |> Maybe.withDefault []
    }


getQueryParam : Url -> String -> String
getQueryParam url param =
    { url | path = "" }
        |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string param))
        |> Maybe.Extra.join
        |> Maybe.withDefault ""


searchWithCurrentQuery : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
searchWithCurrentQuery ( model, cmd ) =
    if String.isEmpty (String.trim model.query)
        && Set.isEmpty model.filteredTraits
        && Set.isEmpty model.filteredTypes
    then
        ( { model | searchResults = [] }
        , Cmd.batch
            [ cmd
            , case model.tracker of
                Just tracker ->
                    Http.cancel ("search-" ++ String.fromInt tracker)

                Nothing ->
                    Cmd.none
            ]
        )

    else
        let
            newTracker : Int
            newTracker =
                case model.tracker of
                    Just tracker ->
                        tracker + 1

                    Nothing ->
                        1
        in
        ( { model | tracker = Just newTracker
          }
        , Cmd.batch
            [ cmd

            , case model.tracker of
                Just tracker ->
                    Http.cancel ("search-" ++ String.fromInt tracker)

                Nothing ->
                    Cmd.none

            , Http.request
                { method = "POST"
                , url = model.elasticUrl ++ "/_search"
                , headers = []
                , body = Http.jsonBody (buildSearchBody model)
                , expect = Http.expectJson GotSearchResult esResultDecoder
                , timeout = Just 10000
                , tracker = Just ("search-" ++ String.fromInt newTracker)
                }
            ]
        )


encodeObjectMaybe : List (Maybe ( String, Encode.Value )) -> Encode.Value
encodeObjectMaybe list =
    List.filterMap identity list
        |> Encode.object


esResultDecoder : Decode.Decoder SearchResult
esResultDecoder =
    Field.requireAt [ "hits", "hits" ] (Decode.list (hitDecoder documentDecoder)) <| \hits ->
    Field.requireAt [ "hits", "total", "value" ] Decode.int <| \total ->
    Decode.succeed
        { hits = hits
        , total = total
        }


hitDecoder : Decode.Decoder a -> Decode.Decoder (Hit a)
hitDecoder decoder =
    Field.require "_id" Decode.string <| \id ->
    Field.require "_score" (Decode.maybe Decode.float) <| \score ->
    Field.require "_source" decoder <| \source ->
    Field.require "sort" Decode.value <| \sort ->
    Decode.succeed
        { id = id
        , score = Maybe.withDefault 0 score
        , sort = sort
        , source = source
        }


documentDecoder : Decode.Decoder Document
documentDecoder =
    Field.require "id" Decode.int <| \id ->
    Field.require "category" Decode.string <| \category ->
    Field.require "name" Decode.string <| \name ->
    Field.require "type" Decode.string <| \type_ ->
    Field.require "url" Decode.string <| \url ->
    Field.attempt "ability_type" Decode.string <| \abilityType ->
    Field.attempt "ac" Decode.int <| \ac ->
    Field.attempt "actions" Decode.string <| \actions ->
    Field.attempt "activate" Decode.string <| \activate ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "ammunition" Decode.string <| \ammunition ->
    Field.attempt "area" Decode.string <| \area ->
    Field.attempt "aspect" Decode.string <| \aspect ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "bulk_raw" Decode.string <| \bulk ->
    Field.attempt "cast" Decode.string <| \cast ->
    Field.attempt "component" (Decode.list Decode.string) <| \components ->
    Field.attempt "cost" Decode.string <| \cost ->
    Field.attempt "creature_family" Decode.string <| \creatureFamily ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "duration" Decode.string <| \duration ->
    Field.attempt "familiar_ability" (Decode.list Decode.string) <| \familiarAbilities ->
    Field.attempt "fortitude_save" Decode.int <| \fort ->
    Field.attempt "frequency" Decode.string <| \frequency ->
    Field.attempt "hands" Decode.string <| \hands ->
    Field.attempt "heighten" (Decode.list Decode.string) <| \heighten ->
    Field.attempt "hp" Decode.int <| \hp ->
    Field.attempt "lesson_type" Decode.string <| \lessonType ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "perception" Decode.int <| \perception ->
    Field.attempt "prerequisite" Decode.string <| \prerequisites ->
    Field.attempt "price_raw" Decode.string <| \price ->
    Field.attempt "primaryCheck" Decode.string <| \primaryCheck ->
    Field.attempt "range_raw" Decode.string <| \range ->
    Field.attempt "reflex_save" Decode.int <| \ref ->
    Field.attempt "reload_raw" Decode.string <| \reload ->
    Field.attempt "required_abilities" Decode.string <| \requiredAbilities ->
    Field.attempt "requirement" Decode.string <| \requirements ->
    Field.attempt "saving_throw" Decode.string <| \savingThrow ->
    Field.attempt "secondary_casters_raw" Decode.string <| \secondaryCasters ->
    Field.attempt "secondary_check" Decode.string <| \secondaryChecks ->
    Field.attempt "source" Decode.string <| \source ->
    Field.attempt "spell_list" Decode.string <| \spellList ->
    Field.attempt "spoilers" Decode.string <| \spoilers ->
    Field.attempt "target" Decode.string <| \targets ->
    Field.attempt "tradition" (Decode.list Decode.string) <| \traditions ->
    Field.attempt "trait_raw" (Decode.list Decode.string) <| \maybeTraits ->
    Field.attempt "trigger" Decode.string <| \trigger ->
    Field.attempt "usage" Decode.string <| \usage ->
    Field.attempt "weapon_category" Decode.string <| \weaponCategory ->
    Field.attempt "weapon_group" Decode.string <| \weaponGroup ->
    Field.attempt "will_save" Decode.int <| \will ->
    Decode.succeed
        { id = id
        , category = category
        , name = name
        , type_ = type_
        , url = url
        , abilityType = abilityType
        , ac = ac
        , actions = actions
        , activate = activate
        , alignment = alignment
        , ammunition = ammunition
        , area = area
        , aspect = aspect
        , breadcrumbs = breadcrumbs
        , bulk = bulk
        , cast = cast
        , components = Maybe.withDefault [] components
        , cost = cost
        , creatureFamily = creatureFamily
        , damage = damage
        , duration = duration
        , familiarAbilities = Maybe.withDefault [] familiarAbilities
        , fort = fort
        , frequency = frequency
        , hands = hands
        , heighten = Maybe.withDefault [] heighten
        , hp = hp
        , lessonType = lessonType
        , level = level
        , perception = perception
        , prerequisites = prerequisites
        , price = price
        , primaryCheck = primaryCheck
        , range = range
        , ref = ref
        , reload = reload
        , requiredAbilities = requiredAbilities
        , requirements = requirements
        , savingThrow = savingThrow
        , secondaryCasters = secondaryCasters
        , secondaryChecks = secondaryChecks
        , source = source
        , spellList = spellList
        , spoilers = spoilers
        , targets = targets
        , traditions = Maybe.withDefault [] traditions
        , traits = Maybe.withDefault [] maybeTraits
        , trigger = trigger
        , usage = usage
        , weaponCategory = weaponCategory
        , weaponGroup = weaponGroup
        , will = will
        }


getUrl : Document -> String
getUrl doc =
    "https://2e.aonprd.com/" ++ doc.url


view : Model -> Browser.Document Msg
view model =
    { title =
        if String.isEmpty model.query then
            "Nethys Search"

        else
            model.query ++ " - Nethys Search"
    , body =
        [ Html.node "style"
            []
            [ Html.text css
            , case model.theme of
                Dark ->
                    Html.text cssDark

                Light ->
                    Html.text cssLight

                Paper ->
                    Html.text cssPaper
            ]
        , FontAwesome.Styles.css
        , Html.div
            [ HA.class "body-container"
            , HA.class "column"
            ]
            [ Html.button
                [ HA.class "menu-open-button"
                , HE.onClick (ShowMenuPressed True)
                , HE.onMouseOver (ShowMenuPressed True)
                ]
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.bars ]
            , Html.div
                [ HA.class "menu-overlay"
                , HAE.attributeIf (not model.menuOpen) (HA.class "menu-overlay-hidden")
                , HE.onClick (ShowMenuPressed False)
                , HAE.attributeIf (model.overlayActive) (HE.onMouseOver (ShowMenuPressed False))
                ]
                []
            , viewMenu model
            , Html.div
                [ HA.class "column"
                , HA.class "content-container"
                , HA.class "gap-large"
                ]
                [ viewTitle
                , Html.main_
                    [ HA.class "column gap-large"
                    ]
                    [ viewQuery model
                    , viewSearchResults model
                    ]
                ]
            ]
        ]
    }


viewMenu : Model -> Html Msg
viewMenu model =
    Html.div
        [ HA.class "menu"
        , HA.class "column"
        , HAE.attributeIf (not model.menuOpen) (HA.style "transform" "translate(-100%, 0px)")
        ]
        [ Html.button
            [ HA.class "menu-close-button"
            , HE.onClick (ShowMenuPressed False)
            , HAE.attributeIf (model.overlayActive) (HE.onMouseOver (ShowMenuPressed False))
            ]
            [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "gap-large"
            ]
            [ Html.section
                [ HA.class "column"
                , HA.class "gap-medium"
                ]
                [ Html.h2
                    [ HA.class "title" ]
                    [ Html.text "Options" ]
                , Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    [ Html.h3
                        [ HA.class "subtitle" ]
                        [ Html.text "Theme" ]
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        [ viewRadioButton
                            { checked = model.theme == Dark
                            , name = "theme-type"
                            , onInput = ThemeSelected Dark
                            , text = "Dark"
                            }
                        , viewRadioButton
                            { checked = model.theme == Light
                            , name = "theme-type"
                            , onInput = ThemeSelected Light
                            , text = "Light"
                            }
                        , viewRadioButton
                            { checked = model.theme == Paper
                            , name = "theme-type"
                            , onInput = ThemeSelected Paper
                            , text = "Paper"
                            }
                        ]
                    ]
                , Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    [ Html.h3
                        [ HA.class "subtitle" ]
                        [ Html.text "Result display" ]
                    , viewCheckbox
                        { checked = model.showResultSpoilers
                        , onCheck = ShowSpoilersChanged
                        , text = "Show spoiler warning"
                        }
                    , viewCheckbox
                        { checked = model.showResultTraits
                        , onCheck = ShowTraitsChanged
                        , text = "Show traits"
                        }
                    , viewCheckbox
                        { checked = model.showResultAdditionalInfo
                        , onCheck = ShowAdditionalInfoChanged
                        , text = "Show additional info"
                        }
                    ]
                ]
            , Html.section
                [ HA.class "column"
                , HA.class "gap-medium"
                ]
                [ Html.h2
                    [ HA.class "title" ]
                    [ Html.text "About / F.A.Q." ]
                , viewFaq
                    "What is this?"
                    [ Html.text "A search engine that searches "
                    , Html.a
                        [ HA.href "https://2e.aonprd.com/" ]
                        [ Html.text "Archives of Nethys" ]
                    , Html.text ", the System Reference Document for Pathfinder Second Edition."
                    ]
                , viewFaq
                    "How can I contact you?"
                    [ Html.text "You can send me an email (nethys-search <at> galdiuz.com), message me on Discord (Galdiuz#7937), or "
                    , Html.a
                        [ HA.href "https://github.com/galdiuz/nethys-search/issues" ]
                        [ Html.text "submit an issue on GitHub" ]
                    , Html.text "."
                    ]
                ]
            ]
        ]


viewFaq : String -> List (Html msg) -> Html msg
viewFaq question answer =
    Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        [ Html.h3
            [ HA.class "subtitle" ]
            [ Html.text question ]
        , Html.div
            []
            answer
        ]


viewTitle : Html Msg
viewTitle =
    Html.header
        [ HA.class "column"
        , HA.class "align-center"
        ]
        [ Html.h1
            []
            [ Html.a
                [ HA.href "?"
                ]
                [ Html.text "Nethys Search" ]
            ]
        , Html.div
            []
            [ Html.text "Search engine for "
            , Html.a
                [ HA.href "https://2e.aonprd.com/" ]
                [ Html.text "2e.aonprd.com" ]
            ]
        ]


viewQuery : Model -> Html Msg
viewQuery model =
    Html.div
        [ HA.class "column"
        , HA.class "align-stretch"
        , HA.class "gap-tiny"
        , HA.style "position" "relative"
        ]
        [ Html.div
            [ HA.style "position" "relative" ]
            [ Html.input
                [ HA.autofocus True
                , HA.class "query-input"
                , HA.placeholder "Enter search query"
                , HA.type_ "text"
                , HA.value model.query
                , HE.onInput QueryChanged
                ]
                [ Html.text model.query ]
            , if String.isEmpty model.query then
                Html.text ""

              else
                Html.button
                    [ HA.class "input-button"
                    , HA.style "font-size" "24px"
                    , HE.onClick (QueryChanged "")
                    ]
                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
            ]

        , Html.button
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HE.onClick (ShowQueryOptionsPressed (not model.queryOptionsOpen))
            , HA.style "align-self" "center"
            ]
            (if model.queryOptionsOpen then
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronUp
                , Html.text "Hide filters and options"
                , FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronUp
                ]

             else
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronDown
                , Html.text " Show filters and options"
                , FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronDown
                ]
            )

        , Html.div
            [ HA.class "query-options-dummy"
            , HA.id "query-options-dummy"
            ]
            [ viewQueryOptions model ]

        , Html.div
            [ HA.class "query-options-container"
            , HA.style "height"
                (if model.queryOptionsOpen then
                    String.fromInt model.queryOptionsHeight

                 else "0"
                )
            ]
            [ viewQueryOptions model ]

        , if model.queryType == ElasticsearchQueryString then
            Html.div
                []
                [ Html.text "Query type: Complex" ]

          else if stringContainsChar model.query ":()\"" then
            Html.div
                [ HA.class "option-container"
                , HA.class "row"
                , HA.class "align-center"
                , HA.class "nowrap"
                ]
                [ Html.div
                    [ HA.style "font-size" "24px"
                    , HA.style "padding" "4px"
                    ]
                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.exclamation ]
                , Html.div
                    [ HE.onClick (QueryTypeSelected ElasticsearchQueryString)
                    ]
                    [ Html.text "Your query contains characters that can be used with the complex query type, but you are currently using the standard query type. Would you like to "
                    , Html.button
                        []
                        [ Html.text "switch to complex query type" ]
                    , Html.text "?"
                    ]
                ]

          else
            Html.text ""

        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            [ viewIncludeFilters model
            , viewExcludeFilters model
            ]

        , if List.isEmpty model.sort then
            Html.text ""

          else
            Html.div
                [ HA.class "row"
                , HA.class "gap-tiny"
                , HA.class "align-baseline"
                ]
                (List.concat
                    [ [ Html.text "Sort by:" ]
                    , List.map
                        (\( field, dir ) ->
                            Html.button
                                [ HE.onClick (SortRemoved field) ]
                                [ Html.text (sortFieldToString field ++ " " ++ sortDirToString dir) ]
                        )
                        model.sort
                    ]
                )
        ]


viewIncludeFilters : Model -> Html Msg
viewIncludeFilters model =
    if (Set.isEmpty model.filteredTraits || not model.includeFilteredTraits)
        && (Set.isEmpty model.filteredTypes || not model.includeFilteredTypes)
    then
        Html.text ""

    else
        Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "align-baseline"
            ]
            (List.concat
                [ [ Html.text "Include:" ]

                , if (Set.isEmpty model.filteredTypes || not model.includeFilteredTypes) then
                    []

                  else
                    model.filteredTypes
                        |> Set.toList
                        |> List.map
                            (\type_ ->
                                Html.button
                                    [ HA.class "filter-type"
                                    , HE.onClick (TypeFilterRemoved type_)
                                    ]
                                    [ Html.text type_ ]
                            )

                , if (Set.isEmpty model.filteredTraits || not model.includeFilteredTraits) then
                    []

                  else
                    model.filteredTraits
                        |> Set.toList
                        |> List.map
                            (\trait ->
                                Html.button
                                    [ HA.class "trait"
                                    , HE.onClick (TraitFilterRemoved trait)
                                    ]
                                    [ Html.text trait ]
                            )
                ]
            )


viewExcludeFilters : Model -> Html Msg
viewExcludeFilters model =
    if (Set.isEmpty model.filteredTraits || model.includeFilteredTraits)
        && (Set.isEmpty model.filteredTypes || model.includeFilteredTypes)
    then
        Html.text ""

    else
        Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "align-baseline"
            ]
            (List.concat
                [ [ Html.text "Exclude:" ]

                , if (Set.isEmpty model.filteredTypes || model.includeFilteredTypes) then
                    []

                  else
                    model.filteredTypes
                        |> Set.toList
                        |> List.map
                            (\type_ ->
                                Html.button
                                    [ HA.class "filter-type"
                                    , HE.onClick (TypeFilterRemoved type_)
                                    ]
                                    [ Html.text type_ ]
                            )

                , if (Set.isEmpty model.filteredTraits || model.includeFilteredTraits) then
                    []

                  else
                    model.filteredTraits
                        |> Set.toList
                        |> List.map
                            (\trait ->
                                Html.button
                                    [ HA.class "trait"
                                    , HE.onClick (TraitFilterRemoved trait)
                                    ]
                                    [ Html.text trait ]
                            )
                ]
            )


viewQueryOptions : Model -> Html Msg
viewQueryOptions model =
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ viewQueryType model
        , viewFilterTypes model
        , viewFilterTraits model
        , viewSortResults model
        ]


viewQueryType : Model -> Html Msg
viewQueryType model =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.h3
            []
            [ Html.text "Query type" ]
        , Html.div
            [ HA.class "row"
            , HA.class "align-baseline"
            , HA.class "gap-medium"
            ]
            [ viewRadioButton
                { checked = model.queryType == Standard
                , name = "query-type"
                , onInput = QueryTypeSelected Standard
                , text = "Standard"
                }
            , viewRadioButton
                { checked = model.queryType == ElasticsearchQueryString
                , name = "query-type"
                , onInput = QueryTypeSelected ElasticsearchQueryString
                , text = "Complex"
                }
            , Html.button
                [ HE.onClick (ShowEqsHelpPressed (not model.eqsHelpOpen)) ]
                (if model.eqsHelpOpen then
                    [ Html.text "Hide help" ]

                 else
                    [ Html.text "Show help" ]
                )
            ]
        , if model.eqsHelpOpen then
            Html.div
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                [ Html.div
                    []
                    [ Html.text "With the complex query type you can write queries using Elasticsearch Query String syntax. The general idea is that you can search in specific fields by searching "
                    , Html.span
                        [ HA.class "monospace" ]
                        [ Html.text "field:value" ]
                    , Html.text ". For full documentation on how the query syntax works see "
                    , Html.a
                        [ HA.href "https://www.elastic.co/guide/en/elasticsearch/reference/7.15/query-dsl-query-string-query.html#query-string-syntax" ]
                        [ Html.text "Elasticsearch's documentation" ]
                    , Html.text ". See below for a list of available fields. [n] means the field is numeric and supports range queries."
                    ]
                , Html.div
                    [ HA.class "scrollbox"
                    ]
                    [ Html.div
                        [ HA.class "column"
                        , HA.class "gap-tiny"
                        ]
                        (List.append
                            [ Html.div
                                [ HA.class "row"
                                , HA.class "gap-medium"
                                ]
                                [ Html.div
                                    [ HA.class "bold"
                                    , HA.style "width" "35%"
                                    , HA.style "max-width" "200px"
                                    ]
                                    [ Html.text "Field" ]
                                , Html.div
                                    [ HA.class "bold"
                                    , HA.style "max-width" "60%"
                                    ]
                                    [ Html.text "Description" ]
                                ]
                            ]
                            (List.map
                                (\( field, desc ) ->
                                    Html.div
                                        [ HA.class "row"
                                        , HA.class "gap-medium"
                                        ]
                                        [ Html.div
                                            [ HA.style "width" "35%"
                                            , HA.style "max-width" "200px"
                                            , HA.style "word-break" "break-all"
                                            , HA.class "monospace"
                                            ]
                                            [ Html.text field ]
                                        , Html.div
                                            [ HA.style "max-width" "60%"
                                            ]
                                            [ Html.text desc ]
                                        ]
                                )
                                Data.fields
                            )
                        )
                    ]
                , Html.h3
                    []
                    [ Html.text "Example queries" ]
                , Html.div
                    []
                    [ Html.div
                        []
                        [ Html.text "Spells or cantrips unique to the arcane tradition:" ]
                    , Html.div
                        [ HA.class "monospace" ]
                        [ Html.text "tradition:(arcane -divine -occult -primal) type:(spell OR cantrip)" ]
                    ]
                , Html.div
                    []
                    [ Html.div
                        []
                        [ Html.text "Evil deities with dagger as their favored weapon:" ]
                    , Html.div
                        [ HA.class "monospace" ]
                        [ Html.text "alignment:?E favored_weapon:dagger" ]
                    ]
                , Html.div
                    []
                    [ Html.div
                        []
                        [ Html.text "Non-consumable items between 500 and 1000 gp:" ]
                    , Html.div
                        [ HA.class "monospace" ]
                        [ Html.text "price:[50000 TO 100000] NOT trait:consumable" ]
                    ]
                , Html.div
                    []
                    [ Html.div
                        []
                        [ Html.text "Spells up to level 5 with a range of at least 100 feet that are granted by any sorcerer bloodline:" ]
                    , Html.div
                        [ HA.class "monospace" ]
                        [ Html.text "type:spell level:<=5 range:>=100 bloodline:*" ]
                    ]
                , Html.div
                    []
                    [ Html.div
                        []
                        [ Html.text "Rules pages that mention 'mental damage':" ]
                    , Html.div
                        [ HA.class "monospace" ]
                        [ Html.text "\"mental damage\" type:rules" ]
                    ]
                , Html.div
                    []
                    [ Html.div
                        []
                        [ Html.text "Weapons with finesse and either disarm or trip:" ]
                    , Html.div
                        [ HA.class "monospace" ]
                        [ Html.text "type:weapon trait:finesse trait:(disarm OR trip)" ]
                    ]
                ]

          else
            Html.text ""
        ]


viewFilterTypes : Model -> Html Msg
viewFilterTypes model =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.h3
            []
            [ Html.text "Filter types" ]
        , Html.div
            [ HA.class "row"
            , HA.class "align-baseline"
            , HA.class "gap-medium"
            ]
            [ viewRadioButton
                { checked = model.includeFilteredTypes
                , name = "filter-types"
                , onInput = IncludeFilteredTypesChanged True
                , text = "Include selected"
                }
            , viewRadioButton
                { checked = not model.includeFilteredTypes
                , name = "filter-types"
                , onInput = IncludeFilteredTypesChanged False
                , text = "Exclude selected"
                }
            , Html.button
                [ HE.onClick RemoveAllTypeFiltersPressed ]
                [ Html.text "Reset selection" ]
            ]

        , Html.div
            [ HA.style "position" "relative"
            ]
            [ Html.input
                [ HA.placeholder "Search among types"
                , HA.type_ "text"
                , HA.value model.searchTypes
                , HE.onInput SearchTypesChanged
                ]
                []
            , if String.isEmpty model.searchTypes then
                Html.text ""

              else
                Html.button
                    [ HA.class "input-button"
                    , HE.onClick (SearchTypesChanged "")
                    ]
                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
            ]

        , Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "scrollbox"
            ]
            (List.map
                (\type_ ->
                    Html.button
                        [ HA.class "filter-type"
                        , HAE.attributeIf
                            (xor
                                model.includeFilteredTypes
                                (Set.member type_ model.filteredTypes)
                                && not (Set.isEmpty model.filteredTypes)
                            )
                            (HA.class "excluded")
                        , HE.onClick
                            (if Set.member type_ model.filteredTypes then
                                TypeFilterRemoved type_

                             else
                                TypeFilterAdded type_
                            )
                        ]
                        [ Html.text type_ ]
                )
                (List.filter
                    (String.toLower >> String.contains (String.toLower model.searchTypes))
                    Data.types
                )
            )
        ]


viewFilterTraits : Model -> Html Msg
viewFilterTraits model =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.h3
            []
            [ Html.text "Filter traits" ]
        , Html.div
            [ HA.class "row"
            , HA.class "align-baseline"
            , HA.class "gap-medium"
            ]
            [ viewRadioButton
                { checked = model.includeFilteredTraits
                , name = "filter-traits"
                , onInput = IncludeFilteredTraitsChanged True
                , text = "Include selected"
                }
            , viewRadioButton
                { checked = not model.includeFilteredTraits
                , name = "filter-traits"
                , onInput = IncludeFilteredTraitsChanged False
                , text = "Exclude selected"
                }
            , Html.button
                [ HE.onClick RemoveAllTraitFiltersPressed ]
                [ Html.text "Reset selection" ]
            ]

        , Html.div
            [ HA.style "position" "relative"
            ]
            [ Html.input
                [ HA.placeholder "Search among traits"
                , HA.value model.searchTraits
                , HA.type_ "text"
                , HE.onInput SearchTraitsChanged
                ]
                []
            , if String.isEmpty model.searchTraits then
                Html.text ""

              else
                Html.button
                    [ HA.class "input-button"
                    , HE.onClick (SearchTraitsChanged "")
                    ]
                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
            ]

        , Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "scrollbox"
            ]
            (List.map
                (\type_ ->
                    Html.button
                        [ HA.class "trait"
                        , HAE.attributeIf
                            (xor
                                model.includeFilteredTraits
                                (Set.member type_ model.filteredTraits)
                                && not (Set.isEmpty model.filteredTraits)
                            )
                            (HA.class "excluded")
                        , HE.onClick
                            (if Set.member type_ model.filteredTraits then
                                TraitFilterRemoved type_

                             else
                                TraitFilterAdded type_
                            )
                        ]
                        [ Html.text type_ ]
                )
                (List.filter
                    (String.toLower >> String.contains (String.toLower model.searchTraits))
                    Data.traits
                )
            )
        ]


viewSortResults : Model -> Html Msg
viewSortResults model =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.h3
            []
            [ Html.text "Sort results" ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-large"
            ]
            (List.append
                [ Html.button
                    [ HE.onClick RemoveAllSortsPressed ]
                    [ Html.text "Reset selection" ]
                ]
                (List.map
                    (\field ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "align-baseline"
                            ]
                            [ Html.text (sortFieldToString field)
                            , Html.button
                                [ HE.onClick
                                    (if List.member ( field, Asc ) model.sort then
                                        (SortRemoved field)

                                     else
                                        (SortAdded field Asc)
                                    )
                                , HA.class
                                    (if List.member ( field, Asc ) model.sort then
                                        "active"

                                     else
                                        "excluded"
                                    )
                                ]
                                [ Html.text "Asc" ]
                            , Html.button
                                [ HE.onClick
                                    (if List.member ( field, Desc ) model.sort then
                                        (SortRemoved field)

                                     else
                                        (SortAdded field Desc)
                                    )
                                , HA.class
                                    (if List.member ( field, Desc ) model.sort then
                                        "active"

                                     else
                                        "excluded"
                                    )
                                ]
                                [ Html.text "Desc" ]
                            ]
                    )
                    [ Name
                    , Level
                    , Type
                    , Price
                    , Bulk
                    , Range
                    , HP
                    , Perception
                    , AC
                    , Fortitude
                    , Reflex
                    , Will
                    -- , Str
                    -- , Dex
                    -- , Con
                    -- , Int
                    -- , Wis
                    -- , Cha
                    ]
                )
            )
        ]


viewCheckbox : { checked : Bool, onCheck : Bool -> msg, text : String } -> Html msg
viewCheckbox { checked, onCheck, text } =
    Html.label
        [ HA.class "row"
        , HA.class "align-baseline"
        ]
        [ Html.input
            [ HA.type_ "checkbox"
            , HA.checked checked
            , HE.onCheck onCheck
            ]
            []
        , Html.text text
        ]


viewRadioButton : { checked : Bool, name : String, onInput : msg, text : String } -> Html msg
viewRadioButton { checked, name, onInput, text } =
    Html.label
        [ HA.class "row"
        , HA.class "align-baseline"
        ]
        [ Html.input
            [ HA.type_ "radio"
            , HA.checked checked
            , HA.name name
            , HE.onClick onInput
            ]
            []
        , Html.div
            []
            [ Html.text text ]
        ]



viewSearchResults : Model -> Html Msg
viewSearchResults model =
    let
        total : Maybe Int
        total =
            model.searchResults
                |> List.head
                |> Maybe.andThen Result.toMaybe
                |> Maybe.map .total

        resultCount : Int
        resultCount =
            model.searchResults
                |> List.map Result.toMaybe
                |> List.map (Maybe.map .hits)
                |> List.map (Maybe.map List.length)
                |> List.map (Maybe.withDefault 0)
                |> List.sum
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        , HA.style "min-height" "500px"
        ]
        (List.concat
            [ case total of
                Just 10000 ->
                    [ Html.text ("10000+ results") ]

                Just count ->
                    [ Html.text (String.fromInt count ++ " results") ]

                _ ->
                    []

            , List.map
                (\result ->
                    case result of
                        Ok r ->
                            List.map (viewSingleSearchResult model) r.hits

                        Err (Http.BadStatus 400) ->
                            [ Html.h2
                                []
                                [ Html.text "Error: Failed to parse query" ]
                            ]

                        Err _ ->
                            [ Html.h2
                                []
                                [ Html.text "Error: Search failed" ]
                            ]
                )
                model.searchResults
                |> List.concat

            , if Maybe.Extra.isJust model.tracker then
                [ Html.div
                    [ HA.class "loader"
                    ]
                    []
                ]

              else if resultCount < Maybe.withDefault 0 total then
                [ Html.button
                    [ HE.onClick LoadMorePressed
                    , HA.style "align-self" "center"
                    ]
                    [ Html.text "Load more" ]
                ]

              else
                []

            , if resultCount > 0 then
                [ Html.button
                    [ HE.onClick ScrollToTopPressed
                    , HA.style "align-self" "center"
                    ]
                    [ Html.text "Scroll to top" ]
                ]

              else
                []
            ]
        )


viewSingleSearchResult : Model -> Hit Document -> Html msg
viewSingleSearchResult model hit =
    let
        hasActionsInTitle : Bool
        hasActionsInTitle =
            List.member hit.source.category [ "action", "creature-ability", "feat" ]
    in
    Html.section
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h2
            [ HA.class "title" ]
            [ Html.div
                []
                [ Html.a
                    [ HA.href (getUrl hit.source)
                    , HA.target "_blank"
                    ]
                    [ Html.text hit.source.name
                    ]
                , case ( hit.source.actions, hasActionsInTitle ) of
                    ( Just actions, True ) ->
                        viewTextWithActionIcons (" " ++ actions)

                    _ ->
                        Html.text ""
                ]
            , Html.div
                [ HA.class "title-type" ]
                [ Html.text hit.source.type_
                , case hit.source.level of
                    Just level ->
                        Html.text (" " ++ String.fromInt level)

                    Nothing ->
                        Html.text ""
                ]
            ]

        , if model.showResultSpoilers then
            Html.h3
                [ HA.class "subtitle"
                ]
                [ hit.source.spoilers
                    |> Maybe.map (\spoiler -> "May contain spoilers from " ++ spoiler)
                    |> Maybe.withDefault ""
                    |> Html.text
                ]

          else
            Html.text ""

        , if model.showResultTraits then
            Html.div
                [ HA.class "row"
                ]
                (List.map
                    viewTrait
                    hit.source.traits
                )

          else
            Html.text ""

        , if model.showResultAdditionalInfo then
            viewSearchResultAdditionalInfo hit

          else
            Html.text ""
        ]


viewSearchResultAdditionalInfo : Hit Document -> Html msg
viewSearchResultAdditionalInfo hit =
    Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        (List.append
            (hit.source.source
                |> Maybe.map (viewLabelAndText "Source")
                |> Maybe.map List.singleton
                |> Maybe.withDefault []
            )
            (case hit.source.category of
                "action" ->
                    (List.filterMap identity
                        [ hit.source.frequency
                            |> Maybe.map (viewLabelAndText "Frequency")
                        , hit.source.trigger
                            |> Maybe.map (viewLabelAndText "Trigger")
                        , hit.source.requirements
                            |> Maybe.map (viewLabelAndText "Requirements")
                        ]
                    )

                "bloodline" ->
                    hit.source.spellList
                        |> Maybe.map (viewLabelAndText "Spell List")
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "creature" ->
                    (List.filterMap identity
                        [ hit.source.creatureFamily
                            |> Maybe.map (viewLabelAndText "Creature Family")
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ hit.source.hp
                                    |> Maybe.map String.fromInt
                                    |> Maybe.map (viewLabelAndText "HP")
                                , hit.source.perception
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Perception")
                                ]
                            )
                                |> Just
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ hit.source.ac
                                    |> Maybe.map String.fromInt
                                    |> Maybe.map (viewLabelAndText "AC")
                                , hit.source.fort
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Fort")
                                , hit.source.ref
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Ref")
                                , hit.source.will
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Will")
                                ]
                            )
                                |> Just
                        ]
                    )

                "equipment" ->
                    (List.filterMap identity
                        [ Maybe.map
                            (viewLabelAndText "Price")
                            hit.source.price

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ Maybe.map
                                    (viewLabelAndText "Hands")
                                    hit.source.hands
                                , Maybe.map
                                    (viewLabelAndText "Usage")
                                    hit.source.usage
                                , Maybe.map
                                    (viewLabelAndText "Bulk")
                                    hit.source.bulk
                                ]
                            )
                                |> Just

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ Maybe.map
                                    (viewLabelAndText "Activate")
                                    hit.source.activate
                                , Maybe.map
                                    (viewLabelAndText "Frequency")
                                    hit.source.frequency
                                , Maybe.map
                                    (viewLabelAndText "Trigger")
                                    hit.source.trigger
                                ]
                            )
                                |> Just
                        ]
                    )

                "familiar" ->
                    hit.source.abilityType
                        |> Maybe.map (viewLabelAndText "Ability Type")
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "familiar-specific" ->
                    (List.filterMap identity
                        [ hit.source.requiredAbilities
                            |> Maybe.map (viewLabelAndText "Required Number of Abilities")
                        , hit.source.familiarAbilities
                            |> String.join ", "
                            |> viewLabelAndText "Granted Abilities"
                            |> Just
                        ]
                    )

                "feat" ->
                    (List.filterMap identity
                        [ hit.source.frequency
                            |> Maybe.map (viewLabelAndText "Frequency")
                        , hit.source.prerequisites
                            |> Maybe.map (viewLabelAndText "Prerequisites")
                        , hit.source.trigger
                            |> Maybe.map (viewLabelAndText "Trigger")
                        , hit.source.requirements
                            |> Maybe.map (viewLabelAndText "Requirements")
                        ]
                    )

                "lesson" ->
                    hit.source.lessonType
                        |> Maybe.map (viewLabelAndText "Lesson Type")
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "patron" ->
                    hit.source.spellList
                        |> Maybe.map (viewLabelAndText "Spell List")
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "relic" ->
                    (List.filterMap identity
                        [ hit.source.aspect
                            |> Maybe.map (viewLabelAndText "Aspect")
                        , hit.source.prerequisites
                            |> Maybe.map (viewLabelAndText "Prerequisite")
                        ]
                    )

                "ritual" ->
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (List.filterMap identity
                            [ Maybe.map
                                (viewLabelAndText "Cast")
                                hit.source.cast
                            , Maybe.map
                                (viewLabelAndText "Cost")
                                hit.source.cost
                            , Maybe.map
                                (viewLabelAndText "Secondary Casters")
                                hit.source.secondaryCasters
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (List.filterMap identity
                            [ Maybe.map
                                (viewLabelAndText "Primary Check")
                                hit.source.primaryCheck
                            , Maybe.map
                                (viewLabelAndText "Secondary Checks")
                                hit.source.secondaryChecks
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (List.filterMap identity
                            [ Maybe.map
                                (viewLabelAndText "Range")
                                hit.source.range
                            , Maybe.map
                                (viewLabelAndText "Targets")
                                hit.source.targets
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (List.filterMap identity
                            [ Maybe.map
                                (viewLabelAndText "Duration")
                                hit.source.duration
                            ]
                        )
                    , hit.source.heighten
                        |> String.join ", "
                        |> String.Extra.nonEmpty
                        |> Maybe.map (viewLabelAndText "Heightened")
                        |> Maybe.withDefault (Html.text "")
                    ]

                "rules" ->
                    hit.source.breadcrumbs
                        |> Maybe.map Html.text
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "spell" ->
                    List.filterMap identity
                        [ hit.source.traditions
                            |> String.join ", "
                            |> String.Extra.nonEmpty
                            |> Maybe.map (viewLabelAndText "Traditions")

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ Maybe.map
                                    (viewLabelAndText "Cast")
                                    hit.source.cast
                                , hit.source.components
                                    |> String.join ", "
                                    |> String.Extra.nonEmpty
                                    |> Maybe.map (viewLabelAndText "Components")
                                , hit.source.trigger
                                    |> Maybe.map (viewLabelAndText "Trigger")
                                , hit.source.requirements
                                    |> Maybe.map (viewLabelAndText "Requirements")
                                ]
                            )
                                |> Just

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ Maybe.map
                                    (viewLabelAndText "Range")
                                    hit.source.range
                                , Maybe.map
                                    (viewLabelAndText "Targets")
                                    hit.source.targets
                                , Maybe.map
                                    (viewLabelAndText "Area")
                                    hit.source.area
                                ]
                            )
                                |> Just

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ Maybe.map
                                    (viewLabelAndText "Duration")
                                    hit.source.duration

                                , Maybe.map
                                    (viewLabelAndText "Saving Throw")
                                    hit.source.savingThrow
                                ]
                            )
                                |> Just
                        , hit.source.heighten
                            |> String.join ", "
                            |> String.Extra.nonEmpty
                            |> Maybe.map (viewLabelAndText "Heightened")
                        ]

                "weapon" ->
                    (List.filterMap identity
                        [ Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ hit.source.price
                                    |> Maybe.map (viewLabelAndText "Price")
                                , hit.source.damage
                                    |> Maybe.map (viewLabelAndText "Damage")
                                , hit.source.bulk
                                    |> Maybe.map (viewLabelAndText "Bulk")
                                ]
                            )
                                |> Just
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ hit.source.hands
                                    |> Maybe.map (viewLabelAndText "Hands")
                                , hit.source.range
                                    |> Maybe.map (viewLabelAndText "Range")
                                , hit.source.reload
                                    |> Maybe.map (viewLabelAndText "Reload")
                                ]
                            )
                                |> Just
                        , hit.source.ammunition
                            |> Maybe.map (viewLabelAndText "Ammunition")
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ hit.source.weaponCategory
                                    |> Maybe.map (viewLabelAndText "Category")
                                , hit.source.weaponGroup
                                    |> Maybe.map (viewLabelAndText "Group")
                                ]
                            )
                                |> Just
                        ]
                    )


                _ ->
                    []
            )
        )


numberWithSign : Int -> String
numberWithSign int =
    if int >= 0 then
        "+" ++ String.fromInt int

    else
        String.fromInt int


viewLabelAndText : String -> String -> Html msg
viewLabelAndText label text =
    Html.div
        []
        [ viewLabel label
        , Html.text " "
        , viewTextWithActionIcons text
        ]


viewLabel : String -> Html msg
viewLabel text =
    Html.span
        [ HA.class "bold" ]
        [ Html.text text ]


viewTextWithActionIcons : String -> Html msg
viewTextWithActionIcons text =
    Html.span
        []
        (replaceActionLigatures
            text
            ( "Single Action", "[one-action]" )
            [ ( "Two Actions", "[two-actions]" )
            , ( "Three Actions", "[three-actions]" )
            , ( "Reaction", "[reaction]" )
            , ( "Free Action", "[free-action]" )
            ]
        )


replaceActionLigatures : String -> ( String, String ) -> List ( String, String ) -> List (Html msg)
replaceActionLigatures text ( find, replace ) rem =
    if String.contains find text then
        case String.split find text of
            before :: after ->
                (List.append
                    [ Html.text before
                    , Html.span
                        [ HA.class "icon-font" ]
                        [ Html.text replace ]
                    ]
                    (replaceActionLigatures
                        (String.join find after)
                        ( find, replace )
                        rem
                    )
                )

            [] ->
                [ Html.text text ]

    else
        case rem of
            next :: remNext ->
                replaceActionLigatures text next remNext

            [] ->
                [ Html.text text ]


viewTrait : String -> Html msg
viewTrait trait =
    Html.div
        [ HA.class "trait"
        , case trait of
            "Uncommon" ->
                HA.class "trait-uncommon"

            "Rare" ->
                HA.class "trait-rare"

            "Unique" ->
                HA.class "trait-unique"

            "Tiny" ->
                HA.class "trait-size"

            "Small" ->
                HA.class "trait-size"

            "Medium" ->
                HA.class "trait-size"

            "Large" ->
                HA.class "trait-size"

            "Huge" ->
                HA.class "trait-size"

            "Gargantuan" ->
                HA.class "trait-size"

            "No Alignment" ->
                HA.class "trait-alignment"

            "LG" ->
                HA.class "trait-alignment"

            "LN" ->
                HA.class "trait-alignment"

            "LE" ->
                HA.class "trait-alignment"

            "NG" ->
                HA.class "trait-alignment"

            "N" ->
                HA.class "trait-alignment"

            "NE" ->
                HA.class "trait-alignment"

            "CG" ->
                HA.class "trait-alignment"

            "CN" ->
                HA.class "trait-alignment"

            "CE" ->
                HA.class "trait-alignment"

            _ ->
                HAE.empty
        ]
        [ Html.text trait ]


stringContainsChar : String -> String -> Bool
stringContainsChar str chars =
    String.any
        (\char ->
            String.contains (String.fromChar char) str
        )
        chars


css : String
css =
    """
    @font-face {
        font-family: "Pathfinder-Icons";
        src: url("Pathfinder-Icons.ttf");
        font-display: swap;
    }

    :root {
        --gap-tiny: 4px;
        --gap-small: 8px;
        --gap-medium: 12px;
        --gap-large: 20px;
        --font-normal: 16px;
        --font-large: 20px;
        --font-very-large: 24px;
    }

    body {
        background-color: var(--color-bg);
        color: var(--color-text);
        font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif;
        margin: 0px;
    }

    a {
        color: inherit;
    }

    a:hover, button:hover {
        text-decoration: underline;
    }

    button {
        border-width: 1px;
        border-style: solid;
        border-radius: 4px;
        background-color: transparent;
        color: var(--color-text);
        font-size: var(--font-normal);
    }

    button.active {
        background-color: var(--color-text);
        color: var(--color-bg);
    }

    button.excluded {
        color: var(--color-inactive-text);
    }

    h1 {
        font-size: 48px;
        font-weight: normal;
        margin: 0;
    }

    h2 {
        font-size: var(--font-very-large);
        margin: 0;
    }

    h3 {
        font-size: var(--font-large);
        margin: 0;
    }

    input[type=text] {
        background-color: var(--color-bg);
        border-style: solid;
        border-radius: 4px;
        color: var(--color-text);
        padding: 4px;
        width: 100%;
    }

    .align-baseline {
        align-items: baseline;
    }

    .align-center {
        align-items: center;
    }

    .align-stretch {
        align-items: stretch;
    }

    .body-container {
        align-items: center;
        min-height: 100%;
        min-width: 400px;
        position: relative;
    }

    .bold {
        font-weight: 700;
    }

    .column {
        display: flex;
        flex-direction: column;
    }

    .content-container {
        box-sizing: border-box;
        max-width: 1000px;
        padding: 8px;
        width: 100%;
    }

    .row {
        display: flex;
        flex-direction: row;
        flex-wrap: wrap;
    }

    .column:empty, .row:empty {
        display: none;
    }

    .filter-type {
        border-radius: 4px;
        border-width: 0;
        background-color: var(--color-element-bg);
        color: var(--color-element-text);
        font-size: 16px;
        font-variant: small-caps;
        font-weight: 700;
        padding: 4px 9px;
    }

    .filter-type.excluded {
        background-color: var(--color-element-inactive-bg);
        color: var(--color-element-inactive-text);
    }

    .gap-large {
        gap: var(--gap-large);
    }

    .gap-medium {
        gap: var(--gap-medium);
    }

    .gap-medium.row, .gap-large.row {
        row-gap: var(--gap-tiny);
    }

    .gap-small {
        gap: var(--gap-small);
    }

    .gap-tiny {
        gap: var(--gap-tiny);
    }

    .icon-font {
        color: var(--color-icon);
        font-family: "Pathfinder-Icons";
        font-variant-caps: normal;
        font-weight: normal;
    }

    .input-button {
        aspect-ratio: 1 / 1;
        background-color: transparent;
        border-width: 0;
        color: var(--color-text);
        height: 100%;
        right: 0px;
        position: absolute;
    }

    .menu {
        align-self: flex-start;
        background-color: var(--color-bg);
        border-width: 0px 1px 1px 0px;
        border-style: solid;
        max-width: 400px;
        padding: 8px;
        position: absolute;
        transition: transform ease-in-out 0.2s;
        width: 85%;
        z-index: 2;
    }

    .menu-close-button {
        align-self: flex-end;
        border: 0;
        font-size: 32px;
        margin-top: -8px;
        padding: 8px;
    }

    .menu-open-button {
        border: 0;
        font-size: 32px;
        left: 0;
        padding: 8px;
        position: absolute;
    }

    .menu-overlay {
        background-color: #44444488;
        height: 100%;
        position: absolute;
        transition: background-color ease-in-out 0.25s;
        width: 100%;
        z-index: 1;
    }

    .menu-overlay-hidden {
        background-color: #44444400;
        pointer-events: none;
    }

    .monospace {
        background-color: var(--color-bg-secondary);
        font-family: monospace;
        font-size: var(--font-normal);
    }

    .nowrap {
        flex-wrap: nowrap;
    }

    .option-container {
        border-style: solid;
        border-width: 1px;
        background-color: var(--color-container-bg);
        gap: var(--gap-small);
        padding: 8px;
    }

    .query-input {
        font-size: var(--font-very-large);
    }

    .query-options-container {
        transition: height ease-in-out 0.2s;
        overflow: clip;
    }

    .query-options-dummy {
        position: absolute;
        visibility: hidden;
    }

    .scrollbox {
        background-color: var(--color-bg-secondary);
        border-color: #767676;
        border-radius: 4px;
        border-style: solid;
        border-width: 1px;
        max-height: 150px;
        overflow-y: auto;
        padding: 4px;
    }

    .subtitle {
        border-radius: 4px;
        background-color: var(--color-subelement-bg);
        color: var(--color-subelement-text);
        font-variant: small-caps;
        line-height: 1rem;
        padding: 4px 9px;
    }

    .subtitle:empty {
        display: none;
    }

    .title {
        border-radius: 4px;
        background-color: var(--color-element-bg);
        border-color: var(--color-container-border);
        color: var(--color-element-text);
        display: flex;
        flex-direction: row;
        font-size: var(--font-very-large);
        font-variant: small-caps;
        font-weight: 700;
        gap: var(--gap-small);
        justify-content: space-between;
        padding: 4px 9px;
    }

    .title .icon-font {
        color: var(--color-element-icon);
    }

    .title a {
        text-decoration: none;
    }

    .title a:hover {
        text-decoration: underline;
    }

    .title-type {
        text-align: right;
    }

    .trait {
        background-color: var(--color-element-bg);
        border-color: var(--color-element-border);
        border-style: double;
        border-width: 2px;
        color: #eeeeee;
        padding: 3px 5px;
        font-size: 16px;
        font-variant: small-caps;
        font-weight: 700;
    }

    .trait.excluded {
        background-color: var(--color-element-inactive-bg);
        border-color: var(--color-element-inactive-border);
        color: var(--color-inactive-text);
    }

    .trait-alignment {
        background-color: #4287f5;
    }

    .trait-rare {
        background-color: #0c1466;
    }

    .trait-size {
        background-color: #478c42;
    }

    .trait-uncommon {
        background-color: #c45500;
    }

    .trait-unique {
        background-color: #800080;
    }

    .loader {
        width: 48px;
        height: 48px;
        border: 5px solid #FFF;
        border-bottom-color: transparent;
        border-radius: 50%;
        display: inline-block;
        box-sizing: border-box;
        align-self: center;
        animation: rotation 1s linear infinite;
    }

    @keyframes rotation {
        0% {
            transform: rotate(0deg);
        }
        100% {
            transform: rotate(360deg);
        }
    }
    """


cssDark : String
cssDark =
    """
    :root {
        --color-bg: #111111;
        --color-bg-secondary: #282828;
        --color-container-bg: #333333;
        --color-container-border: #eeeeee;
        --color-element-bg: #522e2c;
        --color-element-border: #d8c483;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #291716;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #656148;
        --color-element-text: #cbc18f;
        --color-subelement-bg: #806e45;
        --color-subelement-text: #111111;
        --color-icon: #cccccc;
        --color-inactive-text: #999999;
        --color-text: #eeeeee;
    }
    """


cssLight : String
cssLight =
    """
    :root {
        --color-bg: #eeeeee;
        --color-bg-secondary: #cccccc;
        --color-container-bg: #dddddd;
        --color-container-border: #111111;
        --color-element-bg: #6f413e;
        --color-element-border: #d8c483;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #462b29;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #87805f;
        --color-element-text: #cbc18f;
        --color-subelement-bg: #cbc18f;
        --color-subelement-text: #111111;
        --color-icon: #111111;
        --color-inactive-text: #999999;
        --color-text: #111111;
    }
    """


cssPaper : String
cssPaper =
    """
    :root {
        --color-bg: #f1ece5;
        --color-bg-secondary: #cccccc;
        --color-container-bg: #dddddd;
        --color-container-border: #111111;
        --color-element-bg: #5d0000;
        --color-element-border: #d8c483;
        --color-element-icon: #111111;
        --color-element-inactive-bg: #3e0000;
        --color-element-inactive-border: #48412c;
        --color-element-inactive-text: #87805f;
        --color-element-text: #cbc18f;
        --color-subelement-bg: #dbd0bc;
        --color-subelement-text: #111111;
        --color-icon: #111111;
        --color-inactive-text: #999999;
        --color-text: #111111;
    }
    """
