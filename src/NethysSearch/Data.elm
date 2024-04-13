module NethysSearch.Data exposing (..)

import Browser
import Date
import Dict exposing (Dict)
import Dict.Extra
import Http
import Json.Decode as Decode
import Json.Decode.Field as Field
import Json.Encode as Encode
import List.Extra
import Markdown.Block
import Markdown.Parser
import Markdown.Renderer
import Maybe.Extra
import Set exposing (Set)
import String.Extra
import Url exposing (Url)


type alias Model =
    { alwaysShowFilters : Bool
    , autofocus : Bool
    , autoQueryType : Bool
    , bodySize : Size
    , dataUrl : String
    , documentIndex : Dict String String
    , documents : Dict String (Result Http.Error Document)
    , documentsToFetch : Set String
    , elasticUrl : String
    , fixedParams : Dict String (List String)
    , groupTraits : Bool
    , groupedDisplay : GroupedDisplay
    , groupedSort : GroupedSort
    , index : String
    , loadAll : Bool
    , legacyMode : Bool
    , limitTableWidth : Bool
    , linkPreviewsEnabled : Bool
    , noUi : Bool
    , pageDefaultParams : Dict String (Dict String (List String))
    , pageId : String
    , pageSize : Int
    , pageSizeDefaults : Dict String Int
    , pageWidth : Int
    , previewLink : Maybe PreviewLink
    , randomSeed : Int
    , savedColumnConfigurations : Dict String (List String)
    , savedColumnConfigurationName : String
    , searchModel : SearchModel
    , showLegacyFilters : Bool
    , sourcesAggregation : Maybe (Result Http.Error (List Source))
    , traitAggregations : Maybe (Result Http.Error (Dict String (List String)))
    , url : Url
    , viewModel : ViewModel
    , windowSize : Size
    }


type alias ViewModel =
    { browserDateFormat : String
    , dateFormat : String
    , groupedShowHeightenable : Bool
    , groupedShowPfs : Bool
    , groupedShowRarity : Bool
    , openInNewTab : Bool
    , resultBaseUrl : String
    , showResultAdditionalInfo : Bool
    , showResultIndex : Bool
    , showResultPfs : Bool
    , showResultSpoilers : Bool
    , showResultSummary : Bool
    , showResultTraits : Bool
    }


type alias SearchModel =
    { aggregations : Maybe (Result Http.Error Aggregations)
    , debounce : Int
    , defaultQuery : String
    , filteredAttributes : Dict String Bool
    , filteredActions : Dict String Bool
    , filteredAlignments : Dict String Bool
    , filteredArmorCategories : Dict String Bool
    , filteredArmorGroups : Dict String Bool
    , filteredComponents : Dict String Bool
    , filteredCreatureFamilies : Dict String Bool
    , filteredDamageTypes : Dict String Bool
    , filteredDomains : Dict String Bool
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
    , filteredTraitGroups : Dict String Bool
    , filteredTraits : Dict String Bool
    , filteredTypes : Dict String Bool
    , filteredWeakestSaves : Dict String Bool
    , filteredWeaponCategories : Dict String Bool
    , filteredWeaponGroups : Dict String Bool
    , filteredWeaponTypes : Dict String Bool
    , filterApCreatures : Bool
    , filterComponentsOperator : Bool
    , filterDamageTypesOperator : Bool
    , filterDomainsOperator : Bool
    , filterSpoilers : Bool
    , filterTraditionsOperator : Bool
    , filterTraitsOperator : Bool
    , fixedQueryString : String
    , groupField1 : String
    , groupField2 : Maybe String
    , groupField3 : Maybe String
    , groupedLinkLayout : GroupedLinkLayout
    , lastSearchHash : Maybe String
    , legacyMode : Maybe Bool
    , query : String
    , queryType : QueryType
    , removeFilters : List String
    , resultDisplay : ResultDisplay
    , searchCreatureFamilies : String
    , searchGroupResults : List String
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
    , selectedFilterAttribute : String
    , selectedFilterResistance : String
    , selectedFilterSpeed : String
    , selectedFilterWeakness : String
    , selectedSortAttribute : String
    , selectedSortResistance : String
    , selectedSortSpeed : String
    , selectedSortWeakness : String
    , showFilters : Bool
    , sort : List ( String, SortDir )
    , sortHasChanged : Bool
    , tableColumns : List String
    , tracker : Maybe Int
    , visibleFilterBoxes : List String
    }


emptySearchModel :
   { defaultQuery : String
   , removeFilters : List String
   , fixedQueryString : String
   }
   -> SearchModel
emptySearchModel { defaultQuery, fixedQueryString, removeFilters } =
    { aggregations = Nothing
    , debounce = 0
    , defaultQuery = defaultQuery
    , filteredAttributes = Dict.empty
    , filteredActions = Dict.empty
    , filteredAlignments = Dict.empty
    , filteredArmorCategories = Dict.empty
    , filteredArmorGroups = Dict.empty
    , filteredComponents = Dict.empty
    , filteredCreatureFamilies = Dict.empty
    , filteredDamageTypes = Dict.empty
    , filteredDomains = Dict.empty
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
    , filteredTraitGroups = Dict.empty
    , filteredTraits = Dict.empty
    , filteredTypes = Dict.empty
    , filteredWeakestSaves = Dict.empty
    , filteredWeaponCategories = Dict.empty
    , filteredWeaponGroups = Dict.empty
    , filteredWeaponTypes = Dict.empty
    , filterApCreatures = False
    , filterComponentsOperator = True
    , filterDamageTypesOperator = True
    , filterDomainsOperator = True
    , filterSpoilers = False
    , filterTraditionsOperator = True
    , filterTraitsOperator = True
    , fixedQueryString = fixedQueryString
    , groupField1 = "type"
    , groupField2 = Nothing
    , groupField3 = Nothing
    , groupedLinkLayout = Horizontal
    , lastSearchHash = Nothing
    , legacyMode = Nothing
    , query = ""
    , queryType = Standard
    , removeFilters = removeFilters
    , resultDisplay = Short
    , searchResultGroupAggs = Nothing
    , searchCreatureFamilies = ""
    , searchGroupResults = []
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
    , selectedFilterAttribute = "strength"
    , selectedFilterResistance = "acid"
    , selectedFilterSpeed = "land"
    , selectedFilterWeakness = "acid"
    , selectedSortAttribute = "strength"
    , selectedSortResistance = "acid"
    , selectedSortSpeed = "land"
    , selectedSortWeakness = "acid"
    , showFilters = False
    , sort = []
    , sortHasChanged = False
    , tableColumns = []
    , tracker = Nothing
    , visibleFilterBoxes = [ "whats-new" ]
    }


type alias SearchResult =
    { documentIds : List String
    , searchAfter : Encode.Value
    , total : Int
    , groupAggs : Maybe GroupAggregations
    , index : Maybe String
    }


type alias PreviewLink =
    { documentId : String
    , elementPosition : Position
    , fragment : Maybe String
    , noRedirect : Bool
    }


type alias Document =
    { id : String
    , category : String
    , name : String
    , type_ : String
    , url : String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedApocryphalSpell : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , anathemas : Maybe String
    , apocryphalSpell : Maybe String
    , archetype : Maybe String
    , area : Maybe String
    , armorCategory : Maybe String
    , armorGroup : Maybe String
    , aspect : Maybe String
    , attackProficiencies : List String
    , attributeFlaws : List String
    , attributes : List String
    , baseItems : Maybe String
    , bloodlines : Maybe String
    , breadcrumbs : Maybe String
    , bulk : Maybe Float
    , bulkRaw : Maybe String
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
    , damageTypes : List String
    , defenseProficiencies : List String
    , deities : Maybe String
    , deitiesList : List String
    , deityCategory : Maybe String
    , dexCap : Maybe Int
    , dexterity : Maybe Int
    , divineFonts : List String
    , domains : Maybe String
    , domainsList : List String
    , domainSpell : Maybe String
    , duration : Maybe String
    , durationValue : Maybe Int
    , edicts : Maybe String
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
    , heightenGroups : List String
    , heightenLevels : List Int
    , hp : Maybe String
    , iconImage : Maybe String
    , images : List String
    , immunities : Maybe String
    , intelligence : Maybe Int
    , itemCategory : Maybe String
    , itemSubcategory : Maybe String
    , languages : Maybe String
    , legacyId : Maybe String
    , lessonType : Maybe String
    , lessons : Maybe String
    , level : Maybe Int
    , markdown : Markdown
    , mysteries : Maybe String
    , onset : Maybe String
    , pantheons : List String
    , pantheonMarkdown : Maybe String
    , pantheonMembers : Maybe String
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
    , rarityId : Maybe Int
    , ref : Maybe Int
    , reflexProficiency : Maybe String
    , region : Maybe String
    , releaseDate : Maybe String
    , reload : Maybe String
    , remasterId : Maybe String
    , requiredAbilities : Maybe String
    , requirements : Maybe String
    , resistanceValues : Maybe DamageTypeValues
    , resistances : Maybe String
    , sanctification : Maybe String
    , savingThrow : Maybe String
    , school : Maybe String
    , searchMarkdown : Markdown
    , secondaryCasters : Maybe String
    , secondaryChecks : Maybe String
    , senses : Maybe String
    , sizeIds : List Int
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
    , spellType : Maybe String
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
    , wardenSpellTier : Maybe String
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
    , browserDateFormat : String
    , currentUrl : String
    , dataUrl : String
    , defaultQuery : String
    , elasticUrl : String
    , fixedParams : Dict String (List String)
    , fixedQueryString : String
    , loadAll : Bool
    , legacyMode : Bool
    , localStorage : Dict String String
    , noUi : Bool
    , pageId : String
    , randomSeed : Int
    , removeFilters : List String
    , resultBaseUrl : String
    , windowHeight : Int
    , windowWidth : Int
    }


defaultFlags : Flags
defaultFlags =
    { autofocus = False
    , browserDateFormat = "yyyy-MM-dd"
    , currentUrl = "/"
    , dataUrl = ""
    , defaultQuery = ""
    , elasticUrl = ""
    , fixedParams = Dict.empty
    , fixedQueryString = ""
    , loadAll = False
    , legacyMode = False
    , localStorage = Dict.empty
    , noUi = False
    , pageId = ""
    , randomSeed = 1
    , removeFilters = []
    , resultBaseUrl = "https://2e.aonprd.com/"
    , windowHeight = 0
    , windowWidth = 0
    }


type alias Aggregations =
    { actions : List String
    , creatureFamilies : List String
    , domains : List String
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


type Msg
    = ActionsFilterAdded String
    | ActionsFilterRemoved String
    | AlignmentFilterAdded String
    | AlignmentFilterRemoved String
    | AlwaysShowFiltersChanged Bool
    | ArmorCategoryFilterAdded String
    | ArmorCategoryFilterRemoved String
    | ArmorGroupFilterAdded String
    | ArmorGroupFilterRemoved String
    | AttributeFilterAdded String
    | AttributeFilterRemoved String
    | AutoQueryTypeChanged Bool
    | ColumnResistanceChanged String
    | ColumnSpeedChanged String
    | ColumnWeaknessChanged String
    | ComponentFilterAdded String
    | ComponentFilterRemoved String
    | CreatureFamilyFilterAdded String
    | CreatureFamilyFilterRemoved String
    | DamageTypeFilterAdded String
    | DamageTypeFilterRemoved String
    | DateFormatChanged String
    | DebouncePassed Int
    | DeleteColumnConfigurationPressed
    | DomainFilterAdded String
    | DomainFilterRemoved String
    | ExportAsCsvPressed
    | ExportAsJsonPressed
    | GotAggregationsResult (Result Http.Error Aggregations)
    | GotBodySize Size
    | GotDocumentIndexResult (Result Http.Error (Dict String String))
    | GotDocuments Bool (List String) (Result Http.Error (List (Result String Document)))
    | GotGroupAggregationsResult (Result Http.Error SearchResult)
    | GotGroupSearchResult (Result Http.Error SearchResult)
    | GotSearchResult (Result Http.Error SearchResult)
    | GotSourcesAggregationResult (Result Http.Error (List Source))
    | GotTraitAggregationsResult (Result Http.Error (Dict String (List String)))
    | FilterApCreaturesChanged Bool
    | FilterAttributeChanged String
    | FilterComponentsOperatorChanged Bool
    | FilterDamageTypesOperatorChanged Bool
    | FilterDomainsOperatorChanged Bool
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
    | GroupedShowHeightenableChanged Bool
    | GroupedShowPfsIconChanged Bool
    | GroupedShowRarityChanged Bool
    | GroupedSortChanged GroupedSort
    | HandFilterAdded String
    | HandFilterRemoved String
    | ItemCategoryFilterAdded String
    | ItemCategoryFilterRemoved String
    | ItemSubcategoryFilterAdded String
    | ItemSubcategoryFilterRemoved String
    | LegacyModeChanged (Maybe Bool)
    | LimitTableWidthChanged Bool
    | LinkEntered String Position
    | LinkEnteredDebouncePassed String
    | LinkLeft
    | LoadGroupPressed (List ( String, String ))
    | LoadMorePressed Int
    | LocalStorageValueReceived Decode.Value
    | NewRandomSeedPressed
    | NoOp
    | OpenInNewTabChanged Bool
    | PageSizeChanged Int
    | PageSizeDefaultsChanged String Int
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
    | RemoveAllActionsFiltersPressed
    | RemoveAllAlignmentFiltersPressed
    | RemoveAllArmorCategoryFiltersPressed
    | RemoveAllArmorGroupFiltersPressed
    | RemoveAllAttributeFiltersPressed
    | RemoveAllComponentFiltersPressed
    | RemoveAllCreatureFamilyFiltersPressed
    | RemoveAllDamageTypeFiltersPressed
    | RemoveAllDomainFiltersPressed
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
    | ResetDefaultParamsPressed
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
    | ShowFilters
    | ShowFilterBox String Bool
    | ShowLegacyFiltersChanged Bool
    | ShowResultIndexChanged Bool
    | ShowShortPfsChanged Bool
    | ShowSpoilersChanged Bool
    | ShowSummaryChanged Bool
    | ShowTraitsChanged Bool
    | SizeFilterAdded String
    | SizeFilterRemoved String
    | SkillFilterAdded String
    | SkillFilterRemoved String
    | SortAttributeChanged String
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
    | TraitGroupFilterAdded String
    | TraitGroupFilterRemoved String
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


type Markdown
    = Parsed ParsedMarkdownResult
    | ParsedWithUnflattenedChildren ParsedMarkdownResult
    | NotParsed String


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
    | Short
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


allAttributes : List String
allAttributes =
    [ "strength"
    , "dexterity"
    , "constitution"
    , "intelligence"
    , "wisdom"
    , "charisma"
    ]


alignments : List ( String, String )
alignments =
    [ ( "ce", "Chaotic Evil" )
    , ( "cg", "Chaotic Good" )
    , ( "cn", "Chaotic Neutral" )
    , ( "le", "Lawful Evil" )
    , ( "lg", "Lawful Good" )
    , ( "ln", "Lawful Neutral" )
    , ( "n", "Neutral" )
    , ( "ne", "Neutral Evil" )
    , ( "ng", "Neutral Good" )
    , ( "no alignment", "No Alignment")
    , ( "any", "Any")
    ]


armorCategories : List String
armorCategories =
    [ "unarmored"
    , "light"
    , "medium"
    , "heavy"
    ]


armorGroups : List String
armorGroups =
    [ "chain"
    , "cloth"
    , "composite"
    , "leather"
    , "plate"
    , "skeletal"
    , "wood"
    ]


allDamageTypes : List String
allDamageTypes =
    [ "acid"
    , "all"
    , "area"
    , "bleed"
    , "bludgeoning"
    , "chaotic"
    , "cold"
    , "cold_iron"
    , "electricity"
    , "evil"
    , "fire"
    , "force"
    , "good"
    , "holy"
    , "lawful"
    , "mental"
    , "negative"
    , "orichalcum"
    , "physical"
    , "piercing"
    , "poison"
    , "positive"
    , "precision"
    , "silver"
    , "slashing"
    , "sonic"
    , "spirit"
    , "splash"
    , "unholy"
    ]


fields : List ( String, String )
fields =
    [ ( "ability", "Alias for 'attribute'" )
    , ( "ability_boost", "Alias for 'attribute'" )
    , ( "ability_flaw", "Alias for 'attribute_flaw'" )
    , ( "ability_type", "Familiar ability type (Familiar / Master)" )
    , ( "ac", "[n] Armor class of an armor, creature, or shield" )
    , ( "access", "Access requirements" )
    , ( "actions", "Actions or time required to use an action or activity" )
    , ( "activate", "Activation requirements of an item" )
    , ( "advanced_domain_spell", "Advanced domain spell" )
    , ( "advanced_apocryphal_spell", "Advanced apocryphal domain spell" )
    , ( "alignment", "Alignment" )
    , ( "ammunition", "Ammunition type used by a weapon" )
    , ( "anathema", "Deity anathemas" )
    , ( "apocryphal_spell", "Apocryphal domain spell" )
    , ( "archetype", "Archetypes associated with a feat" )
    , ( "area", "Area of a spell" )
    , ( "armor_category", "Armor category" )
    , ( "armor_group", "Armor group" )
    , ( "aspect", "Relic gift aspect type" )
    , ( "attack_proficiency", "A class's attack proficiencies" )
    , ( "attribute", "Related abilities or ability boosts" )
    , ( "attribute_boost", "Alias for 'attribute'" )
    , ( "attribute_flaw", "Ancestry attribute flaw" )
    , ( "base_item", "Base item of a specific magic item" )
    , ( "bloodline", "Sorcerer bloodlines associated with a spell" )
    , ( "bloodline_spell", "Sorcerer bloodline's spells" )
    , ( "bulk", "Item bulk ('L' is 0.1)" )
    , ( "cast", "Alias for 'actions'" )
    , ( "cha", "[n] Alias for 'charisma'" )
    , ( "charisma", "[n] Charisma" )
    , ( "check_penalty", "[n] Armor check penalty" )
    , ( "cleric_spell", "Cleric spells granted by a deity" )
    , ( "complexity", "Hazard complexity" )
    , ( "component", "Spell casting components (Material / Somatic / Verbal)" )
    , ( "con", "[n] Alias for 'constitution'" )
    , ( "constitution", "[n] Constitution" )
    , ( "cost", "Cost to use an action, ritual, or spell" )
    , ( "creature_ability", "Creature abilities" )
    , ( "creature_family", "Creature family" )
    , ( "damage", "Weapon damage" )
    , ( "damage_die", "[n] Weapon damage die" )
    , ( "damage_type", "Weapon damage type" )
    , ( "defense", "Alias for 'saving_throw'" )
    , ( "defense_proficiency", "A class's defense proficiencies" )
    , ( "deity", "Deities associated with a domain, spell, or weapon" )
    , ( "deity_category", "Deity category" )
    , ( "dex", "[n] Alias for 'dexterity'" )
    , ( "dex_cap", "[n] Armor dex cap" )
    , ( "dexterity", "Dexterity" )
    , ( "disable", "Hazard disable requirements" )
    , ( "divine_font", "Deity's divine font" )
    , ( "domain_spell", "Domain spell" )
    , ( "domain", "Domains related to deity or spell" )
    , ( "domain_alternate", "Alternate domains related to deity" )
    , ( "domain_primary", "Primary domains related to deity" )
    , ( "domain_spell", "Domain spells" )
    , ( "duration", "[n] Duration of spell, ritual, or poison, in seconds" )
    , ( "duration_raw", "Duration exactly as written" )
    , ( "edict", "Deity edicts" )
    , ( "element", "Element traits" )
    , ( "familiar_ability", "Abilities granted by specific familiars" )
    , ( "favored_weapon", "Deity's favored weapon" )
    , ( "feat", "Related feat" )
    , ( "follower_alignment", "Deity's follower alignments" )
    , ( "fort", "[n] Alias for 'fortitude_save'" )
    , ( "fortitude", "[n] Alias for 'fortitude_save'" )
    , ( "fortitude_proficiency", "A class's starting fortitude proficiency" )
    , ( "fortitude_save", "[n] Fortitude save" )
    , ( "frequency", "Frequency of which something can be used" )
    , ( "hands", "Hands required to use item" )
    , ( "hardness", "[n] Hazard or shield hardness" )
    , ( "hazard_type", "Hazard type trait" )
    , ( "heighten", "Spell heightens available" )
    , ( "heighten_level", "All levels a spell can be heightened to (including base level)" )
    , ( "hex_cantrip", "Witch patron theme hex cantrip" )
    , ( "home_plane", "Summoner eidolon home plane" )
    , ( "hp", "[n] Hit points" )
    , ( "immunity", "Immunities" )
    , ( "int", "[n] Alias for 'intelligence'" )
    , ( "intelligence", "[n] Intelligence" )
    , ( "item", "Items carried by a creature" )
    , ( "item_category", "Category of an item" )
    , ( "item_subcategory", "Subcategory of an item" )
    , ( "is_general_background", "Is background a general background? (true / false)" )
    , ( "language", "Languages spoken" )
    , ( "lesson", "Witch lesson" )
    , ( "lesson_type", "Witch lesson type" )
    , ( "l", "[n] alias for 'level'" )
    , ( "level", "[n] Level" )
    , ( "mystery", "Oracle mysteries associated with a spell" )
    , ( "name", "Name" )
    , ( "npc", "Is creature an NPC? (true / false)" )
    , ( "onset", "[n] Onset of a disease or poison in seconds" )
    , ( "onset_raw", "Onset exactly as written" )
    , ( "pantheon", "Pantheons a deity is part of" )
    , ( "pantheon_member", "Deities part of a pantheon" )
    , ( "patron_theme", "Witch patron themes associated with a spell" )
    , ( "per", "[n] Alias for 'perception'" )
    , ( "perception", "[n] Perception" )
    , ( "perception_proficiency", "A class's starting perception proficiency" )
    , ( "pfs", "Pathfinder Society status (Standard / Limited / Restricted)" )
    , ( "plane_category", "Plane category" )
    , ( "prerequisite", "Prerequisites" )
    , ( "price", "[n] Item price in copper coins" )
    , ( "price_raw", "Item price exactly as written" )
    , ( "primary_check", "Primary check of a ritual" )
    , ( "range", "[n] Range of spell or weapon in feet" )
    , ( "range_raw", "Range exactly as written" )
    , ( "rank", "Alias for 'level'" )
    , ( "rarity", "Rarity" )
    , ( "ref", "[n] Alias for 'reflex_save'" )
    , ( "reflex", "[n] Alias for 'reflex_save'" )
    , ( "reflex_proficiency", "A class's starting reflex proficiency" )
    , ( "reflex_save", "[n] Reflex save" )
    , ( "region", "Background region" )
    , ( "release_date", "[n] Release date of source (yyyy-mm-dd)" )
    , ( "reload", "[n] Weapon reload" )
    , ( "required_abilities", "[n] Number of required familiar abilities for a specific familiar" )
    , ( "requirement", "Requirements" )
    , ( "reset", "Trap reset" )
    , ( "resistance.<type>", "[n] Resistance to <type>. See list of valid types below. Use resistance.\\* to match any type." )
    , ( "resistance_raw", "Resistances exactly as written" )
    , ( "sanctification", "Deity sanctification (Holy / Unholy)" )
    , ( "sanctification_raw", "Deity sanctification exactly as written" )
    , ( "saving_throw", "Saving throw or defense for an effect (Fortitude / Reflex / Will / AC)" )
    , ( "school", "Magical school" )
    , ( "secondary_casters", "[n] Secondary casters for a ritual" )
    , ( "secondary_check", "Secondary checks for a ritual" )
    , ( "sense", "Senses" )
    , ( "size", "Size" )
    , ( "skill", "Related skills" )
    , ( "skill_mod.<type>", "[n] Skill modifier of <type>. Valid types are acrobatics, arcana, athletics, crafting, deception, diplomacy, intimidation, medicine, nature, occultism, performance, religion, society, stealth, survival, thievery. Use skill_mod.\\* to match any type." )
    , ( "skill_proficiency", "A class's starting skill proficiencies" )
    , ( "source", "Source book name" )
    , ( "source_raw", "Source book exactly as written incl. page" )
    , ( "source_category", "Source book category" )
    , ( "source_group", "Source book group" )
    , ( "speed.<type>", "[n] Speed of <type>. Valid types are burrow, climb, fly, land, and swim. Use speed.\\* to match any type." )
    , ( "speed_raw", "Speed exactly as written" )
    , ( "speed_penalty", "Speed penalty of armor or shield" )
    , ( "spell", "Related spells" )
    , ( "spell_type", "Spell type ( Spell / Cantrip / Focus )" )
    , ( "spoilers", "Adventure path name if there is a spoiler warning on the page" )
    , ( "stage", "Stages of a disease or poison" )
    , ( "stealth", "Hazard stealth" )
    , ( "str", "[n] Alias for 'strength'" )
    , ( "strength", "[n] Creature strength or armor strength requirement" )
    , ( "strongest_save", "The strongest save(s) of a creature ( Fortitude / Reflex / Will )" )
    , ( "target", "Spell targets" )
    , ( "text", "All text on a page" )
    , ( "tradition", "Traditions of spell or summoner eidolon" )
    , ( "t", "Alias for 'trait'" )
    , ( "trait", "Traits with values removed, e.g. 'Deadly d6' is normalized as 'Deadly'" )
    , ( "trait_group", "Trait group" )
    , ( "trait_raw", "Traits exactly as written" )
    , ( "trigger", "Trigger" )
    , ( "type", "Type" )
    , ( "usage", "Usage of curse or item" )
    , ( "vision", "Ancestry or creature vision type" )
    , ( "warden_spell_tier", "Spell tier for Ranger Warden Spells" )
    , ( "weakest_save", "The weakest save(s) of a creature (Fortitude / Reflex / Will)" )
    , ( "weakness.<type>", "[n] Weakness to <type>. See list of valid types below. Use weakness.\\* to match any type." )
    , ( "weakness_raw", "Weaknesses exactly as written" )
    , ( "weapon_category", "Weapon category (Simple / Martial / Advanced / Ammunition)" )
    , ( "weapon_group", "Weapon group" )
    , ( "weapon_type", "Weapon type (Melee / Ranged)" )
    , ( "will", "[n] Alias for 'will_save'" )
    , ( "will_proficiency", "A class's starting will proficiency" )
    , ( "will_save", "[n] Will save" )
    , ( "wis", "[n] Alias for 'wisdom'" )
    , ( "wisdom", "[n] Wisdom" )
    ]


filterFields : SearchModel -> List ( String, Dict String Bool, Bool )
filterFields searchModel =
    [ ( "actions.keyword", searchModel.filteredActions, False )
    , ( "alignment", searchModel.filteredAlignments, False )
    , ( "armor_category", searchModel.filteredArmorCategories, False )
    , ( "armor_group", searchModel.filteredArmorGroups, False )
    , ( "attribute", searchModel.filteredAttributes, False )
    , ( "component", searchModel.filteredComponents, searchModel.filterComponentsOperator )
    , ( "creature_family", searchModel.filteredCreatureFamilies, False )
    , ( "damage_type", searchModel.filteredDamageTypes, searchModel.filterDamageTypesOperator )
    , ( "domain", searchModel.filteredDomains, searchModel.filterDomainsOperator )
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
    , ( "trait_group", searchModel.filteredTraitGroups, searchModel.filterTraitsOperator )
    , ( "trait", searchModel.filteredTraits, searchModel.filterTraitsOperator )
    , ( "type", searchModel.filteredTypes, False )
    , ( "weakest_save", searchModel.filteredWeakestSaves, False )
    , ( "weapon_category", searchModel.filteredWeaponCategories, False )
    , ( "weapon_group", searchModel.filteredWeaponGroups, False )
    , ( "weapon_type", searchModel.filteredWeaponTypes, False )
    ]


groupFields : List String
groupFields =
    [ "ac"
    , "actions"
    , "alignment"
    , "armor_category"
    , "armor_group"
    , "attribute"
    , "bulk"
    , "creature_family"
    , "damage_type"
    , "deity"
    , "deity_category"
    , "domain"
    , "duration"
    , "element"
    , "heighten_group"
    , "item_category"
    , "item_subcategory"
    , "level"
    , "hands"
    , "pantheon"
    , "pfs"
    , "range"
    , "rank"
    , "rarity"
    , "school"
    , "sanctification"
    , "size"
    , "source"
    , "spell_type"
    , "tradition"
    , "trait"
    , "type"
    , "warden_spell_tier"
    , "weapon_category"
    , "weapon_group"
    , "weapon_type"
    ]


magicSchools : List String
magicSchools =
    [ "abjuration"
    , "conjuration"
    , "divination"
    , "enchantment"
    , "evocation"
    , "illusion"
    , "necromancy"
    , "transmutation"
    ]


pageSizes : List Int
pageSizes =
    [ 20, 50, 100, 250, 1000, 5000 ]


allPageWidths : List Int
allPageWidths =
    [ 600, 900, 1200, 1600, 2000, 2500 ]


predefinedColumnConfigurations : List { columns : List String, label : String }
predefinedColumnConfigurations =
    [ { columns = [ "hp", "size", "speed", "ability_boost", "ability_flaw", "language", "vision", "rarity", "pfs" ]
      , label = "Ancestries"
      }
    , { columns = [ "armor_category", "ac", "dex_cap", "check_penalty", "speed_penalty", "strength_req", "bulk", "armor_group", "trait" ]
      , label = "Armor"
      }
    , { columns = [ "pfs", "ability", "skill", "feat", "rarity", "source" ]
      , label = "Backgrounds"
      }
    , { columns = [ "ability", "hp", "attack_proficiency", "defense_proficiency", "fortitude_proficiency", "reflex_proficiency",  "will_proficiency", "perception_proficiency", "skill_proficiency", "rarity", "pfs" ]
      , label = "Classes"
      }
    , { columns = [ "level", "hp", "ac", "fortitude", "reflex", "will", "strongest_save", "weakest_save", "perception", "sense", "size", "alignment", "rarity", "speed", "immunity", "resistance", "weakness", "trait", "creature_family", "language" ]
      , label = "Creatures"
      }
    , { columns = [ "pfs", "edict", "anathema", "domain", "divine_font", "sanctification", "ability", "skill", "favored_weapon", "deity_category", "pantheon", "source" ]
      , label = "Deities"
      }
    , { columns = [ "level", "saving_throw", "onset", "stage", "trait", "rarity" ]
      , label = "Diseases"
      }
    , { columns = [ "level", "trait", "prerequisite", "summary", "rarity", "pfs", "source" ]
      , label = "Feats"
      }
    , { columns = [ "item_category", "item_subcategory", "level", "price", "bulk", "trait", "rarity", "pfs" ]
      , label = "Items"
      }
    , { columns = [ "level", "price", "saving_throw", "onset", "duration", "stage", "trait", "rarity", "pfs" ]
      , label = "Poisons"
      }
    , { columns = [ "type", "aspect", "prerequisite", "trait" ]
      , label = "Relic gifts"
      }
    , { columns = [ "rank", "heighten", "school", "trait", "primary_check", "secondary_casters", "secondary_check", "cost", "actions", "target", "range", "area", "duration", "rarity", "pfs" ]
      , label = "Rituals"
      }
    , { columns = [ "spell_type", "rank", "heighten", "tradition", "school", "trait", "actions", "component", "trigger", "target", "range", "area", "duration", "defense", "rarity", "pfs" ]
      , label = "Spells"
      }
    , { columns = [ "weapon_type", "weapon_category", "weapon_group", "trait", "damage", "hands", "range", "reload", "bulk", "price" ]
      , label = "Weapons"
      }
    ]


rarities : List String
rarities =
    [ "common"
    , "uncommon"
    , "rare"
    , "unique"
    ]


saves : List String
saves =
    [ "fortitude"
    , "reflex"
    , "will"
    ]


allSizes : List String
allSizes =
    [ "tiny"
    , "small"
    , "medium"
    , "large"
    , "huge"
    , "gargantuan"
    ]


allSkills : List String
allSkills =
    [ "acrobatics"
    , "arcana"
    , "athletics"
    , "crafting"
    , "deception"
    , "diplomacy"
    , "intimidation"
    , "lore"
    , "medicine"
    , "nature"
    , "occultism"
    , "performance"
    , "religion"
    , "society"
    , "stealth"
    , "survival"
    , "thievery"
    ]


sortFields : List ( String, String, Bool )
sortFields =
    [ ( "ability_type", "ability_type", False )
    , ( "ac", "ac", True )
    , ( "actions", "actions_number", True )
    , ( "alignment", "alignment", False )
    , ( "archetype", "archetype.keyword", False )
    , ( "area", "area.keyword", False )
    , ( "armor_category", "armor_category", False )
    , ( "armor_group", "armor_group", False )
    , ( "aspect", "aspect", False )
    , ( "attribute", "attribute", False )
    , ( "base_item", "base_item.keyword", False )
    , ( "bloodline", "bloodline", False )
    , ( "bulk", "bulk", True )
    , ( "charisma", "charisma", True )
    , ( "check_penalty", "check_penalty", True )
    , ( "complexity", "complexity", False )
    , ( "component", "component", False )
    , ( "constitution", "constitution", True )
    , ( "cost", "cost.keyword", False )
    , ( "creature_family", "creature_family", False )
    , ( "damage", "damage_die", True )
    , ( "damage_type", "damage_type", False )
    , ( "deity", "deity", False )
    , ( "deity_category", "deity_category.keyword", False )
    , ( "deity_category_order", "deity_category_order", False )
    , ( "dex_cap", "dex_cap", True )
    , ( "dexterity", "dexterity", True )
    , ( "divine_font", "divine_font", False )
    , ( "domain", "domain", False )
    , ( "duration", "duration", True )
    , ( "favored_weapon", "favored_weapon.keyword", False )
    , ( "fortitude", "fortitude", False )
    , ( "fortitude_proficiency", "fortitude_proficiency", False )
    , ( "frequency", "frequency.keyword", False )
    , ( "hands", "hands.keyword", False )
    , ( "hardness", "hardness", False )
    , ( "hazard_type", "hazard_type", False )
    , ( "heighten", "heighten", False )
    , ( "hp", "hp", True )
    , ( "intelligence", "intelligence", False )
    , ( "item_category", "item_category", False )
    , ( "item_subcategory", "item_subcategory", False )
    , ( "level", "level", True )
    , ( "mystery", "mystery", False )
    , ( "name", "name.keyword", False )
    , ( "onset", "onset", True )
    , ( "patron_theme", "patron_theme", False )
    , ( "perception", "perception", True )
    , ( "perception_proficiency", "perception_proficiency", False )
    , ( "pfs", "pfs", False )
    , ( "plane_category", "plane_category", False )
    , ( "prerequisite", "prerequisite.keyword", False )
    , ( "price", "price", True )
    , ( "primary_check", "primary_check.keyword", False )
    , ( "range", "range", True )
    , ( "rank", "rank", True )
    , ( "rarity", "rarity_id", True )
    , ( "reflex", "reflex", True )
    , ( "reflex_proficiency", "reflex_proficiency", False )
    , ( "region", "region", False )
    , ( "release_date", "release_date", False )
    , ( "requirement", "requirement.keyword", False )
    , ( "sanctification", "sanctification_raw.keyword", False )
    , ( "saving_throw", "saving_throw.keyword", False )
    , ( "school", "school", False )
    , ( "secondary_casters", "secondary_casters", False )
    , ( "secondary_check", "secondary_check.keyword", False )
    , ( "size", "size_id", True )
    , ( "source", "source", False )
    , ( "source_category", "source_category", False )
    , ( "source_group", "source_group", False )
    , ( "speed_penalty", "speed_penalty.keyword", False )
    , ( "spell_type", "spell_type", False )
    , ( "spoilers", "spoilers", False )
    , ( "strength", "strength", True )
    , ( "strength_req", "strength", True )
    , ( "strongest_save", "strongest_save", False )
    , ( "target", "target.keyword", False )
    , ( "tradition", "tradition", False )
    , ( "trigger", "trigger.keyword", False )
    , ( "type", "type", False )
    , ( "vision", "vision.keyword", False )
    , ( "warden_spell_tier", "warden_spell_tier", False )
    , ( "weakest_save", "weakest_save", False )
    , ( "weapon_category", "weapon_category", False )
    , ( "weapon_group", "weapon_group", False )
    , ( "weapon_type", "weapon_type", False )
    , ( "will", "will", True )
    , ( "will_proficiency", "will_proficiency", False )
    , ( "wisdom", "wisdom", True )
    ]
        |> List.append
            (List.map
                (\type_ ->
                    ( "resistance." ++ type_
                    , "resistance." ++ type_
                    , True
                    )
                )
                allDamageTypes
            )
        |> List.append
            (List.map
                (\type_ ->
                    ( "weakness." ++ type_
                    , "weakness." ++ type_
                    , True
                    )
                )
                allDamageTypes
            )
        |> List.append
            (List.map
                (\type_ ->
                    ( "speed." ++ type_
                    , "speed." ++ type_
                    , True
                    )
                )
                speedTypes
            )


speedTypes : List String
speedTypes =
    [ "burrow"
    , "climb"
    , "fly"
    , "land"
    , "max"
    , "swim"
    ]


sourceCategories : List String
sourceCategories =
    [ "adventure paths"
    , "adventures"
    , "blog posts"
    , "comics"
    , "lost omens"
    , "rulebooks"
    , "society"
    ]


tableColumns : List String
tableColumns =
    [ "ability_type"
    , "ac"
    , "actions"
    , "advanced_apocryphal_spell"
    , "advanced_domain_spell"
    , "alignment"
    , "apocryphal_spell"
    , "archetype"
    , "area"
    , "armor_category"
    , "armor_group"
    , "aspect"
    , "attack_proficiency"
    , "attribute"
    , "attribute_boost"
    , "attribute_flaw"
    , "base_item"
    , "bloodline"
    , "bulk"
    , "charisma"
    , "check_penalty"
    , "complexity"
    , "component"
    , "constitution"
    , "cost"
    , "creature_ability"
    , "creature_family"
    , "damage"
    , "damage_type"
    , "defense"
    , "defense_proficiency"
    , "deity"
    , "deity_category"
    , "dex_cap"
    , "dexterity"
    , "divine_font"
    , "domain"
    , "domain_spell"
    , "duration"
    , "element"
    , "favored_weapon"
    , "feat"
    , "follower_alignment"
    , "fortitude"
    , "frequency"
    , "hands"
    , "hardness"
    , "hazard_type"
    , "heighten"
    , "heighten_level"
    , "hp"
    , "icon_image"
    , "image"
    , "immunity"
    , "intelligence"
    , "item_category"
    , "item_subcategory"
    , "language"
    , "lesson"
    , "level"
    , "mystery"
    , "onset"
    , "pantheon"
    , "pantheon_member"
    , "patron_theme"
    , "perception"
    , "perception_proficiency"
    , "pfs"
    , "plane_category"
    , "prerequisite"
    , "price"
    , "primary_check"
    , "range"
    , "rank"
    , "rarity"
    , "reflex"
    , "region"
    , "release_date"
    , "requirement"
    , "resistance"
    , "sanctification"
    , "saving_throw"
    , "school"
    , "secondary_casters"
    , "secondary_check"
    , "sense"
    , "size"
    , "skill"
    , "skill_proficiency"
    , "source"
    , "source_category"
    , "source_group"
    , "speed"
    , "speed_penalty"
    , "spell"
    , "spell_type"
    , "spoilers"
    , "stage"
    , "strength"
    , "strength_req"
    , "strongest_save"
    , "summary"
    , "target"
    , "tradition"
    , "trait"
    , "trigger"
    , "type"
    , "url"
    , "usage"
    , "vision"
    , "warden_spell_tier"
    , "weakest_save"
    , "weakness"
    , "weapon_category"
    , "weapon_group"
    , "weapon_type"
    , "will"
    , "wisdom"
    ]


allTraditions : List String
allTraditions =
    [ "arcane"
    , "divine"
    , "occult"
    , "primal"
    ]


traditionsAndSpellLists : List String
traditionsAndSpellLists =
    [ "arcane"
    , "divine"
    , "elemental"
    , "occult"
    , "primal"
    ]


weaponCategories : List String
weaponCategories =
    [ "simple"
    , "martial"
    , "advanced"
    , "ammunition"
    , "unarmed"
    ]


weaponTypes : List String
weaponTypes =
    [ "melee"
    , "ranged"
    ]


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
        , filteredAttributes = getBoolDictFromParams params "abilities"
            |> Dict.union (getBoolDictFromParams params "attributes")
        , filteredActions = getBoolDictFromParams params "actions"
        , filteredAlignments = getBoolDictFromParams params "alignments"
        , filteredArmorCategories = getBoolDictFromParams params "armor-categories"
        , filteredArmorGroups = getBoolDictFromParams params "armor-groups"
        , filteredComponents = getBoolDictFromParams params "components"
        , filteredCreatureFamilies = getBoolDictFromParams params "creature-families"
        , filteredDamageTypes = getBoolDictFromParams params "damage-types"
        , filteredDomains = getBoolDictFromParams params "domains"
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
        , filteredTraitGroups = getBoolDictFromParams params "trait-groups"
        , filteredTraits = getBoolDictFromParams params "traits"
        , filteredTypes = getBoolDictFromParams params "types"
        , filteredWeakestSaves = getBoolDictFromParams params "weakest-saves"
        , filteredWeaponCategories = getBoolDictFromParams params "weapon-categories"
        , filteredWeaponGroups = getBoolDictFromParams params "weapon-groups"
        , filteredWeaponTypes = getBoolDictFromParams params "weapon-types"
        , filterApCreatures = Dict.get "ap-creatures" params == Just [ "hide" ]
        , filterSpoilers = Dict.get "spoilers" params == Just [ "hide" ]
        , filterComponentsOperator = Dict.get "components-operator" params /= Just [ "or" ]
        , filterDamageTypesOperator = Dict.get "damage-types-operator" params /= Just [ "or" ]
        , filterDomainsOperator = Dict.get "domains-operator" params /= Just [ "or" ]
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
        , legacyMode =
            case Dict.get "legacy" params of
                Just [ "yes" ] ->
                    Just True

                Just [ "no" ] ->
                    Just False

                _ ->
                    Nothing
        , resultDisplay =
            case Dict.get "display" params of
                Just [ "full" ] ->
                    Full

                Just [ "grouped" ] ->
                    Grouped

                Just [ "list" ] ->
                    Short

                Just [ "table" ] ->
                    Table

                _ ->
                    Short
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
    , if searchModel.filterApCreatures then
        [ "!(type:creature source_category:\"adventure paths\")" ]

      else
        []
    , case searchModel.legacyMode of
        Just True ->
            [ "!legacy_id:*" ]

        Just False ->
            [ "!remaster_id:*" ]

        Nothing ->
            []

    , if searchModel.filterSpoilers then
        [ "!spoilers:*" ]

      else
        []
    ]
        |> List.concat
        |> String.join " "


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


sortIsRandom : SearchModel -> Bool
sortIsRandom searchModel =
    searchModel.sort == [ ( "random", Asc ) ]


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


numberWithSign : Int -> String
numberWithSign int =
    if int >= 0 then
        "+" ++ String.fromInt int

    else
        String.fromInt int


getIntFromString : String -> Maybe Int
getIntFromString str =
    str
        |> String.filter Char.isDigit
        |> String.toInt


formatDate : ViewModel -> String -> String
formatDate model date =
    let
        format : String
        format =
            if model.dateFormat == "default" then
                model.browserDateFormat

            else
                model.dateFormat
    in
    Date.fromIsoString date
        |> Result.map (Date.format format)
        |> Result.withDefault date


getUrl : ViewModel -> Document -> String
getUrl viewModel doc =
    viewModel.resultBaseUrl ++ doc.url


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


actionsToInt : String -> Int
actionsToInt value =
    let
        multiplier : Int
        multiplier =
            List.Extra.find
                (\(str, _) ->
                    String.contains str (String.toLower value)
                )
                [ ( "free action", 0 )
                , ( "reaction", 1 )
                , ( "single action", 2 )
                , ( "two actions", 4 )
                , ( "three actions", 6 )
                , ( "round", 6 )
                , ( "minute", 60 )
                , ( "hour", 60 * 60 )
                , ( "day", 60 * 60 * 24 )
                , ( "week", 60 * 60 * 24 * 7 )
                , ( "month", 60 * 60 * 24 * 30 )
                , ( "year", 60 * 60 * 24 * 365 )
                ]
                |> Maybe.map Tuple.second
                |> Maybe.withDefault 1
    in
    getIntFromString value
        |> Maybe.withDefault 1
        |> (*) multiplier


toOrdinal : Int -> String
toOrdinal n =
    if ( modBy 100 (abs n) ) // 10 == 1 then
        String.fromInt n ++ "th"

    else
        case modBy 10 (abs n) of
            1 ->
                String.fromInt n ++ "st"

            2 ->
                String.fromInt n ++ "nd"

            3 ->
                String.fromInt n ++ "rd"

            _ ->
                String.fromInt n ++ "th"


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


flattenMarkdown :
    Bool
    -> Dict String (Result Http.Error Document)
    -> Int
    -> Maybe String
    -> List Markdown.Block.Block
    -> ( Bool, List Markdown.Block.Block )
flattenMarkdown legacyMode documents parentLevel overrideTitleRight blocks =
    List.foldr
        (\block ( previousBlocksHaveChildren, flattenedBlocks ) ->
            let
                ( currentBlockHasChildren, flattenedBlock ) =
                    flattenMarkdownBlock legacyMode documents parentLevel overrideTitleRight block
            in
            ( previousBlocksHaveChildren || currentBlockHasChildren
            , flattenedBlock :: flattenedBlocks
            )
        )
        ( False, [] )
        blocks


flattenMarkdownBlock :
    Bool
    -> Dict String (Result Http.Error Document)
    -> Int
    -> Maybe String
    -> Markdown.Block.Block
    -> ( Bool, Markdown.Block.Block )
flattenMarkdownBlock legacyMode documents parentLevel overrideTitleRight block =
    case block of
        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "title" attributes children) ->
            let
                originalTitleLevel : Int
                originalTitleLevel =
                    getValueFromAttribute "original-level" attributes
                        |> Maybe.Extra.orElse (getValueFromAttribute "level" attributes)
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 1

                titleLevel : Int
                titleLevel =
                    originalTitleLevel + parentLevel - 1

                right : Maybe String
                right =
                    if originalTitleLevel == 1 then
                        overrideTitleRight
                            |> Maybe.Extra.orElse (getValueFromAttribute "right" attributes)

                    else
                        getValueFromAttribute "right" attributes
            in
            ( False
            , Markdown.Block.HtmlElement
                "title"
                (List.append
                    (attributes
                        |> List.filter (.name >> (/=) "level")
                        |> List.filter (.name >> (/=) "right")
                    )
                    [ { name = "level"
                      , value = String.fromInt titleLevel
                      }
                    , { name = "original-level"
                      , value = String.fromInt originalTitleLevel
                      }
                    , { name = "right"
                      , value = Maybe.withDefault "" right
                      }
                    ]
                )
                children
                |> Markdown.Block.HtmlBlock
            )

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "document" attributes _) ->
            let
                originalDocumentLevel : Int
                originalDocumentLevel =
                    getValueFromAttribute "level" attributes
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 2

                documentLevel : Int
                documentLevel =
                    originalDocumentLevel + parentLevel - 1

                documentId : String
                documentId =
                    getValueFromAttribute "id" attributes
                        |> Maybe.withDefault ""

                idToWorkWith : String
                idToWorkWith =
                    case Dict.get documentId documents of
                        Just (Ok doc) ->
                            case ( legacyMode, doc.legacyId, doc.remasterId ) of
                                ( True, Just legacyId, _ ) ->
                                    legacyId

                                ( True, Nothing, _ ) ->
                                    documentId

                                ( False, _, Just "0" ) ->
                                    documentId

                                ( False, _, Just remasterId ) ->
                                    remasterId

                                ( False, _, _ ) ->
                                    documentId
                        _ ->
                            documentId

                document : Maybe Document
                document =
                    Dict.get idToWorkWith documents
                        |> Maybe.andThen Result.toMaybe

                documentBlocks : Maybe (List Markdown.Block.Block)
                documentBlocks =
                    document
                        |> Maybe.map .markdown
                        |> Maybe.andThen getParsedMarkdown
                        |> Maybe.andThen Result.toMaybe
            in
            case documentBlocks of
                Just blocks ->
                    let
                        ( hasChildren, flattenedBlocks ) =
                            flattenMarkdown
                                legacyMode
                                documents
                                documentLevel
                                (getValueFromAttribute "override-title-right" attributes)
                                blocks
                    in
                    ( hasChildren
                    , Markdown.Block.HtmlBlock
                        (Markdown.Block.HtmlElement
                            "document-flattened"
                            (List.append
                                (attributes
                                    |> List.filter (.name >> (/=) "id")
                                    |> List.filter (.name >> (/=) "level")
                                )
                                [ { name = "id"
                                  , value = idToWorkWith
                                  }
                                , { name = "level"
                                  , value = String.fromInt documentLevel
                                  }
                                ]
                            )
                            flattenedBlocks
                        )
                    )

                Nothing ->
                    ( True, block )

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "document-flattened" attributes blocks) ->
            let
                documentLevel : Int
                documentLevel =
                    getValueFromAttribute "level" attributes
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 1

                ( hasChildren, flattenedBlocks ) =
                    flattenMarkdown legacyMode documents documentLevel Nothing blocks
            in
            ( hasChildren
            , Markdown.Block.HtmlBlock
                (Markdown.Block.HtmlElement
                    "document-flattened"
                    attributes
                    flattenedBlocks
                )
            )

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement tag attributes blocks) ->
            let
                ( hasChildren, flattenedBlocks ) =
                    flattenMarkdown legacyMode documents parentLevel Nothing blocks
            in
            ( hasChildren
            , Markdown.Block.HtmlBlock
                (Markdown.Block.HtmlElement
                    tag
                    attributes
                    flattenedBlocks
                )
            )

        _ ->
            ( False, block )


getParsedMarkdown : Markdown -> Maybe ParsedMarkdownResult
getParsedMarkdown markdown =
    case markdown of
        Parsed parsed ->
            Just parsed

        ParsedWithUnflattenedChildren parsed ->
            Just parsed

        NotParsed _ ->
            Nothing


getValueFromAttribute : String -> List { name : String, value : String } -> Maybe String
getValueFromAttribute name attributes =
    attributes
        |> List.Extra.find (.name >> (==) name)
        |> Maybe.map .value


mergeInlines : Markdown.Block.Block -> Markdown.Block.Block
mergeInlines block =
    let
        inlineTags : List String
        inlineTags =
            [ "actions"
            , "br"
            , "date"
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


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Field.require "currentUrl" Decode.string <| \currentUrl ->
    Field.require "dataUrl" Decode.string <| \dataUrl ->
    Field.require "elasticUrl" Decode.string <| \elasticUrl ->
    Field.attempt "autofocus" Decode.bool <| \autofocus ->
    Field.attempt "browserDateFormat" Decode.string <| \browserDateFormat ->
    Field.attempt "resultBaseUrl" Decode.string <| \resultBaseUrl ->
    Field.attempt "defaultQuery" Decode.string <| \defaultQuery ->
    Field.attempt "fixedParams" Decode.string <| \fixedParams ->
    Field.attempt "fixedQueryString" Decode.string <| \fixedQueryString ->
    Field.attempt "loadAll" Decode.bool <| \loadAll ->
    Field.attempt "legacyMode" Decode.bool <| \legacyMode ->
    Field.attempt "localStorage" (Decode.dict Decode.string) <| \localStorage ->
    Field.attempt "noUi" Decode.bool <| \noUi ->
    Field.attempt "pageId" Decode.string <| \pageId ->
    Field.attempt "randomSeed" Decode.int <| \randomSeed ->
    Field.attempt "removeFilters" (Decode.list Decode.string) <| \removeFilters ->
    Field.attempt "windowHeight" Decode.int <| \windowHeight ->
    Field.attempt "windowWidth" Decode.int <| \windowWidth ->
    Decode.succeed
        { autofocus = Maybe.withDefault defaultFlags.autofocus autofocus
        , browserDateFormat = Maybe.withDefault defaultFlags.browserDateFormat browserDateFormat
        , currentUrl = currentUrl
        , dataUrl = dataUrl
        , defaultQuery = Maybe.withDefault defaultFlags.defaultQuery defaultQuery
        , elasticUrl = elasticUrl
        , fixedParams =
            fixedParams
                |> Maybe.map queryToParamsDict
                |> Maybe.withDefault defaultFlags.fixedParams
        , fixedQueryString = Maybe.withDefault defaultFlags.fixedQueryString fixedQueryString
        , loadAll = Maybe.withDefault defaultFlags.loadAll loadAll
        , legacyMode = Maybe.withDefault defaultFlags.legacyMode legacyMode
        , localStorage = Maybe.withDefault defaultFlags.localStorage localStorage
        , noUi = Maybe.withDefault defaultFlags.noUi noUi
        , pageId = Maybe.withDefault defaultFlags.pageId pageId
        , randomSeed = Maybe.withDefault defaultFlags.randomSeed randomSeed
        , removeFilters = Maybe.withDefault defaultFlags.removeFilters removeFilters
            |> (\filters ->
                if List.member "abilities" filters then
                    "attributes" :: filters

                else
                    filters
               )
        , resultBaseUrl = Maybe.withDefault defaultFlags.resultBaseUrl resultBaseUrl
        , windowHeight = Maybe.withDefault defaultFlags.windowHeight windowHeight
        , windowWidth = Maybe.withDefault defaultFlags.windowWidth windowWidth
        }


encodeObjectMaybe : List (Maybe ( String, Encode.Value )) -> Encode.Value
encodeObjectMaybe list =
    Maybe.Extra.values list
        |> Encode.object


searchResultDecoder : Decode.Decoder SearchResult
searchResultDecoder =
    Field.requireAt [ "hits", "hits" ] (Decode.list (Decode.field "_id" Decode.string)) <| \documentIds ->
    Field.requireAt [ "hits", "hits" ] (Decode.list (Decode.field "sort" Decode.value)) <| \sorts ->
    Field.requireAt [ "hits", "total", "value" ] Decode.int <| \total ->
    Field.attempt "aggregations" groupAggregationsDecoder <| \groupAggs ->
    Field.attemptAt [ "hits", "hits" ] (Decode.list (Decode.field "_index" Decode.string)) <| \indices ->
    Decode.succeed
        { documentIds = documentIds
        , searchAfter =
            sorts
                |> List.Extra.last
                |> Maybe.withDefault Encode.null
        , total = total
        , groupAggs = groupAggs
        , index = Maybe.andThen List.head indices
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
        [ "aggregations", "domain" ]
        (aggregationBucketDecoder Decode.string)
        <| \domains ->
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
        , domains = domains
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


traitAggregationsDecoder : Decode.Decoder (Dict String (List String))
traitAggregationsDecoder =
    Decode.list
        (Field.require "group" Decode.string <| \group ->
         Field.require "trait" Decode.string <| \trait ->
         Decode.succeed
            { group = String.toLower group
            , trait = String.toLower trait
            }
        )
        |> Decode.map
            (\traitGroups ->
                traitGroups
                    |> Dict.Extra.groupBy .group
                    |> Dict.map (\_ v -> List.map .trait v)
            )


sourcesAggregationDecoder : Decode.Decoder (List Source)
sourcesAggregationDecoder =
    Decode.list
        (Field.require "category" Decode.string <| \category ->
         Field.require "name" Decode.string <| \name ->
         Decode.succeed
            { category = category
            , name = name
            }
        )


sourcesDecoder : Decode.Decoder (List Document)
sourcesDecoder =
    Decode.at [ "hits", "hits" ] (Decode.list (Decode.field "_source" documentDecoder))


intListDecoder : Decode.Decoder (List Int)
intListDecoder =
    Decode.oneOf
        [ Decode.list Decode.int
        , Decode.int
            |> Decode.map List.singleton
        ]


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
    Field.require "id" Decode.string <| \id ->
    Field.require "name" Decode.string <| \name ->
    Field.require "type" Decode.string <| \type_ ->
    Field.require "url" Decode.string <| \url ->
    Field.attempt "ability_type" Decode.string <| \abilityType ->
    Field.attempt "ac" Decode.int <| \ac ->
    Field.attempt "actions" Decode.string <| \actions ->
    Field.attempt "activate" Decode.string <| \activate ->
    Field.attempt "advanced_apocryphal_spell_markdown" Decode.string <| \advancedApocryphalSpell ->
    Field.attempt "advanced_domain_spell_markdown" Decode.string <| \advancedDomainSpell ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "anathema" Decode.string <| \anathemas ->
    Field.attempt "apocryphal_spell_markdown" Decode.string <| \apocryphalSpell ->
    Field.attempt "archetype" Decode.string <| \archetype ->
    Field.attempt "area" Decode.string <| \area ->
    Field.attempt "armor_category" Decode.string <| \armorCategory ->
    Field.attempt "armor_group_markdown" Decode.string <| \armorGroup ->
    Field.attempt "aspect" Decode.string <| \aspect ->
    Field.attempt "attack_proficiency" stringListDecoder <| \attackProficiencies ->
    Field.attempt "attribute_flaw" stringListDecoder <| \attributeFlaws ->
    Field.attempt "attribute" stringListDecoder <| \attributes ->
    Field.attempt "base_item_markdown" Decode.string <| \baseItems ->
    Field.attempt "bloodline_markdown" Decode.string <| \bloodlines ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "bulk" Decode.float <| \bulk ->
    Field.attempt "bulk_raw" Decode.string <| \bulkRaw ->
    Field.attempt "charisma" Decode.int <| \charisma ->
    Field.attempt "check_penalty" Decode.int <| \checkPenalty ->
    Field.attempt "complexity" Decode.string <| \complexity ->
    Field.attempt "component" stringListDecoder <| \components ->
    Field.attempt "constitution" Decode.int <| \constitution ->
    Field.attempt "cost_markdown" Decode.string <| \cost ->
    Field.attempt "creature_ability" stringListDecoder <| \creatureAbilities ->
    Field.attempt "creature_family" Decode.string <| \creatureFamily ->
    Field.attempt "creature_family_markdown" Decode.string <| \creatureFamilyMarkdown ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "damage_type" stringListDecoder <| \damageTypes ->
    Field.attempt "defense_proficiency" stringListDecoder <| \defenseProficiencies ->
    Field.attempt "deity" stringListDecoder <| \deitiesList ->
    Field.attempt "deity_markdown" Decode.string <| \deities ->
    Field.attempt "deity_category" Decode.string <| \deityCategory ->
    Field.attempt "dex_cap" Decode.int <| \dexCap ->
    Field.attempt "dexterity" Decode.int <| \dexterity ->
    Field.attempt "divine_font" stringListDecoder <| \divineFonts ->
    Field.attempt "domain" stringListDecoder <| \domainsList ->
    Field.attempt "domain_markdown" Decode.string <| \domains ->
    Field.attempt "domain_spell_markdown" Decode.string <| \domainSpell ->
    Field.attempt "duration" Decode.int <| \durationValue ->
    Field.attempt "duration_raw" Decode.string <| \duration ->
    Field.attempt "edict" Decode.string <| \edicts ->
    Field.attempt "element" stringListDecoder <| \elements ->
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
    Field.attempt "heighten" stringListDecoder <| \heighten ->
    Field.attempt "heighten_group" stringListDecoder <| \heightenGroups ->
    Field.attempt "heighten_level" (Decode.list Decode.int) <| \heightenLevels ->
    Field.attempt "hp_raw" Decode.string <| \hp ->
    Field.attempt "icon_image" Decode.string <| \iconImage ->
    Field.attempt "image" stringListDecoder <| \images ->
    Field.attempt "immunity_markdown" Decode.string <| \immunities ->
    Field.attempt "intelligence" Decode.int <| \intelligence ->
    Field.attempt "item_category" Decode.string <| \itemCategory ->
    Field.attempt "item_subcategory" Decode.string <| \itemSubcategory ->
    Field.attempt "language_markdown" Decode.string <| \languages ->
    Field.attempt "legacy_id" Decode.string <| \legacyId ->
    Field.attempt "lesson_markdown" Decode.string <| \lessons ->
    Field.attempt "lesson_type" Decode.string <| \lessonType ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "markdown" Decode.string <| \markdown ->
    Field.attempt "mystery_markdown" Decode.string <| \mysteries ->
    Field.attempt "onset_raw" Decode.string <| \onset ->
    Field.attempt "pantheon" stringListDecoder <| \pantheons ->
    Field.attempt "pantheon_markdown" Decode.string <| \pantheonMarkdown ->
    Field.attempt "pantheon_member_markdown" Decode.string <| \pantheonMembers ->
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
    Field.attempt "rarity_id" Decode.int <| \rarityId ->
    Field.attempt "reflex_save" Decode.int <| \ref ->
    Field.attempt "reflex_proficiency" Decode.string <| \reflexProficiency ->
    Field.attempt "region" Decode.string <| \region->
    Field.attempt "release_date" Decode.string <| \releaseDate ->
    Field.attempt "reload_raw" Decode.string <| \reload ->
    Field.attempt "remaster_id" Decode.string <| \remasterId ->
    Field.attempt "required_abilities" Decode.string <| \requiredAbilities ->
    Field.attempt "requirement_markdown" Decode.string <| \requirements ->
    Field.attempt "resistance" damageTypeValuesDecoder <| \resistanceValues ->
    Field.attempt "resistance_markdown" Decode.string <| \resistances ->
    Field.attempt "sanctification_raw" Decode.string <| \sanctification ->
    Field.attempt "saving_throw_markdown" Decode.string <| \savingThrow ->
    Field.attempt "school" Decode.string <| \school ->
    Field.attempt "search_markdown" Decode.string <| \searchMarkdown ->
    Field.attempt "secondary_casters_raw" Decode.string <| \secondaryCasters ->
    Field.attempt "secondary_check_markdown" Decode.string <| \secondaryChecks ->
    Field.attempt "sense_markdown" Decode.string <| \senses ->
    Field.attempt "size_id" intListDecoder <| \sizeIds ->
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
    Field.attempt "spell_markdown" Decode.string <| \spell ->
    Field.attempt "spell_list" Decode.string <| \spellList ->
    Field.attempt "spell_type" Decode.string <| \spellType ->
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
    Field.attempt "warden_spell_tier" Decode.string <| \wardenSpellTier ->
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
        { id = id
        , category = category
        , name = name
        , type_ = type_
        , url = url
        , abilityType = abilityType
        , ac = ac
        , actions = actions
        , activate = activate
        , advancedApocryphalSpell = advancedApocryphalSpell
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , anathemas = anathemas
        , apocryphalSpell = apocryphalSpell
        , archetype = archetype
        , area = area
        , armorCategory = armorCategory
        , armorGroup = armorGroup
        , aspect = aspect
        , attackProficiencies = Maybe.withDefault [] attackProficiencies
        , attributeFlaws = Maybe.withDefault [] attributeFlaws
        , attributes = Maybe.withDefault [] attributes
        , baseItems = baseItems
        , bloodlines = bloodlines
        , breadcrumbs = breadcrumbs
        , bulk = bulk
        , bulkRaw = bulkRaw
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
        , damageTypes = Maybe.withDefault [] damageTypes
        , defenseProficiencies = Maybe.withDefault [] defenseProficiencies
        , deities = deities
        , deitiesList = Maybe.withDefault [] deitiesList
        , deityCategory = deityCategory
        , dexCap = dexCap
        , dexterity = dexterity
        , divineFonts = Maybe.withDefault [] divineFonts
        , domains = domains
        , domainsList = Maybe.withDefault [] domainsList
        , domainSpell = domainSpell
        , duration = duration
        , durationValue = durationValue
        , edicts = edicts
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
        , heightenGroups = Maybe.withDefault [] heightenGroups
        , heightenLevels = Maybe.withDefault [] heightenLevels
        , hp = hp
        , iconImage = iconImage
        , images = Maybe.withDefault [] images
        , immunities = immunities
        , intelligence = intelligence
        , itemCategory = itemCategory
        , itemSubcategory = itemSubcategory
        , languages = languages
        , legacyId = legacyId
        , lessonType = lessonType
        , lessons = lessons
        , level = level
        , markdown = NotParsed (Maybe.withDefault "" markdown)
        , mysteries = mysteries
        , onset = onset
        , pantheons = Maybe.withDefault [] pantheons
        , pantheonMarkdown = pantheonMarkdown
        , pantheonMembers = pantheonMembers
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
        , rarityId = rarityId
        , ref = ref
        , reflexProficiency = reflexProficiency
        , region = region
        , releaseDate = releaseDate
        , reload = reload
        , remasterId = remasterId
        , requiredAbilities = requiredAbilities
        , requirements = requirements
        , resistanceValues = resistanceValues
        , resistances = resistances
        , sanctification = sanctification
        , savingThrow = savingThrow
        , school = school
        , searchMarkdown = NotParsed (Maybe.withDefault "" searchMarkdown)
        , secondaryCasters = secondaryCasters
        , secondaryChecks = secondaryChecks
        , senses = senses
        , sizeIds = Maybe.withDefault [] sizeIds
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
        , spellType = spellType
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
        , wardenSpellTier = wardenSpellTier
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
