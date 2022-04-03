port module NethysSearch exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Data
import Dict exposing (Dict)
import FontAwesome.Attributes
import FontAwesome.Icon
import FontAwesome.Regular
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
import String.Extra
import Svg
import Svg.Attributes as SA
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
    { category : String
    , name : String
    , type_ : String
    , url : String
    , abilities : List String
    , abilityBoosts : List String
    , abilityFlaws : List String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , ammunition : Maybe String
    , area : Maybe String
    , armorGroup : Maybe String
    , aspect : Maybe String
    , bloodlines : List String
    , breadcrumbs : Maybe String
    , bulk : Maybe String
    , cast : Maybe String
    , charisma : Maybe Int
    , checkPenalty : Maybe Int
    , components : List String
    , constitution : Maybe Int
    , cost : Maybe String
    , creatureFamily : Maybe String
    , damage : Maybe String
    , deities : List String
    , dexCap : Maybe Int
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
    , mysteries : List String
    , patronThemes : List String
    , perception : Maybe Int
    , pfs : Maybe String
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
    , sizes : List String
    , skills : List String
    , source : Maybe String
    , speed : Maybe String
    , speedPenalty : Maybe String
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


type alias Flags =
    { currentUrl : String
    , elasticUrl : String
    , showHeader : Bool
    }


defaultFlags : Flags
defaultFlags =
    { currentUrl = "/"
    , elasticUrl = ""
    , showHeader = True
    }


type QueryType
    = Standard
    | ElasticsearchQueryString


type SortDir
    = Asc
    | Desc


type Theme
    = Dark
    | ExtraContrast
    | Lavender
    | Light
    | Paper


type Msg
    = AlignmentFilterAdded String
    | AlignmentFilterRemoved String
    | ComponentFilterAdded String
    | ComponentFilterRemoved String
    | DebouncePassed Int
    | GotElementHeight String Int
    | GotSearchResult (Result Http.Error SearchResult)
    | FilterAbilityChanged String
    | FilterComponentsOperatorChanged Bool
    | FilterResistanceChanged String
    | FilterTraditionsOperatorChanged Bool
    | FilterTraitsOperatorChanged Bool
    | FilterWeaknessChanged String
    | FilteredFromValueChanged String String
    | FilteredToValueChanged String String
    | LoadMorePressed
    | LocalStorageValueReceived Decode.Value
    | MenuOpenDelayPassed
    | NoOp
    | PfsFilterAdded String
    | PfsFilterRemoved String
    | QueryChanged String
    | QueryTypeSelected QueryType
    | RemoveAllSortsPressed
    | RemoveAllAlignmentFiltersPressed
    | RemoveAllComponentFiltersPressed
    | RemoveAllPfsFiltersPressed
    | RemoveAllSizeFiltersPressed
    | RemoveAllTraditionFiltersPressed
    | RemoveAllTraitFiltersPressed
    | RemoveAllTypeFiltersPressed
    | RemoveAllValueFiltersPressed
    | SearchTraitsChanged String
    | SearchTypesChanged String
    | ScrollToTopPressed
    | ShowAdditionalInfoChanged Bool
    | ShowFoldableOptionBoxPressed String Bool
    | ShowMenuPressed Bool
    | ShowQueryOptionsPressed Bool
    | ShowSpoilersChanged Bool
    | ShowTraitsChanged Bool
    | SizeFilterAdded String
    | SizeFilterRemoved String
    | SortAbilityChanged String
    | SortAdded String SortDir
    | SortRemoved String
    | SortResistanceChanged String
    | SortWeaknessChanged String
    | ThemeSelected Theme
    | TraditionFilterAdded String
    | TraditionFilterRemoved String
    | TraitFilterAdded String
    | TraitFilterRemoved String
    | TypeFilterAdded String
    | TypeFilterRemoved String
    | UrlChanged String
    | UrlRequested Browser.UrlRequest
    | WindowResized Int Int


port document_getElementHeight : String -> Cmd msg
port document_receiveElementHeight : ({ id : String, height : Float } -> msg) -> Sub msg
port document_setTitle : String -> Cmd msg
port localStorage_set : Encode.Value -> Cmd msg
port localStorage_get : String -> Cmd msg
port localStorage_receive : (Decode.Value -> msg) -> Sub msg
port navigation_loadUrl : String -> Cmd msg
port navigation_pushUrl : String -> Cmd msg
port navigation_urlChanged : (String -> msg) -> Sub msg


type alias Model =
    { debounce : Int
    , elasticUrl : String
    , elementHeights : Dict String Int
    , filteredAlignments : Dict String Bool
    , filteredComponents : Dict String Bool
    , filteredPfs : Dict String Bool
    , filteredSizes : Dict String Bool
    , filteredTraditions : Dict String Bool
    , filteredTraits : Dict String Bool
    , filteredTypes : Dict String Bool
    , filteredFromValues : Dict String String
    , filteredToValues : Dict String String
    , filterComponentsOperator : Bool
    , filterTraditionsOperator : Bool
    , filterTraitsOperator : Bool
    , menuOpen : Bool
    , overlayActive : Bool
    , query : String
    , queryOptionsOpen : Bool
    , queryType : QueryType
    , searchResults : List (Result Http.Error SearchResult)
    , searchTraits : String
    , searchTypes : String
    , selectedFilterAbility : String
    , selectedFilterResistance : String
    , selectedFilterWeakness : String
    , selectedSortAbility : String
    , selectedSortResistance : String
    , selectedSortWeakness : String
    , showHeader : Bool
    , showResultAdditionalInfo : Bool
    , showResultSpoilers : Bool
    , showResultTraits : Bool
    , sort : List ( String, SortDir )
    , theme : Theme
    , tracker : Maybe Int
    , url : Url
    }


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


init : Decode.Value -> ( Model, Cmd Msg )
init flagsValue =
    let
        flags : Flags
        flags =
            Decode.decodeValue flagsDecoder flagsValue
                |> Result.withDefault defaultFlags

        url : Url
        url =
            parseUrl flags.currentUrl
    in
    ( { debounce = 0
      , elasticUrl = flags.elasticUrl
      , elementHeights = Dict.empty
      , filteredAlignments = Dict.empty
      , filteredComponents = Dict.empty
      , filteredPfs = Dict.empty
      , filteredSizes = Dict.empty
      , filteredTraditions = Dict.empty
      , filteredTraits = Dict.empty
      , filteredTypes = Dict.empty
      , filteredFromValues = Dict.empty
      , filteredToValues = Dict.empty
      , filterComponentsOperator = True
      , filterTraditionsOperator = True
      , filterTraitsOperator = True
      , menuOpen = False
      , overlayActive = False
      , query = ""
      , queryOptionsOpen = False
      , queryType = Standard
      , searchResults = []
      , searchTraits = ""
      , searchTypes = ""
      , selectedFilterAbility = "strength"
      , selectedFilterResistance = "acid"
      , selectedFilterWeakness = "acid"
      , selectedSortAbility = "strength"
      , selectedSortResistance = "acid"
      , selectedSortWeakness = "acid"
      , showHeader = flags.showHeader
      , showResultAdditionalInfo = True
      , showResultSpoilers = True
      , showResultTraits = True
      , sort = []
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
        ]
    )
        |> searchWithCurrentQuery
        |> updateTitle


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize WindowResized
        , document_receiveElementHeight
            (\{ id, height } ->
                GotElementHeight id (round height)
            )
        , localStorage_receive LocalStorageValueReceived
        , navigation_urlChanged UrlChanged
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AlignmentFilterAdded alignment ->
            ( model
            , updateUrl { model | filteredAlignments = toggleBoolDict alignment model.filteredAlignments }
            )

        AlignmentFilterRemoved alignment ->
            ( model
            , updateUrl { model | filteredAlignments = Dict.remove alignment model.filteredAlignments }
            )

        ComponentFilterAdded component ->
            ( model
            , updateUrl { model | filteredComponents = toggleBoolDict component model.filteredComponents }
            )

        ComponentFilterRemoved component ->
            ( model
            , updateUrl { model | filteredComponents = Dict.remove component model.filteredComponents }
            )

        DebouncePassed debounce ->
            if model.debounce == debounce then
                ( model
                , updateUrl model
                )

            else
                ( model, Cmd.none )

        GotElementHeight id height ->
            ( { model | elementHeights = Dict.insert id height model.elementHeights }
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

        FilterAbilityChanged value ->
            ( { model | selectedFilterAbility = value }
            , Cmd.none
            )

        FilterComponentsOperatorChanged value ->
            ( model
            , updateUrl { model | filterComponentsOperator = value }
            )

        FilterResistanceChanged value ->
            ( { model | selectedFilterResistance = value }
            , Cmd.none
            )

        FilterTraditionsOperatorChanged value ->
            ( model
            , updateUrl { model | filterTraditionsOperator = value }
            )

        FilterTraitsOperatorChanged value ->
            ( model
            , updateUrl { model | filterTraitsOperator = value }
            )

        FilterWeaknessChanged value ->
            ( { model | selectedFilterWeakness = value }
            , Cmd.none
            )

        FilteredFromValueChanged key value ->
            let
                updatedModel =
                    { model
                        | filteredFromValues =
                            if String.isEmpty value then
                                Dict.remove key model.filteredFromValues

                            else
                                Dict.insert key value model.filteredFromValues
                    }
            in
            ( updatedModel
            , updateUrl updatedModel
            )

        FilteredToValueChanged key value ->
            let
                updatedModel =
                    { model
                        | filteredToValues =
                            if String.isEmpty value then
                                Dict.remove key model.filteredToValues

                            else
                                Dict.insert key value model.filteredToValues
                    }
            in
            ( updatedModel
            , updateUrl updatedModel
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

                        Ok "book-print" ->
                            { model | theme = Paper }

                        Ok "paper" ->
                            { model | theme = Paper }

                        Ok "extra-contrast" ->
                            { model | theme = ExtraContrast }

                        Ok "contrast-dark" ->
                            { model | theme = ExtraContrast }

                        Ok "lavender" ->
                            { model | theme = Lavender }

                        Ok "lavander" ->
                            { model | theme = Lavender }

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

        PfsFilterAdded pfs ->
            ( model
            , updateUrl { model | filteredPfs = toggleBoolDict pfs model.filteredPfs }
            )

        PfsFilterRemoved pfs ->
            ( model
            , updateUrl { model | filteredPfs = Dict.remove pfs model.filteredPfs }
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

        RemoveAllAlignmentFiltersPressed ->
            ( model
            , updateUrl { model | filteredAlignments = Dict.empty }
            )

        RemoveAllComponentFiltersPressed ->
            ( model
            , updateUrl { model | filteredComponents = Dict.empty }
            )

        RemoveAllPfsFiltersPressed ->
            ( model
            , updateUrl { model | filteredPfs = Dict.empty }
            )

        RemoveAllSizeFiltersPressed ->
            ( model
            , updateUrl { model | filteredSizes = Dict.empty }
            )

        RemoveAllTraditionFiltersPressed ->
            ( model
            , updateUrl { model | filteredTraditions = Dict.empty }
            )

        RemoveAllTraitFiltersPressed ->
            ( model
            , updateUrl { model | filteredTraits = Dict.empty }
            )

        RemoveAllTypeFiltersPressed ->
            ( model
            , updateUrl { model | filteredTypes = Dict.empty }
            )

        RemoveAllValueFiltersPressed ->
            ( model
            , updateUrl
                { model
                    | filteredFromValues = Dict.empty
                    , filteredToValues = Dict.empty
                }
            )

        SearchTraitsChanged value ->
            ( { model | searchTraits = value }
            , getElementHeight queryOptionsMeasureWrapperId
            )

        SearchTypesChanged value ->
            ( { model | searchTypes = value }
            , getElementHeight filterTypesMeasureWrapperId
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

        ShowFoldableOptionBoxPressed id show ->
            if show then
                ( model
                , getElementHeight id
                )

            else
                ( { model | elementHeights = Dict.insert id 0 model.elementHeights }
                , Cmd.none
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
            , getElementHeight queryOptionsMeasureWrapperId
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

        SizeFilterAdded size ->
            ( model
            , updateUrl { model | filteredSizes = toggleBoolDict size model.filteredSizes }
            )

        SizeFilterRemoved size ->
            ( model
            , updateUrl { model | filteredSizes = Dict.remove size model.filteredSizes }
            )

        SortAbilityChanged value ->
            ( { model | selectedSortAbility = value }
            , Cmd.none
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

        SortResistanceChanged value ->
            ( { model | selectedSortResistance = value }
            , Cmd.none
            )

        SortWeaknessChanged value ->
            ( { model | selectedSortWeakness = value }
            , Cmd.none
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

                    ExtraContrast ->
                        "extra-contrast"

                    Lavender ->
                        "lavender"
                )
            )

        TraditionFilterAdded tradition ->
            ( model
            , updateUrl { model | filteredTraditions = toggleBoolDict tradition model.filteredTraditions }
            )

        TraditionFilterRemoved tradition ->
            ( model
            , updateUrl { model | filteredTraditions = Dict.remove tradition model.filteredTraditions }
            )

        TraitFilterAdded trait ->
            ( model
            , updateUrl { model | filteredTraits = toggleBoolDict trait model.filteredTraits }
            )

        TraitFilterRemoved trait ->
            ( model
            , updateUrl { model | filteredTraits = Dict.remove trait model.filteredTraits }
            )

        TypeFilterAdded type_ ->
            ( model
            , updateUrl { model | filteredTypes = toggleBoolDict type_ model.filteredTypes }
            )

        TypeFilterRemoved type_ ->
            ( model
            , updateUrl { model | filteredTypes = Dict.remove type_ model.filteredTypes }
            )

        UrlChanged url ->
            ( updateModelFromQueryString (parseUrl url) model
            , Cmd.none
            )
                |> searchWithCurrentQuery
                |> updateTitle

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , navigation_pushUrl (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , navigation_loadUrl url
                    )

        WindowResized width height ->
            ( model
            , Cmd.batch
                (measureWrapperIds
                    |> List.filter
                        (\id ->
                            Dict.get id model.elementHeights
                                |> Maybe.withDefault 0
                                |> (/=) 0
                        )
                    |> List.map getElementHeight
                )
            )


toggleBoolDict : comparable -> Dict comparable Bool -> Dict comparable Bool
toggleBoolDict key dict =
    Dict.update
        key
        (\value ->
            case value of
                Just True ->
                    Just False

                Just False ->
                    Nothing

                Nothing ->
                    Just True
        )
        dict


boolDictIncluded : Dict comparable Bool -> List comparable
boolDictIncluded dict =
    dict
        |> Dict.toList
        |> List.filter (Tuple.second)
        |> List.map Tuple.first


boolDictExcluded : Dict comparable Bool -> List comparable
boolDictExcluded dict =
    dict
        |> Dict.toList
        |> List.filter (Tuple.second >> not)
        |> List.map Tuple.first


parseUrl : String -> Url
parseUrl url =
    Url.fromString url
        |> Maybe.withDefault
            { protocol = Url.Http
            , host = ""
            , port_ = Nothing
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }


getElementHeight : String -> Cmd Msg
getElementHeight id =
    document_getElementHeight id


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
            , ( "include-traits"
              , model.filteredTraits
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-traits"
              , model.filteredTraits
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "traits-operator"
              , if model.filterTraitsOperator then
                  ""

                else
                  "or"
              )
            , ( "include-types"
              , model.filteredTypes
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-types"
              , model.filteredTypes
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "include-alignments"
              , model.filteredAlignments
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-alignments"
              , model.filteredAlignments
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "include-components"
              , model.filteredComponents
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-components"
              , model.filteredComponents
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "components-operator"
              , if model.filterComponentsOperator then
                  ""

                else
                  "or"
              )
            , ( "include-pfs"
              , model.filteredPfs
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-pfs"
              , model.filteredPfs
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "include-sizes"
              , model.filteredSizes
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-sizes"
              , model.filteredSizes
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "include-traditions"
              , model.filteredTraditions
                    |> Dict.toList
                    |> List.filter (Tuple.second)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "exclude-traditions"
              , model.filteredTraditions
                    |> Dict.toList
                    |> List.filter (Tuple.second >> not)
                    |> List.map Tuple.first
                    |> String.join ","
              )
            , ( "traditions-operator"
              , if model.filterTraditionsOperator then
                  ""

                else
                  "or"
              )
            , ( "values-from"
              , model.filteredFromValues
                    |> Dict.toList
                    |> List.map (\( field, value ) -> field ++ ":" ++ value)
                    |> String.join ","
              )
            , ( "values-to"
              , model.filteredToValues
                    |> Dict.toList
                    |> List.map (\( field, value ) -> field ++ ":" ++ value)
                    |> String.join ","
              )
            , ( "sort"
              , model.sort
                    |> List.map
                        (\( field, dir ) ->
                            sortFieldToLabel field ++ "-" ++ sortDirToString dir
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
        |> navigation_pushUrl


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
                                , Encode.list Encode.object (buildSearchFilterTerms model)
                                )

                        , if List.isEmpty (buildSearchMustNotTerms model) then
                            Nothing

                          else
                            Just
                                ( "must_not"
                                , Encode.list Encode.object (buildSearchMustNotTerms model)
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
                                    [ ( field
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
        , ( "_source"
          , Encode.object
            [ ( "excludes", Encode.list Encode.string [ "text" ] ) ]
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


sortFieldFromLabel : String -> Maybe String
sortFieldFromLabel field =
    Data.sortFields
        |> List.Extra.find (Tuple.second >> (==) field)
        |> Maybe.map Tuple.first


sortFieldToLabel : String -> String
sortFieldToLabel field =
    Data.sortFields
        |> List.Extra.find (Tuple.first >> (==) field)
        |> Maybe.map Tuple.second
        |> Maybe.withDefault field


sortFieldSuffix : String -> String
sortFieldSuffix field =
    case field of
        "price" -> "cp"
        "range" -> "ft."
        _ -> ""


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


buildSearchFilterTerms : Model -> List (List ( String, Encode.Value ))
buildSearchFilterTerms model =
    List.concat
        [ List.map
            (\( field, list, isAnd ) ->
                if List.isEmpty list then
                    []

                else if isAnd then
                    List.map
                        (\value ->
                            [ ( "term"
                              , Encode.object
                                    [ ( field
                                      , Encode.object
                                            [ ( "value", Encode.string value )
                                            ]
                                      )
                                    ]
                              )
                            ]
                        )
                        list

                else
                    [ [ ( "bool"
                        , Encode.object
                            [ ( "should"
                              , Encode.list Encode.object
                                    (Maybe.Extra.values
                                        [ if List.isEmpty (List.filter ((/=) "none") list) then
                                            Nothing

                                          else
                                            [ ( "terms"
                                              , Encode.object
                                                    [ ( field
                                                      , Encode.list Encode.string (List.filter ((/=) "none") list)
                                                      )
                                                    ]
                                              )
                                            ]
                                                |> Just

                                        , if List.member "none" list then
                                            [ ( "bool"
                                              , Encode.object
                                                    [ ( "must_not"
                                                      , Encode.object
                                                            [ ( "exists"
                                                              , Encode.object
                                                                    [ ( "field", Encode.string field )
                                                                    ]
                                                              )
                                                            ]
                                                      )
                                                    ]
                                              )
                                            ]
                                                |> Just

                                          else
                                            Nothing
                                        ]
                                    )
                              )
                            ]
                        )
                      ]
                    ]
            )
            [ ( "alignment", boolDictIncluded model.filteredAlignments, False )
            , ( "component", boolDictIncluded model.filteredComponents, model.filterComponentsOperator )
            , ( "pfs", boolDictIncluded model.filteredPfs, False )
            , ( "size", boolDictIncluded model.filteredSizes, False )
            , ( "tradition", boolDictIncluded model.filteredTraditions, model.filterTraditionsOperator )
            , ( "trait", boolDictIncluded model.filteredTraits, model.filterTraitsOperator )
            , ( "type", boolDictIncluded model.filteredTypes, False )
            ]
            |> List.concat

        , List.map
            (\( field, value ) ->
                [ ( "range"
                  , Encode.object
                        [ ( field
                          , Encode.object
                                [ ( "gte"
                                  , Encode.float (Maybe.withDefault 0 (String.toFloat value))
                                  )
                                ]
                          )
                        ]
                  )
                ]
            )
            (Dict.toList model.filteredFromValues)

        , List.map
            (\( field, value ) ->
                [ ( "range"
                  , Encode.object
                        [ ( field
                          , Encode.object
                                [ ( "lte"
                                  , Encode.float (Maybe.withDefault 0 (String.toFloat value))
                                  )
                                ]
                          )
                        ]
                  )
                ]
            )
            (Dict.toList model.filteredToValues)
        ]


buildSearchMustNotTerms : Model -> List (List ( String, Encode.Value ))
buildSearchMustNotTerms model =
    List.map
        (\( field, list ) ->
            if List.isEmpty list then
                []

            else
                Maybe.Extra.values
                    [ if List.isEmpty (List.filter ((/=) "none") list) then
                        Nothing

                      else
                        [ ( "terms"
                          , Encode.object
                                [ ( field
                                  , Encode.list Encode.string (List.filter ((/=) "none") list)
                                  )
                                ]
                          )
                        ]
                            |> Just

                    , if List.member "none" list then
                        [ ( "bool"
                          , Encode.object
                                [ ( "must_not"
                                  , Encode.list Encode.object
                                        [ [ ( "exists"
                                            , Encode.object
                                                [ ( "field", Encode.string field )
                                                ]
                                            )
                                          ]
                                        ]
                                  )
                                ]
                          )
                        ]
                            |> Just

                      else
                        Nothing
                    ]
        )
        [ ( "alignment", boolDictExcluded model.filteredAlignments )
        , ( "component", boolDictExcluded model.filteredComponents )
        , ( "pfs", boolDictExcluded model.filteredPfs )
        , ( "size", boolDictExcluded model.filteredSizes )
        , ( "tradition", boolDictExcluded model.filteredTraditions )
        , ( "trait", boolDictExcluded model.filteredTraits )
        , ( "type", boolDictExcluded model.filteredTypes )
        ]
        |> List.concat


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
        , filteredAlignments =
            List.append
                (getQueryParam url "include-alignments"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\alignment -> ( alignment, True ))
                )
                (getQueryParam url "exclude-alignments"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\alignment -> ( alignment, False ))
                )
                |> Dict.fromList
        , filteredComponents =
            List.append
                (getQueryParam url "include-components"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\component -> ( component, True ))
                )
                (getQueryParam url "exclude-components"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\component -> ( component, False ))
                )
                |> Dict.fromList
        , filteredPfs =
            List.append
                (getQueryParam url "include-pfs"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\pfs -> ( pfs, True ))
                )
                (getQueryParam url "exclude-pfs"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\pfs -> ( pfs, False ))
                )
                |> Dict.fromList
        , filteredSizes =
            List.append
                (getQueryParam url "include-sizes"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\size -> ( size, True ))
                )
                (getQueryParam url "exclude-sizes"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\size -> ( size, False ))
                )
                |> Dict.fromList
        , filteredTraditions =
            List.append
                (getQueryParam url "include-traditions"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\tradition -> ( tradition, True ))
                )
                (getQueryParam url "exclude-traditions"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\tradition -> ( tradition, False ))
                )
                |> Dict.fromList
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
        , filteredTypes =
            List.append
                (getQueryParam url "include-types"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\type_ -> ( type_, True ))
                )
                (getQueryParam url "exclude-types"
                    |> String.Extra.nonEmpty
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []
                    |> List.map (\type_ -> ( type_, False ))
                )
                |> Dict.fromList
        , filterComponentsOperator = getQueryParam url "components-operator" /= "or"
        , filterTraditionsOperator = getQueryParam url "traditions-operator" /= "or"
        , filterTraitsOperator = getQueryParam url "traits-operator" /= "or"
        , filteredFromValues =
            getQueryParam url "values-from"
                |> String.Extra.nonEmpty
                |> Maybe.map (String.split ",")
                |> Maybe.withDefault []
                |> List.filterMap
                    (\string ->
                        case String.split ":" string of
                            [ field, value ] ->
                                Just ( field, value )

                            _ ->
                                Nothing
                    )
                |> Dict.fromList
        , filteredToValues =
            getQueryParam url "values-to"
                |> String.Extra.nonEmpty
                |> Maybe.map (String.split ",")
                |> Maybe.withDefault []
                |> List.filterMap
                    (\string ->
                        case String.split ":" string of
                            [ field, value ] ->
                                Just ( field, value )

                            _ ->
                                Nothing
                    )
                |> Dict.fromList
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
                                        (sortFieldFromLabel field)
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
        && Dict.isEmpty model.filteredAlignments
        && Dict.isEmpty model.filteredComponents
        && Dict.isEmpty model.filteredPfs
        && Dict.isEmpty model.filteredSizes
        && Dict.isEmpty model.filteredTraditions
        && Dict.isEmpty model.filteredTraits
        && Dict.isEmpty model.filteredTypes
        && Dict.isEmpty model.filteredFromValues
        && Dict.isEmpty model.filteredToValues
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


updateTitle : ( Model, Cmd msg ) -> ( Model, Cmd msg )
updateTitle ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , document_setTitle model.query
        ]
    )


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Field.require "currentUrl" Decode.string <| \currentUrl ->
    Field.require "elasticUrl" Decode.string <| \elasticUrl ->
    Field.attempt "showHeader" Decode.bool <| \showHeader ->
    Decode.succeed
        { currentUrl = currentUrl
        , elasticUrl = elasticUrl
        , showHeader = Maybe.withDefault defaultFlags.showHeader showHeader
        }


encodeObjectMaybe : List (Maybe ( String, Encode.Value )) -> Encode.Value
encodeObjectMaybe list =
    Maybe.Extra.values list
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


stringListDecoder : Decode.Decoder (List String)
stringListDecoder =
    Decode.oneOf
        [ Decode.list Decode.string
        , Decode.string
            |> Decode.map List.singleton
        ]


documentDecoder : Decode.Decoder Document
documentDecoder =
    Field.require "category" Decode.string <| \category ->
    Field.require "name" Decode.string <| \name ->
    Field.require "type" Decode.string <| \type_ ->
    Field.require "url" Decode.string <| \url ->
    Field.attempt "ability" stringListDecoder <| \abilities ->
    Field.attempt "ability_boost" stringListDecoder <| \abilityBoosts ->
    Field.attempt "ability_flaw" stringListDecoder <| \abilityFlaws ->
    Field.attempt "ability_type" Decode.string <| \abilityType ->
    Field.attempt "ac" Decode.int <| \ac ->
    Field.attempt "actions" Decode.string <| \actions ->
    Field.attempt "activate" Decode.string <| \activate ->
    Field.attempt "advanced_domain_spell" Decode.string <| \advancedDomainSpell ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "ammunition" Decode.string <| \ammunition ->
    Field.attempt "area" Decode.string <| \area ->
    Field.attempt "armor_group" Decode.string <| \armorGroup ->
    Field.attempt "aspect" Decode.string <| \aspect ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "bloodline" stringListDecoder <| \bloodlines ->
    Field.attempt "bulk_raw" Decode.string <| \bulk ->
    Field.attempt "cast" Decode.string <| \cast ->
    Field.attempt "charisma" Decode.int <| \charisma ->
    Field.attempt "check_penalty" Decode.int <| \checkPenalty ->
    Field.attempt "component" (Decode.list Decode.string) <| \components ->
    Field.attempt "constitution" Decode.int <| \constitution ->
    Field.attempt "cost" Decode.string <| \cost ->
    Field.attempt "creature_family" Decode.string <| \creatureFamily ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "deity" stringListDecoder <| \deities ->
    Field.attempt "dex_cap" Decode.int <| \dexCap ->
    Field.attempt "dexterity" Decode.int <| \dexterity ->
    Field.attempt "divine_font" Decode.string <| \divineFont ->
    Field.attempt "domain" (Decode.list Decode.string) <| \domains ->
    Field.attempt "domain_spell" Decode.string <| \domainSpell ->
    Field.attempt "duration" Decode.string <| \duration ->
    Field.attempt "familiar_ability" stringListDecoder <| \familiarAbilities ->
    Field.attempt "favored_weapon" Decode.string <| \favoredWeapon ->
    Field.attempt "feat" stringListDecoder <| \feats ->
    Field.attempt "fortitude_save" Decode.int <| \fort ->
    Field.attempt "frequency" Decode.string <| \frequency ->
    Field.attempt "hands" Decode.string <| \hands ->
    Field.attempt "heighten" (Decode.list Decode.string) <| \heighten ->
    Field.attempt "hp" Decode.int <| \hp ->
    Field.attempt "immunity" (Decode.list Decode.string) <| \immunities ->
    Field.attempt "intelligence" Decode.int <| \intelligence ->
    Field.attempt "lesson_type" Decode.string <| \lessonType ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "mystery" stringListDecoder <| \mysteries ->
    Field.attempt "patron_theme" stringListDecoder <| \patronThemes ->
    Field.attempt "perception" Decode.int <| \perception ->
    Field.attempt "pfs" Decode.string <| \pfs ->
    Field.attempt "prerequisite" Decode.string <| \prerequisites ->
    Field.attempt "price_raw" Decode.string <| \price ->
    Field.attempt "primary_check" Decode.string <| \primaryCheck ->
    Field.attempt "range_raw" Decode.string <| \range ->
    Field.attempt "reflex_save" Decode.int <| \ref ->
    Field.attempt "reload_raw" Decode.string <| \reload ->
    Field.attempt "required_abilities" Decode.string <| \requiredAbilities ->
    Field.attempt "requirement" Decode.string <| \requirements ->
    Field.attempt "resistance_raw" (Decode.list Decode.string) <| \resistances ->
    Field.attempt "saving_throw" Decode.string <| \savingThrow ->
    Field.attempt "secondary_casters_raw" Decode.string <| \secondaryCasters ->
    Field.attempt "secondary_check" Decode.string <| \secondaryChecks ->
    Field.attempt "size" stringListDecoder <| \sizes ->
    Field.attempt "skill" stringListDecoder <| \skills ->
    Field.attempt "source" Decode.string <| \source ->
    Field.attempt "speed" Decode.string <| \speed ->
    Field.attempt "speed_penalty" Decode.string <| \speedPenalty ->
    Field.attempt "spell_list" Decode.string <| \spellList ->
    Field.attempt "spoilers" Decode.string <| \spoilers ->
    Field.attempt "strength" Decode.int <| \strength ->
    Field.attempt "target" Decode.string <| \targets ->
    Field.attempt "tradition" stringListDecoder <| \traditions ->
    Field.attempt "trait_raw" (Decode.list Decode.string) <| \maybeTraits ->
    Field.attempt "trigger" Decode.string <| \trigger ->
    Field.attempt "usage" Decode.string <| \usage ->
    Field.attempt "weakness_raw" (Decode.list Decode.string) <| \weaknesses ->
    Field.attempt "weapon_category" Decode.string <| \weaponCategory ->
    Field.attempt "weapon_group" Decode.string <| \weaponGroup ->
    Field.attempt "will_save" Decode.int <| \will ->
    Field.attempt "wisdom" Decode.int <| \wisdom ->
    Decode.succeed
        { category = category
        , name = name
        , type_ = type_
        , url = url
        , abilities = Maybe.withDefault [] abilities
        , abilityBoosts = Maybe.withDefault [] abilityBoosts
        , abilityFlaws = Maybe.withDefault [] abilityFlaws
        , abilityType = abilityType
        , ac = ac
        , actions = actions
        , activate = activate
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , ammunition = ammunition
        , area = area
        , armorGroup = armorGroup
        , aspect = aspect
        , breadcrumbs = breadcrumbs
        , bloodlines = Maybe.withDefault [] bloodlines
        , bulk = bulk
        , cast = cast
        , charisma = charisma
        , checkPenalty = checkPenalty
        , components = Maybe.withDefault [] components
        , constitution = constitution
        , cost = cost
        , creatureFamily = creatureFamily
        , damage = damage
        , deities = Maybe.withDefault [] deities
        , dexCap = dexCap
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
        , mysteries = Maybe.withDefault [] mysteries
        , patronThemes = Maybe.withDefault [] patronThemes
        , perception = perception
        , pfs = pfs
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
        , sizes = Maybe.withDefault [] sizes
        , skills = Maybe.withDefault [] skills
        , source = source
        , speed = speed
        , speedPenalty = speedPenalty
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


getUrl : Document -> String
getUrl doc =
    "https://2e.aonprd.com/" ++ doc.url


view : Model -> Html Msg
view model =
    Html.div
        []
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

                ExtraContrast ->
                    Html.text cssExtraContrast

                Lavender ->
                    Html.text cssLavender
            ]
        , FontAwesome.Styles.css
        , Html.div
            [ HA.class "body-container"
            , HA.class "column"
            , HA.class "align-center"
            ]
            (List.append
                (if model.showHeader then
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
                    ]

                 else
                    []
                )
                [ Html.div
                    [ HA.class "column"
                    , HA.class "content-container"
                    , HA.class "gap-large"
                    ]
                    [ if model.showHeader then
                        viewTitle

                      else
                        Html.text ""
                    , Html.main_
                        [ HA.class "column gap-large"
                        ]
                        [ viewQuery model
                        , viewSearchResults model
                        ]
                    ]
                ]
            )
        ]


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
                        , viewRadioButton
                            { checked = model.theme == ExtraContrast
                            , name = "theme-type"
                            , onInput = ThemeSelected ExtraContrast
                            , text = "Extra Contrast"
                            }
                        , viewRadioButton
                            { checked = model.theme == Lavender
                            , name = "theme-type"
                            , onInput = ThemeSelected Lavender
                            , text = "Lavender"
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
                        [ HA.href "https://2e.aonprd.com/"
                        , HA.target "_blank"
                        ]
                        [ Html.text "Archives of Nethys" ]
                    , Html.text ", the System Reference Document for Pathfinder Second Edition."
                    ]
                , viewFaq
                    "How can I contact you?"
                    [ Html.text "You can send me an email (nethys-search <at> galdiuz.com), message me on Discord (Galdiuz#7937), or "
                    , Html.a
                        [ HA.href "https://github.com/galdiuz/nethys-search/issues"
                        , HA.target "_blank"
                        ]
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
                [ HA.href "https://2e.aonprd.com/"
                , HA.target "_blank"
                ]
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
            [ HA.class "row"
            , HA.class "input-container"
            ]
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
            [ HA.class "foldable-container"
            , HA.style "height"
                (if model.queryOptionsOpen then
                    String.fromInt (getQueryOptionsHeight model) ++ "px"

                 else "0"
                )
            ]
            [ Html.div
                [ HA.id queryOptionsMeasureWrapperId ]
                [ viewQueryOptions model ]
            ]

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
                , HA.class "gap-small"
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

        , viewFilters model

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
                                [ HA.class "row"
                                , HA.class "gap-tiny"
                                , HE.onClick (SortRemoved field)
                                ]
                                [ Html.text (sortFieldToLabel field ++ " " ++ sortDirToString dir)
                                , if dir == Asc then
                                    getSortAscIcon field

                                  else
                                    getSortDescIcon field
                                ]
                        )
                        model.sort
                    ]
                )
        ]


viewFilters : Model -> Html Msg
viewFilters model =
    Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        , HA.class "align-center"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            , HA.class "align-center"
            ]
            (List.map
                (\{ class, label, list, removeMsg } ->
                    if List.isEmpty list then
                        Html.text ""

                    else
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "align-center"
                            ]
                            (List.append
                                [ Html.text label ]
                                (List.map
                                    (\value ->
                                        Html.button
                                            [ HA.class "row"
                                            , HA.class "gap-tiny"
                                            , HAE.attributeMaybe HA.class class
                                            , getTraitClass value
                                            , HE.onClick (removeMsg value)
                                            ]
                                            [ viewPfsIcon value
                                            , Html.text (String.Extra.toSentenceCase value)
                                            ]
                                    )
                                    list
                                )
                            )
                )
                [ { class = Just "trait"
                  , label =
                        if model.filterTraitsOperator then
                            "Include all traits:"

                        else
                            "Include any trait:"
                  , list = boolDictIncluded model.filteredTraits
                  , removeMsg = TraitFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Exclude traits:"
                  , list = boolDictExcluded model.filteredTraits
                  , removeMsg = TraitFilterRemoved
                  }
                , { class = Just "filter-type"
                  , label = "Include types:"
                  , list = boolDictIncluded model.filteredTypes
                  , removeMsg = TypeFilterRemoved
                  }
                , { class = Just "filter-type"
                  , label = "Exclude types:"
                  , list = boolDictExcluded model.filteredTypes
                  , removeMsg = TypeFilterRemoved
                  }
                , { class = Nothing
                  , label =
                        if model.filterTraditionsOperator then
                            "Include all traditions:"

                        else
                            "Include any tradition:"
                  , list = boolDictIncluded model.filteredTraditions
                  , removeMsg = TraditionFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude traditions:"
                  , list = boolDictExcluded model.filteredTraditions
                  , removeMsg = TraditionFilterRemoved
                  }
                , { class = Just "trait trait-alignment"
                  , label = "Include alignments:"
                  , list = boolDictIncluded model.filteredAlignments
                  , removeMsg = AlignmentFilterRemoved
                  }
                , { class = Just "trait trait-alignment"
                  , label = "Exclude alignments:"
                  , list = boolDictExcluded model.filteredAlignments
                  , removeMsg = AlignmentFilterRemoved
                  }
                , { class = Just "component"
                  , label =
                        if model.filterComponentsOperator then
                            "Include all components:"

                        else
                            "Include any component:"
                  , list = boolDictIncluded model.filteredComponents
                  , removeMsg = ComponentFilterRemoved
                  }
                , { class = Just "component"
                  , label = "Exclude components:"
                  , list = boolDictExcluded model.filteredComponents
                  , removeMsg = ComponentFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include PFS:"
                  , list = boolDictIncluded model.filteredPfs
                  , removeMsg = PfsFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude PFS:"
                  , list = boolDictExcluded model.filteredPfs
                  , removeMsg = PfsFilterRemoved
                  }
                , { class = Just "trait trait-size"
                  , label = "Include sizes:"
                  , list = boolDictIncluded model.filteredSizes
                  , removeMsg = SizeFilterRemoved
                  }
                , { class = Just "trait trait-size"
                  , label = "Exclude sizes:"
                  , list = boolDictExcluded model.filteredSizes
                  , removeMsg = SizeFilterRemoved
                  }
                ]
            )

        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            , HA.class "align-baseline"
            ]
            (Dict.merge
                (\field from ->
                    (::) ( field, Just from, Nothing )
                )
                (\field from to ->
                    (::) ( field, Just from, Just to )
                )
                (\field to ->
                    (::) ( field, Nothing, Just to )
                )
                model.filteredFromValues
                model.filteredToValues
                []
                |> List.map
                    (\( field, maybeFrom, maybeTo ) ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "align-baseline"
                            ]
                            [ Html.text (sortFieldToLabel field ++ ":")
                            , maybeFrom
                                |> Maybe.map
                                    (\from ->
                                        Html.button
                                            [ HE.onClick (FilteredFromValueChanged field "")
                                            ]
                                            [ Html.text ("at least " ++ from ++ " " ++ sortFieldSuffix field) ]
                                    )
                                |> Maybe.withDefault (Html.text "")
                            , maybeTo
                                |> Maybe.map
                                    (\to ->
                                        Html.button
                                            [ HE.onClick (FilteredToValueChanged field "")
                                            ]
                                            [ Html.text ("up to " ++ to ++ " " ++ sortFieldSuffix field) ]
                                    )
                                |> Maybe.withDefault (Html.text "")
                            ]
                    )
            )
        ]


viewQueryOptions : Model -> Html Msg
viewQueryOptions model =
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ viewFoldableOptionBox
            model
            "Query type"
            queryTypeMeasureWrapperId
            (viewQueryType model)
        , viewFoldableOptionBox
            model
            "Filter types"
            filterTypesMeasureWrapperId
            (viewFilterTypes model)
        , viewFoldableOptionBox
            model
            "Filter traits"
            filterTraitsMeasureWrapperId
            (viewFilterTraits model)
        , viewFoldableOptionBox
            model
            "Filter alignments"
            filterAlignmentsMeasureWrapperId
            (viewFilterAlignments model)
        , viewFoldableOptionBox
            model
            "Filter traditions"
            filterTraditionsMeasureWrapperId
            (viewFilterTraditions model)
        , viewFoldableOptionBox
            model
            "Filter spell components"
            filterComponentsMeasureWrapperId
            (viewFilterComponents model)
        , viewFoldableOptionBox
            model
            "Filter PFS status"
            filterPfsMeasureWrapperId
            (viewFilterPfs model)
        , viewFoldableOptionBox
            model
            "Filter sizes"
            filterSizesMeasureWrapperId
            (viewFilterSizes model)
        , viewFoldableOptionBox
            model
            "Filter numeric values"
            filterValuesMeasureWrapperId
            (viewFilterValues model)
        , viewFoldableOptionBox
            model
            "Sort results"
            sortResultsMeasureWrapperId
            (viewSortResults model)
        ]


viewFoldableOptionBox : Model -> String -> String -> List (Html Msg) -> Html Msg
viewFoldableOptionBox model label wrapperId content =
    let
        height : Int
        height =
            Dict.get wrapperId model.elementHeights
                |> Maybe.withDefault 0
    in
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        ]
        [ Html.button
            [ HA.style "border" "0"
            , HA.style "padding" "0"
            , HE.onClick (ShowFoldableOptionBoxPressed wrapperId (height == 0))
            ]
            [ Html.h3
                [ HA.class "row"
                , HA.class "gap-tiny"
                ]
                [ Html.text label
                , FontAwesome.Icon.viewStyled
                    [ SA.class "rotatable"
                    , if height == 0 then
                        SA.class ""

                      else
                        SA.class "rotate180"
                    ]
                    FontAwesome.Solid.chevronDown
                ]
            ]
        , Html.div
            [ HA.class "foldable-container"
            , HA.style "height" (String.fromInt height ++ "px")
            ]
            [ Html.div
                [ HA.id wrapperId
                , HA.class "column"
                , HA.class "gap-small"
                , HA.style "padding-top" "var(--gap-small)"
                ]
                content
            ]
        ]


viewQueryType : Model -> List (Html Msg)
viewQueryType model =
    [ Html.div
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
        ]
    , Html.div
        []
        [ Html.text "With the complex query type you can write queries using Elasticsearch Query String syntax. The general idea is that you can search in specific fields by searching "
        , Html.span
            [ HA.class "monospace" ]
            [ Html.text "field:value" ]
        , Html.text ". For full documentation on how the query syntax works see "
        , Html.a
            [ HA.href "https://www.elastic.co/guide/en/elasticsearch/reference/7.15/query-dsl-query-string-query.html#query-string-syntax"
            , HA.target "_blank"
            ]
            [ Html.text "Elasticsearch's documentation" ]
        , Html.text ". See below for a list of available fields. [n] means the field is numeric and supports range queries."
        ]
    , Html.div
        [ HA.class "scrollbox"
        , HA.class "column"
        , HA.class "gap-medium"
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
        , Html.div
            [ HA.class "column" ]
            [ Html.text "Valid types for resistance and weakness:"
            , Html.div
                []
                (List.map
                    (\type_ ->
                        Html.span
                            [ HA.class "monospace" ]
                            [ Html.text type_ ]
                    )
                    Data.damageTypes
                    |> List.intersperse (Html.text ", ")
                )
            ]
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
    , Html.div
        []
        [ Html.div
            []
            [ Html.text "Creatures resistant to fire but not all damage:" ]
        , Html.div
            [ HA.class "monospace" ]
            [ Html.text "resistance.fire:* NOT resistance.all:*" ]
        ]
    ]


viewFilterTypes : Model -> List (Html Msg)
viewFilterTypes model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllTypeFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]

    , Html.div
        [ HA.class "row"
        , HA.class "input-container"
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
                    , HA.class "row"
                    , HA.class "align-center"
                    , HA.class "gap-tiny"
                    , HE.onClick (TypeFilterAdded type_)
                    ]
                    [ Html.text type_
                    , viewFilterIcon (Dict.get type_ model.filteredTypes)
                    ]
            )
            (List.filter
                (String.toLower >> String.contains (String.toLower model.searchTypes))
                Data.types
            )
        )
    ]


viewFilterTraits : Model -> List (Html Msg)
viewFilterTraits model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllTraitFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = model.filterTraitsOperator
            , name = "filter-traits"
            , onInput = FilterTraitsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not model.filterTraitsOperator
            , name = "filter-traits"
            , onInput = FilterTraitsOperatorChanged False
            , text = "Include any (OR)"
            }
        ]

    , Html.div
        [ HA.class "row"
        , HA.class "input-container"
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
            (\trait ->
                Html.button
                    [ HA.class "trait"
                    , getTraitClass trait
                    , HA.class "row"
                    , HA.class "align-center"
                    , HA.class "gap-tiny"
                    , HE.onClick (TraitFilterAdded trait)
                    ]
                    [ Html.text trait
                    , viewFilterIcon (Dict.get trait model.filteredTraits)
                    ]
            )
            (List.filter
                (String.toLower >> String.contains (String.toLower model.searchTraits))
                Data.traits
            )
        )
    ]


viewFilterTraditions : Model -> List (Html Msg)
viewFilterTraditions model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllTraditionFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = model.filterTraditionsOperator
            , name = "filter-traditions"
            , onInput = FilterTraditionsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not model.filterTraditionsOperator
            , name = "filter-traditions"
            , onInput = FilterTraditionsOperatorChanged False
            , text = "Include any (OR)"
            }
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\tradition ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (TraditionFilterAdded tradition)
                    ]
                    [ Html.text (String.Extra.toTitleCase tradition)
                    , viewFilterIcon (Dict.get tradition model.filteredTraditions)
                    ]
            )
            [ "arcane"
            , "divine"
            , "occult"
            , "primal"
            ]
        )
    ]


viewFilterAlignments : Model -> List (Html Msg)
viewFilterAlignments model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllAlignmentFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\(alignment, label) ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "trait"
                    , HA.class "trait-alignment"
                    , HE.onClick (AlignmentFilterAdded alignment)
                    ]
                    [ Html.text label
                    , viewFilterIcon (Dict.get alignment model.filteredAlignments)
                    ]
            )
            Data.alignments
        )
    ]


viewFilterComponents : Model -> List (Html Msg)
viewFilterComponents model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllComponentFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = model.filterComponentsOperator
            , name = "filter-components"
            , onInput = FilterComponentsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not model.filterComponentsOperator
            , name = "filter-components"
            , onInput = FilterComponentsOperatorChanged False
            , text = "Include any (OR)"
            }
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\component ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (ComponentFilterAdded component)
                    ]
                    [ Html.text (String.Extra.toTitleCase component)
                    , viewFilterIcon (Dict.get component model.filteredComponents)
                    ]
            )
            [ "material"
            , "somatic"
            , "verbal"
            ]
        )
    ]


viewFilterPfs : Model -> List (Html Msg)
viewFilterPfs model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllPfsFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\pfs ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (PfsFilterAdded pfs)
                    ]
                    [ viewPfsIcon pfs
                    , Html.text (String.Extra.toTitleCase pfs)
                    , viewFilterIcon (Dict.get pfs model.filteredPfs)
                    ]
            )
            [ "none"
            , "standard"
            , "limited"
            , "restricted"
            ]
        )
    ]


viewFilterSizes : Model -> List (Html Msg)
viewFilterSizes model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllSizeFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\size ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "trait"
                    , HA.class "trait-size"
                    , HE.onClick (SizeFilterAdded size)
                    ]
                    [ Html.text (String.Extra.toTitleCase size)
                    , viewFilterIcon (Dict.get size model.filteredSizes)
                    ]
            )
            [ "tiny"
            , "small"
            , "medium"
            , "large"
            , "huge"
            , "gargantuan"
            ]
        )
    ]


viewFilterValues : Model -> List (Html Msg)
viewFilterValues model =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllValueFiltersPressed
        ]
        [ Html.text "Reset all values" ]
    , Html.div
        [ HA.class "grid"
        , HA.class "gap-large"
        , HA.style "grid-template-columns" "repeat(auto-fill,minmax(250px, 1fr))"
        , HA.style "row-gap" "var(--gap-medium)"
        ]
        (List.concat
            [ List.map
                (\{ field, hint, step, suffix } ->
                    Html.div
                        [ HA.class "column"
                        , HA.class "gap-tiny"
                        ]
                        [ Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            ]
                            [ Html.h4
                                []
                                [ Html.text (sortFieldToLabel field) ]
                            , Html.text (Maybe.withDefault "" hint)
                            ]
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "align-baseline"
                            ]
                            [ Html.div
                                [ HA.class "input-container"
                                , HA.class "row"
                                , HA.class "align-baseline"
                                ]
                                [ Html.input
                                    [ HA.type_ "number"
                                    , HA.step step
                                    , HA.value (Maybe.withDefault "" (Dict.get field model.filteredFromValues))
                                    , HE.onInput (FilteredFromValueChanged field)
                                    ]
                                    []
                                , case suffix of
                                    Just s ->
                                        Html.div
                                            [ HA.style "padding-right" "2px" ]
                                            [ Html.text s ]

                                    Nothing ->
                                        Html.text ""
                                ]
                            , Html.text "to"
                            , Html.div
                                [ HA.class "input-container"
                                , HA.class "row"
                                , HA.class "align-baseline"
                                ]
                                [ Html.input
                                    [ HA.type_ "number"
                                    , HA.step step
                                    , HA.value (Maybe.withDefault "" (Dict.get field model.filteredToValues))
                                    , HE.onInput (FilteredToValueChanged field)
                                    ]
                                    []
                                , case suffix of
                                    Just s ->
                                        Html.div
                                            [ HA.style "padding-right" "2px" ]
                                            [ Html.text s ]

                                    Nothing ->
                                        Html.text ""
                                ]
                            ]
                        ]
                )
                [ { field = "level"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                , { field = "price"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Just "cp"
                  }
                , { field = "bulk"
                  , hint = Just "(L bulk is 0,1)"
                  , step = "0.1"
                  , suffix = Nothing
                  }
                , { field = "range"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Just "ft."
                  }
                , { field = "hp"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                , { field = "ac"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                , { field = "fortitude_save"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                , { field = "reflex_save"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                , { field = "will_save"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                , { field = "perception"
                  , hint = Nothing
                  , step = "1"
                  , suffix = Nothing
                  }
                ]
            , [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    [ Html.h4
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-center"
                        ]
                        [ Html.select
                            [ HA.class "input-container"
                            , HA.style "align-self" "flex-start"
                            , HE.onInput FilterAbilityChanged
                            ]
                            (List.map
                                (\ability ->
                                    Html.option
                                        [ HA.value ability ]
                                        [ Html.text (sortFieldToLabel ability)
                                        ]
                                )
                                [ "strength"
                                , "dexterity"
                                , "constitution"
                                , "intelligence"
                                , "wisdom"
                                , "charisma"
                                ]
                            )
                        , Html.text "score"
                        ]
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-center"
                        ]
                        [ Html.div
                            [ HA.class "input-container"
                            , HA.class "row"
                            , HA.class "align-baseline"
                            ]
                            [ Html.input
                                [ HA.type_ "number"
                                , HA.step "1"
                                , HA.value (Maybe.withDefault "" (Dict.get model.selectedFilterAbility model.filteredFromValues))
                                , HE.onInput (FilteredFromValueChanged model.selectedFilterAbility)
                                ]
                                []
                            ]
                        , Html.text "to"
                        , Html.div
                            [ HA.class "input-container"
                            , HA.class "row"
                            , HA.class "align-baseline"
                            ]
                            [ Html.input
                                [ HA.type_ "number"
                                , HA.step "1"
                                , HA.value (Maybe.withDefault "" (Dict.get model.selectedFilterAbility model.filteredToValues))
                                , HE.onInput (FilteredToValueChanged model.selectedFilterAbility)
                                ]
                                []
                            ]
                        ]
                    ]
              , Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    [ Html.h4
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-baseline"
                        ]
                        [ Html.select
                            [ HA.class "input-container"
                            , HE.onInput FilterResistanceChanged
                            ]
                            (List.map
                                (\type_ ->
                                    Html.option
                                        [ HA.value type_ ]
                                        [ Html.text (String.Extra.humanize type_) ]
                                )
                                Data.damageTypes
                            )
                        , Html.text "resistance"
                        ]
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-center"
                        ]
                        [ Html.div
                            [ HA.class "input-container"
                            , HA.class "row"
                            , HA.class "align-baseline"
                            ]
                            [ Html.input
                                [ HA.type_ "number"
                                , HA.step "1"
                                , HA.value
                                    (Maybe.withDefault
                                        ""
                                        (Dict.get
                                            ("resistance." ++ model.selectedFilterResistance)
                                            model.filteredFromValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredFromValueChanged
                                        ("resistance." ++ model.selectedFilterResistance)
                                    )
                                ]
                                []
                            ]
                        , Html.text "to"
                        , Html.div
                            [ HA.class "input-container"
                            , HA.class "row"
                            , HA.class "align-baseline"
                            ]
                            [ Html.input
                                [ HA.type_ "number"
                                , HA.step "1"
                                , HA.value
                                    (Maybe.withDefault
                                        ""
                                        (Dict.get
                                            ("resistance." ++ model.selectedFilterResistance)
                                            model.filteredToValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredToValueChanged
                                        ("resistance." ++ model.selectedFilterResistance)
                                    )
                                ]
                                []
                            ]
                        ]
                    ]
              , Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    [ Html.h4
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-baseline"
                        ]
                        [ Html.select
                            [ HA.class "input-container"
                            , HE.onInput FilterWeaknessChanged
                            ]
                            (List.map
                                (\type_ ->
                                    Html.option
                                        [ HA.value type_ ]
                                        [ Html.text (String.Extra.humanize type_) ]
                                )
                                Data.damageTypes
                            )
                        , Html.text "weakness"
                        ]
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-center"
                        ]
                        [ Html.div
                            [ HA.class "input-container"
                            , HA.class "row"
                            , HA.class "align-baseline"
                            ]
                            [ Html.input
                                [ HA.type_ "number"
                                , HA.step "1"
                                , HA.value
                                    (Maybe.withDefault
                                        ""
                                        (Dict.get
                                            ("weakness." ++ model.selectedFilterWeakness)
                                            model.filteredFromValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredFromValueChanged
                                        ("weakness." ++ model.selectedFilterWeakness)
                                    )
                                ]
                                []
                            ]
                        , Html.text "to"
                        , Html.div
                            [ HA.class "input-container"
                            , HA.class "row"
                            , HA.class "align-baseline"
                            ]
                            [ Html.input
                                [ HA.type_ "number"
                                , HA.step "1"
                                , HA.value
                                    (Maybe.withDefault
                                        ""
                                        (Dict.get
                                            ("weakness." ++ model.selectedFilterWeakness)
                                            model.filteredToValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredToValueChanged
                                        ("weakness." ++ model.selectedFilterWeakness)
                                    )
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            ]
        )
    ]


viewSortResults : Model -> List (Html Msg)
viewSortResults model =
    [ Html.div
        [ HA.class "grid"
        , HA.style "grid-template-columns" "repeat(auto-fill,minmax(250px, 1fr))"
        , HA.class "gap-medium"
        ]
        (List.concat
            [ [ Html.button
                    [ HA.style "justify-self" "flex-start"
                    , HE.onClick RemoveAllSortsPressed
                    ]
                    [ Html.text "Reset selection" ]
              ]
            , (List.map
                (\field ->
                    Html.div
                        [ HA.class "row"
                        , HA.class "gap-tiny"
                        , HA.class "align-baseline"
                        ]
                        (List.append
                            (viewSortButtons model field)
                            [ Html.text (sortFieldToLabel field)
                            ]
                        )
                )
                [ "name.keyword"
                , "level"
                , "type"
                , "price"
                , "bulk"
                , "range"
                , "hp"
                , "ac"
                , "fortitude_save"
                , "reflex_save"
                , "will_save"
                , "perception"
                ]
              )
            , [ Html.div
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "align-baseline"
                    ]
                    (List.append
                        (viewSortButtons model (model.selectedSortAbility))
                        [ Html.select
                            [ HA.class "input-container"
                            , HE.onInput SortAbilityChanged
                            ]
                            (List.map
                                (\ability ->
                                    Html.option
                                        [ HA.value ability ]
                                        [ Html.text (sortFieldToLabel ability) ]
                                )
                                [ "strength"
                                , "dexterity"
                                , "constitution"
                                , "intelligence"
                                , "wisdom"
                                , "charisma"
                                ]
                            )
                        ]
                    )
              ]
            ]
        )
    , Html.div
        [ HA.class "grid"
        , HA.style "grid-template-columns" "repeat(auto-fill,minmax(340px, 1fr))"
        , HA.class "gap-medium"
        ]
        [ Html.div
                [ HA.class "row"
                , HA.class "gap-tiny"
                , HA.class "align-baseline"
                ]
                (List.append
                    (viewSortButtons model ("resistance." ++ model.selectedSortResistance))
                    [ Html.select
                        [ HA.class "input-container"
                        , HE.onInput SortResistanceChanged
                        ]
                        (List.map
                            (\type_ ->
                                Html.option
                                    [ HA.value type_ ]
                                    [ Html.text (String.Extra.humanize type_) ]
                            )
                            Data.damageTypes
                        )
                    , Html.text "resistance"
                    ]
                )
          , Html.div
                [ HA.class "row"
                , HA.class "gap-tiny"
                , HA.class "align-baseline"
                ]
                (List.append
                    (viewSortButtons model ("weakness." ++ model.selectedSortWeakness))
                    [ Html.select
                        [ HA.class "input-container"
                        , HE.onInput SortWeaknessChanged
                        ]
                        (List.map
                            (\type_ ->
                                Html.option
                                    [ HA.value type_ ]
                                    [ Html.text (String.Extra.humanize type_) ]
                            )
                            Data.damageTypes
                        )
                    , Html.text "weakness"
                    ]
                )
          ]
    ]


viewSortButtons : Model -> String -> List (Html Msg)
viewSortButtons model field =
    [ Html.button
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
        , HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ Html.text "Asc"
        , getSortAscIcon field
        ]
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
        , HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ Html.text "Desc"
        , getSortDescIcon field
        ]
    ]


viewFilterIcon : Maybe Bool -> Html msg
viewFilterIcon value =
    case value of
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
        , HA.style "min-height" "800px"
        , HA.style "display" "flex"
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
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                ]
                [ viewPfsIcon (Maybe.withDefault "" hit.source.pfs)
                , Html.a
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
                    Maybe.Extra.values
                        [ hit.source.frequency
                            |> Maybe.map (viewLabelAndText "Frequency")
                        , hit.source.trigger
                            |> Maybe.map (viewLabelAndText "Trigger")
                        , hit.source.requirements
                            |> Maybe.map (viewLabelAndText "Requirements")
                        ]

                "ancestry" ->
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.hp
                                |> Maybe.map String.fromInt
                                |> Maybe.map (viewLabelAndText "HP")
                            , hit.source.sizes
                                |> nonEmptyList
                                |> Maybe.map (String.join " or ")
                                |> Maybe.map (viewLabelAndText "Size")
                            , hit.source.speed
                                |> Maybe.map (viewLabelAndText "Speed")
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.abilityBoosts
                                |> nonEmptyList
                                |> Maybe.map (viewLabelAndPluralizedText "Ability Bost" "Ability Boosts")
                            , hit.source.abilityFlaws
                                |> nonEmptyList
                                |> Maybe.map (viewLabelAndPluralizedText "Ability Flaw" "Ability Flaws")
                            ]
                        )
                    ]

                "armor" ->
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.price
                                |> Maybe.map (viewLabelAndText "Price")
                            , hit.source.ac
                                |> Maybe.map numberWithSign
                                |> Maybe.map (viewLabelAndText "AC Bonus")
                            , hit.source.dexCap
                                |> Maybe.map numberWithSign
                                |> Maybe.map (viewLabelAndText "Dex Cap")
                            , hit.source.checkPenalty
                                |> Maybe.map numberWithSign
                                |> Maybe.map (viewLabelAndText "Check Penalty")
                            , hit.source.speedPenalty
                                |> Maybe.map (viewLabelAndText "Speed Penalty")
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.strength
                                |> Maybe.map String.fromInt
                                |> Maybe.map (viewLabelAndText "Strength")
                            , hit.source.bulk
                                |> Maybe.map (viewLabelAndText "Bulk")
                            , hit.source.armorGroup
                                |> Maybe.map (viewLabelAndText "Armor Group")
                            ]
                        )
                    ]

                "background" ->
                    Maybe.Extra.values
                        [ hit.source.abilities
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Ability" "Abilities")
                        , hit.source.feats
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Feat" "Feats")
                        , hit.source.skills
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Skill" "Skills")
                        ]

                "bloodline" ->
                    hit.source.spellList
                        |> Maybe.map (viewLabelAndText "Spell List")
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "creature" ->
                    Maybe.Extra.values
                        [ hit.source.creatureFamily
                            |> Maybe.map (viewLabelAndText "Creature Family")
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.hp
                                    |> Maybe.map String.fromInt
                                    |> Maybe.map (viewLabelAndText "HP")
                                , hit.source.ac
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
                            (Maybe.Extra.values
                                [ hit.source.strength
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Str")
                                , hit.source.dexterity
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Dex")
                                , hit.source.constitution
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Con")
                                , hit.source.intelligence
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Int")
                                , hit.source.wisdom
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Wis")
                                , hit.source.charisma
                                    |> Maybe.map numberWithSign
                                    |> Maybe.map (viewLabelAndText "Cha")
                                ]
                            )
                                |> Just
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.immunities
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Immunity" "Immunities")
                                , hit.source.resistances
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Resistance" "Resistances")
                                , hit.source.weaknesses
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Weakness" "Weaknesses")
                                ]
                            )
                                |> Just
                        ]

                "deity" ->
                    Maybe.Extra.values
                        [ hit.source.divineFont
                            |> Maybe.map (viewLabelAndText "Divine Font")
                        , hit.source.skills
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Divine Skill" "Divine Skills")
                        , hit.source.favoredWeapon
                            |> Maybe.map (viewLabelAndText "Favored Weapon")
                        , hit.source.domains
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Domain" "Domains")
                        ]

                "domain" ->
                    Maybe.Extra.values
                        [ hit.source.deities
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Deity" "Deities")
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.domainSpell
                                    |> Maybe.map (viewLabelAndText "Domain Spell")
                                , hit.source.advancedDomainSpell
                                    |> Maybe.map (viewLabelAndText "Advanced Domain Spell")
                                ]
                            )
                                |> Just
                        ]

                "eidolon" ->
                    Maybe.Extra.values
                        [ hit.source.traditions
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Tradition" "Traditions")
                        ]

                "equipment" ->
                    Maybe.Extra.values
                        [ hit.source.price
                            |> Maybe.map (viewLabelAndText "Price")
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.hands
                                    |> Maybe.map (viewLabelAndText "Hands")
                                , hit.source.usage
                                    |> Maybe.map (viewLabelAndText "Usage")
                                , hit.source.bulk
                                    |> Maybe.map (viewLabelAndText "Bulk")
                                ]
                            )
                                |> Just
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.activate
                                    |> Maybe.map (viewLabelAndText "Activate")
                                , hit.source.frequency
                                    |> Maybe.map (viewLabelAndText "Frequency")
                                , hit.source.trigger
                                    |> Maybe.map (viewLabelAndText "Trigger")
                                ]
                            )
                                |> Just
                        ]

                "familiar" ->
                    hit.source.abilityType
                        |> Maybe.map (viewLabelAndText "Ability Type")
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                "familiar-specific" ->
                    Maybe.Extra.values
                        [ hit.source.requiredAbilities
                            |> Maybe.map (viewLabelAndText "Required Number of Abilities")
                        , hit.source.familiarAbilities
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Granted Ability" "Granted Abilities")
                        ]

                "feat" ->
                    Maybe.Extra.values
                        [ hit.source.frequency
                            |> Maybe.map (viewLabelAndText "Frequency")
                        , hit.source.prerequisites
                            |> Maybe.map (viewLabelAndText "Prerequisites")
                        , hit.source.trigger
                            |> Maybe.map (viewLabelAndText "Trigger")
                        , hit.source.requirements
                            |> Maybe.map (viewLabelAndText "Requirements")
                        ]

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
                    Maybe.Extra.values
                        [ hit.source.aspect
                            |> Maybe.map (viewLabelAndText "Aspect")
                        , hit.source.prerequisites
                            |> Maybe.map (viewLabelAndText "Prerequisite")
                        ]

                "ritual" ->
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.cast
                                |> Maybe.map (viewLabelAndText "Cast")
                            , hit.source.cost
                                |> Maybe.map (viewLabelAndText "Cost")
                            , hit.source.secondaryCasters
                                |> Maybe.map (viewLabelAndText "Secondary Casters")
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.primaryCheck
                                |> Maybe.map (viewLabelAndText "Primary Check")
                            , hit.source.secondaryChecks
                                |> Maybe.map (viewLabelAndText "Secondary Checks")
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.range
                                |> Maybe.map (viewLabelAndText "Range")
                            , hit.source.targets
                                |> Maybe.map (viewLabelAndText "Targets")
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.duration
                                |> Maybe.map (viewLabelAndText "Duration")
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
                    Maybe.Extra.values
                        [ hit.source.traditions
                            |> nonEmptyList
                            |> Maybe.map (viewLabelAndPluralizedText "Tradition" "Traditions")

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.bloodlines
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Bloodline" "Bloodlines")
                                , hit.source.domains
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Domain" "Domains")
                                , hit.source.mysteries
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Mystery" "Mysteries")
                                , hit.source.patronThemes
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Patron Theme" "Patron Themes")
                                , hit.source.deities
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Deity" "Deities")
                                ]
                            )
                                |> Just

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.cast
                                    |> Maybe.map (viewLabelAndText "Cast")
                                , hit.source.components
                                    |> nonEmptyList
                                    |> Maybe.map (viewLabelAndPluralizedText "Component" "Components")
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
                            (Maybe.Extra.values
                                [ hit.source.range
                                    |> Maybe.map (viewLabelAndText "Range")
                                , hit.source.targets
                                    |> Maybe.map (viewLabelAndText "Targets")
                                , hit.source.area
                                    |> Maybe.map (viewLabelAndText "Area")
                                ]
                            )
                                |> Just

                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            (Maybe.Extra.values
                                [ hit.source.duration
                                    |> Maybe.map (viewLabelAndText "Duration")
                                , hit.source.savingThrow
                                    |> Maybe.map (viewLabelAndText "Saving Throw")
                                ]
                            )
                                |> Just
                        , hit.source.heighten
                            |> String.join ", "
                            |> String.Extra.nonEmpty
                            |> Maybe.map (viewLabelAndText "Heightened")
                        ]

                "weapon" ->
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.price
                                |> Maybe.map (viewLabelAndText "Price")
                            , hit.source.damage
                                |> Maybe.map (viewLabelAndText "Damage")
                            , hit.source.bulk
                                |> Maybe.map (viewLabelAndText "Bulk")
                            ]
                        )
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.hands
                                |> Maybe.map (viewLabelAndText "Hands")
                            , hit.source.range
                                |> Maybe.map (viewLabelAndText "Range")
                            , hit.source.reload
                                |> Maybe.map (viewLabelAndText "Reload")
                            ]
                        )
                    , hit.source.ammunition
                        |> Maybe.map (viewLabelAndText "Ammunition")
                        |> Maybe.withDefault (Html.text "")
                    , Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        ]
                        (Maybe.Extra.values
                            [ hit.source.weaponCategory
                                |> Maybe.map (viewLabelAndText "Category")
                            , hit.source.weaponGroup
                                |> Maybe.map (viewLabelAndText "Group")
                            ]
                        )
                    ]

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


nonEmptyList : List a -> Maybe (List a)
nonEmptyList list =
    if List.isEmpty list then
        Nothing

    else
        Just list


viewLabelAndText : String -> String -> Html msg
viewLabelAndText label text =
    Html.div
        []
        [ viewLabel label
        , Html.text " "
        , viewTextWithActionIcons text
        ]


viewLabelAndPluralizedText : String -> String -> List String -> Html msg
viewLabelAndPluralizedText singular plural strings =
    viewLabelAndText
        (if List.length strings > 1 then
            plural

         else
            singular
        )
        (String.join ", " strings)


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
        , getTraitClass trait
        ]
        [ Html.text trait ]


getTraitClass : String -> Html.Attribute msg
getTraitClass trait =
    case trait of
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


getSortAscIcon : String -> Html msg
getSortAscIcon field =
    if List.member field [ "name.keyword", "type" ] then
        FontAwesome.Icon.viewIcon FontAwesome.Solid.sortAlphaUp

    else
        FontAwesome.Icon.viewIcon FontAwesome.Solid.sortNumericUp


getSortDescIcon : String -> Html msg
getSortDescIcon field =
    if List.member field [ "name.keyword", "type" ] then
        FontAwesome.Icon.viewIcon FontAwesome.Solid.sortAlphaDownAlt

    else
        FontAwesome.Icon.viewIcon FontAwesome.Solid.sortNumericDownAlt


viewPfsIcon : String -> Html msg
viewPfsIcon pfs =
    case String.toLower pfs of
        "standard" ->
            viewPfsStandard

        "limited" ->
            viewPfsLimited

        "restricted" ->
            viewPfsRestricted

        _ ->
            Html.text ""


viewPfsStandard : Html msg
viewPfsStandard =
    Svg.svg
        [ SA.viewBox "0 0 100 100"
        , SA.height "1em"
        ]
        [ Svg.circle
            [ SA.cx "50"
            , SA.cy "50"
            , SA.r "50"
            , SA.fill "#4ab5f1"
            ]
            []
        , Svg.circle
            [ SA.cx "50"
            , SA.cy "50"
            , SA.r "40"
            , SA.fill "#94805d"
            ]
            []
        ]


viewPfsLimited : Html msg
viewPfsLimited =
    Svg.svg
        [ SA.viewBox "0 0 100 100"
        , SA.height "1em"
        ]
        [ Svg.rect
            [ SA.height "80"
            , SA.width "90"
            , SA.fill "#ecef23"
            , SA.x "5"
            , SA.y "15"
            ]
            []
        , Svg.polygon
            [ SA.points "15,100 25,50 50,0 75,50 85,100"
            , SA.fill "#476468"
            ]
            []
        ]


viewPfsRestricted : Html msg
viewPfsRestricted =
    Svg.svg
        [ SA.viewBox "0 0 100 100"
        , SA.height "1em"
        ]
        [ Svg.line
            [ SA.x1 "10"
            , SA.x2 "90"
            , SA.y1 "10"
            , SA.y2 "90"
            , SA.strokeWidth "30"
            , SA.stroke "#e81d1d"
            ]
            []
        , Svg.line
            [ SA.x1 "10"
            , SA.x2 "90"
            , SA.y1 "90"
            , SA.y2 "10"
            , SA.strokeWidth "30"
            , SA.stroke "#e81d1d"
            ]
            []
        , Svg.circle
            [ SA.cx "50"
            , SA.cy "50"
            , SA.r "35"
            , SA.fill "#dddddd"
            ]
            []
        ]


stringContainsChar : String -> String -> Bool
stringContainsChar str chars =
    String.any
        (\char ->
            String.contains (String.fromChar char) str
        )
        chars


getQueryOptionsHeight : Model -> Int
getQueryOptionsHeight model =
    measureWrapperIds
        |> List.map (\id -> Dict.get id model.elementHeights)
        |> List.map (Maybe.withDefault 0)
        |> List.sum


measureWrapperIds : List String
measureWrapperIds =
    [ queryOptionsMeasureWrapperId
    , queryTypeMeasureWrapperId
    , filterAlignmentsMeasureWrapperId
    , filterComponentsMeasureWrapperId
    , filterPfsMeasureWrapperId
    , filterSizesMeasureWrapperId
    , filterTraditionsMeasureWrapperId
    , filterTraitsMeasureWrapperId
    , filterTypesMeasureWrapperId
    , filterValuesMeasureWrapperId
    , sortResultsMeasureWrapperId
    ]


queryOptionsMeasureWrapperId : String
queryOptionsMeasureWrapperId =
    "query-options-measure-wrapper"


queryTypeMeasureWrapperId : String
queryTypeMeasureWrapperId =
    "query-type-measure-wrapper"


filterTypesMeasureWrapperId : String
filterTypesMeasureWrapperId =
    "filter-types-measure-wrapper"


filterAlignmentsMeasureWrapperId : String
filterAlignmentsMeasureWrapperId =
    "filter-alignments-measure-wrapper"


filterComponentsMeasureWrapperId : String
filterComponentsMeasureWrapperId =
    "filter-components-measure-wrapper"


filterTraitsMeasureWrapperId : String
filterTraitsMeasureWrapperId =
    "filter-traits-measure-wrapper"


filterTraditionsMeasureWrapperId : String
filterTraditionsMeasureWrapperId =
    "filter-traditions-measure-wrapper"


filterSizesMeasureWrapperId : String
filterSizesMeasureWrapperId =
    "filter-sizes-measure-wrapper"


filterPfsMeasureWrapperId : String
filterPfsMeasureWrapperId =
    "filter-pfs-measure-wrapper"


filterValuesMeasureWrapperId : String
filterValuesMeasureWrapperId =
    "filter-values-measure-wrapper"


sortResultsMeasureWrapperId : String
sortResultsMeasureWrapperId =
    "sort-results-measure-wrapper"


css : String
css =
    """
    @font-face {
        font-family: "Pathfinder-Icons";
        src: url("Pathfinder-Icons.ttf");
        font-display: swap;
    }

    body {
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

    h4 {
        font-size: var(--font-medium);
        margin: 0;
    }

    input[type=text], input[type=number] {
        background-color: transparent;
        border-width: 0;
        color: var(--color-text);
        padding: 4px;
        flex-grow: 1;
    }

    input:invalid {
        color: #ff8888;
    }

    input[type=number] {
        width: 80px;
    }

    input:focus-visible {
        border-width: 0;
        border-style: none;
        border-image: none;
        outline: 0;
    }

    select {
        color: var(--color-text);
        font-size: var(--font-normal);
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
        background-color: var(--color-bg);
        color: var(--color-text);
        font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif;
        font-size: var(--font-normal);
        line-height: normal;
        min-height: 100%;
        min-width: 400px;
        position: relative;
        --font-normal: 16px;
        --font-large: 20px;
        --font-very-large: 24px;
        --gap-tiny: 4px;
        --gap-small: 8px;
        --gap-medium: 12px;
        --gap-large: 20px;
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

    .grid {
        display: grid;
    }

    .column:empty, .row:empty, .grid:empty {
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

    .gap-medium.grid, .gap-large.grid {
        row-gap: var(--gap-small);
    }

    .gap-small {
        gap: var(--gap-small);
    }

    .gap-tiny {
        gap: var(--gap-tiny);
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
        outline: 0;
    }

    .icon-font {
        color: var(--color-icon);
        font-family: "Pathfinder-Icons";
        font-variant-caps: normal;
        font-weight: normal;
    }

    .input-button {
        background-color: transparent;
        border-width: 0;
        color: var(--color-text);
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
        padding: 8px;
    }

    .query-input {
        font-size: var(--font-very-large);
    }

    .foldable-container {
        transition: height ease-in-out 0.2s;
        overflow: hidden;
    }

    .rotatable {
        transition: transform ease-in-out 0.2s
    }

    .rotate180 {
        transform: rotate(-180deg);
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
    .body-container {
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
    .body-container {
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
    .body-container {
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


cssExtraContrast : String
cssExtraContrast =
    """
    .body-container {
        --color-bg: #111111;
        --color-bg-secondary: #282828;
        --color-container-bg: #333333;
        --color-container-border: #eeeeee;
        --color-element-bg: #5d0000;
        --color-element-border: #d8c483;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #291716;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #656148;
        --color-element-text: #cbc18f;
        --color-subelement-bg: #769477;
        --color-subelement-text: #111111;
        --color-icon: #cccccc;
        --color-inactive-text: #999999;
        --color-text: #eeeeee;
    }
    """


cssLavender : String
cssLavender =
    """
    .body-container {
        --color-bg: #ffffff;
        --color-bg-secondary: #cccccc;
        --color-container-bg: #dddddd;
        --color-container-border: #111111;
        --color-element-bg: #493a88;
        --color-element-border: #d8c483;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #291716;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #656148;
        --color-element-text: #cbc18f;
        --color-subelement-bg: #f0e6ff;
        --color-subelement-text: #111111;
        --color-icon: #000000;
        --color-inactive-text: #999999;
        --color-text: #000000;
    }
    """
