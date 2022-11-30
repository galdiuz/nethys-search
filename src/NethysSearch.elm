port module NethysSearch exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Data
import Dict exposing (Dict)
import Dict.Extra
import FontAwesome
import FontAwesome.Attributes
import FontAwesome.Regular
import FontAwesome.Solid
import FontAwesome.Styles
import Html exposing (Html)
import Html.Attributes as HA
import Html.Attributes.Extra as HAE
import Html.Events as HE
import Html.Keyed
import Http
import Json.Decode as Decode
import Json.Decode.Extra as DecodeE
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
import Set exposing (Set)
import String.Extra
import Svg
import Svg.Attributes as SA
import Task
import Tuple3
import Url exposing (Url)
import Url.Builder
import Url.Parser
import Url.Parser.Query


port document_setTitle : String -> Cmd msg
port localStorage_set : Encode.Value -> Cmd msg
port localStorage_get : String -> Cmd msg
port localStorage_receive : (Decode.Value -> msg) -> Sub msg
port navigation_loadUrl : String -> Cmd msg
port navigation_pushUrl : String -> Cmd msg
port navigation_urlChanged : (String -> msg) -> Sub msg


type alias Model =
    { autofocus : Bool
    , autoQueryType : Bool
    , elasticUrl : String
    , fixedParams : Dict String String
    , groupTraits : Bool
    , groupedDisplay : GroupedDisplay
    , groupedLinkLayout : GroupedLinkLayout
    , groupedShowPfs : Bool
    , groupedSort : GroupedSort
    , limitTableWidth : Bool
    , menuOpen : Bool
    , openInNewTab : Bool
    , overlayActive : Bool
    , pageDefaultDisplays : Dict String (Dict String String)
    , pageId : String
    , pageSize : Int
    , resultBaseUrl : String
    , savedColumnConfigurations : Dict String (List String)
    , savedColumnConfigurationName : String
    , searchModel : SearchModel
    , showHeader : Bool
    , showResultAdditionalInfo : Bool
    , showResultSpoilers : Bool
    , showResultSummary : Bool
    , showResultTraits : Bool
    , sourcesAggregation : Maybe (Result Http.Error (List Source))
    , theme : Theme
    , url : Url
    }


type alias SearchModel =
    { aggregations : Maybe (Result Http.Error Aggregations)
    , alwaysShowFilters : List String
    , debounce : Int
    , defaultQuery : String
    , filteredAbilities : Dict String Bool
    , filteredActions : Dict String Bool
    , filteredAlignments : Dict String Bool
    , filteredComponents : Dict String Bool
    , filteredCreatureFamilies : Dict String Bool
    , filteredFromValues : Dict String String
    , filteredHands : Dict String Bool
    , filteredItemCategories : Dict String Bool
    , filteredItemSubcategories : Dict String Bool
    , filteredPfs : Dict String Bool
    , filteredRarities : Dict String Bool
    , filteredReloads : Dict String Bool
    , filteredSavingThrows : Dict String Bool
    , filteredSchools : Dict String Bool
    , filteredSizes : Dict String Bool
    , filteredSkills : Dict String Bool
    , filteredSourceCategories : Dict String Bool
    , filteredSources : Dict String Bool
    , filteredStrongestSaves : Dict String Bool
    , filteredToValues : Dict String String
    , filteredTraditions : Dict String Bool
    , filteredTraits : Dict String Bool
    , filteredTypes : Dict String Bool
    , filteredWeakestSaves : Dict String Bool
    , filteredWeaponCategories : Dict String Bool
    , filteredWeaponGroups : Dict String Bool
    , filteredWeaponTypes : Dict String Bool
    , filterComponentsOperator : Bool
    , filterSpoilers : Bool
    , filterTraditionsOperator : Bool
    , filterTraitsOperator : Bool
    , fixedQueryString : String
    , groupField1 : String
    , groupField2 : Maybe String
    , groupField3 : Maybe String
    , lastSearchHash : Maybe String
    , query : String
    , queryType : QueryType
    , removeFilters : List String
    , resultDisplay : ResultDisplay
    , searchCreatureFamilies : String
    , searchItemCategories : String
    , searchItemSubcategories : String
    , searchResultGroupAggs : Maybe GroupAggregations
    , searchResults : List (Result Http.Error SearchResult)
    , searchSources : String
    , searchTraits : String
    , searchTypes : String
    , selectedColumnResistance : String
    , selectedColumnSpeed : String
    , selectedColumnWeakness : String
    , selectedFilterAbility : String
    , selectedFilterResistance : String
    , selectedFilterSpeed : String
    , selectedFilterWeakness : String
    , selectedSortAbility : String
    , selectedSortResistance : String
    , selectedSortSpeed : String
    , selectedSortWeakness : String
    , showAllFilters : Bool
    , sort : List ( String, SortDir )
    , sortHasChanged : Bool
    , tableColumns : List String
    , tracker : Maybe Int
    , visibleFilterBoxes : Set String
    }


emptySearchModel :
   { alwaysShowFilters : List String
   , defaultQuery : String
   , removeFilters : List String
   , fixedQueryString : String
   }
   -> SearchModel
emptySearchModel { alwaysShowFilters, defaultQuery, fixedQueryString, removeFilters }=
    { aggregations = Nothing
    , alwaysShowFilters = alwaysShowFilters
    , debounce = 0
    , defaultQuery = defaultQuery
    , filteredAbilities = Dict.empty
    , filteredActions = Dict.empty
    , filteredAlignments = Dict.empty
    , filteredComponents = Dict.empty
    , filteredCreatureFamilies = Dict.empty
    , filteredFromValues = Dict.empty
    , filteredHands = Dict.empty
    , filteredItemCategories = Dict.empty
    , filteredItemSubcategories = Dict.empty
    , filteredRarities = Dict.empty
    , filteredReloads = Dict.empty
    , filteredSavingThrows = Dict.empty
    , filteredSchools = Dict.empty
    , filteredPfs = Dict.empty
    , filteredSizes = Dict.empty
    , filteredSkills = Dict.empty
    , filteredSourceCategories = Dict.empty
    , filteredSources = Dict.empty
    , filteredStrongestSaves = Dict.empty
    , filteredToValues = Dict.empty
    , filteredTraditions = Dict.empty
    , filteredTraits = Dict.empty
    , filteredTypes = Dict.empty
    , filteredWeakestSaves = Dict.empty
    , filteredWeaponCategories = Dict.empty
    , filteredWeaponGroups = Dict.empty
    , filteredWeaponTypes = Dict.empty
    , filterComponentsOperator = True
    , filterSpoilers = False
    , filterTraditionsOperator = True
    , filterTraitsOperator = True
    , fixedQueryString = fixedQueryString
    , groupField1 = "type"
    , groupField2 = Nothing
    , groupField3 = Nothing
    , lastSearchHash = Nothing
    , query = ""
    , queryType = Standard
    , removeFilters = removeFilters
    , resultDisplay = List
    , searchResultGroupAggs = Nothing
    , searchCreatureFamilies = ""
    , searchItemCategories = ""
    , searchItemSubcategories = ""
    , searchResults = []
    , searchSources = ""
    , searchTraits = ""
    , searchTypes = ""
    , selectedColumnResistance = "acid"
    , selectedColumnSpeed = "land"
    , selectedColumnWeakness = "acid"
    , selectedFilterAbility = "strength"
    , selectedFilterResistance = "acid"
    , selectedFilterSpeed = "land"
    , selectedFilterWeakness = "acid"
    , selectedSortAbility = "strength"
    , selectedSortResistance = "acid"
    , selectedSortSpeed = "land"
    , selectedSortWeakness = "acid"
    , showAllFilters = False
    , sort = []
    , sortHasChanged = False
    , tableColumns = []
    , tracker = Nothing
    , visibleFilterBoxes = Set.empty
    }


type alias SearchResult =
    { hits : List (Hit Document)
    , total : Int
    , groupAggs : Maybe GroupAggregations
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
    , abilityFlaws : List String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedApocryphalSpell : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , ammunition : Maybe String
    , apocryphalSpell : Maybe String
    , archetype : Maybe String
    , area : Maybe String
    , armorCategory : Maybe String
    , armorGroup : Maybe String
    , attackProficiencies : List String
    , aspect : Maybe String
    , baseItems : Maybe String
    , bloodlines : Maybe String
    , breadcrumbs : Maybe String
    , bulk : Maybe String
    , charisma : Maybe Int
    , checkPenalty : Maybe Int
    , complexity : Maybe String
    , components : List String
    , constitution : Maybe Int
    , cost : Maybe String
    , creatureFamily : Maybe String
    , creatureFamilyMarkdown : Maybe String
    , damage : Maybe String
    , defenseProficiencies : List String
    , deities : Maybe String
    , deityCategory : Maybe String
    , dexCap : Maybe Int
    , dexterity : Maybe Int
    , divineFonts : List String
    , domains : Maybe String
    , domainSpell : Maybe String
    , duration : Maybe String
    , durationValue : Maybe Int
    , familiarAbilities : List String
    , favoredWeapons : Maybe String
    , feats : Maybe String
    , followerAlignments : List String
    , fort : Maybe Int
    , fortitudeProficiency : Maybe String
    , frequency : Maybe String
    , hands : Maybe String
    , hardness : Maybe String
    , hazardType : Maybe String
    , heighten : List String
    , heightenLevels : List Int
    , hp : Maybe String
    , iconImage : Maybe String
    , images : List String
    , immunities : Maybe String
    , intelligence : Maybe Int
    , itemCategory : Maybe String
    , itemSubcategory : Maybe String
    , languages : Maybe String
    , lessons : Maybe String
    , lessonType : Maybe String
    , level : Maybe Int
    , mysteries : Maybe String
    , onset : Maybe String
    , patronThemes : Maybe String
    , perception : Maybe Int
    , perceptionProficiency : Maybe String
    , pfs : Maybe String
    , planeCategory : Maybe String
    , prerequisites : Maybe String
    , price : Maybe String
    , primaryCheck : Maybe String
    , range : Maybe String
    , rangeValue : Maybe Int
    , rarity : Maybe String
    , ref : Maybe Int
    , reflexProficiency : Maybe String
    , region : Maybe String
    , releaseDate : Maybe String
    , reload : Maybe String
    , requiredAbilities : Maybe String
    , requirements : Maybe String
    , resistanceValues : Maybe DamageTypeValues
    , resistances : Maybe String
    , savingThrow : Maybe String
    , school : Maybe String
    , searchMarkdown : ParsedMarkdownResult
    , secondaryCasters : Maybe String
    , secondaryChecks : Maybe String
    , senses : Maybe String
    , sizes : List String
    , skills : Maybe String
    , skillProficiencies : List String
    , sourceCategory : Maybe String
    , sourceGroup : Maybe String
    , sourceList : List String
    , sources : Maybe String
    , speed : Maybe String
    , speedValues : Maybe SpeedTypeValues
    , speedPenalty : Maybe String
    , spellList : Maybe String
    , spoilers : Maybe String
    , stages : Maybe String
    , strength : Maybe Int
    , strongestSaves : List String
    , summary : Maybe String
    , targets : Maybe String
    , traditionList : List String
    , traditions : Maybe String
    , traitList : List String
    , traits : Maybe String
    , trigger : Maybe String
    , usage : Maybe String
    , vision : Maybe String
    , weakestSaves : List String
    , weaknessValues : Maybe DamageTypeValues
    , weaknesses : Maybe String
    , weaponCategory : Maybe String
    , weaponGroup : Maybe String
    , weaponGroupMarkdown : Maybe String
    , weaponType : Maybe String
    , will : Maybe Int
    , willProficiency : Maybe String
    , wisdom : Maybe Int
    }


type alias GroupAggregations =
    { group1 : List GroupBucket
    , group2 : Maybe (List GroupBucket)
    , group3 : Maybe (List GroupBucket)
    }


type alias GroupBucket =
    { count : Int
    , key1 : Maybe String
    , key2 : Maybe String
    , key3 : Maybe String
    }


type alias Flags =
    { autofocus : Bool
    , currentUrl : String
    , defaultQuery : String
    , elasticUrl : String
    , fixedParams : Dict String String
    , fixedQueryString : String
    , localStorage : Dict String String
    , pageId : String
    , removeFilters : List String
    , resultBaseUrl : String
    , showFilters : List String
    , showHeader : Bool
    }


defaultFlags : Flags
defaultFlags =
    { autofocus = False
    , currentUrl = "/"
    , defaultQuery = ""
    , elasticUrl = ""
    , fixedParams = Dict.empty
    , fixedQueryString = ""
    , localStorage = Dict.empty
    , pageId = ""
    , removeFilters = []
    , resultBaseUrl = "https://2e.aonprd.com/"
    , showFilters = [ "numbers", "pfs", "rarities", "traits", "types" ]
    , showHeader = True
    }


type alias Aggregations =
    { actions : List String
    , creatureFamilies : List String
    , hands : List String
    , itemCategories : List String
    , itemSubcategories : List { category : String, name : String }
    , reloads : List String
    , sources : List String
    , traits : List String
    , traitGroups : Dict String (List String)
    , types : List String
    , weaponGroups : List String
    }


type alias DamageTypeValues =
    { acid : Maybe Int
    , all : Maybe Int
    , area : Maybe Int
    , bleed : Maybe Int
    , bludgeoning : Maybe Int
    , chaotic : Maybe Int
    , cold : Maybe Int
    , coldIron : Maybe Int
    , electricity : Maybe Int
    , evil : Maybe Int
    , fire : Maybe Int
    , force : Maybe Int
    , good : Maybe Int
    , lawful : Maybe Int
    , mental : Maybe Int
    , negative : Maybe Int
    , orichalcum : Maybe Int
    , physical : Maybe Int
    , piercing : Maybe Int
    , poison : Maybe Int
    , positive : Maybe Int
    , precision : Maybe Int
    , silver : Maybe Int
    , slashing : Maybe Int
    , sonic : Maybe Int
    , splash : Maybe Int
    }


type alias SpeedTypeValues =
    { burrow : Maybe Int
    , climb : Maybe Int
    , fly : Maybe Int
    , land : Maybe Int
    , max : Maybe Int
    , swim : Maybe Int
    }


type alias FilterBox =
    { id : String
    , label : String
    , view : Model -> SearchModel -> List (Html Msg)
    }


type alias ParsedMarkdownResult =
    Result (List String) (List Markdown.Block.Block)


type QueryType
    = Standard
    | ElasticsearchQueryString


type LoadType
    = LoadNew
    | LoadNewForce
    | LoadMore Int


type ResultDisplay
    = Grouped
    | List
    | Table


type GroupedDisplay
    = Show
    | Dim
    | Hide


type GroupedLinkLayout
    = Horizontal
    | Vertical
    | VerticalWithSummary


type GroupedSort
    = Alphanum
    | CountLoaded
    | CountTotal


type SortDir
    = Asc
    | Desc


type Theme
    = Blackbird
    | Dark
    | Dead
    | ExtraContrast
    | Lavender
    | Light
    | Orc
    | Paper


type Msg
    = AbilityFilterAdded String
    | AbilityFilterRemoved String
    | ActionsFilterAdded String
    | ActionsFilterRemoved String
    | AlignmentFilterAdded String
    | AlignmentFilterRemoved String
    | AutoQueryTypeChanged Bool
    | ColumnResistanceChanged String
    | ColumnSpeedChanged String
    | ColumnWeaknessChanged String
    | ComponentFilterAdded String
    | ComponentFilterRemoved String
    | CreatureFamilyFilterAdded String
    | CreatureFamilyFilterRemoved String
    | DebouncePassed Int
    | DeleteColumnConfigurationPressed
    | GotAggregationsResult (Result Http.Error Aggregations)
    | GotGroupAggregationsResult (Result Http.Error SearchResult)
    | GotSearchResult (Result Http.Error SearchResult)
    | GotSourcesAggregationResult (Result Http.Error (List Source))
    | FilterAbilityChanged String
    | FilterComponentsOperatorChanged Bool
    | FilterResistanceChanged String
    | FilterSpeedChanged String
    | FilterSpoilersChanged Bool
    | FilterTraditionsOperatorChanged Bool
    | FilterTraitsOperatorChanged Bool
    | FilterWeaknessChanged String
    | FilteredFromValueChanged String String
    | FilteredToValueChanged String String
    | GroupField1Changed String
    | GroupField2Changed (Maybe String)
    | GroupField3Changed (Maybe String)
    | GroupTraitsChanged Bool
    | GroupedDisplayChanged GroupedDisplay
    | GroupedLinkLayoutChanged GroupedLinkLayout
    | GroupedShowPfsIconChanged Bool
    | GroupedSortChanged GroupedSort
    | HandFilterAdded String
    | HandFilterRemoved String
    | ItemCategoryFilterAdded String
    | ItemCategoryFilterRemoved String
    | ItemSubcategoryFilterAdded String
    | ItemSubcategoryFilterRemoved String
    | LimitTableWidthChanged Bool
    | LoadMorePressed Int
    | LoadPageDefaultDisplayPressed
    | LocalStorageValueReceived Decode.Value
    | MenuOpenDelayPassed
    | NoOp
    | OpenInNewTabChanged Bool
    | PageSizeChanged Int
    | PfsFilterAdded String
    | PfsFilterRemoved String
    | QueryChanged String
    | QueryTypeSelected QueryType
    | RarityFilterAdded String
    | RarityFilterRemoved String
    | ReloadFilterAdded String
    | ReloadFilterRemoved String
    | RemoveAllAbilityFiltersPressed
    | RemoveAllActionsFiltersPressed
    | RemoveAllAlignmentFiltersPressed
    | RemoveAllComponentFiltersPressed
    | RemoveAllCreatureFamilyFiltersPressed
    | RemoveAllHandFiltersPressed
    | RemoveAllItemCategoryFiltersPressed
    | RemoveAllItemSubcategoryFiltersPressed
    | RemoveAllPfsFiltersPressed
    | RemoveAllRarityFiltersPressed
    | RemoveAllReloadFiltersPressed
    | RemoveAllSavingThrowFiltersPressed
    | RemoveAllSchoolFiltersPressed
    | RemoveAllSizeFiltersPressed
    | RemoveAllSkillFiltersPressed
    | RemoveAllSortsPressed
    | RemoveAllSourceCategoryFiltersPressed
    | RemoveAllSourceFiltersPressed
    | RemoveAllStrongestSaveFiltersPressed
    | RemoveAllTraditionFiltersPressed
    | RemoveAllTraitFiltersPressed
    | RemoveAllTypeFiltersPressed
    | RemoveAllValueFiltersPressed
    | RemoveAllWeakestSaveFiltersPressed
    | RemoveAllWeaponCategoryFiltersPressed
    | RemoveAllWeaponGroupFiltersPressed
    | RemoveAllWeaponTypeFiltersPressed
    | ResultDisplayChanged ResultDisplay
    | SaveColumnConfigurationPressed
    | SavePageDefaultDisplayPressed
    | SavedColumnConfigurationNameChanged String
    | SavedColumnConfigurationSelected String
    | SavingThrowFilterAdded String
    | SavingThrowFilterRemoved String
    | SchoolFilterAdded String
    | SchoolFilterRemoved String
    | ScrollToTopPressed
    | SearchCreatureFamiliesChanged String
    | SearchItemCategoriesChanged String
    | SearchItemSubcategoriesChanged String
    | SearchSourcesChanged String
    | SearchTraitsChanged String
    | SearchTypesChanged String
    | ShowAdditionalInfoChanged Bool
    | ShowAllFilters
    | ShowFilterBox String Bool
    | ShowMenuPressed Bool
    | ShowSpoilersChanged Bool
    | ShowSummaryChanged Bool
    | ShowTraitsChanged Bool
    | SizeFilterAdded String
    | SizeFilterRemoved String
    | SkillFilterAdded String
    | SkillFilterRemoved String
    | SortAbilityChanged String
    | SortAdded String SortDir
    | SortOrderChanged Int Int
    | SortRemoved String
    | SortResistanceChanged String
    | SortSetChosen (List ( String, SortDir ))
    | SortSpeedChanged String
    | SortToggled String
    | SortWeaknessChanged String
    | SourceCategoryFilterAdded String
    | SourceCategoryFilterRemoved String
    | SourceFilterAdded String
    | SourceFilterRemoved String
    | StrongestSaveFilterAdded String
    | StrongestSaveFilterRemoved String
    | TableColumnAdded String
    | TableColumnMoved Int Int
    | TableColumnRemoved String
    | TableColumnSetChosen (List String)
    | ThemeSelected Theme
    | TraditionFilterAdded String
    | TraditionFilterRemoved String
    | TraitGroupDeselectPressed (List String)
    | TraitGroupExcludePressed (List String)
    | TraitGroupIncludePressed (List String)
    | TraitFilterAdded String
    | TraitFilterRemoved String
    | TypeFilterAdded String
    | TypeFilterRemoved String
    | UrlChanged String
    | UrlRequested Browser.UrlRequest
    | WeakestSaveFilterAdded String
    | WeakestSaveFilterRemoved String
    | WeaponCategoryFilterAdded String
    | WeaponCategoryFilterRemoved String
    | WeaponGroupFilterAdded String
    | WeaponGroupFilterRemoved String
    | WeaponTypeFilterAdded String
    | WeaponTypeFilterRemoved String


type alias Source =
    { category : String
    , name : String
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
    ( { autofocus = flags.autofocus
      , autoQueryType = False
      , elasticUrl = flags.elasticUrl
      , fixedParams = flags.fixedParams
      , groupTraits = False
      , groupedDisplay = Dim
      , groupedLinkLayout = Horizontal
      , groupedShowPfs = True
      , groupedSort = Alphanum
      , limitTableWidth = False
      , menuOpen = False
      , openInNewTab = False
      , overlayActive = False
      , pageDefaultDisplays = Dict.empty
      , pageId = flags.pageId
      , pageSize = 50
      , resultBaseUrl = flags.resultBaseUrl
      , savedColumnConfigurations = Dict.empty
      , savedColumnConfigurationName = ""
      , searchModel =
            emptySearchModel
                { alwaysShowFilters = flags.showFilters
                , defaultQuery = flags.defaultQuery
                , fixedQueryString = flags.fixedQueryString
                , removeFilters = flags.removeFilters
                }
      , showHeader = flags.showHeader
      , showResultAdditionalInfo = True
      , showResultSpoilers = True
      , showResultSummary = True
      , showResultTraits = True
      , sourcesAggregation = Nothing
      , theme = Dark
      , url = url
      }
        |> \model ->
            List.foldl
                (updateModelFromLocalStorage)
                model
                (Dict.toList flags.localStorage)
        |> updateModelFromUrl url
    , Cmd.none
    )
        |> searchWithCurrentQuery LoadNew
        |> updateTitle
        |> getAggregations
        |> getSourcesAggregation


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ localStorage_receive LocalStorageValueReceived
        , navigation_urlChanged UrlChanged
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AbilityFilterAdded abilities ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAbilities = toggleBoolDict abilities searchModel.filteredAbilities }
                )
                model
                |> updateUrlWithSearchParams
            )

        AbilityFilterRemoved abilities ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAbilities = Dict.remove abilities searchModel.filteredAbilities }
                )
                model
                |> updateUrlWithSearchParams
            )

        ActionsFilterAdded actions ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredActions = toggleBoolDict actions searchModel.filteredActions }
                )
                model
                |> updateUrlWithSearchParams
            )

        ActionsFilterRemoved actions ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredActions = Dict.remove actions searchModel.filteredActions }
                )
                model
                |> updateUrlWithSearchParams
            )

        AlignmentFilterAdded alignment ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAlignments = toggleBoolDict alignment searchModel.filteredAlignments }
                )
                model
                |> updateUrlWithSearchParams
            )

        AlignmentFilterRemoved alignment ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAlignments = Dict.remove alignment searchModel.filteredAlignments }
                )
                model
                |> updateUrlWithSearchParams
            )

        AutoQueryTypeChanged enabled ->
            ( { model | autoQueryType = enabled }
            , Cmd.batch
                [ saveToLocalStorage
                    "auto-query-type"
                    (if enabled then "1" else "0")
                , updateUrlWithSearchParams { model | autoQueryType = enabled }
                ]
            )

        ColumnResistanceChanged resistance ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedColumnResistance = resistance }
                )
                model
            , Cmd.none
            )

        ColumnSpeedChanged speed ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedColumnSpeed = speed }
                )
                model
            , Cmd.none
            )

        ColumnWeaknessChanged weakness ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedColumnWeakness = weakness }
                )
                model
            , Cmd.none
            )

        ComponentFilterAdded component ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredComponents = toggleBoolDict component searchModel.filteredComponents }
                )
                model
                |> updateUrlWithSearchParams
            )

        ComponentFilterRemoved component ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredComponents = Dict.remove component searchModel.filteredComponents }
                )
                model
                |> updateUrlWithSearchParams
            )

        CreatureFamilyFilterAdded creatureFamily ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredCreatureFamilies = toggleBoolDict creatureFamily searchModel.filteredCreatureFamilies }
                )
                model
                |> updateUrlWithSearchParams
            )

        CreatureFamilyFilterRemoved creatureFamily ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredCreatureFamilies = Dict.remove creatureFamily searchModel.filteredCreatureFamilies }
                )
                model
                |> updateUrlWithSearchParams
            )

        DebouncePassed debounce ->
            if model.searchModel.debounce == debounce then
                ( model
                , updateUrlWithSearchParams model
                )

            else
                ( model, Cmd.none )

        DeleteColumnConfigurationPressed ->
            ( { model
                | savedColumnConfigurations =
                    Dict.remove
                        model.savedColumnConfigurationName
                        model.savedColumnConfigurations
              }
            , Cmd.none
            )
                |> saveColumnConfigurationsToLocalStorage

        GotAggregationsResult result ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | aggregations = Just result }
                )
                model
            , Cmd.none
            )

        GotGroupAggregationsResult result ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | searchResultGroupAggs =
                            result
                                |> Result.toMaybe
                                |> Maybe.andThen .groupAggs
                    }
                )
                model
            , Cmd.none
            )

        GotSearchResult result ->
            let
                containsTeleport : Bool
                containsTeleport =
                    model.url.query
                        |> Maybe.map (\q -> String.contains "teleport=true" q)
                        |> Maybe.withDefault False

                firstResultUrl : Maybe String
                firstResultUrl =
                    result
                        |> Result.toMaybe
                        |> Maybe.map .hits
                        |> Maybe.andThen List.head
                        |> Maybe.map .source
                        |> Maybe.map (getUrl model)
            in
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | searchResults =
                            List.append
                                (List.filter Result.Extra.isOk searchModel.searchResults)
                                [ result ]
                        , searchResultGroupAggs =
                            result
                                |> Result.toMaybe
                                |> Maybe.andThen .groupAggs
                                |> Maybe.Extra.orElse searchModel.searchResultGroupAggs
                        , tracker = Nothing
                    }
                )
                model
            , case ( containsTeleport, firstResultUrl ) of
                ( True, Just url ) ->
                    navigation_loadUrl url

                _ ->
                    Cmd.none
            )

        GotSourcesAggregationResult result ->
            ( { model | sourcesAggregation = Just result }
            , Cmd.none
            )

        FilterAbilityChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedFilterAbility = value }
                )
                model
            , Cmd.none
            )

        FilterComponentsOperatorChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterComponentsOperator = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterResistanceChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedFilterResistance = value }
                )
                model
            , Cmd.none
            )

        FilterSpeedChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedFilterSpeed = value }
                )
                model
            , Cmd.none
            )

        FilterSpoilersChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterSpoilers = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterTraditionsOperatorChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterTraditionsOperator = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterTraitsOperatorChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterTraitsOperator = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterWeaknessChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedFilterWeakness = value }
                )
                model
            , Cmd.none
            )

        FilteredFromValueChanged key value ->
            let
                updatedModel : Model
                updatedModel =
                    updateCurrentSearchModel
                        (\searchModel ->
                            { searchModel
                                | filteredFromValues =
                                    if String.isEmpty value then
                                        Dict.remove key searchModel.filteredFromValues

                                    else
                                        Dict.insert key value searchModel.filteredFromValues
                            }
                        )
                        model
            in
            ( updatedModel
            , updateUrlWithSearchParams updatedModel
            )

        FilteredToValueChanged key value ->
            let
                updatedModel : Model
                updatedModel =
                    updateCurrentSearchModel
                        (\searchModel ->
                            { searchModel
                                | filteredToValues =
                                    if String.isEmpty value then
                                        Dict.remove key searchModel.filteredToValues

                                    else
                                        Dict.insert key value searchModel.filteredToValues
                            }
                        )
                        model
            in
            ( updatedModel
            , updateUrlWithSearchParams updatedModel
            )

        GroupField1Changed field ->
            updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | groupField1 = field }
                )
                model
                |> updateWithNewGroupFields

        GroupField2Changed field ->
            updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | groupField2 = field
                        , groupField3 =
                            if field == Nothing then
                                Nothing

                            else
                                searchModel.groupField3
                    }
                )
                model
                |> updateWithNewGroupFields

        GroupField3Changed field ->
            updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | groupField3 = field }
                )
                model
                |> updateWithNewGroupFields

        GroupTraitsChanged enabled ->
            ( { model | groupTraits = enabled }
            , saveToLocalStorage
                "group-traits"
                (if enabled then "1" else "0")
            )

        GroupedDisplayChanged value ->
            ( { model | groupedDisplay = value }
            , saveToLocalStorage
                "grouped-display"
                (case value of
                    Show ->
                        "show"

                    Dim ->
                        "dim"

                    Hide ->
                        "hide"
                )
            )

        GroupedLinkLayoutChanged value ->
            ( { model | groupedLinkLayout = value }
            , saveToLocalStorage
                "grouped-link-layout"
                (case value of
                    Horizontal ->
                        "horizontal"

                    Vertical ->
                        "vertical"

                    VerticalWithSummary ->
                        "vertical-with-summary"
                )
            )

        GroupedShowPfsIconChanged enabled ->
            ( { model | groupedShowPfs = enabled }
            , saveToLocalStorage
                "grouped-show-pfs"
                (if enabled then "1" else "0")
            )

        GroupedSortChanged value ->
            ( { model | groupedSort = value }
            , saveToLocalStorage
                "grouped-sort"
                (case value of
                    Alphanum ->
                        "alphanum"

                    CountLoaded ->
                        "count-loaded"

                    CountTotal ->
                        "count-total"
                )
            )

        HandFilterAdded subcategory ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredHands = toggleBoolDict subcategory searchModel.filteredHands }
                )
                model
                |> updateUrlWithSearchParams
            )

        HandFilterRemoved subcategory ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredHands = Dict.remove subcategory searchModel.filteredHands }
                )
                model
                |> updateUrlWithSearchParams
            )

        ItemCategoryFilterAdded category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    let
                        newFilteredItemCategories : Dict String Bool
                        newFilteredItemCategories =
                            toggleBoolDict category searchModel.filteredItemCategories
                    in
                    { searchModel
                        | filteredItemCategories = newFilteredItemCategories
                        , filteredItemSubcategories =
                            case Dict.get category newFilteredItemCategories of
                                Just True ->
                                    Dict.filter
                                        (\source _ ->
                                            searchModel.aggregations
                                                |> Maybe.andThen Result.toMaybe
                                                |> Maybe.map .itemSubcategories
                                                |> Maybe.withDefault []
                                                |> List.filter
                                                    (\sc ->
                                                        List.member
                                                            sc.category
                                                            (boolDictIncluded newFilteredItemCategories)
                                                    )
                                                |> List.map .name
                                                |> List.member source
                                        )
                                        searchModel.filteredItemSubcategories

                                Just False ->
                                    Dict.filter
                                        (\source _ ->
                                            searchModel.aggregations
                                                |> Maybe.andThen Result.toMaybe
                                                |> Maybe.map .itemSubcategories
                                                |> Maybe.andThen (List.Extra.find (.name >> ((==) source)))
                                                |> Maybe.map .category
                                                |> Maybe.map String.toLower
                                                |> (/=) (Just category)
                                        )
                                        searchModel.filteredItemSubcategories

                                Nothing ->
                                    searchModel.filteredItemSubcategories
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        ItemCategoryFilterRemoved category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredItemCategories = Dict.remove category searchModel.filteredItemCategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        ItemSubcategoryFilterAdded subcategory ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredItemSubcategories = toggleBoolDict subcategory searchModel.filteredItemSubcategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        ItemSubcategoryFilterRemoved subcategory ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredItemSubcategories = Dict.remove subcategory searchModel.filteredItemSubcategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        LimitTableWidthChanged value ->
            ( { model | limitTableWidth = value }
            , saveToLocalStorage
                "limit-table-width"
                (if value then "1" else "0")
            )

        LoadMorePressed size ->
            ( model
            , Cmd.none
            )
                |> searchWithCurrentQuery (LoadMore size)

        LoadPageDefaultDisplayPressed ->
            ( model
            , updateUrlWithSearchParams
                (updateModelFromDisplayParams
                    (Dict.get model.pageId model.pageDefaultDisplays
                        |> Maybe.withDefault Dict.empty
                    )
                    model
                )
            )

        LocalStorageValueReceived json ->
            ( case
                ( Decode.decodeValue (Decode.field "key" Decode.string) json
                , Decode.decodeValue (Decode.field "value" Decode.string) json
                )
              of
                ( Ok key, Ok value ) ->
                    updateModelFromLocalStorage ( key, value ) model

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

        OpenInNewTabChanged value ->
            ( { model | openInNewTab = value }
            , saveToLocalStorage
                "open-in-new-tab"
                (if value then "1" else "0")
            )

        PageSizeChanged size ->
            ( { model | pageSize = size }
            , saveToLocalStorage
                "page-size"
                (String.fromInt size)
            )
                |> searchWithCurrentQuery LoadNewForce

        PfsFilterAdded pfs ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredPfs = toggleBoolDict pfs searchModel.filteredPfs }
                )
                model
                |> updateUrlWithSearchParams
            )

        PfsFilterRemoved pfs ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredPfs = Dict.remove pfs searchModel.filteredPfs }
                )
                model
                |> updateUrlWithSearchParams
            )

        QueryChanged str ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | debounce = searchModel.debounce + 1
                        , query = str
                    }
                )
                model
            , Process.sleep 250
                |> Task.perform (\_ -> DebouncePassed (model.searchModel.debounce + 1))
            )

        QueryTypeSelected queryType ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | queryType = queryType }
                )
                model
                |> updateUrlWithSearchParams
            )

        RarityFilterAdded rarity ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredRarities = toggleBoolDict rarity searchModel.filteredRarities }
                )
                model
                |> updateUrlWithSearchParams
            )

        RarityFilterRemoved rarity ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredRarities = Dict.remove rarity searchModel.filteredRarities }
                )
                model
                |> updateUrlWithSearchParams
            )

        ReloadFilterAdded reload ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredReloads = toggleBoolDict reload searchModel.filteredReloads }
                )
                model
                |> updateUrlWithSearchParams
            )

        ReloadFilterRemoved reload ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredReloads = Dict.remove reload searchModel.filteredReloads }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSortsPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sort = [] }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllAbilityFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAbilities = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllActionsFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredActions = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllAlignmentFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAlignments = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllComponentFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredComponents = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllCreatureFamilyFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredCreatureFamilies = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllHandFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredHands = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllItemCategoryFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredItemCategories = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllItemSubcategoryFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredItemSubcategories = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllPfsFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredPfs = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllRarityFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredRarities = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllReloadFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredReloads = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSavingThrowFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSavingThrows = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSchoolFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSchools = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSizeFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSizes = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSkillFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSkills = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSourceCategoryFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSourceCategories = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllSourceFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSources = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllStrongestSaveFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredStrongestSaves = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllTraditionFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraditions = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllTraitFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraits = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllTypeFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTypes = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllValueFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredFromValues = Dict.empty
                        , filteredToValues = Dict.empty
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllWeakestSaveFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeakestSaves = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllWeaponCategoryFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponCategories = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllWeaponGroupFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponGroups = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllWeaponTypeFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponTypes = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        ResultDisplayChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | resultDisplay = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        SaveColumnConfigurationPressed ->
            ( { model
                | savedColumnConfigurations =
                    if String.isEmpty model.savedColumnConfigurationName then
                        model.savedColumnConfigurations

                    else
                        Dict.insert
                            model.savedColumnConfigurationName
                            model.searchModel.tableColumns
                            model.savedColumnConfigurations
              }
            , Cmd.none
            )
                |> saveColumnConfigurationsToLocalStorage

        SavePageDefaultDisplayPressed ->
            let
                newDefaults =
                    Dict.insert
                        model.pageId
                        (Dict.fromList (getDisplayParamsList model model.searchModel))
                        model.pageDefaultDisplays
            in
            ( { model | pageDefaultDisplays = newDefaults }
            , saveToLocalStorage
                "page-default-displays"
                (Encode.dict
                    identity
                    (Encode.dict
                        identity
                        Encode.string
                    )
                    newDefaults
                    |> Encode.encode 0
                )
            )

        SavedColumnConfigurationNameChanged value ->
            ( { model | savedColumnConfigurationName = value }
            , Cmd.none
            )

        SavedColumnConfigurationSelected name ->
            ( { model | savedColumnConfigurationName = name }
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | tableColumns =
                            Dict.get name model.savedColumnConfigurations
                                |> Maybe.withDefault searchModel.tableColumns
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        SavingThrowFilterAdded savingThrow ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSavingThrows = toggleBoolDict savingThrow searchModel.filteredSavingThrows }
                )
                model
                |> updateUrlWithSearchParams
            )

        SavingThrowFilterRemoved savingThrow ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSavingThrows = Dict.remove savingThrow searchModel.filteredSavingThrows }
                )
                model
                |> updateUrlWithSearchParams
            )

        SchoolFilterAdded school ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSchools = toggleBoolDict school searchModel.filteredSchools }
                )
                model
                |> updateUrlWithSearchParams
            )

        SchoolFilterRemoved school ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSchools = Dict.remove school searchModel.filteredSchools }
                )
                model
                |> updateUrlWithSearchParams
            )

        ScrollToTopPressed  ->
            ( model
            , Task.perform (\_ -> NoOp) (Browser.Dom.setViewport 0 0)
            )

        SearchCreatureFamiliesChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchCreatureFamilies = value }
                )
                model
            , Cmd.none
            )

        SearchItemCategoriesChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchItemCategories = value }
                )
                model
            , Cmd.none
            )

        SearchItemSubcategoriesChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchItemSubcategories = value }
                )
                model
            , Cmd.none
            )

        SearchSourcesChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchSources = value }
                )
                model
            , Cmd.none
            )

        SearchTraitsChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchTraits = value }
                )
                model
            , Cmd.none
            )

        SearchTypesChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchTypes = value }
                )
                model
            , Cmd.none
            )

        ShowAdditionalInfoChanged value ->
            ( { model | showResultAdditionalInfo = value }
            , saveToLocalStorage
                "show-additional-info"
                (if value then "1" else "0")
            )

        ShowAllFilters ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | showAllFilters = True }
                )
                model
            , Cmd.none
            )

        ShowFilterBox id show ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | visibleFilterBoxes =
                            if show then
                                Set.insert id searchModel.visibleFilterBoxes

                            else
                                Set.remove id searchModel.visibleFilterBoxes
                    }
                )
                model
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

        ShowSpoilersChanged value ->
            ( { model | showResultSpoilers = value }
            , saveToLocalStorage
                "show-spoilers"
                (if value then "1" else "0")
            )

        ShowSummaryChanged value ->
            ( { model | showResultSummary = value }
            , saveToLocalStorage
                "show-summary"
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
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSizes = toggleBoolDict size searchModel.filteredSizes }
                )
                model
                |> updateUrlWithSearchParams
            )

        SizeFilterRemoved size ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSizes = Dict.remove size searchModel.filteredSizes }
                )
                model
                |> updateUrlWithSearchParams
            )

        SkillFilterAdded skill ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSkills = toggleBoolDict skill searchModel.filteredSkills }
                )
                model
                |> updateUrlWithSearchParams
            )

        SkillFilterRemoved skill ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSkills = Dict.remove skill searchModel.filteredSkills }
                )
                model
                |> updateUrlWithSearchParams
            )

        SortAbilityChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedSortAbility = value }
                )
                model
            , Cmd.none
            )

        SortAdded field dir ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sortHasChanged = True }
                )
                model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | sort =
                            if List.any (Tuple.first >> (==) field) searchModel.sort then
                                List.Extra.updateIf
                                    (Tuple.first >> (==) field)
                                    (Tuple.mapSecond (\_ -> dir))
                                    searchModel.sort

                            else
                                List.append searchModel.sort [ ( field, dir ) ]
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        SortOrderChanged oldIndex newIndex ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sortHasChanged = True }
                )
                model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sort = List.Extra.swapAt oldIndex newIndex searchModel.sort }
                )
                model
                |> updateUrlWithSearchParams
            )

        SortRemoved field ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sortHasChanged = True }
                )
                model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sort = List.filter (Tuple.first >> (/=) field) searchModel.sort }
                )
                model
                |> updateUrlWithSearchParams
            )

        SortResistanceChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedSortResistance = value }
                )
                model
            , Cmd.none
            )

        SortSetChosen fields ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sortHasChanged = True }
                )
                model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sort = fields }
                )
                model
                |> updateUrlWithSearchParams
            )

        SortSpeedChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedSortSpeed = value }
                )
                model
            , Cmd.none
            )

        SortToggled field ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | sortHasChanged = True }
                )
                model
            , updateCurrentSearchModel
                (\searchModel ->
                    let
                        sort : List ( String, SortDir )
                        sort =
                            if searchModel.sortHasChanged then
                                searchModel.sort

                            else
                                []
                    in
                    { searchModel
                        | sort =
                            case List.Extra.find (Tuple.first >> (==) field) sort of
                                Just ( _, Asc ) ->
                                    sort
                                        |> List.filter (Tuple.first >> (/=) field)
                                        |> (\list -> List.append list [ ( field, Desc ) ])

                                Just ( _, Desc ) ->
                                    sort
                                        |> List.filter (Tuple.first >> (/=) field)

                                Nothing ->
                                    List.append sort [ ( field, Asc ) ]
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        SortWeaknessChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedSortWeakness = value }
                )
                model
            , Cmd.none
            )

        SourceCategoryFilterAdded category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    let
                        newFilteredSourceCategories : Dict String Bool
                        newFilteredSourceCategories =
                            toggleBoolDict category searchModel.filteredSourceCategories
                    in
                    { searchModel
                        | filteredSourceCategories = newFilteredSourceCategories
                        , filteredSources =
                            case Dict.get category newFilteredSourceCategories of
                                Just True ->
                                    Dict.filter
                                        (\source _ ->
                                            model.sourcesAggregation
                                                |> Maybe.andThen Result.toMaybe
                                                |> Maybe.withDefault []
                                                |> List.filter
                                                    (\s ->
                                                        List.member
                                                            s.category
                                                            (boolDictIncluded newFilteredSourceCategories)
                                                    )
                                                |> List.map .name
                                                |> List.member source
                                        )
                                        searchModel.filteredSources

                                Just False ->
                                    Dict.filter
                                        (\source _ ->
                                            model.sourcesAggregation
                                                |> Maybe.andThen Result.toMaybe
                                                |> Maybe.andThen (List.Extra.find (.name >> ((==) source)))
                                                |> Maybe.map .category
                                                |> Maybe.map String.toLower
                                                |> (/=) (Just category)
                                        )
                                        searchModel.filteredSources

                                Nothing ->
                                    searchModel.filteredSources
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        SourceCategoryFilterRemoved category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSourceCategories = Dict.remove category searchModel.filteredSourceCategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        SourceFilterAdded book ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSources = toggleBoolDict book searchModel.filteredSources }
                )
                model
                |> updateUrlWithSearchParams
            )

        SourceFilterRemoved book ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredSources = Dict.remove book searchModel.filteredSources }
                )
                model
                |> updateUrlWithSearchParams
            )

        StrongestSaveFilterAdded strongestSave ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredStrongestSaves = toggleBoolDict strongestSave searchModel.filteredStrongestSaves }
                )
                model
                |> updateUrlWithSearchParams
            )

        StrongestSaveFilterRemoved strongestSave ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredStrongestSaves = Dict.remove strongestSave searchModel.filteredStrongestSaves }
                )
                model
                |> updateUrlWithSearchParams
            )

        TableColumnAdded column ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | tableColumns = List.append searchModel.tableColumns [ column ] }
                )
                model
                |> updateUrlWithSearchParams
            )

        TableColumnMoved oldIndex newIndex ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | tableColumns = List.Extra.swapAt oldIndex newIndex searchModel.tableColumns }
                )
                model
                |> updateUrlWithSearchParams
            )

        TableColumnRemoved column ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | tableColumns = List.filter ((/=) column) searchModel.tableColumns }
                )
                model
                |> updateUrlWithSearchParams
            )

        TableColumnSetChosen columns ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | tableColumns = columns }
                )
                model
                |> updateUrlWithSearchParams
            )

        ThemeSelected theme ->
            ( { model | theme = theme }
            , saveToLocalStorage
                "theme"
                (case theme of
                    Blackbird ->
                        "jonny"

                    Dark ->
                        "dark"

                    Dead ->
                        "dead"

                    Light ->
                        "light"

                    Orc ->
                        "orc"

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
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraditions = toggleBoolDict tradition searchModel.filteredTraditions }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraditionFilterRemoved tradition ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraditions = Dict.remove tradition searchModel.filteredTraditions }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraitGroupDeselectPressed traits ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredTraits =
                            List.foldl
                                (\trait ->
                                    Dict.remove trait
                                )
                                searchModel.filteredTraits
                                traits
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraitGroupExcludePressed traits ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredTraits =
                            List.foldl
                                (\trait ->
                                    Dict.insert trait False
                                )
                                searchModel.filteredTraits
                                traits
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraitGroupIncludePressed traits ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredTraits =
                            List.foldl
                                (\trait ->
                                    Dict.insert trait True
                                )
                                searchModel.filteredTraits
                                traits
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraitFilterAdded trait ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraits = toggleBoolDict trait searchModel.filteredTraits }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraitFilterRemoved trait ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraits = Dict.remove trait searchModel.filteredTraits }
                )
                model
                |> updateUrlWithSearchParams
            )

        TypeFilterAdded type_ ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTypes = toggleBoolDict type_ searchModel.filteredTypes }
                )
                model
                |> updateUrlWithSearchParams
            )

        TypeFilterRemoved type_ ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTypes = Dict.remove type_ searchModel.filteredTypes }
                )
                model
                |> updateUrlWithSearchParams
            )

        UrlChanged urlString ->
            let
                url : Url
                url =
                    parseUrl urlString
            in
            ( { model | url = url }
                |> updateModelFromUrl url
            , Cmd.none
            )
                |> searchWithCurrentQuery LoadNew
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

        WeakestSaveFilterAdded weakestSave ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeakestSaves = toggleBoolDict weakestSave searchModel.filteredWeakestSaves }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeakestSaveFilterRemoved weakestSave ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeakestSaves = Dict.remove weakestSave searchModel.filteredWeakestSaves }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeaponCategoryFilterAdded category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponCategories = toggleBoolDict category searchModel.filteredWeaponCategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeaponCategoryFilterRemoved category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponCategories = Dict.remove category searchModel.filteredWeaponCategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeaponGroupFilterAdded group ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponGroups = toggleBoolDict group searchModel.filteredWeaponGroups }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeaponGroupFilterRemoved group ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponGroups = Dict.remove group searchModel.filteredWeaponGroups }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeaponTypeFilterAdded type_ ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponTypes = toggleBoolDict type_ searchModel.filteredWeaponTypes }
                )
                model
                |> updateUrlWithSearchParams
            )

        WeaponTypeFilterRemoved type_ ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredWeaponTypes = Dict.remove type_ searchModel.filteredWeaponTypes }
                )
                model
                |> updateUrlWithSearchParams
            )


updateCurrentSearchModel : (SearchModel -> SearchModel) -> Model -> Model
updateCurrentSearchModel updateFun model =
    { model | searchModel = updateFun model.searchModel }


updateModelFromLocalStorage : ( String, String ) -> Model -> Model
updateModelFromLocalStorage ( key, value ) model =
    case key of
        "auto-query-type" ->
            case value of
                "1" ->
                    { model | autoQueryType = True }

                "0" ->
                    { model | autoQueryType = False }

                _ ->
                    model

        "column-configurations" ->
            case Decode.decodeString (Decode.dict (Decode.list Decode.string)) value of
                Ok configurations ->
                    { model | savedColumnConfigurations = configurations }

                Err _ ->
                    model

        "grouped-display" ->
            case value of
                "show" ->
                    { model | groupedDisplay = Show }

                "dim" ->
                    { model | groupedDisplay = Dim }

                "hide" ->
                    { model | groupedDisplay = Hide }

                _ ->
                    model

        "grouped-link-layout" ->
            case value of
                "horizontal" ->
                    { model | groupedLinkLayout = Horizontal }

                "vertical" ->
                    { model | groupedLinkLayout = Vertical }

                "vertical-with-summary" ->
                    { model | groupedLinkLayout = VerticalWithSummary }

                _ ->
                    model

        "grouped-show-pfs" ->
            case value of
                "1" ->
                    { model | groupedShowPfs = True }

                "0" ->
                    { model | groupedShowPfs = False }

                _ ->
                    model

        "grouped-sort" ->
            case value of
                "alphanum" ->
                    { model | groupedSort = Alphanum }

                "count-loaded" ->
                    { model | groupedSort = CountLoaded }

                "count-total" ->
                    { model | groupedSort = CountTotal }

                _ ->
                    model

        "group-traits" ->
            case value of
                "1" ->
                    { model | groupTraits = True }

                "0" ->
                    { model | groupTraits = False }

                _ ->
                    model

        "limit-table-width" ->
            case value of
                "1" ->
                    { model | limitTableWidth = True }

                "0" ->
                    { model | limitTableWidth = False }

                _ ->
                    model

        "open-in-new-tab" ->
            case value of
                "1" ->
                    { model | openInNewTab = True }

                "0" ->
                    { model | openInNewTab = False }

                _ ->
                    model

        "page-default-displays" ->
            case Decode.decodeString (Decode.dict (Decode.dict Decode.string)) value of
                Ok configurations ->
                    { model | pageDefaultDisplays = configurations }

                Err _ ->
                    model

        "page-size" ->
            case String.toInt value of
                Just size ->
                    if List.member size Data.pageSizes then
                        { model | pageSize = size }

                    else
                        model

                Nothing ->
                    model

        "show-additional-info" ->
            case value of
                "1" ->
                    { model | showResultAdditionalInfo = True }

                "0" ->
                    { model | showResultAdditionalInfo = False }

                _ ->
                    model

        "show-spoilers" ->
            case value of
                "1" ->
                    { model | showResultSpoilers = True }

                "0" ->
                    { model | showResultSpoilers = False }

                _ ->
                    model

        "show-summary" ->
            case value of
                "1" ->
                    { model | showResultSummary = True }

                "0" ->
                    { model | showResultSummary = False }

                _ ->
                    model

        "show-traits" ->
            case value of
                "1" ->
                    { model | showResultTraits = True }

                "0" ->
                    { model | showResultTraits = False }

                _ ->
                    model

        "theme" ->
            case value of
                "dark" ->
                    { model | theme = Dark }

                "light" ->
                    { model | theme = Light }

                "book-print" ->
                    { model | theme = Paper }

                "paper" ->
                    { model | theme = Paper }

                "extra-contrast" ->
                    { model | theme = ExtraContrast }

                "contrast-dark" ->
                    { model | theme = ExtraContrast }

                "dead" ->
                    { model | theme = Dead }

                "lavender" ->
                    { model | theme = Lavender }

                "lavander" ->
                    { model | theme = Lavender }

                "blackbird" ->
                    { model | theme = Blackbird }

                "jonny" ->
                    { model | theme = Blackbird }

                "orc" ->
                    { model | theme = Orc }

                _ ->
                    model
        _ ->
            model


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


saveToLocalStorage : String -> String -> Cmd msg
saveToLocalStorage key value =
    localStorage_set
        (Encode.object
            [ ( "key", Encode.string key )
            , ( "value", Encode.string value )
            ]
        )


saveColumnConfigurationsToLocalStorage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
saveColumnConfigurationsToLocalStorage ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , saveToLocalStorage
            "column-configurations"
            (Encode.dict identity (Encode.list Encode.string) model.savedColumnConfigurations
                |> Encode.encode 0
            )
        ]
    )


updateUrlWithSearchParams : Model -> Cmd Msg
updateUrlWithSearchParams ({ searchModel, url } as model) =
    { url
        | query =
            [ ( "q", searchModel.query )
            , ( "type"
              , if model.autoQueryType then
                    if queryCouldBeComplex searchModel.query then
                        "eqs"

                    else
                        ""

                else
                    case searchModel.queryType of
                        Standard ->
                            ""

                        ElasticsearchQueryString ->
                            "eqs"
              )
            , ( "include-traits"
              , boolDictIncluded searchModel.filteredTraits
                    |> String.join ";"
              )
            , ( "exclude-traits"
              , boolDictExcluded searchModel.filteredTraits
                    |> String.join ";"
              )
            , ( "traits-operator"
              , if searchModel.filterTraitsOperator then
                  ""

                else
                  "or"
              )
            , ( "include-types"
              , boolDictIncluded searchModel.filteredTypes
                    |> String.join ";"
              )
            , ( "exclude-types"
              , boolDictExcluded searchModel.filteredTypes
                    |> String.join ";"
              )
            , ( "include-abilities"
              , boolDictIncluded searchModel.filteredAbilities
                    |> String.join ";"
              )
            , ( "exclude-abilities"
              , boolDictExcluded searchModel.filteredAbilities
                    |> String.join ";"
              )
            , ( "include-actions"
              , boolDictIncluded searchModel.filteredActions
                    |> String.join ";"
              )
            , ( "exclude-actions"
              , boolDictExcluded searchModel.filteredActions
                    |> String.join ";"
              )
            , ( "include-alignments"
              , boolDictIncluded searchModel.filteredAlignments
                    |> String.join ";"
              )
            , ( "exclude-alignments"
              , boolDictExcluded searchModel.filteredAlignments
                    |> String.join ";"
              )
            , ( "include-components"
              , boolDictIncluded searchModel.filteredComponents
                    |> String.join ";"
              )
            , ( "exclude-components"
              , boolDictExcluded searchModel.filteredComponents
                    |> String.join ";"
              )
            , ( "components-operator"
              , if searchModel.filterComponentsOperator then
                  ""

                else
                  "or"
              )
            , ( "include-creature-families"
              , boolDictIncluded searchModel.filteredCreatureFamilies
                    |> String.join ";"
              )
            , ( "exclude-creature-families"
              , boolDictExcluded searchModel.filteredCreatureFamilies
                    |> String.join ";"
              )
            , ( "include-hands"
              , boolDictIncluded searchModel.filteredHands
                    |> String.join ";"
              )
            , ( "exclude-hands"
              , boolDictExcluded searchModel.filteredHands
                    |> String.join ";"
              )
            , ( "include-item-categories"
              , boolDictIncluded searchModel.filteredItemCategories
                    |> String.join ";"
              )
            , ( "exclude-item-categories"
              , boolDictExcluded searchModel.filteredItemCategories
                    |> String.join ";"
              )
            , ( "include-item-subcategories"
              , boolDictIncluded searchModel.filteredItemSubcategories
                    |> String.join ";"
              )
            , ( "exclude-item-subcategories"
              , boolDictExcluded searchModel.filteredItemSubcategories
                    |> String.join ";"
              )
            , ( "include-pfs"
              , boolDictIncluded searchModel.filteredPfs
                    |> String.join ";"
              )
            , ( "exclude-pfs"
              , boolDictExcluded searchModel.filteredPfs
                    |> String.join ";"
              )
            , ( "include-rarities"
              , boolDictIncluded searchModel.filteredRarities
                    |> String.join ";"
              )
            , ( "exclude-rarities"
              , boolDictExcluded searchModel.filteredRarities
                    |> String.join ";"
              )
            , ( "include-reloads"
              , boolDictIncluded searchModel.filteredReloads
                    |> String.join ";"
              )
            , ( "exclude-reloads"
              , boolDictExcluded searchModel.filteredReloads
                    |> String.join ";"
              )
            , ( "include-saving-throws"
              , boolDictIncluded searchModel.filteredSavingThrows
                    |> String.join ";"
              )
            , ( "exclude-saving-throws"
              , boolDictExcluded searchModel.filteredSavingThrows
                    |> String.join ";"
              )
            , ( "include-schools"
              , boolDictIncluded searchModel.filteredSchools
                    |> String.join ";"
              )
            , ( "exclude-schools"
              , boolDictExcluded searchModel.filteredSchools
                    |> String.join ";"
              )
            , ( "include-sizes"
              , boolDictIncluded searchModel.filteredSizes
                    |> String.join ";"
              )
            , ( "exclude-sizes"
              , boolDictExcluded searchModel.filteredSizes
                    |> String.join ";"
              )
            , ( "include-skills"
              , boolDictIncluded searchModel.filteredSkills
                    |> String.join ";"
              )
            , ( "exclude-skills"
              , boolDictExcluded searchModel.filteredSkills
                    |> String.join ";"
              )
            , ( "include-sources"
              , boolDictIncluded searchModel.filteredSources
                    |> String.join ";"
              )
            , ( "exclude-sources"
              , boolDictExcluded searchModel.filteredSources
                    |> String.join ";"
              )
            , ( "include-source-categories"
              , boolDictIncluded searchModel.filteredSourceCategories
                    |> String.join ";"
              )
            , ( "exclude-source-categories"
              , boolDictExcluded searchModel.filteredSourceCategories
                    |> String.join ";"
              )
            , ( "include-strongest-saves"
              , boolDictIncluded searchModel.filteredStrongestSaves
                    |> String.join ";"
              )
            , ( "exclude-strongest-saves"
              , boolDictExcluded searchModel.filteredStrongestSaves
                    |> String.join ";"
              )
            , ( "include-traditions"
              , boolDictIncluded searchModel.filteredTraditions
                    |> String.join ";"
              )
            , ( "exclude-traditions"
              , boolDictExcluded searchModel.filteredTraditions
                    |> String.join ";"
              )
            , ( "traditions-operator"
              , if searchModel.filterTraditionsOperator then
                    ""

                else
                    "or"
              )
            , ( "include-weakest-saves"
              , boolDictIncluded searchModel.filteredWeakestSaves
                    |> String.join ";"
              )
            , ( "exclude-weakest-saves"
              , boolDictExcluded searchModel.filteredWeakestSaves
                    |> String.join ";"
              )
            , ( "include-weapon-categories"
              , boolDictIncluded searchModel.filteredWeaponCategories
                    |> String.join ";"
              )
            , ( "exclude-weapon-categories"
              , boolDictExcluded searchModel.filteredWeaponCategories
                    |> String.join ";"
              )
            , ( "include-weapon-groups"
              , boolDictIncluded searchModel.filteredWeaponGroups
                    |> String.join ";"
              )
            , ( "exclude-weapon-groups"
              , boolDictExcluded searchModel.filteredWeaponGroups
                    |> String.join ";"
              )
            , ( "include-weapon-types"
              , boolDictIncluded searchModel.filteredWeaponTypes
                    |> String.join ";"
              )
            , ( "exclude-weapon-types"
              , boolDictExcluded searchModel.filteredWeaponTypes
                    |> String.join ";"
              )
            , ( "values-from"
              , searchModel.filteredFromValues
                    |> Dict.toList
                    |> List.map (\( field, value ) -> field ++ ":" ++ value)
                    |> String.join ";"
              )
            , ( "values-to"
              , searchModel.filteredToValues
                    |> Dict.toList
                    |> List.map (\( field, value ) -> field ++ ":" ++ value)
                    |> String.join ";"
              )
            , ( "spoilers"
              , if searchModel.filterSpoilers then
                    "hide"

                else
                    ""
              )
            , ( "sort"
              , searchModel.sort
                    |> List.map
                        (\( field, dir ) ->
                            field ++ "-" ++ sortDirToString dir
                        )
                    |> String.join ","
              )
            ]
                |> List.append (Dict.toList model.fixedParams)
                |> \list -> List.append list (getDisplayParamsList model searchModel)
                |> List.filter (Tuple.second >> String.isEmpty >> not)
                |> List.map (\(key, val) -> Url.Builder.string key val)
                |> Url.Builder.toQuery
                |> String.dropLeft 1
                |> String.Extra.nonEmpty
    }
        |> Url.toString
        |> navigation_pushUrl


getDisplayParamsList : Model -> SearchModel ->  List ( String, String )
getDisplayParamsList model searchModel =
    [ ( "display"
      , case searchModel.resultDisplay of
            Grouped ->
                "grouped"

            List ->
                "list"

            Table ->
                "table"
      )
    , ( "columns"
      , if searchModel.resultDisplay == Table then
            String.join "," searchModel.tableColumns

        else
            ""
      )
    , ( "group-field-1"
      , if searchModel.resultDisplay == Grouped then
            searchModel.groupField1

        else
            ""
      )
    , ( "group-field-2"
      , if searchModel.resultDisplay == Grouped then
            Maybe.withDefault "" searchModel.groupField2

        else
            ""
      )
    , ( "group-field-3"
      , if searchModel.resultDisplay == Grouped then
            Maybe.withDefault "" searchModel.groupField3

        else
            ""
      )
    ]
        |> List.filter (Tuple.second >> String.isEmpty >> not)


searchFields : List String
searchFields =
    [ "name"
    , "text^0.1"
    , "trait_raw"
    , "type"
    ]


buildSearchBody : Model -> SearchModel -> LoadType -> Encode.Value
buildSearchBody model searchModel load =
    encodeObjectMaybe
        [ Just
            ( "query"
            , Encode.object
                [ ( "function_score"
                  , Encode.object
                        [ buildSearchQuery model searchModel
                        , ( "boost_mode", Encode.string "multiply" )
                        , ( "functions"
                          , Encode.list Encode.object
                                [ [ ( "filter"
                                    , Encode.object
                                        [ ( "terms"
                                          , Encode.object
                                                [ ( "type"
                                                  , Encode.list Encode.string
                                                        [ "Ancestry", "Class" ]
                                                  )
                                                ]
                                          )
                                        ]
                                    )
                                  , ( "weight", Encode.float 1.1 )
                                  ]
                                , [ ( "filter"
                                    , Encode.object
                                        [ ( "terms"
                                          , Encode.object
                                                [ ( "type"
                                                  , Encode.list Encode.string
                                                        [ "Trait" ]
                                                  )
                                                ]
                                          )
                                        ]
                                    )
                                  , ( "weight", Encode.float 1.05 )
                                  ]
                                ]
                          )
                        ]
                )
              ]
            )
        , Just
            ( "size"
            , Encode.int
                (case load of
                    LoadMore size ->
                        min 10000 size

                    _ ->
                        model.pageSize
                )
            )
        , ( "sort"
          , Encode.list identity
                (if List.isEmpty (getValidSortFields searchModel.sort) then
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
                            (getValidSortFields searchModel.sort)
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
            |> Maybe.map .hits
            |> Maybe.andThen List.Extra.last
            |> Maybe.map .sort
            |> Maybe.map (Tuple.pair "search_after")
        , if load == LoadNew || load == LoadNewForce then
            Just (buildGroupAggs searchModel)

          else
            Nothing
        ]


buildSearchGroupAggregationsBody : Model -> SearchModel -> Encode.Value
buildSearchGroupAggregationsBody model searchModel =
    Encode.object
        [ buildSearchQuery model searchModel
        , buildGroupAggs searchModel
        , ( "size", Encode.int 0 )
        ]


buildSearchQuery : Model -> SearchModel -> ( String, Encode.Value )
buildSearchQuery model searchModel =
    let
        filters : List (List ( String, Encode.Value ))
        filters =
            buildSearchFilterTerms model searchModel

        mustNots : List (List ( String, Encode.Value ))
        mustNots =
            buildSearchMustNotTerms model searchModel
    in
    ( "query"
    , Encode.object
        [ ( "bool"
          , encodeObjectMaybe
                [ if String.isEmpty searchModel.query then
                    Nothing

                  else
                    Just
                        ( "should"
                        , Encode.list Encode.object
                            (case searchModel.queryType of
                                Standard ->
                                    buildStandardQueryBody searchModel.query

                                ElasticsearchQueryString ->
                                    [ buildElasticsearchQueryStringQueryBody searchModel.query ]
                            )
                        )

                , if List.isEmpty filters then
                    Nothing

                  else
                    Just
                        ( "filter"
                        , Encode.list Encode.object filters
                        )

                , if List.isEmpty mustNots then
                    Nothing

                  else
                    Just
                        ( "must_not"
                        , Encode.list Encode.object mustNots
                        )

                , if String.isEmpty searchModel.query then
                    Nothing

                  else
                    Just ( "minimum_should_match", Encode.int 1 )
                ]
          )
        ]
    )


buildGroupAggs : SearchModel -> ( String, Encode.Value )
buildGroupAggs searchModel =
    ( "aggs"
    , encodeObjectMaybe
        [ buildCompositeAggregation
            "group1"
            True
            [ ( "field1", mapSortFieldToElastic searchModel.groupField1 )
            ]
            |> Just
        , Maybe.map
            (\field2 ->
                buildCompositeAggregation
                    "group2"
                    True
                    [ ( "field1", mapSortFieldToElastic searchModel.groupField1 )
                    , ( "field2", mapSortFieldToElastic field2 )
                    ]
            )
            searchModel.groupField2
        , Maybe.map2
            (\field2 field3 ->
                buildCompositeAggregation
                    "group3"
                    True
                    [ ( "field1", mapSortFieldToElastic searchModel.groupField1 )
                    , ( "field2", mapSortFieldToElastic field2 )
                    , ( "field3", mapSortFieldToElastic field3 )
                    ]
            )
            searchModel.groupField2
            searchModel.groupField3
        ]
    )


mapSortFieldToElastic : String -> String
mapSortFieldToElastic field =
    List.Extra.find (Tuple3.first >> (==) field) Data.sortFields
        |> Maybe.map Tuple3.second
        |> Maybe.withDefault field


getValidSortFields : List ( String, SortDir ) -> List ( String, SortDir )
getValidSortFields values =
    List.filterMap
        (\ (field, dir) ->
            case List.Extra.find (Tuple3.first >> (==) field) Data.sortFields of
                Just ( _, esField, _ ) ->
                    Just ( esField, dir )

                Nothing ->
                    Nothing
        )
        values


sortFieldToLabel : String -> String
sortFieldToLabel field =
    field
        |> String.split "."
        |> List.reverse
        |> String.join " "
        |> String.Extra.humanize


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


buildSearchFilterTerms : Model -> SearchModel -> List (List ( String, Encode.Value ))
buildSearchFilterTerms model searchModel =
    List.concat
        [ List.concatMap
            (\( field, dict, isAnd ) ->
                let
                    list : List String
                    list =
                        boolDictIncluded dict
                in
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
            (filterFields searchModel)

        , List.map
            (\( field, value ) ->
                [ ( "range"
                  , Encode.object
                        [ ( field
                          , Encode.object
                                [ ( "gte"
                                  , if field == "release_date" then
                                        Encode.string value

                                    else
                                        Encode.float (Maybe.withDefault 0 (String.toFloat value))
                                  )
                                ]
                          )
                        ]
                  )
                ]
            )
            (Dict.toList searchModel.filteredFromValues)

        , List.map
            (\( field, value ) ->
                [ ( "range"
                  , Encode.object
                        [ ( field
                          , Encode.object
                                [ ( "lte"
                                  , if field == "release_date" then
                                        Encode.string value

                                    else
                                        Encode.float (Maybe.withDefault 0 (String.toFloat value))
                                  )
                                ]
                          )
                        ]
                  )
                ]
            )
            (Dict.toList searchModel.filteredToValues)

        , if String.isEmpty searchModel.fixedQueryString then
            []

          else
            [ buildElasticsearchQueryStringQueryBody searchModel.fixedQueryString ]
        ]


buildSearchMustNotTerms : Model -> SearchModel -> List (List ( String, Encode.Value ))
buildSearchMustNotTerms model searchModel =
    List.concat
        [ List.concatMap
            (\( field, dict, _ ) ->
                let
                    list : List String
                    list =
                        boolDictExcluded dict
                in
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
            (filterFields searchModel)

        , List.map
            (\category ->
                [ ( "terms"
                  , Encode.object
                        [ ( "source"
                          , Encode.list Encode.string
                                (List.filterMap
                                    (\source ->
                                        if String.toLower source.category == category then
                                            Just source.name

                                        else
                                            Nothing
                                    )
                                    (model.sourcesAggregation
                                        |> Maybe.andThen Result.toMaybe
                                        |> Maybe.withDefault []
                                    )
                                )
                          )
                        ]
                  )
                ]
            )
            (boolDictExcluded searchModel.filteredSourceCategories)

        , if searchModel.filterSpoilers then
            [ ( "exists"
              , Encode.object
                    [ ( "field", Encode.string "spoilers" )
                    ]
              )
            ]
                |> List.singleton

          else
            []
        ]


buildStandardQueryBody : String -> List (List ( String, Encode.Value ))
buildStandardQueryBody queryString =
    [ [ ( "match_phrase_prefix"
        , Encode.object
            [ ( "name.sayt"
              , Encode.object
                    [ ( "query", Encode.string queryString )
                    ]
              )
            ]
        )
      ]
    , [ ( "match_phrase_prefix"
        , Encode.object
            [ ( "text.sayt"
              , Encode.object
                    [ ( "query", Encode.string queryString )
                    , ( "boost", Encode.float 0.1 )
                    ]
              )
            ]
        )
      ]
    , [ ( "term"
        , Encode.object
            [ ( "name", Encode.string queryString )
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


buildElasticsearchQueryStringQueryBody : String -> List ( String, Encode.Value )
buildElasticsearchQueryStringQueryBody queryString =
    [ ( "query_string"
      , Encode.object
            [ ( "query", Encode.string queryString )
            , ( "default_operator", Encode.string "AND" )
            , ( "fields", Encode.list Encode.string searchFields )
            ]
      )
    ]


getQueryParamsDictFromUrl : Dict String String -> Maybe (Dict String String) -> String -> Url -> Dict String String
getQueryParamsDictFromUrl fixedParams pageDefaultDisplay defaultQuery url =
    case url.query of
        Just query ->
            let
                urlDict : Dict String String
                urlDict =
                    queryToParamsDict query
                        |> Dict.filter
                            (\key _ ->
                                not (Dict.member key fixedParams)
                            )
            in
            if Dict.isEmpty urlDict then
                Dict.union
                    (Maybe.withDefault Dict.empty pageDefaultDisplay)
                    (queryToParamsDict defaultQuery)

            else
                if Dict.member "display" urlDict then
                    urlDict

                else
                    Dict.union
                        (Maybe.withDefault Dict.empty pageDefaultDisplay)
                        urlDict

        Nothing ->
            Dict.union
                (Maybe.withDefault Dict.empty pageDefaultDisplay)
                (queryToParamsDict defaultQuery)


queryToParamsDict : String -> Dict String String
queryToParamsDict query =
    query
        |> String.split "&"
        |> List.filterMap
            (\part ->
                case String.split "=" part of
                    [ key, value ] ->
                        Just ( key, Maybe.withDefault value (Url.percentDecode (String.replace "+" " " value)) )

                    _ ->
                        Nothing
            )
        |> Dict.fromList


updateModelFromUrl : Url -> Model -> Model
updateModelFromUrl url model =
    let
        params : Dict String String
        params =
            getQueryParamsDictFromUrl
                model.fixedParams
                (Dict.get model.pageId model.pageDefaultDisplays)
                model.searchModel.defaultQuery
                url
    in
    { model
        | searchModel = updateSearchModelFromParams params model model.searchModel
    }
        |> updateModelFromDisplayParams params


updateSearchModelFromParams : Dict String String -> Model -> SearchModel -> SearchModel
updateSearchModelFromParams params model searchModel =
    let
        query : String
        query =
            Dict.get "q" params
                |> Maybe.Extra.orElse (Dict.get "query" params)
                |> Maybe.withDefault ""
    in
    { searchModel
        | query = query
        , queryType =
            case Dict.get "type" params of
                Just "eqs" ->
                    ElasticsearchQueryString

                _ ->
                    if model.autoQueryType && queryCouldBeComplex query then
                        ElasticsearchQueryString

                    else
                        Standard
        , filteredAbilities = getBoolDictFromParams params ";" "abilities"
        , filteredActions = getBoolDictFromParams params ";" "actions"
        , filteredAlignments = getBoolDictFromParams params ";" "alignments"
        , filteredComponents = getBoolDictFromParams params ";" "components"
        , filteredCreatureFamilies = getBoolDictFromParams params ";" "creature-families"
        , filteredHands = getBoolDictFromParams params ";" "hands"
        , filteredItemCategories = getBoolDictFromParams params ";" "item-categories"
        , filteredItemSubcategories = getBoolDictFromParams params ";" "item-subcategories"
        , filteredPfs = getBoolDictFromParams params ";" "pfs"
        , filteredRarities = getBoolDictFromParams params ";" "rarities"
        , filteredReloads = getBoolDictFromParams params ";" "reloads"
        , filteredSavingThrows = getBoolDictFromParams params ";" "saving-throws"
        , filteredSchools = getBoolDictFromParams params ";" "schools"
        , filteredSizes = getBoolDictFromParams params ";" "sizes"
        , filteredSkills = getBoolDictFromParams params ";" "skills"
        , filteredSourceCategories = getBoolDictFromParams params ";" "source-categories"
        , filteredSources = getBoolDictFromParams params ";" "sources"
        , filteredStrongestSaves = getBoolDictFromParams params ";" "strongest-saves"
        , filteredTraditions = getBoolDictFromParams params ";" "traditions"
        , filteredTraits = getBoolDictFromParams params ";" "traits"
        , filteredTypes = getBoolDictFromParams params ";" "types"
        , filteredWeakestSaves = getBoolDictFromParams params ";" "weakest-saves"
        , filteredWeaponCategories = getBoolDictFromParams params ";" "weapon-categories"
        , filteredWeaponGroups = getBoolDictFromParams params ";" "weapon-groups"
        , filteredWeaponTypes = getBoolDictFromParams params ";" "weapon-types"
        , filterSpoilers = Dict.get "spoilers" params == Just "hide"
        , filterComponentsOperator = Dict.get "components-operator" params /= Just "or"
        , filterTraditionsOperator = Dict.get "traditions-operator" params /= Just "or"
        , filterTraitsOperator = Dict.get "traits-operator" params /= Just "or"
        , filteredFromValues =
            Dict.get "values-from" params
                |> Maybe.map (String.split ";")
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
            Dict.get "values-to" params
                |> Maybe.map (String.split ";")
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
        , sort =
            Dict.get "sort" params
                |> Maybe.map (String.split ",")
                |> Maybe.map
                    (List.filterMap
                        (\str ->
                            case String.split "-" str of
                                [ field, dir ] ->
                                    Maybe.map
                                        (\dir_ ->
                                            ( field
                                            , dir_
                                            )
                                        )
                                        (sortDirFromString dir)

                                _ ->
                                    Nothing
                        )
                    )
                |> Maybe.withDefault []
    }


updateModelFromDisplayParams : Dict String String -> Model -> Model
updateModelFromDisplayParams params model =
    { model
        | searchModel = updateSearchModelFromDisplayParams params model.searchModel
    }


updateSearchModelFromDisplayParams : Dict String String -> SearchModel -> SearchModel
updateSearchModelFromDisplayParams params searchModel =
    { searchModel
        | resultDisplay =
            case Dict.get "display" params of
                Just "grouped" ->
                    Grouped

                Just "table" ->
                    Table

                _ ->
                    List
        , tableColumns =
            if Dict.get "display" params == Just "table" then
                Dict.get "columns" params
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []

            else
                searchModel.tableColumns
        , groupField1 =
            if Dict.get "display" params == Just "grouped" then
                Dict.get "group-field-1" params
                    |> Maybe.withDefault searchModel.groupField1

            else
                searchModel.groupField1
        , groupField2 =
            if Dict.get "display" params == Just "grouped" then
                Dict.get "group-field-2" params

            else
                searchModel.groupField2
        , groupField3 =
            if Dict.get "display" params == Just "grouped" then
                Dict.get "group-field-3" params

            else
                searchModel.groupField3
    }


getBoolDictFromParams : Dict String String -> String -> String -> Dict String Bool
getBoolDictFromParams params splitOn param =
    List.append
        (Dict.get ("include-" ++ param) params
            |> Maybe.map (String.split splitOn)
            |> Maybe.withDefault []
            |> List.map (\value -> ( value, True ))
        )
        (Dict.get ("exclude-" ++ param) params
            |> Maybe.map (String.split splitOn)
            |> Maybe.withDefault []
            |> List.map (\value -> ( value, False ))
        )
        |> Dict.fromList


getQueryParam : Url -> String -> String
getQueryParam url param =
    { url | path = "" }
        |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string param))
        |> Maybe.Extra.join
        |> Maybe.withDefault ""


searchWithCurrentQuery : LoadType -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
searchWithCurrentQuery load ( model, cmd ) =
    if (Just (getSearchHash model.url) /= model.searchModel.lastSearchHash) || load /= LoadNew then
        let
            searchModel : SearchModel
            searchModel =
                model.searchModel

            newTracker : Int
            newTracker =
                case searchModel.tracker of
                    Just tracker ->
                        tracker + 1

                    Nothing ->
                        1

            newModel : Model
            newModel =
                { model
                    | searchModel =
                        { searchModel
                            | lastSearchHash = Just (getSearchHash model.url)
                            , searchResults =
                                if load /= LoadNew && load /= LoadNewForce then
                                    searchModel.searchResults

                                else
                                    []
                            , tracker = Just newTracker
                        }
                }
        in
        ( newModel
        , Cmd.batch
            [ cmd

            , case searchModel.tracker of
                Just tracker ->
                    Http.cancel ("search-" ++ String.fromInt tracker)

                Nothing ->
                    Cmd.none

            , Http.request
                { method = "POST"
                , url = model.elasticUrl ++ "/_search?track_total_hits=true"
                , headers = []
                , body = Http.jsonBody (buildSearchBody newModel newModel.searchModel load)
                , expect = Http.expectJson GotSearchResult esResultDecoder
                , timeout = Just 10000
                , tracker = Just ("search-" ++ String.fromInt newTracker)
                }
            ]
        )

    else
        ( model
        , cmd
        )


getSearchHash : Url -> String
getSearchHash url =
    url.query
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.filter
            (\s ->
                case String.split "=" s of
                    [ "columns", _ ] ->
                        False

                    [ "display", _ ] ->
                        False

                    [ "group-field-1", _ ] ->
                        False

                    [ "group-field-2", _ ] ->
                        False

                    [ "group-field-3", _ ] ->
                        False

                    [ "q", q ] ->
                        q
                            |> Url.percentDecode
                            |> Maybe.withDefault ""
                            |> String.trim
                            |> String.isEmpty
                            |> not

                    _ ->
                        True
            )
        |> String.join "&"


updateTitle : ( Model, Cmd msg ) -> ( Model, Cmd msg )
updateTitle ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , document_setTitle model.searchModel.query
        ]
    )


updateWithNewGroupFields : Model -> ( Model, Cmd Msg )
updateWithNewGroupFields model =
    ( updateCurrentSearchModel
        (\searchModel ->
            { searchModel | searchResultGroupAggs = Nothing }
        )
        model
    , Cmd.batch
        [ updateUrlWithSearchParams model
        , Http.request
            { method = "POST"
            , url = model.elasticUrl ++ "/_search"
            , headers = []
            , body = Http.jsonBody (buildSearchGroupAggregationsBody model model.searchModel)
            , expect = Http.expectJson GotGroupAggregationsResult esResultDecoder
            , timeout = Just 10000
            , tracker = Nothing
            }
        ]
    )


getAggregations : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
getAggregations ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , Http.request
            { method = "POST"
            , url = model.elasticUrl ++ "/_search"
            , headers = []
            , body = Http.jsonBody (buildAggregationsBody model.searchModel)
            , expect = Http.expectJson GotAggregationsResult aggregationsDecoder
            , timeout = Just 10000
            , tracker = Nothing
            }
        ]
    )


buildAggregationsBody : SearchModel -> Encode.Value
buildAggregationsBody searchModel =
    encodeObjectMaybe
        [ if String.isEmpty searchModel.fixedQueryString then
            Nothing

          else
            ( "query"
            , Encode.object (buildElasticsearchQueryStringQueryBody searchModel.fixedQueryString)
            )
                |> Just
        , ( "aggs"
          , Encode.object
                (List.append
                    (List.map
                        buildTermsAggregation
                        [ "actions.keyword"
                        , "creature_family"
                        , "item_category"
                        , "hands.keyword"
                        , "reload_raw.keyword"
                        , "source"
                        , "trait"
                        , "type"
                        , "weapon_group"
                        ]
                    )
                    [ buildCompositeAggregation
                        "item_subcategory"
                        False
                        [ ( "category", "item_category" )
                        , ( "name", "item_subcategory" )
                        ]
                    , buildCompositeAggregation
                        "trait_group"
                        False
                        [ ( "group", "trait_group" )
                        , ( "trait", "name.keyword" )
                        ]
                    ]
                )
          )
            |> Just
        , ( "size", Encode.int 0 )
            |> Just
        ]


buildTermsAggregation : String -> ( String, Encode.Value )
buildTermsAggregation field =
    ( field
    , Encode.object
        [ ( "terms"
          , Encode.object
                [ ( "field", Encode.string field)
                , ( "size", Encode.int 10000 )
                ]
          )
        ]
    )


buildCompositeAggregation : String -> Bool -> List ( String, String ) -> ( String, Encode.Value )
buildCompositeAggregation name missing sources =
    ( name
    , Encode.object
        [ ( "composite"
          , Encode.object
                [ ( "sources"
                  , Encode.list Encode.object (List.map (buildCompositeTermsSource missing) sources)
                  )
                , ( "size", Encode.int 10000 )
                ]
          )
        ]
    )


buildCompositeTermsSource : Bool -> ( String, String ) -> List ( String, Encode.Value )
buildCompositeTermsSource missing ( name, field ) =
    [ ( name
      , Encode.object
            [ ( "terms"
              , Encode.object
                    [ ( "field", Encode.string field )
                    -- TODO: Fix
                    , ( "missing_bucket", Encode.bool missing )
                    ]
              )
            ]
      )
    ]


getSourcesAggregation : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
getSourcesAggregation ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , Http.request
            { method = "POST"
            , url = model.elasticUrl ++ "/_search"
            , headers = []
            , body = Http.jsonBody buildSourcesAggregationBody
            , expect = Http.expectJson (GotSourcesAggregationResult) sourcesAggregationDecoder
            , timeout = Just 10000
            , tracker = Nothing
            }
        ]
    )


buildSourcesAggregationBody : Encode.Value
buildSourcesAggregationBody =
    Encode.object
        [ ( "aggs"
          , Encode.object
                [ buildCompositeAggregation
                    "source"
                    False
                    [ ( "category", "source_category" )
                    , ( "name", "name.keyword" )
                    ]
                ]
          )
        , ( "size", Encode.int 0 )
        , ( "query"
          , Encode.object
                [ ( "match"
                  , Encode.object [ ( "type", Encode.string "source" ) ]
                  )
                ]
          )
        ]


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Field.require "currentUrl" Decode.string <| \currentUrl ->
    Field.require "elasticUrl" Decode.string <| \elasticUrl ->
    Field.attempt "autofocus" Decode.bool <| \autofocus ->
    Field.attempt "resultBaseUrl" Decode.string <| \resultBaseUrl ->
    Field.attempt "showHeader" Decode.bool <| \showHeader ->
    Field.attempt "defaultQuery" Decode.string <| \defaultQuery ->
    Field.attempt "fixedParams" Decode.string <| \fixedParams ->
    Field.attempt "fixedQueryString" Decode.string <| \fixedQueryString ->
    Field.attempt "localStorage" (Decode.dict Decode.string) <| \localStorage ->
    Field.attempt "pageId" Decode.string <| \pageId ->
    Field.attempt "removeFilters" (Decode.list Decode.string) <| \removeFilters ->
    Field.attempt "showFilters" (Decode.list Decode.string) <| \showFilters ->
    Decode.succeed
        { autofocus = Maybe.withDefault defaultFlags.autofocus autofocus
        , currentUrl = currentUrl
        , defaultQuery = Maybe.withDefault defaultFlags.defaultQuery defaultQuery
        , elasticUrl = elasticUrl
        , fixedParams =
            fixedParams
                |> Maybe.map queryToParamsDict
                |> Maybe.withDefault defaultFlags.fixedParams
        , fixedQueryString = Maybe.withDefault defaultFlags.fixedQueryString fixedQueryString
        , localStorage = Maybe.withDefault defaultFlags.localStorage localStorage
        , pageId = Maybe.withDefault defaultFlags.pageId pageId
        , removeFilters = Maybe.withDefault defaultFlags.removeFilters removeFilters
        , resultBaseUrl = Maybe.withDefault defaultFlags.resultBaseUrl resultBaseUrl
        , showFilters = Maybe.withDefault defaultFlags.showFilters showFilters
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
    Field.attempt "aggregations" groupAggregationsDecoder <| \groupAggs ->
    Decode.succeed
        { hits = hits
        , total = total
        , groupAggs = groupAggs
        }


groupAggregationsDecoder : Decode.Decoder GroupAggregations
groupAggregationsDecoder =
    Field.requireAt [ "group1", "buckets" ] (Decode.list groupBucketDecoder) <| \group1 ->
    Field.attemptAt [ "group2", "buckets" ] (Decode.list groupBucketDecoder) <| \group2 ->
    Field.attemptAt [ "group3", "buckets" ] (Decode.list groupBucketDecoder) <| \group3 ->
    Decode.succeed
        { group1 = group1
        , group2 = group2
        , group3 = group3
        }


groupBucketDecoder : Decode.Decoder GroupBucket
groupBucketDecoder =
    Field.require "doc_count" Decode.int <| \count ->
    Field.attemptAt [ "key", "field1" ] decodeToString <| \key1 ->
    Field.attemptAt [ "key", "field2" ] decodeToString <| \key2 ->
    Field.attemptAt [ "key", "field3" ] decodeToString <| \key3 ->
    Decode.succeed
        { count = count
        , key1 = key1
        , key2 = key2
        , key3 = key3
        }


decodeToString : Decode.Decoder String
decodeToString =
    Decode.oneOf
        [ Decode.string
        , Decode.map String.fromInt Decode.int
        , Decode.map String.fromFloat Decode.float
        ]


aggregationBucketCountDecoder : Decode.Decoder a -> Decode.Decoder ( a, Int )
aggregationBucketCountDecoder keyDecoder =
    Field.require "key" keyDecoder <| \key ->
    Field.require "doc_count" Decode.int <| \count ->
    Decode.succeed ( key, count )


aggregationsDecoder : Decode.Decoder Aggregations
aggregationsDecoder =
    Field.requireAt
        [ "aggregations", "actions.keyword" ]
        (aggregationBucketDecoder Decode.string)
        <| \actions ->
    Field.requireAt
        [ "aggregations", "creature_family" ]
        (aggregationBucketDecoder Decode.string)
        <| \creatureFamilies ->
    Field.requireAt
        [ "aggregations", "hands.keyword" ]
        (aggregationBucketDecoder Decode.string)
        <| \hands ->
    Field.requireAt
        [ "aggregations", "item_category" ]
        (aggregationBucketDecoder Decode.string)
        <| \itemCategories ->
    Field.requireAt
        [ "aggregations", "item_subcategory" ]
        (aggregationBucketDecoder
            (Field.require "category" Decode.string <| \category ->
             Field.require "name" Decode.string <| \name ->
             Decode.succeed
                { category = category
                , name = name
                }
            )
        )
        <| \itemSubcategories ->
    Field.requireAt
        [ "aggregations", "reload_raw.keyword" ]
        (aggregationBucketDecoder Decode.string)
        <| \reloads ->
    Field.requireAt
        [ "aggregations", "source" ]
        (aggregationBucketDecoder Decode.string)
        <| \sources ->
    Field.requireAt
        [ "aggregations", "trait" ]
        (aggregationBucketDecoder Decode.string)
        <| \traits ->
    Field.requireAt
        [ "aggregations", "trait_group" ]
        (aggregationBucketDecoder
            (Field.require "group" Decode.string <| \group ->
             Field.require "trait" Decode.string <| \trait ->
             Decode.succeed
                { group = String.toLower group
                , trait = String.toLower trait
                }
            )
        )
        <| \traitGroups ->
    Field.requireAt
        [ "aggregations", "type" ]
        (aggregationBucketDecoder Decode.string)
        <| \types ->
    Field.requireAt
        [ "aggregations", "weapon_group" ]
        (aggregationBucketDecoder Decode.string)
        <| \weaponGroups ->
    Decode.succeed
        { actions = actions
        , creatureFamilies = creatureFamilies
        , hands = hands
        , itemCategories = itemCategories
        , itemSubcategories = itemSubcategories
        , reloads = reloads
        , sources = sources
        , traits = traits
        , traitGroups =
            traitGroups
                |> Dict.Extra.groupBy .group
                |> Dict.map (\_ v -> List.map .trait v)
        , types = types
        , weaponGroups = weaponGroups
        }


aggregationBucketDecoder : Decode.Decoder a -> Decode.Decoder (List a)
aggregationBucketDecoder keyDecoder =
    Decode.field "buckets" (Decode.list (Decode.field "key" keyDecoder))


sourcesAggregationDecoder : Decode.Decoder (List Source)
sourcesAggregationDecoder =
    Decode.at
        [ "aggregations", "source" ]
        (aggregationBucketDecoder
            (Field.require "category" Decode.string <| \category ->
             Field.require "name" Decode.string <| \name ->
             Decode.succeed
                { category = category
                , name = name
                }
            )
        )


sourcesDecoder : Decode.Decoder (List Document)
sourcesDecoder =
    Decode.at [ "hits", "hits" ] (Decode.list (Decode.field "_source" documentDecoder))


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
    Field.attempt "advanced_apocryphal_spell_markdown" Decode.string <| \advancedApocryphalSpell ->
    Field.attempt "advanced_domain_spell_markdown" Decode.string <| \advancedDomainSpell ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "ammunition" Decode.string <| \ammunition ->
    Field.attempt "apocryphal_spell_markdown" Decode.string <| \apocryphalSpell ->
    Field.attempt "archetype" Decode.string <| \archetype ->
    Field.attempt "area" Decode.string <| \area ->
    Field.attempt "armor_category" Decode.string <| \armorCategory ->
    Field.attempt "armor_group_markdown" Decode.string <| \armorGroup ->
    Field.attempt "aspect" Decode.string <| \aspect ->
    Field.attempt "attack_proficiency" stringListDecoder <| \attackProficiencies ->
    Field.attempt "base_item_markdown" Decode.string <| \baseItems ->
    Field.attempt "bloodline_markdown" Decode.string <| \bloodlines ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "bulk_raw" Decode.string <| \bulk ->
    Field.attempt "charisma" Decode.int <| \charisma ->
    Field.attempt "check_penalty" Decode.int <| \checkPenalty ->
    Field.attempt "complexity" Decode.string <| \complexity ->
    Field.attempt "component" stringListDecoder <| \components ->
    Field.attempt "constitution" Decode.int <| \constitution ->
    Field.attempt "cost_markdown" Decode.string <| \cost ->
    Field.attempt "creature_family" Decode.string <| \creatureFamily ->
    Field.attempt "creature_family_markdown" Decode.string <| \creatureFamilyMarkdown ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "defense_proficiency" stringListDecoder <| \defenseProficiencies ->
    Field.attempt "deity_markdown" Decode.string <| \deities ->
    Field.attempt "deity_category" Decode.string <| \deityCategory ->
    Field.attempt "dex_cap" Decode.int <| \dexCap ->
    Field.attempt "dexterity" Decode.int <| \dexterity ->
    Field.attempt "divine_font" stringListDecoder <| \divineFonts ->
    Field.attempt "domain_markdown" Decode.string <| \domains ->
    Field.attempt "domain_spell_markdown" Decode.string <| \domainSpell ->
    Field.attempt "duration" Decode.int <| \durationValue ->
    Field.attempt "duration_raw" Decode.string <| \duration ->
    Field.attempt "familiar_ability" stringListDecoder <| \familiarAbilities ->
    Field.attempt "favored_weapon_markdown" Decode.string <| \favoredWeapons ->
    Field.attempt "feat_markdown" Decode.string <| \feats ->
    Field.attempt "fortitude_save" Decode.int <| \fort ->
    Field.attempt "fortitude_proficiency" Decode.string <| \fortitudeProficiency ->
    Field.attempt "follower_alignment" stringListDecoder <| \followerAlignments ->
    Field.attempt "frequency" Decode.string <| \frequency ->
    Field.attempt "hands" Decode.string <| \hands ->
    Field.attempt "hardness_raw" Decode.string <| \hardness ->
    Field.attempt "hazard_type" Decode.string <| \hazardType ->
    Field.attempt "heighten" (Decode.list Decode.string) <| \heighten ->
    Field.attempt "heighten_level" (Decode.list Decode.int) <| \heightenLevels ->
    Field.attempt "hp_raw" Decode.string <| \hp ->
    Field.attempt "icon_image" Decode.string <| \iconImage ->
    Field.attempt "image" stringListDecoder <| \images ->
    Field.attempt "immunity_markdown" Decode.string <| \immunities ->
    Field.attempt "intelligence" Decode.int <| \intelligence ->
    Field.attempt "item_category" Decode.string <| \itemCategory ->
    Field.attempt "item_subcategory" Decode.string <| \itemSubcategory ->
    Field.attempt "language_markdown" Decode.string <| \languages ->
    Field.attempt "lesson_markdown" Decode.string <| \lessons ->
    Field.attempt "lesson_type" Decode.string <| \lessonType ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "search_markdown" Decode.string <| \searchMarkdown ->
    Field.attempt "mystery_markdown" Decode.string <| \mysteries ->
    Field.attempt "onset_raw" Decode.string <| \onset ->
    Field.attempt "patron_theme_markdown" Decode.string <| \patronThemes ->
    Field.attempt "perception" Decode.int <| \perception ->
    Field.attempt "perception_proficiency" Decode.string <| \perceptionProficiency ->
    Field.attempt "pfs" Decode.string <| \pfs ->
    Field.attempt "plane_category" Decode.string <| \planeCategory ->
    Field.attempt "prerequisite_markdown" Decode.string <| \prerequisites ->
    Field.attempt "price_raw" Decode.string <| \price ->
    Field.attempt "primary_check_markdown" Decode.string <| \primaryCheck ->
    Field.attempt "range" Decode.int <| \rangeValue ->
    Field.attempt "range_raw" Decode.string <| \range ->
    Field.attempt "rarity" Decode.string <| \rarity ->
    Field.attempt "reflex_save" Decode.int <| \ref ->
    Field.attempt "reflex_proficiency" Decode.string <| \reflexProficiency ->
    Field.attempt "region" Decode.string <| \region->
    Field.attempt "release_date" Decode.string <| \releaseDate ->
    Field.attempt "reload_raw" Decode.string <| \reload ->
    Field.attempt "required_abilities" Decode.string <| \requiredAbilities ->
    Field.attempt "requirement_markdown" Decode.string <| \requirements ->
    Field.attempt "resistance" damageTypeValuesDecoder <| \resistanceValues ->
    Field.attempt "resistance_markdown" Decode.string <| \resistances ->
    Field.attempt "saving_throw_markdown" Decode.string <| \savingThrow ->
    Field.attempt "school" Decode.string <| \school ->
    Field.attempt "secondary_casters_raw" Decode.string <| \secondaryCasters ->
    Field.attempt "secondary_check_markdown" Decode.string <| \secondaryChecks ->
    Field.attempt "sense_markdown" Decode.string <| \senses ->
    Field.attempt "size" stringListDecoder <| \sizes ->
    Field.attempt "skill_markdown" Decode.string <| \skills ->
    Field.attempt "skill_proficiency" stringListDecoder <| \skillProficiencies ->
    Field.attempt "source" stringListDecoder <| \sourceList ->
    Field.attempt "source_category" Decode.string <| \sourceCategory ->
    Field.attempt "source_group" Decode.string <| \sourceGroup ->
    Field.attempt "source_markdown" Decode.string <| \sources ->
    Field.attempt "speed" speedTypeValuesDecoder <| \speedValues ->
    Field.attempt "speed_markdown" Decode.string <| \speed ->
    Field.attempt "speed_penalty" Decode.string <| \speedPenalty ->
    Field.attempt "spell_list" Decode.string <| \spellList ->
    Field.attempt "spoilers" Decode.string <| \spoilers ->
    Field.attempt "stage_markdown" Decode.string <| \stages ->
    Field.attempt "strength" Decode.int <| \strength ->
    Field.attempt "strongest_save" stringListDecoder <| \strongestSaves ->
    Field.attempt "summary_markdown" Decode.string <| \summary ->
    Field.attempt "target_markdown" Decode.string <| \targets ->
    Field.attempt "tradition" stringListDecoder <| \traditionList ->
    Field.attempt "tradition_markdown" Decode.string <| \traditions ->
    Field.attempt "trait_markdown" Decode.string <| \traits ->
    Field.attempt "trait" stringListDecoder <| \traitList ->
    Field.attempt "trigger_markdown" Decode.string <| \trigger ->
    Field.attempt "usage_markdown" Decode.string <| \usage ->
    Field.attempt "vision" Decode.string <| \vision ->
    Field.attempt "weakest_save" stringListDecoder <| \weakestSaves ->
    Field.attempt "weakness" damageTypeValuesDecoder <| \weaknessValues ->
    Field.attempt "weakness_markdown" Decode.string <| \weaknesses ->
    Field.attempt "weapon_category" Decode.string <| \weaponCategory ->
    Field.attempt "weapon_group" Decode.string <| \weaponGroup ->
    Field.attempt "weapon_group_markdown" Decode.string <| \weaponGroupMarkdown ->
    Field.attempt "weapon_type" Decode.string <| \weaponType ->
    Field.attempt "will_save" Decode.int <| \will ->
    Field.attempt "will_proficiency" Decode.string <| \willProficiency ->
    Field.attempt "wisdom" Decode.int <| \wisdom ->
    Decode.succeed
        { category = category
        , name = name
        , type_ = type_
        , url = url
        , abilities = Maybe.withDefault [] abilities
        , abilityFlaws = Maybe.withDefault [] abilityFlaws
        , abilityType = abilityType
        , ac = ac
        , actions = actions
        , activate = activate
        , advancedApocryphalSpell = advancedApocryphalSpell
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , ammunition = ammunition
        , apocryphalSpell = apocryphalSpell
        , archetype = archetype
        , area = area
        , armorCategory = armorCategory
        , armorGroup = armorGroup
        , aspect = aspect
        , attackProficiencies = Maybe.withDefault [] attackProficiencies
        , baseItems = baseItems
        , bloodlines = bloodlines
        , breadcrumbs = breadcrumbs
        , bulk = bulk
        , charisma = charisma
        , checkPenalty = checkPenalty
        , complexity = complexity
        , components = Maybe.withDefault [] components
        , constitution = constitution
        , cost = cost
        , creatureFamily = creatureFamily
        , creatureFamilyMarkdown = creatureFamilyMarkdown
        , damage = damage
        , defenseProficiencies = Maybe.withDefault [] defenseProficiencies
        , deities = deities
        , deityCategory = deityCategory
        , dexCap = dexCap
        , dexterity = dexterity
        , divineFonts = Maybe.withDefault [] divineFonts
        , domains = domains
        , domainSpell = domainSpell
        , duration = duration
        , durationValue = durationValue
        , familiarAbilities = Maybe.withDefault [] familiarAbilities
        , favoredWeapons = favoredWeapons
        , feats = feats
        , fort = fort
        , fortitudeProficiency = fortitudeProficiency
        , followerAlignments = Maybe.withDefault [] followerAlignments
        , frequency = frequency
        , hands = hands
        , hardness = hardness
        , hazardType = hazardType
        , heighten = Maybe.withDefault [] heighten
        , heightenLevels = Maybe.withDefault [] heightenLevels
        , hp = hp
        , iconImage = iconImage
        , images = Maybe.withDefault [] images
        , immunities = immunities
        , intelligence = intelligence
        , itemCategory = itemCategory
        , itemSubcategory = itemSubcategory
        , languages = languages
        , lessons = lessons
        , lessonType = lessonType
        , level = level
        , mysteries = mysteries
        , onset = onset
        , patronThemes = patronThemes
        , perception = perception
        , perceptionProficiency = perceptionProficiency
        , pfs = pfs
        , planeCategory = planeCategory
        , prerequisites = prerequisites
        , price = price
        , primaryCheck = primaryCheck
        , range = range
        , rangeValue = rangeValue
        , rarity = rarity
        , ref = ref
        , reflexProficiency = reflexProficiency
        , region = region
        , releaseDate = releaseDate
        , reload = reload
        , requiredAbilities = requiredAbilities
        , requirements = requirements
        , resistanceValues = resistanceValues
        , resistances = resistances
        , savingThrow = savingThrow
        , school = school
        , searchMarkdown =
            searchMarkdown
                |> Maybe.withDefault ""
                |> Markdown.Parser.parse
                |> Result.map (List.map (Markdown.Block.walk mergeInlines))
                |> Result.mapError (List.map Markdown.Parser.deadEndToString)
        , secondaryCasters = secondaryCasters
        , secondaryChecks = secondaryChecks
        , senses = senses
        , sizes = Maybe.withDefault [] sizes
        , skills = skills
        , skillProficiencies = Maybe.withDefault [] skillProficiencies
        , sourceCategory = sourceCategory
        , sourceGroup = sourceGroup
        , sourceList = Maybe.withDefault [] sourceList
        , sources = sources
        , speed = speed
        , speedPenalty = speedPenalty
        , speedValues = speedValues
        , spellList = spellList
        , spoilers = spoilers
        , stages = stages
        , strength = strength
        , strongestSaves = Maybe.withDefault [] strongestSaves
        , summary = summary
        , targets = targets
        , traditionList = Maybe.withDefault [] traditionList
        , traditions = traditions
        , traitList = Maybe.withDefault [] traitList
        , traits = traits
        , trigger = trigger
        , usage = usage
        , vision = vision
        , weakestSaves = Maybe.withDefault [] weakestSaves
        , weaknessValues = weaknessValues
        , weaknesses = weaknesses
        , weaponCategory = weaponCategory
        , weaponGroup = weaponGroup
        , weaponGroupMarkdown = weaponGroupMarkdown
        , weaponType = weaponType
        , will = will
        , willProficiency = willProficiency
        , wisdom = wisdom
        }


damageTypeValuesDecoder : Decode.Decoder DamageTypeValues
damageTypeValuesDecoder =
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "acid" Decode.int <| \acid ->
    Field.attempt "all" Decode.int <| \all ->
    Field.attempt "area" Decode.int <| \area ->
    Field.attempt "bleed" Decode.int <| \bleed ->
    Field.attempt "bludgeoning" Decode.int <| \bludgeoning ->
    Field.attempt "chaotic" Decode.int <| \chaotic ->
    Field.attempt "cold" Decode.int <| \cold ->
    Field.attempt "cold_iron" Decode.int <| \coldIron ->
    Field.attempt "electricity" Decode.int <| \electricity ->
    Field.attempt "evil" Decode.int <| \evil ->
    Field.attempt "fire" Decode.int <| \fire ->
    Field.attempt "force" Decode.int <| \force ->
    Field.attempt "good" Decode.int <| \good ->
    Field.attempt "lawful" Decode.int <| \lawful ->
    Field.attempt "mental" Decode.int <| \mental ->
    Field.attempt "negative" Decode.int <| \negative ->
    Field.attempt "orichalcum" Decode.int <| \orichalcum ->
    Field.attempt "physical" Decode.int <| \physical ->
    Field.attempt "piercing" Decode.int <| \piercing ->
    Field.attempt "poison" Decode.int <| \poison ->
    Field.attempt "positive" Decode.int <| \positive ->
    Field.attempt "precision" Decode.int <| \precision ->
    Field.attempt "silver" Decode.int <| \silver ->
    Field.attempt "slashing" Decode.int <| \slashing ->
    Field.attempt "sonic" Decode.int <| \sonic ->
    Field.attempt "splash" Decode.int <| \splash ->
    Decode.succeed
        { acid = acid
        , all = all
        , area = area
        , bleed = bleed
        , bludgeoning = bludgeoning
        , chaotic = chaotic
        , cold = cold
        , coldIron = coldIron
        , electricity = electricity
        , evil = evil
        , fire = fire
        , force = force
        , good = good
        , lawful = lawful
        , mental = mental
        , negative = negative
        , orichalcum = orichalcum
        , physical = physical
        , piercing = piercing
        , poison = poison
        , positive = positive
        , precision = precision
        , silver = silver
        , slashing = slashing
        , sonic = sonic
        , splash = splash
        }


speedTypeValuesDecoder : Decode.Decoder SpeedTypeValues
speedTypeValuesDecoder =
    Field.attempt "burrow" Decode.int <| \burrow ->
    Field.attempt "climb" Decode.int <| \climb ->
    Field.attempt "fly" Decode.int <| \fly ->
    Field.attempt "land" Decode.int <| \land ->
    Field.attempt "max" Decode.int <| \max ->
    Field.attempt "swim" Decode.int <| \swim ->
    Decode.succeed
        { burrow = burrow
        , climb = climb
        , fly = fly
        , land = land
        , max = max
        , swim = swim
        }


mergeInlines : Markdown.Block.Block -> Markdown.Block.Block
mergeInlines block =
    let
        inlineTags : List String
        inlineTags =
            [ "actions"
            , "br"
            , "sup"
            ]
    in
    mapHtmlElementChildren
        (List.foldl
            (\child children ->
                case child of
                    Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement tagName a c) ->
                        if List.member tagName inlineTags then
                            case List.Extra.splitAt (List.length children - 1) children of
                                -- If previous block is a paragraph, add the block to its inlines
                                ( before, [ Markdown.Block.Paragraph inlines ] ) ->
                                    Markdown.Block.HtmlInline (Markdown.Block.HtmlElement tagName a c)
                                        |> List.singleton
                                        |> List.append inlines
                                        |> Markdown.Block.Paragraph
                                        |> List.singleton
                                        |> List.append before

                                _ ->
                                    List.append children [ child ]

                        else
                            List.append children [ child ]

                    Markdown.Block.Paragraph inlines ->
                        case List.Extra.splitAt (List.length children - 1) children of
                            -- If previous block is a paragraph and its last inline is an inline tag,
                            -- then merge the paragraphs
                            ( before, [ Markdown.Block.Paragraph prevInlines ] ) ->
                                case List.Extra.last prevInlines of
                                    Just (Markdown.Block.HtmlInline (Markdown.Block.HtmlElement tagName _ _)) ->
                                        if List.member tagName inlineTags then
                                            List.append
                                                before
                                                [ Markdown.Block.Paragraph (List.append prevInlines inlines) ]

                                        else
                                            List.append children [ child ]

                                    _ ->
                                        List.append children [ child ]

                            _ ->
                                List.append children [ child ]

                    _ ->
                        List.append children [ child ]
            )
            []
        )
        block


mapHtmlElementChildren :
    (List (Markdown.Block.Block) -> List (Markdown.Block.Block))
    -> Markdown.Block.Block
    -> Markdown.Block.Block
mapHtmlElementChildren mapFun block =
    case block of
        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement name attrs children) ->
            Markdown.Block.HtmlBlock
                (Markdown.Block.HtmlElement
                    name
                    attrs
                    (mapFun children)
                )

        _ ->
            block


getUrl : Model -> Document -> String
getUrl model doc =
    model.resultBaseUrl ++ doc.url


view : Model -> Html Msg
view model =
    Html.div
        []
        [ Html.node "style"
            []
            [ Html.text css
            , case model.theme of
                Blackbird ->
                    Html.text cssBlackbird

                Dark ->
                    Html.text cssDark

                Dead ->
                    Html.text cssDead

                Light ->
                    Html.text cssLight

                Orc ->
                    Html.text cssOrc

                Paper ->
                    Html.text cssPaper

                ExtraContrast ->
                    Html.text cssExtraContrast

                Lavender ->
                    Html.text cssLavender

            , if model.showResultAdditionalInfo then
                Html.text ""

              else
                Html.text ".additional-info { display:none; }"

            , if model.showResultSpoilers then
                Html.text ""

              else
                Html.text ".spoilers { display:none; }"

            , if model.showResultSummary then
                Html.text ""

              else
                Html.text ".summary { display:none; }"

            , if model.showResultTraits then
                Html.text ""

              else
                Html.text ".traits { display:none; }"

            , if model.showResultAdditionalInfo && model.showResultSummary then
                Html.text ""

              else
                Html.text ".additional-info + hr { display:none; }"
            ]
        , FontAwesome.Styles.css
        , Html.div
            [ HA.class "body-container"
            , HA.class "column"
            , HA.class "align-center"
            , HA.class "gap-large"
            ]
            (List.append
                (if model.showHeader then
                    [ Html.button
                        [ HA.class "menu-open-button"
                        , HE.onClick (ShowMenuPressed True)
                        , HE.onMouseOver (ShowMenuPressed True)
                        ]
                        [ FontAwesome.view FontAwesome.Solid.bars ]
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
                [ if model.showHeader then
                    viewTitle

                  else
                    Html.text ""

                , viewQuery model model.searchModel
                , viewSearchResults model model.searchModel
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
            [ FontAwesome.view FontAwesome.Solid.times
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
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Dark
                            , text = "Dark"
                            }
                        , viewRadioButton
                            { checked = model.theme == Light
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Light
                            , text = "Light"
                            }
                        , viewRadioButton
                            { checked = model.theme == Paper
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Paper
                            , text = "Paper"
                            }
                        , viewRadioButton
                            { checked = model.theme == ExtraContrast
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected ExtraContrast
                            , text = "Extra Contrast"
                            }
                        , viewRadioButton
                            { checked = model.theme == Dead
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Dead
                            , text = "Theme of the Dead"
                            }
                        , viewRadioButton
                            { checked = model.theme == Lavender
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Lavender
                            , text = "Lavender"
                            }
                        , viewRadioButton
                            { checked = model.theme == Blackbird
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Blackbird
                            , text = "Blackbird"
                            }
                        , viewRadioButton
                            { checked = model.theme == Orc
                            , enabled = True
                            , name = "theme-type"
                            , onInput = ThemeSelected Orc
                            , text = "Orc"
                            }
                        ]
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
        , HA.class "limit-width"
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


viewQuery : Model -> SearchModel -> Html Msg
viewQuery model searchModel =
    Html.div
        [ HA.class "column"
        , HA.class "align-stretch"
        , HA.class "limit-width"
        , HA.class "gap-medium"
        , HA.class "fill-width-with-padding"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "input-container"
            ]
            [ Html.input
                [ HA.autofocus model.autofocus
                , HA.class "query-input"
                , HA.maxlength 8192
                , HA.placeholder "Enter search query"
                , HA.type_ "text"
                , HA.value searchModel.query
                , HA.attribute "autocapitalize" "off"
                , HE.onInput QueryChanged
                ]
                [ Html.text searchModel.query ]
            , if String.isEmpty searchModel.query then
                Html.text ""

              else
                Html.button
                    [ HA.class "input-button"
                    , HA.style "font-size" "24px"
                    , HE.onClick (QueryChanged "")
                    ]
                    [ FontAwesome.view FontAwesome.Solid.times ]
            ]

        , viewFilters model searchModel
        , viewActiveFiltersAndOptions model searchModel
        ]


viewFilters : Model -> SearchModel -> Html Msg
viewFilters model searchModel =
    let
        availableFilters : List FilterBox
        availableFilters =
            allFilters
                |> List.filter (\filter -> not (List.member filter.id searchModel.removeFilters))

        visibleFilters : List FilterBox
        visibleFilters =
            if searchModel.showAllFilters || List.length availableFilters <= 6 then
                availableFilters

             else
                availableFilters
                    |> List.filter (\filter -> List.member filter.id searchModel.alwaysShowFilters)
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "gap-small"
            , HA.class "align-center"
            ]
            (List.concat
                [ [ Html.h4
                        []
                        [ Html.text "Filters:" ]
                  ]
                , List.map
                    (\filter ->
                        Html.button
                            [ HE.onClick
                                (ShowFilterBox
                                    filter.id
                                    (not (Set.member filter.id searchModel.visibleFilterBoxes))
                                )
                            , HAE.attributeIf
                                (Set.member filter.id searchModel.visibleFilterBoxes)
                                (HA.class "active")
                            ]
                            [ Html.text filter.label ]
                    )
                    visibleFilters
                , if List.length visibleFilters == List.length availableFilters then
                    []

                  else
                    [ Html.button
                        [ HE.onClick ShowAllFilters ]
                        [ Html.text "Show all filters" ]
                    ]
                ]
            )
        , Html.div
            [ HA.class "row"
            , HA.class "gap-small"
            , HA.class "align-center"
            ]
            (List.append
                [ Html.h4
                    []
                    [ Html.text "Options:" ]
                ]
                (List.map
                    (\filter ->
                        Html.button
                            [ HE.onClick
                                (ShowFilterBox
                                    filter.id
                                    (not (Set.member filter.id searchModel.visibleFilterBoxes))
                                )
                            , HAE.attributeIf
                                (Set.member filter.id searchModel.visibleFilterBoxes)
                                (HA.class "active")
                            ]
                            [ Html.text filter.label ]
                    )
                    allOptions
                )
            )
        , Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
            (List.map
                (\filter ->
                    if Set.member filter.id searchModel.visibleFilterBoxes then
                        viewOptionBox model searchModel filter

                    else
                        Html.text ""
                )
                (allFilters ++ allOptions)
            )
        ]


viewOptionBox : Model -> SearchModel -> FilterBox -> Html Msg
viewOptionBox model searchModel filter =
    Html.div
        [ HA.class "option-container"
        , HA.class "column"
        , HA.class "gap-small"
        , HA.class "fade-in"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.style "justify-content" "space-between"
            ]
            [ Html.h3
                []
                [ Html.text filter.label
                ]
            , Html.button
                [ HA.class "input-button"
                , HA.style "font-size" "var(--font-large)"
                , HE.onClick (ShowFilterBox filter.id False)
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
            (filter.view model searchModel)
        ]


allFilters : List FilterBox
allFilters =
    [ { id = "numbers"
      , label = "Numbers"
      , view = viewFilterNumbers
      }
    , { id = "abilities"
      , label = "Abilities (Boosts)"
      , view = viewFilterAbilities
      }
    , { id = "actions"
      , label = "Actions / Cast time"
      , view = viewFilterActions
      }
    , { id = "alignments"
      , label = "Alignments"
      , view = viewFilterAlignments
      }
    , { id = "components"
      , label = "Casting components"
      , view = viewFilterComponents
      }
    , { id = "creature-families"
      , label = "Creature families"
      , view = viewFilterCreatureFamilies
      }
    , { id = "item-categories"
      , label = "Item categories"
      , view = viewFilterItemCategories
      }
    , { id = "hands"
      , label = "Hands"
      , view = viewFilterHands
      }
    , { id = "schools"
      , label = "Magic schools"
      , view = viewFilterMagicSchools
      }
    , { id = "pfs"
      , label = "PFS"
      , view = viewFilterPfs
      }
    , { id = "rarities"
      , label = "Rarities"
      , view = viewFilterRarities
      }
    , { id = "reload"
      , label = "Reload"
      , view = viewFilterReload
      }
    , { id = "saving-throws"
      , label = "Saving throws"
      , view = viewFilterSavingThrows
      }
    , { id = "sizes"
      , label = "Sizes"
      , view = viewFilterSizes
      }
    , { id = "skills"
      , label = "Skills"
      , view = viewFilterSkills
      }
    , { id = "sources"
      , label = "Sources & Spoilers"
      , view = viewFilterSources
      }
    , { id = "strongest-saves"
      , label = "Strongest / Weakest saves"
      , view = viewFilterStrongestSaves
      }
    , { id = "traditions"
      , label = "Traditions / Spell lists"
      , view = viewFilterTraditions
      }
    , { id = "traits"
      , label = "Traits"
      , view = viewFilterTraits
      }
    , { id = "types"
      , label = "Types / Categories"
      , view = viewFilterTypes
      }
    , { id = "weapons"
      , label = "Weapons"
      , view = viewFilterWeapons
      }
    ]


allOptions : List FilterBox
allOptions =
    [ { id = "query-type"
      , label = "Query type"
      , view = viewQueryType
      }
    , { id = "display"
      , label = "Result display"
      , view = viewResultDisplay
      }
    , { id = "sort"
      , label = "Sort results"
      , view = viewSortResults
      }
    , { id = "page-size"
      , label = "Result amount"
      , view = viewResultPageSize
      }
    ]


filterFields : SearchModel -> List ( String, Dict String Bool, Bool )
filterFields searchModel =
    [ ( "ability", searchModel.filteredAbilities, False )
    , ( "actions.keyword", searchModel.filteredActions, False )
    , ( "alignment", searchModel.filteredAlignments, False )
    , ( "component", searchModel.filteredComponents, searchModel.filterComponentsOperator )
    , ( "creature_family", searchModel.filteredCreatureFamilies, False )
    , ( "hands.keyword", searchModel.filteredHands, False )
    , ( "item_category", searchModel.filteredItemCategories, False )
    , ( "item_subcategory", searchModel.filteredItemSubcategories, False )
    , ( "pfs", searchModel.filteredPfs, False )
    , ( "rarity", searchModel.filteredRarities, False )
    , ( "reload_raw.keyword", searchModel.filteredReloads, False )
    , ( "saving_throw", searchModel.filteredSavingThrows, False )
    , ( "school", searchModel.filteredSchools, False )
    , ( "size", searchModel.filteredSizes, False )
    , ( "skill", searchModel.filteredSkills, False )
    , ( "source", searchModel.filteredSources, False )
    , ( "source_category", searchModel.filteredSourceCategories, False )
    , ( "strongest_save", searchModel.filteredStrongestSaves, False )
    , ( "tradition", searchModel.filteredTraditions, searchModel.filterTraditionsOperator )
    , ( "trait", searchModel.filteredTraits, searchModel.filterTraitsOperator )
    , ( "type", searchModel.filteredTypes, False )
    , ( "weakest_save", searchModel.filteredWeakestSaves, False )
    , ( "weapon_category", searchModel.filteredWeaponCategories, False )
    , ( "weapon_group", searchModel.filteredWeaponGroups, False )
    , ( "weapon_type", searchModel.filteredWeaponTypes, False )
    ]


mergeFromToValues : SearchModel -> List ( String, Maybe String, Maybe String )
mergeFromToValues searchModel =
    Dict.merge
        (\field from ->
            (::) ( field, Just from, Nothing )
        )
        (\field from to ->
            (::) ( field, Just from, Just to )
        )
        (\field to ->
            (::) ( field, Nothing, Just to )
        )
        searchModel.filteredFromValues
        searchModel.filteredToValues
        []


currentQueryAsComplex : SearchModel -> String
currentQueryAsComplex searchModel =
    let
        surroundWithQuotes : String -> String
        surroundWithQuotes s =
            if String.contains " " s then
                "\"" ++ s ++ "\""

            else
                s

        surroundWithParantheses : Dict String Bool -> String -> String
        surroundWithParantheses dict s =
            if Dict.size dict > 1 || List.length (boolDictExcluded dict) /= 0 then
                "(" ++ s ++ ")"
            else
                s
    in
    [ filterFields searchModel
        |> List.filterMap
            (\( field, dict, isAnd ) ->
                if Dict.isEmpty dict then
                    Nothing

                else
                    [ boolDictIncluded dict
                        |> List.map surroundWithQuotes
                        |> String.join (if isAnd then " AND " else " OR ")
                    , boolDictExcluded dict
                        |> List.map surroundWithQuotes
                        |> List.map (String.append "-")
                        |> String.join " "
                    ]
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "
                        |> surroundWithParantheses dict
                        |> String.append ":"
                        |> String.append field
                        |> Just
            )
    , List.map
        (\( field, maybeFrom, maybeTo ) ->
            case ( maybeFrom, maybeTo ) of
                ( Just from, Just to ) ->
                    if from == to then
                        field ++ ":" ++ from

                    else
                        field ++ ":[" ++ from ++ " TO " ++ to ++ "]"

                ( Just from, Nothing ) ->
                    field ++ ":>=" ++ from

                ( Nothing, Just to ) ->
                    field ++ ":<=" ++ to

                ( Nothing, Nothing ) ->
                    ""
        )
        (mergeFromToValues searchModel)
    , if searchModel.filterSpoilers then
        [ "NOT spoilers:*" ]

      else
        []
    ]
        |> List.concat
        |> String.join " "


viewActiveFiltersAndOptions : Model -> SearchModel -> Html Msg
viewActiveFiltersAndOptions model searchModel =
    let
        currentQuery : String
        currentQuery =
            currentQueryAsComplex searchModel
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h4
            []
            [ Html.text "Active filters and options:" ]

        , if String.isEmpty currentQuery then
            Html.text ""

          else
            viewActiveFilters searchModel

        , if List.isEmpty searchModel.sort then
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
                                [ Html.text
                                    (field
                                        |> String.split "."
                                        |> (::) (sortDirToString dir)
                                        |> List.reverse
                                        |> String.join " "
                                        |> String.Extra.humanize
                                    )
                                , getSortIcon field (Just dir)
                                ]
                        )
                        searchModel.sort
                    ]
                )

        , Html.div
            []
            [ case searchModel.queryType of
                Standard ->
                    Html.text "Query type: Standard (includes similar results)"

                ElasticsearchQueryString ->
                    Html.text "Query type: Complex"
            ]

        , if searchModel.queryType == Standard && not model.autoQueryType && queryCouldBeComplex searchModel.query then
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
                    [ FontAwesome.view FontAwesome.Solid.exclamation ]
                , Html.div
                    []
                    [ Html.text "Your query contains characters that can be used with the complex query type, but you are currently using the standard query type. Would you like to "
                    , Html.button
                        [ HE.onClick (QueryTypeSelected ElasticsearchQueryString) ]
                        [ Html.text "switch to complex query type" ]
                    , Html.text " or "
                    , Html.button
                        [ HE.onClick (AutoQueryTypeChanged True) ]
                        [ Html.text "enable automatic query type switching" ]
                    , Html.text "?"
                    ]
                ]

          else
            Html.text ""
        ]


viewActiveFilters : SearchModel -> Html Msg
viewActiveFilters searchModel =
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
                                            [ viewPfsIcon 16 value
                                            , viewTextWithActionIcons (String.Extra.toTitleCase value)
                                            ]
                                    )
                                    list
                                )
                            )
                )
                [ { class = Just "trait"
                  , label =
                        if searchModel.filterTraitsOperator then
                            "Include all traits:"

                        else
                            "Include any trait:"
                  , list = boolDictIncluded searchModel.filteredTraits
                  , removeMsg = TraitFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Exclude traits:"
                  , list = boolDictExcluded searchModel.filteredTraits
                  , removeMsg = TraitFilterRemoved
                  }
                , { class = Just "filter-type"
                  , label = "Include types:"
                  , list = boolDictIncluded searchModel.filteredTypes
                  , removeMsg = TypeFilterRemoved
                  }
                , { class = Just "filter-type"
                  , label = "Exclude types:"
                  , list = boolDictExcluded searchModel.filteredTypes
                  , removeMsg = TypeFilterRemoved
                  }
                , { class = Nothing
                  , label =
                        if searchModel.filterTraditionsOperator then
                            "Include all traditions:"

                        else
                            "Include any tradition:"
                  , list = boolDictIncluded searchModel.filteredTraditions
                  , removeMsg = TraditionFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude traditions:"
                  , list = boolDictExcluded searchModel.filteredTraditions
                  , removeMsg = TraditionFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include actions:"
                  , list = boolDictIncluded searchModel.filteredActions
                  , removeMsg = ActionsFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude actions:"
                  , list = boolDictExcluded searchModel.filteredActions
                  , removeMsg = ActionsFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include abilities:"
                  , list = boolDictIncluded searchModel.filteredAbilities
                  , removeMsg = AbilityFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude abilities:"
                  , list = boolDictExcluded searchModel.filteredAbilities
                  , removeMsg = AbilityFilterRemoved
                  }
                , { class = Just "trait trait-alignment"
                  , label = "Include alignments:"
                  , list = boolDictIncluded searchModel.filteredAlignments
                  , removeMsg = AlignmentFilterRemoved
                  }
                , { class = Just "trait trait-alignment"
                  , label = "Exclude alignments:"
                  , list = boolDictExcluded searchModel.filteredAlignments
                  , removeMsg = AlignmentFilterRemoved
                  }
                , { class = Nothing
                  , label =
                        if searchModel.filterComponentsOperator then
                            "Include all components:"

                        else
                            "Include any component:"
                  , list = boolDictIncluded searchModel.filteredComponents
                  , removeMsg = ComponentFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude components:"
                  , list = boolDictExcluded searchModel.filteredComponents
                  , removeMsg = ComponentFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include creature families:"
                  , list = boolDictIncluded searchModel.filteredCreatureFamilies
                  , removeMsg = CreatureFamilyFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude creature families:"
                  , list = boolDictExcluded searchModel.filteredCreatureFamilies
                  , removeMsg = CreatureFamilyFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include hands:"
                  , list = boolDictIncluded searchModel.filteredHands
                  , removeMsg = HandFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude hands:"
                  , list = boolDictExcluded searchModel.filteredHands
                  , removeMsg = HandFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include item categories:"
                  , list = boolDictIncluded searchModel.filteredItemCategories
                  , removeMsg = ItemCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude item categories:"
                  , list = boolDictExcluded searchModel.filteredItemCategories
                  , removeMsg = ItemCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include item subcategories:"
                  , list = boolDictIncluded searchModel.filteredItemSubcategories
                  , removeMsg = ItemSubcategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude item subcategories:"
                  , list = boolDictExcluded searchModel.filteredItemSubcategories
                  , removeMsg = ItemSubcategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include PFS:"
                  , list = boolDictIncluded searchModel.filteredPfs
                  , removeMsg = PfsFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude PFS:"
                  , list = boolDictExcluded searchModel.filteredPfs
                  , removeMsg = PfsFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Include rarity:"
                  , list = boolDictIncluded searchModel.filteredRarities
                  , removeMsg = RarityFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Exclude rarity:"
                  , list = boolDictExcluded searchModel.filteredRarities
                  , removeMsg = RarityFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include reload:"
                  , list = boolDictIncluded searchModel.filteredReloads
                  , removeMsg = ReloadFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude reload:"
                  , list = boolDictExcluded searchModel.filteredReloads
                  , removeMsg = ReloadFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include saving throws:"
                  , list = boolDictIncluded searchModel.filteredSavingThrows
                  , removeMsg = SavingThrowFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude saving throws:"
                  , list = boolDictExcluded searchModel.filteredSavingThrows
                  , removeMsg = SavingThrowFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Include schools:"
                  , list = boolDictIncluded searchModel.filteredSchools
                  , removeMsg = SchoolFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Exclude schools:"
                  , list = boolDictExcluded searchModel.filteredSchools
                  , removeMsg = SchoolFilterRemoved
                  }
                , { class = Just "trait trait-size"
                  , label = "Include sizes:"
                  , list = boolDictIncluded searchModel.filteredSizes
                  , removeMsg = SizeFilterRemoved
                  }
                , { class = Just "trait trait-size"
                  , label = "Exclude sizes:"
                  , list = boolDictExcluded searchModel.filteredSizes
                  , removeMsg = SizeFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include skills:"
                  , list = boolDictIncluded searchModel.filteredSkills
                  , removeMsg = SkillFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude skills:"
                  , list = boolDictExcluded searchModel.filteredSkills
                  , removeMsg = SkillFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include sources:"
                  , list = boolDictIncluded searchModel.filteredSources
                  , removeMsg = SourceFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude sources:"
                  , list = boolDictExcluded searchModel.filteredSources
                  , removeMsg = SourceFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include source categories:"
                  , list = boolDictIncluded searchModel.filteredSourceCategories
                  , removeMsg = SourceCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude source categories:"
                  , list = boolDictExcluded searchModel.filteredSourceCategories
                  , removeMsg = SourceCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include strongest saves:"
                  , list = boolDictIncluded searchModel.filteredStrongestSaves
                  , removeMsg = StrongestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude strongest saves:"
                  , list = boolDictExcluded searchModel.filteredStrongestSaves
                  , removeMsg = StrongestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weakest saves:"
                  , list = boolDictIncluded searchModel.filteredWeakestSaves
                  , removeMsg = WeakestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weakest saves:"
                  , list = boolDictExcluded searchModel.filteredWeakestSaves
                  , removeMsg = WeakestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weapon categories:"
                  , list = boolDictIncluded searchModel.filteredWeaponCategories
                  , removeMsg = WeaponCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weapon categories:"
                  , list = boolDictExcluded searchModel.filteredWeaponCategories
                  , removeMsg = WeaponCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weapon groups:"
                  , list = boolDictIncluded searchModel.filteredWeaponGroups
                  , removeMsg = WeaponGroupFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weapon groups:"
                  , list = boolDictExcluded searchModel.filteredWeaponGroups
                  , removeMsg = WeaponGroupFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weapon types:"
                  , list = boolDictIncluded searchModel.filteredWeaponTypes
                  , removeMsg = WeaponTypeFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weapon types:"
                  , list = boolDictExcluded searchModel.filteredWeaponTypes
                  , removeMsg = WeaponTypeFilterRemoved
                  }
                , { class = Nothing
                  , label = "Spoilers:"
                  , list =
                        if searchModel.filterSpoilers then
                            [ "Hide spoilers" ]

                        else
                            []
                  , removeMsg = \_ -> FilterSpoilersChanged False
                  }
                ]
            )

        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            , HA.class "align-baseline"
            ]
            (mergeFromToValues searchModel
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


viewFilterAbilities : Model -> SearchModel -> List (Html Msg)
viewFilterAbilities model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllAbilityFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\ability ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (AbilityFilterAdded ability)
                    ]
                    [ Html.text (String.Extra.toTitleCase ability)
                    , viewFilterIcon (Dict.get ability searchModel.filteredAbilities)
                    ]
            )
            Data.abilities
        )
    ]


viewFilterActions : Model -> SearchModel -> List (Html Msg)
viewFilterActions model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllActionsFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\actions ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "align-center"
                            , HA.class "gap-tiny"
                            , HE.onClick (ActionsFilterAdded actions)
                            ]
                            [ viewTextWithActionIcons actions
                            , viewFilterIcon (Dict.get actions searchModel.filteredActions)
                            ]
                    )
                    (List.sort aggregations.actions)

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterAlignments : Model -> SearchModel -> List (Html Msg)
viewFilterAlignments model searchModel =
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
                    , viewFilterIcon (Dict.get alignment searchModel.filteredAlignments)
                    ]
            )
            Data.alignments
        )
    ]


viewFilterComponents : Model -> SearchModel -> List (Html Msg)
viewFilterComponents model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllComponentFiltersPressed ]
            [ Html.text "Reset selection" ]
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
                    , viewFilterIcon (Dict.get component searchModel.filteredComponents)
                    ]
            )
            [ "focus"
            , "material"
            , "somatic"
            , "verbal"
            ]
        )
    ]


viewFilterCreatureFamilies : Model -> SearchModel -> List (Html Msg)
viewFilterCreatureFamilies model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllCreatureFamilyFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "input-container"
        ]
        [ Html.input
            [ HA.placeholder "Search among creature families"
            , HA.value searchModel.searchCreatureFamilies
            , HA.type_ "text"
            , HE.onInput SearchCreatureFamiliesChanged
            ]
            []
        , if String.isEmpty searchModel.searchCreatureFamilies then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchCreatureFamiliesChanged "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\creatureFamily ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "nowrap"
                            , HA.class "align-center"
                            , HA.style "text-align" "left"
                            , HE.onClick (CreatureFamilyFilterAdded (String.toLower creatureFamily))
                            ]
                            [ Html.text (String.Extra.toTitleCase creatureFamily)
                            , viewFilterIcon (Dict.get (String.toLower creatureFamily) searchModel.filteredCreatureFamilies)
                            ]
                    )
                    (aggregations.creatureFamilies
                        |> List.filter (String.toLower >> String.contains (String.toLower searchModel.searchCreatureFamilies))
                        |> List.sort
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterHands : Model -> SearchModel -> List (Html Msg)
viewFilterHands model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllHandFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok { hands })->
                (List.map
                    (\hand ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (HandFilterAdded hand)
                            ]
                            [ Html.text hand
                            , viewFilterIcon (Dict.get hand searchModel.filteredHands)
                            ]
                    )
                    (List.sort hands)
                )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterItemCategories : Model -> SearchModel -> List (Html Msg)
viewFilterItemCategories model searchModel =
    [ Html.h4
        []
        [ Html.text "Item categories" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllItemCategoryFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "input-container"
        ]
        [ Html.input
            [ HA.placeholder "Search among item categories"
            , HA.value searchModel.searchItemCategories
            , HA.type_ "text"
            , HE.onInput SearchItemCategoriesChanged
            ]
            []
        , if String.isEmpty searchModel.searchItemCategories then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchItemCategoriesChanged "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\category ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "nowrap"
                            , HE.onClick (ItemCategoryFilterAdded category)
                            ]
                            [ Html.div
                                []
                                [ Html.text (String.Extra.toTitleCase category) ]
                            , viewFilterIcon (Dict.get category searchModel.filteredItemCategories)
                            ]
                    )
                    (aggregations.itemCategories
                        |> List.filter (String.toLower >> String.contains (String.toLower searchModel.searchItemCategories))
                        |> List.sort
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    , Html.h4
        []
        [ Html.text "Item subcategories" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllItemSubcategoryFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "input-container"
        ]
        [ Html.input
            [ HA.placeholder "Search among item subcategories"
            , HA.value searchModel.searchItemSubcategories
            , HA.type_ "text"
            , HE.onInput SearchItemSubcategoriesChanged
            ]
            []
        , if String.isEmpty searchModel.searchItemSubcategories then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchItemSubcategoriesChanged "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\subcategory ->
                        let
                            filteredCategory : Maybe Bool
                            filteredCategory =
                                Maybe.Extra.or
                                    (case boolDictIncluded searchModel.filteredItemCategories of
                                        [] ->
                                            Nothing

                                        categories ->
                                            if List.member subcategory.category categories then
                                                Nothing

                                            else
                                                Just False
                                    )
                                    (case boolDictExcluded searchModel.filteredItemCategories of
                                        [] ->
                                            Nothing

                                        categories ->
                                            if List.member subcategory.category categories then
                                                Just False

                                            else
                                                Nothing
                                    )
                        in
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "nowrap"
                            , HA.disabled (Maybe.Extra.isJust filteredCategory)
                            , HAE.attributeIf (Maybe.Extra.isJust filteredCategory) (HA.class "excluded")
                            , HE.onClick (ItemSubcategoryFilterAdded subcategory.name)
                            ]
                            [ Html.div
                                []
                                [ Html.text (String.Extra.toTitleCase subcategory.name) ]
                            , viewFilterIcon
                                (Maybe.Extra.or
                                    (Dict.get subcategory.name searchModel.filteredItemSubcategories)
                                    filteredCategory
                                )
                            ]
                    )
                    (aggregations.itemSubcategories
                        |> List.filter
                            (.name
                                >> String.toLower
                                >> String.contains (String.toLower searchModel.searchItemSubcategories)
                            )
                        |> List.sortBy .name
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterMagicSchools : Model -> SearchModel -> List (Html Msg)
viewFilterMagicSchools model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllSchoolFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\school ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "nowrap"
                    , HA.class "align-center"
                    , HA.style "text-align" "left"
                    , HA.class "trait"
                    , HE.onClick (SchoolFilterAdded school)
                    ]
                    [ Html.text (String.Extra.toTitleCase school)
                    , viewFilterIcon (Dict.get school searchModel.filteredSchools)
                    ]
            )
            Data.magicSchools
        )
    ]


viewFilterPfs : Model -> SearchModel -> List (Html Msg)
viewFilterPfs model searchModel =
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
                    [ viewPfsIcon 16 pfs
                    , Html.text (String.Extra.toTitleCase pfs)
                    , viewFilterIcon (Dict.get pfs searchModel.filteredPfs)
                    ]
            )
            [ "none"
            , "standard"
            , "limited"
            , "restricted"
            ]
        )
    ]


viewFilterRarities : Model -> SearchModel -> List (Html Msg)
viewFilterRarities model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllRarityFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\rarity ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "trait"
                            , HA.class ("trait-" ++ rarity)
                            , HE.onClick (RarityFilterAdded rarity)
                            ]
                            [ Html.text (String.Extra.toTitleCase rarity)
                            , viewFilterIcon (Dict.get rarity searchModel.filteredRarities)
                            ]
                    )
                    (aggregations.traits
                        |> List.filter (\trait -> List.member trait Data.rarities)
                        |> List.filter ((/=) "common")
                        |> (::) "common"
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterReload : Model -> SearchModel -> List (Html Msg)
viewFilterReload model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllReloadFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok { reloads })->
                (List.map
                    (\reload ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (ReloadFilterAdded reload)
                            ]
                            [ Html.text reload
                            , viewFilterIcon (Dict.get reload searchModel.filteredReloads)
                            ]
                    )
                    (List.sort reloads)
                )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterSavingThrows : Model -> SearchModel -> List (Html Msg)
viewFilterSavingThrows model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllSavingThrowFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\save ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "nowrap"
                    , HA.class "align-center"
                    , HA.style "text-align" "left"
                    , HE.onClick (SavingThrowFilterAdded save)
                    ]
                    [ Html.text (String.Extra.toTitleCase save)
                    , viewFilterIcon (Dict.get save searchModel.filteredSavingThrows)
                    ]
            )
            Data.saves
        )
    ]


viewFilterSizes : Model -> SearchModel -> List (Html Msg)
viewFilterSizes model searchModel =
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
                    , viewFilterIcon (Dict.get size searchModel.filteredSizes)
                    ]
            )
            Data.sizes
        )
    ]


viewFilterSkills : Model -> SearchModel -> List (Html Msg)
viewFilterSkills model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllSkillFiltersPressed ]
            [ Html.text "Reset selection" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\skill ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (SkillFilterAdded skill)
                    ]
                    [ Html.text (String.Extra.toTitleCase skill)
                    , viewFilterIcon (Dict.get skill searchModel.filteredSkills)
                    ]
            )
            Data.skills
        )
    ]


viewFilterSources : Model -> SearchModel -> List (Html Msg)
viewFilterSources model searchModel =
    [ viewCheckbox
        { checked = searchModel.filterSpoilers
        , onCheck = FilterSpoilersChanged
        , text = "Hide results with spoilers"
        }
    , Html.h4
        []
        [ Html.text "Source categories" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllSourceCategoryFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\category ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (SourceCategoryFilterAdded category)
                    ]
                    [ Html.text (String.Extra.toTitleCase category)
                    , viewFilterIcon (Dict.get category searchModel.filteredSourceCategories)
                    ]
            )
            Data.sourceCategories
        )
    , Html.h4
        []
        [ Html.text "Sources" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllSourceFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "input-container"
        ]
        [ Html.input
            [ HA.placeholder "Search among sources"
            , HA.value searchModel.searchSources
            , HA.type_ "text"
            , HE.onInput SearchSourcesChanged
            ]
            []
        , if String.isEmpty searchModel.searchSources then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchSourcesChanged "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case ( model.sourcesAggregation, searchModel.aggregations ) of
            ( Just (Ok allSources), Just (Ok { sources }) ) ->
                (List.map
                    (\source ->
                        let
                            filteredCategory : Maybe Bool
                            filteredCategory =
                                Maybe.Extra.or
                                    (case boolDictIncluded searchModel.filteredSourceCategories of
                                        [] ->
                                            Nothing

                                        categories ->
                                            if List.member source.category categories then
                                                Nothing

                                            else
                                                Just False
                                    )
                                    (case boolDictExcluded searchModel.filteredSourceCategories of
                                        [] ->
                                            Nothing

                                        categories ->
                                            if List.member source.category categories then
                                                Just False

                                            else
                                                Nothing
                                    )
                        in
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "nowrap"
                            , HA.class "align-center"
                            , HA.style "text-align" "left"
                            , HA.disabled (Maybe.Extra.isJust filteredCategory)
                            , HAE.attributeIf (Maybe.Extra.isJust filteredCategory) (HA.class "excluded")
                            , HE.onClick (SourceFilterAdded source.name)
                            ]
                            [ Html.div
                                []
                                [ Html.text source.name ]
                            , viewFilterIcon
                                (Maybe.Extra.or
                                    (Dict.get source.name searchModel.filteredSources)
                                    filteredCategory
                                )
                            ]
                    )
                    (allSources
                        |> List.filter
                            (.name
                                >> String.toLower
                                >> String.contains (String.toLower searchModel.searchSources)
                            )
                        |> List.filter (\source -> List.member (String.toLower source.name) sources)
                        |> List.sortBy .name
                    )
                )

            ( Just (Err _), _ ) ->
                []

            ( _, Just (Err _) ) ->
                []

            _ ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterStrongestSaves : Model -> SearchModel -> List (Html Msg)
viewFilterStrongestSaves model searchModel =
    [ Html.h4
        []
        [ Html.text "Strongest saves" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllStrongestSaveFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\save ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "nowrap"
                    , HA.class "align-center"
                    , HA.style "text-align" "left"
                    , HE.onClick (StrongestSaveFilterAdded (String.toLower save))
                    ]
                    [ Html.text (String.Extra.toTitleCase save)
                    , viewFilterIcon (Dict.get (String.toLower save) searchModel.filteredStrongestSaves)
                    ]
            )
            Data.saves
        )

    , Html.h4
        []
        [ Html.text "Weakest saves" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllWeakestSaveFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\save ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "nowrap"
                    , HA.class "align-center"
                    , HA.style "text-align" "left"
                    , HE.onClick (WeakestSaveFilterAdded (String.toLower save))
                    ]
                    [ Html.text (String.Extra.toTitleCase save)
                    , viewFilterIcon (Dict.get (String.toLower save) searchModel.filteredWeakestSaves)
                    ]
            )
            Data.saves
        )
    ]


viewFilterTraditions : Model -> SearchModel -> List (Html Msg)
viewFilterTraditions model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllTraditionFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = searchModel.filterTraditionsOperator
            , enabled = True
            , name = "filter-traditions"
            , onInput = FilterTraditionsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not searchModel.filterTraditionsOperator
            , enabled = True
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
                    , viewFilterIcon (Dict.get tradition searchModel.filteredTraditions)
                    ]
            )
            Data.traditionsAndSpellLists
        )
    ]


viewFilterTraits : Model -> SearchModel -> List (Html Msg)
viewFilterTraits model searchModel =
    [ viewCheckbox
        { checked = model.groupTraits
        , onCheck = GroupTraitsChanged
        , text = "Group traits by category"
        }
    , Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllTraitFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = searchModel.filterTraitsOperator
            , enabled = True
            , name = "filter-traits"
            , onInput = FilterTraitsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not searchModel.filterTraitsOperator
            , enabled = True
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
            , HA.value searchModel.searchTraits
            , HA.type_ "text"
            , HE.onInput SearchTraitsChanged
            ]
            []
        , if String.isEmpty searchModel.searchTraits then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchTraitsChanged "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
        ]

    , if model.groupTraits then
        Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
            (case searchModel.aggregations of
                Just (Ok aggregations) ->
                    let
                        categorizedTraits : List String
                        categorizedTraits =
                            aggregations.traitGroups
                                |> Dict.values
                                |> List.concat

                        uncategorizedTraits : List String
                        uncategorizedTraits =
                            aggregations.traits
                                |> List.filter (\trait -> not (List.member trait categorizedTraits))
                                |> List.filter (\trait -> not (List.member trait (List.map Tuple.first Data.alignments)))
                                |> List.filter (\trait -> not (List.member trait Data.sizes))
                    in
                    (List.map
                        (\( group, traits ) ->
                            Html.div
                                [ HA.class "column"
                                , HA.class "gap-tiny"
                                ]
                                [ Html.div
                                    [ HA.class "row"
                                    , HA.class "gap-small"
                                    , HA.class "align-center"
                                    ]
                                    [ Html.h4
                                        []
                                        [ Html.text (String.Extra.toTitleCase group) ]
                                    , Html.button
                                        [ HE.onClick (TraitGroupIncludePressed traits) ]
                                        [ Html.text "Include group" ]
                                    , Html.button
                                        [ HE.onClick (TraitGroupExcludePressed traits) ]
                                        [ Html.text "Exclude group" ]
                                    , Html.button
                                        [ HE.onClick (TraitGroupDeselectPressed traits) ]
                                        [ Html.text "Deselect group" ]
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
                                                [ Html.text (String.Extra.toTitleCase trait)
                                                , viewFilterIcon (Dict.get trait searchModel.filteredTraits)
                                                ]
                                        )
                                        (List.sort traits)
                                    )
                                ]
                        )
                        (aggregations.traitGroups
                            |> Dict.filter
                                (\group traits ->
                                    not (List.member group [ "half-elf", "half-orc", "aon-special" ])
                                )
                            |> Dict.toList
                            |> (::) ( "uncategorized", uncategorizedTraits )
                            |> List.map
                                (Tuple.mapSecond
                                    (List.filter
                                        (String.toLower >> String.contains (String.toLower searchModel.searchTraits))
                                    )
                                )
                            |> List.map (Tuple.mapSecond (List.filter ((/=) "common")))
                            |> List.filter (Tuple.second >> List.isEmpty >> not)
                        )
                    )

                Just (Err _) ->
                    []

                Nothing ->
                    [ viewScrollboxLoader ]
            )

      else
        Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "scrollbox"
            ]
            (case searchModel.aggregations of
                Just (Ok aggregations) ->
                    List.map
                        (\trait ->
                            Html.button
                                [ HA.class "trait"
                                , getTraitClass trait
                                , HA.class "row"
                                , HA.class "align-center"
                                , HA.class "gap-tiny"
                                , HE.onClick (TraitFilterAdded trait)
                                ]
                                [ Html.text (String.Extra.toTitleCase trait)
                                , viewFilterIcon (Dict.get trait searchModel.filteredTraits)
                                ]
                        )
                        (aggregations.traits
                            |> List.filter (\trait -> not (List.member trait (List.map Tuple.first Data.alignments)))
                            |> List.filter (\trait -> not (List.member trait Data.sizes))
                            |> List.filter (String.toLower >> String.contains (String.toLower searchModel.searchTraits))
                            |> List.sort
                        )

                Just (Err _) ->
                    []

                Nothing ->
                    [ viewScrollboxLoader ]
            )
    ]


viewFilterTypes : Model -> SearchModel -> List (Html Msg)
viewFilterTypes model searchModel =
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
            , HA.value searchModel.searchTypes
            , HE.onInput SearchTypesChanged
            ]
            []
        , if String.isEmpty searchModel.searchTypes then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchTypesChanged "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
        ]

    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\type_ ->
                        Html.button
                            [ HA.class "filter-type"
                            , HA.class "row"
                            , HA.class "align-center"
                            , HA.class "gap-tiny"
                            , HE.onClick (TypeFilterAdded type_)
                            ]
                            [ Html.text (String.Extra.toTitleCase type_)
                            , viewFilterIcon (Dict.get type_ searchModel.filteredTypes)
                            ]
                    )
                    (List.filter
                        (String.toLower >> String.contains (String.toLower searchModel.searchTypes))
                        (List.sort aggregations.types)
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterWeapons : Model -> SearchModel -> List (Html Msg)
viewFilterWeapons model searchModel =
    [ Html.h4
        []
        [ Html.text "Weapon categories" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllWeaponCategoryFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\category ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (WeaponCategoryFilterAdded category)
                    ]
                    [ Html.text (String.Extra.toTitleCase category)
                    , viewFilterIcon (Dict.get category searchModel.filteredWeaponCategories)
                    ]
            )
            Data.weaponCategories
        )

    , Html.h4
        []
        [ Html.text "Weapon groups" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllWeaponGroupFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case searchModel.aggregations of
            Just (Ok { weaponGroups })->
                (List.map
                    (\group ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (WeaponGroupFilterAdded group)
                            ]
                            [ Html.text (String.Extra.toTitleCase group)
                            , viewFilterIcon (Dict.get group searchModel.filteredWeaponGroups)
                            ]
                    )
                    (List.sort weaponGroups)
                )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )

    , Html.h4
        []
        [ Html.text "Weapon types" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllWeaponTypeFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\type_ ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (WeaponTypeFilterAdded type_)
                    ]
                    [ Html.text (String.Extra.toTitleCase type_)
                    , viewFilterIcon (Dict.get type_ searchModel.filteredWeaponTypes)
                    ]
            )
            Data.weaponTypes
        )
    ]


viewFilterNumbers : Model -> SearchModel -> List (Html Msg)
viewFilterNumbers model searchModel =
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
                            , HA.class "align-center"
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
                                    , HA.value (Maybe.withDefault "" (Dict.get field searchModel.filteredFromValues))
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
                                    , HA.value (Maybe.withDefault "" (Dict.get field searchModel.filteredToValues))
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
                , { field = "duration"
                  , hint = Just "(1 round is 6s)"
                  , step = "1"
                  , suffix = Just "s"
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
                            , HA.value searchModel.selectedFilterAbility
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
                                , HA.value (Maybe.withDefault "" (Dict.get searchModel.selectedFilterAbility searchModel.filteredFromValues))
                                , HE.onInput (FilteredFromValueChanged searchModel.selectedFilterAbility)
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
                                , HA.value (Maybe.withDefault "" (Dict.get searchModel.selectedFilterAbility searchModel.filteredToValues))
                                , HE.onInput (FilteredToValueChanged searchModel.selectedFilterAbility)
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
                        , HA.class "align-center"
                        ]
                        [ Html.select
                            [ HA.class "input-container"
                            , HA.value searchModel.selectedFilterSpeed
                            , HE.onInput FilterSpeedChanged
                            ]
                            (List.map
                                (\speed ->
                                    Html.option
                                        [ HA.value speed ]
                                        [ Html.text (String.Extra.toTitleCase speed)
                                        ]
                                )
                                Data.speedTypes
                            )
                        , Html.text "speed"
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
                                            ("speed." ++ searchModel.selectedFilterSpeed)
                                            searchModel.filteredFromValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredFromValueChanged
                                        ("speed." ++ searchModel.selectedFilterSpeed)
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
                                            ("speed." ++ searchModel.selectedFilterSpeed)
                                            searchModel.filteredToValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredToValueChanged
                                        ("speed." ++ searchModel.selectedFilterSpeed)
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
                            , HA.value searchModel.selectedFilterResistance
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
                                            ("resistance." ++ searchModel.selectedFilterResistance)
                                            searchModel.filteredFromValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredFromValueChanged
                                        ("resistance." ++ searchModel.selectedFilterResistance)
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
                                            ("resistance." ++ searchModel.selectedFilterResistance)
                                            searchModel.filteredToValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredToValueChanged
                                        ("resistance." ++ searchModel.selectedFilterResistance)
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
                            , HA.value searchModel.selectedFilterWeakness
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
                                            ("weakness." ++ searchModel.selectedFilterWeakness)
                                            searchModel.filteredFromValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredFromValueChanged
                                        ("weakness." ++ searchModel.selectedFilterWeakness)
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
                                            ("weakness." ++ searchModel.selectedFilterWeakness)
                                            searchModel.filteredToValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredToValueChanged
                                        ("weakness." ++ searchModel.selectedFilterWeakness)
                                    )
                                ]
                                []
                            ]
                        ]
                    ]
              ]
            , [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-small"
                        , HA.class "align-center"
                        ]
                        [ Html.h4
                            []
                            [ Html.text "Release date" ]
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
                                [ HA.type_ "date"
                                , HA.value (Maybe.withDefault "" (Dict.get "release_date" searchModel.filteredFromValues))
                                , HE.onInput (FilteredFromValueChanged "release_date")
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
                                [ HA.type_ "date"
                                , HA.value (Maybe.withDefault "" (Dict.get "release_date" searchModel.filteredToValues))
                                , HE.onInput (FilteredToValueChanged "release_date")
                                ]
                                []
                            ]
                        ]
                    ]
              ]
            ]
        )
    ]


viewQueryType : Model -> SearchModel -> List (Html Msg)
viewQueryType model searchModel =
    let
        currentQuery : String
        currentQuery =
            currentQueryAsComplex searchModel
    in
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = searchModel.queryType == Standard
            , enabled = not model.autoQueryType
            , name = "query-type"
            , onInput = QueryTypeSelected Standard
            , text = "Standard"
            }
        , viewRadioButton
            { checked = searchModel.queryType == ElasticsearchQueryString
            , enabled = not model.autoQueryType
            , name = "query-type"
            , onInput = QueryTypeSelected ElasticsearchQueryString
            , text = "Complex"
            }
        , viewCheckbox
            { checked = model.autoQueryType
            , onCheck = AutoQueryTypeChanged
            , text = "Automatically set query type based on query"
            }
        ]
    , Html.div
        []
        [ Html.text "The standard query type behaves like most search engines, searching on keywords. It includes results that are similar to what you searched for to help catch misspellings (a.k.a. fuzzy matching). Results matching by name are scored higher than results matching in the description."
        ]
    , Html.div
        []
        [ Html.text "The complex query type allows you to write queries using Elasticsearch Query String syntax. It doesn't do fuzzy matching by default, and allows searching for phrases by surrounding them with quotes. It also allows searching in specific fields by searching "
        , Html.span
            [ HA.class "monospace" ]
            [ Html.text "field:value" ]
        , Html.text ". For full documentation on how the query syntax works see "
        , Html.a
            [ HA.href "https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-syntax"
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

    , Html.h4
        []
        [ Html.text "Current filters as complex query" ]
    , Html.div
        [ HA.class "scrollbox"
        , HA.class "monospace"
        ]
        [ if String.isEmpty currentQuery then
            Html.span
                [ HA.style "color" "var(--color-inactive-text)" ]
                [ Html.text "No filters applied"
                ]

          else
            Html.text currentQuery
        ]

    , Html.h4
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
            [ Html.text "Non-consumable items between 500 and 1000 gp (note that price is in copper):" ]
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


viewResultPageSize : Model -> SearchModel -> List (Html Msg)
viewResultPageSize model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        (List.map
            (\size ->
                viewRadioButton
                    { checked = model.pageSize == size
                    , enabled = True
                    , name = "page-size"
                    , onInput = PageSizeChanged size
                    , text = String.fromInt size
                    }
            )
            Data.pageSizes
        )
    , Html.text "Number of results to load. Smaller numbers gives faster results."
    ]


viewResultDisplay : Model -> SearchModel -> List (Html Msg)
viewResultDisplay model searchModel =
    let
        pageDefaultDisplayIsCurrent : Bool
        pageDefaultDisplayIsCurrent =
            Dict.get model.pageId model.pageDefaultDisplays
                |> Maybe.withDefault Dict.empty
                |> (==) (Dict.fromList (getDisplayParamsList model searchModel))
    in
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = searchModel.resultDisplay == List
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged List
            , text = "List"
            }
        , viewRadioButton
            { checked = searchModel.resultDisplay == Table
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged Table
            , text = "Table"
            }
        , viewRadioButton
            { checked = searchModel.resultDisplay == Grouped
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged Grouped
            , text = "Grouped"
            }
        ]
    , Html.h4
        []
        [ Html.text "Page default display" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        ]
        [ Html.button
            [ HE.onClick SavePageDefaultDisplayPressed
            , HA.disabled
                (Dict.member model.pageId model.pageDefaultDisplays
                    && pageDefaultDisplayIsCurrent
                )
            ]
            [ Html.text "Save current as default" ]
        , Html.button
            [ HE.onClick LoadPageDefaultDisplayPressed
            , HA.disabled
                (not (Dict.member model.pageId model.pageDefaultDisplays)
                    || pageDefaultDisplayIsCurrent
                )
            ]
            [ Html.text "Load default" ]
        ]
    , Html.div
        []
        [ Html.text ("Current page ID: " ++ model.pageId) ]
    , Html.h4
        []
        [ Html.text "General result settings" ]
    , viewCheckbox
        { checked = model.openInNewTab
        , onCheck = OpenInNewTabChanged
        , text = "Links open in new tab"
        }
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        (case searchModel.resultDisplay of
            List ->
                viewResultDisplayList model

            Table ->
                viewResultDisplayTable model searchModel

            Grouped ->
                viewResultDisplayGrouped model searchModel
        )
    ]


viewResultDisplayList : Model -> List (Html Msg)
viewResultDisplayList model =
    [ Html.h4
        []
        [ Html.text "List configuration" ]
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
    , viewCheckbox
        { checked = model.showResultSummary
        , onCheck = ShowSummaryChanged
        , text = "Show summary"
        }
    ]


viewResultDisplayTable : Model -> SearchModel -> List (Html Msg)
viewResultDisplayTable model searchModel =
    [ Html.h4
        []
        [ Html.text "Table configuration" ]
    , viewCheckbox
        { checked = model.limitTableWidth
        , onCheck = LimitTableWidthChanged
        , text = "Limit table width"
        }
    , Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        ]
        [ Html.div
            [ HA.class "column"
            , HA.class "gap-tiny"
            , HA.class "grow"
            , HA.style "flex-basis" "300px"
            ]
            [ Html.div
                []
                [ Html.text "Selected columns" ]
            , Html.Keyed.node
                "div"
                [ HA.class "scrollbox"
                , HA.class "column"
                , HA.class "gap-small"
                ]
                (List.indexedMap
                    (\index column ->
                        ( column
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            , HA.class "align-center"
                            ]
                            [ Html.button
                                [ HE.onClick (TableColumnRemoved column)
                                ]
                                [ FontAwesome.view FontAwesome.Solid.times
                                ]
                            , Html.button
                                [ HA.disabled (index == 0)
                                , HE.onClick (TableColumnMoved index (index - 1))
                                ]
                                [ FontAwesome.view FontAwesome.Solid.chevronUp
                                ]
                            , Html.button
                                [ HA.disabled (index + 1 == List.length searchModel.tableColumns)
                                , HE.onClick (TableColumnMoved index (index + 1))
                                ]
                                [ FontAwesome.view FontAwesome.Solid.chevronDown
                                ]
                            , Html.text (sortFieldToLabel column)
                            ]
                        )
                    )
                    searchModel.tableColumns
                )
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "gap-tiny"
            , HA.class "grow"
            , HA.style "flex-basis" "300px"
            ]
            [ Html.div
                []
                [ Html.text "Available columns" ]
            , Html.div
                [ HA.class "scrollbox"
                , HA.class "column"
                , HA.class "gap-small"
                ]
                (List.concatMap
                    (viewResultDisplayTableColumn searchModel)
                    Data.tableColumns
                )
            ]
        ]
    , Html.h4
        []
        [ Html.text "Predefined column sets" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        (List.map
            (\{ columns, label } ->
                Html.button
                    [ HE.onClick (TableColumnSetChosen columns)
                    ]
                    [ Html.text label ]
            )
            Data.predefinedColumnConfigurations
        )

    , Html.h4
        []
        [ Html.text "User-defined column sets" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        ]
        [ Html.div
            [ HA.class "input-container" ]
            [ Html.input
                [ HA.placeholder "Name"
                , HA.type_ "text"
                , HA.value model.savedColumnConfigurationName
                , HA.maxlength 100
                , HE.onInput SavedColumnConfigurationNameChanged
                ]
                []
            ]
        , Html.button
            [ HA.disabled
                (String.isEmpty model.savedColumnConfigurationName
                    || Dict.get model.savedColumnConfigurationName model.savedColumnConfigurations
                        == Just searchModel.tableColumns
                )
            , HE.onClick SaveColumnConfigurationPressed ]
            [ Html.text "Save" ]
        , Html.button
            [ HA.disabled
                (not (Dict.member
                    model.savedColumnConfigurationName
                    model.savedColumnConfigurations
                ))
            , HE.onClick (DeleteColumnConfigurationPressed)
            ]
            [ Html.text "Delete" ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        (List.map
            (\name ->
                Html.button
                    [ HE.onClick (SavedColumnConfigurationSelected name) ]
                    [ Html.text name ]
            )
            (Dict.keys model.savedColumnConfigurations)
        )
    ]


viewResultDisplayTableColumn : SearchModel -> String -> List (Html Msg)
viewResultDisplayTableColumn searchModel column =
    [ Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        , HA.class "align-center"
        ]
        [ Html.button
            [ HAE.attributeIf (List.member column searchModel.tableColumns) (HA.class "active")
            , if List.member column searchModel.tableColumns then
                HE.onClick (TableColumnRemoved column)

              else
                HE.onClick (TableColumnAdded column)
            ]
            [ FontAwesome.view FontAwesome.Solid.plus
            ]

        , Html.text (toTitleCase (String.Extra.humanize column))
        ]

    , case column of
        "resistance" ->
            viewResultDisplayTableColumnWithSelect
                searchModel
                { column = column
                , onInput = ColumnResistanceChanged
                , selected = searchModel.selectedColumnResistance
                , types = Data.damageTypes
                }

        "speed" ->
            viewResultDisplayTableColumnWithSelect
                searchModel
                { column = column
                , onInput = ColumnSpeedChanged
                , selected = searchModel.selectedColumnSpeed
                , types = Data.speedTypes
                }

        "weakness" ->
            viewResultDisplayTableColumnWithSelect
                searchModel
                { column = column
                , onInput = ColumnWeaknessChanged
                , selected = searchModel.selectedColumnWeakness
                , types = Data.damageTypes
                }

        _ ->
            Html.text ""
    ]


viewResultDisplayTableColumnWithSelect :
    SearchModel
    -> { column : String
       , onInput : String -> Msg
       , selected : String
       , types : List String
       }
    -> Html Msg
viewResultDisplayTableColumnWithSelect searchModel { column, onInput, selected, types } =
    let
        columnWithType : String
        columnWithType =
            column ++ "." ++ selected
    in
    Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        , HA.class "align-center"
        ]
        [ Html.button
            [ HA.disabled (List.member columnWithType searchModel.tableColumns)
            , HE.onClick (TableColumnAdded columnWithType)
            ]
            [ FontAwesome.view FontAwesome.Solid.plus
            ]
        , Html.select
            [ HA.class "input-container"
            , HA.value selected
            , HE.onInput onInput
            ]
            (List.map
                (\type_ ->
                    Html.option
                        [ HA.value type_ ]
                        [ Html.text (String.Extra.humanize type_) ]
                )
                types
            )
        , Html.text column
        ]


viewResultDisplayGrouped : Model -> SearchModel -> List (Html Msg)
viewResultDisplayGrouped model searchModel =
    [ Html.h4
        []
        [ Html.text "Group by" ]
    , Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        [ Html.div
            [ HA.class "scrollbox"
            , HA.class "column"
            , HA.class "gap-small"
            ]
            (List.map
                (\field ->
                    Html.div
                        [ HA.class "row"
                        , HA.class "gap-small"
                        , HA.class "align-center"
                        ]
                        [ Html.button
                            [ HE.onClick (GroupField1Changed field)
                            , HA.disabled (searchModel.groupField1 == field)
                            , HAE.attributeIf
                                (searchModel.groupField1 == field)
                                (HA.class "active")
                            ]
                            [ Html.text "1st" ]
                        , Html.button
                            [ HE.onClick
                                (if searchModel.groupField2 == Just field then
                                    GroupField2Changed Nothing

                                 else
                                    GroupField2Changed (Just field)
                                )
                            , HAE.attributeIf
                                (searchModel.groupField2 == Just field)
                                (HA.class "active")
                            ]
                            [ Html.text "2nd" ]
                        , Html.button
                            [ HE.onClick
                                (if searchModel.groupField3 == Just field then
                                    GroupField3Changed Nothing

                                 else
                                    GroupField3Changed (Just field)
                                )
                            , HA.disabled (searchModel.groupField2 == Nothing)
                            , HAE.attributeIf
                                (searchModel.groupField3 == Just field)
                                (HA.class "active")
                            ]
                            [ Html.text "3rd" ]
                        , Html.text (toTitleCase (String.Extra.humanize field))
                        ]
                )
                [ "ability"
                , "actions"
                , "alignment"
                , "creature_family"
                , "duration"
                , "heighten_level"
                , "item_category"
                , "item_subcategory"
                , "level"
                , "hands"
                , "pfs"
                , "range"
                , "rarity"
                , "school"
                , "size"
                , "source"
                , "tradition"
                , "trait"
                , "type"
                , "weapon_category"
                , "weapon_group"
                , "weapon_type"
                ]
            )
        ]

    , Html.h4
        []
        [ Html.text "Groups with 0 loaded results" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = model.groupedDisplay == Show
            , enabled = True
            , name = "grouped-display"
            , onInput = GroupedDisplayChanged Show
            , text = "Show"
            }
        , viewRadioButton
            { checked = model.groupedDisplay == Dim
            , enabled = True
            , name = "grouped-display"
            , onInput = GroupedDisplayChanged Dim
            , text = "Dim"
            }
        , viewRadioButton
            { checked = model.groupedDisplay == Hide
            , enabled = True
            , name = "grouped-display"
            , onInput = GroupedDisplayChanged Hide
            , text = "Hide"
            }
        ]

    , Html.h4
        []
        [ Html.text "Group sort order" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = model.groupedSort == Alphanum
            , enabled = True
            , name = "grouped-sort"
            , onInput = GroupedSortChanged Alphanum
            , text = "Alphanumeric"
            }
        , viewRadioButton
            { checked = model.groupedSort == CountLoaded
            , enabled = True
            , name = "grouped-sort"
            , onInput = GroupedSortChanged CountLoaded
            , text = "Count (Loaded)"
            }
        , viewRadioButton
            { checked = model.groupedSort == CountTotal
            , enabled = True
            , name = "grouped-sort"
            , onInput = GroupedSortChanged CountTotal
            , text = "Count (Total)"
            }
        ]
    , Html.h4
        []
        [ Html.text "Link layout" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = model.groupedLinkLayout == Horizontal
            , enabled = True
            , name = "grouped-results"
            , onInput = GroupedLinkLayoutChanged Horizontal
            , text = "Horizontal"
            }
        , viewRadioButton
            { checked = model.groupedLinkLayout == Vertical
            , enabled = True
            , name = "grouped-results"
            , onInput = GroupedLinkLayoutChanged Vertical
            , text = "Vertical"
            }
        , viewRadioButton
            { checked = model.groupedLinkLayout == VerticalWithSummary
            , enabled = True
            , name = "grouped-results"
            , onInput = GroupedLinkLayoutChanged VerticalWithSummary
            , text = "Vertical with summary"
            }
        ]
        , viewCheckbox
            { checked = model.groupedShowPfs
            , onCheck = GroupedShowPfsIconChanged
            , text = "Show PFS icons"
            }
    ]


viewSortResults : Model -> SearchModel -> List (Html Msg)
viewSortResults model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        ]
        [ Html.div
            [ HA.class "column"
            , HA.class "gap-tiny"
            , HA.class "grow"
            , HA.style "flex-basis" "400px"
            ]
            [ Html.div
                []
                [ Html.text "Selected fields" ]
            , Html.div
                [ HA.class "scrollbox"
                , HA.class "column"
                , HA.class "gap-small"
                ]
                (List.indexedMap
                    (\index ( field, dir ) ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            , HA.class "align-center"
                            ]
                            [ Html.button
                                [ HE.onClick (SortRemoved field)
                                ]
                                [ FontAwesome.view FontAwesome.Solid.times
                                ]
                            , Html.button
                                [ HE.onClick (SortAdded field (if dir == Asc then Desc else Asc))
                                ]
                                [ getSortIcon field (Just dir)
                                ]
                            , Html.button
                                [ HA.disabled (index == 0)
                                , HE.onClick (SortOrderChanged index (index - 1))
                                ]
                                [ FontAwesome.view FontAwesome.Solid.chevronUp
                                ]
                            , Html.button
                                [ HA.disabled (index + 1 == List.length searchModel.sort)
                                , HE.onClick (SortOrderChanged index (index + 1))
                                ]
                                [ FontAwesome.view FontAwesome.Solid.chevronDown
                                ]
                            , Html.text (sortFieldToLabel field)
                            ]
                    )
                    searchModel.sort
                )
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "gap-tiny"
            , HA.class "grow"
            , HA.style "flex-basis" "400px"
            ]
            [ Html.div
                []
                [ Html.text "Available fields" ]
            , Html.div
                [ HA.class "scrollbox"
                , HA.class "column"
                , HA.class "gap-small"
                ]
                (List.map
                    (viewSortResultsField searchModel)
                    (Data.sortFields
                        |> List.map Tuple3.first
                        |> List.filter (not << String.contains ".")
                        |> List.append [ "resistance", "speed", "weakness" ]
                        |> List.sort
                    )
                )
            ]
        ]
    , Html.div
        []
        [ Html.text "Predefined sort configurations" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        (List.map
            (\{ fields, label } ->
                Html.button
                    [ HE.onClick (SortSetChosen fields)
                    ]
                    [ Html.text label ]
            )
            [ { fields = [ ( "level", Asc ), ( "name", Asc ) ]
              , label = "Level + Name"
              }
            , { fields = [ ( "type", Asc ), ( "name", Asc ) ]
              , label = "Type + Name"
              }
            ]
        )
    ]


viewSortResultsField : SearchModel -> String -> Html Msg
viewSortResultsField searchModel field =
    case field of
        "resistance" ->
            viewSortResultsFieldWithSelect
                searchModel
                { field = field
                , onInput = SortResistanceChanged
                , selected = searchModel.selectedSortResistance
                , types = Data.damageTypes
                }

        "speed" ->
            viewSortResultsFieldWithSelect
                searchModel
                { field = field
                , onInput = SortSpeedChanged
                , selected = searchModel.selectedSortSpeed
                , types = Data.speedTypes
                }

        "weakness" ->
            viewSortResultsFieldWithSelect
                searchModel
                { field = field
                , onInput = SortWeaknessChanged
                , selected = searchModel.selectedSortWeakness
                , types = Data.damageTypes
                }

        _ ->
            Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                ]
                (List.append
                    (viewSortButtons searchModel field)
                    [ Html.text (String.Extra.humanize field)
                    ]
                )


viewSortResultsFieldWithSelect :
    SearchModel
    -> { field : String
       , onInput : String -> Msg
       , selected : String
       , types : List String
       }
    -> Html Msg
viewSortResultsFieldWithSelect searchModel { field, onInput, selected, types } =
    let
        fieldWithType : String
        fieldWithType =
            field ++ "." ++ selected
    in
    Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        , HA.class "align-center"
        ]
        (List.append
            (viewSortButtons searchModel fieldWithType)
            [ Html.select
                [ HA.class "input-container"
                , HA.value selected
                , HE.onInput onInput
                ]
                (List.map
                    (\type_ ->
                        Html.option
                            [ HA.value type_ ]
                            [ Html.text (String.Extra.humanize type_) ]
                    )
                    types
                )
            , Html.text field
            ]
        )


viewSortButtons : SearchModel -> String -> List (Html Msg)
viewSortButtons searchModel field =
    [ Html.button
        [ HE.onClick
            (if List.member ( field, Asc ) searchModel.sort then
                (SortRemoved field)

             else
                (SortAdded field Asc)
            )
        , HAE.attributeIf (List.member ( field, Asc ) searchModel.sort) (HA.class "active")
        , HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ Html.text "Asc"
        , getSortIcon field (Just Asc)
        ]
    , Html.button
        [ HE.onClick
            (if List.member ( field, Desc ) searchModel.sort then
                (SortRemoved field)

             else
                (SortAdded field Desc)
            )
        , HAE.attributeIf (List.member ( field, Desc ) searchModel.sort) (HA.class "active")
        , HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ Html.text "Desc"
        , getSortIcon field (Just Desc)
        ]
    ]


viewFilterIcon : Maybe Bool -> Html msg
viewFilterIcon value =
    case value of
        Just True ->
            Html.div
                [ HA.style "color" "#00cc00"
                ]
                [ FontAwesome.view FontAwesome.Solid.checkCircle ]

        Just False ->
            Html.div
                [ HA.style "color" "#dd0000"
                ]
                [ FontAwesome.view FontAwesome.Solid.minusCircle ]

        Nothing ->
            Html.div
                []
                [ FontAwesome.view FontAwesome.Regular.circle ]


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


viewRadioButton : { checked : Bool, enabled : Bool, name : String, onInput : msg, text : String } -> Html msg
viewRadioButton { checked, enabled, name, onInput, text } =
    Html.label
        [ HA.class "row"
        , HA.class "align-baseline"
        ]
        [ Html.input
            [ HA.type_ "radio"
            , HA.checked checked
            , HA.disabled (not enabled)
            , HA.name name
            , HE.onClick onInput
            ]
            []
        , Html.div
            []
            [ Html.text text ]
        ]



viewSearchResults : Model -> SearchModel -> Html Msg
viewSearchResults model searchModel =
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
                |> List.map Result.toMaybe
                |> List.map (Maybe.map .hits)
                |> List.map (Maybe.map List.length)
                |> List.map (Maybe.withDefault 0)
                |> List.sum

        remaining : Int
        remaining =
            Maybe.withDefault 0 total - resultCount
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        , HA.class "align-center"
        , HA.style "align-self" "stretch"
        , HA.style "min-height" "90vh"
        , HA.style "padding-bottom" "8px"
        ]
        (List.concat
            [ [ Html.div
                    [ HA.class "limit-width"
                    , HA.class "fill-width-with-padding"
                    , HA.class "fade-in"
                    ]
                    [ case total of
                        Just count ->
                            Html.text ("Showing " ++ String.fromInt resultCount ++ " of " ++ String.fromInt count ++ " results")

                        _ ->
                            Html.text ""
                    ]
              ]

            , case searchModel.resultDisplay of
                List ->
                    viewSearchResultsList model searchModel remaining resultCount

                Table ->
                    viewSearchResultsTable model searchModel remaining

                Grouped ->
                    viewSearchResultsGrouped model searchModel remaining
            ]
        )


viewLoadMoreButtons : Model -> Int -> Html Msg
viewLoadMoreButtons model remaining =
    Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        , HA.style "justify-content" "center"
        ]
        [ if remaining > model.pageSize then
            Html.button
                [ HE.onClick (LoadMorePressed model.pageSize)
                ]
                [ Html.text ("Load " ++ String.fromInt model.pageSize ++ " more") ]

          else
            Html.text ""

        , if remaining > 0 && remaining <= 10000 then
            Html.button
                [ HE.onClick (LoadMorePressed 10000)
                ]
                [ Html.text ("Load remaining " ++ String.fromInt remaining) ]

          else
            Html.text ""
        ]


viewSearchResultsList : Model -> SearchModel -> Int -> Int -> List (Html Msg)
viewSearchResultsList model searchModel remaining resultCount =
    [ List.concatMap
        (\result ->
            case result of
                Ok r ->
                    List.map (viewSingleSearchResult model) r.hits

                Err err ->
                    [ Html.h2
                        []
                        [ Html.text (httpErrorToString err) ]
                    ]
        )
        searchModel.searchResults

    , if Maybe.Extra.isJust searchModel.tracker then
        [ Html.div
            [ HA.class "loader"
            ]
            []
        ]

      else
        [ viewLoadMoreButtons model remaining ]

    , if resultCount > 0 then
        [ Html.button
            [ HE.onClick ScrollToTopPressed
            ]
            [ Html.text "Scroll to top" ]
        ]

      else
        []
    ]
        |> List.concat


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
        , HA.class "limit-width"
        , HA.class "fill-width-with-padding"
        , HA.class "fade-in"
        ]
        [ Html.h2
            [ HA.class "title" ]
            [ Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                , HA.class "nowrap"
                ]
                [ viewPfsIconWithLink 25 (Maybe.withDefault "" hit.source.pfs)
                , Html.a
                    [ HA.href (getUrl model hit.source)
                    , HAE.attributeIf model.openInNewTab (HA.target "_blank")
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
                [ HA.class "title-type"
                ]
                [ Html.text hit.source.type_
                , case hit.source.level of
                    Just level ->
                        Html.text (" " ++ String.fromInt level)

                    Nothing ->
                        Html.text ""
                ]
            ]

            , Html.div
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                (viewMarkdown model hit.source.searchMarkdown)
        ]


viewSearchResultsTable : Model -> SearchModel -> Int -> List (Html Msg)
viewSearchResultsTable model searchModel remaining =
    [ Html.div
        [ HA.class "fill-width-with-padding"
        , HA.style "transition" "max-width ease-in-out 0.2s"
        , if model.limitTableWidth then
            HA.class  "limit-width"

          else
            HA.style "max-width" "100%"
        ]
        [ Html.div
            [ HA.class "column"
            , HA.class "gap-medium"
            , HA.style "max-height" "95vh"
            , HA.style "overflow" "auto"
            ]
            [ viewSearchResultGrid model searchModel

            , case List.Extra.last searchModel.searchResults of
                Just (Err err) ->
                    Html.h2
                        []
                        [ Html.text (httpErrorToString err) ]

                _ ->
                    Html.text ""

            , if Maybe.Extra.isJust searchModel.tracker then
                Html.div
                    [ HA.class "column"
                    , HA.class "align-center"
                    , HA.style "position" "sticky"
                    , HA.style "left" "0"
                    , HA.style "padding-bottom" "var(--gap-medium)"
                    ]
                    [ Html.div
                        [ HA.class "loader"
                        ]
                        []
                    ]

              else
                Html.div
                    [ HA.class "row"
                    , HA.class "gap-medium"
                    , HA.style "justify-content" "center"
                    , HA.style "position" "sticky"
                    , HA.style "left" "0"
                    , HA.style "padding-bottom" "var(--gap-medium)"
                    ]
                    [ if remaining > model.pageSize then
                        Html.button
                            [ HE.onClick (LoadMorePressed model.pageSize)
                            ]
                            [ Html.text ("Load " ++ String.fromInt model.pageSize ++ " more") ]

                      else
                        Html.text ""

                    , if remaining > 0 && remaining < 10000 then
                        Html.button
                            [ HE.onClick (LoadMorePressed 10000)
                            ]
                            [ Html.text ("Load remaining " ++ String.fromInt remaining) ]

                      else
                        Html.text ""
                    ]
            ]
        ]
    ]


viewSearchResultGrid : Model -> SearchModel -> Html Msg
viewSearchResultGrid model searchModel =
    Html.table
        []
        [ Html.thead
            []
            [ Html.tr
                []
                (List.map
                    (\column ->
                        Html.th
                            (if column == "name" then
                                [ HA.class "sticky-left"
                                , HA.style "z-index" "1"
                                ]
                             else
                                []
                            )
                            [ if List.any (Tuple3.first >> (==) column) Data.sortFields then
                                Html.button
                                    [ HA.class "row"
                                    , HA.class "gap-small"
                                    , HA.class "nowrap"
                                    , HA.class "align-center"
                                    , HA.style "justify-content" "space-between"
                                    , HE.onClick (SortToggled column)
                                    ]
                                    [ Html.div
                                        []
                                        [ Html.text (sortFieldToLabel column)
                                        ]
                                    , getSortIcon
                                        column
                                        (searchModel.sort
                                            |> List.Extra.find (Tuple.first >> (==) column)
                                            |> Maybe.map Tuple.second
                                        )
                                    ]

                              else
                                Html.text (sortFieldToLabel column)
                            ]
                    )
                    ("name" :: searchModel.tableColumns)
                )
            ]
        , Html.tbody
            []
            (List.map
                (\result ->
                    case result of
                        Ok r ->
                            List.map
                                (\hit ->
                                    Html.tr
                                        []
                                        (List.map
                                            (viewSearchResultGridCell model hit)
                                            ("name" :: searchModel.tableColumns)
                                        )
                                )
                                r.hits

                        Err _ ->
                            []
                )
                searchModel.searchResults
                |> List.concat
            )
        ]


viewSearchResultGridCell : Model -> Hit Document -> String -> Html msg
viewSearchResultGridCell model hit column =
    let
        maybeAsMarkdown : Maybe String -> List (Html msg)
        maybeAsMarkdown maybeString =
            maybeString
                |> Maybe.withDefault ""
                |> parseAndViewAsMarkdown model
    in
    Html.td
        [ HAE.attributeIf (column == "name") (HA.class "sticky-left")
        ]
        (case String.split "." column of
            [ "ability" ] ->
                hit.source.abilities
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "ability_boost" ] ->
                hit.source.abilities
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "ability_flaw" ] ->
                hit.source.abilityFlaws
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "ability_type" ] ->
                maybeAsText hit.source.abilityType

            [ "ac" ] ->
                hit.source.ac
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "actions" ] ->
                hit.source.actions
                    |> Maybe.withDefault ""
                    |> viewTextWithActionIcons
                    |> List.singleton

            [ "advanced_apocryphal_spell" ] ->
                maybeAsMarkdown hit.source.advancedApocryphalSpell

            [ "advanced_domain_spell" ] ->
                maybeAsMarkdown hit.source.advancedDomainSpell

            [ "alignment" ] ->
                maybeAsText hit.source.alignment

            [ "apocryphal_spell" ] ->
                maybeAsMarkdown hit.source.apocryphalSpell

            [ "archetype" ] ->
                maybeAsText hit.source.archetype

            [ "area" ] ->
                maybeAsText hit.source.area

            [ "armor_category" ] ->
                maybeAsText hit.source.armorCategory

            [ "armor_group" ] ->
                maybeAsMarkdown hit.source.armorGroup

            [ "aspect" ] ->
                hit.source.aspect
                    |> Maybe.map String.Extra.toTitleCase
                    |> maybeAsText

            [ "attack_proficiency" ] ->
                [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    (List.map
                        (\prof ->
                            Html.p
                                []
                                [ Html.text prof ]
                        )
                        hit.source.attackProficiencies
                    )
                ]

            [ "base_item" ] ->
                maybeAsMarkdown hit.source.baseItems

            [ "bloodline" ] ->
                maybeAsMarkdown hit.source.bloodlines

            [ "bulk" ] ->
                maybeAsText hit.source.bulk

            [ "charisma" ] ->
                hit.source.charisma
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "check_penalty" ] ->
                hit.source.checkPenalty
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "creature_family" ] ->
                maybeAsMarkdown hit.source.creatureFamilyMarkdown

            [ "complexity" ] ->
                maybeAsText hit.source.complexity

            [ "component" ] ->
                hit.source.components
                    |> List.map String.Extra.toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "constitution" ] ->
                hit.source.constitution
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "cost" ] ->
                maybeAsMarkdown hit.source.cost

            [ "deity" ] ->
                maybeAsMarkdown hit.source.deities

            [ "deity_category" ] ->
                maybeAsText hit.source.deityCategory

            [ "damage" ] ->
                maybeAsText hit.source.damage

            [ "defense_proficiency" ] ->
                [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    (List.map
                        (\prof ->
                            Html.p
                                []
                                [ Html.text prof ]
                        )
                        hit.source.defenseProficiencies
                    )
                ]

            [ "dexterity" ] ->
                hit.source.dexterity
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "dex_cap" ] ->
                hit.source.dexCap
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "divine_font" ] ->
                hit.source.divineFonts
                    |> List.map String.Extra.toTitleCase
                    |> String.join " or "
                    |> Html.text
                    |> List.singleton

            [ "domain" ] ->
                maybeAsMarkdown hit.source.domains

            [ "domain_spell" ] ->
                maybeAsMarkdown hit.source.domainSpell

            [ "duration" ] ->
                maybeAsText hit.source.duration

            [ "favored_weapon" ] ->
                maybeAsMarkdown hit.source.favoredWeapons

            [ "feat" ] ->
                maybeAsMarkdown hit.source.feats

            [ "follower_alignment" ] ->
                hit.source.followerAlignments
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "fortitude" ] ->
                hit.source.fort
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "fortitude_proficiency" ] ->
                maybeAsText hit.source.fortitudeProficiency

            [ "frequency" ] ->
                maybeAsText hit.source.frequency

            [ "hands" ] ->
                maybeAsText hit.source.hands

            [ "hardness" ] ->
                maybeAsText hit.source.hardness

            [ "hazard_type" ] ->
                maybeAsText hit.source.hazardType

            [ "heighten" ] ->
                hit.source.heighten
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "heighten_level" ] ->
                hit.source.heightenLevels
                    |> List.map String.fromInt
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "hp" ] ->
                maybeAsText hit.source.hp

            [ "icon_image" ] ->
                case hit.source.iconImage of
                    Just image ->
                        [ Html.div
                            [ HA.class "column"
                            , HA.class "align-center"
                            ]
                            [ Html.img
                                [ HA.src image
                                , HA.width 64
                                ]
                                []
                            ]
                        ]

                    Nothing ->
                        []

            [ "image" ] ->
                case hit.source.images of
                    [] ->
                        []

                    images ->
                        [ Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            , HA.style "justify-content" "center"
                            ]
                            (List.map
                                (\image ->
                                    Html.a
                                        [ HA.href image
                                        , HA.target "_blank"
                                        ]
                                        [ Html.img
                                            [ HA.src image
                                            , HA.width 96
                                            ]
                                            []
                                        ]
                                )
                                images
                            )
                        ]

            [ "immunity" ] ->
                maybeAsMarkdown hit.source.immunities

            [ "intelligence" ] ->
                hit.source.intelligence
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "item_category" ] ->
                maybeAsText hit.source.itemCategory

            [ "item_subcategory" ] ->
                maybeAsText hit.source.itemSubcategory

            [ "language" ] ->
                maybeAsMarkdown hit.source.languages

            [ "lesson" ] ->
                maybeAsMarkdown hit.source.lessons

            [ "level" ] ->
                hit.source.level
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "mystery" ] ->
                maybeAsMarkdown hit.source.mysteries

            [ "name" ] ->
                [ Html.a
                    [ HA.href (getUrl model hit.source)
                    , HAE.attributeIf model.openInNewTab (HA.target "_blank")
                    ]
                    [ Html.text hit.source.name
                    ]
                ]

            [ "onset" ] ->
                maybeAsText hit.source.onset

            [ "patron_theme" ] ->
                maybeAsMarkdown hit.source.patronThemes

            [ "perception" ] ->
                hit.source.perception
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "perception_proficiency" ] ->
                maybeAsText hit.source.perceptionProficiency

            [ "pfs" ] ->
                hit.source.pfs
                    |> Maybe.withDefault ""
                    |> viewPfsIconWithLink 20
                    |> List.singleton
                    |> Html.div
                        [ HA.class "column"
                        , HA.class "align-center"
                        ]
                    |> List.singleton

            [ "plane_category" ] ->
                maybeAsText hit.source.planeCategory

            [ "prerequisite" ] ->
                maybeAsMarkdown hit.source.prerequisites

            [ "price" ] ->
                maybeAsText hit.source.price

            [ "primary_check" ] ->
                maybeAsMarkdown hit.source.primaryCheck

            [ "range" ] ->
                maybeAsText hit.source.range

            [ "rarity" ] ->
                hit.source.rarity
                    |> Maybe.map (String.Extra.toTitleCase)
                    |> maybeAsText

            [ "reflex" ] ->
                hit.source.ref
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "reflex_proficiency" ] ->
                maybeAsText hit.source.reflexProficiency

            [ "region" ] ->
                maybeAsText hit.source.region

            [ "release_date" ] ->
                maybeAsText hit.source.releaseDate

            [ "reload" ] ->
                maybeAsText hit.source.reload

            [ "requirement" ] ->
                maybeAsMarkdown hit.source.requirements

            [ "resistance" ] ->
                maybeAsMarkdown hit.source.resistances

            [ "resistance", type_ ] ->
                hit.source.resistanceValues
                    |> Maybe.andThen (getDamageTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "saving_throw" ] ->
                maybeAsMarkdown hit.source.savingThrow

            [ "school" ] ->
                hit.source.school
                    |> Maybe.map (String.Extra.toTitleCase)
                    |> maybeAsText

            [ "secondary_casters" ] ->
                maybeAsText hit.source.secondaryCasters

            [ "secondary_check" ] ->
                maybeAsMarkdown hit.source.secondaryChecks

            [ "sense" ] ->
                maybeAsMarkdown hit.source.senses

            [ "size" ] ->
                hit.source.sizes
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "skill" ] ->
                maybeAsMarkdown hit.source.skills

            [ "skill_proficiency" ] ->
                [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    ]
                    (List.map
                        (\prof ->
                            Html.p
                                []
                                [ Html.text prof ]
                        )
                        hit.source.skillProficiencies
                    )
                ]

            [ "source" ] ->
                maybeAsMarkdown hit.source.sources

            [ "source_category" ] ->
                maybeAsText hit.source.sourceCategory

            [ "source_group" ] ->
                maybeAsText hit.source.sourceGroup

            [ "speed" ] ->
                maybeAsMarkdown hit.source.speed

            [ "speed", type_ ] ->
                hit.source.speedValues
                    |> Maybe.andThen (getSpeedTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "speed_penalty" ] ->
                maybeAsText hit.source.speedPenalty

            [ "spoilers" ] ->
                maybeAsText hit.source.spoilers

            [ "stage" ] ->
                maybeAsMarkdown hit.source.stages

            [ "strength" ] ->
                hit.source.strength
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "strongest_save" ] ->
                hit.source.strongestSaves
                    |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                    |> List.map String.Extra.toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "summary" ] ->
                maybeAsMarkdown hit.source.summary

            [ "target" ] ->
                maybeAsMarkdown hit.source.targets

            [ "tradition" ] ->
                maybeAsMarkdown hit.source.traditions

            [ "trait" ] ->
                maybeAsMarkdown hit.source.traits

            [ "trigger" ] ->
                maybeAsMarkdown hit.source.trigger

            [ "type" ] ->
                [ Html.text hit.source.type_ ]

            [ "usage" ] ->
                maybeAsMarkdown hit.source.usage

            [ "vision" ] ->
                maybeAsText hit.source.vision

            [ "weapon_category" ] ->
                maybeAsText hit.source.weaponCategory

            [ "weapon_group" ] ->
                maybeAsMarkdown hit.source.weaponGroupMarkdown

            [ "weapon_type" ] ->
                maybeAsText hit.source.weaponType

            [ "weakest_save" ] ->
                hit.source.weakestSaves
                    |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                    |> List.map String.Extra.toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "weakness" ] ->
                maybeAsMarkdown hit.source.weaknesses

            [ "weakness", type_ ] ->
                hit.source.weaknessValues
                    |> Maybe.andThen (getDamageTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "will" ] ->
                hit.source.will
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "will_proficiency" ] ->
                maybeAsText hit.source.willProficiency

            [ "wisdom" ] ->
                hit.source.wisdom
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            _ ->
                []
        )


maybeAsText : Maybe String -> List (Html msg)
maybeAsText maybeString =
    maybeString
        |> Maybe.withDefault ""
        |> Html.text
        |> List.singleton


viewSearchResultsGrouped : Model -> SearchModel -> Int -> List (Html Msg)
viewSearchResultsGrouped model searchModel remaining =
    let
        allHits : List (Hit Document)
        allHits =
            searchModel.searchResults
                |> List.concatMap (Result.map .hits >> Result.withDefault [])

        keys : List String
        keys =
            searchModel.searchResultGroupAggs
                |> Maybe.map .group1
                |> Maybe.withDefault []
                |> List.map .key1
                |> List.map (Maybe.withDefault "")

        counts : Dict String Int
        counts =
            searchModel.searchResultGroupAggs
                |> Maybe.map .group1
                |> Maybe.withDefault []
                |> List.map
                    (\agg ->
                        ( Maybe.withDefault "" agg.key1, agg.count )
                    )
                |> Dict.fromList

    in
    [ if Maybe.Extra.isJust searchModel.tracker || searchModel.searchResultGroupAggs == Nothing then
        Html.div
            [ HA.class "loader"
            ]
            []

      else
        viewLoadMoreButtons model remaining

    , Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        , HA.class "limit-width"
        , HA.class "fill-width-with-padding"
        ]
        (List.map
            (\( key1, hits1 ) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length hits1 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h2
                        [ HA.class "title" ]
                        [ Html.div
                            []
                            [ viewGroupedTitle searchModel.groupField1 key1
                            ]
                        , Html.div
                            []
                            [ Html.text (String.fromInt (List.length hits1))
                            , Html.text "/"
                            , Html.text
                                (Dict.get key1 counts
                                    |> Maybe.withDefault 0
                                    |> String.fromInt
                                )
                            ]
                        ]

                    , case searchModel.groupField2 of
                        Just field2 ->
                            viewSearchResultsGroupedLevel2 model searchModel key1 field2 hits1

                        Nothing ->
                            viewSearchResultsGroupedLinkList model hits1
                    ]
            )
            (if searchModel.searchResultGroupAggs == Nothing then
                []

             else
                groupDocumentsByField keys searchModel.groupField1 allHits
                    |> Dict.toList
                    |> sortGroupedList model "" counts
            )
        )
    ]


viewSearchResultsGroupedLevel2 : Model -> SearchModel -> String -> String -> List (Hit Document) -> Html Msg
viewSearchResultsGroupedLevel2 model searchModel key1 field2 hits1 =
    let
        keys : List String
        keys =
            searchModel.searchResultGroupAggs
                |> Maybe.andThen .group2
                |> Maybe.withDefault []
                |> List.filter
                    (\agg ->
                        agg.key1 == Just key1
                    )
                |> List.map .key2
                |> List.map (Maybe.withDefault "")

        counts : Dict String Int
        counts =
            searchModel.searchResultGroupAggs
                |> Maybe.andThen .group2
                |> Maybe.withDefault []
                |> List.map
                    (\agg ->
                        ( Maybe.withDefault "" agg.key1
                            ++ "--"
                            ++ Maybe.withDefault "" agg.key2
                        , agg.count
                        )
                    )
                |> Dict.fromList
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        ]
        (List.map
            (\( key2, hits2 ) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length hits2 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h3
                        [ HA.class "subtitle" ]
                        [ Html.div
                            []
                            [ viewGroupedTitle field2 key2
                            ]
                        , Html.div
                            []
                            [ Html.text (String.fromInt (List.length hits2))
                            , Html.text "/"
                            , Html.text
                                (Dict.get (key1 ++ "--" ++ key2) counts
                                    |> Maybe.withDefault 0
                                    |> String.fromInt
                                )
                            ]
                        ]
                    , case searchModel.groupField3 of
                        Just field3 ->
                            viewSearchResultsGroupedLevel3 model searchModel key1 key2 field3 hits2

                        Nothing ->
                            viewSearchResultsGroupedLinkList model hits2
                    ]
            )
            (groupDocumentsByField keys field2 hits1
                |> Dict.toList
                |> sortGroupedList model (key1 ++ "--") counts
            )
        )


viewSearchResultsGroupedLevel3 : Model -> SearchModel -> String -> String -> String -> List (Hit Document) -> Html Msg
viewSearchResultsGroupedLevel3 model searchModel key1 key2 field3 hits2 =
    let
        keys : List String
        keys =
            searchModel.searchResultGroupAggs
                |> Maybe.andThen .group3
                |> Maybe.withDefault []
                |> List.filter
                    (\agg ->
                        agg.key1 == Just key1
                        && agg.key2 == Just key2
                    )
                |> List.map .key3
                |> List.map (Maybe.withDefault "")

        counts : Dict String Int
        counts =
            searchModel.searchResultGroupAggs
                |> Maybe.andThen .group3
                |> Maybe.withDefault []
                |> List.map
                    (\agg ->
                        ( Maybe.withDefault "" agg.key1
                            ++ "--"
                            ++ Maybe.withDefault "" agg.key2
                            ++ "--"
                            ++ Maybe.withDefault "" agg.key3
                        , agg.count
                        )
                    )
                |> Dict.fromList
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        ]
        (List.map
            (\( key3, hits3 ) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length hits3 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h4
                        [ HA.class "subtitle"
                        , HA.style "background-color" "var(--color-subsubelement-bg)"
                        , HA.style "color" "var(--color-subsubelement-text)"
                        , HA.style "border-radius" "4px"
                        , HA.style "line-height" "16px"
                        ]
                        [ Html.div
                            []
                            [ viewGroupedTitle field3 key3
                            ]
                        , Html.div
                            []
                            [ Html.text (String.fromInt (List.length hits3))
                            , Html.text "/"
                            , Html.text
                                (Dict.get (key1 ++ "--" ++ key2 ++ "--" ++ key3) counts
                                    |> Maybe.withDefault 0
                                    |> String.fromInt
                                )
                            ]
                        ]
                    , viewSearchResultsGroupedLinkList model hits3
                    ]
            )
            (groupDocumentsByField keys field3 hits2
                |> Dict.toList
                |> sortGroupedList model (key1 ++ "--" ++ key2 ++ "--") counts
            )
        )


viewSearchResultsGroupedLinkList : Model -> List (Hit Document) -> Html msg
viewSearchResultsGroupedLinkList model hits =
    let
        sortedHits : List (Hit Document)
        sortedHits =
            List.sortBy (.source >> .name) hits
    in
    case model.groupedLinkLayout of
        Horizontal ->
            Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                ]
                (List.map
                    (\hit ->
                        if model.groupedShowPfs then
                            Html.div
                                [ HA.class "row"
                                , HA.class "gap-tiny"
                                ]
                                [ hit.source.pfs
                                    |> Maybe.withDefault ""
                                    |> viewPfsIcon 0
                                , Html.a
                                    [ HA.href (getUrl model hit.source) ]
                                    [ Html.text hit.source.name ]
                                ]

                        else
                            Html.a
                                [ HA.href (getUrl model hit.source) ]
                                [ Html.text hit.source.name ]
                    )
                    sortedHits
                )

        Vertical ->
            Html.div
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                (List.map
                    (\hit ->
                        if model.groupedShowPfs then
                            Html.div
                                [ HA.class "row"
                                , HA.class "gap-tiny"
                                ]
                                [ hit.source.pfs
                                    |> Maybe.withDefault ""
                                    |> viewPfsIcon 0
                                , Html.a
                                    [ HA.href (getUrl model hit.source) ]
                                    [ Html.text hit.source.name ]
                                ]

                        else
                            Html.a
                                [ HA.href (getUrl model hit.source) ]
                                [ Html.text hit.source.name ]
                    )
                    sortedHits
                )

        VerticalWithSummary ->
            Html.div
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                (List.map
                    (\hit ->
                        Html.div
                            [ HA.class "inline" ]
                            (List.append
                                (if model.groupedShowPfs then
                                    [ hit.source.pfs
                                        |> Maybe.withDefault ""
                                        |> viewPfsIcon 0
                                    , Html.text " "
                                    , Html.a
                                        [ HA.href (getUrl model hit.source) ]
                                        [ Html.text hit.source.name ]
                                    ]

                                else
                                    [ Html.a
                                        [ HA.href (getUrl model hit.source) ]
                                        [ Html.text hit.source.name ]
                                    ]

                                )
                                (case hit.source.summary of
                                    Just summary ->
                                        List.append
                                            [ Html.text " - " ]
                                            (parseAndViewAsMarkdown model summary)

                                    Nothing ->
                                        []
                                )
                            )
                    )
                    sortedHits
                )


groupedDisplayAttribute : Model -> Html.Attribute msg
groupedDisplayAttribute model =
    case model.groupedDisplay of
        Show ->
            HAE.empty

        Dim ->
            HA.class "dim"

        Hide ->
            HA.style "display" "none"


groupDocumentsByField : List String -> String -> List (Hit Document) -> Dict String (List (Hit Document))
groupDocumentsByField keys field hits =
    List.foldl
        (\hit dict ->
            case field of
                "ability" ->
                    if List.isEmpty hit.source.abilities then
                        insertToListDict "" hit dict

                    else
                        List.foldl
                            (\ability ->
                                insertToListDict (String.toLower ability) hit
                            )
                            dict
                            (List.Extra.unique hit.source.abilities)

                "actions" ->
                    insertToListDict
                        (hit.source.actions
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "alignment" ->
                    insertToListDict
                        (hit.source.alignment
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "creature_family" ->
                    insertToListDict
                        (hit.source.creatureFamily
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "duration" ->
                    insertToListDict
                        (hit.source.durationValue
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        hit
                        dict

                "heighten_level" ->
                    if List.isEmpty hit.source.heightenLevels then
                        insertToListDict "" hit dict

                    else
                        List.foldl
                            (\level ->
                                insertToListDict (String.fromInt level) hit
                            )
                            dict
                            hit.source.heightenLevels

                "item_category" ->
                    insertToListDict
                        (hit.source.itemCategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "item_subcategory" ->
                    insertToListDict
                        (hit.source.itemSubcategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "level" ->
                    insertToListDict
                        (hit.source.level
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        hit
                        dict

                "pfs" ->
                    insertToListDict
                        (hit.source.pfs
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "range" ->
                    insertToListDict
                        (hit.source.rangeValue
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        hit
                        dict

                "rarity" ->
                    insertToListDict
                        (hit.source.rarity
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "school" ->
                    insertToListDict
                        (hit.source.school
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "size" ->
                    if List.isEmpty hit.source.sizes then
                        insertToListDict "" hit dict

                    else
                        List.foldl
                            (\size ->
                                insertToListDict (String.toLower size) hit
                            )
                            dict
                            hit.source.sizes

                "source" ->
                    List.foldl
                        (\source ->
                            insertToListDict (String.toLower source) hit
                        )
                        dict
                        hit.source.sourceList

                "tradition" ->
                    if List.isEmpty hit.source.traditionList then
                        insertToListDict "" hit dict

                    else
                        List.foldl
                            (\tradition ->
                                insertToListDict (String.toLower tradition) hit
                            )
                            dict
                            hit.source.traditionList

                "trait" ->
                    if List.isEmpty hit.source.traitList then
                        insertToListDict "" hit dict

                    else
                        List.foldl
                            (\trait ->
                                insertToListDict (String.toLower trait) hit
                            )
                            dict
                            hit.source.traitList

                "type" ->
                    insertToListDict (String.toLower hit.source.type_) hit dict

                "weapon_category" ->
                    insertToListDict
                        (hit.source.weaponCategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "weapon_group" ->
                    insertToListDict
                        (hit.source.weaponGroup
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                "weapon_type" ->
                    insertToListDict
                        (hit.source.weaponType
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        hit
                        dict

                _ ->
                    dict
        )
        (keys
            |> List.map (\key -> ( key, [] ))
            |> Dict.fromList
        )
        hits


sortGroupedList : Model -> String -> Dict String Int -> List ( String, List a ) -> List ( String, List a )
sortGroupedList model keyPrefix counts list =
    List.sortWith
        (\( k1, v1 ) ( k2, v2 ) ->
            case model.groupedSort of
                Alphanum ->
                    case ( List.length v1, List.length v2 ) of
                        ( 0, 0 ) ->
                            case ( k1, k2 ) of
                                ( "", _ ) ->
                                    GT

                                ( _, "" ) ->
                                    LT

                                _ ->
                                    Maybe.map2 compare (String.toInt k1) (String.toInt k2)
                                        |> Maybe.withDefault (compare k1 k2)

                        ( 0, _ ) ->
                            GT

                        ( _, 0 ) ->
                            LT

                        _ ->
                            case ( k1, k2 ) of
                                ( "", _ ) ->
                                    GT

                                ( _, "" ) ->
                                    LT

                                _ ->
                                    Maybe.map2 compare (String.toInt k1) (String.toInt k2)
                                        |> Maybe.withDefault (compare k1 k2)

                CountLoaded ->
                    compare (List.length v2) (List.length v1)

                CountTotal ->
                    compare
                        (Dict.get (keyPrefix ++ k2) counts
                            |> Maybe.withDefault 0
                        )
                        (Dict.get (keyPrefix ++ k1) counts
                            |> Maybe.withDefault 0
                        )
        )
        list


viewGroupedTitle : String -> String -> Html msg
viewGroupedTitle field value =
    if value == "" then
        Html.text "N/A"

    else if field == "actions.keyword" then
        viewTextWithActionIcons value

    else if field == "alignment" then
        Html.text
            (Dict.fromList Data.alignments
                |> Dict.get value
                |> Maybe.withDefault value
                |> String.Extra.toTitleCase
            )

    else if field == "duration" then
        case String.toInt value of
            Just duration ->
                Html.text (durationToString duration)

            Nothing ->
                Html.text value

    else if field == "heighten_level" then
        Html.text ("Level " ++ value)

    else if field == "level" then
        Html.text ("Level " ++ value)

    else if field == "pfs" then
        Html.div
            [ HA.class "row"
            , HA.class "gap-small"
            , HA.class "align-center"
            ]
            [ viewPfsIcon 0 value
            , Html.text (String.Extra.toTitleCase value)
            ]

    else if field == "range" then
        case String.toInt value of
            Just range ->
                Html.text (rangeToString range)

            Nothing ->
                Html.text value

    else
        Html.text (toTitleCase value)


insertToListDict : comparable -> a -> Dict comparable (List a) -> Dict comparable (List a)
insertToListDict key value dict =
    Dict.update
        key
        (\maybeList ->
            maybeList
                |> Maybe.withDefault []
                |> (::) value
                |> Just
        )
        dict


durationToString : Int -> String
durationToString duration =
    if duration > 60 * 60 * 24 * 365 then
        String.fromInt (duration // (60 * 60 * 24 * 365)) ++ " years"

    else if duration == 60 * 60 * 24 * 365 then
        "1 year"

    else if duration > 60 * 60 * 24 then
        String.fromInt (duration // (60 * 60 * 24)) ++ " days"

    else if duration == 60 * 60 * 24 then
        "1 day"

    else if duration > 60 * 60 then
        String.fromInt (duration // (60 * 60)) ++ " hours"

    else if duration == 60 * 60 then
        "1 hour"

    else if duration > 60 then
        String.fromInt (duration // 60) ++ " minutes"

    else if duration == 60 then
        "1 minute"

    else if duration == 6 then
        "1 round"

    else
        String.fromInt (duration // 6) ++ " rounds"


rangeToString : Int -> String
rangeToString range =
    if range == 100000000 then
        "Unlimited"

    else if range == 10000000 then
        "Planetary"

    else if range > 5280 then
        String.fromInt (range // 5280) ++ " miles"

    else if range == 5280 then
        "1 mile"

    else
        String.fromInt range ++ " feet"


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadBody _ ->
            "Error: Failed to parse response"

        Http.BadStatus 400 ->
            "Error: Failed to parse query"

        Http.BadStatus code ->
            "Error: Failed with HTTP " ++ String.fromInt code

        Http.BadUrl _ ->
            "Error: Invalid URL"

        Http.NetworkError ->
            "Error: Network error"

        Http.Timeout ->
            "Error: Request timed out"


parseAndViewAsMarkdown : Model -> String -> List (Html msg)
parseAndViewAsMarkdown model string =
    if String.isEmpty string then
        []

    else
        string
            |> Markdown.Parser.parse
            |> Result.map (List.map (Markdown.Block.walk mergeInlines))
            |> Result.mapError (List.map Markdown.Parser.deadEndToString)
            |> viewMarkdown model


viewMarkdown : Model -> ParsedMarkdownResult -> List (Html msg)
viewMarkdown model markdown =
    case markdown of
        Ok blocks ->
            case Markdown.Renderer.render (markdownRenderer model) blocks of
                Ok v ->
                        v

                Err err ->
                    [ Html.text err ]

        Err errors ->
            [ Html.div
                [ HA.style "color" "red" ]
                (List.map Html.text errors)
            ]


markdownRenderer : Model -> Markdown.Renderer.Renderer (Html msg)
markdownRenderer model =
    let
        defaultRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defaultRenderer
        | html =
            Markdown.Html.oneOf
                [ Markdown.Html.tag "actions"
                    (\string _ ->
                        viewTextWithActionIcons string
                    )
                    |> Markdown.Html.withAttribute "string"
                , Markdown.Html.tag "additional-info"
                    (\content ->
                        Html.div
                            [ HA.class "column"
                            , HA.class "gap-tiny"
                            , HA.class "additional-info"
                            ]
                            content
                    )
                , Markdown.Html.tag "b"
                    (\content ->
                        Html.span
                            [ HA.style "font-weight" "700" ]
                            content
                    )
                , Markdown.Html.tag "br"
                    (\_ ->
                        Html.br
                            []
                            []
                    )
                , Markdown.Html.tag "center"
                    (\content ->
                        Html.div
                            [ HA.class "column"
                            , HA.class "gap-medium"
                            , HA.class "align-center"
                            ]
                            content
                    )
                , Markdown.Html.tag "spoilers"
                    (\content ->
                        Html.h3
                            [ HA.class "row"
                            , HA.class "subtitle"
                            , HA.class "spoilers"
                            ]
                            content
                    )
                , Markdown.Html.tag "summary"
                    (\content ->
                        Html.div
                            [ HA.class "summary"
                            ]
                            content
                    )
                , Markdown.Html.tag "sup"
                    (\content ->
                        Html.sup
                            []
                            content
                    )
                , Markdown.Html.tag "trait"
                    (\label url _ ->
                        viewTrait url label
                    )
                    |> Markdown.Html.withAttribute "label"
                    |> Markdown.Html.withOptionalAttribute "url"
                , Markdown.Html.tag "traits"
                    (\content ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "traits"
                            ]
                            content
                    )
                , Markdown.Html.tag "ul"
                    (\content ->
                        Html.ul
                            []
                            content
                    )
                , Markdown.Html.tag "row"
                    (\maybeGap content ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "wrap"
                            , HAE.attributeMaybe
                                (\gap -> HA.class ("gap-" ++ gap))
                                maybeGap
                            ]
                            content
                    )
                    |> Markdown.Html.withOptionalAttribute "gap"
                , Markdown.Html.tag "column"
                    (\gap content ->
                        Html.div
                            [ HA.class "column"
                            , HA.class ("gap-" ++ gap)
                            , HA.style "flex" "1"
                            ]
                            content
                    )
                    |> Markdown.Html.withAttribute "gap"
                ]

        , link = \link contents ->
            Html.a
                [ HA.href link.destination
                , HAE.attributeIf model.openInNewTab (HA.target "_blank")
                ]
                contents
    }


getDamageTypeValue : String -> DamageTypeValues -> Maybe Int
getDamageTypeValue type_ values =
    case type_ of
        "acid" ->
            values.acid

        "all" ->
            values.all

        "area" ->
            values.area

        "bleed" ->
            values.bleed

        "bludgeoning" ->
            values.bludgeoning

        "chaotic" ->
            values.chaotic

        "cold" ->
            values.cold

        "cold_iron" ->
            values.coldIron

        "electricity" ->
            values.electricity

        "evil" ->
            values.evil

        "fire" ->
            values.fire

        "force" ->
            values.force

        "good" ->
            values.good

        "lawful" ->
            values.lawful

        "mental" ->
            values.mental

        "negative" ->
            values.negative

        "orichalcum" ->
            values.orichalcum

        "physical" ->
            values.physical

        "piercing" ->
            values.piercing

        "poison" ->
            values.poison

        "positive" ->
            values.positive

        "precision" ->
            values.precision

        "silver" ->
            values.silver

        "slashing" ->
            values.slashing

        "sonic" ->
            values.sonic

        "splash" ->
            values.splash

        _ ->
            Nothing


getSpeedTypeValue : String -> SpeedTypeValues -> Maybe Int
getSpeedTypeValue type_ values =
    case type_ of
        "burrow" ->
            values.burrow

        "climb" ->
            values.climb

        "fly" ->
            values.fly

        "land" ->
            values.land

        "max" ->
            values.max

        "swim" ->
            values.swim

        _ ->
            Nothing


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
            ( "single action", "[one-action]" )
            [ ( "two actions", "[two-actions]" )
            , ( "three actions", "[three-actions]" )
            , ( "reaction", "[reaction]" )
            , ( "free action", "[free-action]" )
            ]
        )


replaceActionLigatures : String -> ( String, String ) -> List ( String, String ) -> List (Html msg)
replaceActionLigatures text ( find, replace ) rem =
    if String.contains find (String.toLower text) then
        case String.split find (String.toLower text) of
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


viewTrait : Maybe String -> String -> Html msg
viewTrait maybeUrl trait =
    Html.div
        [ HA.class "trait"
        , getTraitClass trait
        ]
        [ case maybeUrl of
            Just url ->
                Html.a
                    [ HA.href url
                    , HA.target "_blank"
                    ]
                    [ Html.text trait ]

            Nothing ->
                Html.text trait
        ]


getTraitClass : String -> Html.Attribute msg
getTraitClass trait =
    case String.toLower trait of
        "uncommon" ->
            HA.class "trait-uncommon"

        "rare" ->
            HA.class "trait-rare"

        "unique" ->
            HA.class "trait-unique"

        "tiny" ->
            HA.class "trait-size"

        "small" ->
            HA.class "trait-size"

        "medium" ->
            HA.class "trait-size"

        "large" ->
            HA.class "trait-size"

        "huge" ->
            HA.class "trait-size"

        "gargantuan" ->
            HA.class "trait-size"

        "no alignment" ->
            HA.class "trait-alignment"

        "any" ->
            HA.class "trait-alignment"

        "lg" ->
            HA.class "trait-alignment"

        "ln" ->
            HA.class "trait-alignment"

        "le" ->
            HA.class "trait-alignment"

        "ng" ->
            HA.class "trait-alignment"

        "n" ->
            HA.class "trait-alignment"

        "ne" ->
            HA.class "trait-alignment"

        "cg" ->
            HA.class "trait-alignment"

        "cn" ->
            HA.class "trait-alignment"

        "ce" ->
            HA.class "trait-alignment"

        "all ancestries" ->
            HA.class "trait-aon-special"

        "stamina" ->
            HA.class "trait-aon-special"

        _ ->
            HAE.empty


getSortIcon : String -> Maybe SortDir -> Html msg
getSortIcon field dir =
    case ( dir, List.Extra.find (Tuple3.first >> (==) field) Data.sortFields ) of
        ( Just Asc, Just ( _, _, True ) ) ->
            FontAwesome.view FontAwesome.Solid.sortNumericDown

        ( Just Asc, Just ( _, _, False ) ) ->
            FontAwesome.view FontAwesome.Solid.sortAlphaDown

        ( Just Desc, Just ( _, _, True ) ) ->
            FontAwesome.view FontAwesome.Solid.sortNumericDownAlt

        ( Just Desc, Just ( _, _, False ) ) ->
            FontAwesome.view FontAwesome.Solid.sortAlphaDownAlt

        _ ->
            Html.text ""


viewPfsIcon : Int -> String -> Html msg
viewPfsIcon height pfs =
    case getPfsIconUrl pfs of
        Just url ->
            Html.img
                [ HA.src url
                , if height == 0 then
                    HA.style "height" "1em"

                  else
                    HA.style "height" (String.fromInt height ++ "px")
                ]
                []

        Nothing ->
            Html.text ""


viewPfsIconWithLink : Int -> String -> Html msg
viewPfsIconWithLink height pfs =
    case getPfsIconUrl pfs of
        Just url ->
            Html.a
                [ HA.href "/PFS.aspx"
                , HA.target "_blank"
                ]
                [ Html.img
                    [ HA.src url
                    , HA.style "height" (String.fromInt height ++ "px")
                    ]
                    []
                ]

        Nothing ->
            Html.text ""


getPfsIconUrl : String -> Maybe String
getPfsIconUrl pfs =
    case String.toLower pfs of
        "standard" ->
            Just "/Images/Icons/PFS_Standard.png"

        "limited" ->
            Just "/Images/Icons/PFS_Limited.png"

        "restricted" ->
            Just "/Images/Icons/PFS_Restricted.png"

        _ ->
            Nothing


viewScrollboxLoader : Html msg
viewScrollboxLoader =
    Html.div
        [ HA.class "row"
        , HA.style "height" "72px"
        , HA.style "margin" "auto"
        ]
        [ Html.div
            [ HA.class "loader"
            ]
            []
        ]


queryCouldBeComplex : String -> Bool
queryCouldBeComplex query =
    stringContainsChar query ":()\"+-*?"
        || String.contains " OR " query
        || String.contains " AND " query
        || String.contains " || " query
        || String.contains " && " query


stringContainsChar : String -> String -> Bool
stringContainsChar str chars =
    String.any
        (\char ->
            String.contains (String.fromChar char) str
        )
        chars


toTitleCase : String -> String
toTitleCase str =
    str
        |> String.Extra.toTitleCase
        |> String.replace " In " " in "
        |> String.replace " Of " " of "
        |> String.replace " On " " on "
        |> String.replace " Or " " or "
        |> String.replace " To " " to "
        |> String.replace " The " " the "
        |> String.replace ": the " ": The "
        |> String.replace ", the " ", The "
        |> String.replace "Pfs" "PFS"
        |> String.replace "Gm's " "GM's "


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

    a:hover {
        text-decoration: underline;
    }

    button {
        border-color: var(--color-inactive-text);
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

    button.excluded, button:disabled {
        color: var(--color-inactive-text);
    }

    button:hover:enabled {
        border-color: var(--color-text);
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

    h4 {
        font-size: var(--font-medium);
        margin: 0;
    }

    hr {
        margin: 0;
        width: 100%;
    }

    input[type=text], input[type=number], input[type=date] {
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

    p {
        margin: 0;
    }

    sup > p {
        display: inline-block;
    }

    .inline p {
        display: inline;
    }

    .inline div {
        display: inline;
    }

    select {
        color: var(--color-text);
        font-size: var(--font-normal);
    }

    table {
        border-collapse: separate;
        border-spacing: 0;
        color: var(--color-table-text);
        position: relative;
    }

    tbody tr td {
        background-color: var(--color-table-even);
    }

    tbody tr:nth-child(odd) td {
        background-color: var(--color-table-odd);
    }

    td {
        border-right: 1px solid var(--color-table-text);
        border-bottom: 1px solid var(--color-table-text);
        padding: 4px 12px 4px 4px;
    }

    th {
        background-color: var(--color-element-bg);
        border-top: 1px solid var(--color-table-text);
        border-right: 1px solid var(--color-table-text);
        border-bottom: 1px solid var(--color-table-text);
        color: var(--color-element-text);
        font-variant: small-caps;
        font-size: var(--font-large);
        font-weight: 700;
        padding: 4px 12px 4px 4px;
        position: sticky;
        text-align: start;
        top: 0px;
    }

    th button {
        border: 0;
        color: inherit;
        font-size: inherit;
        font-variant: inherit;
        font-weight: inherit;
        padding: 0;
        text-align: inherit;
    }

    td:first-child, th:first-child {
        border-left: 1px solid var(--color-table-text);
    }

    thead tr {
        background-color: var(--color-element-bg);
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

    .dim {
        opacity: 0.5;
    }

    .dim .dim {
        opacity: inherit;
    }

    .external-link {
        color: var(--color-external-link);
        font-style: italic;
    }

    .fade-in {
        animation: 0.3s fade-in;
    }

    .fill-width-with-padding {
        box-sizing: border-box;
        padding-left: 8px;
        padding-right: 8px;
        width: 100%;
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

    .grow {
        flex-grow: 1;
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
        font-family: "Pathfinder-Icons";
        font-variant-caps: normal;
        font-weight: normal;
    }

    .input-button {
        background-color: transparent;
        border-color: transparent;
        border-width: 1px;
        color: var(--color-text);
    }

    .input-button:hover {
        border-color: inherit;
    }

    .limit-width {
        max-width: 1000px;
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
        max-height: 200px;
        overflow-y: auto;
        padding: 4px;
    }

    .subtitle {
        border-radius: 4px;
        background-color: var(--color-subelement-bg);
        color: var(--color-subelement-text);
        display: flex;
        font-variant: var(--element-font-variant);
        justify-content: space-between;
        line-height: 1rem;
        padding: 4px 9px;
    }

    .subtitle:empty {
        display: none;
    }

    .sticky-left {
        left: 0;
        position: sticky;
    }

    .title {
        border-radius: 4px;
        background-color: var(--color-element-bg);
        border-color: var(--color-container-border);
        color: var(--color-element-text);
        display: flex;
        flex-direction: row;
        font-size: var(--font-very-large);
        font-variant: var(--element-font-variant);
        font-weight: 700;
        gap: var(--gap-small);
        justify-content: space-between;
        padding: 4px 9px;
    }

    .title a, .trait a {
        text-decoration: none;
    }

    .title a:hover, .trait a:hover {
        text-decoration: underline;
    }

    .title-type {
        align-items: center;
        display: flex;
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
        font-variant: var(--element-font-variant);
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

    .trait-aon-special {
        background: linear-gradient(#000, #666);
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

    @keyframes fade-in {
        from {
            opacity: 0;
        }

        to {
            opacity: 1;
        }
    }
    """


cssBlackbird : String
cssBlackbird =
    """
    .body-container {
        color-scheme: dark;
        --color-bg: #21252b;
        --color-bg-secondary: #21252b;
        --color-container-bg: #404859;
        --color-container-border: #ededed;
        --color-element-bg: #404859;
        --color-element-border: #cbc5c3;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #291716;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #656148;
        --color-element-text: #ededed;
        --color-external-link: #a2a4a3;
        --color-subelement-bg: #404859;
        --color-subelement-text: #ededed;
        --color-subsubelement-bg: #404859;
        --color-subsubelement-text: #ededed;
        --color-inactive-text: #999999;
        --color-table-even: #404859;
        --color-table-odd: #21252b;
        --color-table-text: #cbc5c3;
        --color-text: #ededed;
        --element-font-variant: normal;
    }
    """


cssDark : String
cssDark =
    """
    .body-container {
        color-scheme: dark;
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
        --color-external-link: #00ffff;
        --color-subelement-bg: #806e45;
        --color-subelement-text: #111111;
        --color-subsubelement-bg: #627d62;
        --color-subsubelement-text: #0f0f0f;
        --color-inactive-text: #999999;
        --color-table-even: #64542f;
        --color-table-odd: #342c19;
        --color-table-text: #eeeeee;
        --color-text: #eeeeee;
        --element-font-variant: small-caps;
    }
    """


cssDead : String
cssDead =
    """
    .body-container {
        color-scheme: light;
        --color-bg: #ffffff;
        --color-bg-secondary: #c8c8c8;
        --color-container-bg: #dddddd;
        --color-container-border: #eeeeee;
        --color-element-bg: #482d5a;
        --color-element-border: #d8c483;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #291716;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #656148;
        --color-element-text: #e6d8ad;
        --color-external-link: #0000ff;
        --color-subelement-bg: #709cab;
        --color-subelement-text: #0f0f0f;
        --color-subsubelement-bg: #c18479;
        --color-subsubelement-text: #0f0f0f;
        --color-inactive-text: #999999;
        --color-table-even: #c3cdce;
        --color-table-odd: #74919b;
        --color-table-text: #000000;
        --color-text: #0f0f0f;
        --element-font-variant: small-caps;
    }
    """


cssLight : String
cssLight =
    """
    .body-container {
        color-scheme: light;
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
        --color-external-link: #0000ff;
        --color-subelement-bg: #cbc18f;
        --color-subelement-text: #111111;
        --color-subsubelement-bg: #627d62;
        --color-subsubelement-text: #0f0f0f;
        --color-inactive-text: #999999;
        --color-table-even: #cbc18f;
        --color-table-odd: #ded7bb;
        --color-table-text: #0f0f0f;
        --color-text: #111111;
        --element-font-variant: small-caps;
    }
    """


cssOrc : String
cssOrc =
    """
    .body-container {
        color-scheme: dark;
        --color-bg: #002604;
        --color-bg-secondary: #002604;
        --color-container-bg: #0e3c10;
        --color-container-border: #eeeeee;
        --color-element-bg: #4a4300;
        --color-element-border: #ddffdd;
        --color-element-icon: #cccccc;
        --color-element-inactive-bg: #291716;
        --color-element-inactive-border: #6c6242;
        --color-element-inactive-text: #656148;
        --color-element-text: #ddffdd;
        --color-external-link: #00ffff;
        --color-subelement-bg: #806e45;
        --color-subelement-text: #111111;
        --color-subsubelement-bg: #627d62;
        --color-subsubelement-text: #0f0f0f;
        --color-inactive-text: #999999;
        --color-table-even: #4a4300;
        --color-table-odd: #002604;
        --color-table-text: #ddffdd;
        --color-text: #ddffdd;
        --element-font-variant: small-caps;
    }

    .title, thead th:first-child, .query-input {
        background-image: url(/Images/orc-face-circ-25t.webp);
        background-repeat: no-repeat;
        background-position: 10% 39%;
    }

    .option-container {
        background-image: url(/Images/orc-face-circ-25t.webp);
        background-repeat: no-repeat;
        background-position: 10% -38px;
    }
    """


cssPaper : String
cssPaper =
    """
    .body-container {
        color-scheme: light;
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
        --color-external-link: #0000ff;
        --color-subelement-bg: #dbd0bc;
        --color-subelement-text: #111111;
        --color-subsubelement-bg: #002564;
        --color-subsubelement-text: #c8c6b7;
        --color-inactive-text: #999999;
        --color-table-even: #ede3c7;
        --color-table-odd: #f4eee0;
        --color-table-text: #0f0f0f;
        --color-text: #111111;
        --element-font-variant: small-caps;
    }
    """


cssExtraContrast : String
cssExtraContrast =
    """
    .body-container {
        color-scheme: dark;
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
        --color-external-link: #00ffff;
        --color-subelement-bg: #002564;
        --color-subelement-text: #ffffff;
        --color-subsubelement-bg: #769477;
        --color-subsubelement-text: #0f0f0f;
        --color-inactive-text: #999999;
        --color-table-even: #ffffff;
        --color-table-odd: #cccccc;
        --color-table-text: #0f0f0f;
        --color-text: #eeeeee;
        --element-font-variant: small-caps;
    }
    """


cssLavender : String
cssLavender =
    """
    .body-container {
        color-scheme: light;
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
        --color-external-link: #0000ff;
        --color-subelement-bg: #b8a0ce;
        --color-subelement-text: #ffffff;
        --color-subsubelement-bg: #f0e6ff;
        --color-subsubelement-text: #0f0f0f;
        --color-inactive-text: #999999;
        --color-table-even: #8471a7;
        --color-table-odd: #6f5f98;
        --color-table-text: #ffffff;
        --color-text: #000000;
        --element-font-variant: small-caps;
    }
    """
