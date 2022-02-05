port module Main exposing (main)

import Browser
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
import Maybe.Extra
import Process
import Regex
import Set exposing (Set)
import String.Extra
import Task
import Url exposing (Url)
import Url.Builder
import Url.Parser
import Url.Parser.Query


type alias Hit a =
    { id : String
    , score : Float
    , source : a
    }


type alias Document =
    { id : Int
    , url : String
    , category : Category
    , name : String
    , level : Maybe Int
    , type_ : String
    , traits : List String
    , breadcrumbs : Maybe String
    , alignment : Maybe String
    , damage : Maybe String
    , weaponCategory : Maybe String
    , weaponGroup : Maybe String
    , hands : Maybe String
    , range : Maybe String
    , reload : Maybe String
    , traditions : List String
    , components : List String
    , actions : Maybe String
    , duration : Maybe String
    , savingThrow : Maybe String
    , targets : Maybe String
    , area : Maybe String
    , price : Maybe String
    , bulk : Maybe String
    , usage : Maybe String
    , prerequisites : Maybe String
    }


type alias Flags =
    { elasticUrl : String
    }


type Category
    = Action
    | Ancestry
    | Archetype
    | Armor
    | ArmorGroup
    | Background
    | Cause
    | Class
    | Condition
    | Curse
    | Deity
    | Disease
    | Domain
    | Equipment
    | Feat
    | Hazard
    | Heritage
    | Language
    | Monster
    | MonsterAbility
    | MonsterFamily
    | NPC
    | Plane
    | Relic
    | Ritual
    | Rules
    | Shield
    | Skill
    | Spell
    | Trait
    | Way
    | Weapon
    | WeaponGroup
    | Other


type QueryType
    = Standard
    | ElasticsearchQueryString


type Theme
    = Dark
    | Light
    | Paper


type Msg
    = DebouncePassed Int
    | GotSearchResult (Result Http.Error (List (Hit Document)))
    | IncludeFilteredTraitsChanged Bool
    | IncludeFilteredTypesChanged Bool
    | LocalStorageValueReceived Decode.Value
    | QueryChanged String
    | QueryTypeSelected QueryType
    | RemoveAllTraitFiltersPressed
    | RemoveAllTypeFiltersPressed
    | SearchTraitsChanged String
    | SearchTypesChanged String
    | ShowAdditionalInfoChanged Bool
    | ShowMenuPressed Bool
    | ShowQueryOptionsPressed Bool
    | ShowTraitsChanged Bool
    | ThemeSelected Theme
    | TraitFilterAdded String
    | TraitFilterRemoved String
    | TypeFilterAdded String
    | TypeFilterRemoved String
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest


port localStorage_set : Encode.Value -> Cmd msg
port localStorage_get : String -> Cmd msg
port localStorage_receive : (Decode.Value -> msg) -> Sub msg


type alias Model =
    { debounce : Int
    , elasticUrl : String
    , filteredTraits : Set String
    , filteredTypes : Set String
    , includeFilteredTraits : Bool
    , includeFilteredTypes : Bool
    , menuOpen : Bool
    , navKey : Browser.Navigation.Key
    , query : String
    , queryOptionsOpen : Bool
    , queryType : QueryType
    , searchResult : Maybe (Result Http.Error (List (Hit Document)))
    , searchTraits : String
    , searchTypes : String
    , showResultAdditionalInfo : Bool
    , showResultTraits : Bool
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
      , filteredTraits = Set.empty
      , filteredTypes = Set.empty
      , includeFilteredTraits = True
      , includeFilteredTypes = True
      , menuOpen = False
      , navKey = navKey
      , query = ""
      , queryOptionsOpen = False
      , queryType = Standard
      , searchResult = Nothing
      , searchTraits = ""
      , searchTypes = ""
      , showResultAdditionalInfo = True
      , showResultTraits = True
      , theme = Dark
      , tracker = Nothing
      , url = url
      }
        |> updateModelFromQueryString url
    , Cmd.batch
        [ localStorage_get "show-additional-info"
        , localStorage_get "show-traits"
        , localStorage_get "theme"
        ]
    )
        |> searchWithCurrentQuery


subscriptions : Model -> Sub Msg
subscriptions model =
    localStorage_receive LocalStorageValueReceived


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

        GotSearchResult result ->
            ( { model
                | searchResult = Just result
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

        QueryChanged str ->
            if String.isEmpty (String.trim str) then
                ( { model
                    | query = str
                    , searchResult = Nothing
                  }
                , updateUrl { model | query = str }
                )

            else
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
            , Cmd.none
            )

        SearchTypesChanged value ->
            ( { model | searchTypes = value }
            , Cmd.none
            )

        ShowAdditionalInfoChanged value ->
            ( { model | showResultAdditionalInfo = value }
            , saveToLocalStorage
                "show-additional-info"
                (if value then "1" else "0")
            )

        ShowMenuPressed show ->
            ( { model | menuOpen = show }
            , Cmd.none
            )

        ShowQueryOptionsPressed show ->
            ( { model | queryOptionsOpen = show }
            , Cmd.none
            )

        ShowTraitsChanged value ->
            ( { model | showResultTraits = value }
            , saveToLocalStorage
                "show-traits"
                (if value then "1" else "0")
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
    , "traits.raw"
    , "type"
    ]


buildSearchBody : Model -> Encode.Value
buildSearchBody model =
    Encode.object
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , encodeObjectMaybe
                        [ Just
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

                        , Just ( "minimum_should_match", Encode.int 1 )
                        ]
                  )
                ]
          )
        , ( "size", Encode.int 100 )
        ]


buildSearchFilterTerms : Model -> List ( String, Encode.Value )
buildSearchFilterTerms model =
    [ if Set.isEmpty model.filteredTraits || not model.includeFilteredTraits then
        Nothing

      else
        Just
            ( "terms"
            , Encode.object
                [ ( "traits.normalized"
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
                [ ( "traits.normalized"
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
    }


getQueryParam : Url -> String -> String
getQueryParam url param =
    { url | path = "" }
        |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string param))
        |> Maybe.Extra.join
        |> Maybe.withDefault ""


searchWithCurrentQuery : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
searchWithCurrentQuery ( model, cmd ) =
    let
        newTracker : Int
        newTracker =
            case model.tracker of
                Just tracker ->
                    tracker + 1

                Nothing ->
                    1
    in
    if String.isEmpty (String.trim model.query) then
        ( model, cmd )

    else
        ( { model | tracker = Just newTracker }
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
    Field.require "url" Decode.string <| \url ->
    Field.require "category" categoryDecoder <| \category ->
    Field.require "name" Decode.string <| \name ->
    Field.require "type" Decode.string <| \type_ ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attemptAt [ "traits", "raw" ] (Decode.list Decode.string) <| \maybeTraits ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "weaponCategory" Decode.string <| \weaponCategory ->
    Field.attempt "weaponGroup" Decode.string <| \weaponGroup ->
    Field.attempt "hands" Decode.string <| \hands ->
    Field.attempt "range" Decode.string <| \range ->
    Field.attempt "reload" Decode.string <| \reload ->
    Field.attempt "traditions" (Decode.list Decode.string) <| \traditions ->
    Field.attempt "components" (Decode.list Decode.string) <| \components ->
    Field.attempt "actions" Decode.string <| \actions ->
    Field.attempt "duration" Decode.string <| \duration ->
    Field.attempt "targets" Decode.string <| \targets ->
    Field.attempt "savingThrow" Decode.string <| \savingThrow ->
    Field.attempt "area" Decode.string <| \area ->
    Field.attemptAt [ "price", "raw" ] Decode.string <| \price ->
    Field.attempt "bulk" Decode.string <| \bulk ->
    Field.attempt "usage" Decode.string <| \usage ->
    Field.attempt "prerequisites" Decode.string <| \prerequisites ->
    Decode.succeed
        { id = id
        , url = url
        , category = category
        , type_ = type_
        , name = name
        , level = level
        , traits = Maybe.withDefault [] maybeTraits
        , breadcrumbs = breadcrumbs
        , alignment = alignment
        , damage = damage
        , weaponCategory = weaponCategory
        , weaponGroup = weaponGroup
        , hands = hands
        , range = range
        , reload = reload
        , traditions = Maybe.withDefault [] traditions
        , components = Maybe.withDefault [] components
        , actions = actions
        , duration = duration
        , savingThrow = savingThrow
        , targets = targets
        , area = area
        , price = price
        , bulk = bulk
        , usage = usage
        , prerequisites = prerequisites
        }


categoryDecoder : Decode.Decoder Category
categoryDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "action" ->
                        Decode.succeed Action

                    "ancestry" ->
                        Decode.succeed Ancestry

                    "archetype" ->
                        Decode.succeed Archetype

                    "armor" ->
                        Decode.succeed Armor

                    "armor-group" ->
                        Decode.succeed ArmorGroup

                    "background" ->
                        Decode.succeed Background

                    "cause" ->
                        Decode.succeed Cause

                    "class" ->
                        Decode.succeed Class

                    "condition" ->
                        Decode.succeed Condition

                    "curse" ->
                        Decode.succeed Curse

                    "deity" ->
                        Decode.succeed Deity

                    "disease" ->
                        Decode.succeed Disease

                    "domain" ->
                        Decode.succeed Domain

                    "equipment" ->
                        Decode.succeed Equipment

                    "feat" ->
                        Decode.succeed Feat

                    "hazard" ->
                        Decode.succeed Hazard

                    "heritage" ->
                        Decode.succeed Heritage

                    "language" ->
                        Decode.succeed Language

                    "monster" ->
                        Decode.succeed Monster

                    "monster-ability" ->
                        Decode.succeed MonsterAbility

                    "monster-family" ->
                        Decode.succeed MonsterFamily

                    "npc" ->
                        Decode.succeed NPC

                    "plane" ->
                        Decode.succeed Plane

                    "relic" ->
                        Decode.succeed Relic

                    "ritual" ->
                        Decode.succeed Ritual

                    "rules" ->
                        Decode.succeed Rules

                    "shield" ->
                        Decode.succeed Shield

                    "skill" ->
                        Decode.succeed Skill

                    "spell" ->
                        Decode.succeed Spell

                    "trait" ->
                        Decode.succeed Trait

                    "way" ->
                        Decode.succeed Way

                    "weapon" ->
                        Decode.succeed Weapon

                    "weapon-group" ->
                        Decode.succeed WeaponGroup

                    _ ->
                        Decode.succeed Other
            )


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
            [ HA.class "column"
            , HA.class "align-center"
            , HA.style "position" "relative"
            , HA.style "min-height" "100%"
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
                ]
                []
            , viewMenu model
            , Html.div
                [ HA.class "column"
                , HA.class "gap-large"
                , HA.class "content"
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
                    "What is Elasticsearch Query String?"
                    [ Html.text "A query syntax to write advanced queries. For more information on how to use it see the "
                    , Html.a
                        [ HA.href "https://www.elastic.co/guide/en/elasticsearch/reference/7.15/query-dsl-query-string-query.html#query-string-syntax" ]
                        [ Html.text "documentation" ]
                    , Html.text "."
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
            [ Html.text "Nethys Search" ]
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
            , HA.style "border-width" "0"
            , HA.style "background-color" "transparent"
            , HA.style "color" "var(--color-text)"
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

        , if model.queryOptionsOpen then
            viewQueryOptions model

          else
            Html.text ""

        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            [ viewIncludeFilters model
            , viewExcludeFilters model
            ]
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
        [ Html.div
            [ HA.class "option-container"
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
                    , text = "Standard Query"
                    }
                , viewRadioButton
                    { checked = model.queryType == ElasticsearchQueryString
                    , name = "query-type"
                    , onInput = QueryTypeSelected ElasticsearchQueryString
                    , text = "Elasticsearch Query String"
                    }
                ]
            ]

        , Html.div
            [ HA.class "option-container"
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

        , Html.div
            [ HA.class "option-container"
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



viewSearchResults : Model -> Html msg
viewSearchResults model =
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        , HA.style "min-height" "500px"
        ]
        (if Maybe.Extra.isJust model.tracker then
            [ Html.div
                [ HA.class "loader"
                ]
                []
            ]

        else
            case model.searchResult of
                Just (Ok []) ->
                    [ Html.h2
                        []
                        [ Html.text "No matches"
                        ]
                    ]

                Just (Ok hits) ->
                    (List.map (viewSingleSearchResult model) hits)

                Just (Err (Http.BadStatus 400)) ->
                    [ Html.h2
                        []
                        [ Html.text "Error: Failed to parse query"
                        ]
                    ]

                _ ->
                    []
        )


viewSingleSearchResult : Model -> Hit Document -> Html msg
viewSingleSearchResult model hit =
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
                , case ( hit.source.actions, List.member hit.source.category [ Action, Feat ]) of
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
        (case hit.source.category of
            Equipment ->
                (List.filterMap identity
                    [ Maybe.map
                        (viewLabelAndText "Price")
                        hit.source.price

                    , if List.any
                        Maybe.Extra.isJust
                        [ hit.source.hands, hit.source.usage, hit.source.bulk ]
                      then
                        Html.div
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

                      else
                        Nothing
                    ]
                )

            Feat ->
                case hit.source.prerequisites of
                    Just prerequisites ->
                        [ viewLabelAndText "Prerequisites" prerequisites
                        ]

                    Nothing ->
                        []

            Rules ->
                case hit.source.breadcrumbs of
                    Just breadcrumbs ->
                        [ Html.text breadcrumbs
                        ]

                    Nothing ->
                        []

            Spell ->
                List.filterMap identity
                    [ if List.isEmpty hit.source.traditions then
                        Nothing

                      else
                        hit.source.traditions
                            |> String.join ", "
                            |> viewLabelAndText "Traditions"
                            |> Just

                    , if Maybe.Extra.isNothing hit.source.actions && List.isEmpty hit.source.components then
                        Nothing

                      else
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (List.filterMap identity
                                [ Maybe.map
                                    (viewLabelAndText "Cast")
                                    hit.source.actions

                                , if List.isEmpty hit.source.components then
                                    Nothing

                                  else
                                    hit.source.components
                                        |> String.join ", "
                                        |> viewLabelAndText "Components"
                                        |> Just
                                ]
                            )
                            |> Just

                    , if List.any
                        Maybe.Extra.isJust
                        [ hit.source.range, hit.source.targets, hit.source.area ]
                      then
                        Html.div
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

                      else
                        Nothing

                    , if List.any
                        Maybe.Extra.isJust
                        [ hit.source.savingThrow, hit.source.duration ]
                      then
                        Html.div
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

                      else
                        Nothing
                    ]

            Weapon ->
                (List.filterMap identity
                    [ case hit.source.range of
                        Just _ ->
                            Just "Ranged"

                        Nothing ->
                            Just "Melee"
                    , hit.source.weaponCategory
                    , hit.source.weaponGroup
                    , Maybe.map (\hands -> hands ++ " hands") hit.source.hands
                    , hit.source.damage
                    , hit.source.range
                    , Maybe.map (\reload -> "Reload " ++ reload) hit.source.reload
                    ]
                    |> List.map Html.text
                    |> List.intersperse (Html.text ", ")
                )


            _ ->
                []
        )


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

    .bold {
        font-weight: 700;
    }

    .column {
        display: flex;
        flex-direction: column;
    }

    .content {
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

    .gap-medium.row {
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
        transition: transform ease-in-out 0.25s;
        width: 85%;
        z-index: 2;
    }

    .menu-close-button {
        align-self: flex-end;
        background-color: inherit;
        border: 0;
        color: var(--color-text);
        font-size: 32px;
        margin-top: -8px;
        padding: 8px;
    }

    .menu-open-button {
        background-color: transparent;
        border: 0;
        color: var(--color-text);
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

    .option-container {
        border-style: solid;
        border-width: 1px;
        background-color: var(--color-container-bg);
        display: flex;
        flex-direction: column;
        gap: var(--gap-small);
        padding: 8px;
    }

    .query-input {
        font-size: var(--font-very-large);
    }

    .scrollbox {
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
        color: #999999;
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
        --color-text: #eeeeee;
    }
    """


cssLight : String
cssLight =
    """
    :root {
        --color-bg: #eeeeee;
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
        --color-text: #111111;
    }
    """


cssPaper : String
cssPaper =
    """
    :root {
        --color-bg: #f1ece5;
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
        --color-text: #111111;
    }
    """
