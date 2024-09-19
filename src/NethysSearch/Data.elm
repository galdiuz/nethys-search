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
import Markdown.Block as MB
import Markdown.Parser
import Markdown.Renderer
import Maybe.Extra
import Order.Extra
import Set exposing (Set)
import String.Extra
import Tuple3
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
    , globalAggregations : Maybe (Result Http.Error GlobalAggregations)
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
    , queryFieldFocused : Bool
    , randomSeed : Int
    , savedColumnConfigurations : Dict String (List String)
    , savedColumnConfigurationName : String
    , searchModel : SearchModel
    , showQueryControls : Bool
    , showLegacyFilters : Bool
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
    , maskedSourceGroups : Set String
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
    , dropdownFilterInput : String
    , dropdownFilterSelectedIndex : Int
    , dropdownFilterState : DropdownFilterState
    , filteredFromValues : Dict String String
    , filteredToValues : Dict String String
    , filteredValues : Dict String (Dict String Bool)
    , filterApCreatures : Bool
    , filterItemChildren : Bool
    , filterOperators : Dict String Bool
    , filterSpoilers : Bool
    , fixedQueryString : String
    , groupField1 : String
    , groupField2 : Maybe String
    , groupField3 : Maybe String
    , groupedLinkLayout : GroupedLinkLayout
    , lastSearchHash : Maybe String
    , legacyMode : Maybe Bool
    , loadingNew : Bool
    , query : String
    , queryType : QueryType
    , removeFilters : List String
    , resultDisplay : ResultDisplay
    , searchFilters : Dict String String
    , searchGroupResults : List String
    , searchResultGroupAggs : Maybe GroupAggregations
    , searchResults : List (Result Http.Error SearchResult)
    , selectValues : Dict String String
    , showDropdownFilter : Bool
    , showDropdownFilterHint : Bool
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
    , dropdownFilterInput = ""
    , dropdownFilterSelectedIndex = 0
    , dropdownFilterState = SelectField
    , filteredFromValues = Dict.empty
    , filteredToValues = Dict.empty
    , filteredValues = Dict.empty
    , filterApCreatures = False
    , filterItemChildren = True
    , filterOperators = Dict.empty
    , filterSpoilers = False
    , fixedQueryString = fixedQueryString
    , groupField1 = "type"
    , groupField2 = Nothing
    , groupField3 = Nothing
    , groupedLinkLayout = Horizontal
    , lastSearchHash = Nothing
    , legacyMode = Nothing
    , loadingNew = False
    , query = ""
    , queryType = Standard
    , removeFilters = removeFilters
    , resultDisplay = Short
    , searchResultGroupAggs = Nothing
    , searchFilters = Dict.empty
    , searchGroupResults = []
    , searchResults = []
    , selectValues = Dict.empty
    , showDropdownFilter = False
    , showDropdownFilterHint = True
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
    , acScale : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedApocryphalSpell : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , anathemas : Maybe String
    , apocryphalSpell : Maybe String
    , archetype : Maybe String
    , area : Maybe String
    , areasOfConcern : Maybe String
    , areaTypes : List String
    , armorCategory : Maybe String
    , armorGroup : Maybe String
    , aspect : Maybe String
    , attackBonus : List Int
    , attackBonusScale : List Int
    , attackProficiencies : List String
    , attributeFlaws : List String
    , attributes : List String
    , baseItems : Maybe String
    , bloodlines : Maybe String
    , breadcrumbs : Maybe String
    , bulk : Maybe Float
    , bulkRaw : Maybe String
    , charisma : Maybe Int
    , charismaScale : Maybe Int
    , checkPenalty : Maybe Int
    , complexity : Maybe String
    , components : List String
    , constitution : Maybe Int
    , constitutionScale : Maybe Int
    , cost : Maybe String
    , creatureAbilities : List String
    , creatureFamily : Maybe String
    , creatureFamilyMarkdown : Maybe String
    , crew : Maybe String
    , damage : Maybe String
    , damageTypes : List String
    , defenseProficiencies : List String
    , deities : Maybe String
    , deitiesList : List String
    , deityCategory : Maybe String
    , dexCap : Maybe Int
    , dexterity : Maybe Int
    , dexterityScale : Maybe Int
    , divineFonts : List String
    , domains : Maybe String
    , domainsList : List String
    , domainsAlternate : Maybe String
    , domainsPrimary : Maybe String
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
    , fortitudeScale : Maybe Int
    , frequency : Maybe String
    , hands : Maybe String
    , hardness : Maybe String
    , hazardType : Maybe String
    , heighten : List String
    , heightenGroups : List String
    , heightenLevels : List Int
    , hp : Maybe String
    , hpScale : Maybe Int
    , iconImage : Maybe String
    , images : List String
    , immunities : Maybe String
    , intelligence : Maybe Int
    , intelligenceScale : Maybe Int
    , itemBonusAction : Maybe String
    , itemBonusConsumable : Maybe Bool
    , itemBonusNote : Maybe String
    , itemBonusValue : Maybe Int
    , itemCategory : Maybe String
    , itemHasChildren : Bool
    , itemSubcategory : Maybe String
    , languages : Maybe String
    , legacyIds : List String
    , lessonType : Maybe String
    , lessons : Maybe String
    , level : Maybe Int
    , markdown : Markdown
    , mysteries : Maybe String
    , onset : Maybe String
    , pantheons : List String
    , pantheonMarkdown : Maybe String
    , pantheonMembers : Maybe String
    , passengers : Maybe String
    , patronThemes : Maybe String
    , perception : Maybe Int
    , perceptionProficiency : Maybe String
    , perceptionScale : Maybe Int
    , pfs : Maybe String
    , pilotingCheck : Maybe String
    , planeCategory : Maybe String
    , prerequisites : Maybe String
    , price : Maybe String
    , primaryCheck : Maybe String
    , primarySourceCategory : Maybe String
    , primarySourceGroup : Maybe String
    , range : Maybe String
    , rangeValue : Maybe Int
    , rarity : Maybe String
    , rarityId : Maybe Int
    , ref : Maybe Int
    , reflexProficiency : Maybe String
    , reflexScale : Maybe Int
    , region : Maybe String
    , releaseDate : Maybe String
    , reload : Maybe String
    , remasterIds : List String
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
    , sourceCategories : List String
    , sourceGroups : List String
    , sourceList : List String
    , sources : Maybe String
    , space : Maybe String
    , speed : Maybe String
    , speedValues : Maybe SpeedTypeValues
    , speedPenalty : Maybe String
    , spell : Maybe String
    , spellList : Maybe String
    , spellAttackBonus : List Int
    , spellAttackBonusScale : List Int
    , spellDc : List Int
    , spellDcScale : List Int
    , spellType : Maybe String
    , spoilers : Maybe String
    , stages : Maybe String
    , strength : Maybe Int
    , strengthScale : Maybe Int
    , strikeDamageAverage : List Int
    , strikeDamageScale : List Int
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
    , willScale : Maybe Int
    , wisdom : Maybe Int
    , wisdomScale : Maybe Int
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
    , showQueryControls : Bool
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
    , showQueryControls = True
    , windowHeight = 0
    , windowWidth = 0
    }


type alias Aggregations =
    { itemSubcategories : List { category : String, name : String }
    , minmax : Dict String ( Float, Float )
    , values : Dict String (List String)
    }


type alias GlobalAggregations =
    { sources : List Source
    , traits : Dict String (List String)
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
    , group : Maybe String
    , name : String
    }


type Msg
    = AlwaysShowFiltersChanged Bool
    | AutoQueryTypeChanged Bool
    | CloseDropdownFilterHint
    | DateFormatChanged String
    | DebouncePassed Int
    | DeleteColumnConfigurationPressed
    | DropdownFilterFinalized DropdownFilterComplete
    | DropdownFilterInputChanged String
    | DropdownFilterOptionSelected DropdownFilterState
    | DropdownFilterToggled
    | ExportAsCsvPressed
    | ExportAsJsonPressed
    | GotAggregationsResult (Result Http.Error Aggregations)
    | GotBodySize Size
    | GotDocumentIndexResult (Result Http.Error (Dict String String))
    | GotDocuments Bool LegacyMode (List String) (Result Http.Error (List (Result String Document)))
    | GotGlobalAggregationsResult (Result Http.Error GlobalAggregations)
    | GotGroupAggregationsResult (Result Http.Error SearchResult)
    | GotGroupSearchResult (Result Http.Error SearchResult)
    | GotSearchResult Bool (Result Http.Error SearchResult)
    | FilterRemoved String String
    | FilterToggled String String
    | FilterApCreaturesChanged Bool
    | FilterItemChildrenChanged Bool
    | FilterOperatorChanged String Bool
    | FilterSpoilersChanged Bool
    | FilteredBothValuesChanged String String
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
    | KeyDown String
    | LegacyModeChanged (Maybe Bool)
    | LimitTableWidthChanged Bool
    | LinkEntered String Position
    | LinkEnteredDebouncePassed String LegacyMode
    | LinkLeft
    | LoadGroupPressed (List ( String, String ))
    | LoadMorePressed Int
    | LocalStorageValueReceived Decode.Value
    | MaskSourceGroupToggled String
    | NewRandomSeedPressed
    | NoOp
    | OpenInNewTabChanged Bool
    | PageSizeChanged Int
    | PageSizeDefaultsChanged String Int
    | PageWidthChanged Int
    | QueryChanged String
    | QueryFieldBlurred
    | QueryFieldFocused
    | QueryTypeSelected QueryType
    | RandomSeedGenerated Int
    | RemoveAllFiltersOfTypePressed String
    | RemoveAllRangeValueFiltersPressed
    | RemoveAllSortsPressed
    | ResetDefaultParamsPressed
    | ResultDisplayChanged ResultDisplay
    | SaveColumnConfigurationPressed
    | SaveDefaultParamsPressed
    | SavedColumnConfigurationNameChanged String
    | SavedColumnConfigurationSelected String
    | ScrollToTopPressed
    | SearchFilterChanged String String
    | SelectValueChanged String String
    | ShowAdditionalInfoChanged Bool
    | ShowFilters
    | ShowFilterBox String Bool
    | ShowLegacyFiltersChanged Bool
    | ShowQueryControlsPressed
    | ShowResultIndexChanged Bool
    | ShowShortPfsChanged Bool
    | ShowSpoilersChanged Bool
    | ShowSummaryChanged Bool
    | ShowTraitsChanged Bool
    | SortAdded String SortDir
    | SortOrderChanged Int Int
    | SortRemoved String
    | SortSetChosen (List ( String, SortDir ))
    | SortToggled String
    | TableColumnAdded String
    | TableColumnMoved Int Int
    | TableColumnRemoved String
    | TableColumnSetChosen (List String)
    | TraitGroupDeselectPressed (List String)
    | UrlChanged String
    | UrlRequested Browser.UrlRequest
    | WindowResized Int Int


type Markdown
    = Parsed ParsedMarkdownResult
    | ParsedWithUnflattenedChildren ParsedMarkdownResult
    | NotParsed String


type alias ParsedMarkdownResult =
    Result (List String) (List MB.Block)


type LegacyMode
    = LegacyMode
    | RemasterMode
    | NoRedirect


getLegacyMode : Model -> LegacyMode
getLegacyMode model =
    if Maybe.withDefault model.legacyMode model.searchModel.legacyMode then
        LegacyMode

    else
        RemasterMode


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


type DropdownFilterState
    = SelectField
    | SelectValueOperator String String
    | SelectValue String String DropdownFilterValueOperator
    | SelectNumericOperator String String
    | SelectNumericSubfield String String
    | SelectNumericValue String String Order
    | SelectSortDirection String String Bool


type DropdownFilterValueOperator
    = Is
    | IsAnd
    | IsOr
    | IsNot


type DropdownFilterComplete
    = Numeric String Order Float
    | Sort String SortDir
    | Value String DropdownFilterValueOperator String


allAttributes : List String
allAttributes =
    [ "strength"
    , "dexterity"
    , "constitution"
    , "intelligence"
    , "wisdom"
    , "charisma"
    ]


allAlignments : List ( String, String )
allAlignments =
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


castingComponents : List String
castingComponents =
    [ "focus"
    , "material"
    , "somatic"
    , "verbal"
    ]


fields : List ( String, String )
fields =
    [ ( "ability", "Alias for 'attribute'" )
    , ( "ability_boost", "Alias for 'attribute'" )
    , ( "ability_flaw", "Alias for 'attribute_flaw'" )
    , ( "ability_type", "Familiar ability type (Familiar / Master)" )
    , ( "ac", "[n] Armor class of an armor, creature, or shield" )
    , ( "ac_scale", "AC scale according to creature building rules" )
    , ( "access", "Access requirements" )
    , ( "actions", "Actions or time required to use an action or activity" )
    , ( "activate", "Activation requirements of an item" )
    , ( "advanced_domain_spell", "Advanced domain spell" )
    , ( "advanced_apocryphal_spell", "Advanced apocryphal domain spell" )
    , ( "alignment", "Alignment" )
    , ( "attack_bonus", "[n] Attack bonus for creatures" )
    , ( "attack_bonus_scale", "Attack bonus scale according to creature building rules" )
    , ( "ammunition", "Ammunition type used by a weapon" )
    , ( "anathema", "Deity anathemas" )
    , ( "apocryphal_spell", "Apocryphal domain spell" )
    , ( "archetype", "Archetypes associated with a feat" )
    , ( "archetype_category", "Archetype category" )
    , ( "area", "Area of a spell" )
    , ( "area_raw", "Area exactly as written" )
    , ( "area_type", "Area shape, e.g. burst or line" )
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
    , ( "charisma_scale", "Charisma scale according to creature building rules" )
    , ( "check_penalty", "[n] Armor check penalty" )
    , ( "cleric_spell", "Cleric spells granted by a deity" )
    , ( "complexity", "Hazard complexity" )
    , ( "component", "Spell casting components (Material / Somatic / Verbal)" )
    , ( "con", "[n] Alias for 'constitution'" )
    , ( "constitution", "[n] Constitution" )
    , ( "constitution_scale", "Constitution scale according to creature building rules" )
    , ( "cost", "Cost to use an action, ritual, or spell" )
    , ( "creature_ability", "Creature abilities" )
    , ( "creature_family", "Creature family" )
    , ( "crew", "Seige weapon / vehicle crew" )
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
    , ( "dexterity_scale", "Dexterity scale according to creature building rules" )
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
    , ( "fortitude_save_scale", "Fortitude save scale according to creatuer building rules" )
    , ( "frequency", "Frequency of which something can be used" )
    , ( "hands", "Hands required to use item" )
    , ( "hardness", "[n] Hazard or shield hardness" )
    , ( "hazard_type", "Hazard type trait" )
    , ( "heighten", "Spell heightens available" )
    , ( "heighten_level", "All levels a spell can be heightened to (including base level)" )
    , ( "hex_cantrip", "Witch patron theme hex cantrip" )
    , ( "home_plane", "Summoner eidolon home plane" )
    , ( "hp", "[n] Hit points" )
    , ( "hp_scale", "Hit points scale according creature building rules" )
    , ( "immunity", "Immunities" )
    , ( "int", "[n] Alias for 'intelligence'" )
    , ( "intelligence", "[n] Intelligence" )
    , ( "intelligence_scale", "Intelligence scale according to creature building rules" )
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
    , ( "passengers", "[n] Vehicle passengers" )
    , ( "passengers_raw", "Vehicle passengers as written" )
    , ( "patron_theme", "Witch patron themes associated with a spell" )
    , ( "per", "[n] Alias for 'perception'" )
    , ( "perception", "[n] Perception" )
    , ( "perception_proficiency", "A class's starting perception proficiency" )
    , ( "perception_scale", "Perception scale according to creature building rules" )
    , ( "pfs", "Pathfinder Society status (Standard / Limited / Restricted)" )
    , ( "piloting_check", "Piloting check for a vehicle" )
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
    , ( "reflex_save_scale", "Reflex save scale according to creature building rules" )
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
    , ( "space", "Siege weapon / vehicle space" )
    , ( "speed.<type>", "[n] Speed of <type>. Valid types are burrow, climb, fly, land, and swim. Use speed.\\* to match any type." )
    , ( "speed_raw", "Speed exactly as written" )
    , ( "speed_penalty", "Speed penalty of armor or shield" )
    , ( "spell", "Related spells" )
    , ( "spell_attack_bonus", "[n] Spell attack bonus for creatures" )
    , ( "spell_attack_bonus_scale", "Spell attack bonus scale according to creature building rules" )
    , ( "spell_dc", "[n] Spell DC for creatures" )
    , ( "spell_dc_scale", "Spell DC scale according to creature building rules" )
    , ( "spell_type", "Spell type ( Spell / Cantrip / Focus )" )
    , ( "spoilers", "Adventure path name if there is a spoiler warning on the page" )
    , ( "stage", "Stages of a disease or poison" )
    , ( "stealth", "Hazard stealth" )
    , ( "str", "[n] Alias for 'strength'" )
    , ( "strength", "[n] Creature strength or armor strength requirement" )
    , ( "strength_scale", "Strength scale according to creature building rules" )
    , ( "strike_damage_average", "Average strike damage for creatures" )
    , ( "strike_damage_scale", "Strike damage scale according to creature building rules" )
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
    , ( "will_save_scale", "Will save scale according to creature building rules" )
    , ( "wis", "[n] Alias for 'wisdom'" )
    , ( "wisdom", "[n] Wisdom" )
    , ( "wisdom_scale", "Wisdom scale according to creature building rules" )
    ]


type alias FilterField =
    { field : String
    , key : String
    , useOperator : Bool
    , values : List String -> List String
    }


filterFields : List FilterField
filterFields =
    [ { field = "ac_scale"
      , key = "ac-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "actions.keyword"
      , key = "actions"
      , useOperator = False
      , values = List.sortBy actionsToInt
      }
    , { field = "alignment"
      , key = "alignments"
      , useOperator = False
      , values =
            List.filter (\a -> List.member a (List.map Tuple.first allAlignments))
                >> List.sort
      }
    , { field = "area_type"
      , key = "area-types"
      , useOperator = False
      , values = List.sort
      }
    , { field = "armor_category"
      , key = "armor-categories"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit armorCategories)
      }
    , { field = "armor_group"
      , key = "armor-groups"
      , useOperator = False
      , values = List.sort
      }
    , { field = "attack_bonus_scale"
      , key = "attack-bonus-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "attribute"
      , key = "attributes"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit allAttributes)
      }
    , { field = "charisma_scale"
      , key = "charisma-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "component"
      , key = "components"
      , useOperator = True
      , values = List.sort
      }
    , { field = "complexity"
      , key = "complexities"
      , useOperator = False
      , values = List.sort
      }
    , { field = "constitution_scale"
      , key = "constitution-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "creature_family.keyword"
      , key = "creature-families"
      , useOperator = False
      , values = List.sort
      }
    , { field = "damage_type"
      , key = "damage-types"
      , useOperator = True
      , values = List.sort
      }
    , { field = "dexterity_scale"
      , key = "dexterity-scales"
      , useOperator = False
      , values = List.sort
      }
    , { field = "deity.keyword"
      , key = "deities"
      , useOperator = True
      , values = List.sort
      }
    , { field = "deity_category.keyword"
      , key = "deity-categories"
      , useOperator = False
      , values = List.sort
      }
    , { field = "divine_font"
      , key = "divine-fonts"
      , useOperator = True
      , values = List.sort
      }
    , { field = "domain"
      , key = "domains"
      , useOperator = True
      , values = List.sort
      }
    , { field = "favored_weapon.keyword"
      , key = "favored-weapons"
      , useOperator = False
      , values = List.sort
      }
    , { field = "fortitude_save_scale"
      , key = "fortitude-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "hands.keyword"
      , key = "hands"
      , useOperator = False
      , values = List.sort
      }
    , { field = "hazard_type"
      , key = "hazard-types"
      , useOperator = False
      , values = List.sort
      }
    , { field = "pantheon.keyword"
      , key = "pantheons"
      , useOperator = False
      , values = List.sort
      }
    , { field = "hp_scale"
      , key = "hp-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "intelligence_scale"
      , key = "intelligence-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "item_bonus_action.keyword"
      , key = "item-bonus-actions"
      , useOperator = False
      , values = List.sort
      }
    , { field = "item_bonus_consumable"
      , key = "item-bonus-consumable"
      , useOperator = False
      , values = List.sort >> List.reverse
      }
    , { field = "item_category.keyword"
      , key = "item-categories"
      , useOperator = False
      , values = List.sort
      }
    , { field = "item_subcategory.keyword"
      , key = "item-subcategories"
      , useOperator = False
      , values = List.sort
      }
    , { field = "perception_scale"
      , key = "perception-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "pfs"
      , key = "pfs"
      , useOperator = False
      , values = (::) "none"
      }
    , { field = "rarity"
      , key = "rarities"
      , useOperator = False
      , values = identity
      }
    , { field = "reflex_save_scale"
      , key = "reflex-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "region"
      , key = "regions"
      , useOperator = False
      , values = List.sort
      }
    , { field = "reload_raw.keyword"
      , key = "reloads"
      , useOperator = False
      , values = List.sort
      }
    , { field = "sanctification"
      , key = "sanctifications"
      , useOperator = True
      , values = List.sort
      }
    , { field = "saving_throw"
      , key = "saving-throws"
      , useOperator = False
      , values =
            List.concatMap explodeSaves
                >> List.Extra.unique
                >> List.sort
      }
    , { field = "school"
      , key = "schools"
      , useOperator = False
      , values = List.sort
      }
    , { field = "size"
      , key = "sizes"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit allSizes)
      }
    , { field = "skill.keyword"
      , key = "skills"
      , useOperator = True
      , values =
            List.filter (\skill -> List.member skill allSkills)
                >> List.sort
      }
    , { field = "skill.keyword"
      , key = "lore-skills"
      , useOperator = True
      , values =
            List.filter (String.endsWith "lore")
                >> List.filter ((/=) "lore")
                >> List.sort
      }
    , { field = "source.keyword"
      , key = "sources"
      , useOperator = False
      , values = List.sort
      }
    , { field = "source_category"
      , key = "source-categories"
      , useOperator = False
      , values = List.sort
      }
    , { field = "source_group.keyword"
      , key = "source-groups"
      , useOperator = False
      , values = List.sort
      }
    , { field = "spell.keyword"
      , key = "spells"
      , useOperator = True
      , values = List.sort
      }
    , { field = "spell_attack_bonus_scale"
      , key = "spell-attack-bonus-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "spell_dc_scale"
      , key = "spell-dc-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "strength_scale"
      , key = "strength-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "strike_damage_scale"
      , key = "strike-damage-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "strongest_save"
      , key = "strongest-saves"
      , useOperator = False
      , values =
            List.filter (\s -> List.Extra.notMember s [ "fort", "ref" ])
                >> List.sort
      }
    , { field = "tradition"
      , key = "traditions"
      , useOperator = True
      , values = List.sort
      }
    , { field = "trait"
      , key = "traits"
      , useOperator = True
      , values = List.sort
      }
    , { field = "trait_group"
      , key = "trait-groups"
      , useOperator = True
      , values =
            List.filter (\group -> List.Extra.notMember group [ "half-elf", "half-orc", "aon-special", "settlement" ])
                >> List.sort
      }
    , { field = "type"
      , key = "types"
      , useOperator = False
      , values = List.sort
      }
    , { field = "warden_spell_tier"
      , key = "warden-spell-tiers"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit wardenSpellTiers)
      }
    -- , { field = "vision.keyword"
    --   , key = "visions"
    --   , useOperator = False
    --   , values = List.sort
    --   }
    , { field = "weakest_save"
      , key = "weakest-saves"
      , useOperator = False
      , values =
            List.filter (\s -> List.Extra.notMember s [ "fort", "ref" ])
                >> List.sort
      }
    , { field = "weapon_category"
      , key = "weapon-categories"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit weaponCategories)
      }
    , { field = "weapon_group"
      , key = "weapon-groups"
      , useOperator = False
      , values = List.sort
      }
    , { field = "weapon_type"
      , key = "weapon-types"
      , useOperator = False
      , values = List.sort
      }
    , { field = "will_save_scale"
      , key = "will-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    , { field = "wisdom_scale"
      , key = "wisdom-scales"
      , useOperator = False
      , values = List.sortWith (Order.Extra.explicit scales)
      }
    ]


numericFields : List String
numericFields =
    [ "ac"
    , "area"
    , "attack_bonus"
    , "bulk"
    , "charisma"
    , "check_penalty"
    , "constitution"
    , "damage_die"
    , "dexterity"
    , "dex_cap"
    , "duration"
    , "fortitude_save"
    , "hardness"
    , "hp"
    , "level"
    , "rank"
    , "item_bonus_value"
    , "intelligence"
    , "onset"
    , "passengers"
    , "perception"
    , "price"
    , "range"
    , "reflex_save"
    , "required_abilities"
    , "resistance"
    , "secondary_casters"
    , "skill_mod"
    , "speed"
    , "spell_attack_bonus"
    , "spell_dc"
    , "strength"
    , "weakness"
    , "will_save"
    , "wisdom"
    ]


numericFieldsWithSubfields : List String
numericFieldsWithSubfields =
    [ "resistance"
    , "skill_mod"
    , "speed"
    , "weakness"
    ]


mapNumericFields : String -> List String
mapNumericFields field =
    case field of
        "resistance" ->
            List.map
                ((++) "resistance.")
                allDamageTypes

        "skill_mod" ->
            List.map
                ((++) "skill_mod.")
                allSkills

        "speed" ->
            List.map
                ((++) "speed.")
                speedTypes

        "weakness" ->
            List.map
                ((++) "weakness.")
                allDamageTypes

        _ ->
            [ field ]


dropdownFilterFields : Model -> SearchModel -> List { label : String, key : String, onSelect : Msg }
dropdownFilterFields model searchModel =
    availableDropdownFilterFields model searchModel
        |> List.filter
            (\field ->
                caseInsensitiveContains
                    searchModel.dropdownFilterInput
                    field.label
            )


availableDropdownFilterFields : Model -> SearchModel -> List { label : String, key : String, onSelect : Msg }
availableDropdownFilterFields model searchModel =
    let
        toLabel : String -> String
        toLabel field =
            field
                |> String.replace "_raw" ""
                |> String.replace ".keyword" ""
                |> String.Extra.humanize
                |> toTitleCase
    in
    case searchModel.dropdownFilterState of
        SelectField ->
            -- TODO: Legacy / Remaster toggle?
            List.append
                (filterFields
                    |> List.filter
                        (\field ->
                            (getAggregationValues field.field searchModel
                                |> field.values
                                |> List.length
                                |> (<=) 2
                            )
                        )
                    |> List.map
                        (\field ->
                            let
                                label : String
                                label =
                                    if field.key == "lore-skills" then
                                        "Lore Skills"

                                    else
                                        toLabel field.field
                            in
                            { label = label
                            , key = field.key
                            , onSelect =
                                DropdownFilterOptionSelected
                                    (SelectValueOperator
                                        field.key
                                        label
                                    )
                            }
                        )
                    |> List.filter
                        (\field ->
                            (List.Extra.notMember field.key [ "alignments", "components", "schools" ])
                                || model.showLegacyFilters
                        )
                )
                (List.filterMap
                    (\field ->
                        if List.member field numericFieldsWithSubfields then
                            if hasMinmaxAggregationForSubfield field searchModel then
                                { label = toLabel field
                                , key = field
                                , onSelect =
                                    DropdownFilterOptionSelected
                                        (SelectNumericSubfield
                                            field
                                            (toLabel field)
                                        )
                                }
                                    |> Just

                            else
                                Nothing

                        else
                            case getAggregationMinmax field searchModel of
                                Just ( min, max ) ->
                                    if min == max then
                                        Nothing

                                    else
                                        { label = toLabel field
                                        , key = field
                                        , onSelect =
                                            DropdownFilterOptionSelected
                                                (SelectNumericOperator
                                                    field
                                                    (toLabel field)
                                                )
                                        }
                                            |> Just

                                Nothing ->
                                    Nothing
                    )
                    numericFields
                )
                    |> List.sortBy .label

        SelectNumericOperator field label ->
            List.append
                [ { label = "is exactly"
                  , key = "=="
                  , onSelect = DropdownFilterOptionSelected (SelectNumericValue field label EQ)
                  }
                , { label = "is at least"
                  , key = "<="
                  , onSelect = DropdownFilterOptionSelected (SelectNumericValue field label GT)
                  }
                , { label = "is at most"
                  , key = ">="
                  , onSelect = DropdownFilterOptionSelected (SelectNumericValue field label LT)
                  }
                ]
                (if List.any (Tuple3.first >> (==) field) sortFields
                    || List.member field numericFieldsWithSubfields
                 then
                    [ { label = "sort by"
                      , key = "sort"
                      , onSelect = DropdownFilterOptionSelected (SelectSortDirection field label True)
                      }
                    ]

                 else
                    []
                )

        SelectNumericSubfield field label ->
            (if field == "resistance" || field == "weakness" then
                allDamageTypes

             else if field == "skill_mod" then
                allSkills

             else if field == "speed" then
                speedTypes

             else
                []
            )
                |> List.filter
                    (\t ->
                        getAggregationMinmax (field ++ "." ++ t) searchModel
                            |> Maybe.Extra.isJust
                    )
                |> List.map
                    (\damageType ->
                        { label = toLabel damageType
                        , key = damageType
                        , onSelect =
                            DropdownFilterOptionSelected
                                (SelectNumericOperator
                                    (field ++ "." ++ damageType)
                                    (toLabel damageType ++ " " ++ label)
                                )
                        }
                    )

        SelectNumericValue field label operator ->
            case String.toFloat searchModel.dropdownFilterInput of
                Just value ->
                    [ { label = String.fromFloat value
                      , key = "value"
                      , onSelect = DropdownFilterFinalized (Numeric field operator value)
                      }
                    ]

                Nothing ->
                    []

        SelectValueOperator key label ->
            let
                useOperator : Bool
                useOperator =
                    filterFields
                        |> List.Extra.find (.key >> (==) key)
                        |> Maybe.map .useOperator
                        |> Maybe.withDefault False

                field : String
                field =
                    filterFields
                        |> List.Extra.find (.key >> (==) key)
                        |> Maybe.map .field
                        |> Maybe.withDefault ""
            in
            List.concat
                [ if List.isEmpty (boolDictIncluded key searchModel.filteredValues) then
                    [ { label = "is"
                      , key = "is"
                      , onSelect = DropdownFilterOptionSelected (SelectValue key label Is)
                      }
                    ]

                  else if useOperator then
                    [ { label = "is"
                      , key = "and"
                      , onSelect = DropdownFilterOptionSelected (SelectValue key label IsAnd)
                      }
                    , { label = "is any"
                      , key = "or"
                      , onSelect = DropdownFilterOptionSelected (SelectValue key label IsOr)
                      }
                    ]

                  else
                    [ { label = "is"
                      , key = "or"
                      , onSelect = DropdownFilterOptionSelected (SelectValue key label IsOr)
                      }
                    ]

                , [ { label = "is not"
                    , key = "not"
                    , onSelect = DropdownFilterOptionSelected (SelectValue key label IsNot)
                    }
                  ]

                , if List.any (Tuple3.first >> (==) field) sortFields then
                    [ { label = "sort by"
                      , key = "sort"
                      , onSelect = DropdownFilterOptionSelected (SelectSortDirection field label False)
                      }
                    ]

                  else
                    []

                ]

        SelectSortDirection field label isNumeric ->
            [ { label = "asc"
              , key = "asc"
              , onSelect = DropdownFilterFinalized (Sort field Asc)
              }
            , { label = "desc"
              , key = "desc"
              , onSelect = DropdownFilterFinalized (Sort field Desc)
              }
            ]

        SelectValue key _ operator ->
            case List.Extra.find (.key >> (==) key) filterFields of
                Just fieldSpec ->
                    List.map
                        (\value ->
                            { label = toTitleCase value
                            , key = value
                            , onSelect = DropdownFilterFinalized (Value key operator value)
                            }
                        )
                        (getAggregationValues fieldSpec.field searchModel
                            |> fieldSpec.values
                        )

                Nothing ->
                    []


groupFields : List String
groupFields =
    [ "ac"
    , "ac_scale"
    , "actions"
    , "alignment"
    , "area_type"
    , "armor_category"
    , "armor_group"
    , "attack_bonus_scale"
    , "attribute"
    , "bulk"
    , "charisma_scale"
    , "constitution_scale"
    , "creature_family"
    , "damage_type"
    , "deity"
    , "deity_category"
    , "dexterity_scale"
    , "domain"
    , "duration"
    , "element"
    , "fortitude_scale"
    , "hands"
    , "heighten_group"
    , "hp_scale"
    , "intelligence_scale"
    , "item_category"
    , "item_subcategory"
    , "level"
    , "pantheon"
    , "perception_scale"
    , "pfs"
    , "range"
    , "rank"
    , "rarity"
    , "reflex_scale"
    , "sanctification"
    , "school"
    , "size"
    , "source"
    , "source_category"
    , "source_group"
    , "spell_attack_bonus_scale"
    , "spell_dc_scale"
    , "spell_type"
    , "strength_scale"
    , "strike_damage_scale"
    , "tradition"
    , "trait"
    , "type"
    , "warden_spell_tier"
    , "weapon_category"
    , "weapon_group"
    , "weapon_type"
    , "will_scale"
    , "wisdom_scale"
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
    , { columns = [ "armor_category", "ac", "dex_cap", "check_penalty", "speed_penalty", "strength", "bulk", "armor_group", "trait" ]
      , label = "Armor"
      }
    , { columns = [ "pfs", "ability", "skill", "feat", "rarity", "source" ]
      , label = "Backgrounds"
      }
    , { columns = [ "ability", "hp", "attack_proficiency", "defense_proficiency", "fortitude_proficiency", "reflex_proficiency",  "will_proficiency", "perception_proficiency", "skill_proficiency", "rarity", "pfs" ]
      , label = "Classes"
      }
    , { columns = [ "level", "creature_family", "rarity", "size", "trait", "hp", "ac", "fortitude", "reflex", "will", "speed", "immunity", "resistance", "weakness" ]
      , label = "Creatures"
      }
    , { columns =
        [ "level", "creature_family", "source", "rarity", "size", "trait"
        , "hp", "hp_scale", "ac", "ac_scale", "fortitude", "fortitude_scale", "reflex", "reflex_scale", "will", "will_scale"
        , "immunity", "resistance", "weakness", "creature_ability"
        , "perception", "perception_scale", "sense", "speed"
        , "attack_bonus", "attack_bonus_scale", "strike_damage_average", "strike_damage_scale"
        , "spell_attack", "spell_attack_scale", "spell_dc", "spell_dc_scale", "spell", "language"
        , "strength", "strength_scale", "dexterity", "dexterity_scale", "constitution", "constitution_scale"
        , "intelligence", "intelligence_scale", "wisdom", "wisdom_scale", "charisma", "charisma_scale", "skill"
        ]
      , label = "Creatures (extended)"
      }
    , { columns = [ "pfs", "area_of_concern", "edict", "anathema", "domain_primary", "domain_alternate", "divine_font", "sanctification", "attribute", "skill", "favored_weapon", "deity_category", "pantheon", "source" ]
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
    , { columns = [ "source", "pfs", "summary", "size", "trait", "level", "price", "usage", "space", "crew", "speed", "ac", "fortitude", "reflex", "hardness", "hp" ]
      , label = "Siege Weapons"
      }
    , { columns = [ "spell_type", "rank", "heighten", "tradition", "school", "trait", "actions", "component", "trigger", "target", "range", "area", "duration", "defense", "rarity", "pfs" ]
      , label = "Spells"
      }
    , { columns = [ "source", "pfs", "size", "trait", "level", "price", "space", "crew", "passengers", "piloting_check", "speed", "ac", "fortitude", "hardness", "hp", "immunity", "resistance", "weakness" ]
      , label = "Vehicles"
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
    [ "ac"
    , "fortitude"
    , "reflex"
    , "will"
    ]


explodeSaves : String -> List String
explodeSaves string =
    List.filterMap
        (\save ->
            if String.contains save (String.toLower string) then
                Just save

            else
                Nothing
        )
        saves


scales : List String
scales =
    [ "terrible"
    , "low"
    , "moderate"
    , "high"
    , "extreme"
    , "undefined"
    ]


settlementSizes : List String
settlementSizes =
    [ "city"
    , "metropolis"
    , "town"
    , "village"
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
    , ( "ac_scale", "ac_scale_number", True )
    , ( "actions", "actions_number", True )
    , ( "alignment", "alignment", False )
    , ( "archetype", "archetype.keyword", False )
    , ( "area", "area", False )
    , ( "area_type", "area_type", False )
    , ( "armor_category", "armor_category", False )
    , ( "armor_group", "armor_group", False )
    , ( "aspect", "aspect", False )
    , ( "attack_bonus", "attack_bonus", True )
    , ( "attack_bonus_scale", "attack_bonus_scale_number", True )
    , ( "attribute", "attribute", False )
    , ( "base_item", "base_item.keyword", False )
    , ( "bloodline", "bloodline", False )
    , ( "bulk", "bulk", True )
    , ( "charisma", "charisma", True )
    , ( "charisma_scale", "charisma_scale_number", True )
    , ( "check_penalty", "check_penalty", True )
    , ( "complexity", "complexity", False )
    , ( "component", "component", False )
    , ( "constitution", "constitution", True )
    , ( "constitution_scale", "constitution_scale_number", True )
    , ( "cost", "cost.keyword", False )
    , ( "creature_family", "creature_family.keyword", False )
    , ( "damage", "damage_die", True )
    , ( "damage_type", "damage_type", False )
    , ( "deity", "deity.keyword", False )
    , ( "deity_category", "deity_category.keyword", False )
    , ( "deity_category_order", "deity_category_order", False )
    , ( "dex_cap", "dex_cap", True )
    , ( "dexterity", "dexterity", True )
    , ( "dexterity_scale", "dexterity_scale_number", True )
    , ( "divine_font", "divine_font", False )
    , ( "domain", "domain", False )
    , ( "domain_alternate", "domain_alternate", False )
    , ( "domain_primary", "domain_primary", False )
    , ( "duration", "duration", True )
    , ( "favored_weapon", "favored_weapon.keyword", False )
    , ( "fortitude", "fortitude", False )
    , ( "fortitude_proficiency", "fortitude_proficiency", False )
    , ( "fortitude_scale", "fortitude_save_scale_number", True )
    , ( "frequency", "frequency.keyword", False )
    , ( "hands", "hands.keyword", False )
    , ( "hardness", "hardness", False )
    , ( "hazard_type", "hazard_type", False )
    , ( "heighten", "heighten", False )
    , ( "hp", "hp", True )
    , ( "hp_scale", "hp_scale_number", True )
    , ( "intelligence", "intelligence", False )
    , ( "intelligence_scale", "intelligence_scale_number", True )
    , ( "item_bonus_action", "item_bonus_action.keyword", False )
    , ( "item_bonus_consumable", "item_bonus_consumable", False )
    , ( "item_bonus_value", "item_bonus_value", False )
    , ( "item_category", "item_category.keyword", False )
    , ( "item_subcategory", "item_subcategory.keyword", False )
    , ( "level", "level", True )
    , ( "mystery", "mystery", False )
    , ( "name", "name.keyword", False )
    , ( "onset", "onset", True )
    , ( "pantheon", "pantheon.keyword", False )
    , ( "passengers", "passengers", True )
    , ( "patron_theme", "patron_theme", False )
    , ( "perception", "perception", True )
    , ( "perception_proficiency", "perception_proficiency", False )
    , ( "perception_scale", "perception_scale_number", True )
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
    , ( "reflex_scale", "reflex_save_scale_number", True )
    , ( "region", "region", False )
    , ( "release_date", "release_date", False )
    , ( "requirement", "requirement.keyword", False )
    , ( "sanctification", "sanctification_raw.keyword", False )
    , ( "saving_throw", "saving_throw.keyword", False )
    , ( "school", "school", False )
    , ( "secondary_casters", "secondary_casters", False )
    , ( "secondary_check", "secondary_check.keyword", False )
    , ( "siege_weapon_category", "siege_weapon_category", False )
    , ( "size", "size_id", True )
    , ( "skill", "skill.keyword", True )
    , ( "source", "source.keyword", False )
    , ( "source_category", "primary_source_category", False )
    , ( "source_group", "primary_source_group.keyword", False )
    , ( "speed_penalty", "speed_penalty.keyword", False )
    , ( "spell_attack_bonus", "spell_attack_bonus", True )
    , ( "spell_attack_bonus_scale", "spell_attack_bonus_scale_number", True )
    , ( "spell_dc", "spell_dc", True )
    , ( "spell_dc_scale", "spell_dc_scale_number", True )
    , ( "spell_type", "spell_type", False )
    , ( "spoilers", "spoilers", False )
    , ( "strength", "strength", True )
    , ( "strength_scale", "strength_scale_number", True )
    , ( "strength_req", "strength", True )
    , ( "strike_damage_average", "strike_damage_average", True )
    , ( "strike_damage_scale", "strike_damage_scale_number", True )
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
    , ( "will_scale", "will_save_scale_number", True )
    , ( "wisdom", "wisdom", True )
    , ( "wisdom_scale", "wisdom_scale_number", True )
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


allSourceCategories : List String
allSourceCategories =
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
    , "ac_scale"
    , "actions"
    , "advanced_apocryphal_spell"
    , "advanced_domain_spell"
    , "alignment"
    , "apocryphal_spell"
    , "archetype"
    , "area"
    , "area_type"
    , "armor_category"
    , "armor_group"
    , "aspect"
    , "attack_bonus"
    , "attack_bonus_scale"
    , "attack_proficiency"
    , "attribute"
    , "attribute_boost"
    , "attribute_flaw"
    , "base_item"
    , "bloodline"
    , "bulk"
    , "charisma"
    , "charisma_scale"
    , "check_penalty"
    , "complexity"
    , "component"
    , "constitution"
    , "constitution_scale"
    , "cost"
    , "creature_ability"
    , "creature_family"
    , "crew"
    , "damage"
    , "damage_type"
    , "defense"
    , "defense_proficiency"
    , "deity"
    , "deity_category"
    , "dex_cap"
    , "dexterity"
    , "dexterity_scale"
    , "divine_font"
    , "domain"
    , "domain_alternate"
    , "domain_primary"
    , "domain_spell"
    , "duration"
    , "element"
    , "favored_weapon"
    , "feat"
    , "follower_alignment"
    , "fortitude"
    , "fortitude_scale"
    , "frequency"
    , "hands"
    , "hardness"
    , "hazard_type"
    , "heighten"
    , "heighten_level"
    , "hp"
    , "hp_scale"
    , "icon_image"
    , "image"
    , "immunity"
    , "intelligence"
    , "intelligence_scale"
    , "item_bonus_action"
    , "item_bonus_consumable"
    , "item_bonus_note"
    , "item_bonus_value"
    , "item_category"
    , "item_subcategory"
    , "language"
    , "lesson"
    , "level"
    , "mystery"
    , "onset"
    , "passengers"
    , "pantheon"
    , "pantheon_member"
    , "patron_theme"
    , "perception"
    , "perception_proficiency"
    , "perception_scale"
    , "pfs"
    , "plane_category"
    , "prerequisite"
    , "price"
    , "primary_check"
    , "range"
    , "rank"
    , "rarity"
    , "reflex"
    , "reflex_scale"
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
    , "space"
    , "speed"
    , "speed_penalty"
    , "spell"
    , "spell_attack_bonus"
    , "spell_attack_bonus_scale"
    , "spell_dc"
    , "spell_dc_scale"
    , "spell_type"
    , "spoilers"
    , "stage"
    , "strength"
    , "strength_req"
    , "strength_scale"
    , "strike_damage_average"
    , "strike_damage_scale"
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
    , "will_scale"
    , "wisdom"
    , "wisdom_scale"
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


wardenSpellTiers : List String
wardenSpellTiers =
    [ "initiate"
    , "advanced"
    , "master"
    , "peerless"
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
        , filterApCreatures = Dict.get "ap-creatures" params == Just [ "hide" ]
        , filterItemChildren = Dict.get "item-children" params /= Just [ "parent" ]
        , filterSpoilers = Dict.get "spoilers" params == Just [ "hide" ]
        , filterOperators =
            List.map
                (\filter ->
                    ( filter.key
                    , Dict.get (filter.key ++ "-operator") params /= Just [ "or" ]
                    )
                )
                (filterFields
                    |> List.filter .useOperator
                )
                |> Dict.fromList
        , filteredValues =
            List.map
                (\{ key } ->
                    ( key
                    , getBoolDictFromParams params key
                        |> if key == "attributes" then
                            Dict.union (getBoolDictFromParams params "abilities")

                           else
                            identity
                    )
                )
                filterFields
                |> Dict.fromList
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
            if String.contains " " s || String.contains "+" s then
                "\"" ++ s ++ "\""

            else
                s

        surroundWithParantheses : Dict String Bool -> Dict String Bool -> String -> String
        surroundWithParantheses dict excluded s =
            if Dict.size dict > 1 || Dict.size excluded /= 0 then
                "(" ++ s ++ ")"

            else
                s
    in
    [ filterFields
        |> List.filterMap
            (\filter ->
                let
                    dict : Dict String Bool
                    dict =
                        Dict.get filter.key searchModel.filteredValues
                            |> Maybe.withDefault Dict.empty

                    ( included, excluded ) =
                        Dict.get filter.key searchModel.filteredValues
                            |> Maybe.withDefault Dict.empty
                            |> Dict.partition (\_ v -> v)

                    isAnd : Bool
                    isAnd =
                        Dict.get filter.key searchModel.filterOperators
                            |> Maybe.withDefault False
                in
                if Dict.isEmpty dict then
                    Nothing

                else
                    [ Dict.keys included
                        |> List.map surroundWithQuotes
                        |> String.join (if isAnd then " AND " else " OR ")
                    , Dict.keys excluded
                        |> List.map surroundWithQuotes
                        |> List.map (String.append "-")
                        |> String.join " "
                    ]
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "
                        |> surroundWithParantheses dict excluded
                        |> String.append ":"
                        |> String.append (String.replace ".keyword" "" filter.field)
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
    , if searchModel.filterItemChildren then
        []

      else
        [ "!item_parent_id:*" ]
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
    stringContainsChar query ":()\"+-*?/~"
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
        |> String.replace " A " " a "
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
        |> String.replace " Dc" " DC"
        |> String.replace "Ac " "AC "
        |> replaceString "Ac" "AC"
        |> String.replace "Hp " "HP "
        |> replaceString "Hp" "HP"
        |> String.replace "Gm " "GM "


replaceString : String -> String -> String -> String
replaceString search replacement input =
    if input == search then
        replacement

    else
        input


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


dictGetString : comparable -> Dict comparable String -> String
dictGetString key dict =
    Dict.get key dict
        |> Maybe.withDefault ""


nestedDictGet : comparable -> comparable -> Dict comparable (Dict comparable a) -> Maybe a
nestedDictGet key1 key2 dict =
    Dict.get key1 dict
        |> Maybe.withDefault Dict.empty
        |> Dict.get key2


nestedDictFilter :
    comparable
    -> (comparable -> v -> Bool)
    -> Dict comparable (Dict comparable v)
    -> Dict comparable (Dict comparable v)
nestedDictFilter key fun dict =
    Dict.update
        key
        (Maybe.map (Dict.filter fun))
        dict


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


boolDictIncluded : comparable -> Dict comparable (Dict comparable Bool) -> List comparable
boolDictIncluded key dict =
    Dict.get key dict
        |> Maybe.withDefault Dict.empty
        |> Dict.filter (\_ v -> v)
        |> Dict.keys


boolDictExcluded : comparable -> Dict comparable (Dict comparable Bool) -> List comparable
boolDictExcluded key dict =
    Dict.get key dict
        |> Maybe.withDefault Dict.empty
        |> Dict.filter (\_ v -> not v)
        |> Dict.keys


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
        |> toTitleCase


sortFieldSuffix : String -> String
sortFieldSuffix field =
    case field of
        "price" -> "cp"
        "range" -> "ft."
        _ -> ""


sortIsRandom : SearchModel -> Bool
sortIsRandom searchModel =
    searchModel.sort == [ ( "random", Asc ) ]


getAggregationMaybe : (Aggregations -> List a) -> SearchModel -> Maybe (List a)
getAggregationMaybe fun searchModel =
    searchModel.aggregations
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map fun


getAggregation : (Aggregations -> List a) -> SearchModel -> List a
getAggregation fun searchModel =
    getAggregationMaybe fun searchModel
        |> Maybe.withDefault []


getAggregationValues : String -> SearchModel -> List String
getAggregationValues key searchModel =
    searchModel.aggregations
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map .values
        |> Maybe.andThen (Dict.get (String.replace ".keyword" "" key))
        |> Maybe.withDefault []


moreThanOneValueAggregation : String -> SearchModel -> Bool
moreThanOneValueAggregation key searchModel =
    getAggregationValues key searchModel
        |> List.length
        |> (<) 1


moreThanOneAggregation : (Aggregations -> List a) -> SearchModel -> Bool
moreThanOneAggregation fun searchModel =
    getAggregation fun searchModel
        |> List.length
        |> (<) 1


getAggregationMinmax : String -> SearchModel -> Maybe ( Float, Float )
getAggregationMinmax field searchModel =
    searchModel.aggregations
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map .minmax
        |> Maybe.andThen (Dict.get field)


hasMultipleMinmaxValues : String -> SearchModel -> Bool
hasMultipleMinmaxValues field searchModel =
    getAggregationMinmax field searchModel
        |> Maybe.map (\( min, max ) -> min < max)
        |> Maybe.withDefault False


hasMinmaxAggregationForSubfield : String -> SearchModel -> Bool
hasMinmaxAggregationForSubfield field searchModel =
    searchModel.aggregations
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map .minmax
        |> Maybe.map Dict.keys
        |> Maybe.withDefault []
        |> List.any (String.startsWith (field ++ "."))


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


caseInsensitiveContains : String -> String -> Bool
caseInsensitiveContains needle haystack =
    String.contains (String.toLower needle) (String.toLower haystack)


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


scaleToString : Int -> String
scaleToString scale =
    case scale of
        5 -> "Extreme"
        4 -> "High"
        3 -> "Moderate"
        2 -> "Low"
        1 -> "Terrible"
        _ -> "Undefined"


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
    LegacyMode
    -> Dict String (Result Http.Error Document)
    -> Int
    -> Maybe String
    -> List MB.Block
    -> ( Bool, List MB.Block )
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
    LegacyMode
    -> Dict String (Result Http.Error Document)
    -> Int
    -> Maybe String
    -> MB.Block
    -> ( Bool, MB.Block )
flattenMarkdownBlock legacyMode documents parentLevel overrideTitleRight block =
    case block of
        MB.HtmlBlock (MB.HtmlElement "title" attributes children) ->
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
            , MB.HtmlElement
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
                |> MB.HtmlBlock
            )

        MB.HtmlBlock (MB.HtmlElement "document" attributes _) ->
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
                            case ( legacyMode, doc.legacyIds, doc.remasterIds ) of
                                ( LegacyMode, "0" :: _, _ ) ->
                                    documentId

                                ( LegacyMode, legacyId :: _, _ ) ->
                                    legacyId

                                ( LegacyMode, [], _ ) ->
                                    documentId

                                ( RemasterMode, _, "0" :: _ ) ->
                                    documentId

                                ( RemasterMode, _, remasterId :: _ ) ->
                                    remasterId

                                ( RemasterMode, _, [] ) ->
                                    documentId

                                ( NoRedirect, _, _ ) ->
                                    documentId

                        _ ->
                            documentId

                document : Maybe Document
                document =
                    Dict.get idToWorkWith documents
                        |> Maybe.andThen Result.toMaybe

                documentBlocks : Maybe (List MB.Block)
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
                    , MB.HtmlBlock
                        (MB.HtmlElement
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

        MB.HtmlBlock (MB.HtmlElement "document-flattened" attributes blocks) ->
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
            , MB.HtmlBlock
                (MB.HtmlElement
                    "document-flattened"
                    attributes
                    flattenedBlocks
                )
            )

        MB.HtmlBlock (MB.HtmlElement tag attributes blocks) ->
            let
                ( hasChildren, flattenedBlocks ) =
                    flattenMarkdown legacyMode documents parentLevel Nothing blocks
            in
            ( hasChildren
            , MB.HtmlBlock
                (MB.HtmlElement
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


mergeInlines : MB.Block -> MB.Block
mergeInlines block =
    mapHtmlElementChildren
        (List.foldl
            mergeInlinesHelper
            []
            >> List.reverse
        )
        block


mapHtmlElementChildren :
    (List (MB.Block) -> List (MB.Block))
    -> MB.Block
    -> MB.Block
mapHtmlElementChildren mapFun block =
    case block of
        MB.HtmlBlock (MB.HtmlElement name attrs children) ->
            MB.HtmlBlock
                (MB.HtmlElement
                    name
                    attrs
                    (mapFun children)
                )

        _ ->
            block


mergeInlinesHelper : MB.Block -> List MB.Block -> List MB.Block
mergeInlinesHelper block result =
    let
        inlineTags : List String
        inlineTags =
            [ "actions"
            , "br"
            , "date"
            , "sup"
            ]

        nextInlineIsStrong : List MB.Inline -> Bool
        nextInlineIsStrong inlines =
            case List.head inlines of
                Just (MB.Strong _) ->
                    True

                _ ->
                    False

        inlinesStartWithAlphaNum : List MB.Inline -> Bool
        inlinesStartWithAlphaNum inlines =
            MB.extractInlineText inlines
                |> String.uncons
                |> Maybe.map Tuple.first
                |> Maybe.map (not << Char.isAlphaNum)
                |> Maybe.withDefault False
    in
    case block of
        MB.HtmlBlock (MB.HtmlElement tagName attrs children) ->
            if List.member tagName inlineTags then
                case List.head result of
                    -- If previous block is a paragraph, add the block to its inlines.
                    Just (MB.Paragraph inlines) ->
                        (MB.Paragraph
                            (MB.HtmlElement tagName attrs children
                                |> MB.HtmlInline
                                |> List.singleton
                                |> List.append inlines
                            )
                        )
                            :: (List.drop 1 result)

                    _ ->
                        block :: result

            else
                block :: result

        MB.Paragraph inlines ->
            case List.head result of
                -- If previous block is an HTML block with an inline tag, merge it into this
                -- paragraph.
                Just (MB.HtmlBlock (MB.HtmlElement tagName attrs children)) ->
                    if List.member tagName inlineTags then
                        MB.Paragraph
                            (MB.HtmlInline (MB.HtmlElement tagName attrs children)
                                :: inlines
                            )
                            :: (List.drop 1 result)

                    else
                        block :: result

                -- If previous block is a paragraph, its last inline is an inline tag,
                -- and the next inline isn't a Strong, then merge the paragraphs.
                Just (MB.Paragraph prevInlines) ->
                    case List.Extra.last prevInlines of
                        Just (MB.HtmlInline (MB.HtmlElement tagName _ _)) ->
                            if List.member tagName inlineTags && not (nextInlineIsStrong inlines) then

                                MB.Paragraph
                                    (List.concat
                                        [ prevInlines
                                        , if inlinesStartWithAlphaNum inlines then
                                            []

                                          else
                                            [ MB.Text " " ]
                                        , inlines
                                        ]
                                    )
                                    :: (List.drop 1 result)

                            else
                                block :: result

                        _ ->
                            block :: result

                _ ->
                    block :: result

        _ ->
            block :: result


paragraphToInline : MB.Block -> MB.Block
paragraphToInline block =
    case block of
        MB.HtmlBlock (MB.HtmlElement tagName attr [ MB.Paragraph [ inline ] ]) ->
            MB.HtmlBlock
                (MB.HtmlElement
                    tagName
                    attr
                    [ MB.Inlines [ inline ] ]
                )

        MB.Paragraph inlines ->
            inlines
                |> List.map
                    (\inline ->
                        case inline of
                            MB.HtmlInline (MB.HtmlElement name attrs [ MB.Paragraph [ innerInline ] ]) ->
                                MB.Inlines [ innerInline ]
                                    |> List.singleton
                                    |> MB.HtmlElement name attrs
                                    |> MB.HtmlInline

                            _ ->
                                inline
                    )
                |> MB.Paragraph

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
    Field.attempt "showQueryControls" Decode.bool <| \showQueryControls ->
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
        , showQueryControls = Maybe.withDefault defaultFlags.showQueryControls showQueryControls
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
        [ "aggregations", "item_category_subcategory" ]
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
    Field.require
        "aggregations"
        valuesAggregationsDecoder
        <| \values ->
    Field.require
        "aggregations"
        minmaxAggregationsDecoder
        <| \minmax ->
    Decode.succeed
        { itemSubcategories = itemSubcategories
        , minmax = minmax
        , values = values
        }


aggregationBucketDecoder : Decode.Decoder a -> Decode.Decoder (List a)
aggregationBucketDecoder keyDecoder =
    Decode.field "buckets" (Decode.list (Decode.field "key" keyDecoder))


valuesAggregationsDecoder : Decode.Decoder (Dict String (List String))
valuesAggregationsDecoder =
    Decode.dict
        (Decode.oneOf
            [ aggregationBucketDecoder Decode.string
                |> Decode.map Just
            , aggregationBucketDecoder
                (Decode.int
                    |> Decode.map
                        (\v ->
                            if v == 0 then
                                "false"

                            else
                                "true"
                        )
                )
                |> Decode.map Just
            , Decode.succeed Nothing
            ]
        )
        |> Decode.map (Dict.Extra.filterMap (\k v -> v))


minmaxAggregationsDecoder : Decode.Decoder (Dict String ( Float, Float ))
minmaxAggregationsDecoder =
    Decode.dict
        (Decode.oneOf
            [ Decode.field "value" Decode.float
                |> Decode.map Just
            , Decode.succeed Nothing
            ]
        )
        |> Decode.map (Dict.Extra.filterMap (\k v -> v))
        |> Decode.map
            (\dict ->
                Dict.foldl
                    (\key min result ->
                        if String.endsWith ".min" key then
                            case Dict.get (String.replace ".min" ".max" key) dict of
                                Just max ->
                                    Dict.insert
                                        (String.replace ".min" "" key)
                                        ( min, max )
                                        result

                                Nothing ->
                                    result

                        else
                            result
                    )
                    Dict.empty
                    dict
            )


globalAggregationsDecoder : Decode.Decoder GlobalAggregations
globalAggregationsDecoder =
    Field.require "sources" (Decode.list sourceAggregationDecoder) <| \sources ->
    Field.require "traits" (Decode.list traitAggregationDecoder) <| \traits ->
    Decode.succeed
        { sources = sources
        , traits =
            traits
                |> Dict.Extra.groupBy .group
                |> Dict.map (\_ v -> List.map .trait v)
        }


sourceAggregationDecoder : Decode.Decoder Source
sourceAggregationDecoder =
    Field.require "category" Decode.string <| \category ->
    Field.require "group" (Decode.nullable Decode.string) <| \group ->
    Field.require "name" Decode.string <| \name ->
    Decode.succeed
       { category = category
       , group = group
       , name = name
       }


traitAggregationDecoder : Decode.Decoder { group : String, trait : String }
traitAggregationDecoder =
    Field.require "group" Decode.string <| \group ->
    Field.require "trait" Decode.string <| \trait ->
    Decode.succeed
       { group = String.toLower group
       , trait = String.toLower trait
       }


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
    Field.attempt "ac_scale_number" Decode.int <| \acScale ->
    Field.attempt "actions" Decode.string <| \actions ->
    Field.attempt "activate" Decode.string <| \activate ->
    Field.attempt "advanced_apocryphal_spell_markdown" Decode.string <| \advancedApocryphalSpell ->
    Field.attempt "advanced_domain_spell_markdown" Decode.string <| \advancedDomainSpell ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "anathema" Decode.string <| \anathemas ->
    Field.attempt "apocryphal_spell_markdown" Decode.string <| \apocryphalSpell ->
    Field.attempt "archetype" Decode.string <| \archetype ->
    Field.attempt "area_raw" Decode.string <| \area ->
    Field.attempt "area_of_concern_raw" Decode.string <| \areasOfConcern ->
    Field.attempt "area_type" stringListDecoder <| \areaTypes ->
    Field.attempt "armor_category" Decode.string <| \armorCategory ->
    Field.attempt "armor_group_markdown" Decode.string <| \armorGroup ->
    Field.attempt "aspect" Decode.string <| \aspect ->
    Field.attempt "attack_bonus" (Decode.list Decode.int) <| \attackBonus ->
    Field.attempt "attack_bonus_scale_number" (Decode.list Decode.int) <| \attackBonusScale ->
    Field.attempt "attack_proficiency" stringListDecoder <| \attackProficiencies ->
    Field.attempt "attribute_flaw" stringListDecoder <| \attributeFlaws ->
    Field.attempt "attribute" stringListDecoder <| \attributes ->
    Field.attempt "base_item_markdown" Decode.string <| \baseItems ->
    Field.attempt "bloodline_markdown" Decode.string <| \bloodlines ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "bulk" Decode.float <| \bulk ->
    Field.attempt "bulk_raw" Decode.string <| \bulkRaw ->
    Field.attempt "charisma" Decode.int <| \charisma ->
    Field.attempt "charisma_scale_number" Decode.int <| \charismaScale ->
    Field.attempt "check_penalty" Decode.int <| \checkPenalty ->
    Field.attempt "complexity" Decode.string <| \complexity ->
    Field.attempt "component" stringListDecoder <| \components ->
    Field.attempt "constitution" Decode.int <| \constitution ->
    Field.attempt "constitution_scale_number" Decode.int <| \constitutionScale ->
    Field.attempt "cost_markdown" Decode.string <| \cost ->
    Field.attempt "creature_ability" stringListDecoder <| \creatureAbilities ->
    Field.attempt "creature_family" Decode.string <| \creatureFamily ->
    Field.attempt "creature_family_markdown" Decode.string <| \creatureFamilyMarkdown ->
    Field.attempt "crew" Decode.string <| \crew ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "damage_type" stringListDecoder <| \damageTypes ->
    Field.attempt "defense_proficiency" stringListDecoder <| \defenseProficiencies ->
    Field.attempt "deity" stringListDecoder <| \deitiesList ->
    Field.attempt "deity_markdown" Decode.string <| \deities ->
    Field.attempt "deity_category" Decode.string <| \deityCategory ->
    Field.attempt "dex_cap" Decode.int <| \dexCap ->
    Field.attempt "dexterity" Decode.int <| \dexterity ->
    Field.attempt "dexterity_scale_number" Decode.int <| \dexterityScale ->
    Field.attempt "divine_font" stringListDecoder <| \divineFonts ->
    Field.attempt "domain" stringListDecoder <| \domainsList ->
    Field.attempt "domain_markdown" Decode.string <| \domains ->
    Field.attempt "domain_alternate_markdown" Decode.string <| \domainsAlternate ->
    Field.attempt "domain_primary_markdown" Decode.string <| \domainsPrimary ->
    Field.attempt "domain_spell_markdown" Decode.string <| \domainSpell ->
    Field.attempt "duration" Decode.int <| \durationValue ->
    Field.attempt "duration_raw" Decode.string <| \duration ->
    Field.attempt "edict" Decode.string <| \edicts ->
    Field.attempt "element" stringListDecoder <| \elements ->
    Field.attempt "familiar_ability" stringListDecoder <| \familiarAbilities ->
    Field.attempt "favored_weapon_markdown" Decode.string <| \favoredWeapons ->
    Field.attempt "feat_markdown" Decode.string <| \feats ->
    Field.attempt "fortitude_proficiency" Decode.string <| \fortitudeProficiency ->
    Field.attempt "fortitude_save" Decode.int <| \fort ->
    Field.attempt "fortitude_save_scale_number" Decode.int <| \fortitudeScale ->
    Field.attempt "follower_alignment" stringListDecoder <| \followerAlignments ->
    Field.attempt "frequency" Decode.string <| \frequency ->
    Field.attempt "hands" Decode.string <| \hands ->
    Field.attempt "hardness_raw" Decode.string <| \hardness ->
    Field.attempt "hazard_type" Decode.string <| \hazardType ->
    Field.attempt "heighten" stringListDecoder <| \heighten ->
    Field.attempt "heighten_group" stringListDecoder <| \heightenGroups ->
    Field.attempt "heighten_level" (Decode.list Decode.int) <| \heightenLevels ->
    Field.attempt "hp_raw" Decode.string <| \hp ->
    Field.attempt "hp_scale_number" Decode.int <| \hpScale ->
    Field.attempt "icon_image" Decode.string <| \iconImage ->
    Field.attempt "image" stringListDecoder <| \images ->
    Field.attempt "immunity_markdown" Decode.string <| \immunities ->
    Field.attempt "intelligence" Decode.int <| \intelligence ->
    Field.attempt "intelligence_scale_number" Decode.int <| \intelligenceScale ->
    Field.attempt "item_bonus_action" Decode.string <| \itemBonusAction ->
    Field.attempt "item_bonus_consumable" Decode.bool <| \itemBonusConsumable ->
    Field.attempt "item_bonus_note" Decode.string <| \itemBonusNote ->
    Field.attempt "item_bonus_value" Decode.int <| \itemBonusValue ->
    Field.attempt "item_category" Decode.string <| \itemCategory ->
    Field.attempt "item_child_id" stringListDecoder <| \itemChildrenIds ->
    Field.attempt "item_subcategory" Decode.string <| \itemSubcategory ->
    Field.attempt "language_markdown" Decode.string <| \languages ->
    Field.attempt "legacy_id" stringListDecoder <| \legacyIds ->
    Field.attempt "lesson_markdown" Decode.string <| \lessons ->
    Field.attempt "lesson_type" Decode.string <| \lessonType ->
    Field.attempt "level" Decode.int <| \level ->
    Field.attempt "markdown" Decode.string <| \markdown ->
    Field.attempt "mystery_markdown" Decode.string <| \mysteries ->
    Field.attempt "onset_raw" Decode.string <| \onset ->
    Field.attempt "pantheon" stringListDecoder <| \pantheons ->
    Field.attempt "pantheon_markdown" Decode.string <| \pantheonMarkdown ->
    Field.attempt "pantheon_member_markdown" Decode.string <| \pantheonMembers ->
    Field.attempt "passengers_raw" Decode.string <| \passengers ->
    Field.attempt "patron_theme_markdown" Decode.string <| \patronThemes ->
    Field.attempt "perception" Decode.int <| \perception ->
    Field.attempt "perception_proficiency" Decode.string <| \perceptionProficiency ->
    Field.attempt "perception_scale_number" Decode.int <| \perceptionScale ->
    Field.attempt "pfs" Decode.string <| \pfs ->
    Field.attempt "piloting_check_markdown" Decode.string <| \pilotingCheck ->
    Field.attempt "plane_category" Decode.string <| \planeCategory ->
    Field.attempt "prerequisite_markdown" Decode.string <| \prerequisites ->
    Field.attempt "price_raw" Decode.string <| \price ->
    Field.attempt "primary_check_markdown" Decode.string <| \primaryCheck ->
    Field.attempt "primary_source_category" Decode.string <| \primarySourceCategory ->
    Field.attempt "primary_source_group" Decode.string <| \primarySourceGroup ->
    Field.attempt "range" Decode.int <| \rangeValue ->
    Field.attempt "range_raw" Decode.string <| \range ->
    Field.attempt "rarity" Decode.string <| \rarity ->
    Field.attempt "rarity_id" Decode.int <| \rarityId ->
    Field.attempt "reflex_proficiency" Decode.string <| \reflexProficiency ->
    Field.attempt "reflex_save" Decode.int <| \ref ->
    Field.attempt "reflex_save_scale_number" Decode.int <| \reflexScale ->
    Field.attempt "region" Decode.string <| \region->
    Field.attempt "release_date" Decode.string <| \releaseDate ->
    Field.attempt "reload_raw" Decode.string <| \reload ->
    Field.attempt "remaster_id" stringListDecoder <| \remasterIds ->
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
    Field.attempt "source_category" stringListDecoder <| \sourceCategories ->
    Field.attempt "source_group" stringListDecoder <| \sourceGroups ->
    Field.attempt "source_markdown" Decode.string <| \sources ->
    Field.attempt "space" Decode.string <| \space ->
    Field.attempt "speed" speedTypeValuesDecoder <| \speedValues ->
    Field.attempt "speed_markdown" Decode.string <| \speed ->
    Field.attempt "speed_penalty" Decode.string <| \speedPenalty ->
    Field.attempt "spell_markdown" Decode.string <| \spell ->
    Field.attempt "spell_list" Decode.string <| \spellList ->
    Field.attempt "spell_attack_bonus" (Decode.list Decode.int) <| \spellAttackBonus ->
    Field.attempt "spell_attack_bonus_scale_number" (Decode.list Decode.int) <| \spellAttackBonusScale ->
    Field.attempt "spell_dc" (Decode.list Decode.int) <| \spellDc ->
    Field.attempt "spell_dc_scale_number" (Decode.list Decode.int) <| \spellDcScale ->
    Field.attempt "spell_type" Decode.string <| \spellType ->
    Field.attempt "spoilers" Decode.string <| \spoilers ->
    Field.attempt "stage_markdown" Decode.string <| \stages ->
    Field.attempt "strength" Decode.int <| \strength ->
    Field.attempt "strength_scale_number" Decode.int <| \strengthScale ->
    Field.attempt "strike_damage_average" (Decode.list Decode.int) <| \strikeDamageAverage ->
    Field.attempt "strike_damage_scale_number" (Decode.list Decode.int) <| \strikeDamageScale ->
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
    Field.attempt "will_proficiency" Decode.string <| \willProficiency ->
    Field.attempt "will_save" Decode.int <| \will ->
    Field.attempt "will_save_scale_number" Decode.int <| \willScale ->
    Field.attempt "wisdom" Decode.int <| \wisdom ->
    Field.attempt "wisdom_scale_number" Decode.int <| \wisdomScale ->
    Decode.succeed
        { id = id
        , category = category
        , name = name
        , type_ = type_
        , url = url
        , abilityType = abilityType
        , ac = ac
        , acScale = acScale
        , actions = actions
        , activate = activate
        , advancedApocryphalSpell = advancedApocryphalSpell
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , anathemas = anathemas
        , apocryphalSpell = apocryphalSpell
        , archetype = archetype
        , area = area
        , areasOfConcern = areasOfConcern
        , areaTypes = Maybe.withDefault [] areaTypes
        , armorCategory = armorCategory
        , armorGroup = armorGroup
        , aspect = aspect
        , attackBonus = Maybe.withDefault [] attackBonus
        , attackBonusScale = Maybe.withDefault [] attackBonusScale
        , attackProficiencies = Maybe.withDefault [] attackProficiencies
        , attributeFlaws = Maybe.withDefault [] attributeFlaws
        , attributes = Maybe.withDefault [] attributes
        , baseItems = baseItems
        , bloodlines = bloodlines
        , breadcrumbs = breadcrumbs
        , bulk = bulk
        , bulkRaw = bulkRaw
        , charisma = charisma
        , charismaScale = charismaScale
        , checkPenalty = checkPenalty
        , complexity = complexity
        , components = Maybe.withDefault [] components
        , constitution = constitution
        , constitutionScale = constitutionScale
        , cost = cost
        , creatureAbilities = Maybe.withDefault [] creatureAbilities
        , creatureFamily = creatureFamily
        , creatureFamilyMarkdown = creatureFamilyMarkdown
        , crew = crew
        , damage = damage
        , damageTypes = Maybe.withDefault [] damageTypes
        , defenseProficiencies = Maybe.withDefault [] defenseProficiencies
        , deities = deities
        , deitiesList = Maybe.withDefault [] deitiesList
        , deityCategory = deityCategory
        , dexCap = dexCap
        , dexterity = dexterity
        , dexterityScale = dexterityScale
        , divineFonts = Maybe.withDefault [] divineFonts
        , domains = domains
        , domainsList = Maybe.withDefault [] domainsList
        , domainsAlternate = domainsAlternate
        , domainsPrimary = domainsPrimary
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
        , fortitudeScale = fortitudeScale
        , followerAlignments = Maybe.withDefault [] followerAlignments
        , frequency = frequency
        , hands = hands
        , hardness = hardness
        , hazardType = hazardType
        , heighten = Maybe.withDefault [] heighten
        , heightenGroups = Maybe.withDefault [] heightenGroups
        , heightenLevels = Maybe.withDefault [] heightenLevels
        , hp = hp
        , hpScale = hpScale
        , iconImage = iconImage
        , images = Maybe.withDefault [] images
        , immunities = immunities
        , intelligence = intelligence
        , intelligenceScale = intelligenceScale
        , itemBonusAction = itemBonusAction
        , itemBonusConsumable = itemBonusConsumable
        , itemBonusNote = itemBonusNote
        , itemBonusValue = itemBonusValue
        , itemCategory = itemCategory
        , itemHasChildren = not (List.isEmpty (Maybe.withDefault [] itemChildrenIds))
        , itemSubcategory = itemSubcategory
        , languages = languages
        , legacyIds = Maybe.withDefault [] legacyIds
        , lessonType = lessonType
        , lessons = lessons
        , level = level
        , markdown = NotParsed (Maybe.withDefault "" markdown)
        , mysteries = mysteries
        , onset = onset
        , pantheons = Maybe.withDefault [] pantheons
        , pantheonMarkdown = pantheonMarkdown
        , pantheonMembers = pantheonMembers
        , passengers = passengers
        , patronThemes = patronThemes
        , perception = perception
        , perceptionProficiency = perceptionProficiency
        , perceptionScale = perceptionScale
        , pfs = pfs
        , pilotingCheck = pilotingCheck
        , planeCategory = planeCategory
        , prerequisites = prerequisites
        , price = price
        , primaryCheck = primaryCheck
        , primarySourceCategory = primarySourceCategory
        , primarySourceGroup = primarySourceGroup
        , range = range
        , rangeValue = rangeValue
        , rarity = rarity
        , rarityId = rarityId
        , ref = ref
        , reflexProficiency = reflexProficiency
        , reflexScale = reflexScale
        , region = region
        , releaseDate = releaseDate
        , reload = reload
        , remasterIds = Maybe.withDefault [] remasterIds
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
        , sourceCategories = Maybe.withDefault [] sourceCategories
        , sourceGroups = Maybe.withDefault [] sourceGroups
        , sourceList = Maybe.withDefault [] sourceList
        , sources = sources
        , space = space
        , speed = speed
        , speedPenalty = speedPenalty
        , speedValues = speedValues
        , spell = spell
        , spellList = spellList
        , spellAttackBonus = Maybe.withDefault [] spellAttackBonus
        , spellAttackBonusScale = Maybe.withDefault [] spellAttackBonusScale
        , spellDc = Maybe.withDefault [] spellDc
        , spellDcScale = Maybe.withDefault [] spellDcScale
        , spellType = spellType
        , spoilers = spoilers
        , stages = stages
        , strength = strength
        , strengthScale = strengthScale
        , strikeDamageAverage = Maybe.withDefault [] strikeDamageAverage
        , strikeDamageScale = Maybe.withDefault [] strikeDamageScale
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
        , willScale = willScale
        , wisdom = wisdom
        , wisdomScale = wisdomScale
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
