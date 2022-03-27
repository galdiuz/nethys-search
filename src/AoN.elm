module AoN exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Dict exposing (Dict)
import FontAwesome.Icon
import FontAwesome.Solid
import FontAwesome.Regular
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
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Maybe.Extra
import Process
import Regex
import Result.Extra
import String.Extra
import Task
import Url exposing (Url)
import Url.Builder
import Url.Parser
import Url.Parser.Query


type alias Flags =
    { elasticUrl : String
    }


type alias Model =
    { documents : Dict String (Result Http.Error Document)
    , elasticUrl : String
    , navKey : Browser.Navigation.Key
    , page : Page
    , search : Dict String SearchModel
    , url : Url
    }


type alias SearchModel =
    { debounce : Int
    , defaultSort : List ( String, SortDir )
    , filteredTraits : Dict String Bool
    , fixedFilters : List ( String, String )
    , optionsHeight : Int
    , optionsOpen : Bool
    , query : String
    , queryType : QueryType
    , searchResults : List (Result Http.Error SearchResult)
    , searchTraitsInput : String
    , traits : List String
    , tracker : Maybe Int
    }


type alias SearchResult =
    { documents : List (Document)
    , searchAfter : Encode.Value
    , total : Int
    }


type SortDir
    = Asc
    | Desc


type alias Document =
    { id : String
    , category : String
    , name : String
    , type_ : String
    , url : String
    , abilities : List String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , ammunition : Maybe String
    , aonUrl : Maybe String
    , area : Maybe String
    , aspect : Maybe String
    , bloodlines : List String
    , breadcrumbs : List String
    , bulk : Maybe String
    , cast : Maybe String
    , charisma : Maybe Int
    , components : List String
    , constitution : Maybe Int
    , cost : Maybe String
    , creatureFamily : Maybe String
    , damage : Maybe String
    , deities : List String
    , dexterity : Maybe Int
    , divineFont : Maybe String
    , domains : List String
    , domainSpell : Maybe String
    , duration : Maybe String
    , familiarAbilities : List String
    , favoredWeapon : Maybe String
    , feats : List String
    , fort : Maybe Int
    , frequency : Maybe String
    , hands : Maybe String
    , heighten : List String
    , hp : Maybe Int
    , immunities : List String
    , intelligence : Maybe Int
    , lessonType : Maybe String
    , level : Maybe Int
    , markdown : String
    , mysteries : List String
    , patronThemes : List String
    , perception : Maybe Int
    , prerequisites : Maybe String
    , price : Maybe String
    , primaryCheck : Maybe String
    , range : Maybe String
    , ref : Maybe Int
    , reload : Maybe String
    , requiredAbilities : Maybe String
    , requirements : Maybe String
    , resistances : List String
    , savingThrow : Maybe String
    , secondaryCasters : Maybe String
    , secondaryChecks : Maybe String
    , skills : List String
    , sources : List String
    , spellList : Maybe String
    , spoilers : Maybe String
    , strength : Maybe Int
    , targets : Maybe String
    , traditions : List String
    , traits : List String
    , trigger : Maybe String
    , usage : Maybe String
    , weaknesses : List String
    , weaponCategory : Maybe String
    , weaponGroup : Maybe String
    , will : Maybe Int
    , wisdom : Maybe Int
    }


type QueryType
    = Standard
    | ElasticsearchQueryString


type Page
    = Action String
    | Class String
    | Classes
    | ClassFeats String
    -- | Equipment
    | Feat String
    | Instinct String
    | Instincts
    | Home
    | NotFound
    | Rule (List String)
    | Rules
    | SampleBuild String String
    | SampleBuilds String
    | Trait String
    | Traits


type Msg
    = GotDocument String (Result Http.Error Document)
    | GotDocuments (List String) (Result Http.Error (List (Result String Document)))
    | GotQueryOptionsHeight Int
    | GotSearchResult String (Result Http.Error SearchResult)
    | GotTraitAggs String (Result Http.Error (List String))
    | LoadMoreSearchResultsPressed
    | NoOp
    | QueryChanged String String
    | QueryOptionsPressed String Bool
    | QueryTypeSelected String QueryType
    | RemoveAllTraitFiltersPressed String
    | SearchDebouncePassed String Int
    | SearchTraitsChanged String String
    | TraitFilterPressed String String
    | UrlChanged Url.Url
    | UrlRequested Browser.UrlRequest
    | WindowResized Int Int


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


init : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        page : Page
        page =
            urlToPage url
    in
    ( { documents = Dict.empty
      , elasticUrl = flags.elasticUrl
      , navKey = navKey
      , page = page
      , search =
            case getSearchKey page of
                Just key ->
                    Dict.insert
                        key
                        (updateSearchModelFromQueryString url (emptySearchModel page))
                        Dict.empty

                Nothing ->
                    Dict.empty
      , url = url
      }
    , Cmd.none
    )
        |> fetchData
        |> searchWithCurrentSearchModel


subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onResize WindowResized


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDocument id result ->
            ( { model | documents = Dict.insert id result model.documents }
            , result
                |> Result.map .markdown
                |> Result.map getChildDocuments
                |> Debug.log "child ids"
                |> Result.map (fetchDocuments model)
                |> Result.withDefault Cmd.none
            )

        GotDocuments ids result ->
            ( { model
                | documents =
                    Dict.union
                        model.documents
                        (ids
                            |> List.map
                                (\id ->
                                    ( id
                                    , Result.andThen
                                        (\docs ->
                                            docs
                                                |> List.filterMap (Result.toMaybe)
                                                |> List.Extra.find (.id >> (==) id)
                                                |> Result.fromMaybe (Http.BadStatus 404)
                                        )
                                        result
                                    )
                                )
                            |> Dict.fromList
                        )
              }
            , result
                |> Result.map (List.filterMap (Result.toMaybe))
                |> Result.map (List.map .markdown)
                |> Result.map (List.concatMap getChildDocuments)
                |> Result.map (fetchDocuments model)
                |> Result.withDefault Cmd.none
            )

        GotQueryOptionsHeight height ->
            case getSearchKey model.page of
                Just key ->
                    ( { model
                        | search =
                            Dict.update
                                key
                                (Maybe.map
                                    (\search ->
                                        { search | optionsHeight = height }
                                    )
                                )
                                model.search
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model
                    , Cmd.none
                    )

        GotSearchResult key result ->
            ( { model
                | documents =
                    Dict.union
                        model.documents
                        (result
                            |> Result.map .documents
                            |> Result.map
                                (List.map
                                    (\document ->
                                        ( document.id, Ok document )
                                    )
                                )
                            |> Result.withDefault []
                            |> Dict.fromList
                        )
                , search =
                    Dict.update
                        key
                        (Maybe.map
                            (\search ->
                                { search
                                    | searchResults =
                                        List.append
                                            (List.filter Result.Extra.isOk search.searchResults)
                                            [ result ]
                                    , tracker = Nothing
                                }
                            )
                        )
                        model.search
              }
            , Cmd.none
            )

        GotTraitAggs key result ->
            ( { model
                | search =
                    Dict.update
                        key
                        (Maybe.map
                            (\search ->
                                { search | traits = Result.withDefault [] result }
                            )
                        )
                        model.search
              }
            , getQueryOptionsHeight
            )

        LoadMoreSearchResultsPressed ->
            ( model
            , Cmd.none
            )
                |> searchWithCurrentSearchModel

        NoOp ->
            ( model
            , Cmd.none
            )

        QueryChanged key value ->
            let
                newDebounce : Int
                newDebounce =
                    Dict.get key model.search
                        |> Maybe.map .debounce
                        |> Maybe.withDefault 0
            in
            ( { model
                | search =
                    Dict.update
                        key
                        (Maybe.map
                            (\search ->
                                { search
                                    | debounce = newDebounce
                                    , query = value
                                }
                            )
                        )
                        model.search
              }
            , Process.sleep 250
                |> Task.perform (\_ -> SearchDebouncePassed key newDebounce)
            )

        QueryTypeSelected key value ->
            ( { model
                | search =
                    Dict.update
                        key
                        (Maybe.map
                            (\search ->
                                { search | queryType = value }
                            )
                        )
                        model.search
              }
            , Cmd.none
            )

        RemoveAllTraitFiltersPressed key ->
            ( { model
                | search =
                    Dict.update
                        key
                        (Maybe.map
                            (\search ->
                                { search | filteredTraits = Dict.empty }
                            )
                        )
                        model.search
              }
            , Dict.get key model.search
                |> Maybe.map
                    (\search ->
                        { search | filteredTraits = Dict.empty }
                    )
                |> Maybe.map (updateUrlWithSearchParams model)
                |> Maybe.withDefault Cmd.none
            )

        SearchDebouncePassed key debounce ->
            if (getSearchKey model.page == Just key)
                && (Dict.get key model.search
                    |> Maybe.map .debounce
                    |> (==) (Just debounce)
                )
            then
                ( model
                , Dict.get key model.search
                    |> Maybe.map (updateUrlWithSearchParams model)
                    |> Maybe.withDefault Cmd.none
                )

            else
                ( model, Cmd.none )

        QueryOptionsPressed key value ->
            if value then
                ( model
                , getQueryOptionsHeight
                )

            else
                ( { model
                    | search =
                        Dict.update
                            key
                            (Maybe.map
                                (\search ->
                                    { search | optionsHeight = 0 }
                                )
                            )
                            model.search
                  }
                , Cmd.none
                )

        SearchTraitsChanged key value ->
            ( { model
                | search =
                    Dict.update
                        key
                        (Maybe.map
                            (\search ->
                                { search | searchTraitsInput = value }
                            )
                        )
                        model.search
              }
            , getQueryOptionsHeight
            )

        TraitFilterPressed key trait ->
            ( model
            , Dict.get key model.search
                |> Maybe.map
                    (\search ->
                        { search
                            | filteredTraits =
                                Dict.update
                                    trait
                                    (\value ->
                                        case value of
                                            Just True ->
                                                Just False

                                            Just False ->
                                                Nothing

                                            Nothing ->
                                                Just True
                                    )
                                    search.filteredTraits


                        }
                    )
                |> Maybe.map (updateUrlWithSearchParams model)
                |> Maybe.withDefault Cmd.none
            )

        UrlChanged url ->
            let
                page : Page
                page =
                    urlToPage url
            in
            ( { model
                | page = page
                , search =
                    case getSearchKey page of
                        Just key ->
                            Dict.update
                                key
                                (Maybe.withDefault (emptySearchModel page)
                                    >> updateSearchModelFromQueryString url
                                    >> Just
                                )
                                model.search

                        Nothing ->
                            model.search
                , url = url
              }
            , Cmd.none
            )
                |> fetchData
                |> searchWithCurrentSearchModel

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


emptySearchModel : Page -> SearchModel
emptySearchModel page =
    { debounce = 0
    , defaultSort =
        case page of
            ClassFeats _ ->
                [ ( "level", Asc ), ( "name.keyword", Asc ) ]
            _ ->
                []
    , filteredTraits = Dict.empty
    , fixedFilters =
        case page of
            ClassFeats class ->
                [ ( "trait", class ), ( "type", "feat" ) ]

            _ ->
                []
    , optionsHeight = 0
    , optionsOpen = False
    , query = ""
    , queryType = Standard
    , searchResults = []
    , searchTraitsInput = ""
    , traits = []
    , tracker = Nothing
    }


updateSearchModelFromQueryString : Url -> SearchModel -> SearchModel
updateSearchModelFromQueryString url searchModel =
    { searchModel
        | query = getQueryParam url "q"
        , filteredTraits =
            List.append
                (getQueryParam url "include-traits"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\trait -> ( trait, True ))
                )
                (getQueryParam url "exclude-traits"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\trait -> ( trait, False ))
                )
                |> Dict.fromList
        , searchResults = []
    }


getQueryParam : Url -> String -> String
getQueryParam url param =
    { url | path = "" }
        |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string param))
        |> Maybe.Extra.join
        |> Maybe.withDefault ""


getQueryOptionsHeight =
    Browser.Dom.getViewportOf "search-options-measure-wrapper"
        |> Task.map .scene
        |> Task.map .height
        |> Task.map round
        |> Task.attempt (Result.withDefault 0 >> GotQueryOptionsHeight)


updateUrlWithSearchParams : Model -> SearchModel -> Cmd Msg
updateUrlWithSearchParams { navKey, url } searchModel =
    { url
        | query =
            [ ( "q", searchModel.query )
            , ( "include-traits"
              , searchModel.filteredTraits
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-traits"
              , searchModel.filteredTraits
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
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
        |> Browser.Navigation.pushUrl navKey


dasherize : String -> String
dasherize string =
    string
        |> String.trim
        |> Regex.replace (regexFromString "([A-Z]+)") (.match >> String.append "-")
        |> String.replace "'" ""
        |> String.replace "&" "and"
        |> Regex.replace (regexFromString "[^a-zA-Z0-9]+") (\_ -> "-")
        |> Regex.replace (regexFromString "^-+|-+$") (\_ -> "")
        |> String.toLower


regexFromString : String -> Regex.Regex
regexFromString =
    Regex.fromString >> Maybe.withDefault Regex.never


urlToPage : Url.Url -> Page
urlToPage url =
    case String.split "/" (String.dropLeft 1 url.path) of
        [ "" ] ->
            Home

        [ "actions", id ] ->
            Action id

        [ "classes" ] ->
            Classes

        [ "classes", id ] ->
            Class id

        [ "classes", class, "feats" ] ->
            ClassFeats class

        [ "classes", "barbarian", "instincts", id ] ->
            Instinct id

        [ "classes", "barbarian", "instincts" ] ->
            Instincts

        [ "classes", class, "sample-builds", id ] ->
            SampleBuild class id

        [ "classes", class, "sample-builds" ] ->
            SampleBuilds class

        [ "feats", id ] ->
            Feat id

        [ "rules" ] ->
            Rules

        "rules" :: ids  ->
            Rule ids

        [ "traits", id ] ->
            Trait id

        [ "traits" ] ->
            Traits

        _ ->
            NotFound


documentToUrl : Document -> String
documentToUrl document =
    case document.category of
        "action" ->
            "/actions/" ++ document.url

        "class" ->
            "/classes/" ++ document.url

        "rules" ->
            List.append document.breadcrumbs [ document.name ]
                |> List.map dasherize
                |> String.join "/"
                |> (++) "/"

        _ ->
            ""


pageToDataKey : Page -> Maybe String
pageToDataKey page =
    case page of
        Action id ->
            Just ("action-" ++ id)

        Class id ->
            Just ("class-" ++ id)

        Feat id ->
            Just ("feat-" ++ id)

        Instincts ->
            Just "instincts"

        Rule ids ->
            Just ("rules-" ++ String.join "-" ids)

        Rules ->
            Just "rules"

        Trait id ->
            Just ("trait-" ++ id)

        NotFound ->
            Nothing

        _ ->
            Nothing


searchWithCurrentSearchModel : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
searchWithCurrentSearchModel ( model, cmd ) =
    case getSearchKey model.page of
        Just key ->
            let
                searchModel : SearchModel
                searchModel =
                    Dict.get key model.search
                        |> Maybe.withDefault (emptySearchModel model.page)

                newTracker : Int
                newTracker =
                    searchModel.tracker
                        |> Maybe.withDefault 0
                        |> (+) 1
            in
            ( { model
                | search =
                    Dict.insert
                        key
                        { searchModel | tracker = Just newTracker }
                        model.search
              }
            , Cmd.batch
                [ cmd
                , case searchModel.tracker of
                    Just oldTracker ->
                        Http.cancel ("search-" ++ String.fromInt oldTracker)

                    Nothing ->
                        Cmd.none
                , Http.request
                    { method = "POST"
                    , url = model.elasticUrl ++ "/_search"
                    , headers = []
                    , body = Http.jsonBody (buildSearchBody searchModel)
                    , expect = Http.expectJson (GotSearchResult key) searchResultDecoder
                    , timeout = Just 10000
                    , tracker = Just ("search-" ++ String.fromInt newTracker)
                    }

                , if List.isEmpty searchModel.traits then
                    getTraitAggs model key searchModel

                  else
                    Cmd.none
                ]
            )

        Nothing ->
            ( model
            , cmd
            )


getTraitAggs : Model -> String -> SearchModel -> Cmd Msg
getTraitAggs model key searchModel =
    Http.request
        { method = "POST"
        , url = model.elasticUrl ++ "/_search"
        , headers = []
        , body = Http.jsonBody (buildAggsBody searchModel)
        , expect = Http.expectJson (GotTraitAggs key) aggsResultDecoder
        , timeout = Just 10000
        , tracker = Nothing
        }


buildAggsBody : SearchModel -> Encode.Value
buildAggsBody searchModel =
    Encode.object
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , Encode.object
                        [ ( "filter"
                          , searchModel.fixedFilters
                                |> List.map
                                    (\( field, value ) ->
                                        [ ( "term"
                                        , Encode.object
                                            [ ( field
                                              , Encode.object
                                                    [ ( "value", Encode.string value ) ]
                                              )
                                            ]
                                          )
                                        ]
                                    )
                                |> Encode.list Encode.object
                          )
                        ]
                  )
                ]
          )
        , ( "aggs"
          , Encode.object
                [ ( "traits"
                  , Encode.object
                        [ ( "terms"
                          , Encode.object
                                [ ( "field", Encode.string "trait" )
                                , ( "size", Encode.int 10000 )
                                ]
                          )
                        ]
                  )
                ]
          )
        , ( "size", Encode.int 0 )
        ]


getSearchKey : Page -> Maybe String
getSearchKey page =
    case page of
        ClassFeats class ->
            Just ("class-feats-" ++ class)

        _ ->
            Nothing


buildSearchBody : SearchModel -> Encode.Value
buildSearchBody searchModel =
    let
        includedTraits : List String
        includedTraits =
            searchModel.filteredTraits
                |> Dict.toList
                |> List.filter (Tuple.second)
                |> List.map Tuple.first


        excludedTraits : List String
        excludedTraits =
            searchModel.filteredTraits
                |> Dict.toList
                |> List.filter (Tuple.second >> not)
                |> List.map Tuple.first

        filters : List (List ( String, Encode.Value ))
        filters =
            List.concat
                [ searchModel.fixedFilters
                    |> List.map
                        (\( field, value ) ->
                            [ ( "term"
                            , Encode.object
                                [ ( field
                                  , Encode.object
                                        [ ( "value", Encode.string value ) ]
                                  )
                                ]
                              )
                            ]
                        )
                , if List.isEmpty includedTraits then
                    []

                  else
                    [ [ ( "terms"
                        , Encode.object
                            [ ( "trait"
                              , Encode.list Encode.string includedTraits
                              )
                            ]
                        )
                      ]
                    ]
                ]

        mustNots : List (List ( String, Encode.Value ))
        mustNots =
            List.concat
                [ if List.isEmpty excludedTraits then
                    []

                  else
                    [ [ ( "terms"
                        , Encode.object
                            [ ( "trait"
                              , Encode.list Encode.string excludedTraits
                              )
                            ]
                        )
                      ]
                    ]
                ]
    in
    encodeObjectMaybe
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , encodeObjectMaybe
                        [ if String.isEmpty searchModel.query then
                            Nothing

                          else
                            ( "should"
                            , Encode.list Encode.object
                                (case searchModel.queryType of
                                    Standard ->
                                        buildStandardQueryBody searchModel.query

                                    ElasticsearchQueryString ->
                                        buildElasticsearchQueryStringQueryBody searchModel.query
                                )
                            )
                                |> Just

                        , if List.isEmpty filters then
                            Nothing

                          else
                            ( "filter"
                            , Encode.list Encode.object filters
                            )
                                |> Just

                        , if List.isEmpty excludedTraits then
                            Nothing

                          else
                            ( "must_not"
                            , Encode.list Encode.object mustNots
                            )
                                |> Just

                        , if String.isEmpty searchModel.query then
                            Nothing

                          else
                            Just ( "minimum_should_match", Encode.int 1 )
                        ]
                  )
                ]
          )
            |> Just

        , ( "size", Encode.int 50 )
            |> Just

        , ( "sort"
          , Encode.list identity
                (if List.isEmpty searchModel.defaultSort then
                    [ Encode.string "_score"
                    , Encode.string "_doc"
                    ]

                 else
                     List.append
                        (List.map
                            (\( field, dir ) ->
                                Encode.object
                                    [ ( field
                                      , Encode.object
                                            [ ( "order", Encode.string (sortDirToString dir) )
                                            ]
                                      )
                                    ]
                            )
                            searchModel.defaultSort
                        )
                        [ Encode.string "_doc" ]
                )
          )
            |> Just

        , ( "_source"
          , Encode.object
                [ ( "excludes", Encode.list Encode.string [ "text" ] ) ]
          )
            |> Just

        , searchModel.searchResults
            |> List.Extra.last
            |> Maybe.andThen (Result.toMaybe)
            |> Maybe.map .searchAfter
            |> Maybe.map (Tuple.pair "search_after")
        ]


sortDirToString : SortDir -> String
sortDirToString dir =
    case dir of
        Asc ->
            "asc"

        Desc ->
            "desc"


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


searchFields : List String
searchFields =
    [ "name"
    , "text^0.1"
    , "trait_raw"
    , "type"
    ]


encodeObjectMaybe : List (Maybe ( String, Encode.Value )) -> Encode.Value
encodeObjectMaybe list =
    Maybe.Extra.values list
        |> Encode.object


fetchData : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fetchData ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , case pageToDataKey model.page of
            Just id ->
                fetchDocument model id

            Nothing ->
                Cmd.none
        ]
    )


fetchDocument : Model -> String -> Cmd Msg
fetchDocument model id =
    case Dict.get id model.documents of
        Just _ ->
            Cmd.none

        Nothing ->
            Http.request
                { method = "GET"
                , url = model.elasticUrl ++ "/_doc/" ++ id
                , headers = []
                , body = Http.emptyBody
                , expect = Http.expectJson (GotDocument id) documentDecoder
                , timeout = Just 10000
                , tracker = Nothing
                }


fetchDocuments : Model -> List String -> Cmd Msg
fetchDocuments model ids =
    let
        idsToFetch : List String
        idsToFetch =
            List.filter
                (\id -> not (Dict.member id model.documents))
                ids
    in
    if List.isEmpty idsToFetch then
        Cmd.none

    else
        Http.request
            { method = "POST"
            , url = model.elasticUrl ++ "/_mget"
            , headers = []
            , body =
                Http.jsonBody
                    (Encode.object
                        [ ( "docs"
                          , Encode.list
                                (\id ->
                                    Encode.object [ ( "_id", Encode.string id ) ]
                                )
                                idsToFetch
                          )
                        ]
                    )
            , expect =
                Http.expectJson
                    (GotDocuments idsToFetch)
                    (Decode.field
                        "docs"
                        (Decode.list
                            (Decode.oneOf
                                [ Decode.map Ok documentDecoder
                                , Decode.map Err (Decode.field "_id" Decode.string)
                                ]
                            )
                        )
                    )
            , timeout = Just 10000
            , tracker = Nothing
            }


aggsResultDecoder : Decode.Decoder (List String)
aggsResultDecoder =
    Decode.at
        [ "aggregations", "traits", "buckets" ]
        (Decode.list (Decode.field "key" Decode.string))



searchResultDecoder : Decode.Decoder SearchResult
searchResultDecoder =
    Field.requireAt [ "hits", "hits" ] (Decode.list documentDecoder) <| \documents ->
    Field.requireAt [ "hits", "hits" ] (Decode.list (Decode.field "sort" Decode.value)) <| \sorts ->
    Field.requireAt [ "hits", "total", "value" ] Decode.int <| \total ->
    Decode.succeed
        { documents = documents
        , searchAfter =
            sorts
                |> List.Extra.last
                |> Maybe.withDefault Encode.null
        , total = total
        }


documentDecoder : Decode.Decoder Document
documentDecoder =
    Field.requireAt [ "_id" ] Decode.string <| \id ->
    Field.requireAt [ "_source", "category" ] Decode.string <| \category ->
    Field.requireAt [ "_source", "name" ] Decode.string <| \name ->
    Field.requireAt [ "_source", "type" ] Decode.string <| \type_ ->
    Field.requireAt [ "_source", "url" ] Decode.string <| \url ->
    Field.attemptAt [ "_source", "markdown" ] Decode.string <| \markdown ->
    Field.attemptAt [ "_source", "ability" ] stringListDecoder <| \abilities ->
    Field.attemptAt [ "_source", "ability_type" ] Decode.string <| \abilityType ->
    Field.attemptAt [ "_source", "ac" ] Decode.int <| \ac ->
    Field.attemptAt [ "_source", "actions" ] Decode.string <| \actions ->
    Field.attemptAt [ "_source", "activate" ] Decode.string <| \activate ->
    Field.attemptAt [ "_source", "advanced_domain_spell" ] Decode.string <| \advancedDomainSpell ->
    Field.attemptAt [ "_source", "alignment" ] Decode.string <| \alignment ->
    Field.attemptAt [ "_source", "ammunition" ] Decode.string <| \ammunition ->
    Field.attemptAt [ "_source", "aon_url" ] Decode.string <| \aonUrl ->
    Field.attemptAt [ "_source", "area" ] Decode.string <| \area ->
    Field.attemptAt [ "_source", "aspect" ] Decode.string <| \aspect ->
    Field.attemptAt [ "_source", "breadcrumbs" ] stringListDecoder <| \breadcrumbs ->
    Field.attemptAt [ "_source", "bloodline" ] stringListDecoder <| \bloodlines ->
    Field.attemptAt [ "_source", "bulk_raw" ] Decode.string <| \bulk ->
    Field.attemptAt [ "_source", "cast" ] Decode.string <| \cast ->
    Field.attemptAt [ "_source", "charisma" ] Decode.int <| \charisma ->
    Field.attemptAt [ "_source", "component" ] (Decode.list Decode.string) <| \components ->
    Field.attemptAt [ "_source", "constitution" ] Decode.int <| \constitution ->
    Field.attemptAt [ "_source", "cost" ] Decode.string <| \cost ->
    Field.attemptAt [ "_source", "creature_family" ] Decode.string <| \creatureFamily ->
    Field.attemptAt [ "_source", "damage" ] Decode.string <| \damage ->
    Field.attemptAt [ "_source", "deity" ] stringListDecoder <| \deities ->
    Field.attemptAt [ "_source", "dexterity" ] Decode.int <| \dexterity ->
    Field.attemptAt [ "_source", "divine_font" ] Decode.string <| \divineFont ->
    Field.attemptAt [ "_source", "domain" ] (Decode.list Decode.string) <| \domains ->
    Field.attemptAt [ "_source", "domain_spell" ] Decode.string <| \domainSpell ->
    Field.attemptAt [ "_source", "duration" ] Decode.string <| \duration ->
    Field.attemptAt [ "_source", "familiar_ability" ] stringListDecoder <| \familiarAbilities ->
    Field.attemptAt [ "_source", "favored_weapon" ] Decode.string <| \favoredWeapon ->
    Field.attemptAt [ "_source", "feat" ] stringListDecoder <| \feats ->
    Field.attemptAt [ "_source", "fortitude_save" ] Decode.int <| \fort ->
    Field.attemptAt [ "_source", "frequency" ] Decode.string <| \frequency ->
    Field.attemptAt [ "_source", "hands" ] Decode.string <| \hands ->
    Field.attemptAt [ "_source", "heighten" ] (Decode.list Decode.string) <| \heighten ->
    Field.attemptAt [ "_source", "hp" ] Decode.int <| \hp ->
    Field.attemptAt [ "_source", "immunity" ] (Decode.list Decode.string) <| \immunities ->
    Field.attemptAt [ "_source", "intelligence" ] Decode.int <| \intelligence ->
    Field.attemptAt [ "_source", "lesson_type" ] Decode.string <| \lessonType ->
    Field.attemptAt [ "_source", "level" ] Decode.int <| \level ->
    Field.attemptAt [ "_source", "mystery" ] stringListDecoder <| \mysteries ->
    Field.attemptAt [ "_source", "patron_theme" ] stringListDecoder <| \patronThemes ->
    Field.attemptAt [ "_source", "perception" ] Decode.int <| \perception ->
    Field.attemptAt [ "_source", "prerequisite" ] Decode.string <| \prerequisites ->
    Field.attemptAt [ "_source", "price_raw" ] Decode.string <| \price ->
    Field.attemptAt [ "_source", "primaryCheck" ] Decode.string <| \primaryCheck ->
    Field.attemptAt [ "_source", "range_raw" ] Decode.string <| \range ->
    Field.attemptAt [ "_source", "reflex_save" ] Decode.int <| \ref ->
    Field.attemptAt [ "_source", "reload_raw" ] Decode.string <| \reload ->
    Field.attemptAt [ "_source", "required_abilities" ] Decode.string <| \requiredAbilities ->
    Field.attemptAt [ "_source", "requirement" ] Decode.string <| \requirements ->
    Field.attemptAt [ "_source", "resistance_raw" ] (Decode.list Decode.string) <| \resistances ->
    Field.attemptAt [ "_source", "saving_throw" ] Decode.string <| \savingThrow ->
    Field.attemptAt [ "_source", "secondary_casters_raw" ] Decode.string <| \secondaryCasters ->
    Field.attemptAt [ "_source", "secondary_check" ] Decode.string <| \secondaryChecks ->
    Field.attemptAt [ "_source", "skill" ] stringListDecoder <| \skills ->
    Field.attemptAt [ "_source", "source" ] stringListDecoder <| \sources ->
    Field.attemptAt [ "_source", "spell_list" ] Decode.string <| \spellList ->
    Field.attemptAt [ "_source", "spoilers" ] Decode.string <| \spoilers ->
    Field.attemptAt [ "_source", "strength" ] Decode.int <| \strength ->
    Field.attemptAt [ "_source", "target" ] Decode.string <| \targets ->
    Field.attemptAt [ "_source", "tradition" ] (Decode.list Decode.string) <| \traditions ->
    Field.attemptAt [ "_source", "trait_raw" ] (Decode.list Decode.string) <| \maybeTraits ->
    Field.attemptAt [ "_source", "trigger" ] Decode.string <| \trigger ->
    Field.attemptAt [ "_source", "usage" ] Decode.string <| \usage ->
    Field.attemptAt [ "_source", "weakness_raw" ] (Decode.list Decode.string) <| \weaknesses ->
    Field.attemptAt [ "_source", "weapon_category" ] Decode.string <| \weaponCategory ->
    Field.attemptAt [ "_source", "weapon_group" ] Decode.string <| \weaponGroup ->
    Field.attemptAt [ "_source", "will_save" ] Decode.int <| \will ->
    Field.attemptAt [ "_source", "wisdom" ] Decode.int <| \wisdom ->
    Decode.succeed
        { id = id
        , category = category
        , name = name
        , type_ = type_
        , url = url
        , abilities = Maybe.withDefault [] abilities
        , abilityType = abilityType
        , ac = ac
        , actions = actions
        , activate = activate
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , ammunition = ammunition
        , aonUrl = aonUrl
        , area = area
        , aspect = aspect
        , breadcrumbs = Maybe.withDefault [] breadcrumbs
        , bloodlines = Maybe.withDefault [] bloodlines
        , bulk = bulk
        , cast = cast
        , charisma = charisma
        , components = Maybe.withDefault [] components
        , constitution = constitution
        , cost = cost
        , creatureFamily = creatureFamily
        , damage = damage
        , deities = Maybe.withDefault [] deities
        , dexterity = dexterity
        , divineFont = divineFont
        , domains = Maybe.withDefault [] domains
        , domainSpell = domainSpell
        , duration = duration
        , familiarAbilities = Maybe.withDefault [] familiarAbilities
        , favoredWeapon = favoredWeapon
        , feats = Maybe.withDefault [] feats
        , fort = fort
        , frequency = frequency
        , hands = hands
        , heighten = Maybe.withDefault [] heighten
        , hp = hp
        , immunities = Maybe.withDefault [] immunities
        , intelligence = intelligence
        , lessonType = lessonType
        , level = level
        , markdown = Maybe.withDefault "" markdown
        , mysteries = Maybe.withDefault [] mysteries
        , patronThemes = Maybe.withDefault [] patronThemes
        , perception = perception
        , prerequisites = prerequisites
        , price = price
        , primaryCheck = primaryCheck
        , range = range
        , ref = ref
        , reload = reload
        , requiredAbilities = requiredAbilities
        , requirements = requirements
        , resistances = Maybe.withDefault [] resistances
        , savingThrow = savingThrow
        , secondaryCasters = secondaryCasters
        , secondaryChecks = secondaryChecks
        , skills = Maybe.withDefault [] skills
        , sources = Maybe.withDefault [] sources
        , spellList = spellList
        , spoilers = spoilers
        , strength = strength
        , targets = targets
        , traditions = Maybe.withDefault [] traditions
        , traits = Maybe.withDefault [] maybeTraits
        , trigger = trigger
        , usage = usage
        , weaknesses = Maybe.withDefault [] weaknesses
        , weaponCategory = weaponCategory
        , weaponGroup = weaponGroup
        , will = will
        , wisdom = wisdom
        }


stringListDecoder : Decode.Decoder (List String)
stringListDecoder =
    Decode.oneOf
        [ Decode.list Decode.string
        , Decode.string
            |> Decode.map List.singleton
        ]


getChildDocuments : String -> List String
getChildDocuments markdown =
    case Markdown.Parser.parse markdown of
        Ok blocks ->
            List.foldl
                parseBlock
                []
                blocks

        Err _ ->
            []


parseBlock block list =
    case block of
        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "document" attributes _) ->
            case List.Extra.find (.name >> (==) "id") attributes of
                Just id ->
                    id.value :: list

                Nothing ->
                    list

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement _ _ children) ->
            List.foldl
                parseBlock
                list
                children

        _ ->
            list


view : Model -> Browser.Document Msg
view model =
    { title = "AoN prototype"
    , body =
        [ Html.div
            [ HA.style "padding" "8px"
            , HA.class "row"
            , HA.class "justify-center"
            ]
            [ Html.node "style"
                []
                [ Html.text css
                , Html.text cssDark
                ]
            , FontAwesome.Styles.css
            , Html.div
                [ HA.class "column"
                , HA.class "align-stretch"
                , HA.class "grow"
                , HA.style "max-width" "1200px"
                , HA.style "width" "100%"
                ]
                [ viewNavigation model

                , case pageToDataKey model.page of
                    Just id ->
                        viewDocument model id 0 True

                    _ ->
                        Html.text ""

                , case getSearchKey model.page of
                    Just key ->
                        viewSearch model key

                    Nothing ->
                        Html.text ""
                ]
            ]
        ]
    }


viewSearch : Model -> String -> Html Msg
viewSearch model key =
    Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        (case Dict.get key model.search of
            Just searchModel ->
                [ viewQuery key searchModel
                , viewSearchResults searchModel
                ]

            Nothing ->
                []
        )


viewQuery : String -> SearchModel -> Html Msg
viewQuery key searchModel =
    Html.div
        [ HA.class "column"
        , HA.class "align-stretch"
        , HA.class "gap-tiny"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "input-container"
            ]
            [ Html.input
                [ HA.class "query-input"
                , HA.placeholder "Enter search query"
                , HA.type_ "text"
                , HA.value searchModel.query
                , HE.onInput (QueryChanged key)
                ]
                [ Html.text searchModel.query ]
            , if String.isEmpty searchModel.query then
                Html.text ""

              else
                Html.button
                    [ HA.class "input-button"
                    , HA.style "font-size" "24px"
                    , HE.onClick (QueryChanged key "")
                    ]
                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
            ]

        , Html.button
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HE.onClick (QueryOptionsPressed key (searchModel.optionsHeight == 0))
            , HA.style "align-self" "center"
            ]
            (if searchModel.optionsOpen then
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronUp
                , Html.text "Hide filters and options"
                , FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronUp
                ]

             else
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronDown
                , Html.text "Show filters and options"
                , FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronDown
                ]
            )

        , Html.div
            [ HA.class "search-options-container"
            , HA.style "height" (String.fromInt searchModel.optionsHeight ++ "px")
            ]
            [ Html.div
                [ HA.id "search-options-measure-wrapper" ]
                [ viewSearchOptions key searchModel ]
            ]
        ]


viewSearchOptions : String -> SearchModel -> Html Msg
viewSearchOptions key searchModel =
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ viewQueryType key searchModel
        -- , viewFilterTypes model
        , viewFilterTraits key searchModel
        -- , viewSortResults model
        ]


viewQueryType : String -> SearchModel -> Html Msg
viewQueryType key searchModel =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.h2
            []
            [ Html.text "Query type" ]
        , Html.div
            [ HA.class "row"
            , HA.class "align-baseline"
            , HA.class "gap-medium"
            ]
            [ viewRadioButton
                { checked = searchModel.queryType == Standard
                , name = "query-type"
                , onInput = QueryTypeSelected key Standard
                , text = "Standard"
                }
            , viewRadioButton
                { checked = searchModel.queryType == ElasticsearchQueryString
                , name = "query-type"
                , onInput = QueryTypeSelected key ElasticsearchQueryString
                , text = "Complex"
                }
            ]
        ]


viewFilterTraits : String -> SearchModel -> Html Msg
viewFilterTraits key searchModel =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.h2
            []
            [ Html.text "Filter traits" ]
        , Html.div
            [ HA.class "row"
            , HA.class "input-container"
            ]
            [ Html.input
                [ HA.placeholder "Search among traits"
                , HA.value searchModel.searchTraitsInput
                , HA.type_ "text"
                , HE.onInput (SearchTraitsChanged key)
                ]
                []
            , if String.isEmpty searchModel.searchTraitsInput then
                Html.text ""

              else
                Html.button
                    [ HA.class "input-button"
                    , HE.onClick (SearchTraitsChanged key "")
                    ]
                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
            ]

        , Html.button
            [ HE.onClick (RemoveAllTraitFiltersPressed key)
            , HA.style "align-self" "flex-start"
            ]
            [ Html.text "Reset trait filters" ]

        , Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "scrollbox"
            , HA.class "wrap"
            ]
            (List.map
                (\trait ->
                    Html.button
                        [ HA.class "trait"
                        , HA.class "row"
                        , HA.class "align-center"
                        , HA.class "gap-tiny"
                        , HE.onClick (TraitFilterPressed key trait)
                        ]
                        [ Html.div
                            []
                            [ Html.text trait ]
                        , case Dict.get trait searchModel.filteredTraits of
                            Just True ->
                                Html.div
                                    [ HA.style "color" "#00cc00"
                                    ]
                                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.checkCircle ]

                            Just False ->
                                Html.div
                                    [ HA.style "color" "#dd0000"
                                    ]
                                    [ FontAwesome.Icon.viewIcon FontAwesome.Solid.minusCircle ]

                            Nothing ->
                                Html.div
                                    []
                                    [ FontAwesome.Icon.viewIcon FontAwesome.Regular.circle ]
                        ]
                )
                (List.filter
                    (String.toLower >> String.contains (String.toLower searchModel.searchTraitsInput))
                    searchModel.traits
                )
            )
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


viewSearchResults : SearchModel -> Html Msg
viewSearchResults searchModel =
    let
        total : Maybe Int
        total =
            searchModel.searchResults
                |> List.head
                |> Maybe.andThen Result.toMaybe
                |> Maybe.map .total

        resultCount : Int
        resultCount =
            searchModel.searchResults
                |> List.map (Result.map .documents)
                |> List.map (Result.map List.length)
                |> List.map (Result.withDefault 0)
                |> List.sum
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
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
                            List.map (viewSearchDocument) r.documents

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
                searchModel.searchResults
                |> List.concat

            , if Maybe.Extra.isJust searchModel.tracker then
                [ Html.div
                    [ HA.class "loader"
                    ]
                    []
                ]

              else if resultCount < Maybe.withDefault 0 total then
                [ Html.button
                    [ HA.style "align-self" "center"
                    , HE.onClick LoadMoreSearchResultsPressed
                    ]
                    [ Html.text "Load more" ]
                ]

              else
                []
            ]
        )


viewSearchDocument document =
    Html.section
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h1
            [ HA.class "title" ]
            [ Html.div
                []
                [ Html.a
                    [ HA.href ""
                    -- [ HA.href (getUrl hit.source)
                    , HA.target "_blank"
                    ]
                    [ Html.text document.name
                    ]
                , case ( document.actions, hasActionsInTitle document ) of
                    ( Just actions, True ) ->
                        viewTextWithActionIcons (" " ++ actions)

                    _ ->
                        Html.text ""
                ]
            , Html.div
                [ HA.class "title-type" ]
                [ Html.text document.type_
                , case document.level of
                    Just level ->
                        Html.text (" " ++ String.fromInt level)

                    Nothing ->
                        Html.text ""
                ]
            ]
        ]


viewNavigation model =
    Html.div
        [ HA.class "column"
        , HA.class "align-center"
        , HA.class "gap-small"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "wrap"
            , HA.class "gap-small"
            ]
            (List.map
                (\{ href, label } ->
                    Html.a
                        [ HA.href href ]
                        [ Html.text label ]
                )
                [ { href = "/actions"
                  , label = "Actions/Activities"
                  }
                , { href = "/afflictions"
                  , label = "Afflictions"
                  }
                , { href = "/classes"
                  , label = "Classes"
                  }
                , { href = "/rules"
                  , label = "Rules"
                  }
                , { href = "/traits"
                  , label = "Traits"
                  }
                ]
                |> List.intersperse (Html.text "|")
            )
        , Html.hr [] []
        , case model.page of
            Class _ ->
                viewClassSubnav

            Classes ->
                viewClassSubnav

            ClassFeats _ ->
                viewClassSubnav

            Instinct _ ->
                viewClassSubnav

            Instincts ->
                viewClassSubnav

            SampleBuild _ _ ->
                viewClassSubnav

            SampleBuilds _ ->
                viewClassSubnav

            _ ->
                Html.text ""

        , Html.hr [] []

        , case model.page of
            Class "barbarian" ->
                viewBarbarianSubnav

            Class "bard" ->
                viewBardSubnav

            ClassFeats "barbarian" ->
                viewBarbarianSubnav

            Instinct _ ->
                viewBarbarianSubnav

            Instincts ->
                viewBarbarianSubnav

            SampleBuilds "barbarian" ->
                viewBarbarianSubnav

            _ ->
                Html.text ""

        , Html.hr [] []
        ]


viewClassSubnav =
    Html.div
        [ HA.class "column"
        , HA.class "gap-medium"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "wrap"
            , HA.class "gap-small"
            , HA.class "justify-center"
            ]
            (List.map
                (\c ->
                    Html.a
                        [ HA.href ("/classes/" ++ String.toLower c) ]
                        [ Html.text c ]
                )
                [ "Alchemist"
                , "Barbarian"
                , "Bard"
                , "Champion"
                , "Cleric"
                , "Druid"
                , "Fighter"
                , "Gunslinger"
                , "Inventory"
                , "Investigator"
                , "Magus"
                , "Monk"
                , "Oracle"
                , "Ranger"
                , "Rogue"
                , "Sorcerer"
                , "Summoner"
                , "Swashbuckler"
                , "Witch"
                , "Wizard"
                ]
                |> List.intersperse (Html.text "|")
            )
        ]


viewBarbarianSubnav =
    Html.div
        [ HA.class "row"
        , HA.class "wrap"
        , HA.class "gap-small"
        ]
        (List.map
            (\{ href, label } ->
                Html.a
                    [ HA.href href ]
                    [ Html.text label ]
            )
            [ { href = "/classes/barbarian"
              , label = "Details"
              }
            , { href = "/classes/barbarian/feats"
              , label = "Feats"
              }
            , { href = "/classes/barbarian/kits"
              , label = "Kits"
              }
            , { href = "/classes/barbarian/sample-builds"
              , label = "Sample Builds"
              }
            , { href = "/classes/barbarian/instincts"
              , label = "Instincts"
              }
            ]
            |> List.intersperse (Html.text "|")
        )


viewBardSubnav =
    Html.div
        [ HA.class "row"
        , HA.class "wrap"
        , HA.class "gap-small"
        ]
        (List.map
            (\{ href, label } ->
                Html.a
                    [ HA.href href ]
                    [ Html.text label ]
            )
            [ { href = "/classes/bard"
              , label = "Details"
              }
            , { href = "/classes/bard/feats"
              , label = "Feats"
              }
            , { href = "/classes/bard/kits"
              , label = "Kits"
              }
            , { href = "/classes/bard/sample-builds"
              , label = "Sample Builds"
              }
            , { href = "/classes/bard/muses"
              , label = "Muses"
              }
            ]
            |> List.intersperse (Html.text "|")
        )


viewDocument : Model -> String -> Int -> Bool -> Html Msg
viewDocument model id titleLevel isMain =
    case Dict.get id model.documents of
        Just (Ok document) ->
            Html.div
                [ HA.class "column"
                , HA.class "gap-medium"
                , HA.class "margin-top-not-first"
                ]
                [ if isMain && not (List.isEmpty document.breadcrumbs) then
                    Html.div
                        [ HA.class "row"
                        , HA.class "gap-small"
                        ]
                        (List.foldl
                            (\breadcrumb ( prev, html ) ->
                                ( List.append prev [ breadcrumb ]
                                , List.append
                                    html
                                    [ Html.a
                                        [ HA.href
                                            (List.append prev [ breadcrumb ]
                                                |> List.map dasherize
                                                |> String.join "/"
                                                |> (++) "/"
                                            )
                                        ]
                                        [ Html.text breadcrumb ]
                                    ]
                                )
                            )
                            ( [], [] )
                            document.breadcrumbs
                            |> Tuple.second
                            |> \list ->
                                List.append
                                    list
                                    [ Html.div
                                        []
                                        [ Html.text document.name ]
                                    ]
                            |> List.intersperse (Html.text "/")
                        )

                  else
                    Html.text ""

                , case ( isMain, document.aonUrl ) of
                    ( True, Just aonUrl ) ->
                        Html.a
                            [ HA.href ("https://2e.aonprd.com/" ++ aonUrl) ]
                            [ Html.text "View this page on Archives of Nethys" ]

                    _ ->
                        Html.text ""

                -- Title
                , (if titleLevel <= 1 then
                    Html.h1

                   else if titleLevel == 2 then
                    Html.h2

                   else if titleLevel == 3 then
                    Html.h3

                   else
                    Html.h4
                  )
                    [ HA.class "title" ]
                    [ Html.div
                        []
                        [ Html.a
                            [ HA.href (documentToUrl document) ]
                            [ Html.text document.name ]
                        , case ( document.actions, hasActionsInTitle document ) of
                            ( Just actions, True ) ->
                                viewTextWithActionIcons (" " ++ actions)

                            _ ->
                                Html.text ""
                        ]
                    , if document.type_ /= "Page" then
                        Html.div
                            []
                            [ Html.text document.type_ ]

                      else
                        Html.text ""
                    ]

                -- Traits
                , Html.div
                    [ HA.class "row" ]
                    (List.map viewTrait document.traits)

                -- Source
                , case document.sources of
                    [] ->
                        Html.text ""

                    sources ->
                        Html.div
                            []
                            [ Html.span
                                [ HA.class "bold" ]
                                [ Html.text "Source" ]
                            , Html.text " "
                            , List.map
                                (\source ->
                                    -- TODO: Page numbers?
                                    -- TODO: Link style?
                                    Html.a
                                        [ HA.href ("/source/" ++ dasherize source) ]
                                        [ Html.text source ]
                                )
                                sources
                                |> List.intersperse (Html.text ", ")
                                |> Html.span []
                            ]

                , renderMarkdown model (titleLevel + 1) document.markdown
                ]

        Just (Err _) ->
            Html.text "err"

        Nothing ->
            Html.div
                [ HA.class "loader" ]
                []


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


hasActionsInTitle : Document -> Bool
hasActionsInTitle document =
    List.member document.category [ "action", "creature-ability", "feat" ]


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



renderMarkdown : Model -> Int -> String -> Html Msg
renderMarkdown model titleLevel markdown =
    case Markdown.Parser.parse markdown of
        Ok blocks ->
            case Markdown.Renderer.render (renderer model titleLevel) blocks of
                Ok v ->
                    Html.div
                        [ HA.class "column"
                        , HA.class "gap-medium"
                        ]
                        v

                Err err ->
                    Html.text err

        Err errors ->
            Html.div
                []
                (List.map
                    (Markdown.Parser.deadEndToString >> Html.text)
                    errors
                )


renderer : Model -> Int ->  Markdown.Renderer.Renderer (Html Msg)
renderer model titleLevel =
    let
        defaultRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defaultRenderer
        | html =
            Markdown.Html.oneOf
                [ Markdown.Html.tag "title"
                    (\level right content ->
                        (case level of
                            "1" ->
                                Html.h1

                            "2" ->
                                Html.h2

                            "3" ->
                                Html.h3

                            "4" ->
                                Html.h4

                            _ ->
                                Html.h1
                        )
                            [ HA.class "title"
                            , HA.class "margin-top-not-first"
                            ]
                            [ Html.div
                                []
                                content
                            , case right of
                                Just r ->
                                    Html.div
                                        [ HA.class "align-right" ]
                                        [ Html.text r ]

                                Nothing ->
                                    Html.text ""
                            ]
                    )
                    |> Markdown.Html.withAttribute "level"
                    |> Markdown.Html.withOptionalAttribute "right"
                , Markdown.Html.tag "center"
                    (\content ->
                        Html.div
                            [ HA.class "column"
                            , HA.class "gap-medium"
                            , HA.class "align-center"
                            ]
                            content
                    )
                , Markdown.Html.tag "document"
                    (\id level _ ->
                        viewDocument
                            model
                            id
                            (max
                                (level
                                    |> Maybe.andThen String.toInt
                                    |> Maybe.withDefault 0
                                )
                                titleLevel
                            )
                            False
                    )
                    |> Markdown.Html.withAttribute "id"
                    |> Markdown.Html.withOptionalAttribute "level"
                , Markdown.Html.tag "infobox"
                    (\content ->
                        Html.div
                            [ HA.class "option-container"
                            , HA.class "column"
                            ]
                            content
                    )
                , Markdown.Html.tag "table"
                    (\content ->
                        Html.div
                            [ HA.style "overflow-x" "auto"
                            , HA.style "max-width" "100%"
                            , HA.style "align-self" "center"
                            ]
                            [ Html.table
                                []
                                content
                            ]
                    )
                , Markdown.Html.tag "tbody"
                    (\content ->
                        Html.tbody
                            [ HA.style "max-width" "100%"
                            ]
                            content
                    )
                , Markdown.Html.tag "td"
                    (\colspan content ->
                        Html.td
                            [ HAE.attributeMaybe
                                HA.colspan
                                (Maybe.andThen String.toInt colspan)
                            ]
                            content
                    )
                    |> Markdown.Html.withOptionalAttribute "colspan"
                , Markdown.Html.tag "tfoot"
                    (\content ->
                        Html.tfoot
                            []
                            content
                    )
                , Markdown.Html.tag "th"
                    (\content ->
                        Html.th
                            []
                            content
                    )
                , Markdown.Html.tag "thead"
                    (\content ->
                        Html.thead
                            []
                            content
                    )
                , Markdown.Html.tag "tr"
                    (\content ->
                        Html.tr
                            []
                            content
                    )
                , Markdown.Html.tag "trait"
                    (\content ->
                        Html.div
                            [ HA.class "trait"
                            ]
                            content
                    )
                ]
    }


css : String
css =
    """
    @font-face {
        font-family: "Pathfinder-Icons";
        src: url("/Pathfinder-Icons.ttf");
        font-display: swap;
    }

    :root, :host {
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
        line-height: 1.25;
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

    h1, h2, h3, h4 {
        font-variant: small-caps;
        font-weight: 700;
        margin: 0;
    }

    h1 {
        font-size: var(--font-very-large);
    }

    h1.title {
        background-color: var(--color-element-bg);
        border-color: var(--color-container-border);
        color: var(--color-element-text);
    }

    h2 {
        font-size: var(--font-large);
    }

    h2.title {
        background-color: var(--color-subelement-bg);
        color: var(--color-subelement-text);
        line-height: 1;
    }

    h3 {
        font-size: 18px;
    }

    h3.title {
        background-color: #627d62;
        color: var(--color-subelement-text);
        line-height: 1;
    }

    h4 {
        font-size: var(--font-medium);
    }

    h4.title {
        background-color: #494e70;
        color: var(--color-subelement-text);
        line-height: 1;
    }

    hr {
        margin: 0;
        width: 100%;
    }

    input[type=text] {
        background-color: transparent;
        border-width: 0;
        color: var(--color-text);
        padding: 4px;
        flex-grow: 1;
    }

    input:focus-visible {
        border-width: 0;
        border-style: none;
        border-image: none;
        outline: 0;
    }

    p {
        margin: 0;
    }

    ul {
        margin: 0;
    }

    select {
        font-size: var(--font-normal);
    }

    table {
        align-self: center;
        border-spacing: 0;
        border-collapse: collapse;
    }

    tbody tr {
        background-color: #64542f;
    }

    tbody tr:nth-child(odd) {
        background-color: #342c19;
    }

    thead tr, tfoot tr {
        background-color: var(--color-element-bg);
        color: var(--color-element-text)
    }

    td, th {
        border: 1px solid var(--color-text);
        padding: 1px 5px;
        line-height: 1.5;
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

    .align-right {
        text-align: right;
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
    }

    .wrap {
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

    .grow {
        flex-grow: 1;
    }

    .icon-font {
        color: var(--color-icon);
        font-family: "Pathfinder-Icons";
        font-variant-caps: normal;
        font-weight: normal;
    }

    .input-container {
        background-color: var(--color-bg);
        border-style: solid;
        border-radius: 4px;
        border-width: 2px;
        border-color: #808080;
    }

    .input-container:focus-within {
        border-color: var(--color-text);
    }

    .input-button {
        background-color: transparent;
        border-width: 0;
        color: var(--color-text);
    }

    .justify-between {
        justify-content: space-between;
    }

    .justify-center {
        justify-content: center;
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
        gap: var(--gap-medium);
        padding: 8px;
    }

    .query-input {
        font-size: var(--font-very-large);
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

    .search-options-container {
        transition: height ease-in-out 0.2s;
        overflow: hidden;
    }

    .option-container h2 {
        background-color: inherit;
        color: inherit;
        padding: 0;
    }

    .margin-top-not-first:not(:first-child) {
        margin-top: var(--gap-medium);
    }

    .title {
        border-radius: 4px;
        display: flex;
        flex-direction: row;
        gap: var(--gap-small);
        justify-content: space-between;
        padding: 4px 9px;
    }

    .title:empty {
        display: none;
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
    :root, :host {
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
        --color-subelement-bg2: #64542f;
        --color-subelement-text: #111111;
        --color-icon: #cccccc;
        --color-inactive-text: #999999;
        --color-text: #eeeeee;
    }
    """
