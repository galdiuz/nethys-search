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
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Maybe.Extra
import Process
import Regex
import Result.Extra
import String.Extra
import Svg
import Svg.Attributes as SA
import Task
import Tuple3
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
    , abilityFlaws : List String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , ammunition : Maybe String
    , anathema : Maybe String
    , archetype : Maybe String
    , area : Maybe String
    , areasOfConcern : Maybe String
    , armorCategory : Maybe String
    , armorGroup : Maybe String
    , attackProficiencies : List String
    , aspect : Maybe String
    , bloodlines : Maybe String
    , breadcrumbs : Maybe String
    , bulk : Maybe String
    , charisma : Maybe Int
    , checkPenalty : Maybe Int
    , clericSpells : Maybe String
    , components : List String
    , constitution : Maybe Int
    , cost : Maybe String
    , creatureFamily : Maybe String
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
    , edict : Maybe String
    , familiarAbilities : List String
    , favoredWeapons : Maybe String
    , feats : Maybe String
    , followerAlignments : List String
    , fort : Maybe Int
    , frequency : Maybe String
    , hands : Maybe String
    , hardness : Maybe String
    , heighten : List String
    , hp : Maybe String
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
    , rarity : Maybe String
    , ref : Maybe Int
    , region : Maybe String
    , reload : Maybe String
    , requiredAbilities : Maybe String
    , requirements : Maybe String
    , resistanceValues : Maybe DamageTypeValues
    , resistances : Maybe String
    , savingThrow : Maybe String
    , savingThrowProficiencies : List String
    , school : Maybe String
    , searchMarkdown : ParsedMarkdownResult
    , secondaryCasters : Maybe String
    , secondaryChecks : Maybe String
    , senses : Maybe String
    , sizes : List String
    , skills : Maybe String
    , skillProficiencies : List String
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
    , traditions : Maybe String
    , traits : Maybe String
    , trigger : Maybe String
    , usage : Maybe String
    , vision : Maybe String
    , weakestSaves : List String
    , weaknessValues : Maybe DamageTypeValues
    , weaknesses : Maybe String
    , weaponCategory : Maybe String
    , weaponGroup : Maybe String
    , weaponType : Maybe String
    , will : Maybe Int
    , wisdom : Maybe Int
    }


type alias Flags =
    { autofocus : Bool
    , currentUrl : String
    , defaultQuery : String
    , elasticUrl : String
    , fixedQueryString : String
    , hideFilters : List String
    , resultBaseUrl : String
    , showHeader : Bool
    }


defaultFlags : Flags
defaultFlags =
    { autofocus = False
    , currentUrl = "/"
    , defaultQuery = ""
    , elasticUrl = ""
    , fixedQueryString = ""
    , hideFilters = []
    , resultBaseUrl = "https://2e.aonprd.com/"
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


type alias ParsedMarkdownResult =
    Result (List String) (List Markdown.Block.Block)


type QueryType
    = Standard
    | ElasticsearchQueryString


type LoadType
    = LoadNew
    | LoadMore
    | LoadRemaining


type ResultDisplay
    = List
    | Table


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
    | GotAggregationsResult (Result Http.Error Aggregations)
    | GotElementHeight String Int
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
    | HandFilterAdded String
    | HandFilterRemoved String
    | ItemCategoryFilterAdded String
    | ItemCategoryFilterRemoved String
    | ItemSubcategoryFilterAdded String
    | ItemSubcategoryFilterRemoved String
    | LimitTableWidthChanged Bool
    | LoadMorePressed
    | LoadRemainingPressed
    | LocalStorageValueReceived Decode.Value
    | MenuOpenDelayPassed
    | NoOp
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
    | ShowFoldableOptionBoxPressed String Bool
    | ShowMenuPressed Bool
    | ShowQueryOptionsPressed Bool
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
    { aggregations : Maybe (Result Http.Error Aggregations)
    , autofocus : Bool
    , autoQueryType : Bool
    , debounce : Int
    , defaultQuery : String
    , elasticUrl : String
    , elementHeights : Dict String Int
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
    , hideFilters : List String
    , lastSearchKey : Maybe String
    , limitTableWidth : Bool
    , menuOpen : Bool
    , overlayActive : Bool
    , pageSize : Int
    , query : String
    , queryOptionsOpen : Bool
    , queryType : QueryType
    , resultBaseUrl : String
    , resultDisplay : ResultDisplay
    , searchCreatureFamilies : String
    , searchItemCategories : String
    , searchItemSubcategories : String
    , searchSources : String
    , searchResults : List (Result Http.Error SearchResult)
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
    , showHeader : Bool
    , showResultAdditionalInfo : Bool
    , showResultSpoilers : Bool
    , showResultSummary : Bool
    , showResultTraits : Bool
    , sort : List ( String, SortDir )
    , sourcesAggregation : Maybe (Result Http.Error (List Source))
    , tableColumns : List String
    , theme : Theme
    , tracker : Maybe Int
    , url : Url
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
    ( { aggregations = Nothing
      , autofocus = flags.autofocus
      , autoQueryType = False
      , debounce = 0
      , defaultQuery = flags.defaultQuery
      , elasticUrl = flags.elasticUrl
      , elementHeights = Dict.empty
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
      , fixedQueryString = flags.fixedQueryString
      , hideFilters = flags.hideFilters
      , lastSearchKey = Nothing
      , limitTableWidth = False
      , menuOpen = False
      , overlayActive = False
      , pageSize = 50
      , query = ""
      , queryOptionsOpen = False
      , queryType = Standard
      , resultBaseUrl = flags.resultBaseUrl
      , resultDisplay = List
      , searchCreatureFamilies = ""
      , searchItemCategories = ""
      , searchItemSubcategories = ""
      , searchSources = ""
      , searchResults = []
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
      , showHeader = flags.showHeader
      , showResultAdditionalInfo = True
      , showResultSpoilers = True
      , showResultSummary = True
      , showResultTraits = True
      , sort = []
      , sourcesAggregation = Nothing
      , tableColumns = []
      , theme = Dark
      , tracker = Nothing
      , url = url
      }
        |> updateModelFromParams
            (url.query
                |> Maybe.withDefault flags.defaultQuery
                |> queryToParamsDict
            )
    , Cmd.batch
        [ localStorage_get "auto-query-type"
        , localStorage_get "limit-table-width"
        , localStorage_get "show-additional-info"
        , localStorage_get "show-spoilers"
        , localStorage_get "show-summary"
        , localStorage_get "show-traits"
        , localStorage_get "theme"
        ]
    )
        |> searchWithCurrentQuery LoadNew
        |> updateTitle
        |> getAggregations
        |> getSourcesAggregation


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
        AbilityFilterAdded abilities ->
            ( model
            , updateUrl { model | filteredAbilities = toggleBoolDict abilities model.filteredAbilities }
            )

        AbilityFilterRemoved abilities ->
            ( model
            , updateUrl { model | filteredAbilities = Dict.remove abilities model.filteredAbilities }
            )

        ActionsFilterAdded actions ->
            ( model
            , updateUrl { model | filteredActions = toggleBoolDict actions model.filteredActions }
            )

        ActionsFilterRemoved actions ->
            ( model
            , updateUrl { model | filteredActions = Dict.remove actions model.filteredActions }
            )

        AlignmentFilterAdded alignment ->
            ( model
            , updateUrl { model | filteredAlignments = toggleBoolDict alignment model.filteredAlignments }
            )

        AlignmentFilterRemoved alignment ->
            ( model
            , updateUrl { model | filteredAlignments = Dict.remove alignment model.filteredAlignments }
            )

        AutoQueryTypeChanged enabled ->
            ( { model | autoQueryType = enabled }
            , Cmd.batch
                [ saveToLocalStorage
                    "auto-query-type"
                    (if enabled then "1" else "0")
                , updateUrl { model | autoQueryType = enabled }
                ]
            )

        ColumnResistanceChanged resistance ->
            ( { model | selectedColumnResistance = resistance }
            , Cmd.none
            )

        ColumnSpeedChanged speed ->
            ( { model | selectedColumnSpeed = speed }
            , Cmd.none
            )

        ColumnWeaknessChanged weakness ->
            ( { model | selectedColumnWeakness = weakness }
            , Cmd.none
            )

        ComponentFilterAdded component ->
            ( model
            , updateUrl { model | filteredComponents = toggleBoolDict component model.filteredComponents }
            )

        ComponentFilterRemoved component ->
            ( model
            , updateUrl { model | filteredComponents = Dict.remove component model.filteredComponents }
            )

        CreatureFamilyFilterAdded creatureFamily ->
            ( model
            , updateUrl { model | filteredCreatureFamilies = toggleBoolDict creatureFamily model.filteredCreatureFamilies }
            )

        CreatureFamilyFilterRemoved creatureFamily ->
            ( model
            , updateUrl { model | filteredCreatureFamilies = Dict.remove creatureFamily model.filteredCreatureFamilies }
            )

        DebouncePassed debounce ->
            if model.debounce == debounce then
                ( model
                , updateUrl model
                )

            else
                ( model, Cmd.none )

        GotAggregationsResult result ->
            ( { model | aggregations = Just result }
            , Cmd.none
            )

        GotElementHeight id height ->
            ( { model | elementHeights = Dict.insert id height model.elementHeights }
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
            ( { model
                | searchResults =
                    List.append
                        (List.filter Result.Extra.isOk model.searchResults)
                        [ result ]
                , tracker = Nothing
              }
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

        FilterSpeedChanged value ->
            ( { model | selectedFilterSpeed = value }
            , Cmd.none
            )

        FilterSpoilersChanged value ->
            ( model
            , updateUrl { model | filterSpoilers = value }
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

        HandFilterAdded subcategory ->
            ( model
            , updateUrl { model | filteredHands = toggleBoolDict subcategory model.filteredHands }
            )

        HandFilterRemoved subcategory ->
            ( model
            , updateUrl { model | filteredHands = Dict.remove subcategory model.filteredHands }
            )

        ItemCategoryFilterAdded category ->
            let
                newFilteredItemCategories : Dict String Bool
                newFilteredItemCategories =
                    toggleBoolDict category model.filteredItemCategories
            in
            ( model
            , updateUrl
                { model
                    | filteredItemCategories = newFilteredItemCategories
                    , filteredItemSubcategories =
                        case Dict.get category newFilteredItemCategories of
                            Just True ->
                                Dict.filter
                                    (\source _ ->
                                        model.aggregations
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
                                    model.filteredItemSubcategories

                            Just False ->
                                Dict.filter
                                    (\source _ ->
                                        model.aggregations
                                            |> Maybe.andThen Result.toMaybe
                                            |> Maybe.map .itemSubcategories
                                            |> Maybe.andThen (List.Extra.find (.name >> ((==) source)))
                                            |> Maybe.map .category
                                            |> Maybe.map String.toLower
                                            |> (/=) (Just category)
                                    )
                                    model.filteredItemSubcategories

                            Nothing ->
                                model.filteredItemSubcategories
                }
            )

        ItemCategoryFilterRemoved category ->
            ( model
            , updateUrl { model | filteredItemCategories = Dict.remove category model.filteredItemCategories }
            )

        ItemSubcategoryFilterAdded subcategory ->
            ( model
            , updateUrl { model | filteredItemSubcategories = toggleBoolDict subcategory model.filteredItemSubcategories }
            )

        ItemSubcategoryFilterRemoved subcategory ->
            ( model
            , updateUrl { model | filteredItemSubcategories = Dict.remove subcategory model.filteredItemSubcategories }
            )

        LimitTableWidthChanged value ->
            ( { model | limitTableWidth = value }
            , saveToLocalStorage
                "limit-table-width"
                (if value then "1" else "0")
            )

        LoadMorePressed ->
            ( model
            , Cmd.none
            )
                |> searchWithCurrentQuery LoadMore

        LoadRemainingPressed ->
            ( model
            , Cmd.none
            )
                |> searchWithCurrentQuery LoadRemaining

        LocalStorageValueReceived value ->
            ( case Decode.decodeValue (Decode.field "key" Decode.string) value of
                Ok "auto-query-type" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "1" ->
                            { model | autoQueryType = True }

                        Ok "0" ->
                            { model | autoQueryType = False }

                        _ ->
                            model

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

                        Ok "dead" ->
                            { model | theme = Dead }

                        Ok "lavender" ->
                            { model | theme = Lavender }

                        Ok "lavander" ->
                            { model | theme = Lavender }

                        Ok "blackbird" ->
                            { model | theme = Blackbird }

                        Ok "jonny" ->
                            { model | theme = Blackbird }

                        _ ->
                            model

                Ok "limit-table-width" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "1" ->
                            { model | limitTableWidth = True }

                        Ok "0" ->
                            { model | limitTableWidth = False }

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

                Ok "show-summary" ->
                    case Decode.decodeValue (Decode.field "value" Decode.string) value of
                        Ok "1" ->
                            { model | showResultSummary = True }

                        Ok "0" ->
                            { model | showResultSummary = False }

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

        RarityFilterAdded rarity ->
            ( model
            , updateUrl { model | filteredRarities = toggleBoolDict rarity model.filteredRarities }
            )

        RarityFilterRemoved rarity ->
            ( model
            , updateUrl { model | filteredRarities = Dict.remove rarity model.filteredRarities }
            )

        ReloadFilterAdded reload ->
            ( model
            , updateUrl { model | filteredReloads = toggleBoolDict reload model.filteredReloads }
            )

        ReloadFilterRemoved reload ->
            ( model
            , updateUrl { model | filteredReloads = Dict.remove reload model.filteredReloads }
            )

        RemoveAllSortsPressed ->
            ( model
            , updateUrl { model | sort = [] }
            )

        RemoveAllAbilityFiltersPressed ->
            ( model
            , updateUrl { model | filteredAbilities = Dict.empty }
            )

        RemoveAllActionsFiltersPressed ->
            ( model
            , updateUrl { model | filteredActions = Dict.empty }
            )

        RemoveAllAlignmentFiltersPressed ->
            ( model
            , updateUrl { model | filteredAlignments = Dict.empty }
            )

        RemoveAllComponentFiltersPressed ->
            ( model
            , updateUrl { model | filteredComponents = Dict.empty }
            )

        RemoveAllCreatureFamilyFiltersPressed ->
            ( model
            , updateUrl { model | filteredCreatureFamilies = Dict.empty }
            )

        RemoveAllHandFiltersPressed ->
            ( model
            , updateUrl { model | filteredHands = Dict.empty }
            )

        RemoveAllItemCategoryFiltersPressed ->
            ( model
            , updateUrl { model | filteredItemCategories = Dict.empty }
            )

        RemoveAllItemSubcategoryFiltersPressed ->
            ( model
            , updateUrl { model | filteredItemSubcategories = Dict.empty }
            )

        RemoveAllPfsFiltersPressed ->
            ( model
            , updateUrl { model | filteredPfs = Dict.empty }
            )

        RemoveAllRarityFiltersPressed ->
            ( model
            , updateUrl { model | filteredRarities = Dict.empty }
            )

        RemoveAllReloadFiltersPressed ->
            ( model
            , updateUrl { model | filteredReloads = Dict.empty }
            )

        RemoveAllSavingThrowFiltersPressed ->
            ( model
            , updateUrl { model | filteredSavingThrows = Dict.empty }
            )

        RemoveAllSchoolFiltersPressed ->
            ( model
            , updateUrl { model | filteredSchools = Dict.empty }
            )

        RemoveAllSizeFiltersPressed ->
            ( model
            , updateUrl { model | filteredSizes = Dict.empty }
            )

        RemoveAllSkillFiltersPressed ->
            ( model
            , updateUrl { model | filteredSkills = Dict.empty }
            )

        RemoveAllSourceCategoryFiltersPressed ->
            ( model
            , updateUrl { model | filteredSourceCategories = Dict.empty }
            )

        RemoveAllSourceFiltersPressed ->
            ( model
            , updateUrl { model | filteredSources = Dict.empty }
            )

        RemoveAllStrongestSaveFiltersPressed ->
            ( model
            , updateUrl { model | filteredStrongestSaves = Dict.empty }
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

        RemoveAllWeakestSaveFiltersPressed ->
            ( model
            , updateUrl { model | filteredWeakestSaves = Dict.empty }
            )

        RemoveAllWeaponCategoryFiltersPressed ->
            ( model
            , updateUrl { model | filteredWeaponCategories = Dict.empty }
            )

        RemoveAllWeaponGroupFiltersPressed ->
            ( model
            , updateUrl { model | filteredWeaponGroups = Dict.empty }
            )

        RemoveAllWeaponTypeFiltersPressed ->
            ( model
            , updateUrl { model | filteredWeaponTypes = Dict.empty }
            )

        ResultDisplayChanged value ->
            ( model
            , Cmd.batch
                [ updateUrl { model | resultDisplay = value }
                , getElementHeight resultDisplayMeasureWrapperId
                ]
            )

        SavingThrowFilterAdded savingThrow ->
            ( model
            , updateUrl { model | filteredSavingThrows = toggleBoolDict savingThrow model.filteredSavingThrows }
            )

        SavingThrowFilterRemoved savingThrow ->
            ( model
            , updateUrl { model | filteredSavingThrows = Dict.remove savingThrow model.filteredSavingThrows }
            )

        SchoolFilterAdded school ->
            ( model
            , updateUrl { model | filteredSchools = toggleBoolDict school model.filteredSchools }
            )

        SchoolFilterRemoved school ->
            ( model
            , updateUrl { model | filteredSchools = Dict.remove school model.filteredSchools }
            )

        ScrollToTopPressed  ->
            ( model
            , Task.perform (\_ -> NoOp) (Browser.Dom.setViewport 0 0)
            )

        SearchCreatureFamiliesChanged value ->
            ( { model | searchCreatureFamilies = value }
            , getElementHeight filterCreaturesMeasureWrapperId
            )

        SearchItemCategoriesChanged value ->
            ( { model | searchItemCategories = value }
            , getElementHeight filterItemCategoriesMeasureWrapperId
            )

        SearchItemSubcategoriesChanged value ->
            ( { model | searchItemSubcategories = value }
            , getElementHeight filterItemCategoriesMeasureWrapperId
            )

        SearchSourcesChanged value ->
            ( { model | searchSources = value }
            , getElementHeight filterSourcesMeasureWrapperId
            )

        SearchTraitsChanged value ->
            ( { model | searchTraits = value }
            , getElementHeight filterTraitsMeasureWrapperId
            )

        SearchTypesChanged value ->
            ( { model | searchTypes = value }
            , getElementHeight filterTypesMeasureWrapperId
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
            , updateUrl { model | filteredSizes = toggleBoolDict size model.filteredSizes }
            )

        SizeFilterRemoved size ->
            ( model
            , updateUrl { model | filteredSizes = Dict.remove size model.filteredSizes }
            )

        SkillFilterAdded skill ->
            ( model
            , updateUrl { model | filteredSkills = toggleBoolDict skill model.filteredSkills }
            )

        SkillFilterRemoved skill ->
            ( model
            , updateUrl { model | filteredSkills = Dict.remove skill model.filteredSkills }
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
                        if List.any (Tuple.first >> (==) field) model.sort then
                            List.Extra.updateIf
                                (Tuple.first >> (==) field)
                                (Tuple.mapSecond (\_ -> dir))
                                model.sort

                        else
                            List.append model.sort [ ( field, dir ) ]
                }
            )

        SortOrderChanged oldIndex newIndex ->
            ( model
            , updateUrl { model | sort = List.Extra.swapAt oldIndex newIndex model.sort }
            )

        SortRemoved field ->
            ( model
            , updateUrl { model | sort = List.filter (Tuple.first >> (/=) field) model.sort }
            )

        SortResistanceChanged value ->
            ( { model | selectedSortResistance = value }
            , Cmd.none
            )

        SortSetChosen fields ->
            ( model
            , updateUrl { model | sort = fields }
            )

        SortSpeedChanged value ->
            ( { model | selectedSortSpeed = value }
            , Cmd.none
            )

        SortToggled field ->
            ( model
            , updateUrl
                { model
                    | sort =
                        case List.Extra.find (Tuple.first >> (==) field) model.sort of
                            Just ( _, Asc ) ->
                                model.sort
                                    |> List.filter (Tuple.first >> (/=) field)
                                    |> (\list -> List.append list [ ( field, Desc ) ])

                            Just ( _, Desc ) ->
                                model.sort
                                    |> List.filter (Tuple.first >> (/=) field)

                            Nothing ->
                                List.append model.sort [ ( field, Asc ) ]
                }
            )

        SortWeaknessChanged value ->
            ( { model | selectedSortWeakness = value }
            , Cmd.none
            )

        SourceCategoryFilterAdded category ->
            let
                newFilteredSourceCategories : Dict String Bool
                newFilteredSourceCategories =
                    toggleBoolDict category model.filteredSourceCategories
            in
            ( model
            , updateUrl
                { model
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
                                    model.filteredSources

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
                                    model.filteredSources

                            Nothing ->
                                model.filteredSources
                }
            )

        SourceCategoryFilterRemoved category ->
            ( model
            , updateUrl { model | filteredSourceCategories = Dict.remove category model.filteredSourceCategories }
            )

        SourceFilterAdded book ->
            ( model
            , updateUrl { model | filteredSources = toggleBoolDict book model.filteredSources }
            )

        SourceFilterRemoved book ->
            ( model
            , updateUrl { model | filteredSources = Dict.remove book model.filteredSources }
            )

        StrongestSaveFilterAdded strongestSave ->
            ( model
            , updateUrl { model | filteredStrongestSaves = toggleBoolDict strongestSave model.filteredStrongestSaves }
            )

        StrongestSaveFilterRemoved strongestSave ->
            ( model
            , updateUrl { model | filteredStrongestSaves = Dict.remove strongestSave model.filteredStrongestSaves }
            )

        TableColumnAdded column ->
            ( model
            , updateUrl { model | tableColumns = List.append model.tableColumns [ column ] }
            )

        TableColumnMoved oldIndex newIndex ->
            ( model
            , updateUrl { model | tableColumns = List.Extra.swapAt oldIndex newIndex model.tableColumns }
            )

        TableColumnRemoved column ->
            ( model
            , updateUrl { model | tableColumns = List.filter ((/=) column) model.tableColumns }
            )

        TableColumnSetChosen columns ->
            ( model
            , updateUrl { model | tableColumns = columns }
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

        UrlChanged urlString ->
            let
                url : Url
                url =
                    parseUrl urlString
            in
            ( { model | url = url }
                |> updateModelFromParams
                    (url.query
                        |> Maybe.withDefault ""
                        |> queryToParamsDict
                    )
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
            , updateUrl { model | filteredWeakestSaves = toggleBoolDict weakestSave model.filteredWeakestSaves }
            )

        WeakestSaveFilterRemoved weakestSave ->
            ( model
            , updateUrl { model | filteredWeakestSaves = Dict.remove weakestSave model.filteredWeakestSaves }
            )

        WeaponCategoryFilterAdded category ->
            ( model
            , updateUrl { model | filteredWeaponCategories = toggleBoolDict category model.filteredWeaponCategories }
            )

        WeaponCategoryFilterRemoved category ->
            ( model
            , updateUrl { model | filteredWeaponCategories = Dict.remove category model.filteredWeaponCategories }
            )

        WeaponGroupFilterAdded group ->
            ( model
            , updateUrl { model | filteredWeaponGroups = toggleBoolDict group model.filteredWeaponGroups }
            )

        WeaponGroupFilterRemoved group ->
            ( model
            , updateUrl { model | filteredWeaponGroups = Dict.remove group model.filteredWeaponGroups }
            )

        WeaponTypeFilterAdded type_ ->
            ( model
            , updateUrl { model | filteredWeaponTypes = toggleBoolDict type_ model.filteredWeaponTypes }
            )

        WeaponTypeFilterRemoved type_ ->
            ( model
            , updateUrl { model | filteredWeaponTypes = Dict.remove type_ model.filteredWeaponTypes }
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
              , if model.autoQueryType then
                    if queryCouldBeComplex model.query then
                        "eqs"

                    else
                        ""

                else
                    case model.queryType of
                        Standard ->
                            ""

                        ElasticsearchQueryString ->
                            "eqs"
              )
            , ( "include-traits"
              , boolDictIncluded model.filteredTraits
                    |> String.join ";"
              )
            , ( "exclude-traits"
              , boolDictExcluded model.filteredTraits
                    |> String.join ";"
              )
            , ( "traits-operator"
              , if model.filterTraitsOperator then
                  ""

                else
                  "or"
              )
            , ( "include-types"
              , boolDictIncluded model.filteredTypes
                    |> String.join ";"
              )
            , ( "exclude-types"
              , boolDictExcluded model.filteredTypes
                    |> String.join ";"
              )
            , ( "include-abilities"
              , boolDictIncluded model.filteredAbilities
                    |> String.join ";"
              )
            , ( "exclude-abilities"
              , boolDictExcluded model.filteredAbilities
                    |> String.join ";"
              )
            , ( "include-actions"
              , boolDictIncluded model.filteredActions
                    |> String.join ";"
              )
            , ( "exclude-actions"
              , boolDictExcluded model.filteredActions
                    |> String.join ";"
              )
            , ( "include-alignments"
              , boolDictIncluded model.filteredAlignments
                    |> String.join ";"
              )
            , ( "exclude-alignments"
              , boolDictExcluded model.filteredAlignments
                    |> String.join ";"
              )
            , ( "include-components"
              , boolDictIncluded model.filteredComponents
                    |> String.join ";"
              )
            , ( "exclude-components"
              , boolDictExcluded model.filteredComponents
                    |> String.join ";"
              )
            , ( "components-operator"
              , if model.filterComponentsOperator then
                  ""

                else
                  "or"
              )
            , ( "include-creature-families"
              , boolDictIncluded model.filteredCreatureFamilies
                    |> String.join ";"
              )
            , ( "exclude-creature-families"
              , boolDictExcluded model.filteredCreatureFamilies
                    |> String.join ";"
              )
            , ( "include-hands"
              , boolDictIncluded model.filteredHands
                    |> String.join ";"
              )
            , ( "exclude-hands"
              , boolDictExcluded model.filteredHands
                    |> String.join ";"
              )
            , ( "include-item-categories"
              , boolDictIncluded model.filteredItemCategories
                    |> String.join ";"
              )
            , ( "exclude-item-categories"
              , boolDictExcluded model.filteredItemCategories
                    |> String.join ";"
              )
            , ( "include-item-subcategories"
              , boolDictIncluded model.filteredItemSubcategories
                    |> String.join ";"
              )
            , ( "exclude-item-subcategories"
              , boolDictExcluded model.filteredItemSubcategories
                    |> String.join ";"
              )
            , ( "include-pfs"
              , boolDictIncluded model.filteredPfs
                    |> String.join ";"
              )
            , ( "exclude-pfs"
              , boolDictExcluded model.filteredPfs
                    |> String.join ";"
              )
            , ( "include-rarities"
              , boolDictIncluded model.filteredRarities
                    |> String.join ";"
              )
            , ( "exclude-rarities"
              , boolDictExcluded model.filteredRarities
                    |> String.join ";"
              )
            , ( "include-reloads"
              , boolDictIncluded model.filteredReloads
                    |> String.join ";"
              )
            , ( "exclude-reloads"
              , boolDictExcluded model.filteredReloads
                    |> String.join ";"
              )
            , ( "include-saving-throws"
              , boolDictIncluded model.filteredSavingThrows
                    |> String.join ";"
              )
            , ( "exclude-saving-throws"
              , boolDictExcluded model.filteredSavingThrows
                    |> String.join ";"
              )
            , ( "include-schools"
              , boolDictIncluded model.filteredSchools
                    |> String.join ";"
              )
            , ( "exclude-schools"
              , boolDictExcluded model.filteredSchools
                    |> String.join ";"
              )
            , ( "include-sizes"
              , boolDictIncluded model.filteredSizes
                    |> String.join ";"
              )
            , ( "exclude-sizes"
              , boolDictExcluded model.filteredSizes
                    |> String.join ";"
              )
            , ( "include-skills"
              , boolDictIncluded model.filteredSkills
                    |> String.join ";"
              )
            , ( "exclude-skills"
              , boolDictExcluded model.filteredSkills
                    |> String.join ";"
              )
            , ( "include-sources"
              , boolDictIncluded model.filteredSources
                    |> String.join ";"
              )
            , ( "exclude-sources"
              , boolDictExcluded model.filteredSources
                    |> String.join ";"
              )
            , ( "include-source-categories"
              , boolDictIncluded model.filteredSourceCategories
                    |> String.join ";"
              )
            , ( "exclude-source-categories"
              , boolDictExcluded model.filteredSourceCategories
                    |> String.join ";"
              )
            , ( "include-strongest-saves"
              , boolDictIncluded model.filteredStrongestSaves
                    |> String.join ";"
              )
            , ( "exclude-strongest-saves"
              , boolDictExcluded model.filteredStrongestSaves
                    |> String.join ";"
              )
            , ( "include-traditions"
              , boolDictIncluded model.filteredTraditions
                    |> String.join ";"
              )
            , ( "exclude-traditions"
              , boolDictExcluded model.filteredTraditions
                    |> String.join ";"
              )
            , ( "traditions-operator"
              , if model.filterTraditionsOperator then
                    ""

                else
                    "or"
              )
            , ( "include-weakest-saves"
              , boolDictIncluded model.filteredWeakestSaves
                    |> String.join ";"
              )
            , ( "exclude-weakest-saves"
              , boolDictExcluded model.filteredWeakestSaves
                    |> String.join ";"
              )
            , ( "include-weapon-categories"
              , boolDictIncluded model.filteredWeaponCategories
                    |> String.join ";"
              )
            , ( "exclude-weapon-categories"
              , boolDictExcluded model.filteredWeaponCategories
                    |> String.join ";"
              )
            , ( "include-weapon-groups"
              , boolDictIncluded model.filteredWeaponGroups
                    |> String.join ";"
              )
            , ( "exclude-weapon-groups"
              , boolDictExcluded model.filteredWeaponGroups
                    |> String.join ";"
              )
            , ( "include-weapon-types"
              , boolDictIncluded model.filteredWeaponTypes
                    |> String.join ";"
              )
            , ( "exclude-weapon-types"
              , boolDictExcluded model.filteredWeaponTypes
                    |> String.join ";"
              )
            , ( "values-from"
              , model.filteredFromValues
                    |> Dict.toList
                    |> List.map (\( field, value ) -> field ++ ":" ++ value)
                    |> String.join ";"
              )
            , ( "values-to"
              , model.filteredToValues
                    |> Dict.toList
                    |> List.map (\( field, value ) -> field ++ ":" ++ value)
                    |> String.join ";"
              )
            , ( "spoilers"
              , if model.filterSpoilers then
                    "hide"

                else
                    ""
              )
            , ( "display"
              , if model.resultDisplay == Table then
                    "table"

                else
                    ""
              )
            , ( "columns"
              , if model.resultDisplay == Table then
                    String.join "," model.tableColumns

                else
                    ""
              )
            , ( "sort"
              , model.sort
                    |> List.map
                        (\( field, dir ) ->
                            field ++ "-" ++ sortDirToString dir
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


buildSearchBody : Model -> Int -> Encode.Value
buildSearchBody model size =
    let
        filters : List (List ( String, Encode.Value ))
        filters =
            buildSearchFilterTerms model

        mustNots : List (List ( String, Encode.Value ))
        mustNots =
            buildSearchMustNotTerms model
    in
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
                                            [ buildElasticsearchQueryStringQueryBody model.query ]
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

                        , if String.isEmpty model.query then
                            Nothing

                          else
                            Just ( "minimum_should_match", Encode.int 1 )
                        ]
                  )
                ]
          )
            |> Just
        , Just ( "size", Encode.int size )
        , ( "sort"
          , Encode.list identity
                (if List.isEmpty (getValidSortFields model.sort) then
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
                            (getValidSortFields model.sort)
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
        , model.searchResults
            |> List.Extra.last
            |> Maybe.andThen (Result.toMaybe)
            |> Maybe.map .hits
            |> Maybe.andThen List.Extra.last
            |> Maybe.map .sort
            |> Maybe.map (Tuple.pair "search_after")
        ]


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


getAggregation : (Aggregations -> List a) -> Model -> List a
getAggregation fun model =
    model.aggregations
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map fun
        |> Maybe.withDefault []


buildSearchFilterTerms : Model -> List (List ( String, Encode.Value ))
buildSearchFilterTerms model =
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
            (filterFields model)

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

        , if String.isEmpty model.fixedQueryString then
            []

          else
            [ buildElasticsearchQueryStringQueryBody model.fixedQueryString ]
        ]


buildSearchMustNotTerms : Model -> List (List ( String, Encode.Value ))
buildSearchMustNotTerms model =
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
            (filterFields model)

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
            (boolDictExcluded model.filteredSourceCategories)

        , if model.filterSpoilers then
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


queryToParamsDict : String -> Dict String String
queryToParamsDict query =
    query
        |> String.split "&"
        |> List.filterMap
            (\part ->
                case String.split "=" part of
                    [ key, value ] ->
                        Just ( key, Maybe.withDefault value (Url.percentDecode value) )

                    _ ->
                        Nothing
            )
        |> Dict.fromList


updateModelFromParams : Dict String String -> Model -> Model
updateModelFromParams params model =
    { model
        | query =
            Dict.get "q" params
                |> Maybe.Extra.orElse (Dict.get "query" params)
                |> Maybe.withDefault ""
        , queryType =
            case Dict.get "type" params of
                Just "eqs" ->
                    ElasticsearchQueryString

                _ ->
                    Standard
        , filteredAbilities = getBoolDictFromParams params ";" "abilities"
        , filteredActions = getBoolDictFromParams params ";" "actions"
        , filteredAlignments = getBoolDictFromParams params ";" "alignments"
        , filteredComponents = getBoolDictFromParams params ";" "components"
        , filteredCreatureFamilies = getBoolDictFromParams params ";" "creature-families"
        , filteredStrongestSaves = getBoolDictFromParams params ";" "strongest-saves"
        , filteredHands = getBoolDictFromParams params ";" "hands"
        , filteredItemCategories = getBoolDictFromParams params ";" "item-categories"
        , filteredItemSubcategories = getBoolDictFromParams params ";" "item-subcategories"
        , filteredWeakestSaves = getBoolDictFromParams params ";" "weakest-saves"
        , filteredPfs = getBoolDictFromParams params ";" "pfs"
        , filteredRarities = getBoolDictFromParams params ";" "rarities"
        , filteredReloads = getBoolDictFromParams params ";" "reloads"
        , filteredSavingThrows = getBoolDictFromParams params ";" "saving-throws"
        , filteredSchools = getBoolDictFromParams params ";" "schools"
        , filteredSizes = getBoolDictFromParams params ";" "sizes"
        , filteredSkills = getBoolDictFromParams params ";" "skills"
        , filteredSources = getBoolDictFromParams params ";" "sources"
        , filteredSourceCategories = getBoolDictFromParams params ";" "source-categories"
        , filteredTraditions = getBoolDictFromParams params ";" "traditions"
        , filteredTraits = getBoolDictFromParams params ";" "traits"
        , filteredTypes = getBoolDictFromParams params ";" "types"
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
        , resultDisplay =
            if Dict.get "display" params == Just "table" then
                Table

            else
                List
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
        , tableColumns =
            if Dict.get "display" params == Just "table" then
                Dict.get "columns" params
                    |> Maybe.map (String.split ",")
                    |> Maybe.withDefault []

            else
                model.tableColumns
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
    if (Just (getSearchKey model.url) /= model.lastSearchKey) || load /= LoadNew then
        let
            newTracker : Int
            newTracker =
                case model.tracker of
                    Just tracker ->
                        tracker + 1

                    Nothing ->
                        1

            newModel : Model
            newModel =
                { model
                    | lastSearchKey = Just (getSearchKey model.url)
                    , searchResults =
                        if load /= LoadNew then
                            model.searchResults

                        else
                            []
                    , tracker = Just newTracker
                }

            size : Int
            size =
                if load == LoadRemaining then
                    10000

                else
                    model.pageSize
        in
        ( newModel
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
                , body = Http.jsonBody (buildSearchBody newModel size)
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


getSearchKey : Url -> String
getSearchKey url =
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
        , document_setTitle model.query
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
            , body = Http.jsonBody (buildAggregationsBody model)
            , expect = Http.expectJson GotAggregationsResult aggregationsDecoder
            , timeout = Just 10000
            , tracker = Nothing
            }
        ]
    )


buildAggregationsBody : Model -> Encode.Value
buildAggregationsBody model =
    encodeObjectMaybe
        [ if String.isEmpty model.fixedQueryString then
            Nothing

          else
            ( "query"
            , Encode.object (buildElasticsearchQueryStringQueryBody model.fixedQueryString)
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
                        [ ( "category", "item_category" )
                        , ( "name", "item_subcategory" )
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


buildCompositeAggregation : String -> List ( String, String ) -> ( String, Encode.Value )
buildCompositeAggregation name sources =
    ( name
    , Encode.object
        [ ( "composite"
          , Encode.object
                [ ( "sources"
                  , Encode.list Encode.object (List.map buildCompositeTermsSource sources)
                  )
                , ( "size", Encode.int 10000 )
                ]
          )
        ]
    )


buildCompositeTermsSource : ( String, String ) -> List ( String, Encode.Value )
buildCompositeTermsSource ( name, field ) =
    [ ( name
      , Encode.object
            [ ( "terms"
              , Encode.object
                    [ ( "field", Encode.string field )
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
    Field.attempt "fixedQueryString" Decode.string <| \fixedQueryString ->
    Field.attempt "hideFilters" (Decode.list Decode.string) <| \hideFilters ->
    Decode.succeed
        { autofocus = Maybe.withDefault defaultFlags.autofocus autofocus
        , currentUrl = currentUrl
        , defaultQuery = Maybe.withDefault defaultFlags.defaultQuery defaultQuery
        , elasticUrl = elasticUrl
        , fixedQueryString = Maybe.withDefault defaultFlags.fixedQueryString fixedQueryString
        , hideFilters = Maybe.withDefault defaultFlags.hideFilters hideFilters
        , resultBaseUrl = Maybe.withDefault defaultFlags.resultBaseUrl resultBaseUrl
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
    Field.attempt "advanced_domain_spell_markdown" Decode.string <| \advancedDomainSpell ->
    Field.attempt "alignment" Decode.string <| \alignment ->
    Field.attempt "ammunition" Decode.string <| \ammunition ->
    Field.attempt "anathema" Decode.string <| \anathema ->
    Field.attempt "archetype" Decode.string <| \archetype ->
    Field.attempt "area" Decode.string <| \area ->
    Field.attempt "area_of_concern" Decode.string <| \areaOfConcern ->
    Field.attempt "armor_category" Decode.string <| \armorCategory ->
    Field.attempt "armor_group_markdown" Decode.string <| \armorGroup ->
    Field.attempt "aspect" Decode.string <| \aspect ->
    Field.attempt "attack_proficiency" stringListDecoder <| \attackProficiencies ->
    Field.attempt "breadcrumbs" Decode.string <| \breadcrumbs ->
    Field.attempt "bloodline_markdown" Decode.string <| \bloodlines ->
    Field.attempt "bulk_raw" Decode.string <| \bulk ->
    Field.attempt "charisma" Decode.int <| \charisma ->
    Field.attempt "check_penalty" Decode.int <| \checkPenalty ->
    Field.attempt "cleric_spell" Decode.string <| \clericSpell ->
    Field.attempt "component" (Decode.list Decode.string) <| \components ->
    Field.attempt "constitution" Decode.int <| \constitution ->
    Field.attempt "cost_markdown" Decode.string <| \cost ->
    Field.attempt "creature_family_markdown" Decode.string <| \creatureFamily ->
    Field.attempt "damage" Decode.string <| \damage ->
    Field.attempt "defense_proficiency" stringListDecoder <| \defenseProficiencies ->
    Field.attempt "deity_markdown" Decode.string <| \deities ->
    Field.attempt "deity_category" Decode.string <| \deityCategory ->
    Field.attempt "dex_cap" Decode.int <| \dexCap ->
    Field.attempt "dexterity" Decode.int <| \dexterity ->
    Field.attempt "divine_font" stringListDecoder <| \divineFonts ->
    Field.attempt "domain_markdown" Decode.string <| \domains ->
    Field.attempt "domain_spell_markdown" Decode.string <| \domainSpell ->
    Field.attempt "duration_raw" Decode.string <| \duration ->
    Field.attempt "edict" Decode.string <| \edict ->
    Field.attempt "familiar_ability" stringListDecoder <| \familiarAbilities ->
    Field.attempt "favored_weapon_markdown" Decode.string <| \favoredWeapons ->
    Field.attempt "feat_markdown" Decode.string <| \feats ->
    Field.attempt "fortitude_save" Decode.int <| \fort ->
    Field.attempt "follower_alignment" stringListDecoder <| \followerAlignments ->
    Field.attempt "frequency" Decode.string <| \frequency ->
    Field.attempt "hands" Decode.string <| \hands ->
    Field.attempt "hardness_raw" Decode.string <| \hardness ->
    Field.attempt "heighten" (Decode.list Decode.string) <| \heighten ->
    Field.attempt "hp_raw" Decode.string <| \hp ->
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
    Field.attempt "range_raw" Decode.string <| \range ->
    Field.attempt "rarity" Decode.string <| \rarity ->
    Field.attempt "reflex_save" Decode.int <| \ref ->
    Field.attempt "region" Decode.string <| \region->
    Field.attempt "reload_raw" Decode.string <| \reload ->
    Field.attempt "required_abilities" Decode.string <| \requiredAbilities ->
    Field.attempt "requirement_markdown" Decode.string <| \requirements ->
    Field.attempt "resistance" damageTypeValuesDecoder <| \resistanceValues ->
    Field.attempt "resistance_markdown" Decode.string <| \resistances ->
    Field.attempt "saving_throw_markdown" Decode.string <| \savingThrow ->
    Field.attempt "saving_throw_proficiency" stringListDecoder <| \savingThrowProficiencies ->
    Field.attempt "school" Decode.string <| \school ->
    Field.attempt "secondary_casters_raw" Decode.string <| \secondaryCasters ->
    Field.attempt "secondary_check_markdown" Decode.string <| \secondaryChecks ->
    Field.attempt "sense_markdown" Decode.string <| \senses ->
    Field.attempt "size" stringListDecoder <| \sizes ->
    Field.attempt "skill_markdown" Decode.string <| \skills ->
    Field.attempt "skill_proficiency" stringListDecoder <| \skillProficiencies ->
    Field.attempt "source_markdown" Decode.string <| \sources ->
    Field.attempt "speed" speedTypeValuesDecoder <| \speedValues ->
    Field.attempt "speed_markdown" Decode.string <| \speed ->
    Field.attempt "speed_penalty" Decode.string <| \speedPenalty ->
    Field.attempt "spell_list" Decode.string <| \spellList ->
    Field.attempt "spoilers" Decode.string <| \spoilers ->
    Field.attempt "stage_markdown" Decode.string <| \stages ->
    Field.attempt "strength" Decode.int <| \strength ->
    Field.attempt "strongest_save" stringListDecoder <| \strongestSaves ->
    Field.attempt "summary" Decode.string <| \summary ->
    Field.attempt "target_markdown" Decode.string <| \targets ->
    Field.attempt "tradition_markdown" Decode.string <| \traditions ->
    Field.attempt "trait_markdown" Decode.string <| \traits ->
    Field.attempt "trigger_markdown" Decode.string <| \trigger ->
    Field.attempt "usage" Decode.string <| \usage ->
    Field.attempt "vision" Decode.string <| \vision ->
    Field.attempt "weakest_save" stringListDecoder <| \weakestSaves ->
    Field.attempt "weakness" damageTypeValuesDecoder <| \weaknessValues ->
    Field.attempt "weakness_markdown" Decode.string <| \weaknesses ->
    Field.attempt "weapon_category" Decode.string <| \weaponCategory ->
    Field.attempt "weapon_group_markdown" Decode.string <| \weaponGroup ->
    Field.attempt "weapon_type" Decode.string <| \weaponType ->
    Field.attempt "will_save" Decode.int <| \will ->
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
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , ammunition = ammunition
        , anathema = anathema
        , archetype = archetype
        , area = area
        , areasOfConcern = areaOfConcern
        , armorCategory = armorCategory
        , armorGroup = armorGroup
        , aspect = aspect
        , attackProficiencies = Maybe.withDefault [] attackProficiencies
        , breadcrumbs = breadcrumbs
        , bloodlines = bloodlines
        , bulk = bulk
        , charisma = charisma
        , checkPenalty = checkPenalty
        , clericSpells = clericSpell
        , components = Maybe.withDefault [] components
        , constitution = constitution
        , cost = cost
        , creatureFamily = creatureFamily
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
        , edict = edict
        , familiarAbilities = Maybe.withDefault [] familiarAbilities
        , favoredWeapons = favoredWeapons
        , feats = feats
        , fort = fort
        , followerAlignments = Maybe.withDefault [] followerAlignments
        , frequency = frequency
        , hands = hands
        , hardness = hardness
        , heighten = Maybe.withDefault [] heighten
        , hp = hp
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
        , rarity = rarity
        , ref = ref
        , region = region
        , reload = reload
        , requiredAbilities = requiredAbilities
        , requirements = requirements
        , resistanceValues = resistanceValues
        , resistances = resistances
        , savingThrow = savingThrow
        , savingThrowProficiencies = Maybe.withDefault [] savingThrowProficiencies
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
        , traditions = traditions
        , traits = traits
        , trigger = trigger
        , usage = usage
        , vision = vision
        , weakestSaves = Maybe.withDefault [] weakestSaves
        , weaknessValues = weaknessValues
        , weaknesses = weaknesses
        , weaponCategory = weaponCategory
        , weaponGroup = weaponGroup
        , weaponType = weaponType
        , will = will
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
                [ if model.showHeader then
                    viewTitle

                  else
                    Html.text ""

                , viewQuery model
                , viewSearchResults model
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


viewQuery : Model -> Html Msg
viewQuery model =
    Html.div
        [ HA.class "column"
        , HA.class "align-stretch"
        , HA.class "limit-width"
        , HA.class "gap-tiny"
        , HA.class "fill-width-with-padding"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "input-container"
            ]
            [ Html.input
                [ HA.autofocus model.autofocus
                , HA.class "query-input"
                , HA.placeholder "Enter search query"
                , HA.type_ "text"
                , HA.value model.query
                , HA.attribute "autocapitalize" "off"
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

          else if not model.autoQueryType && queryCouldBeComplex model.query then
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
                                            [ viewPfsIcon 16 value
                                            , viewTextWithActionIcons (String.Extra.toTitleCase value)
                                            -- , Html.text (String.Extra.toTitleCase value)
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
                , { class = Nothing
                  , label = "Include actions:"
                  , list = boolDictIncluded model.filteredActions
                  , removeMsg = ActionsFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude actions:"
                  , list = boolDictExcluded model.filteredActions
                  , removeMsg = ActionsFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include abilities:"
                  , list = boolDictIncluded model.filteredAbilities
                  , removeMsg = AbilityFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude abilities:"
                  , list = boolDictExcluded model.filteredAbilities
                  , removeMsg = AbilityFilterRemoved
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
                , { class = Nothing
                  , label =
                        if model.filterComponentsOperator then
                            "Include all components:"

                        else
                            "Include any component:"
                  , list = boolDictIncluded model.filteredComponents
                  , removeMsg = ComponentFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude components:"
                  , list = boolDictExcluded model.filteredComponents
                  , removeMsg = ComponentFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include creature families:"
                  , list = boolDictIncluded model.filteredCreatureFamilies
                  , removeMsg = CreatureFamilyFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude creature families:"
                  , list = boolDictExcluded model.filteredCreatureFamilies
                  , removeMsg = CreatureFamilyFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include hands:"
                  , list = boolDictIncluded model.filteredHands
                  , removeMsg = HandFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude hands:"
                  , list = boolDictExcluded model.filteredHands
                  , removeMsg = HandFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include item categories:"
                  , list = boolDictIncluded model.filteredItemCategories
                  , removeMsg = ItemCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude item categories:"
                  , list = boolDictExcluded model.filteredItemCategories
                  , removeMsg = ItemCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include item subcategories:"
                  , list = boolDictIncluded model.filteredItemSubcategories
                  , removeMsg = ItemSubcategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude item subcategories:"
                  , list = boolDictExcluded model.filteredItemSubcategories
                  , removeMsg = ItemSubcategoryFilterRemoved
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
                , { class = Just "trait"
                  , label = "Include rarity:"
                  , list = boolDictIncluded model.filteredRarities
                  , removeMsg = RarityFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Exclude rarity:"
                  , list = boolDictExcluded model.filteredRarities
                  , removeMsg = RarityFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include reload:"
                  , list = boolDictIncluded model.filteredReloads
                  , removeMsg = ReloadFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude reload:"
                  , list = boolDictExcluded model.filteredReloads
                  , removeMsg = ReloadFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include saving throws:"
                  , list = boolDictIncluded model.filteredSavingThrows
                  , removeMsg = SavingThrowFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude saving throws:"
                  , list = boolDictExcluded model.filteredSavingThrows
                  , removeMsg = SavingThrowFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Include schools:"
                  , list = boolDictIncluded model.filteredSchools
                  , removeMsg = SchoolFilterRemoved
                  }
                , { class = Just "trait"
                  , label = "Exclude schools:"
                  , list = boolDictExcluded model.filteredSchools
                  , removeMsg = SchoolFilterRemoved
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
                , { class = Nothing
                  , label = "Include skills:"
                  , list = boolDictIncluded model.filteredSkills
                  , removeMsg = SkillFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude skills:"
                  , list = boolDictExcluded model.filteredSkills
                  , removeMsg = SkillFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include sources:"
                  , list = boolDictIncluded model.filteredSources
                  , removeMsg = SourceFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude sources:"
                  , list = boolDictExcluded model.filteredSources
                  , removeMsg = SourceFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include source categories:"
                  , list = boolDictIncluded model.filteredSourceCategories
                  , removeMsg = SourceCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude source categories:"
                  , list = boolDictExcluded model.filteredSourceCategories
                  , removeMsg = SourceCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include strongest saves:"
                  , list = boolDictIncluded model.filteredStrongestSaves
                  , removeMsg = StrongestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude strongest saves:"
                  , list = boolDictExcluded model.filteredStrongestSaves
                  , removeMsg = StrongestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weakest saves:"
                  , list = boolDictIncluded model.filteredWeakestSaves
                  , removeMsg = WeakestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weakest saves:"
                  , list = boolDictExcluded model.filteredWeakestSaves
                  , removeMsg = WeakestSaveFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weapon categories:"
                  , list = boolDictIncluded model.filteredWeaponCategories
                  , removeMsg = WeaponCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weapon categories:"
                  , list = boolDictExcluded model.filteredWeaponCategories
                  , removeMsg = WeaponCategoryFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weapon groups:"
                  , list = boolDictIncluded model.filteredWeaponGroups
                  , removeMsg = WeaponGroupFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weapon groups:"
                  , list = boolDictExcluded model.filteredWeaponGroups
                  , removeMsg = WeaponGroupFilterRemoved
                  }
                , { class = Nothing
                  , label = "Include weapon types:"
                  , list = boolDictIncluded model.filteredWeaponTypes
                  , removeMsg = WeaponTypeFilterRemoved
                  }
                , { class = Nothing
                  , label = "Exclude weapon types:"
                  , list = boolDictExcluded model.filteredWeaponTypes
                  , removeMsg = WeaponTypeFilterRemoved
                  }
                , { class = Nothing
                  , label = "Spoilers:"
                  , list =
                        if model.filterSpoilers then
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
            (mergeFromToValues model
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
        (List.filterMap
            (\( type_, filterView ) ->
                if List.member type_ model.hideFilters then
                    Nothing

                else
                    Just filterView
            )
            [ ( "type"
              , viewFoldableOptionBox
                    model
                    "Query type"
                    queryTypeMeasureWrapperId
                    (viewQueryType model)
              )
            , ( "abilities"
              , viewFoldableOptionBox
                    model
                    "Filter abilities / ability boosts"
                    filterAbilitiesMeasureWrapperId
                    (viewFilterAbilities model)
              )
            , ( "alignments"
              , viewFoldableOptionBox
                    model
                    "Filter alignments"
                    filterAlignmentsMeasureWrapperId
                    (viewFilterAlignments model)
              )
            , ( "creatures"
              , viewFoldableOptionBox
                    model
                    "Filter creatures"
                    filterCreaturesMeasureWrapperId
                    (viewFilterCreatures model)
              )
            , ( "items"
              , viewFoldableOptionBox
                    model
                    "Filter item categories"
                    filterItemCategoriesMeasureWrapperId
                    (viewFilterItemCategories model)
              )
            , ( "pfs"
              , viewFoldableOptionBox
                    model
                    "Filter PFS status"
                    filterPfsMeasureWrapperId
                    (viewFilterPfs model)
              )
            , ( "rarities"
              , viewFoldableOptionBox
                    model
                    "Filter rarities"
                    filterRaritiesMeasureWrapperId
                    (viewFilterRarities model)
              )
            , ( "sizes"
              , viewFoldableOptionBox
                    model
                    "Filter sizes"
                    filterSizesMeasureWrapperId
                    (viewFilterSizes model)
              )
            , ( "skills"
              , viewFoldableOptionBox
                    model
                    "Filter skills"
                    filterSkillsMeasureWrapperId
                    (viewFilterSkills model)
              )
            , ( "sources"
              , viewFoldableOptionBox
                    model
                    "Filter sources & spoilers"
                    filterSourcesMeasureWrapperId
                    (viewFilterSources model)
              )
            , ( "spells"
              , viewFoldableOptionBox
                    model
                    "Filter spells"
                    filterSpellsMeasureWrapperId
                    (viewFilterSpells model)
              )
            , ( "traits"
              , viewFoldableOptionBox
                    model
                    "Filter traits"
                    filterTraitsMeasureWrapperId
                    (viewFilterTraits model)
              )
            , ( "types"
              , viewFoldableOptionBox
                    model
                    "Filter types"
                    filterTypesMeasureWrapperId
                    (viewFilterTypes model)
              )
            , ( "weapons"
              , viewFoldableOptionBox
                    model
                    "Filter weapons"
                    filterWeaponsMeasureWrapperId
                    (viewFilterWeapons model)
              )
            , ( "values"
              , viewFoldableOptionBox
                    model
                    "Filter numeric values"
                    filterValuesMeasureWrapperId
                    (viewFilterValues model)
              )
            , ( "display"
              , viewFoldableOptionBox
                    model
                    "Result display"
                    resultDisplayMeasureWrapperId
                    (viewResultDisplay model)
              )
            , ( "sort"
              , viewFoldableOptionBox
                    model
                    "Sort results"
                    sortResultsMeasureWrapperId
                    (viewSortResults model)
              )
            ]
        )


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
    let
        currentQuery : String
        currentQuery =
            currentQueryAsComplex model
    in
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = model.queryType == Standard
            , enabled = not model.autoQueryType
            , name = "query-type"
            , onInput = QueryTypeSelected Standard
            , text = "Standard"
            }
        , viewRadioButton
            { checked = model.queryType == ElasticsearchQueryString
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
        [ Html.text "The standard query type behaves like most search engines, searching on keywords. The complex query type instead allows you to write queries using Elasticsearch Query String syntax. The general idea is that you can search in specific fields by searching "
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


filterFields : Model -> List ( String, Dict String Bool, Bool )
filterFields model =
    [ ( "ability", model.filteredAbilities, False )
    , ( "actions.keyword", model.filteredActions, False )
    , ( "alignment", model.filteredAlignments, False )
    , ( "component", model.filteredComponents, model.filterComponentsOperator )
    , ( "creature_family", model.filteredCreatureFamilies, False )
    , ( "hands.keyword", model.filteredHands, False )
    , ( "item_category", model.filteredItemCategories, False )
    , ( "item_subcategory", model.filteredItemSubcategories, False )
    , ( "pfs", model.filteredPfs, False )
    , ( "rarity", model.filteredRarities, False )
    , ( "reload_raw.keyword", model.filteredReloads, False )
    , ( "saving_throw", model.filteredSavingThrows, False )
    , ( "school", model.filteredSchools, False )
    , ( "size", model.filteredSizes, False )
    , ( "skill", model.filteredSkills, False )
    , ( "source", model.filteredSources, False )
    , ( "source_category", model.filteredSourceCategories, False )
    , ( "strongest_save", model.filteredStrongestSaves, False )
    , ( "tradition", model.filteredTraditions, model.filterTraditionsOperator )
    , ( "trait", model.filteredTraits, model.filterTraitsOperator )
    , ( "type", model.filteredTypes, False )
    , ( "weakest_save", model.filteredWeakestSaves, False )
    , ( "weapon_category", model.filteredWeaponCategories, False )
    , ( "weapon_group", model.filteredWeaponGroups, False )
    , ( "weapon_type", model.filteredWeaponTypes, False )
    ]


mergeFromToValues : Model -> List ( String, Maybe String, Maybe String )
mergeFromToValues model =
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
        model.filteredFromValues
        model.filteredToValues
        []


currentQueryAsComplex : Model -> String
currentQueryAsComplex model =
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
    [ filterFields model
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
        (mergeFromToValues model)
    ]
        |> List.concat
        |> String.join " "


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
        (case model.aggregations of
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
                            , viewFilterIcon (Dict.get type_ model.filteredTypes)
                            ]
                    )
                    (List.filter
                        (String.toLower >> String.contains (String.toLower model.searchTypes))
                        (List.sort aggregations.types)
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
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
            , enabled = True
            , name = "filter-traits"
            , onInput = FilterTraitsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not model.filterTraitsOperator
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
        (case model.aggregations of
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
                            , viewFilterIcon (Dict.get trait model.filteredTraits)
                            ]
                    )
                    (aggregations.traits
                        |> List.filter (\trait -> not (List.member trait (List.map Tuple.first Data.alignments)))
                        |> List.filter (\trait -> not (List.member trait Data.sizes))
                        |> List.filter (String.toLower >> String.contains (String.toLower model.searchTraits))
                        |> List.sort
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterSpells : Model -> List (Html Msg)
viewFilterSpells model =
    [ Html.h4
        []
        [ Html.text "Filter actions / cast time" ]
    , Html.button
        [ HA.style "align-self" "flex-start"
        , HE.onClick RemoveAllActionsFiltersPressed
        ]
        [ Html.text "Reset selection" ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case model.aggregations of
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
                            , viewFilterIcon (Dict.get actions model.filteredActions)
                            ]
                    )
                    (List.sort aggregations.actions)

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )

    , Html.h4
        []
        [ Html.text "Filter casting components" ]
    , Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllComponentFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = model.filterComponentsOperator
            , enabled = True
            , name = "filter-components"
            , onInput = FilterComponentsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not model.filterComponentsOperator
            , enabled = True
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
            [ "focus"
            , "material"
            , "somatic"
            , "verbal"
            ]
        )

    , Html.h4
        []
        [ Html.text "Filter magic schools" ]
    , Html.button
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
                    , viewFilterIcon (Dict.get school model.filteredSchools)
                    ]
            )
            Data.magicSchools
        )

    , Html.h4
        []
        [ Html.text "Filter saving throws" ]
    , Html.button
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
                    , viewFilterIcon (Dict.get save model.filteredSavingThrows)
                    ]
            )
            Data.saves
        )

    , Html.h4
        []
        [ Html.text "Filter traditions / spell lists" ]
    , Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HE.onClick RemoveAllTraditionFiltersPressed ]
            [ Html.text "Reset selection" ]
        , viewRadioButton
            { checked = model.filterTraditionsOperator
            , enabled = True
            , name = "filter-traditions"
            , onInput = FilterTraditionsOperatorChanged True
            , text = "Include all (AND)"
            }
        , viewRadioButton
            { checked = not model.filterTraditionsOperator
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
                    , viewFilterIcon (Dict.get tradition model.filteredTraditions)
                    ]
            )
            Data.traditionsAndSpellLists
        )
    ]


viewFilterAbilities : Model -> List (Html Msg)
viewFilterAbilities model =
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
                    , viewFilterIcon (Dict.get ability model.filteredAbilities)
                    ]
            )
            Data.abilities
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


viewFilterCreatures : Model -> List (Html Msg)
viewFilterCreatures model =
    [ Html.h4
        []
        [ Html.text "Filter strongest save" ]
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
                    , viewFilterIcon (Dict.get (String.toLower save) model.filteredStrongestSaves)
                    ]
            )
            Data.saves
        )

    , Html.h4
        []
        [ Html.text "Filter weakest save" ]
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
                    , viewFilterIcon (Dict.get (String.toLower save) model.filteredWeakestSaves)
                    ]
            )
            Data.saves
        )

    , Html.h4
        []
        [ Html.text "Filter creature families" ]
    , Html.button
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
            , HA.value model.searchCreatureFamilies
            , HA.type_ "text"
            , HE.onInput SearchCreatureFamiliesChanged
            ]
            []
        , if String.isEmpty model.searchCreatureFamilies then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchCreatureFamiliesChanged "")
                ]
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case model.aggregations of
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
                            , viewFilterIcon (Dict.get (String.toLower creatureFamily) model.filteredCreatureFamilies)
                            ]
                    )
                    (aggregations.creatureFamilies
                        |> List.filter (String.toLower >> String.contains (String.toLower model.searchCreatureFamilies))
                        |> List.sort
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    ]


viewFilterItemCategories : Model -> List (Html Msg)
viewFilterItemCategories model =
    [ Html.h4
        []
        [ Html.text "Filter item categories" ]
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
            , HA.value model.searchItemCategories
            , HA.type_ "text"
            , HE.onInput SearchItemCategoriesChanged
            ]
            []
        , if String.isEmpty model.searchItemCategories then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchItemCategoriesChanged "")
                ]
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case model.aggregations of
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
                            , viewFilterIcon (Dict.get category model.filteredItemCategories)
                            ]
                    )
                    (aggregations.itemCategories
                        |> List.filter (String.toLower >> String.contains (String.toLower model.searchItemCategories))
                        |> List.sort
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )
    , Html.h4
        []
        [ Html.text "Filter item subcategories" ]
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
            , HA.value model.searchItemSubcategories
            , HA.type_ "text"
            , HE.onInput SearchItemSubcategoriesChanged
            ]
            []
        , if String.isEmpty model.searchItemSubcategories then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchItemSubcategoriesChanged "")
                ]
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case model.aggregations of
            Just (Ok aggregations) ->
                List.map
                    (\subcategory ->
                        let
                            filteredCategory : Maybe Bool
                            filteredCategory =
                                Maybe.Extra.or
                                    (case boolDictIncluded model.filteredItemCategories of
                                        [] ->
                                            Nothing

                                        categories ->
                                            if List.member subcategory.category categories then
                                                Nothing

                                            else
                                                Just False
                                    )
                                    (case boolDictExcluded model.filteredItemCategories of
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
                                    (Dict.get subcategory.name model.filteredItemSubcategories)
                                    filteredCategory
                                )
                            ]
                    )
                    (aggregations.itemSubcategories
                        |> List.filter
                            (.name
                                >> String.toLower
                                >> String.contains (String.toLower model.searchItemSubcategories)
                            )
                        |> List.sortBy .name
                    )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
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
                    [ viewPfsIcon 16 pfs
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


viewFilterRarities : Model -> List (Html Msg)
viewFilterRarities model =
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
        (case model.aggregations of
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
                            , viewFilterIcon (Dict.get rarity model.filteredRarities)
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
            Data.sizes
        )
    ]


viewFilterSkills : Model -> List (Html Msg)
viewFilterSkills model =
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
                    , viewFilterIcon (Dict.get skill model.filteredSkills)
                    ]
            )
            Data.skills
        )
    ]


viewFilterSources : Model -> List (Html Msg)
viewFilterSources model =
    [ Html.h4
        []
        [ Html.text "Filter spoilers" ]
    , viewCheckbox
        { checked = model.filterSpoilers
        , onCheck = FilterSpoilersChanged
        , text = "Hide results with spoilers"
        }
    , Html.h4
        []
        [ Html.text "Filter source categories" ]
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
                    , viewFilterIcon (Dict.get category model.filteredSourceCategories)
                    ]
            )
            Data.sourceCategories
        )
    , Html.h4
        []
        [ Html.text "Filter sources" ]
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
            , HA.value model.searchSources
            , HA.type_ "text"
            , HE.onInput SearchSourcesChanged
            ]
            []
        , if String.isEmpty model.searchSources then
            Html.text ""

          else
            Html.button
                [ HA.class "input-button"
                , HE.onClick (SearchSourcesChanged "")
                ]
                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times ]
        ]
    , Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (case ( model.sourcesAggregation, model.aggregations ) of
            ( Just (Ok allSources), Just (Ok { sources }) ) ->
                (List.map
                    (\source ->
                        let
                            filteredCategory : Maybe Bool
                            filteredCategory =
                                Maybe.Extra.or
                                    (case boolDictIncluded model.filteredSourceCategories of
                                        [] ->
                                            Nothing

                                        categories ->
                                            if List.member source.category categories then
                                                Nothing

                                            else
                                                Just False
                                    )
                                    (case boolDictExcluded model.filteredSourceCategories of
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
                                    (Dict.get source.name model.filteredSources)
                                    filteredCategory
                                )
                            ]
                    )
                    (allSources
                        |> List.filter
                            (.name
                                >> String.toLower
                                >> String.contains (String.toLower model.searchSources)
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


viewFilterWeapons : Model -> List (Html Msg)
viewFilterWeapons model =
    [ Html.h4
        []
        [ Html.text "Filter weapon categories" ]
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
                    , viewFilterIcon (Dict.get category model.filteredWeaponCategories)
                    ]
            )
            Data.weaponCategories
        )

    , Html.h4
        []
        [ Html.text "Filter weapon groups" ]
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
        (case model.aggregations of
            Just (Ok { weaponGroups })->
                (List.map
                    (\group ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (WeaponGroupFilterAdded group)
                            ]
                            [ Html.text (String.Extra.toTitleCase group)
                            , viewFilterIcon (Dict.get group model.filteredWeaponGroups)
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
        [ Html.text "Filter weapon types" ]
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
                    , viewFilterIcon (Dict.get type_ model.filteredWeaponTypes)
                    ]
            )
            Data.weaponTypes
        )

    , Html.h4
        []
        [ Html.text "Filter hands" ]
    , Html.button
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
        (case model.aggregations of
            Just (Ok { hands })->
                (List.map
                    (\hand ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (HandFilterAdded hand)
                            ]
                            [ Html.text hand
                            , viewFilterIcon (Dict.get hand model.filteredHands)
                            ]
                    )
                    (List.sort hands)
                )

            Just (Err _) ->
                []

            Nothing ->
                [ viewScrollboxLoader ]
        )

    , Html.h4
        []
        [ Html.text "Filter reload" ]
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
        (case model.aggregations of
            Just (Ok { reloads })->
                (List.map
                    (\reload ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HE.onClick (ReloadFilterAdded reload)
                            ]
                            [ Html.text reload
                            , viewFilterIcon (Dict.get reload model.filteredReloads)
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
                            , HA.value model.selectedFilterAbility
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
                        , HA.class "align-center"
                        ]
                        [ Html.select
                            [ HA.class "input-container"
                            , HA.value model.selectedFilterSpeed
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
                                            ("speed." ++ model.selectedFilterSpeed)
                                            model.filteredFromValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredFromValueChanged
                                        ("speed." ++ model.selectedFilterSpeed)
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
                                            ("speed." ++ model.selectedFilterSpeed)
                                            model.filteredToValues
                                        )
                                    )
                                , HE.onInput
                                    (FilteredToValueChanged
                                        ("speed." ++ model.selectedFilterSpeed)
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
                            , HA.value model.selectedFilterResistance
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
                            , HA.value model.selectedFilterWeakness
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


viewResultDisplay : Model -> List (Html Msg)
viewResultDisplay model =
    [ Html.div
        [ HA.class "row"
        , HA.class "align-baseline"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = model.resultDisplay == List
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged List
            , text = "List"
            }
        , viewRadioButton
            { checked = model.resultDisplay == Table
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged Table
            , text = "Table"
            }
        ]
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        (if model.resultDisplay == Table then
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
                    , Html.div
                        [ HA.class "scrollbox"
                        , HA.class "column"
                        , HA.class "gap-small"
                        ]
                        (List.indexedMap
                            (\index column ->
                                Html.div
                                    [ HA.class "row"
                                    , HA.class "gap-small"
                                    , HA.class "align-center"
                                    ]
                                    [ Html.button
                                        [ HE.onClick (TableColumnRemoved column)
                                        ]
                                        [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times
                                        ]
                                    , Html.button
                                        [ HA.disabled (index == 0)
                                        , HE.onClick (TableColumnMoved index (index - 1))
                                        ]
                                        [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronUp
                                        ]
                                    , Html.button
                                        [ HA.disabled (index + 1 == List.length model.tableColumns)
                                        , HE.onClick (TableColumnMoved index (index + 1))
                                        ]
                                        [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronDown
                                        ]
                                    , Html.text (sortFieldToLabel column)
                                    ]
                            )
                            model.tableColumns
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
                            (viewResultDisplayColumn model)
                            Data.tableColumns
                        )
                    ]
                ]
            , Html.div
                []
                [ Html.text "Predefined column configurations" ]
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
            ]

         else
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
        )
    ]


viewResultDisplayColumn : Model -> String -> List (Html Msg)
viewResultDisplayColumn model column =
    [ Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        , HA.class "align-center"
        ]
        [ Html.button
            [ HAE.attributeIf (List.member column model.tableColumns) (HA.class "active")
            , if List.member column model.tableColumns then
                HE.onClick (TableColumnRemoved column)

              else
                HE.onClick (TableColumnAdded column)
            ]
            [ FontAwesome.Icon.viewIcon FontAwesome.Solid.plus
            ]

        , Html.text (String.Extra.humanize column)
        ]

    , case column of
        "resistance" ->
            viewResultDisplayColumnWithSelect
                model
                { column = column
                , onInput = ColumnResistanceChanged
                , selected = model.selectedColumnResistance
                , types = Data.damageTypes
                }

        "speed" ->
            viewResultDisplayColumnWithSelect
                model
                { column = column
                , onInput = ColumnSpeedChanged
                , selected = model.selectedColumnSpeed
                , types = Data.speedTypes
                }

        "weakness" ->
            viewResultDisplayColumnWithSelect
                model
                { column = column
                , onInput = ColumnWeaknessChanged
                , selected = model.selectedColumnWeakness
                , types = Data.damageTypes
                }

        _ ->
            Html.text ""
    ]


viewResultDisplayColumnWithSelect :
    Model
    -> { column : String
       , onInput : String -> Msg
       , selected : String
       , types : List String
       }
    -> Html Msg
viewResultDisplayColumnWithSelect model { column, onInput, selected, types } =
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
            [ HA.disabled (List.member columnWithType model.tableColumns)
            , HE.onClick (TableColumnAdded columnWithType)
            ]
            [ FontAwesome.Icon.viewIcon FontAwesome.Solid.plus
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


viewSortResults : Model -> List (Html Msg)
viewSortResults model =
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
                                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.times
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
                                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronUp
                                ]
                            , Html.button
                                [ HA.disabled (index + 1 == List.length model.sort)
                                , HE.onClick (SortOrderChanged index (index + 1))
                                ]
                                [ FontAwesome.Icon.viewIcon FontAwesome.Solid.chevronDown
                                ]
                            , Html.text (sortFieldToLabel field)
                            ]
                    )
                    model.sort
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
                    (viewSortResultsField model)
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


viewSortResultsField : Model -> String -> Html Msg
viewSortResultsField model field =
    case field of
        "resistance" ->
            viewSortResultsFieldWithSelect
                model
                { field = field
                , onInput = SortResistanceChanged
                , selected = model.selectedSortResistance
                , types = Data.damageTypes
                }

        "speed" ->
            viewSortResultsFieldWithSelect
                model
                { field = field
                , onInput = SortSpeedChanged
                , selected = model.selectedSortSpeed
                , types = Data.speedTypes
                }

        "weakness" ->
            viewSortResultsFieldWithSelect
                model
                { field = field
                , onInput = SortWeaknessChanged
                , selected = model.selectedSortWeakness
                , types = Data.damageTypes
                }

        _ ->
            Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                ]
                (List.append
                    (viewSortButtons model field)
                    [ Html.text (String.Extra.humanize field)
                    ]
                )


viewSortResultsFieldWithSelect :
    Model
    -> { field : String
       , onInput : String -> Msg
       , selected : String
       , types : List String
       }
    -> Html Msg
viewSortResultsFieldWithSelect model { field, onInput, selected, types } =
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
            (viewSortButtons model fieldWithType)
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


viewSortButtons : Model -> String -> List (Html Msg)
viewSortButtons model field =
    [ Html.button
        [ HE.onClick
            (if List.member ( field, Asc ) model.sort then
                (SortRemoved field)

             else
                (SortAdded field Asc)
            )
        , HAE.attributeIf (List.member ( field, Asc ) model.sort) (HA.class "active")
        , HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ Html.text "Asc"
        , getSortIcon field (Just Asc)
        ]
    , Html.button
        [ HE.onClick
            (if List.member ( field, Desc ) model.sort then
                (SortRemoved field)

             else
                (SortAdded field Desc)
            )
        , HAE.attributeIf (List.member ( field, Desc ) model.sort) (HA.class "active")
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
                    ]
                    [ case total of
                        Just 10000 ->
                            Html.text ("Showing " ++ String.fromInt resultCount ++ " of 10000+ results")

                        Just count ->
                            Html.text ("Showing " ++ String.fromInt resultCount ++ " of " ++ String.fromInt count ++ " results")

                        _ ->
                            Html.text ""
                    ]
              ]

            , if model.resultDisplay == Table then
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
                        [ viewSearchResultGrid model

                        , case List.Extra.last model.searchResults of
                            Just (Err (Http.BadStatus 400)) ->
                                Html.h2
                                    []
                                    [ Html.text "Error: Failed to parse query" ]

                            Just (Err _) ->
                                Html.h2
                                    []
                                    [ Html.text "Error: Search failed" ]

                            _ ->
                                Html.text ""

                        , if Maybe.Extra.isJust model.tracker then
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
                                        [ HE.onClick LoadMorePressed
                                        ]
                                        [ Html.text ("Load " ++ String.fromInt model.pageSize ++ " more") ]

                                  else
                                    Html.text ""

                                , if remaining > 0 && remaining < 1000 then
                                    Html.button
                                        [ HE.onClick LoadRemainingPressed
                                        ]
                                        [ Html.text ("Load remaining " ++ String.fromInt remaining) ]

                                  else
                                    Html.text ""
                                ]
                        ]
                    ]
                ]

              else
                [ List.map
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

                  else
                    [ Html.div
                        [ HA.class "row"
                        , HA.class "gap-medium"
                        , HA.style "justify-content" "center"
                        ]
                        [ if remaining > model.pageSize then
                            Html.button
                                [ HE.onClick LoadMorePressed
                                ]
                                [ Html.text ("Load " ++ String.fromInt model.pageSize ++ " more") ]

                          else
                            Html.text ""

                        , if remaining > 0 && remaining < 1000 then
                            Html.button
                                [ HE.onClick LoadRemainingPressed
                                ]
                                [ Html.text ("Load remaining " ++ String.fromInt remaining) ]

                          else
                            Html.text ""
                        ]
                    ]

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
        , HA.class "limit-width"
        , HA.class "fill-width-with-padding"
        ]
        [ Html.h2
            [ HA.class "title" ]
            [ Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                ]
                [ viewPfsIconWithLink 25 (Maybe.withDefault "" hit.source.pfs)
                , Html.a
                    [ HA.href (getUrl model hit.source)
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

            , viewMarkdown hit.source.searchMarkdown
        ]


viewSearchResultGrid : Model -> Html Msg
viewSearchResultGrid model =
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
                                        (model.sort
                                            |> List.Extra.find (Tuple.first >> (==) column)
                                            |> Maybe.map Tuple.second
                                        )
                                    ]

                              else
                                Html.text (sortFieldToLabel column)
                            ]
                    )
                    ("name" :: model.tableColumns)
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
                                            ("name" :: model.tableColumns)
                                        )
                                )
                                r.hits

                        Err _ ->
                            []
                )
                model.searchResults
                |> List.concat
            )
        ]


viewSearchResultGridCell : Model -> Hit Document -> String -> Html msg
viewSearchResultGridCell model hit column =
    Html.td
        [ HAE.attributeIf (column == "name") (HA.class "sticky-left")
        ]
        [ case String.split "." column of
            [ "ability" ] ->
                hit.source.abilities
                    |> String.join ", "
                    |> Html.text

            [ "ability_boost" ] ->
                hit.source.abilities
                    |> String.join ", "
                    |> Html.text

            [ "ability_flaw" ] ->
                hit.source.abilityFlaws
                    |> String.join ", "
                    |> Html.text

            [ "ability_type" ] ->
                hit.source.abilityType
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "ac" ] ->
                hit.source.ac
                    |> Maybe.map String.fromInt
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "actions" ] ->
                hit.source.actions
                    |> Maybe.withDefault ""
                    |> viewTextWithActionIcons

            [ "alignment" ] ->
                hit.source.alignment
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "anathema" ] ->
                hit.source.anathema
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "archetype" ] ->
                hit.source.archetype
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "area" ] ->
                hit.source.area
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "area_of_concern" ] ->
                hit.source.areasOfConcern
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "armor_category" ] ->
                hit.source.armorCategory
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "armor_group" ] ->
                hit.source.armorGroup
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "aspect" ] ->
                hit.source.aspect
                    |> Maybe.withDefault ""
                    |> String.Extra.toTitleCase
                    |> Html.text

            [ "attack_proficiency" ] ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    ]
                    (List.map
                        (\prof ->
                            Html.div
                                []
                                [ Html.text prof ]
                        )
                        hit.source.attackProficiencies
                    )

            [ "bloodline" ] ->
                hit.source.bloodlines
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "bulk" ] ->
                hit.source.bulk
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "charisma" ] ->
                hit.source.charisma
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "check_penalty" ] ->
                hit.source.checkPenalty
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "cleric_spell" ] ->
                hit.source.clericSpells
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "creature_family" ] ->
                hit.source.creatureFamily
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "component" ] ->
                hit.source.components
                    |> List.map String.Extra.toTitleCase
                    |> String.join ", "
                    |> Html.text

            [ "constitution" ] ->
                hit.source.constitution
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "cost" ] ->
                hit.source.cost
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "deity" ] ->
                hit.source.deities
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "deity_category" ] ->
                hit.source.deityCategory
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "damage" ] ->
                hit.source.damage
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "defense_proficiency" ] ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    ]
                    (List.map
                        (\prof ->
                            Html.div
                                []
                                [ Html.text prof ]
                        )
                        hit.source.defenseProficiencies
                    )

            [ "dexterity" ] ->
                hit.source.dexterity
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "dex_cap" ] ->
                hit.source.dexCap
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "divine_font" ] ->
                hit.source.divineFonts
                    |> List.map String.Extra.toTitleCase
                    |> String.join " or "
                    |> Html.text

            [ "domain" ] ->
                hit.source.domains
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "duration" ] ->
                hit.source.duration
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "edict" ] ->
                hit.source.edict
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "favored_weapon" ] ->
                hit.source.favoredWeapons
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "feat" ] ->
                hit.source.feats
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "follower_alignment" ] ->
                hit.source.followerAlignments
                    |> String.join ", "
                    |> Html.text

            [ "fortitude" ] ->
                hit.source.fort
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "frequency" ] ->
                hit.source.frequency
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "hands" ] ->
                hit.source.hands
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "hardness" ] ->
                hit.source.hardness
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "heighten" ] ->
                hit.source.heighten
                    |> String.join ", "
                    |> Html.text

            [ "hp" ] ->
                hit.source.hp
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "immunity" ] ->
                hit.source.immunities
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "intelligence" ] ->
                hit.source.intelligence
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "item_category" ] ->
                hit.source.itemCategory
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "item_subcategory" ] ->
                hit.source.itemSubcategory
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "language" ] ->
                hit.source.languages
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "lesson" ] ->
                hit.source.lessons
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "level" ] ->
                hit.source.level
                    |> Maybe.map String.fromInt
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "mystery" ] ->
                hit.source.mysteries
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "name" ] ->
                Html.a
                    [ HA.href (getUrl model hit.source)
                    , HA.target "_blank"
                    ]
                    [ Html.text hit.source.name
                    ]

            [ "onset" ] ->
                hit.source.onset
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "patron_theme" ] ->
                hit.source.patronThemes
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "perception" ] ->
                hit.source.perception
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "perception_proficiency" ] ->
                hit.source.perceptionProficiency
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "pfs" ] ->
                hit.source.pfs
                    |> Maybe.withDefault ""
                    |> viewPfsIconWithLink 20

            [ "plane_category" ] ->
                hit.source.planeCategory
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "prerequisite" ] ->
                hit.source.prerequisites
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "price" ] ->
                hit.source.price
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "primary_check" ] ->
                hit.source.primaryCheck
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "range" ] ->
                hit.source.range
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "rarity" ] ->
                hit.source.rarity
                    |> Maybe.map (String.Extra.toTitleCase)
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "reflex" ] ->
                hit.source.ref
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "region" ] ->
                hit.source.region
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "reload" ] ->
                hit.source.reload
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "requirement" ] ->
                hit.source.requirements
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "resistance" ] ->
                hit.source.resistances
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "resistance", type_ ] ->
                hit.source.resistanceValues
                    |> Maybe.andThen (getDamageTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "saving_throw" ] ->
                hit.source.savingThrow
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "saving_throw_proficiency" ] ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    ]
                    (List.map
                        (\prof ->
                            Html.div
                                []
                                [ Html.text prof ]
                        )
                        hit.source.savingThrowProficiencies
                    )

            [ "school" ] ->
                hit.source.school
                    |> Maybe.map (String.Extra.toTitleCase)
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "secondary_casters" ] ->
                hit.source.secondaryCasters
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "secondary_check" ] ->
                hit.source.secondaryChecks
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "sense" ] ->
                hit.source.senses
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "size" ] ->
                hit.source.sizes
                    |> String.join ", "
                    |> Html.text

            [ "skill" ] ->
                hit.source.skills
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "skill_proficiency" ] ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    ]
                    (List.map
                        (\prof ->
                            Html.div
                                []
                                [ Html.text prof ]
                        )
                        hit.source.skillProficiencies
                    )

            [ "source" ] ->
                hit.source.sources
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "speed" ] ->
                hit.source.speed
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "speed", type_ ] ->
                hit.source.speedValues
                    |> Maybe.andThen (getSpeedTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "speed_penalty" ] ->
                hit.source.speedPenalty
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "spoilers" ] ->
                hit.source.spoilers
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "stage" ] ->
                hit.source.stages
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "strength" ] ->
                hit.source.strength
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "strongest_save" ] ->
                hit.source.strongestSaves
                    |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                    |> List.map String.Extra.toTitleCase
                    |> String.join ", "
                    |> Html.text

            [ "summary" ] ->
                hit.source.summary
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "target" ] ->
                hit.source.targets
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "tradition" ] ->
                hit.source.traditions
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "trait" ] ->
                hit.source.traits
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "trigger" ] ->
                hit.source.trigger
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "type" ] ->
                Html.text hit.source.type_

            [ "vision" ] ->
                hit.source.vision
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "weapon_category" ] ->
                hit.source.weaponCategory
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "weapon_group" ] ->
                hit.source.weaponGroup
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "weapon_type" ] ->
                hit.source.weaponType
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "weakest_save" ] ->
                hit.source.weakestSaves
                    |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                    |> List.map String.Extra.toTitleCase
                    |> String.join ", "
                    |> Html.text

            [ "weakness" ] ->
                hit.source.weaknesses
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown

            [ "weakness", type_ ] ->
                hit.source.weaknessValues
                    |> Maybe.andThen (getDamageTypeValue type_)
                    |> Maybe.map String.fromInt
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "will" ] ->
                hit.source.will
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            [ "wisdom" ] ->
                hit.source.wisdom
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""
                    |> Html.text

            _ ->
                Html.text ""
        ]


parseAndViewAsMarkdown : String -> Html msg
parseAndViewAsMarkdown string =
    if String.isEmpty string then
        Html.text ""

    else
        string
            |> Markdown.Parser.parse
            |> Result.map (List.map (Markdown.Block.walk mergeInlines))
            |> Result.mapError (List.map Markdown.Parser.deadEndToString)
            |> viewMarkdown


viewMarkdown : ParsedMarkdownResult -> Html msg
viewMarkdown markdown =
    case markdown of
        Ok blocks ->
            case Markdown.Renderer.render markdownRenderer blocks of
                Ok v ->
                    Html.div
                        [ HA.class "column"
                        , HA.class "gap-small"
                        ]
                        v

                Err err ->
                    Html.text err

        Err errors ->
            Html.div
                [ HA.style "color" "red" ]
                (List.map Html.text errors)


markdownRenderer : Markdown.Renderer.Renderer (Html msg)
markdownRenderer =
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
                , HA.target "_blank"
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

        _ ->
            HAE.empty


getSortIcon : String -> Maybe SortDir -> Html msg
getSortIcon field dir =
    case ( dir, List.Extra.find (Tuple3.first >> (==) field) Data.sortFields ) of
        ( Just Asc, Just ( _, _, True ) ) ->
            FontAwesome.Icon.viewIcon FontAwesome.Solid.sortNumericUp

        ( Just Asc, Just ( _, _, False ) ) ->
            FontAwesome.Icon.viewIcon FontAwesome.Solid.sortAlphaUp


        ( Just Desc, Just ( _, _, True ) ) ->
            FontAwesome.Icon.viewIcon FontAwesome.Solid.sortNumericDownAlt

        ( Just Desc, Just ( _, _, False ) ) ->
            FontAwesome.Icon.viewIcon FontAwesome.Solid.sortAlphaDownAlt

        _ ->
            Html.text ""


viewPfsIcon : Int -> String -> Html msg
viewPfsIcon height pfs =
    case getPfsIconUrl pfs of
        Just url ->
            Html.img
                [ HA.src url
                , HA.style "height" (String.fromInt height ++ "px")
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


capitalizeSource : String -> String
capitalizeSource str =
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
        |> String.replace "Pfs " "PFS "
        |> String.replace "Gm's " "GM's "


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
    , filterAbilitiesMeasureWrapperId
    , filterAlignmentsMeasureWrapperId
    , filterCreaturesMeasureWrapperId
    , filterItemCategoriesMeasureWrapperId
    , filterPfsMeasureWrapperId
    , filterRaritiesMeasureWrapperId
    , filterSizesMeasureWrapperId
    , filterSkillsMeasureWrapperId
    , filterSourcesMeasureWrapperId
    , filterSpellsMeasureWrapperId
    , filterTraitsMeasureWrapperId
    , filterTypesMeasureWrapperId
    , filterValuesMeasureWrapperId
    , filterWeaponsMeasureWrapperId
    , resultDisplayMeasureWrapperId
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


filterAbilitiesMeasureWrapperId : String
filterAbilitiesMeasureWrapperId =
    "filter-abilities-measure-wrapper"


filterAlignmentsMeasureWrapperId : String
filterAlignmentsMeasureWrapperId =
    "filter-alignments-measure-wrapper"


filterCreaturesMeasureWrapperId : String
filterCreaturesMeasureWrapperId =
    "filter-creatures-measure-wrapper"


filterItemCategoriesMeasureWrapperId : String
filterItemCategoriesMeasureWrapperId =
    "filter-item-categories-measure-wrapper"


filterPfsMeasureWrapperId : String
filterPfsMeasureWrapperId =
    "filter-pfs-measure-wrapper"


filterRaritiesMeasureWrapperId : String
filterRaritiesMeasureWrapperId =
    "filter-rarities-measure-wrapper"


filterSizesMeasureWrapperId : String
filterSizesMeasureWrapperId =
    "filter-sizes-measure-wrapper"


filterSkillsMeasureWrapperId : String
filterSkillsMeasureWrapperId =
    "filter-skills-measure-wrapper"


filterSourcesMeasureWrapperId : String
filterSourcesMeasureWrapperId =
    "filter-sources-measure-wrapper"


filterSpellsMeasureWrapperId : String
filterSpellsMeasureWrapperId =
    "filter-spells-measure-wrapper"


filterTraitsMeasureWrapperId : String
filterTraitsMeasureWrapperId =
    "filter-traits-measure-wrapper"


filterValuesMeasureWrapperId : String
filterValuesMeasureWrapperId =
    "filter-values-measure-wrapper"


filterWeaponsMeasureWrapperId : String
filterWeaponsMeasureWrapperId =
    "filter-weapons-measure-wrapper"


resultDisplayMeasureWrapperId : String
resultDisplayMeasureWrapperId =
    "result-display-measure-wrapper"


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

    p {
        margin: 0;
    }

    sup > p {
        display: inline-block;
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

    .external-link {
        color: var(--color-external-link);
        font-style: italic;
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
        border-width: 0;
        color: var(--color-text);
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
        font-variant: var(--element-font-variant);
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


cssBlackbird : String
cssBlackbird =
    """
    .body-container {
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
        --color-inactive-text: #999999;
        --color-table-even: #cbc18f;
        --color-table-odd: #ded7bb;
        --color-table-text: #0f0f0f;
        --color-text: #111111;
        --element-font-variant: small-caps;
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
        --color-external-link: #0000ff;
        --color-subelement-bg: #dbd0bc;
        --color-subelement-text: #111111;
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
        --color-subelement-bg: #769477;
        --color-subelement-text: #111111;
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
        --color-subelement-bg: #f0e6ff;
        --color-subelement-text: #111111;
        --color-inactive-text: #999999;
        --color-table-even: #8471a7;
        --color-table-odd: #6f5f98;
        --color-table-text: #ffffff;
        --color-text: #000000;
        --element-font-variant: small-caps;
    }
    """
