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
import Random
import Regex
import Result.Extra
import String.Extra
import Svg
import Svg.Attributes as SA
import Task
import Tuple3
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query


port document_linkEntered : (Decode.Value -> msg) -> Sub msg
port document_linkLeft : (String -> msg) -> Sub msg
port document_receiveBodySize : (Size -> msg) -> Sub msg
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
    , bodySize : Size
    , documents : Dict String (Result Http.Error Document)
    , elasticUrl : String
    , fixedParams : Dict String (List String)
    , globalAggregations : Maybe (Result Http.Error GlobalAggregations)
    , groupTraits : Bool
    , groupedDisplay : GroupedDisplay
    , groupedShowPfs : Bool
    , groupedShowRarity : Bool
    , groupedSort : GroupedSort
    , limitTableWidth : Bool
    , linkPreviewsEnabled : Bool
    , menuOpen : Bool
    , noUi : Bool
    , openInNewTab : Bool
    , overlayActive : Bool
    , pageDefaultParams : Dict String (Dict String (List String))
    , pageId : String
    , pageSize : Int
    , pageWidth : Int
    , previewLink : Maybe { documentId : String, elementPosition : Position, fragment : Maybe String }
    , randomSeed : Int
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
    , url : Url
    , windowSize : Size
    }


type alias SearchModel =
    { aggregations : Maybe (Result Http.Error Aggregations)
    , alwaysShowFilters : List String
    , debounce : Int
    , defaultQuery : String
    , filteredAbilities : Dict String Bool
    , filteredActions : Dict String Bool
    , filteredAlignments : Dict String Bool
    , filteredArmorCategories : Dict String Bool
    , filteredArmorGroups : Dict String Bool
    , filteredComponents : Dict String Bool
    , filteredCreatureFamilies : Dict String Bool
    , filteredFromValues : Dict String String
    , filteredHands : Dict String Bool
    , filteredItemCategories : Dict String Bool
    , filteredItemSubcategories : Dict String Bool
    , filteredPfs : Dict String Bool
    , filteredRarities : Dict String Bool
    , filteredRegions : Dict String Bool
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
    , groupedLinkLayout : GroupedLinkLayout
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
    , searchTableColumns : String
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
    , visibleFilterBoxes : List String
    }


emptySearchModel :
   { alwaysShowFilters : List String
   , defaultQuery : String
   , removeFilters : List String
   , fixedQueryString : String
   }
   -> SearchModel
emptySearchModel { alwaysShowFilters, defaultQuery, fixedQueryString, removeFilters } =
    { aggregations = Nothing
    , alwaysShowFilters = alwaysShowFilters
    , debounce = 0
    , defaultQuery = defaultQuery
    , filteredAbilities = Dict.empty
    , filteredActions = Dict.empty
    , filteredAlignments = Dict.empty
    , filteredArmorCategories = Dict.empty
    , filteredArmorGroups = Dict.empty
    , filteredComponents = Dict.empty
    , filteredCreatureFamilies = Dict.empty
    , filteredFromValues = Dict.empty
    , filteredHands = Dict.empty
    , filteredItemCategories = Dict.empty
    , filteredItemSubcategories = Dict.empty
    , filteredRarities = Dict.empty
    , filteredRegions = Dict.empty
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
    , groupedLinkLayout = Horizontal
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
    , searchTableColumns = ""
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
    , visibleFilterBoxes = []
    }


type alias SearchResult =
    { documentIds : List String
    , searchAfter : Encode.Value
    , total : Int
    , groupAggs : Maybe GroupAggregations
    }


type alias SearchResultWithDocuments =
    { documents : List Document
    , searchAfter : Encode.Value
    , total : Int
    , groupAggs : Maybe GroupAggregations
    }


type alias Document =
    { id : String
    , category : String
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
    , creatureAbilities : List String
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
    , elements : List String
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
    , markdown : Markdown
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
    , searchMarkdown : Markdown
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
    , spell : Maybe String
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
    , fixedParams : Dict String (List String)
    , fixedQueryString : String
    , localStorage : Dict String String
    , noUi : Bool
    , pageId : String
    , randomSeed : Int
    , removeFilters : List String
    , resultBaseUrl : String
    , showFilters : List String
    , showHeader : Bool
    , windowHeight : Int
    , windowWidth : Int
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
    , noUi = False
    , pageId = ""
    , randomSeed = 1
    , removeFilters = []
    , resultBaseUrl = "https://2e.aonprd.com/"
    , showFilters = [ "numbers", "pfs", "rarities", "traits", "types" ]
    , showHeader = True
    , windowHeight = 0
    , windowWidth = 0
    }


type alias Aggregations =
    { actions : List String
    , creatureFamilies : List String
    , hands : List String
    , itemCategories : List String
    , itemSubcategories : List { category : String, name : String }
    , regions : List String
    , reloads : List String
    , sources : List String
    , traits : List String
    , types : List String
    , weaponGroups : List String
    }


type alias GlobalAggregations =
    { traitGroups : Dict String (List String)
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
    , visibleIf : SearchModel -> Bool
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
    = Full
    | Grouped
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


type Msg
    = AbilityFilterAdded String
    | AbilityFilterRemoved String
    | ActionsFilterAdded String
    | ActionsFilterRemoved String
    | AlignmentFilterAdded String
    | AlignmentFilterRemoved String
    | ArmorCategoryFilterAdded String
    | ArmorCategoryFilterRemoved String
    | ArmorGroupFilterAdded String
    | ArmorGroupFilterRemoved String
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
    | GotBodySize Size
    | GotDocuments (List String) Bool (Result Http.Error (List (Result String Document)))
    | GotGlobalAggregationsResult (Result Http.Error GlobalAggregations)
    | GotGroupAggregationsResult (Result Http.Error SearchResultWithDocuments)
    | GotSearchResult (Result Http.Error SearchResultWithDocuments)
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
    | GroupedShowRarityChanged Bool
    | GroupedSortChanged GroupedSort
    | HandFilterAdded String
    | HandFilterRemoved String
    | ItemCategoryFilterAdded String
    | ItemCategoryFilterRemoved String
    | ItemSubcategoryFilterAdded String
    | ItemSubcategoryFilterRemoved String
    | LimitTableWidthChanged Bool
    | LinkEntered String Position
    | LinkEnteredDebouncePassed String
    | LinkLeft
    | LoadMorePressed Int
    | LocalStorageValueReceived Decode.Value
    | MenuOpenDelayPassed
    | NewRandomSeedPressed
    | NoOp
    | OpenInNewTabChanged Bool
    | PageSizeChanged Int
    | PageWidthChanged Int
    | PfsFilterAdded String
    | PfsFilterRemoved String
    | QueryChanged String
    | QueryTypeSelected QueryType
    | RandomSeedGenerated Int
    | RarityFilterAdded String
    | RarityFilterRemoved String
    | RegionFilterAdded String
    | RegionFilterRemoved String
    | ReloadFilterAdded String
    | ReloadFilterRemoved String
    | RemoveAllAbilityFiltersPressed
    | RemoveAllActionsFiltersPressed
    | RemoveAllAlignmentFiltersPressed
    | RemoveAllArmorCategoryFiltersPressed
    | RemoveAllArmorGroupFiltersPressed
    | RemoveAllComponentFiltersPressed
    | RemoveAllCreatureFamilyFiltersPressed
    | RemoveAllHandFiltersPressed
    | RemoveAllItemCategoryFiltersPressed
    | RemoveAllItemSubcategoryFiltersPressed
    | RemoveAllPfsFiltersPressed
    | RemoveAllRarityFiltersPressed
    | RemoveAllRegionFiltersPressed
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
    | SaveDefaultParamsPressed
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
    | SearchTableColumnsChanged String
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
    | WindowResized Int Int


type alias Position =
    { x : Int
    , y : Int
    , width : Int
    , height : Int
    }


type alias Size =
    { width : Int
    , height : Int
    }


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
      , bodySize = { width = 0, height = 0 }
      , documents = Dict.empty
      , elasticUrl = flags.elasticUrl
      , fixedParams = flags.fixedParams
      , globalAggregations = Nothing
      , groupTraits = False
      , groupedDisplay = Dim
      , groupedShowPfs = True
      , groupedShowRarity = True
      , groupedSort = Alphanum
      , limitTableWidth = False
      , linkPreviewsEnabled = True
      , menuOpen = False
      , noUi = flags.noUi
      , openInNewTab = False
      , overlayActive = False
      , pageDefaultParams = Dict.empty
      , pageId = flags.pageId
      , pageSize = 50
      , pageWidth = 0
      , previewLink = Nothing
      , randomSeed = flags.randomSeed
      , resultBaseUrl =
            if String.endsWith "/" flags.resultBaseUrl then
                String.dropRight 1 flags.resultBaseUrl

            else
                flags.resultBaseUrl
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
      , url = url
      , windowSize = { width = flags.windowWidth, height = flags.windowHeight }
      }
        |> \model ->
            List.foldl
                (updateModelFromLocalStorage)
                model
                (Dict.toList flags.localStorage)
        |> updateModelFromDefaultsOrUrl
    , Cmd.none
    )
        |> \( model, cmd ) ->
            if model.noUi then
                ( model, cmd )

            else
                ( model, cmd )
                    |> searchWithCurrentQuery LoadNew
                    |> updateTitle
                    |> getAggregations
                    |> getGlobalAggregations
                    |> getSourcesAggregation


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ document_linkEntered
            (\val ->
                case Decode.decodeValue linkEnteredDecoder val of
                    Ok ( url, pos ) ->
                        LinkEntered url pos

                    Err _ ->
                        NoOp
            )
        , document_linkLeft (\_ -> LinkLeft)
        , document_receiveBodySize GotBodySize
        , localStorage_receive LocalStorageValueReceived
        , navigation_urlChanged UrlChanged
        , Browser.Events.onResize WindowResized
        ]


linkEnteredDecoder : Decode.Decoder ( String, Position )
linkEnteredDecoder =
    Field.require "url" Decode.string <| \url ->
    Field.require "x" Decode.int <| \x ->
    Field.require "y" Decode.int <| \y ->
    Field.require "width" Decode.int <| \width ->
    Field.require "height" Decode.int <| \height ->
    Decode.succeed
        ( url
        , { x = x, y = y, width = width, height = height }
        )



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

        ArmorCategoryFilterAdded category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredArmorCategories = toggleBoolDict category searchModel.filteredArmorCategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        ArmorCategoryFilterRemoved category ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredArmorCategories = Dict.remove category searchModel.filteredArmorCategories }
                )
                model
                |> updateUrlWithSearchParams
            )

        ArmorGroupFilterAdded group ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredArmorGroups = toggleBoolDict group searchModel.filteredArmorGroups }
                )
                model
                |> updateUrlWithSearchParams
            )

        ArmorGroupFilterRemoved group ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredArmorGroups = Dict.remove group searchModel.filteredArmorGroups }
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

        GotAggregationsResult result ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | aggregations = Just result }
                )
                model
            , Cmd.none
            )

        GotBodySize size ->
            ( { model | bodySize = size
              }
            , Cmd.none
            )

        GotDocuments ids fetchLinks result ->
            let
                resultWithParsedMarkdown : Result Http.Error (List (Result String Document))
                resultWithParsedMarkdown =
                    Result.map (List.map (Result.map parseDocumentMarkdown)) result

                childMarkdown : List ParsedMarkdownResult
                childMarkdown =
                    resultWithParsedMarkdown
                        |> Result.withDefault []
                        |> List.filterMap (Result.toMaybe)
                        |> List.map .markdown
                        |> List.filterMap getParsedMarkdown

                childDocumentIds : List String
                childDocumentIds =
                    childMarkdown
                        |> List.concatMap getChildDocumentIds
                        |> List.filter (\childId -> not (Dict.member childId model.documents))
                        |> List.filter (\childId -> not (List.member childId ids))

                linkDocumentIds : List String
                linkDocumentIds =
                    if fetchLinks then
                        childMarkdown
                            |> List.concatMap getLinksFromMarkdown
                            |> List.map parseUrl
                            |> List.filterMap urlToDocumentId
                            |> List.filter (\childId -> not (Dict.member childId model.documents))
                            |> List.filter (\childId -> not (List.member childId ids))

                    else
                        []
            in
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
                                        resultWithParsedMarkdown
                                    )
                                )
                            |> Dict.fromList
                        )
              }
            , Cmd.batch
                [ if List.isEmpty childDocumentIds then
                    Cmd.none

                  else
                    fetchDocuments model fetchLinks childDocumentIds
                , fetchDocuments model False linkDocumentIds
                ]
            )

        GotGlobalAggregationsResult result ->
            ( { model | globalAggregations = Just result }
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
                        |> Maybe.map .documents
                        |> Maybe.andThen List.head
                        |> Maybe.map (getUrl model)

                resultWithParsedMarkdown : Result Http.Error SearchResultWithDocuments
                resultWithParsedMarkdown =
                    Result.map
                        (\r ->
                            { r
                                | documents =
                                    List.map
                                        (\d ->
                                            case model.searchModel.resultDisplay of
                                                List ->
                                                    parseDocumentSearchMarkdown d

                                                Full ->
                                                    parseDocumentMarkdown d

                                                _ ->
                                                    d
                                        )
                                        r.documents
                            }
                        )
                        result

                childDocumentIds : List String
                childDocumentIds =
                    resultWithParsedMarkdown
                        |> Result.map .documents
                        |> Result.withDefault []
                        |> List.map .markdown
                        |> List.filterMap getParsedMarkdown
                        |> List.concatMap getChildDocumentIds
                        |> List.filter (\childId -> not (Dict.member childId model.documents))
            in
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | searchResults =
                            List.append
                                (List.filter Result.Extra.isOk searchModel.searchResults)
                                [ Result.map removeDocumentsFromSearchResult result ]
                        , searchResultGroupAggs =
                            result
                                |> Result.toMaybe
                                |> Maybe.andThen .groupAggs
                                |> Maybe.Extra.orElse searchModel.searchResultGroupAggs
                        , tracker = Nothing
                    }
                )
                { model
                    | documents =
                        Dict.union
                            model.documents
                            (resultWithParsedMarkdown
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
                }
            , case ( containsTeleport, firstResultUrl ) of
                ( True, Just url ) ->
                    navigation_loadUrl url

                _ ->
                    if List.isEmpty childDocumentIds then
                        Cmd.none

                    else
                        fetchDocuments model False childDocumentIds
            )

        GotSourcesAggregationResult result ->
            ( { model | sourcesAggregation = Just result }
            , Cmd.none
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
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | groupedLinkLayout = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        GroupedShowPfsIconChanged enabled ->
            ( { model | groupedShowPfs = enabled }
            , saveToLocalStorage
                "grouped-show-pfs"
                (if enabled then "1" else "0")
            )

        GroupedShowRarityChanged enabled ->
            ( { model | groupedShowRarity = enabled }
            , saveToLocalStorage
                "grouped-show-rarity"
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

        LinkEntered url position ->
            let
                parsedUrl : Maybe Url
                parsedUrl =
                    if String.startsWith "/" url then
                        Url.fromString ("https://example.com" ++ url)

                    else
                        Url.fromString url

                documentId : Maybe String
                documentId =
                    Maybe.andThen urlToDocumentId parsedUrl

                documentsWithParsedMarkdown : Dict String (Result Http.Error Document)
                documentsWithParsedMarkdown =
                    parseMarkdownAndCollectIdsToFetch (Maybe.Extra.toList documentId) [] model.documents
                        |> Tuple.first
            in
            ( { model
                | documents = documentsWithParsedMarkdown
                , previewLink =
                    if model.linkPreviewsEnabled then
                        documentId
                            |> Maybe.map
                                (\id ->
                                    { documentId = id
                                    , fragment = Maybe.andThen .fragment parsedUrl
                                    , elementPosition = position
                                    }
                                )

                    else
                        Nothing
              }
            , case ( model.linkPreviewsEnabled, documentId ) of
                ( True, Just id ) ->
                    Process.sleep 150
                        |> Task.perform (\_ -> LinkEnteredDebouncePassed id)

                _ ->
                    Cmd.none
            )

        LinkEnteredDebouncePassed documentId ->
            let
                idsToLoad : List String
                idsToLoad =
                    parseMarkdownAndCollectIdsToFetch [ documentId ] [] model.documents
                        |> Tuple.second
            in
            if Maybe.map .documentId model.previewLink == Just documentId then
                ( model
                , fetchDocuments model False idsToLoad
                )

            else
                ( model
                , Cmd.none
                )

        LinkLeft ->
            ( { model | previewLink = Nothing }
            , Cmd.none
            )

        LoadMorePressed size ->
            ( model
            , Cmd.none
            )
                |> searchWithCurrentQuery (LoadMore size)

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

        NewRandomSeedPressed ->
            ( model
            , Random.generate RandomSeedGenerated (Random.int 0 2147483647)
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

        PageWidthChanged width ->
            ( { model | pageWidth = width }
            , saveToLocalStorage
                "page-width"
                (String.fromInt width)
            )

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

        RandomSeedGenerated seed ->
            ( { model | randomSeed = seed }
            , Cmd.none
            )
                |> (if sortIsRandom model.searchModel then
                        searchWithCurrentQuery LoadNewForce

                    else
                        identity
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

        RegionFilterAdded region ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredRegions = toggleBoolDict region searchModel.filteredRegions }
                )
                model
                |> updateUrlWithSearchParams
            )

        RegionFilterRemoved region ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredRegions = Dict.remove region searchModel.filteredRegions }
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

        RemoveAllArmorCategoryFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredArmorCategories = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllArmorGroupFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredArmorGroups = Dict.empty }
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

        RemoveAllRegionFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredRegions = Dict.empty }
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
            let
                newModel : Model
                newModel =
                    { model
                        | documents =
                            if value == List then
                                Dict.map
                                    (\_ -> Result.map parseDocumentSearchMarkdown)
                                    model.documents

                            else if value == Full then
                                Dict.map
                                    (\_ -> Result.map parseDocumentMarkdown)
                                    model.documents

                            else
                                model.documents
                    }

                childDocumentIds : List String
                childDocumentIds =
                    newModel.documents
                        |> Dict.values
                        |> List.filterMap Result.toMaybe
                        |> List.map .markdown
                        |> List.filterMap getParsedMarkdown
                        |> List.concatMap getChildDocumentIds
                        |> List.filter (\childId -> not (Dict.member childId model.documents))
            in
            ( newModel
            , Cmd.batch
                [ updateCurrentSearchModel
                    (\searchModel ->
                        { searchModel
                            | resultDisplay = value
                        }
                    )
                    model
                    |> updateUrlWithSearchParams
                , if List.isEmpty childDocumentIds then
                    Cmd.none

                  else
                    fetchDocuments model False childDocumentIds
                ]
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

        SaveDefaultParamsPressed ->
            let
                newDefaults : Dict String (Dict String (List String))
                newDefaults =
                    Dict.insert
                        model.pageId
                        (Dict.fromList (getSearchModelQueryParams model model.searchModel))
                        model.pageDefaultParams
            in
            ( { model | pageDefaultParams = newDefaults }
            , saveToLocalStorage
                "page-default-params"
                (Encode.dict
                    identity
                    (Encode.dict
                        identity
                        (Encode.list Encode.string)
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

        SearchTableColumnsChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | searchTableColumns = value }
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
                                id :: searchModel.visibleFilterBoxes

                            else
                                List.Extra.remove id searchModel.visibleFilterBoxes
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
                            if field == "random" then
                                [ ( field, dir ) ]

                            else if List.any (Tuple.first >> (==) field) searchModel.sort then
                                List.Extra.updateIf
                                    (Tuple.first >> (==) field)
                                    (Tuple.mapSecond (\_ -> dir))
                                    searchModel.sort
                                    |> List.Extra.remove ( "random", Asc )

                            else
                                List.append searchModel.sort [ ( field, dir ) ]
                                    |> List.Extra.remove ( "random", Asc )
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
                |> updateModelFromDefaultsOrUrl
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

        WindowResized width height ->
            ( { model | windowSize = { width = width, height = height } }
            , Cmd.none
            )


fetchDocuments : Model -> Bool -> List String -> Cmd Msg
fetchDocuments model fetchLinks ids =
    let
        idsToFetch : List String
        idsToFetch =
            List.filter
                (\id -> not (Dict.member id model.documents))
                ids
                |> List.Extra.unique
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
                    (GotDocuments idsToFetch fetchLinks)
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


removeDocumentsFromSearchResult : SearchResultWithDocuments -> SearchResult
removeDocumentsFromSearchResult result =
    { documentIds = List.map .id result.documents
    , searchAfter = result.searchAfter
    , total = result.total
    , groupAggs = result.groupAggs
    }


parseMarkdown : Markdown -> Markdown
parseMarkdown markdown =
    case markdown of
        Parsed _ ->
            markdown

        NotParsed string ->
            string
                |> Markdown.Parser.parse
                |> Result.map (List.map (Markdown.Block.walk mergeInlines))
                |> Result.mapError (List.map Markdown.Parser.deadEndToString)
                |> Parsed


parseDocumentMarkdown : Document -> Document
parseDocumentMarkdown document =
    { document | markdown = parseMarkdown document.markdown }


parseDocumentSearchMarkdown : Document -> Document
parseDocumentSearchMarkdown document =
    { document | searchMarkdown = parseMarkdown document.searchMarkdown }


getParsedMarkdown : Markdown -> Maybe ParsedMarkdownResult
getParsedMarkdown markdown =
    case markdown of
        Parsed parsed ->
            Just parsed

        NotParsed _ ->
            Nothing


parseMarkdownAndCollectIdsToFetch :
    List String
    -> List String
    -> Dict String (Result Http.Error Document)
    -> ( Dict String (Result Http.Error Document) , List String )
parseMarkdownAndCollectIdsToFetch idsToCheck idsToFetch documents =
    case idsToCheck of
        id :: remainingToCheck ->
            let
                documentWithParsedMarkdown : Maybe Document
                documentWithParsedMarkdown =
                    Dict.get id documents
                        |> Maybe.andThen Result.toMaybe
                        |> Maybe.map parseDocumentMarkdown

                fetchCurrentId : List String
                fetchCurrentId =
                    if Dict.member id documents then
                        []

                    else
                        [ id ]

                childDocumentIds : List String
                childDocumentIds =
                    documentWithParsedMarkdown
                        |> Maybe.map .markdown
                        |> Maybe.andThen getParsedMarkdown
                        |> Maybe.map getChildDocumentIds
                        |> Maybe.withDefault []

                childrenIdsToCheck : List String
                childrenIdsToCheck =
                    childDocumentIds
                        |> List.filter (\childId -> Dict.member childId documents)

                childrenIdsToFetch : List String
                childrenIdsToFetch =
                    childDocumentIds
                        |> List.filter (\childId -> not (Dict.member childId documents))
            in
            parseMarkdownAndCollectIdsToFetch
                (remainingToCheck ++ childrenIdsToCheck)
                (idsToFetch ++ childrenIdsToFetch ++ fetchCurrentId)
                (Dict.update
                    id
                    (Maybe.map (Result.map (\doc -> Maybe.withDefault doc documentWithParsedMarkdown)))
                    documents
                )

        [] ->
            ( documents, idsToFetch )


getChildDocumentIds : ParsedMarkdownResult -> List String
getChildDocumentIds markdown =
    case markdown of
        Ok blocks ->
            List.foldl
                findDocumentIdsInBlock
                []
                blocks

        Err _ ->
            []


findDocumentIdsInBlock : Markdown.Block.Block -> List String -> List String
findDocumentIdsInBlock block list =
    case block of
        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "document" attributes _) ->
            case List.Extra.find (.name >> (==) "id") attributes of
                Just id ->
                    id.value :: list

                Nothing ->
                    list

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement _ _ children) ->
            List.foldl
                findDocumentIdsInBlock
                list
                children

        _ ->
            list


getLinksFromMarkdown : ParsedMarkdownResult -> List String
getLinksFromMarkdown markdown =
    case markdown of
        Ok blocks ->
            List.append
                (Markdown.Block.inlineFoldl
                    (\inline list ->
                        case inline of
                            Markdown.Block.Link url _ _ ->
                                url :: list

                            _ ->
                                list
                    )
                    []
                    blocks
                )
                (Markdown.Block.foldl
                    (\block list ->
                        case block of
                            Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "trait" attributes _) ->
                                case List.Extra.find (.name >> (==) "url") attributes of
                                    Just url ->
                                        url.value :: list

                                    Nothing ->
                                        list

                            _ ->
                                list
                    )
                    []
                    blocks
                )

        Err _ ->
            []


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

        "grouped-show-pfs" ->
            case value of
                "1" ->
                    { model | groupedShowPfs = True }

                "0" ->
                    { model | groupedShowPfs = False }

                _ ->
                    model

        "grouped-show-rarity" ->
            case value of
                "1" ->
                    { model | groupedShowRarity = True }

                "0" ->
                    { model | groupedShowRarity = False }

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

        "link-previews-enabled" ->
            case value of
                "1" ->
                    { model | linkPreviewsEnabled = True }

                "0" ->
                    { model | linkPreviewsEnabled = False }

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

        -- Legacy
        "page-default-displays" ->
            case Decode.decodeString paramsDecoder value of
                Ok defaults ->
                    if Dict.isEmpty model.pageDefaultParams then
                        { model | pageDefaultParams = defaults }

                    else
                        model

                Err _ ->
                    model

        "page-default-params" ->
            case Decode.decodeString paramsDecoder value of
                Ok defaults ->
                    { model | pageDefaultParams = defaults }

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

        "page-width" ->
            case String.toInt value of
                Just width ->
                    if List.member width Data.allPageWidths || width == 0 then
                        { model | pageWidth = width }

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
    (if String.startsWith "/" url then
        "http://example.com" ++ url

     else
        url
    )
        |> Url.fromString
        |> Maybe.withDefault
            { protocol = Url.Http
            , host = ""
            , port_ = Nothing
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }


urlToDocumentId : Url -> Maybe String
urlToDocumentId url =
    let
        queryParams : Dict String (List String)
        queryParams =
            url.query
                |> Maybe.map String.toLower
                |> Maybe.map queryToParamsDict
                |> Maybe.withDefault Dict.empty

        withId type_ =
            case Dict.get "id" queryParams of
                Just [ id ] ->
                    Just (type_ ++ "-" ++ id)

                _ ->
                    Nothing
    in
    case String.toLower url.path of
        "/actions.aspx" ->
            withId "action"

        "/ancestries.aspx" ->
            withId "ancestry"

        "/animalcompanions.aspx" ->
            if Dict.get "advanced" queryParams == Just [ "true" ] then
                withId "animal-companion-advanced"

            else if Dict.get "specialized" queryParams == Just [ "true" ] then
                withId "animal-companion-specialization"

            else if Dict.get "unique" queryParams == Just [ "true" ] then
                withId "animal-companion-unique"

            else
                withId "animal-companion"

        "/arcaneschools.aspx" ->
            withId "arcane-school"

        "/arcanethesis.aspx" ->
            withId "arcane-thesis"

        "/archetypes.aspx" ->
            withId "archetype"

        "/armor.aspx" ->
            withId "armor"

        "/armorgroups.aspx" ->
            withId "armor-group"

        "/articles.aspx" ->
            withId "article"

        "/backgrounds.aspx" ->
            withId "background"

        "/bloodlines.aspx" ->
            withId "bloodline"

        "/campmeals.aspx" ->
            withId "campsite-meal"

        "/causes.aspx" ->
            withId "cause"

        "/classes.aspx" ->
            withId "class"

        "/classkits.aspx" ->
            withId "class-kit"

        "/classsamples.aspx" ->
            withId "class-sample"

        "/conditions.aspx" ->
            withId "condition"

        "/consciousminds.aspx" ->
            withId "conscious-mind"

        "/monsters.aspx" ->
            withId "creature"

        "/npcs.aspx" ->
            withId "creature"

        "/monsterfamilies.aspx" ->
            withId "creature-family"

        "/curses.aspx" ->
            withId "curse"

        "/deities.aspx" ->
            withId "deity"

        "/deitycategories.aspx" ->
            withId "deity-category"

        "/deviantfeats.aspx" ->
            withId "deviant-ability-classification"

        "/diseases.aspx" ->
            withId "disease"

        "/doctrines.aspx" ->
            withId "doctrine"

        "/domains.aspx" ->
            withId "domain"

        "/druidicorders.aspx" ->
            withId "druidic-order"

        "/eidolons.aspx" ->
            withId "eidolon"

        "/elements.aspx" ->
            withId "element"

        "/equipment.aspx" ->
            withId "equipment"

        "/familiars.aspx" ->
            if Dict.get "specific" queryParams == Just [ "true" ] then
                withId "familiar-specific"

            else
                withId "familiar-ability"

        "/feats.aspx" ->
            withId "feat"

        "/hazards.aspx" ->
            withId "hazard"

        "/hellknightorders.aspx" ->
            withId "hellknight-order"

        "/heritages.aspx" ->
            withId "heritage"

        "/huntersedge.aspx" ->
            withId "hunters-edge"

        "/hybridstudies.aspx" ->
            withId "hybrid-study"

        "/implements.aspx" ->
            withId "implement"

        "/innovations.aspx" ->
            withId "innovation"

        "/instincts.aspx" ->
            withId "instinct"

        "/kmevents.aspx" ->
            withId "kingdom-event"

        "/kmstructures.aspx" ->
            withId "kingdom-structure"

        "/languages.aspx" ->
            withId "language"

        "/lessons.aspx" ->
            withId "lesson"

        "/methodologies.aspx" ->
            withId "methodology"

        "/monsterabilities.aspx" ->
            withId "creature-ability"

        "/muses.aspx" ->
            withId "muse"

        "/mysteries.aspx" ->
            withId "mystery"

        "/npcthemetemplates.aspx" ->
            withId "npc-theme-template"

        "/patrons.aspx" ->
            withId "patron"

        "/planes.aspx" ->
            withId "plane"

        "/rackets.aspx" ->
            withId "racket"

        "/relics.aspx" ->
            withId "relic"

        "/researchfields.aspx" ->
            withId "research-field"

        "/rituals.aspx" ->
            withId "ritual"

        "/rules.aspx" ->
            withId "rules"

        "/setrelics.aspx" ->
            withId "set-relic"

        "/shields.aspx" ->
            withId "shield"

        "/siegeweapons.aspx" ->
            withId "siege-weapon"

        "/skills.aspx" ->
            case Dict.get "general" queryParams of
                Just [ "true" ] ->
                    withId "skill-general-action"

                _ ->
                    withId "skill"

        "/sources.aspx" ->
            withId "source"

        "/spells.aspx" ->
            withId "spell"

        "/styles.aspx" ->
            withId "style"

        "/subconsciousminds.aspx" ->
            withId "subconscious-mind"

        "/tenets.aspx" ->
            withId "tenet"

        "/spelllists.aspx" ->
            case Dict.get "tradition" queryParams of
                Just [ id ] ->
                    Just ("tradition-" ++ id)

                _ ->
                    Nothing

        "/traits.aspx" ->
            withId "trait"

        "/vehicles.aspx" ->
            withId "vehicle"

        "/kmwararmies.aspx" ->
            withId "warfare-army"

        "/kmwartactics.aspx" ->
            withId "warfare-tactic"

        "/ways.aspx" ->
            withId "way"

        "/weapons.aspx" ->
            withId "weapon"

        "/weapongroups.aspx" ->
            withId "weapon-group"

        "/weatherhazards.aspx" ->
            withId "weather-hazard"

        _ ->
            Nothing


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
            getSearchModelQueryParams model searchModel
                |> List.append (Dict.toList model.fixedParams)
                |> List.map (Tuple.mapSecond (List.map Url.percentEncode))
                |> List.map (Tuple.mapSecond (String.join "+"))
                |> List.map (\(key, val) -> key ++ "=" ++ val)
                |> String.join "&"
                |> String.Extra.nonEmpty
    }
        |> Url.toString
        |> navigation_pushUrl


getSearchModelQueryParams : Model -> SearchModel -> List ( String, List String )
getSearchModelQueryParams model searchModel =
    [ ( "q"
      , searchModel.query
            |> String.Extra.nonEmpty
            |> Maybe.map (String.split " ")
            |> Maybe.withDefault []
      )
    , ( "type"
      , if model.autoQueryType then
            if queryCouldBeComplex searchModel.query then
                [ "eqs" ]

            else
                []

        else
            case searchModel.queryType of
                Standard ->
                    []

                ElasticsearchQueryString ->
                    [ "eqs" ]
      )
    , ( "include-traits"
      , boolDictIncluded searchModel.filteredTraits
      )
    , ( "exclude-traits"
      , boolDictExcluded searchModel.filteredTraits
      )
    , ( "traits-operator"
      , if searchModel.filterTraitsOperator then
            []

        else
            [ "or" ]
      )
    , ( "include-types"
      , boolDictIncluded searchModel.filteredTypes
      )
    , ( "exclude-types"
      , boolDictExcluded searchModel.filteredTypes
      )
    , ( "include-abilities"
      , boolDictIncluded searchModel.filteredAbilities
      )
    , ( "exclude-abilities"
      , boolDictExcluded searchModel.filteredAbilities
      )
    , ( "include-actions"
      , boolDictIncluded searchModel.filteredActions
      )
    , ( "exclude-actions"
      , boolDictExcluded searchModel.filteredActions
      )
    , ( "include-alignments"
      , boolDictIncluded searchModel.filteredAlignments
      )
    , ( "exclude-alignments"
      , boolDictExcluded searchModel.filteredAlignments
      )
    , ( "include-armor-categories"
      , boolDictIncluded searchModel.filteredArmorCategories
      )
    , ( "exclude-armor-categories"
      , boolDictExcluded searchModel.filteredArmorCategories
      )
    , ( "include-armor-groups"
      , boolDictIncluded searchModel.filteredArmorGroups
      )
    , ( "exclude-armor-groups"
      , boolDictExcluded searchModel.filteredArmorGroups
      )
    , ( "include-components"
      , boolDictIncluded searchModel.filteredComponents
      )
    , ( "exclude-components"
      , boolDictExcluded searchModel.filteredComponents
      )
    , ( "components-operator"
      , if searchModel.filterComponentsOperator then
            []

        else
            [ "or" ]
      )
    , ( "include-creature-families"
      , boolDictIncluded searchModel.filteredCreatureFamilies
      )
    , ( "exclude-creature-families"
      , boolDictExcluded searchModel.filteredCreatureFamilies
      )
    , ( "include-hands"
      , boolDictIncluded searchModel.filteredHands
      )
    , ( "exclude-hands"
      , boolDictExcluded searchModel.filteredHands
      )
    , ( "include-item-categories"
      , boolDictIncluded searchModel.filteredItemCategories
      )
    , ( "exclude-item-categories"
      , boolDictExcluded searchModel.filteredItemCategories
      )
    , ( "include-item-subcategories"
      , boolDictIncluded searchModel.filteredItemSubcategories
      )
    , ( "exclude-item-subcategories"
      , boolDictExcluded searchModel.filteredItemSubcategories
      )
    , ( "include-pfs"
      , boolDictIncluded searchModel.filteredPfs
      )
    , ( "exclude-pfs"
      , boolDictExcluded searchModel.filteredPfs
      )
    , ( "include-rarities"
      , boolDictIncluded searchModel.filteredRarities
      )
    , ( "exclude-rarities"
      , boolDictExcluded searchModel.filteredRarities
      )
    , ( "include-regions"
      , boolDictIncluded searchModel.filteredRegions
      )
    , ( "exclude-regions"
      , boolDictExcluded searchModel.filteredRegions
      )
    , ( "include-reloads"
      , boolDictIncluded searchModel.filteredReloads
      )
    , ( "exclude-reloads"
      , boolDictExcluded searchModel.filteredReloads
      )
    , ( "include-saving-throws"
      , boolDictIncluded searchModel.filteredSavingThrows
      )
    , ( "exclude-saving-throws"
      , boolDictExcluded searchModel.filteredSavingThrows
      )
    , ( "include-schools"
      , boolDictIncluded searchModel.filteredSchools
      )
    , ( "exclude-schools"
      , boolDictExcluded searchModel.filteredSchools
      )
    , ( "include-sizes"
      , boolDictIncluded searchModel.filteredSizes
      )
    , ( "exclude-sizes"
      , boolDictExcluded searchModel.filteredSizes
      )
    , ( "include-skills"
      , boolDictIncluded searchModel.filteredSkills
      )
    , ( "exclude-skills"
      , boolDictExcluded searchModel.filteredSkills
      )
    , ( "include-sources"
      , boolDictIncluded searchModel.filteredSources
      )
    , ( "exclude-sources"
      , boolDictExcluded searchModel.filteredSources
      )
    , ( "include-source-categories"
      , boolDictIncluded searchModel.filteredSourceCategories
      )
    , ( "exclude-source-categories"
      , boolDictExcluded searchModel.filteredSourceCategories
      )
    , ( "include-strongest-saves"
      , boolDictIncluded searchModel.filteredStrongestSaves
      )
    , ( "exclude-strongest-saves"
      , boolDictExcluded searchModel.filteredStrongestSaves
      )
    , ( "include-traditions"
      , boolDictIncluded searchModel.filteredTraditions
      )
    , ( "exclude-traditions"
      , boolDictExcluded searchModel.filteredTraditions
      )
    , ( "traditions-operator"
      , if searchModel.filterTraditionsOperator then
            []

        else
            [ "or" ]
      )
    , ( "include-weakest-saves"
      , boolDictIncluded searchModel.filteredWeakestSaves
      )
    , ( "exclude-weakest-saves"
      , boolDictExcluded searchModel.filteredWeakestSaves
      )
    , ( "include-weapon-categories"
      , boolDictIncluded searchModel.filteredWeaponCategories
      )
    , ( "exclude-weapon-categories"
      , boolDictExcluded searchModel.filteredWeaponCategories
      )
    , ( "include-weapon-groups"
      , boolDictIncluded searchModel.filteredWeaponGroups
      )
    , ( "exclude-weapon-groups"
      , boolDictExcluded searchModel.filteredWeaponGroups
      )
    , ( "include-weapon-types"
      , boolDictIncluded searchModel.filteredWeaponTypes
      )
    , ( "exclude-weapon-types"
      , boolDictExcluded searchModel.filteredWeaponTypes
      )
    , ( "values-from"
      , searchModel.filteredFromValues
            |> Dict.toList
            |> List.map (\( field, value ) -> field ++ ":" ++ value)
      )
    , ( "values-to"
      , searchModel.filteredToValues
            |> Dict.toList
            |> List.map (\( field, value ) -> field ++ ":" ++ value)
      )
    , ( "spoilers"
      , if searchModel.filterSpoilers then
            [ "hide" ]

        else
            []
      )
    , ( "sort"
      , searchModel.sort
            |> List.map
                (\( field, dir ) ->
                    if field == "random" then
                        field

                    else
                        field ++ "-" ++ sortDirToString dir
                )
      )
    , ( "display"
      , [ case searchModel.resultDisplay of
            Full ->
                "full"

            Grouped ->
                "grouped"

            List ->
                "list"

            Table ->
                "table"
        ]
      )
    , ( "columns"
      , if searchModel.resultDisplay == Table then
            searchModel.tableColumns

        else
            []
      )
    , ( "group-fields"
      , if searchModel.resultDisplay == Grouped then
            [ Just searchModel.groupField1
            , searchModel.groupField2
            , searchModel.groupField3
            ]
                |> Maybe.Extra.values

        else
            []
      )
    , ( "link-layout"
      , if searchModel.resultDisplay == Grouped then
            [ case searchModel.groupedLinkLayout of
                Horizontal ->
                    "horizontal"

                Vertical ->
                    "vertical"

                VerticalWithSummary ->
                    "vertical-with-summary"
            ]

        else
            []
      )
    ]
        |> List.filter (Tuple.second >> List.isEmpty >> not)


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
                        (if sortIsRandom searchModel then
                            [ buildSearchQuery model searchModel
                            , ( "boost_mode", Encode.string "replace" )
                            , ( "random_score"
                              , Encode.object
                                    [ ( "seed", Encode.int model.randomSeed )
                                    , ( "field", Encode.string "_seq_no" )
                                    ]
                              )
                            ]

                         else
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
            |> Maybe.map .searchAfter
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


sortIsRandom : SearchModel -> Bool
sortIsRandom searchModel =
    searchModel.sort == [ ( "random", Asc ) ]


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

        , [ [ ( "term"
              , Encode.object
                    [ ( "exclude_from_search", Encode.bool True ) ]
              )
            ]
          ]
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


getQueryParamsDictFromUrl : Dict String (List String) -> Url -> Dict String (List String)
getQueryParamsDictFromUrl fixedParams url =
    case url.query of
        Just query ->
            queryToParamsDict query
                |> Dict.filter
                    (\key _ ->
                        not (Dict.member key fixedParams)
                    )

        Nothing ->
            Dict.empty


queryToParamsDict : String -> Dict String (List String)
queryToParamsDict query =
    query
        |> String.split "&"
        |> List.filterMap
            (\part ->
                case String.split "=" part of
                    [ key, value ] ->
                        Just
                            ( key
                            , value
                                |> (if List.member key [ "columns", "sort" ] then
                                        String.replace "%2C" "+"

                                    else if key /= "q" then
                                        String.replace "%3B" "+"

                                    else
                                        identity
                                   )
                                |> String.split "+"
                                |> List.filterMap Url.percentDecode
                            )

                    _ ->
                        Nothing
            )
        |> Dict.fromList


updateModelFromDefaultsOrUrl : Model -> Model
updateModelFromDefaultsOrUrl model =
    let
        defaultParams : Dict String (List String)
        defaultParams =
            Dict.get model.pageId model.pageDefaultParams
                |> Maybe.withDefault (queryToParamsDict model.searchModel.defaultQuery)

        urlParams : Dict String (List String)
        urlParams =
            getQueryParamsDictFromUrl
                model.fixedParams
                model.url

        shouldApplyDefault : Bool
        shouldApplyDefault =
            urlParams
                |> Dict.remove "q"
                |> Dict.isEmpty

        paramsToUpdateWith : Dict String (List String)
        paramsToUpdateWith =
            if shouldApplyDefault then
                (Dict.insert
                    "q"
                    (Maybe.withDefault [] (Dict.get "q" urlParams))
                    defaultParams
                )

             else
                urlParams
    in
    { model | searchModel = updateSearchModelFromParams paramsToUpdateWith model model.searchModel }


updateSearchModelFromParams : Dict String (List String) -> Model -> SearchModel -> SearchModel
updateSearchModelFromParams params model searchModel =
    let
        query : String
        query =
            Dict.get "q" params
                |> Maybe.Extra.orElse (Dict.get "query" params)
                |> Maybe.withDefault []
                |> String.join " "
    in
    { searchModel
        | query = query
        , queryType =
            case Dict.get "type" params of
                Just [ "eqs" ] ->
                    ElasticsearchQueryString

                _ ->
                    if model.autoQueryType && queryCouldBeComplex query then
                        ElasticsearchQueryString

                    else
                        Standard
        , filteredAbilities = getBoolDictFromParams params "abilities"
        , filteredActions = getBoolDictFromParams params "actions"
        , filteredAlignments = getBoolDictFromParams params "alignments"
        , filteredArmorCategories = getBoolDictFromParams params "armor-categories"
        , filteredArmorGroups = getBoolDictFromParams params "armor-groups"
        , filteredComponents = getBoolDictFromParams params "components"
        , filteredCreatureFamilies = getBoolDictFromParams params "creature-families"
        , filteredHands = getBoolDictFromParams params "hands"
        , filteredItemCategories = getBoolDictFromParams params "item-categories"
        , filteredItemSubcategories = getBoolDictFromParams params "item-subcategories"
        , filteredPfs = getBoolDictFromParams params "pfs"
        , filteredRarities = getBoolDictFromParams params "rarities"
        , filteredRegions = getBoolDictFromParams params "regions"
        , filteredReloads = getBoolDictFromParams params "reloads"
        , filteredSavingThrows = getBoolDictFromParams params "saving-throws"
        , filteredSchools = getBoolDictFromParams params "schools"
        , filteredSizes = getBoolDictFromParams params "sizes"
        , filteredSkills = getBoolDictFromParams params "skills"
        , filteredSourceCategories = getBoolDictFromParams params "source-categories"
        , filteredSources = getBoolDictFromParams params "sources"
        , filteredStrongestSaves = getBoolDictFromParams params "strongest-saves"
        , filteredTraditions = getBoolDictFromParams params "traditions"
        , filteredTraits = getBoolDictFromParams params "traits"
        , filteredTypes = getBoolDictFromParams params "types"
        , filteredWeakestSaves = getBoolDictFromParams params "weakest-saves"
        , filteredWeaponCategories = getBoolDictFromParams params "weapon-categories"
        , filteredWeaponGroups = getBoolDictFromParams params "weapon-groups"
        , filteredWeaponTypes = getBoolDictFromParams params "weapon-types"
        , filterSpoilers = Dict.get "spoilers" params == Just [ "hide" ]
        , filterComponentsOperator = Dict.get "components-operator" params /= Just [ "or" ]
        , filterTraditionsOperator = Dict.get "traditions-operator" params /= Just [ "or" ]
        , filterTraitsOperator = Dict.get "traits-operator" params /= Just [ "or" ]
        , filteredFromValues =
            Dict.get "values-from" params
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
                                    if str == "random" then
                                        Just ( str, Asc )

                                    else
                                        Nothing
                        )
                    )
                |> Maybe.withDefault []
        , resultDisplay =
            case Dict.get "display" params of
                Just [ "full" ] ->
                    Full

                Just [ "grouped" ] ->
                    Grouped

                Just [ "table" ] ->
                    Table

                _ ->
                    List
        , tableColumns =
            if Dict.get "display" params == Just [ "table" ] then
                Dict.get "columns" params
                    |> Maybe.withDefault []

            else
                searchModel.tableColumns
        , groupField1 =
            if Dict.get "display" params == Just [ "grouped" ] then
                Dict.get "group-fields" params
                    |> Maybe.andThen List.head
                    |> Maybe.Extra.orElse
                        (Dict.get "group-field-1" params
                            |> Maybe.andThen List.head
                        )
                    |> Maybe.withDefault searchModel.groupField1

            else
                searchModel.groupField1
        , groupField2 =
            if Dict.get "display" params == Just [ "grouped" ] then
                Dict.get "group-fields" params
                    |> Maybe.andThen (List.Extra.getAt 1)
                    |> Maybe.Extra.orElse
                        (Dict.get "group-field-2" params
                            |> Maybe.andThen List.head
                        )

            else
                searchModel.groupField2
        , groupField3 =
            if Dict.get "display" params == Just [ "grouped" ] then
                Dict.get "group-fields" params
                    |> Maybe.andThen (List.Extra.getAt 2)
                    |> Maybe.Extra.orElse
                        (Dict.get "group-field-3" params
                            |> Maybe.andThen List.head
                        )

            else
                searchModel.groupField3
        , groupedLinkLayout =
            if Dict.get "display" params == Just [ "grouped" ] then
                case Dict.get "link-layout" params of
                    Just [ "horizontal" ] ->
                        Horizontal

                    Just [ "vertical" ] ->
                        Vertical

                    Just [ "vertical-with-summary" ] ->
                        VerticalWithSummary

                    _ ->
                        Horizontal

            else
                searchModel.groupedLinkLayout
    }


getBoolDictFromParams : Dict String (List String) -> String -> Dict String Bool
getBoolDictFromParams params param =
    List.append
        (Dict.get ("include-" ++ param) params
            |> Maybe.withDefault []
            |> List.map (\value -> ( value, True ))
        )
        (Dict.get ("exclude-" ++ param) params
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

                    [ "link-layout", _ ] ->
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
                        , "region"
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


getGlobalAggregations : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
getGlobalAggregations ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , Http.request
            { method = "POST"
            , url = model.elasticUrl ++ "/_search"
            , headers = []
            , body = Http.jsonBody (buildGlobalAggregationsBody model.searchModel)
            , expect = Http.expectJson GotGlobalAggregationsResult globalAggregationsDecoder
            , timeout = Just 10000
            , tracker = Nothing
            }
        ]
    )


buildGlobalAggregationsBody : SearchModel -> Encode.Value
buildGlobalAggregationsBody searchModel =
    Encode.object
        [ ( "aggs"
          , Encode.object
                [ buildCompositeAggregation
                    "trait_group"
                    False
                    [ ( "group", "trait_group" )
                    , ( "trait", "name.keyword" )
                    ]
                ]
          )
        , ( "size", Encode.int 0 )
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
    Field.attempt "noUi" Decode.bool <| \noUi ->
    Field.attempt "pageId" Decode.string <| \pageId ->
    Field.attempt "randomSeed" Decode.int <| \randomSeed ->
    Field.attempt "removeFilters" (Decode.list Decode.string) <| \removeFilters ->
    Field.attempt "showFilters" (Decode.list Decode.string) <| \showFilters ->
    Field.attempt "windowHeight" Decode.int <| \windowHeight ->
    Field.attempt "windowWidth" Decode.int <| \windowWidth ->
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
        , noUi = Maybe.withDefault defaultFlags.noUi noUi
        , pageId = Maybe.withDefault defaultFlags.pageId pageId
        , randomSeed = Maybe.withDefault defaultFlags.randomSeed randomSeed
        , removeFilters = Maybe.withDefault defaultFlags.removeFilters removeFilters
        , resultBaseUrl = Maybe.withDefault defaultFlags.resultBaseUrl resultBaseUrl
        , showFilters = Maybe.withDefault defaultFlags.showFilters showFilters
        , showHeader = Maybe.withDefault defaultFlags.showHeader showHeader
        , windowHeight = Maybe.withDefault defaultFlags.windowHeight windowHeight
        , windowWidth = Maybe.withDefault defaultFlags.windowWidth windowWidth
        }


encodeObjectMaybe : List (Maybe ( String, Encode.Value )) -> Encode.Value
encodeObjectMaybe list =
    Maybe.Extra.values list
        |> Encode.object


esResultDecoder : Decode.Decoder SearchResultWithDocuments
esResultDecoder =
    Field.requireAt [ "hits", "hits" ] (Decode.list documentDecoder) <| \documents ->
    Field.requireAt [ "hits", "hits" ] (Decode.list (Decode.field "sort" Decode.value)) <| \sorts ->
    Field.requireAt [ "hits", "total", "value" ] Decode.int <| \total ->
    Field.attempt "aggregations" groupAggregationsDecoder <| \groupAggs ->
    Decode.succeed
        { documents = documents
        , searchAfter =
            sorts
                |> List.Extra.last
                |> Maybe.withDefault Encode.null
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
        [ "aggregations", "region" ]
        (aggregationBucketDecoder Decode.string)
        <| \regions ->
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
        , regions = regions
        , reloads = reloads
        , sources = sources
        , traits = traits
        , types = types
        , weaponGroups = weaponGroups
        }


aggregationBucketDecoder : Decode.Decoder a -> Decode.Decoder (List a)
aggregationBucketDecoder keyDecoder =
    Decode.field "buckets" (Decode.list (Decode.field "key" keyDecoder))


globalAggregationsDecoder : Decode.Decoder GlobalAggregations
globalAggregationsDecoder =
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
    Decode.succeed
        { traitGroups =
            traitGroups
                |> Dict.Extra.groupBy .group
                |> Dict.map (\_ v -> List.map .trait v)
        }


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


stringListDecoder : Decode.Decoder (List String)
stringListDecoder =
    Decode.oneOf
        [ Decode.list Decode.string
        , Decode.string
            |> Decode.map List.singleton
        ]


documentDecoder : Decode.Decoder Document
documentDecoder =
    Field.require "_id" Decode.string <| \id ->
    Field.requireAt [ "_source", "category" ] Decode.string <| \category ->
    Field.requireAt [ "_source", "name" ] Decode.string <| \name ->
    Field.requireAt [ "_source", "type" ] Decode.string <| \type_ ->
    Field.requireAt [ "_source", "url" ] Decode.string <| \url ->
    Field.attemptAt [ "_source", "ability" ] stringListDecoder <| \abilities ->
    Field.attemptAt [ "_source", "ability_boost" ] stringListDecoder <| \abilityBoosts ->
    Field.attemptAt [ "_source", "ability_flaw" ] stringListDecoder <| \abilityFlaws ->
    Field.attemptAt [ "_source", "ability_type" ] Decode.string <| \abilityType ->
    Field.attemptAt [ "_source", "ac" ] Decode.int <| \ac ->
    Field.attemptAt [ "_source", "actions" ] Decode.string <| \actions ->
    Field.attemptAt [ "_source", "activate" ] Decode.string <| \activate ->
    Field.attemptAt [ "_source", "advanced_apocryphal_spell_markdown" ] Decode.string <| \advancedApocryphalSpell ->
    Field.attemptAt [ "_source", "advanced_domain_spell_markdown" ] Decode.string <| \advancedDomainSpell ->
    Field.attemptAt [ "_source", "alignment" ] Decode.string <| \alignment ->
    Field.attemptAt [ "_source", "ammunition" ] Decode.string <| \ammunition ->
    Field.attemptAt [ "_source", "apocryphal_spell_markdown" ] Decode.string <| \apocryphalSpell ->
    Field.attemptAt [ "_source", "archetype" ] Decode.string <| \archetype ->
    Field.attemptAt [ "_source", "area" ] Decode.string <| \area ->
    Field.attemptAt [ "_source", "armor_category" ] Decode.string <| \armorCategory ->
    Field.attemptAt [ "_source", "armor_group_markdown" ] Decode.string <| \armorGroup ->
    Field.attemptAt [ "_source", "aspect" ] Decode.string <| \aspect ->
    Field.attemptAt [ "_source", "attack_proficiency" ] stringListDecoder <| \attackProficiencies ->
    Field.attemptAt [ "_source", "base_item_markdown" ] Decode.string <| \baseItems ->
    Field.attemptAt [ "_source", "bloodline_markdown" ] Decode.string <| \bloodlines ->
    Field.attemptAt [ "_source", "breadcrumbs" ] Decode.string <| \breadcrumbs ->
    Field.attemptAt [ "_source", "bulk_raw" ] Decode.string <| \bulk ->
    Field.attemptAt [ "_source", "charisma" ] Decode.int <| \charisma ->
    Field.attemptAt [ "_source", "check_penalty" ] Decode.int <| \checkPenalty ->
    Field.attemptAt [ "_source", "complexity" ] Decode.string <| \complexity ->
    Field.attemptAt [ "_source", "component" ] stringListDecoder <| \components ->
    Field.attemptAt [ "_source", "constitution" ] Decode.int <| \constitution ->
    Field.attemptAt [ "_source", "cost_markdown" ] Decode.string <| \cost ->
    Field.attemptAt [ "_source", "creature_ability" ] stringListDecoder <| \creatureAbilities ->
    Field.attemptAt [ "_source", "creature_family" ] Decode.string <| \creatureFamily ->
    Field.attemptAt [ "_source", "creature_family_markdown" ] Decode.string <| \creatureFamilyMarkdown ->
    Field.attemptAt [ "_source", "damage" ] Decode.string <| \damage ->
    Field.attemptAt [ "_source", "defense_proficiency" ] stringListDecoder <| \defenseProficiencies ->
    Field.attemptAt [ "_source", "deity_markdown" ] Decode.string <| \deities ->
    Field.attemptAt [ "_source", "deity_category" ] Decode.string <| \deityCategory ->
    Field.attemptAt [ "_source", "dex_cap" ] Decode.int <| \dexCap ->
    Field.attemptAt [ "_source", "dexterity" ] Decode.int <| \dexterity ->
    Field.attemptAt [ "_source", "divine_font" ] stringListDecoder <| \divineFonts ->
    Field.attemptAt [ "_source", "domain_markdown" ] Decode.string <| \domains ->
    Field.attemptAt [ "_source", "domain_spell_markdown" ] Decode.string <| \domainSpell ->
    Field.attemptAt [ "_source", "duration" ] Decode.int <| \durationValue ->
    Field.attemptAt [ "_source", "duration_raw" ] Decode.string <| \duration ->
    Field.attemptAt [ "_source", "element" ] stringListDecoder <| \elements ->
    Field.attemptAt [ "_source", "familiar_ability" ] stringListDecoder <| \familiarAbilities ->
    Field.attemptAt [ "_source", "favored_weapon_markdown" ] Decode.string <| \favoredWeapons ->
    Field.attemptAt [ "_source", "feat_markdown" ] Decode.string <| \feats ->
    Field.attemptAt [ "_source", "fortitude_save" ] Decode.int <| \fort ->
    Field.attemptAt [ "_source", "fortitude_proficiency" ] Decode.string <| \fortitudeProficiency ->
    Field.attemptAt [ "_source", "follower_alignment" ] stringListDecoder <| \followerAlignments ->
    Field.attemptAt [ "_source", "frequency" ] Decode.string <| \frequency ->
    Field.attemptAt [ "_source", "hands" ] Decode.string <| \hands ->
    Field.attemptAt [ "_source", "hardness_raw" ] Decode.string <| \hardness ->
    Field.attemptAt [ "_source", "hazard_type" ] Decode.string <| \hazardType ->
    Field.attemptAt [ "_source", "heighten" ] stringListDecoder <| \heighten ->
    Field.attemptAt [ "_source", "heighten_level" ] (Decode.list Decode.int) <| \heightenLevels ->
    Field.attemptAt [ "_source", "hp_raw" ] Decode.string <| \hp ->
    Field.attemptAt [ "_source", "icon_image" ] Decode.string <| \iconImage ->
    Field.attemptAt [ "_source", "image" ] stringListDecoder <| \images ->
    Field.attemptAt [ "_source", "immunity_markdown" ] Decode.string <| \immunities ->
    Field.attemptAt [ "_source", "intelligence" ] Decode.int <| \intelligence ->
    Field.attemptAt [ "_source", "item_category" ] Decode.string <| \itemCategory ->
    Field.attemptAt [ "_source", "item_subcategory" ] Decode.string <| \itemSubcategory ->
    Field.attemptAt [ "_source", "language_markdown" ] Decode.string <| \languages ->
    Field.attemptAt [ "_source", "lesson_markdown" ] Decode.string <| \lessons ->
    Field.attemptAt [ "_source", "lesson_type" ] Decode.string <| \lessonType ->
    Field.attemptAt [ "_source", "level" ] Decode.int <| \level ->
    Field.attemptAt [ "_source", "markdown" ] Decode.string <| \markdown ->
    Field.attemptAt [ "_source", "mystery_markdown" ] Decode.string <| \mysteries ->
    Field.attemptAt [ "_source", "onset_raw" ] Decode.string <| \onset ->
    Field.attemptAt [ "_source", "patron_theme_markdown" ] Decode.string <| \patronThemes ->
    Field.attemptAt [ "_source", "perception" ] Decode.int <| \perception ->
    Field.attemptAt [ "_source", "perception_proficiency" ] Decode.string <| \perceptionProficiency ->
    Field.attemptAt [ "_source", "pfs" ] Decode.string <| \pfs ->
    Field.attemptAt [ "_source", "plane_category" ] Decode.string <| \planeCategory ->
    Field.attemptAt [ "_source", "prerequisite_markdown" ] Decode.string <| \prerequisites ->
    Field.attemptAt [ "_source", "price_raw" ] Decode.string <| \price ->
    Field.attemptAt [ "_source", "primary_check_markdown" ] Decode.string <| \primaryCheck ->
    Field.attemptAt [ "_source", "range" ] Decode.int <| \rangeValue ->
    Field.attemptAt [ "_source", "range_raw" ] Decode.string <| \range ->
    Field.attemptAt [ "_source", "rarity" ] Decode.string <| \rarity ->
    Field.attemptAt [ "_source", "reflex_save" ] Decode.int <| \ref ->
    Field.attemptAt [ "_source", "reflex_proficiency" ] Decode.string <| \reflexProficiency ->
    Field.attemptAt [ "_source", "region" ] Decode.string <| \region->
    Field.attemptAt [ "_source", "release_date" ] Decode.string <| \releaseDate ->
    Field.attemptAt [ "_source", "reload_raw" ] Decode.string <| \reload ->
    Field.attemptAt [ "_source", "required_abilities" ] Decode.string <| \requiredAbilities ->
    Field.attemptAt [ "_source", "requirement_markdown" ] Decode.string <| \requirements ->
    Field.attemptAt [ "_source", "resistance" ] damageTypeValuesDecoder <| \resistanceValues ->
    Field.attemptAt [ "_source", "resistance_markdown" ] Decode.string <| \resistances ->
    Field.attemptAt [ "_source", "saving_throw_markdown" ] Decode.string <| \savingThrow ->
    Field.attemptAt [ "_source", "school" ] Decode.string <| \school ->
    Field.attemptAt [ "_source", "search_markdown" ] Decode.string <| \searchMarkdown ->
    Field.attemptAt [ "_source", "secondary_casters_raw" ] Decode.string <| \secondaryCasters ->
    Field.attemptAt [ "_source", "secondary_check_markdown" ] Decode.string <| \secondaryChecks ->
    Field.attemptAt [ "_source", "sense_markdown" ] Decode.string <| \senses ->
    Field.attemptAt [ "_source", "size" ] stringListDecoder <| \sizes ->
    Field.attemptAt [ "_source", "skill_markdown" ] Decode.string <| \skills ->
    Field.attemptAt [ "_source", "skill_proficiency" ] stringListDecoder <| \skillProficiencies ->
    Field.attemptAt [ "_source", "source" ] stringListDecoder <| \sourceList ->
    Field.attemptAt [ "_source", "source_category" ] Decode.string <| \sourceCategory ->
    Field.attemptAt [ "_source", "source_group" ] Decode.string <| \sourceGroup ->
    Field.attemptAt [ "_source", "source_markdown" ] Decode.string <| \sources ->
    Field.attemptAt [ "_source", "speed" ] speedTypeValuesDecoder <| \speedValues ->
    Field.attemptAt [ "_source", "speed_markdown" ] Decode.string <| \speed ->
    Field.attemptAt [ "_source", "speed_penalty" ] Decode.string <| \speedPenalty ->
    Field.attemptAt [ "_source", "spell_markdown" ] Decode.string <| \spell ->
    Field.attemptAt [ "_source", "spell_list" ] Decode.string <| \spellList ->
    Field.attemptAt [ "_source", "spoilers" ] Decode.string <| \spoilers ->
    Field.attemptAt [ "_source", "stage_markdown" ] Decode.string <| \stages ->
    Field.attemptAt [ "_source", "strength" ] Decode.int <| \strength ->
    Field.attemptAt [ "_source", "strongest_save" ] stringListDecoder <| \strongestSaves ->
    Field.attemptAt [ "_source", "summary_markdown" ] Decode.string <| \summary ->
    Field.attemptAt [ "_source", "target_markdown" ] Decode.string <| \targets ->
    Field.attemptAt [ "_source", "tradition" ] stringListDecoder <| \traditionList ->
    Field.attemptAt [ "_source", "tradition_markdown" ] Decode.string <| \traditions ->
    Field.attemptAt [ "_source", "trait_markdown" ] Decode.string <| \traits ->
    Field.attemptAt [ "_source", "trait" ] stringListDecoder <| \traitList ->
    Field.attemptAt [ "_source", "trigger_markdown" ] Decode.string <| \trigger ->
    Field.attemptAt [ "_source", "usage_markdown" ] Decode.string <| \usage ->
    Field.attemptAt [ "_source", "vision" ] Decode.string <| \vision ->
    Field.attemptAt [ "_source", "weakest_save" ] stringListDecoder <| \weakestSaves ->
    Field.attemptAt [ "_source", "weakness" ] damageTypeValuesDecoder <| \weaknessValues ->
    Field.attemptAt [ "_source", "weakness_markdown" ] Decode.string <| \weaknesses ->
    Field.attemptAt [ "_source", "weapon_category" ] Decode.string <| \weaponCategory ->
    Field.attemptAt [ "_source", "weapon_group" ] Decode.string <| \weaponGroup ->
    Field.attemptAt [ "_source", "weapon_group_markdown" ] Decode.string <| \weaponGroupMarkdown ->
    Field.attemptAt [ "_source", "weapon_type" ] Decode.string <| \weaponType ->
    Field.attemptAt [ "_source", "will_save" ] Decode.int <| \will ->
    Field.attemptAt [ "_source", "will_proficiency" ] Decode.string <| \willProficiency ->
    Field.attemptAt [ "_source", "wisdom" ] Decode.int <| \wisdom ->
    Decode.succeed
        { id = id
        , category = category
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
        , creatureAbilities = Maybe.withDefault [] creatureAbilities
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
        , elements = Maybe.withDefault [] elements
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
        , markdown = NotParsed (Maybe.withDefault "" markdown)
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
        , searchMarkdown = NotParsed (Maybe.withDefault "" searchMarkdown)
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
        , spell = spell
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


paramsDecoder : Decode.Decoder (Dict String (Dict String (List String)))
paramsDecoder =
    Decode.oneOf
        [ Decode.dict (Decode.dict (Decode.list Decode.string))
        , Decode.dict (Decode.dict Decode.string)
            |> Decode.map
                (Dict.map
                    (\_ ->
                        Dict.map
                            (\key ->
                                if List.member key [ "columns", "sort" ] then
                                    String.split ","

                                else if key /= "q" then
                                    String.split ";"

                                else
                                    List.singleton
                            )
                    )
                )
        ]


type Markdown
    = Parsed ParsedMarkdownResult
    | NotParsed String


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
                                                [ Markdown.Block.Paragraph
                                                    (List.concat
                                                        [ prevInlines
                                                        , [ Markdown.Block.Text " " ]
                                                        , inlines
                                                        ]
                                                    )
                                                ]

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
            [ Html.text
                (css
                    { pageWidth = model.pageWidth
                    }
                )

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
        , if model.noUi then
            Html.text ""

          else
            Html.div
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

        , viewLinkPreview model
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
                [ Html.h1
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
        [ Html.h2
            [ HA.class "title" ]
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


viewLinkPreview : Model -> Html Msg
viewLinkPreview model =
    case model.previewLink of
        Just link ->
            case Dict.get link.documentId model.documents of
                Just (Ok doc) ->
                    let
                        top : Int
                        top =
                            link.elementPosition.y
                                + link.elementPosition.height
                                + 8

                        bottom : Int
                        bottom =
                            model.bodySize.height
                                - link.elementPosition.y
                                + 8
                    in
                    Html.div
                        [ HA.id "preview"
                        , HA.class "preview"
                        , HA.class "fade-in"
                        , HA.class "column"
                        , HA.class "gap-medium"
                        , if link.elementPosition.x + 830 < model.bodySize.width then
                            HA.style "left" (String.fromInt link.elementPosition.x ++ "px")

                          else
                            HA.style "left"
                                (String.fromInt
                                    (max
                                        (model.bodySize.width - 830)
                                        8
                                    )
                                    ++ "px"
                                )

                        , if top + 620 < model.bodySize.height
                            || top + 620 < model.windowSize.height
                            || 620 + bottom > model.windowSize.height
                          then
                            HA.style "top" (String.fromInt top ++ "px")

                          else
                            HA.style "bottom" (String.fromInt bottom ++ "px")
                        ]
                        (viewDocument model doc.id 0 Nothing)

                _ ->
                    Html.text ""

        Nothing ->
            Html.text ""


viewDocument : Model -> String -> Int -> Maybe String -> List (Html Msg)
viewDocument model id titleLevel overrideRight =
    case Dict.get id model.documents of
        Just (Ok document) ->
            case document.markdown of
                Parsed parsed ->
                    viewMarkdown model document.id titleLevel overrideRight parsed

                NotParsed _ ->
                    [ Html.div
                        [ HA.style "color" "red" ]
                        [ Html.text ("Not parsed: " ++ document.id) ]
                    ]

        Just (Err (Http.BadStatus 404)) ->
            [ Html.div
                [ HA.class "row"
                , HA.class "justify-center"
                , HA.style "font-size" "var(--font-very-large)"
                , HA.style "font-variant" "small-caps"
                ]
                [ Html.text "Page not found" ]
            ]

        Just (Err _) ->
            [ Html.div
                [ HA.style "color" "red" ]
                [ Html.text ("Failed to load " ++ id) ]
            ]

        Nothing ->
            [ Html.div
                [ HA.class "loader"
                , HA.style "margin-top" "20px"
                ]
                []
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
                |> List.filter (\filter -> filter.visibleIf searchModel)

        visibleFilters : List FilterBox
        visibleFilters =
            if searchModel.showAllFilters || List.length availableFilters <= 8 then
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
                                    (not (List.member filter.id searchModel.visibleFilterBoxes))
                                )
                            , HAE.attributeIf
                                (List.member filter.id searchModel.visibleFilterBoxes)
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
                                    (not (List.member filter.id searchModel.visibleFilterBoxes))
                                )
                            , HAE.attributeIf
                                (List.member filter.id searchModel.visibleFilterBoxes)
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
            (allFilters ++ allOptions
                |> List.filterMap
                    (\filterBox ->
                        case List.Extra.elemIndex filterBox.id searchModel.visibleFilterBoxes of
                            Just idx ->
                                Just ( idx, filterBox )

                            Nothing ->
                                Nothing
                    )
                |> List.sortBy Tuple.first
                |> List.map Tuple.second
                |> List.map (viewOptionBox model searchModel)
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
            [ Html.h2
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
      , visibleIf = \_ -> True
      }
    , { id = "abilities"
      , label = "Abilities (Boosts)"
      , view = viewFilterAbilities
      , visibleIf = \_ -> True
      }
    , { id = "actions"
      , label = "Actions / Cast time"
      , view = viewFilterActions
      , visibleIf = moreThanOneAggregation .actions
      }
    , { id = "alignments"
      , label = "Alignments"
      , view = viewFilterAlignments
      , visibleIf = \_ -> True
      }
    , { id = "armor"
      , label = "Armor"
      , view = viewFilterArmor
      , visibleIf = getAggregation .types >> List.member "armor"
      }
    , { id = "components"
      , label = "Casting components"
      , view = viewFilterComponents
      , visibleIf = \_ -> True
      }
    , { id = "creature-families"
      , label = "Creature families"
      , view = viewFilterCreatureFamilies
      , visibleIf = moreThanOneAggregation .creatureFamilies
      }
    , { id = "item-categories"
      , label = "Item categories"
      , view = viewFilterItemCategories
      , visibleIf =
            \searchModel ->
                (moreThanOneAggregation .itemCategories searchModel)
                    || (moreThanOneAggregation .itemSubcategories searchModel)
      }
    , { id = "hands"
      , label = "Hands"
      , view = viewFilterHands
      , visibleIf = moreThanOneAggregation .hands
      }
    , { id = "schools"
      , label = "Magic schools"
      , view = viewFilterMagicSchools
      , visibleIf = \_ -> True
      }
    , { id = "pfs"
      , label = "PFS"
      , view = viewFilterPfs
      , visibleIf = \_ -> True
      }
    , { id = "rarities"
      , label = "Rarities"
      , view = viewFilterRarities
      , visibleIf = moreThanOneAggregation .traits
      }
    , { id = "regions"
      , label = "Regions"
      , view = viewFilterRegions
      , visibleIf = moreThanOneAggregation .regions
      }
    , { id = "saving-throws"
      , label = "Saving throws"
      , view = viewFilterSavingThrows
      , visibleIf = \_ -> True
      }
    , { id = "sizes"
      , label = "Sizes"
      , view = viewFilterSizes
      , visibleIf = \_ -> True
      }
    , { id = "skills"
      , label = "Skills"
      , view = viewFilterSkills
      , visibleIf = \_ -> True
      }
    , { id = "sources"
      , label = "Sources & Spoilers"
      , view = viewFilterSources
      , visibleIf = \_ -> True
      }
    , { id = "strongest-saves"
      , label = "Strongest / Weakest saves"
      , view = viewFilterStrongestSaves
      , visibleIf = \_ -> True
      }
    , { id = "traditions"
      , label = "Traditions / Spell lists"
      , view = viewFilterTraditions
      , visibleIf = \_ -> True
      }
    , { id = "traits"
      , label = "Traits"
      , view = viewFilterTraits
      , visibleIf = moreThanOneAggregation .traits
      }
    , { id = "types"
      , label = "Types / Categories"
      , view = viewFilterTypes
      , visibleIf = moreThanOneAggregation .types
      }
    , { id = "weapons"
      , label = "Weapons"
      , view = viewFilterWeapons
      , visibleIf = getAggregation .types >> List.member "weapon"
      }
    ]


allOptions : List FilterBox
allOptions =
    [ { id = "query-type"
      , label = "Query type"
      , view = viewQueryType
      , visibleIf = \_ -> True
      }
    , { id = "display"
      , label = "Result display"
      , view = viewResultDisplay
      , visibleIf = \_ -> True
      }
    , { id = "sort"
      , label = "Sort results"
      , view = viewSortResults
      , visibleIf = \_ -> True
      }
    , { id = "page-size"
      , label = "Result amount"
      , view = viewResultPageSize
      , visibleIf = \_ -> True
      }
    , { id = "settings"
      , label = "General settings"
      , view = viewGeneralSettings
      , visibleIf = \_ -> True
      }
    , { id = "default-params"
      , label = "Default params"
      , view = viewDefaultParams
      , visibleIf = \_ -> True
      }
    ]


getAggregation : (Aggregations -> List a) -> SearchModel -> List a
getAggregation fun searchModel =
    searchModel.aggregations
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map fun
        |> Maybe.withDefault []


moreThanOneAggregation : (Aggregations -> List a) -> SearchModel -> Bool
moreThanOneAggregation fun searchModel =
    getAggregation fun searchModel
        |> List.length
        |> (<) 1


filterFields : SearchModel -> List ( String, Dict String Bool, Bool )
filterFields searchModel =
    [ ( "ability", searchModel.filteredAbilities, False )
    , ( "actions.keyword", searchModel.filteredActions, False )
    , ( "alignment", searchModel.filteredAlignments, False )
    , ( "armor_category", searchModel.filteredArmorCategories, False )
    , ( "armor_group", searchModel.filteredArmorGroups, False )
    , ( "component", searchModel.filteredComponents, searchModel.filterComponentsOperator )
    , ( "creature_family", searchModel.filteredCreatureFamilies, False )
    , ( "hands.keyword", searchModel.filteredHands, False )
    , ( "item_category", searchModel.filteredItemCategories, False )
    , ( "item_subcategory", searchModel.filteredItemSubcategories, False )
    , ( "pfs", searchModel.filteredPfs, False )
    , ( "rarity", searchModel.filteredRarities, False )
    , ( "region", searchModel.filteredRegions, False )
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
            viewActiveFilters True searchModel

        , viewActiveSorts True searchModel

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


viewActiveFilters : Bool -> SearchModel -> Html Msg
viewActiveFilters canClick searchModel =
    Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        , HA.class "align-center"
        ]
        (List.append
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
                                            , HAE.attributeIf canClick (HE.onClick (removeMsg value))
                                            ]
                                            (List.append
                                                [ viewPfsIcon 16 value
                                                ]
                                                (viewTextWithActionIcons (toTitleCase value))
                                            )
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
                  , label = "Include armor categories:"
                  , list = boolDictIncluded searchModel.filteredArmorCategories
                  , removeMsg = ArmorCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude armor categories:"
                  , list = boolDictExcluded searchModel.filteredArmorCategories
                  , removeMsg = ArmorCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include armor groups:"
                  , list = boolDictIncluded searchModel.filteredArmorGroups
                  , removeMsg = ArmorGroupFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude armor groups:"
                  , list = boolDictExcluded searchModel.filteredArmorGroups
                  , removeMsg = ArmorGroupFilterRemoved
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
                                            [ HAE.attributeIf canClick (HE.onClick (FilteredFromValueChanged field ""))
                                            ]
                                            [ Html.text ("at least " ++ from ++ " " ++ sortFieldSuffix field) ]
                                    )
                                |> Maybe.withDefault (Html.text "")
                            , maybeTo
                                |> Maybe.map
                                    (\to ->
                                        Html.button
                                            [ HAE.attributeIf canClick (HE.onClick (FilteredToValueChanged field ""))
                                            ]
                                            [ Html.text ("up to " ++ to ++ " " ++ sortFieldSuffix field) ]
                                    )
                                |> Maybe.withDefault (Html.text "")
                            ]
                    )
            )
        )


viewActiveSorts : Bool -> SearchModel -> Html Msg
viewActiveSorts canClick searchModel =
    if List.isEmpty searchModel.sort then
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
                            , HAE.attributeIf canClick (HE.onClick (SortRemoved field))
                            ]
                            [ Html.text
                                (if field == "random" then
                                    "Random"

                                 else
                                    field
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
                    [ Html.text (toTitleCase ability)
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
                            [ Html.span
                                []
                                (viewTextWithActionIcons actions)
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


viewFilterArmor : Model -> SearchModel -> List (Html Msg)
viewFilterArmor model searchModel =
    [ Html.h4
        []
        [ Html.text "Armor categories" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllArmorCategoryFiltersPressed
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
                    , HE.onClick (ArmorCategoryFilterAdded category)
                    ]
                    [ Html.text (toTitleCase category)
                    , viewFilterIcon (Dict.get category searchModel.filteredArmorCategories)
                    ]
            )
            Data.armorCategories
        )

    , Html.h4
        []
        [ Html.text "Armor groups" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllArmorGroupFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\group ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HE.onClick (ArmorGroupFilterAdded group)
                    ]
                    [ Html.text (toTitleCase group)
                    , viewFilterIcon (Dict.get group searchModel.filteredArmorGroups)
                    ]
            )
            Data.armorGroups
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
                    [ Html.text (toTitleCase component)
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
                            [ Html.text (toTitleCase creatureFamily)
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
                                [ Html.text (toTitleCase category) ]
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
                                [ Html.text (toTitleCase subcategory.name) ]
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
                    [ Html.text (toTitleCase school)
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
                    , Html.text (toTitleCase pfs)
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
                            [ Html.text (toTitleCase rarity)
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


viewFilterRegions : Model -> SearchModel -> List (Html Msg)
viewFilterRegions model searchModel =
    [ Html.button
        [ HA.style "align-self" "flex-start"
        , HA.style "justify-self" "flex-start"
        , HE.onClick RemoveAllRegionFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        , HA.class "wrap"
        ]
        (case searchModel.aggregations of
            Just (Ok { regions })->
                (List.map
                    (\region ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (RegionFilterAdded region)
                            ]
                            [ Html.text (toTitleCase region)
                            , viewFilterIcon (Dict.get region searchModel.filteredRegions)
                            ]
                    )
                    (List.sort regions)
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
                    [ Html.text (toTitleCase save)
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
                    [ Html.text (toTitleCase size)
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
                    [ Html.text (toTitleCase skill)
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
                    [ Html.text (toTitleCase category)
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
                    [ Html.text (toTitleCase save)
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
                    [ Html.text (toTitleCase save)
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
                    [ Html.text (toTitleCase tradition)
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
            (case ( model.globalAggregations, searchModel.aggregations ) of
                ( Just (Ok globalAggregations), Just (Ok aggregations) ) ->
                    let
                        categorizedTraits : List String
                        categorizedTraits =
                            globalAggregations.traitGroups
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
                                        [ Html.text (toTitleCase group) ]
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
                                                [ Html.text (toTitleCase trait)
                                                , viewFilterIcon (Dict.get trait searchModel.filteredTraits)
                                                ]
                                        )
                                        (List.sort traits)
                                    )
                                ]
                        )
                        (globalAggregations.traitGroups
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
                            |> List.map (Tuple.mapSecond (List.filter (\trait -> List.member trait aggregations.traits)))
                            |> List.filter (Tuple.second >> List.isEmpty >> not)
                        )
                    )

                ( Nothing, Nothing ) ->
                    [ viewScrollboxLoader ]

                _ ->
                    []

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
                                [ Html.text (toTitleCase trait)
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
                            [ Html.text (toTitleCase type_)
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
                    [ Html.text (toTitleCase category)
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
                            [ Html.text (toTitleCase group)
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
                    [ Html.text (toTitleCase type_)
                    , viewFilterIcon (Dict.get type_ searchModel.filteredWeaponTypes)
                    ]
            )
            Data.weaponTypes
        )

    , Html.h4
        []
        [ Html.text "Reload" ]
    , Html.button
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
                , { field = "damage_die"
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
                                        [ Html.text (toTitleCase speed)
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
                [ HA.style "color" "var(--color-text-inactive)" ]
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


viewGeneralSettings : Model -> SearchModel -> List (Html Msg)
viewGeneralSettings model searchModel =
    [ viewCheckbox
        { checked = model.openInNewTab
        , onCheck = OpenInNewTabChanged
        , text = "Links open in new tab"
        }
    , Html.h4
        []
        [ Html.text "Max width" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        (List.append
            (List.map
                (\width ->
                    viewRadioButton
                        { checked = model.pageWidth == width
                        , enabled = True
                        , name = "page-width"
                        , onInput = PageWidthChanged width
                        , text = String.fromInt width ++ "px"
                        }
                )
                Data.allPageWidths
            )
            [ viewRadioButton
                { checked = model.pageWidth == 0
                , enabled = True
                , name = "page-width"
                , onInput = PageWidthChanged 0
                , text = "Unlimited"
                }
            ]
        )

    , viewCheckbox
        { checked = not model.limitTableWidth
        , onCheck = not >> LimitTableWidthChanged
        , text = "Tables always use full width"
        }
    ]


viewDefaultParams : Model -> SearchModel -> List (Html Msg)
viewDefaultParams model searchModel =
    let
        pageDefaultSearchModel : SearchModel
        pageDefaultSearchModel =
            updateSearchModelFromParams
                (Dict.get model.pageId model.pageDefaultParams
                    |> Maybe.withDefault (queryToParamsDict searchModel.defaultQuery)
                )
                model
                model.searchModel
    in
    [ Html.text
        """
        Default parameters are automatically applied when you visit a page without
        any search parameters in the URL. These defaults are saved per page
        type. You can view the defaults for the current page type below.
        """
    , Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        ]
        [ Html.button
            [ HE.onClick SaveDefaultParamsPressed
            ]
            [ Html.text "Save current filters as default" ]
        ]
    , Html.h3
        []
        [ Html.text ("Defaults for " ++ model.pageId) ]
    , viewActiveFilters False pageDefaultSearchModel
    , viewActiveSorts False pageDefaultSearchModel
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ Html.div
            []
            [ Html.text "Display: "
            , Html.text
                (case pageDefaultSearchModel.resultDisplay of
                    List ->
                        "List"

                    Full ->
                        "Full"

                    Table ->
                        "Table"

                    Grouped ->
                        "Grouped"
                )
            ]
        , case pageDefaultSearchModel.resultDisplay of
            Table ->
                Html.div
                    []
                    [ Html.text "Columns: "
                    , Html.text
                        (pageDefaultSearchModel.tableColumns
                            |> List.map String.Extra.humanize
                            |> List.map toTitleCase
                            |> String.join ", "
                        )
                    ]

            _ ->
                Html.text ""
        ]
    ]


viewResultDisplay : Model -> SearchModel -> List (Html Msg)
viewResultDisplay model searchModel =
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
            { checked = searchModel.resultDisplay == Full
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged Full
            , text = "Full"
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
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        (case searchModel.resultDisplay of
            List ->
                viewResultDisplayList model

            Full ->
                viewResultDisplayFull model

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


viewResultDisplayFull : Model -> List (Html Msg)
viewResultDisplayFull model =
    []


viewResultDisplayTable : Model -> SearchModel -> List (Html Msg)
viewResultDisplayTable model searchModel =
    [ Html.h4
        []
        [ Html.text "Table configuration" ]
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
                [ HA.class "row"
                , HA.class "input-container"
                ]
                [ Html.input
                    [ HA.placeholder "Filter columns"
                    , HA.value searchModel.searchTableColumns
                    , HA.type_ "text"
                    , HE.onInput SearchTableColumnsChanged
                    ]
                    []
                , if String.isEmpty searchModel.searchTableColumns then
                    Html.text ""

                  else
                    Html.button
                        [ HA.class "input-button"
                        , HE.onClick (SearchTableColumnsChanged "")
                        ]
                        [ FontAwesome.view FontAwesome.Solid.times ]
                ]
            , Html.div
                [ HA.class "scrollbox"
                , HA.class "column"
                , HA.class "gap-small"
                , HA.style "max-height" "170px"
                ]
                (List.concatMap
                    (viewResultDisplayTableColumn searchModel)

                    (Data.tableColumns
                        |> List.filter
                            (String.toLower
                                >> String.replace "_" " "
                                >> String.contains (String.toLower searchModel.searchTableColumns)
                            )
                    )
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
                , "element"
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
        [ Html.text "Link layout" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = searchModel.groupedLinkLayout == Horizontal
            , enabled = True
            , name = "grouped-results"
            , onInput = GroupedLinkLayoutChanged Horizontal
            , text = "Horizontal"
            }
        , viewRadioButton
            { checked = searchModel.groupedLinkLayout == Vertical
            , enabled = True
            , name = "grouped-results"
            , onInput = GroupedLinkLayoutChanged Vertical
            , text = "Vertical"
            }
        , viewRadioButton
            { checked = searchModel.groupedLinkLayout == VerticalWithSummary
            , enabled = True
            , name = "grouped-results"
            , onInput = GroupedLinkLayoutChanged VerticalWithSummary
            , text = "Vertical with summary"
            }
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

    , Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ viewCheckbox
            { checked = model.groupedShowPfs
            , onCheck = GroupedShowPfsIconChanged
            , text = "Show PFS icons"
            }
        , viewCheckbox
            { checked = model.groupedShowRarity
            , onCheck = GroupedShowRarityChanged
            , text = "Show Rarity"
            }
        ]
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
                            , if field == "random" then
                                Html.text ""

                              else
                                Html.button
                                    [ HE.onClick (SortAdded field (if dir == Asc then Desc else Asc))
                                    ]
                                    [ getSortIcon field (Just dir)
                                    ]
                            , if field == "random" then
                                Html.text ""

                              else
                                Html.button
                                    [ HA.disabled (index == 0)
                                    , HE.onClick (SortOrderChanged index (index - 1))
                                    ]
                                    [ FontAwesome.view FontAwesome.Solid.chevronUp
                                    ]
                            , if field == "random" then
                                Html.text ""

                              else
                                Html.button
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
        [ HA.class "row"
        , HA.class "gap-medium"
        , HA.class "align-center"
        ]
        [ Html.button
            [ HE.onClick
                (if List.member ( "random", Asc ) searchModel.sort then
                    (SortRemoved "random")

                 else
                    (SortAdded "random" Asc)
                )
            , HAE.attributeIf (List.member ( "random", Asc ) searchModel.sort) (HA.class "active")
            ]
            [ Html.text "Random sort" ]
        , if sortIsRandom model.searchModel then
            Html.text ("Current seed: " ++ String.fromInt model.randomSeed)

          else
            Html.text ""
        , if sortIsRandom model.searchModel then
            Html.button
                [ HE.onClick NewRandomSeedPressed
                ]
                [ Html.text "New seed" ]

          else
            Html.text ""
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
                |> List.map (Maybe.map .documentIds)
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

                Full ->
                    viewSearchResultsFull model searchModel remaining

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
                    r.documentIds
                        |> List.filterMap (\id -> Dict.get id model.documents)
                        |> List.filterMap Result.toMaybe
                        |> List.map (viewSingleSearchResult model)

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


viewSingleSearchResult : Model -> Document -> Html Msg
viewSingleSearchResult model document =
    let
        hasActionsInTitle : Bool
        hasActionsInTitle =
            List.member document.category [ "action", "creature-ability", "feat" ]
    in
    Html.section
        [ HA.class "column"
        , HA.class "gap-small"
        , HA.class "limit-width"
        , HA.class "fill-width-with-padding"
        , HA.class "fade-in"
        ]
        [ Html.h1
            [ HA.class "title" ]
            [ Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                , HA.class "nowrap"
                ]
                (List.append
                    [ viewPfsIconWithLink 25 (Maybe.withDefault "" document.pfs)
                    , Html.a
                        (List.append
                            [ HA.href (getUrl model document)
                            , HAE.attributeIf model.openInNewTab (HA.target "_blank")
                            ]
                            (linkEventAttributes document.url)
                        )
                        [ Html.text document.name
                        ]
                    ]
                    (case ( document.actions, hasActionsInTitle ) of
                        ( Just actions, True ) ->
                            viewTextWithActionIcons (" " ++ actions)

                        _ ->
                            []
                    )
                )
            , Html.div
                [ HA.class "title-type"
                ]
                [ Html.text document.type_
                , case document.level of
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
                (case document.searchMarkdown of
                    Parsed parsed ->
                        viewMarkdown model document.id 0 Nothing parsed

                    NotParsed _ ->
                        [ Html.div
                            [ HA.style "color" "red" ]
                            [ Html.text ("Not parsed: " ++ document.id) ]
                        ]
                )
        ]


viewSearchResultsFull : Model -> SearchModel -> Int -> List (Html Msg)
viewSearchResultsFull model searchModel remaining =
    [ List.concatMap
        (\result ->
            case result of
                Ok r ->
                    List.map
                        (\id ->
                            Html.section
                                [ HA.class "column"
                                , HA.class "gap-small"
                                , HA.class "limit-width"
                                , HA.class "fill-width-with-padding"
                                , HA.class "fade-in"
                                ]
                                (viewDocument model id 0 Nothing)
                        )
                        r.documentIds

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
    ]
        |> List.concat


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
                            r.documentIds
                                |> List.filterMap (\id -> Dict.get id model.documents)
                                |> List.filterMap Result.toMaybe
                                |> List.map
                                    (\document ->
                                        Html.tr
                                            []
                                            (List.map
                                                (viewSearchResultGridCell model document)
                                                ("name" :: searchModel.tableColumns)
                                            )
                                    )

                        Err _ ->
                            []
                )
                searchModel.searchResults
                |> List.concat
            )
        ]


viewSearchResultGridCell : Model -> Document -> String -> Html Msg
viewSearchResultGridCell model document column =
    let
        maybeAsMarkdown : Maybe String -> List (Html Msg)
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
                document.abilities
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "ability_boost" ] ->
                document.abilities
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "ability_flaw" ] ->
                document.abilityFlaws
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "ability_type" ] ->
                maybeAsText document.abilityType

            [ "ac" ] ->
                document.ac
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "actions" ] ->
                document.actions
                    |> Maybe.withDefault ""
                    |> viewTextWithActionIcons

            [ "advanced_apocryphal_spell" ] ->
                maybeAsMarkdown document.advancedApocryphalSpell

            [ "advanced_domain_spell" ] ->
                maybeAsMarkdown document.advancedDomainSpell

            [ "alignment" ] ->
                maybeAsText document.alignment

            [ "apocryphal_spell" ] ->
                maybeAsMarkdown document.apocryphalSpell

            [ "archetype" ] ->
                maybeAsText document.archetype

            [ "area" ] ->
                maybeAsText document.area

            [ "armor_category" ] ->
                maybeAsText document.armorCategory

            [ "armor_group" ] ->
                maybeAsMarkdown document.armorGroup

            [ "aspect" ] ->
                document.aspect
                    |> Maybe.map toTitleCase
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
                        document.attackProficiencies
                    )
                ]

            [ "base_item" ] ->
                maybeAsMarkdown document.baseItems

            [ "bloodline" ] ->
                maybeAsMarkdown document.bloodlines

            [ "bulk" ] ->
                maybeAsText document.bulk

            [ "charisma" ] ->
                document.charisma
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "check_penalty" ] ->
                document.checkPenalty
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "creature_ability" ] ->
                document.creatureAbilities
                    |> List.sort
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "creature_family" ] ->
                maybeAsMarkdown document.creatureFamilyMarkdown

            [ "complexity" ] ->
                maybeAsText document.complexity

            [ "component" ] ->
                document.components
                    |> List.map toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "constitution" ] ->
                document.constitution
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "cost" ] ->
                maybeAsMarkdown document.cost

            [ "deity" ] ->
                maybeAsMarkdown document.deities

            [ "deity_category" ] ->
                maybeAsText document.deityCategory

            [ "damage" ] ->
                maybeAsText document.damage

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
                        document.defenseProficiencies
                    )
                ]

            [ "dexterity" ] ->
                document.dexterity
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "dex_cap" ] ->
                document.dexCap
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "divine_font" ] ->
                document.divineFonts
                    |> List.map toTitleCase
                    |> String.join " or "
                    |> Html.text
                    |> List.singleton

            [ "domain" ] ->
                maybeAsMarkdown document.domains

            [ "domain_spell" ] ->
                maybeAsMarkdown document.domainSpell

            [ "duration" ] ->
                maybeAsText document.duration

            [ "element" ] ->
                document.elements
                    |> List.map toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "favored_weapon" ] ->
                maybeAsMarkdown document.favoredWeapons

            [ "feat" ] ->
                maybeAsMarkdown document.feats

            [ "follower_alignment" ] ->
                document.followerAlignments
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "fortitude" ] ->
                document.fort
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "fortitude_proficiency" ] ->
                maybeAsText document.fortitudeProficiency

            [ "frequency" ] ->
                maybeAsText document.frequency

            [ "hands" ] ->
                maybeAsText document.hands

            [ "hardness" ] ->
                maybeAsText document.hardness

            [ "hazard_type" ] ->
                maybeAsText document.hazardType

            [ "heighten" ] ->
                document.heighten
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "heighten_level" ] ->
                document.heightenLevels
                    |> List.map String.fromInt
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "hp" ] ->
                maybeAsText document.hp

            [ "icon_image" ] ->
                case document.iconImage of
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
                case document.images of
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
                maybeAsMarkdown document.immunities

            [ "intelligence" ] ->
                document.intelligence
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "item_category" ] ->
                maybeAsText document.itemCategory

            [ "item_subcategory" ] ->
                maybeAsText document.itemSubcategory

            [ "language" ] ->
                maybeAsMarkdown document.languages

            [ "lesson" ] ->
                maybeAsMarkdown document.lessons

            [ "level" ] ->
                document.level
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "mystery" ] ->
                maybeAsMarkdown document.mysteries

            [ "name" ] ->
                [ Html.a
                    (List.append
                        [ HA.href (getUrl model document)
                        , HAE.attributeIf model.openInNewTab (HA.target "_blank")
                        ]
                        (linkEventAttributes (getUrl model document))
                    )
                    [ Html.text document.name
                    ]
                ]

            [ "onset" ] ->
                maybeAsText document.onset

            [ "patron_theme" ] ->
                maybeAsMarkdown document.patronThemes

            [ "perception" ] ->
                document.perception
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "perception_proficiency" ] ->
                maybeAsText document.perceptionProficiency

            [ "pfs" ] ->
                document.pfs
                    |> Maybe.withDefault ""
                    |> viewPfsIconWithLink 20
                    |> List.singleton
                    |> Html.div
                        [ HA.class "column"
                        , HA.class "align-center"
                        ]
                    |> List.singleton

            [ "plane_category" ] ->
                maybeAsText document.planeCategory

            [ "prerequisite" ] ->
                maybeAsMarkdown document.prerequisites

            [ "price" ] ->
                maybeAsText document.price

            [ "primary_check" ] ->
                maybeAsMarkdown document.primaryCheck

            [ "range" ] ->
                maybeAsText document.range

            [ "rarity" ] ->
                document.rarity
                    |> Maybe.map toTitleCase
                    |> maybeAsText

            [ "reflex" ] ->
                document.ref
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "reflex_proficiency" ] ->
                maybeAsText document.reflexProficiency

            [ "region" ] ->
                maybeAsText document.region

            [ "release_date" ] ->
                maybeAsText document.releaseDate

            [ "reload" ] ->
                maybeAsText document.reload

            [ "requirement" ] ->
                maybeAsMarkdown document.requirements

            [ "resistance" ] ->
                maybeAsMarkdown document.resistances

            [ "resistance", type_ ] ->
                document.resistanceValues
                    |> Maybe.andThen (getDamageTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "saving_throw" ] ->
                maybeAsMarkdown document.savingThrow

            [ "school" ] ->
                document.school
                    |> Maybe.map toTitleCase
                    |> maybeAsText

            [ "secondary_casters" ] ->
                maybeAsText document.secondaryCasters

            [ "secondary_check" ] ->
                maybeAsMarkdown document.secondaryChecks

            [ "sense" ] ->
                maybeAsMarkdown document.senses

            [ "size" ] ->
                document.sizes
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "skill" ] ->
                maybeAsMarkdown document.skills

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
                        document.skillProficiencies
                    )
                ]

            [ "source" ] ->
                maybeAsMarkdown document.sources

            [ "source_category" ] ->
                maybeAsText document.sourceCategory

            [ "source_group" ] ->
                maybeAsText document.sourceGroup

            [ "speed" ] ->
                maybeAsMarkdown document.speed

            [ "speed", type_ ] ->
                document.speedValues
                    |> Maybe.andThen (getSpeedTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "speed_penalty" ] ->
                maybeAsText document.speedPenalty

            [ "spell" ] ->
                maybeAsMarkdown document.spell

            [ "spoilers" ] ->
                maybeAsText document.spoilers

            [ "stage" ] ->
                maybeAsMarkdown document.stages

            [ "strength" ] ->
                document.strength
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "strength_req" ] ->
                document.strength
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "strongest_save" ] ->
                document.strongestSaves
                    |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                    |> List.map toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "summary" ] ->
                maybeAsMarkdown document.summary

            [ "target" ] ->
                maybeAsMarkdown document.targets

            [ "tradition" ] ->
                maybeAsMarkdown document.traditions

            [ "trait" ] ->
                maybeAsMarkdown document.traits

            [ "trigger" ] ->
                maybeAsMarkdown document.trigger

            [ "type" ] ->
                [ Html.text document.type_ ]

            [ "usage" ] ->
                maybeAsMarkdown document.usage

            [ "vision" ] ->
                maybeAsText document.vision

            [ "weapon_category" ] ->
                maybeAsText document.weaponCategory

            [ "weapon_group" ] ->
                maybeAsMarkdown document.weaponGroupMarkdown

            [ "weapon_type" ] ->
                maybeAsText document.weaponType

            [ "weakest_save" ] ->
                document.weakestSaves
                    |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                    |> List.map toTitleCase
                    |> String.join ", "
                    |> Html.text
                    |> List.singleton

            [ "weakness" ] ->
                maybeAsMarkdown document.weaknesses

            [ "weakness", type_ ] ->
                document.weaknessValues
                    |> Maybe.andThen (getDamageTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> maybeAsText

            [ "will" ] ->
                document.will
                    |> Maybe.map numberWithSign
                    |> maybeAsText

            [ "will_proficiency" ] ->
                maybeAsText document.willProficiency

            [ "wisdom" ] ->
                document.wisdom
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
        allDocuments : List Document
        allDocuments =
            searchModel.searchResults
                |> List.concatMap (Result.map .documentIds >> Result.withDefault [])
                |> List.filterMap (\id -> Dict.get id model.documents)
                |> List.filterMap Result.toMaybe

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
            (\( key1, documents1 ) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length documents1 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h1
                        [ HA.class "title" ]
                        [ Html.div
                            []
                            [ viewGroupedTitle searchModel.groupField1 key1
                            ]
                        , Html.div
                            []
                            [ Html.text (String.fromInt (List.length documents1))
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
                            viewSearchResultsGroupedLevel2 model searchModel key1 field2 documents1

                        Nothing ->
                            viewSearchResultsGroupedLinkList model searchModel documents1
                    ]
            )
            (if searchModel.searchResultGroupAggs == Nothing then
                []

             else
                groupDocumentsByField keys searchModel.groupField1 allDocuments
                    |> Dict.toList
                    |> sortGroupedList model "" counts
            )
        )

    , if Maybe.Extra.isJust searchModel.tracker || searchModel.searchResultGroupAggs == Nothing then
        Html.div
            [ HA.class "loader"
            ]
            []

      else
        viewLoadMoreButtons model remaining
    ]


viewSearchResultsGroupedLevel2 : Model -> SearchModel -> String -> String -> List Document -> Html Msg
viewSearchResultsGroupedLevel2 model searchModel key1 field2 documents1 =
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
            (\( key2, documents2 ) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length documents2 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h2
                        [ HA.class "title" ]
                        [ Html.div
                            []
                            [ viewGroupedTitle field2 key2
                            ]
                        , Html.div
                            []
                            [ Html.text (String.fromInt (List.length documents2))
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
                            viewSearchResultsGroupedLevel3 model searchModel key1 key2 field3 documents2

                        Nothing ->
                            viewSearchResultsGroupedLinkList model searchModel documents2
                    ]
            )
            (groupDocumentsByField keys field2 documents1
                |> Dict.toList
                |> sortGroupedList model (key1 ++ "--") counts
            )
        )


viewSearchResultsGroupedLevel3 : Model -> SearchModel -> String -> String -> String -> List Document -> Html Msg
viewSearchResultsGroupedLevel3 model searchModel key1 key2 field3 documents2 =
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
            (\( key3, documents3 ) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length documents3 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h3
                        [ HA.class "title"
                        ]
                        [ Html.div
                            []
                            [ viewGroupedTitle field3 key3
                            ]
                        , Html.div
                            []
                            [ Html.text (String.fromInt (List.length documents3))
                            , Html.text "/"
                            , Html.text
                                (Dict.get (key1 ++ "--" ++ key2 ++ "--" ++ key3) counts
                                    |> Maybe.withDefault 0
                                    |> String.fromInt
                                )
                            ]
                        ]
                    , viewSearchResultsGroupedLinkList model searchModel documents3
                    ]
            )
            (groupDocumentsByField keys field3 documents2
                |> Dict.toList
                |> sortGroupedList model (key1 ++ "--" ++ key2 ++ "--") counts
            )
        )


viewSearchResultsGroupedLinkList : Model -> SearchModel -> List Document -> Html Msg
viewSearchResultsGroupedLinkList model searchModel documents =
    let
        sortedDocuments : List Document
        sortedDocuments =
            List.sortBy .name documents

        link : Document -> Html Msg
        link document =
            Html.a
                (List.append
                    [ HA.href (getUrl model document)
                    ]
                    (linkEventAttributes (getUrl model document))
                )
                [ Html.text document.name ]

        rarityBadge : Document -> Html msg
        rarityBadge document =
            if model.groupedShowRarity then
                case Maybe.map String.toLower document.rarity of
                    Just "uncommon" ->
                        Html.div
                            [ HA.class "trait"
                            , HA.class "trait-uncommon"
                            , HA.class "traitbadge"
                            ]
                            [ Html.text "U" ]

                    Just "rare" ->
                        Html.div
                            [ HA.class "trait"
                            , HA.class "trait-rare"
                            , HA.class "traitbadge"
                            ]
                            [ Html.text "R" ]

                    Just "unique" ->
                        Html.div
                            [ HA.class "trait"
                            , HA.class "trait-unique"
                            , HA.class "traitbadge"
                            ]
                            [ Html.text "Q" ]

                    _ ->
                        Html.text ""

            else
                Html.text ""
    in
    case searchModel.groupedLinkLayout of
        Horizontal ->
            Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                ]
                (List.map
                    (\document ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            ]
                            [ if model.groupedShowPfs then
                                document.pfs
                                    |> Maybe.withDefault ""
                                    |> viewPfsIcon 0

                              else
                                  Html.text ""
                            , link document
                            , rarityBadge document
                            ]
                    )
                    sortedDocuments
                )

        Vertical ->
            Html.div
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                (List.map
                    (\document ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            ]
                            [ if model.groupedShowPfs then
                                document.pfs
                                    |> Maybe.withDefault ""
                                    |> viewPfsIcon 0
                              else
                                Html.text ""
                            , link document
                            , rarityBadge document
                            ]
                    )
                    sortedDocuments
                )

        VerticalWithSummary ->
            Html.div
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                (List.map
                    (\document ->
                        Html.div
                            [ HA.class "inline" ]
                            (List.append
                                (if model.groupedShowPfs then
                                    [ document.pfs
                                        |> Maybe.withDefault ""
                                        |> viewPfsIcon 0
                                    , Html.text " "
                                    , link document
                                    , Html.text " "
                                    , rarityBadge document
                                    ]

                                else
                                    [ link document
                                    , Html.text " "
                                    , rarityBadge document
                                    ]

                                )
                                (case document.summary of
                                    Just summary ->
                                        List.append
                                            [ Html.text " - " ]
                                            (parseAndViewAsMarkdown model summary)

                                    Nothing ->
                                        []
                                )
                            )
                    )
                    sortedDocuments
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


groupDocumentsByField : List String -> String -> List Document -> Dict String (List Document)
groupDocumentsByField keys field documents =
    List.foldl
        (\document dict ->
            case field of
                "ability" ->
                    if List.isEmpty document.abilities then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\ability ->
                                insertToListDict (String.toLower ability) document
                            )
                            dict
                            (List.Extra.unique document.abilities)

                "actions" ->
                    insertToListDict
                        (document.actions
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "alignment" ->
                    insertToListDict
                        (document.alignment
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "creature_family" ->
                    insertToListDict
                        (document.creatureFamily
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "duration" ->
                    insertToListDict
                        (document.durationValue
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "element" ->
                    if List.isEmpty document.elements then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\element ->
                                insertToListDict (String.toLower element) document
                            )
                            dict
                            document.elements

                "heighten_level" ->
                    if List.isEmpty document.heightenLevels then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\level ->
                                insertToListDict (String.fromInt level) document
                            )
                            dict
                            document.heightenLevels

                "item_category" ->
                    insertToListDict
                        (document.itemCategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "item_subcategory" ->
                    insertToListDict
                        (document.itemSubcategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "level" ->
                    insertToListDict
                        (document.level
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "pfs" ->
                    insertToListDict
                        (document.pfs
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "range" ->
                    insertToListDict
                        (document.rangeValue
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "rarity" ->
                    insertToListDict
                        (document.rarity
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "school" ->
                    insertToListDict
                        (document.school
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "size" ->
                    if List.isEmpty document.sizes then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\size ->
                                insertToListDict (String.toLower size) document
                            )
                            dict
                            document.sizes

                "source" ->
                    List.foldl
                        (\source ->
                            insertToListDict (String.toLower source) document
                        )
                        dict
                        document.sourceList

                "tradition" ->
                    if List.isEmpty document.traditionList then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\tradition ->
                                insertToListDict (String.toLower tradition) document
                            )
                            dict
                            document.traditionList

                "trait" ->
                    if List.isEmpty document.traitList then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\trait ->
                                insertToListDict (String.toLower trait) document
                            )
                            dict
                            document.traitList

                "type" ->
                    insertToListDict (String.toLower document.type_) document dict

                "weapon_category" ->
                    insertToListDict
                        (document.weaponCategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "weapon_group" ->
                    insertToListDict
                        (document.weaponGroup
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "weapon_type" ->
                    insertToListDict
                        (document.weaponType
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                _ ->
                    dict
        )
        (keys
            |> List.map (\key -> ( key, [] ))
            |> Dict.fromList
        )
        documents


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
        Html.span
            []
            (viewTextWithActionIcons value)

    else if field == "alignment" then
        Html.text
            (Dict.fromList Data.alignments
                |> Dict.get value
                |> Maybe.withDefault value
                |> toTitleCase
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
            , Html.text (toTitleCase value)
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


parseAndViewAsMarkdown : Model -> String -> List (Html Msg)
parseAndViewAsMarkdown model string =
    if String.isEmpty string then
        []

    else
        string
            |> Markdown.Parser.parse
            |> Result.map (List.map (Markdown.Block.walk mergeInlines))
            |> Result.mapError (List.map Markdown.Parser.deadEndToString)
            |> viewMarkdown model "" 0 Nothing


viewMarkdown : Model -> String -> Int -> Maybe String -> ParsedMarkdownResult -> List (Html Msg)
viewMarkdown model id titleLevel overrideRight markdown =
    case markdown of
        Ok blocks ->
            case Markdown.Renderer.render (markdownRenderer model titleLevel overrideRight) blocks of
                Ok v ->
                    List.concat v

                Err err ->
                    [ Html.div
                        [ HA.style "color" "red" ]
                        [ Html.text ("Error rendering markdown for " ++ id ++ ":") ]
                    , Html.div
                        [ HA.style "color" "red" ]
                        [ Html.text err ]
                    ]

        Err errors ->
            [ Html.div
                [ HA.style "color" "red" ]
                [ Html.text ("Error parsing markdown for " ++ id ++ ":") ]
            , Html.div
                [ HA.style "color" "red" ]
                (List.map Html.text errors)
            ]


markdownRenderer : Model -> Int -> Maybe String -> Markdown.Renderer.Renderer (List (Html Msg))
markdownRenderer model titleLevel overrideRight =
    let
        defaultRenderer : Markdown.Renderer.Renderer (Html msg)
        defaultRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { blockQuote = List.concat >> defaultRenderer.blockQuote >> List.singleton
    , codeBlock = defaultRenderer.codeBlock >> List.singleton
    , codeSpan = defaultRenderer.codeSpan >> List.singleton
    , emphasis = List.concat >> defaultRenderer.emphasis >> List.singleton
    , hardLineBreak = defaultRenderer.hardLineBreak |> List.singleton
    , heading =
        \heading ->
            [ defaultRenderer.heading
                { level = heading.level
                , rawText = heading.rawText
                , children = List.concat heading.children
                }
            ]
    , html = markdownHtmlRenderer model titleLevel overrideRight
    , image =
        \image ->
            [ viewImage 150 image.src
            ]
    , link =
        \linkData children ->
            [ Html.a
                (List.append
                    [ HA.href linkData.destination
                    , HAE.attributeMaybe HA.title linkData.title
                    ]
                    (linkEventAttributes linkData.destination)
                )
                (List.concat children)
            ]
    , orderedList = \startingIndex -> List.concat >> defaultRenderer.orderedList startingIndex >> List.singleton
    , paragraph = List.concat >> defaultRenderer.paragraph >> List.singleton
    , strikethrough = List.concat >> defaultRenderer.strikethrough >> List.singleton
    , strong = List.concat >> defaultRenderer.strong >> List.singleton
    , table = List.concat >> defaultRenderer.table >> List.singleton
    , tableBody = List.concat >> defaultRenderer.tableBody >> List.singleton
    , tableCell = \alignment -> List.concat >> defaultRenderer.tableCell alignment >> List.singleton
    , tableHeader = List.concat >> defaultRenderer.tableHeader >> List.singleton
    , tableHeaderCell = \alignment -> List.concat >> defaultRenderer.tableHeaderCell alignment >> List.singleton
    , tableRow = List.concat >> defaultRenderer.tableRow >> List.singleton
    , text = defaultRenderer.text >> List.singleton
    , thematicBreak = defaultRenderer.thematicBreak |> List.singleton
    , unorderedList =
        List.map
            (\item ->
                case item of
                    Markdown.Block.ListItem task children ->
                        Markdown.Block.ListItem task (List.concat children)
            )
            >> defaultRenderer.unorderedList
            >> List.singleton
    }


markdownHtmlRenderer :
    Model
    -> Int
    -> Maybe String
    -> Markdown.Html.Renderer (List (List (Html Msg)) -> List (Html Msg))
markdownHtmlRenderer model titleLevel overrideRight =
    Markdown.Html.oneOf
        [ Markdown.Html.tag "actions"
            (\string _ ->
                viewTextWithActionIcons string
            )
            |> Markdown.Html.withAttribute "string"
        , Markdown.Html.tag "additional-info"
            (\children ->
                [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    , HA.class "additional-info"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "aside"
            (\children ->
                [ Html.aside
                    [ HA.class "option-container"
                    , HA.class "column"
                    , HA.class "gap-medium"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "b"
            (\children ->
                [ Html.span
                    [ HA.style "font-weight" "700" ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "br"
            (\_ ->
                [ Html.br
                    []
                    []
                ]
            )
        , Markdown.Html.tag "center"
            (\children ->
                [ Html.div
                    [ HA.class "column"
                    , HA.class "gap-medium"
                    , HA.class "align-center"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "document"
            (\id level titleRight _ ->
                viewDocument
                    model
                    id
                    (max
                        (level
                            |> Maybe.andThen String.toInt
                            |> Maybe.withDefault 1
                            |> (+) (titleLevel - 1)
                        )
                        titleLevel
                    )
                    titleRight
            )
            |> Markdown.Html.withAttribute "id"
            |> Markdown.Html.withOptionalAttribute "level"
            |> Markdown.Html.withOptionalAttribute "override-title-right"
        , Markdown.Html.tag "document-flattened"
            (\children ->
                List.concat children
            )
        , Markdown.Html.tag "filter-button"
            (\_ ->
                []
            )
        -- TODO
        -- , Markdown.Html.tag "filter-button"
        --     (\type_ value _ ->
        --         [ viewFilterButton model type_ value
        --         ]
        --     )
        --     |> Markdown.Html.withAttribute "type"
        --     |> Markdown.Html.withAttribute "value"
        , Markdown.Html.tag "li"
            (\children ->
                [ Html.li
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "ol"
            (\children ->
                [ Html.ol
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "query-button"
            (\_ ->
                []
            )
        -- TODO
        -- , Markdown.Html.tag "query-button"
        --     (\query children ->
        --         [ Html.button
        --             [ HE.onClick (QueryButtonPressed query) ]
        --             (List.concat children)
        --         ]
        --     )
        --     |> Markdown.Html.withAttribute "query"
        , Markdown.Html.tag "search"
            (\_ ->
                [] -- Rendered elsewhere
            )
        , Markdown.Html.tag "spoilers"
            (\children ->
                [ Html.h3
                    [ HA.class "row"
                    , HA.class "option-container"
                    , HA.class "spoilers"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "summary"
            (\children ->
                [ Html.div
                    [ HA.class "summary"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "sup"
            (\children ->
                [ Html.sup
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "table"
            (\children ->
                [ Html.div
                    [ HA.style "max-width" "100%"
                    -- , HA.style "overflow-x" "auto"
                    ]
                    [ Html.table
                        []
                        (List.concat children)
                    ]
                ]
            )
        , Markdown.Html.tag "tbody"
            (\children ->
                [ Html.tbody
                    [ HA.style "max-width" "100%"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "td"
            (\colspan rowspan children ->
                [ Html.td
                    [ HAE.attributeMaybe
                        HA.colspan
                        (Maybe.andThen String.toInt colspan)
                    , HAE.attributeMaybe
                        HA.rowspan
                        (Maybe.andThen String.toInt rowspan)
                    ]
                    (List.concat children)
                ]
            )
            |> Markdown.Html.withOptionalAttribute "colspan"
            |> Markdown.Html.withOptionalAttribute "rowspan"
        , Markdown.Html.tag "tfoot"
            (\children ->
                [ Html.tfoot
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "th"
            (\children ->
                [ Html.th
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "thead"
            (\children ->
                [ Html.thead
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "title"
            (\level maybeAnchorLink maybeAnchorLevel maybeRight maybePfs maybeNoClass maybeIcon children ->
                let
                    maybeRightWithOverride : Maybe String
                    maybeRightWithOverride =
                        if level == "1" then
                            Maybe.Extra.or overrideRight maybeRight

                        else
                            maybeRight
                in
                [ (String.toInt level
                    |> Maybe.map ((+) titleLevel)
                    |> Maybe.withDefault 0
                    |> titleLevelToTag
                  )
                    [ HA.class "column"
                    , HA.class "gap-tiny"
                    , HA.class "margin-top-not-first"
                    ]
                    [ case ( maybeAnchorLink, maybeAnchorLevel ) of
                        ( Just anchorLink, Just anchorLevel ) ->
                            Html.a
                                [ HA.id anchorLink
                                , HA.href ("#" ++ anchorLink)
                                , HA.class "title-anchor"
                                ]
                                [ Html.text ("#" ++ anchorLevel) ]

                        _ ->
                            Html.text ""

                    , Html.div
                        [ case maybeNoClass of
                            Just _ ->
                                HAE.empty

                            Nothing ->
                                HA.class "title"
                        ]
                        [ Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            , HA.class "align-center"
                            ]
                            (List.concat
                                [ case maybePfs of
                                    Just pfs ->
                                        [ viewPfsIconWithLink 0 pfs ]

                                    _ ->
                                        []
                                , case maybeIcon of
                                    Just "" ->
                                        []

                                    Just icon ->
                                        [ Html.img
                                            [ HA.src icon
                                            , HA.style "height" "1em"
                                            ]
                                            []
                                        ]

                                    Nothing ->
                                        []
                                , List.concat children
                                ]
                            )
                        , case maybeRightWithOverride of
                            Just right ->
                                Html.div
                                    [ HA.class "align-right"
                                    ]
                                    [ Html.text right ]

                            Nothing ->
                                Html.text ""
                        ]
                    ]
                ]
            )
            |> Markdown.Html.withAttribute "level"
            |> Markdown.Html.withOptionalAttribute "anchor-link"
            |> Markdown.Html.withOptionalAttribute "anchor-level"
            |> Markdown.Html.withOptionalAttribute "right"
            |> Markdown.Html.withOptionalAttribute "pfs"
            |> Markdown.Html.withOptionalAttribute "noclass"
            |> Markdown.Html.withOptionalAttribute "icon"
        , Markdown.Html.tag "tr"
            (\children ->
                [ Html.tr
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "trait"
            (\label url _ ->
                [ viewTrait url label ]
            )
            |> Markdown.Html.withAttribute "label"
            |> Markdown.Html.withOptionalAttribute "url"
        , Markdown.Html.tag "traits"
            (\children ->
                [ Html.div
                    [ HA.class "row"
                    , HA.class "traits"
                    , HA.class "wrap"
                    ]
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "ul"
            (\children ->
                [ Html.ul
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "responsive"
            (\maybeGap children ->
                [ Html.div
                    [ HA.class "row"
                    , HA.class "wrap"
                    , HAE.attributeMaybe
                        (\gap -> HA.class ("gap-" ++ gap))
                        maybeGap
                    ]
                    (List.concat children)
                ]
            )
            |> Markdown.Html.withOptionalAttribute "gap"
        , Markdown.Html.tag "row"
            (\maybeGap children ->
                [ Html.div
                    [ HA.class "row"
                    , HA.class "wrap"
                    , HAE.attributeMaybe
                        (\gap -> HA.class ("gap-" ++ gap))
                        maybeGap
                    ]
                    (List.concat children)
                ]
            )
            |> Markdown.Html.withOptionalAttribute "gap"
        , Markdown.Html.tag "column"
            (\gap flex children ->
                [ Html.div
                    [ HA.class "column"
                    , HA.class ("gap-" ++ gap)
                    , HAE.attributeMaybe (HA.style "flex") flex
                    ]
                    (List.concat children)
                ]
            )
            |> Markdown.Html.withAttribute "gap"
            |> Markdown.Html.withOptionalAttribute "flex"
        , Markdown.Html.tag "image"
            (\src _ ->
                [ Html.a
                    [ HA.href src
                    , HA.target "_blank"
                    ]
                    [ viewImage 150 src
                    ]
                ]
            )
            |> Markdown.Html.withAttribute "src"
        ]


viewImage : Int -> String -> Html msg
viewImage maxWidth url =
    Html.img
        [ HA.src url
        , HA.alt ""
        , HA.style "max-width" (String.fromInt maxWidth ++ "px")
        ]
        []


titleLevelToTag : Int -> (List (Html.Attribute msg) -> List (Html msg) -> Html msg)
titleLevelToTag level =
    case level of
        0 ->
            Html.h1

        1 ->
            Html.h1

        2 ->
            Html.h2

        3 ->
            Html.h3

        4 ->
            Html.h4

        5 ->
            Html.h5

        6 ->
            Html.h6

        _ ->
            Html.h6


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


viewTextWithActionIcons : String -> List (Html msg)
viewTextWithActionIcons text =
    case
        replaceActionLigatures
            text
            ( "single action", "[one-action]" )
            [ ( "two actions", "[two-actions]" )
            , ( "three actions", "[three-actions]" )
            , ( "reaction", "[reaction]" )
            , ( "free action", "[free-action]" )
            ]
    of
        [ single ] ->
            [ Html.text " "
            , single
            , Html.text " "
            ]

        multiple ->
            multiple


replaceActionLigatures : String -> ( String, String ) -> List ( String, String ) -> List (Html msg)
replaceActionLigatures text ( find, replace ) rem =
    if String.contains find (String.toLower text) then
        case String.split find (String.toLower text) of
            before :: after ->
                List.concat
                    [ if String.isEmpty before then
                        []
                      else
                        [ Html.text before ]
                    , [ Html.span
                            [ HA.class "icon-font" ]
                            [ Html.text replace ]
                      ]
                    , replaceActionLigatures
                        (String.join find after)
                        ( find, replace )
                        rem
                    ]

            [] ->
                if String.isEmpty text then
                    []

                else
                    [ Html.text text ]

    else
        case rem of
            next :: remNext ->
                replaceActionLigatures text next remNext

            [] ->
                if String.isEmpty text then
                    []

                else
                    [ Html.text text ]


viewTrait : Maybe String -> String -> Html Msg
viewTrait maybeUrl trait =
    Html.div
        [ HA.class "trait"
        , getTraitClass trait
        ]
        [ case maybeUrl of
            Just url ->
                Html.a
                    (List.append
                        [ HA.href url
                        ]
                        (linkEventAttributes url)
                    )
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

        "size" ->
            HA.class "trait-size"

        "metropolis" ->
            HA.class "trait-size"

        "town" ->
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

        "alignment" ->
            HA.class "trait-alignment"

        "alignment abbreviation" ->
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
                , HA.style "display" "flex"
                ]
                [ viewPfsIcon height pfs
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
        |> String.replace " And " " and "
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


linkEventAttributes : String -> List (Html.Attribute Msg)
linkEventAttributes url =
    [ HE.on "mouseenter"
        (Decode.map
            (LinkEntered url)
            elementEventDecoder
        )
    , HE.on "focus"
        (Decode.map
            (LinkEntered url)
            elementEventDecoder
        )
    , HE.onMouseLeave LinkLeft
    , HE.onBlur LinkLeft
    ]


elementEventDecoder : Decode.Decoder Position
elementEventDecoder =
    Field.requireAt [ "target", "offsetLeft" ] Decode.int <| \x ->
    Field.requireAt [ "target", "offsetTop" ] Decode.int <| \y ->
    Field.requireAt [ "target", "offsetHeight" ] Decode.int <| \height ->
    Field.requireAt [ "target", "offsetWidth" ] Decode.int <| \width ->
    Field.requireAt [ "target", "offsetParent" ] parentOffsetDecoder <| \parent ->
    Decode.succeed
        { x = x + parent.x
        , y = y + parent.y
        , width = width
        , height = height
        }


parentOffsetDecoder : Decode.Decoder { x : Int, y : Int }
parentOffsetDecoder =
    Field.require "offsetLeft" Decode.int <| \x ->
    Field.require "offsetTop" Decode.int <| \y ->
    Field.require "id" Decode.string <| \id ->
    Field.attemptAt [ "parentElement", "scrollLeft" ] numericDecoder <| \parentScrollX ->
    Field.attemptAt [ "parentElement", "scrollTop" ] numericDecoder <| \parentScrollY ->
    Field.attemptAt [ "parentElement", "tagName" ] Decode.string <| \parentTagName ->
    Field.attempt "offsetParent" (Decode.lazy (\_ -> parentOffsetDecoder)) <| \parent ->
    Decode.succeed
        { x =
            if id == "page" then
                0

            else
                x
                + (parent
                    |> Maybe.map .x
                    |> Maybe.withDefault 0
                  )
                - (if parentTagName == Just "HTML" then
                    0

                   else
                    Maybe.withDefault 0 parentScrollX
                  )
        , y =
            if id == "page" then
                0

            else
                y
                + (parent
                    |> Maybe.map .y
                    |> Maybe.withDefault 0
                  )
                - (if parentTagName == Just "HTML" then
                    0

                   else
                    Maybe.withDefault 0 parentScrollY
                  )
        }


numericDecoder : Decode.Decoder Int
numericDecoder =
    Decode.oneOf
        [ Decode.int
        , Decode.float
            |> Decode.map floor
        ]


css : { pageWidth : Int } -> String
css args =
    """
    @font-face {
        font-family: "Pathfinder-Icons";
        src: url("Pathfinder-Icons.ttf");
        font-display: swap;
    }

    :root, :host {
        --color-bg: var(--bg-main, #0f0f0f);
        --color-box-bg: var(--border-1, #333333);
        --color-box-bg-alt: var(--border-2, #282828);
        --color-box-border: var(--text-1, #eeeeee);
        --color-box-text: var(--text-1, --color-text);
        --color-table-border: var(--color-text);
        --color-table-head-bg: var(--color-title1-bg);
        --color-table-head-text: var(--color-title1-text);
        --color-table-row-bg-alt: var(--bg-1, #64542f);
        --color-table-row-bg: var(--bg-2, #342c19);
        --color-table-row-text: var(--text-2, --color-text);
        --color-text: var(--text-1, #eeeeee);
        --color-text-inactive: var(--border-1, #999999);
        --color-title1-bg: var(--head-bg, #522e2c);
        --color-title1-text: var(--head-fg, #cbc18f);
        --color-title2-bg: var(--mid-bg, #806e45);
        --color-title2-text: var(--mid-fg, #0f0f0f);
        --color-title3-bg: var(--sub-bg, #627d62);
        --color-title3-text: var(--sub-fg, #0f0f0f);
        --color-title4-bg: var(--header4-bg, #4a8091);
        --color-title4-text: var(--header4-fg, #0f0f0f);
        --color-title5-bg: var(--header5-bg, #494e70);
        --color-title5-text: var(--header5-fg, #0f0f0f);
        --color-title6-bg: var(--header6-bg, #623a6e);
        --color-title6-text: var(--header6-fg, #0f0f0f);
        --color-trait-bg: var(--head-bg, #522e2c);
        --color-trait-border: #d8c483;
        --color-trait-text: var(--text-2, #eeeeee);
        --element-font-variant: var(--font-variant, small-caps);
        --element-border-radius: var(--border-radius, 4px);
        --font-normal: 16px;
        --font-large: 20px;
        --font-very-large: 24px;
        --gap-tiny: 4px;
        --gap-small: 8px;
        --gap-medium: 12px;
        --gap-large: 20px;
        color: var(--color-text);
        color-scheme: var(--color-scheme, light);
        font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif;
        font-size: var(--font-normal);
        line-height: normal;
    }

    body {
        background-color: var(--color-bg);
        margin: 0px;
    }

    a {
        color: inherit;
    }

    a:hover {
        text-decoration: underline;
    }

    button {
        border-color: var(--color-text);
        border-width: 1px;
        border-style: solid;
        border-radius: 4px;
        background-color: transparent;
        color: var(--color-text);
        font-size: var(--font-normal);
        padding: 1px 6px;
    }

    button.active {
        background-color: var(--color-text);
        color: var(--color-bg);
    }

    button.excluded, button:disabled {
        border-color: var(--color-text-inactive);
        color: var(--color-text-inactive);
    }

    button:hover:enabled {
        border-color: var(--color-text);
        text-decoration: underline;
    }

    h1, h2, h3, h4, h5, h6 {
        font-variant: small-caps;
        font-weight: 700;
        margin: 0;
    }

    h1 {
        font-size: var(--font-very-large);
    }

    h1.title, h1 .title {
        background-color: var(--color-title1-bg);
        color: var(--color-title1-text);
    }

    h2 {
        font-size: var(--font-large);
    }

    h2.title, h2 .title {
        background-color: var(--color-title2-bg);
        color: var(--color-title2-text);
        line-height: 1;
    }

    h3 {
        font-size: 18px;
    }

    h3.title, h3 .title {
        background-color: var(--color-title3-bg);
        color: var(--color-title3-text);
        line-height: 1;
    }

    h4 {
        font-size: 18px;
    }

    h4.title, h4 .title {
        background-color: var(--color-title4-bg);
        color: var(--color-title4-text);
        line-height: 1;
    }

    h5 {
        font-size: 18px;
    }

    h5.title, h5 .title {
        background-color: var(--color-title5-bg);
        color: var(--color-title5-text);
        line-height: 1;
    }

    h6 {
        font-size: 18px;
    }

    h6.title, h6 .title {
        background-color: var(--color-title6-bg);
        color: var(--color-title6-text);
        line-height: 1;
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
        color: var(--color-table-row-text, inherit);
        position: relative;
    }

    table td {
        background-color: var(--color-table-row-bg);
    }

    table tr:nth-child(odd) td {
        background-color: var(--color-table-row-bg-alt);
    }

    table > tr:first-child td, thead tr, table tfoot td {
        background-color: var(--color-table-head-bg);
        color: var(--color-table-head-text)
    }

    table > tr:first-child td {
        border-top: 1px solid var(--color-table-border);
        font-variant: small-caps;
    }

    td {
        border-right: 1px solid var(--color-table-border);
        border-bottom: 1px solid var(--color-table-border);
        padding: 4px 12px 4px 4px;
    }

    th {
        background-color: var(--color-table-head-bg);
        border-top: 1px solid var(--color-table-border);
        border-right: 1px solid var(--color-table-border);
        border-bottom: 1px solid var(--color-table-border);
        color: var(--color-table-head-text);
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
        border-left: 1px solid var(--color-table-border);
    }

    thead tr {
        background-color: var(--color-table-head-bg);
    }

    ul {
        margin-block-start: 0.5em;
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
        background-color: var(--color-title1-bg);
        color: var(--color-title1-text);
        font-size: 16px;
        font-variant: small-caps;
        font-weight: 700;
        padding: 4px 9px;
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
        vertical-align: text-bottom;
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
        max-width: """ ++
            (case args.pageWidth of
                0 ->
                    "100%"

                width ->
                    String.fromInt width ++ "px"

            ) ++ """;
        transition: max-width ease-in-out 0.2s;
    }

    .margin-top-not-first:not(:first-child):not(h1 + h2):not(h2 + h3):not(h3 + h4):not(ul + h2):not(ul + h3) {
        margin-top: var(--gap-medium);
    }

    h2.margin-top-not-first:not(:first-child):not(h1 + h2):not(h2 + h3):not(h3 + h4):not(ul + h2):not(ul + h3) {
        margin-top: var(--gap-large);
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
        background-color: var(--color-box-bg-alt);
        font-family: monospace;
        font-size: var(--font-normal);
    }

    .nowrap {
        flex-wrap: nowrap;
    }

    .option-container {
        border-style: solid;
        border-width: 1px;
        border-color: var(--color-box-border);
        background-color: var(--color-box-bg);
        color: var(--color-box-text);
        padding: 8px;
    }

    .preview {
        background-color: var(--color-bg);
        border-radius: 4px;
        border: var(--color-text) solid 1px;
        box-shadow: 0px 0px 10px black;
        box-sizing: border-box;
        margin-right: var(--gap-small);
        max-height: 600px;
        max-width: min(800px, 95%);
        overflow: hidden;
        padding: var(--gap-small);
        pointer-events: none;
        position: absolute;
        z-index: 1000000;
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
        background-color: var(--color-box-bg-alt);
        border-color: #767676;
        border-radius: 4px;
        border-style: solid;
        border-width: 1px;
        max-height: 200px;
        overflow-y: auto;
        padding: 4px;
    }

    .sticky-left {
        left: 0;
        position: sticky;
    }

    .title {
        align-items: center;
        border-radius: var(--element-border-radius);
        display: flex;
        flex-direction: row;
        font-variant: var(--element-font-variant);
        gap: var(--gap-medium);
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
        align-self: flex-start;
        background-color: var(--color-trait-bg);
        border-color: var(--color-trait-border);
        border-style: double;
        border-width: 2px;
        color: #eeeeee;
        padding: 3px 5px;
        font-size: 16px;
        font-variant: var(--element-font-variant);
        font-weight: 700;
    }

    .traitbadge {
        font-size: 8px;
        border-width: 1px;
        padding: 1px 2px;
        vertical-align: super;
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
