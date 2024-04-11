port module NethysSearch exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Cmd.Extra
import Csv.Encode
import Dict exposing (Dict)
import Dict.Extra
import File.Download
import Http
import Json.Decode as Decode
import Json.Decode.Field as Field
import Json.Encode as Encode
import List.Extra
import Markdown.Block
import Markdown.Parser
import Maybe.Extra
import NethysSearch.Data as Data exposing (..)
import NethysSearch.View as View
import Process
import Random
import Result.Extra
import Set exposing (Set)
import String.Extra
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


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = View.view
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
    ( { alwaysShowFilters = False
      , autofocus = flags.autofocus
      , autoQueryType = False
      , bodySize = { width = 0, height = 0 }
      , browserDateFormat = flags.browserDateFormat
      , dataUrl = flags.dataUrl
      , dateFormat = "default"
      , documentIndex = Dict.empty
      , documents = Dict.empty
      , documentsToFetch = Set.empty
      , elasticUrl = flags.elasticUrl
      , fixedParams = flags.fixedParams
      , groupTraits = False
      , groupedDisplay = Dim
      , groupedShowHeightenable = True
      , groupedShowPfs = True
      , groupedShowRarity = True
      , groupedSort = Alphanum
      , index = ""
      , loadAll = flags.loadAll
      , legacyMode = flags.legacyMode
      , limitTableWidth = False
      , linkPreviewsEnabled = True
      , noUi = flags.noUi
      , openInNewTab = False
      , pageDefaultParams = Dict.empty
      , pageId = flags.pageId
      , pageSize = 50
      , pageSizeDefaults = Dict.empty
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
                { defaultQuery = flags.defaultQuery
                , fixedQueryString = flags.fixedQueryString
                , removeFilters = flags.removeFilters
                }
      , showLegacyFilters = True
      , showResultAdditionalInfo = True
      , showResultIndex = True
      , showResultPfs = True
      , showResultSpoilers = True
      , showResultSummary = True
      , showResultTraits = True
      , sourcesAggregation = Nothing
      , traitAggregations = Nothing
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
        |> addCmd getDocumentIndex
        |> \( model, cmd ) ->
            if model.noUi && model.index /= "" then
                ( model, cmd )

            else
                ( model, cmd )
                    |> searchWithCurrentQuery LoadNew
                    |> addCmd updateTitle
                    |> addCmd getAggregations
                    |> addCmd getSourcesAggregation
                    |> addCmd getTraitAggregations


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

        AlwaysShowFiltersChanged enabled ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | showFilters = True }
                )
                { model | alwaysShowFilters = enabled }
            , saveToLocalStorage
                "always-show-filters"
                (if enabled then "1" else "0")
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

        AttributeFilterAdded attributes ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAttributes = toggleBoolDict attributes searchModel.filteredAttributes }
                )
                model
                |> updateUrlWithSearchParams
            )

        AttributeFilterRemoved attributes ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAttributes = Dict.remove attributes searchModel.filteredAttributes }
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

        DamageTypeFilterAdded component ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredDamageTypes = toggleBoolDict component searchModel.filteredDamageTypes }
                )
                model
                |> updateUrlWithSearchParams
            )

        DamageTypeFilterRemoved component ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredDamageTypes = Dict.remove component searchModel.filteredDamageTypes }
                )
                model
                |> updateUrlWithSearchParams
            )

        DateFormatChanged format ->
            ( { model | dateFormat = format }
            , saveToLocalStorage "date-format" format
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

        DomainFilterAdded component ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredDomains = toggleBoolDict component searchModel.filteredDomains }
                )
                model
                |> updateUrlWithSearchParams
            )

        DomainFilterRemoved component ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredDomains = Dict.remove component searchModel.filteredDomains }
                )
                model
                |> updateUrlWithSearchParams
            )

        ExportAsCsvPressed ->
            ( model
            , model.searchModel.searchResults
                |> List.concatMap
                    (\result ->
                        case result of
                            Ok r ->
                                r.documentIds
                                    |> List.filterMap (\id -> Dict.get id model.documents)
                                    |> List.filterMap Result.toMaybe

                            Err _ ->
                                []
                    )
                |> Csv.Encode.encode
                    { encoder =
                        Csv.Encode.withFieldNames
                            (\document ->
                                List.map
                                    (\column ->
                                        ( column
                                        , View.searchResultTableCellToString model document column
                                        )
                                    )
                                    ("name" :: model.searchModel.tableColumns)
                            )
                    , fieldSeparator = ','
                    }
                |> File.Download.string "table-data.csv" "text/csv"
            )

        ExportAsJsonPressed ->
            ( model
            , model.searchModel.searchResults
                |> List.concatMap
                    (\result ->
                        case result of
                            Ok r ->
                                r.documentIds
                                    |> List.filterMap (\id -> Dict.get id model.documents)
                                    |> List.filterMap Result.toMaybe

                            Err _ ->
                                []
                    )
                |> Encode.list
                    (\document ->
                        List.map
                            (\column ->
                                ( column
                                , View.searchResultTableCellToString model document column
                                    |> Encode.string
                                )
                            )
                            ("name" :: model.searchModel.tableColumns)
                            |> Encode.object
                    )
                |> Encode.encode 0
                |> File.Download.string "table-data.json" "application/json"
            )

        FilterApCreaturesChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterApCreatures = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterAttributeChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedFilterAttribute = value }
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

        FilterDamageTypesOperatorChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterDamageTypesOperator = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterDomainsOperatorChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterDomainsOperator = value }
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

        GotDocumentIndexResult result ->
            ( { model
                | documentIndex = Result.withDefault Dict.empty result
                , documentsToFetch = Set.empty
              }
            , Cmd.none
            )
                |> fetchDocuments False (Set.toList model.documentsToFetch)

        GotDocuments alwaysParseMarkdown ids result ->
            ( { model
                | documentIndex =
                    List.foldl
                        (\id index -> Dict.remove id index)
                        model.documentIndex
                        ids
                , documents =
                    Dict.union
                        model.documents
                        (result
                            |> Result.withDefault []
                            |> List.map
                                (\docResult ->
                                    case docResult of
                                        Ok doc ->
                                            ( doc.id, Ok doc )

                                        Err id ->
                                            ( id, Err (Http.BadStatus 404) )
                                )
                            |> Dict.fromList
                        )
              }
            , Cmd.none
            )
                |> parseAndFetchDocuments alwaysParseMarkdown ids

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

        GotGroupSearchResult result ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | searchGroupResults =
                            result
                                |> Result.map .documentIds
                                |> Result.withDefault []
                                |> List.append searchModel.searchGroupResults
                                |> List.Extra.unique
                        , tracker = Nothing
                    }
                )
                model
            , Cmd.none
            )
                |> parseAndFetchDocuments
                    False
                    (result
                        |> Result.map .documentIds
                        |> Result.withDefault []
                        |> List.filter (\id -> not (Dict.member id model.documents))
                    )

        GotSearchResult result ->
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
            , Cmd.none
            )
                |> updateIndex (Result.toMaybe result |> Maybe.andThen .index)
                |> parseAndFetchDocuments
                    False
                    (result
                        |> Result.map .documentIds
                        |> Result.withDefault []
                    )

        GotSourcesAggregationResult result ->
            ( { model | sourcesAggregation = Just result }
            , Cmd.none
            )

        GotTraitAggregationsResult result ->
            ( { model | traitAggregations = Just result }
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

        GroupedShowHeightenableChanged enabled ->
            ( { model | groupedShowHeightenable = enabled }
            , saveToLocalStorage
                "grouped-show-heightenable"
                (if enabled then "1" else "0")
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

        LegacyModeChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | legacyMode = value }
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
                    parseMarkdownAndCollectIdsToFetch
                        (Maybe.Extra.toList documentId)
                        []
                        model.documents
                        (Maybe.withDefault model.legacyMode model.searchModel.legacyMode)
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
                                    , noRedirect =
                                        parsedUrl
                                            |> Maybe.andThen .query
                                            |> Maybe.map (String.contains "NoRedirect=1")
                                            |> Maybe.withDefault False
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
            if Maybe.map .documentId model.previewLink == Just documentId then
                ( model
                , Cmd.none
                )
                    |> parseAndFetchDocuments True [ documentId ]

            else
                ( model
                , Cmd.none
                )

        LinkLeft ->
            ( { model | previewLink = Nothing }
            , Cmd.none
            )

        LoadGroupPressed groups ->
            ( model
            , Cmd.none
            )
                |> searchWithGroups groups

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
            , Cmd.none
            )
                |> searchWithCurrentQuery LoadNewForce

        PageSizeDefaultsChanged pageId size ->
            let
                newDefaults : Dict String Int
                newDefaults =
                    if size == 0 then
                        Dict.remove pageId model.pageSizeDefaults

                    else
                        Dict.insert pageId size model.pageSizeDefaults
            in
            ( { model | pageSizeDefaults = newDefaults }
            , saveToLocalStorage
                "page-size"
                (Encode.dict identity Encode.int newDefaults
                    |> Encode.encode 0
                )
            )

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

        RemoveAllAttributeFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredAttributes = Dict.empty }
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

        RemoveAllDamageTypeFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredDamageTypes = Dict.empty }
                )
                model
                |> updateUrlWithSearchParams
            )

        RemoveAllDomainFiltersPressed ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredDomains = Dict.empty }
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
                    { searchModel
                        | filteredTraits = Dict.empty
                        , filteredTraitGroups = Dict.empty
                    }
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

        ResetDefaultParamsPressed ->
            let
                newDefaults : Dict String (Dict String (List String))
                newDefaults =
                    Dict.remove model.pageId model.pageDefaultParams
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

        ResultDisplayChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | resultDisplay = value
                    }
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

        ShowFilters ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | showFilters = True }
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
            , if not show && id == "whats-new" then
                saveToLocalStorage
                    "seen-whats-new"
                    (String.fromInt whatsNewVersion)

              else
                Cmd.none
            )

        ShowLegacyFiltersChanged value ->
            ( { model | showLegacyFilters = value }
            , saveToLocalStorage
                "show-legacy-filters"
                (if value then "1" else "0")
            )

        ShowResultIndexChanged value ->
            ( { model | showResultIndex = value }
            , saveToLocalStorage
                "show-result-index"
                (if value then "1" else "0")
            )

        ShowShortPfsChanged value ->
            ( { model | showResultPfs = value }
            , saveToLocalStorage
                "show-short-pfs"
                (if value then "1" else "0")
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

        SortAttributeChanged value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectedSortAttribute = value }
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

        TraitGroupFilterAdded group ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraitGroups = toggleBoolDict group searchModel.filteredTraitGroups }
                )
                model
                |> updateUrlWithSearchParams
            )

        TraitGroupFilterRemoved group ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filteredTraitGroups = Dict.remove group searchModel.filteredTraitGroups }
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
                |> addCmd updateTitle
                |> parseAndFetchDocuments
                    False
                    (model.searchModel.searchResults
                        |> List.concatMap (Result.map .documentIds >> Result.withDefault [])
                    )

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


addCmd : (Model -> Cmd Msg) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
addCmd fn ( model, cmd ) =
    ( model
    , Cmd.batch
        [ cmd
        , fn model
        ]
    )


updateIndex : Maybe String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateIndex maybeIndex ( model, cmd ) =
    case maybeIndex of
        Just index ->
            if index /= model.index then
                ( { model
                    | documentIndex = Dict.empty
                    , index = index
                  }
                , cmd
                )
                    |> addCmd getDocumentIndex
                    |> addCmd getSourcesAggregation
                    |> addCmd getTraitAggregations
                    |> Cmd.Extra.add (saveToLocalStorage "index" index)

            else
                ( model, cmd )

        Nothing ->
            ( model, cmd )


parseAndFetchDocuments : Bool -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
parseAndFetchDocuments alwaysParseMarkdown ids ( model, cmd ) =
    let
        ( parsedDocuments, idsToFetch ) =
            if model.searchModel.resultDisplay == Full || alwaysParseMarkdown then
                parseMarkdownAndCollectIdsToFetch
                    ids
                    []
                    model.documents
                    (Maybe.withDefault model.legacyMode model.searchModel.legacyMode)

            else if model.searchModel.resultDisplay == Short then
                ( List.foldl
                    (\id documents ->
                        Dict.update
                            id
                            (Maybe.map (Result.map parseDocumentSearchMarkdown))
                            documents
                    )
                    model.documents
                    ids
                , ids
                )

            else
                ( model.documents, ids )

        containsTeleport : Bool
        containsTeleport =
            model.url.query
                |> Maybe.map (\q -> String.contains "teleport=true" q)
                |> Maybe.withDefault False

        teleportUrl : Maybe String
        teleportUrl =
            if containsTeleport then
                model.searchModel.searchResults
                    |> List.head
                    |> Maybe.andThen Result.toMaybe
                    |> Maybe.map .documentIds
                    |> Maybe.andThen List.head
                    |> Maybe.andThen (\id -> Dict.get id model.documents)
                    |> Maybe.andThen Result.toMaybe
                    |> Maybe.map (getUrl model)

            else
                Nothing
    in
    ( { model
        | documents = parsedDocuments
      }
    , cmd
    )
        |> case teleportUrl of
            Just url ->
                Cmd.Extra.add (navigation_loadUrl url)

            Nothing ->
                fetchDocuments alwaysParseMarkdown idsToFetch


fetchDocuments : Bool -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fetchDocuments alwaysParseMarkdown ids ( model, cmd ) =
    let
        idsToFetch : List String
        idsToFetch =
            List.filter
                (\id -> not (Dict.member id model.documents))
                ids
                |> List.Extra.unique

        filesToFetch : List ( String, List String )
        filesToFetch =
            idsToFetch
                |> List.map
                    (\id ->
                        ( id
                        , Dict.get id model.documentIndex
                        )
                    )
                |> Dict.Extra.filterGroupBy Tuple.second
                |> Dict.map (\_ v -> List.map Tuple.first v)
                |> Dict.toList
    in
    ( { model
        | documentsToFetch =
            if True then
                Set.union model.documentsToFetch (Set.fromList idsToFetch)

            else
                model.documentsToFetch
      }
    , filesToFetch
        |> List.map
            (\( file, fileIds ) ->
                Http.get
                    { expect = Http.expectJson
                        (GotDocuments alwaysParseMarkdown fileIds)
                        (Decode.list
                            (Decode.oneOf
                                [ Decode.map Ok documentDecoder
                                , Decode.map Err (Decode.field "id" Decode.string)
                                ]
                            )
                        )
                    , url = model.dataUrl ++ "/" ++ file ++ ".json"
                    }
            )
        |> List.append [ cmd ]
        |> Cmd.batch
    )


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
    -> Bool
    -> ( Dict String (Result Http.Error Document), List String )
parseMarkdownAndCollectIdsToFetch idsToCheck idsToFetch documents legacyMode =
    case idsToCheck of
        id :: remainingToCheck ->
            let
                idToWorkWith : String
                idToWorkWith =
                    case Dict.get id documents of
                        Just (Ok doc) ->
                            case ( legacyMode, doc.legacyId, doc.remasterId ) of
                                ( True, Just legacyId, _ ) ->
                                    legacyId

                                ( True, Nothing, _ ) ->
                                    id

                                ( False, _, Just remasterId ) ->
                                    remasterId

                                ( False, _, _ ) ->
                                    id

                        _ ->
                            id

                fetchCurrentId : List String
                fetchCurrentId =
                    if Dict.member idToWorkWith documents then
                        []

                    else
                        [ idToWorkWith ]

                documentWithParsedMarkdown : Maybe Document
                documentWithParsedMarkdown =
                    Dict.get idToWorkWith documents
                        |> Maybe.andThen Result.toMaybe
                        |> Maybe.map parseDocumentMarkdown

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
                    idToWorkWith
                    (Maybe.map (Result.map (\doc -> Maybe.withDefault doc documentWithParsedMarkdown)))
                    documents
                )
                legacyMode

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
        "always-show-filters" ->
            case value of
                "1" ->
                    { model | alwaysShowFilters = True }

                "0" ->
                    { model | alwaysShowFilters = False }

                _ ->
                    model

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

        "date-format" ->
            { model | dateFormat = value }

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

        "grouped-show-heightenable" ->
            case value of
                "1" ->
                    { model | groupedShowHeightenable = True }

                "0" ->
                    { model | groupedShowHeightenable = False }

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

        "index" ->
            { model | index = value }

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
            case Decode.decodeString (Decode.dict Decode.int) value of
                Ok defaults ->
                    { model
                        | pageSize =
                            Dict.get model.pageId defaults
                                |> Maybe.Extra.orElse (Dict.get "global" defaults)
                                |> Maybe.withDefault model.pageSize
                        , pageSizeDefaults = defaults
                    }

                Err _ ->
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

        "seen-whats-new" ->
            case String.toInt value of
                Just version ->
                    if version >= whatsNewVersion then
                        updateCurrentSearchModel
                            (\searchModel ->
                                { searchModel
                                    | visibleFilterBoxes =
                                        List.Extra.remove "whats-new" searchModel.visibleFilterBoxes
                                }
                            )
                            model

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

        "show-legacy-filters" ->
            case value of
                "1" ->
                    { model | showLegacyFilters = True }

                "0" ->
                    { model | showLegacyFilters = False }

                _ ->
                    model

        "show-result-index" ->
            case value of
                "1" ->
                    { model | showResultIndex = True }

                "0" ->
                    { model | showResultIndex = False }

                _ ->
                    model

        "show-short-pfs" ->
            case value of
                "1" ->
                    { model | showResultPfs = True }

                "0" ->
                    { model | showResultPfs = False }

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
    , ( "include-attributes"
      , boolDictIncluded searchModel.filteredAttributes
      )
    , ( "exclude-attributes"
      , boolDictExcluded searchModel.filteredAttributes
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
    , ( "include-damage-types"
      , boolDictIncluded searchModel.filteredDamageTypes
      )
    , ( "exclude-damage-types"
      , boolDictExcluded searchModel.filteredDamageTypes
      )
    , ( "damage-types-operator"
      , if searchModel.filterDamageTypesOperator then
            []

        else
            [ "or" ]
      )
    , ( "include-domains"
      , boolDictIncluded searchModel.filteredDomains
      )
    , ( "exclude-domains"
      , boolDictExcluded searchModel.filteredDomains
      )
    , ( "domains-operator"
      , if searchModel.filterDomainsOperator then
            []

        else
            [ "or" ]
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
    , ( "include-trait-groups"
      , boolDictIncluded searchModel.filteredTraitGroups
      )
    , ( "exclude-trait-groups"
      , boolDictExcluded searchModel.filteredTraitGroups
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
    , ( "ap-creatures"
      , if searchModel.filterApCreatures then
            [ "hide" ]

        else
            []
      )
    , ( "legacy"
      , case searchModel.legacyMode of
            Just True ->
                [ "yes" ]

            Just False ->
                [ "no" ]

            Nothing ->
                []
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

            Short ->
                "short"

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
    , "legacy_name"
    , "remaster_name"
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
                            [ buildSearchQuery model searchModel []
                            , ( "boost_mode", Encode.string "replace" )
                            , ( "random_score"
                              , Encode.object
                                    [ ( "seed", Encode.int model.randomSeed )
                                    , ( "field", Encode.string "_seq_no" )
                                    ]
                              )
                            ]

                         else
                            [ buildSearchQuery model searchModel []
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
                        if model.loadAll then
                            10000

                        else
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
        , Just ( "_source" , Encode.bool False )
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


buildSearchGroupedBody : Model -> SearchModel -> List ( String, String ) -> Encode.Value
buildSearchGroupedBody model searchModel groups =
    Encode.object
        [ buildSearchQuery model searchModel groups
        , ( "size", Encode.int 10000 )
        , ( "sort"
          , Encode.list identity
                [ Encode.string "_score"
                , Encode.string "_doc"
                ]
          )
        , ( "_source", Encode.bool False )
        ]


buildSearchGroupAggregationsBody : Model -> SearchModel -> Encode.Value
buildSearchGroupAggregationsBody model searchModel =
    Encode.object
        [ buildSearchQuery model searchModel []
        , buildGroupAggs searchModel
        , ( "size", Encode.int 0 )
        ]


buildSearchQuery : Model -> SearchModel -> List ( String, String ) -> ( String, Encode.Value )
buildSearchQuery model searchModel groupFilters =
    let
        filters : List (List ( String, Encode.Value ))
        filters =
            buildSearchFilterTerms model searchModel groupFilters

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
    if field == "actions" then
        "actions.keyword"

    else
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


buildSearchFilterTerms :
    Model
    -> SearchModel
    -> List ( String, String )
    -> List (List ( String, Encode.Value ))
buildSearchFilterTerms model searchModel groupFilters =
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

        , List.map
            (\( field, value ) ->
                if value /= "" then
                    [ ( "term"
                      , Encode.object
                            [ ( mapSortFieldToElastic field
                              , Encode.object
                                    [ ( "value", Encode.string value ) ]
                              )
                            ]
                      )
                    ]

                else
                    [ ( "bool"
                      , Encode.object
                            [ ( "must_not"
                              , Encode.object
                                    [ ( "exists"
                                      , Encode.object
                                            [ ( "field"
                                              , Encode.string field
                                              )
                                            ]
                                      )
                                    ]
                              )
                            ]
                      )
                    ]
            )
            groupFilters

        , [ [ ( "bool"
              , Encode.object
                    [ ( "must_not"
                      , Encode.object
                            [ ( "exists"
                              , Encode.object
                                    [ ( "field"
                                      , if Maybe.withDefault model.legacyMode searchModel.legacyMode then
                                            Encode.string "legacy_id"

                                        else
                                            Encode.string "remaster_id"
                                      )
                                    ]
                              )
                            ]
                      )
                    ]
            )
          ] ]
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

        , if searchModel.filterApCreatures then
            [ ( "query_string"
              , Encode.object
                    [ ( "query", Encode.string "(type:creature source_category:\"adventure paths\")" )
                    , ( "default_operator", Encode.string "AND" )
                    ]
              )
            ]
                |> List.singleton

          else
            []

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
            [ ( "legacy_name.sayt"
              , Encode.object
                    [ ( "query", Encode.string queryString )
                    ]
              )
            ]
        )
      ]
    , [ ( "match_phrase_prefix"
        , Encode.object
            [ ( "remaster_name.sayt"
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
    , [ ( "term"
        , Encode.object
            [ ( "legacy_name", Encode.string queryString )
            ]
        )
      ]
    , [ ( "term"
        , Encode.object
            [ ( "remaster_name", Encode.string queryString )
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
                , expect = Http.expectJson GotSearchResult searchResultDecoder
                , timeout = Just 10000
                , tracker = Just ("search-" ++ String.fromInt newTracker)
                }
            ]
        )

    else
        ( model
        , cmd
        )


searchWithGroups : List ( String, String ) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
searchWithGroups groups ( model, cmd ) =
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
                        | tracker = Just newTracker
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
            , body = Http.jsonBody (buildSearchGroupedBody newModel newModel.searchModel groups)
            , expect = Http.expectJson GotGroupSearchResult searchResultDecoder
            , timeout = Just 10000
            , tracker = Just ("search-" ++ String.fromInt newTracker)
            }
        ]
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

                    [ "group-fields", _ ] ->
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


updateTitle : Model -> Cmd msg
updateTitle model =
    document_setTitle model.searchModel.query


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
            , expect = Http.expectJson GotGroupAggregationsResult searchResultDecoder
            , timeout = Just 10000
            , tracker = Nothing
            }
        ]
    )


getAggregations : Model -> Cmd Msg
getAggregations model =
    Http.request
        { method = "POST"
        , url = model.elasticUrl ++ "/_search"
        , headers = []
        , body = Http.jsonBody (buildAggregationsBody model.searchModel)
        , expect = Http.expectJson GotAggregationsResult aggregationsDecoder
        , timeout = Just 10000
        , tracker = Nothing
        }


buildAggregationsBody : SearchModel -> Encode.Value
buildAggregationsBody searchModel =
    Encode.object
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , encodeObjectMaybe
                        [ if String.isEmpty searchModel.fixedQueryString then
                            Nothing

                          else
                            ( "filter"
                            , Encode.object (buildElasticsearchQueryStringQueryBody searchModel.fixedQueryString)
                            )
                                |> Just

                        , ( "must_not"
                          , Encode.object
                                [ ( "term"
                                  , Encode.object [ ( "exclude_from_search", Encode.bool True ) ]
                                  )
                                ]
                          )
                            |> Just
                        ]
                  )
                ]
          )

        , ( "aggs"
          , Encode.object
                (List.append
                    (List.map
                        buildTermsAggregation
                        [ "actions.keyword"
                        , "creature_family"
                        , "domain"
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
                    ]
                )
          )
        , ( "size", Encode.int 0 )
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


getDocumentIndex : Model -> Cmd Msg
getDocumentIndex model =
    if model.index /= "" then
        Http.get
            { expect =
                Http.expectJson
                    GotDocumentIndexResult
                    (Decode.dict (Decode.list Decode.string)
                        |> Decode.map
                            (\dict ->
                                Dict.foldl
                                    (\key docs carry ->
                                        List.foldl
                                            (\id -> Dict.insert id key)
                                            carry
                                            docs
                                    )
                                    Dict.empty
                                    dict
                            )
                    )
            , url = model.dataUrl ++ "/" ++ model.index ++ "-index.json"
            }

    else
        Cmd.none


getSourcesAggregation : Model -> Cmd Msg
getSourcesAggregation model =
    if model.index /= "" then
        Http.get
            { expect = Http.expectJson GotSourcesAggregationResult sourcesAggregationDecoder
            , url = model.dataUrl ++ "/" ++ model.index ++ "-source-agg.json"
            }

    else
        Cmd.none


getTraitAggregations : Model -> Cmd Msg
getTraitAggregations model =
    if model.index /= "" then
        Http.get
            { expect = Http.expectJson GotTraitAggregationsResult traitAggregationsDecoder
            , url = model.dataUrl ++ "/" ++ model.index ++ "-trait-agg.json"
            }

    else
        Cmd.none


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
                [ ( "bool"
                  , Encode.object
                        [ ( "filter"
                          , Encode.object
                                [ ( "term"
                                  , Encode.object [ ( "type", Encode.string "source" ) ]
                                  )
                                ]
                          )
                        , ( "must_not"
                          , Encode.object
                                [ ( "term"
                                  , Encode.object [ ( "exclude_from_search", Encode.bool True ) ]
                                  )
                                ]
                          )
                        ]
                  )
                ]
          )
        ]


whatsNewVersion : Int
whatsNewVersion =
    1
