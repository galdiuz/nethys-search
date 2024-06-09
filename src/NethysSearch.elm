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
import Json.Decode.Extra as DecodeExtra
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
import Regex
import Result.Extra
import Set exposing (Set)
import Set.Extra
import String.Extra
import Task exposing (Task)
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
      , dataUrl = flags.dataUrl
      , documentIndex = Dict.empty
      , documents = Dict.empty
      , documentsToFetch = Set.empty
      , elasticUrl = flags.elasticUrl
      , fixedParams = flags.fixedParams
      , globalAggregations = Nothing
      , groupTraits = False
      , groupedDisplay = Dim
      , groupedSort = Alphanum
      , index = ""
      , loadAll = flags.loadAll
      , legacyMode = flags.legacyMode
      , limitTableWidth = False
      , linkPreviewsEnabled = True
      , noUi = flags.noUi
      , pageDefaultParams = Dict.empty
      , pageId = flags.pageId
      , pageSize = 50
      , pageSizeDefaults = Dict.empty
      , pageWidth = 0
      , previewLink = Nothing
      , randomSeed = flags.randomSeed
      , savedColumnConfigurations = Dict.empty
      , savedColumnConfigurationName = ""
      , searchModel =
            emptySearchModel
                { defaultQuery = flags.defaultQuery
                , fixedQueryString = flags.fixedQueryString
                , removeFilters = flags.removeFilters
                }
      , showLegacyFilters = True
      , url = url
      , viewModel =
            { browserDateFormat = flags.browserDateFormat
            , dateFormat = "default"
            , groupedShowHeightenable = True
            , groupedShowPfs = True
            , groupedShowRarity = True
            , maskedSourceGroups = Set.empty
            , openInNewTab = False
            , resultBaseUrl =
                if String.endsWith "/" flags.resultBaseUrl then
                    String.dropRight 1 flags.resultBaseUrl

                else
                    flags.resultBaseUrl
            , showResultAdditionalInfo = True
            , showResultIndex = True
            , showResultPfs = True
            , showResultSpoilers = True
            , showResultSummary = True
            , showResultTraits = True
            }
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
                    |> addCmd getGlobalAggregations


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

        AutoQueryTypeChanged enabled ->
            ( { model | autoQueryType = enabled }
            , Cmd.batch
                [ saveToLocalStorage
                    "auto-query-type"
                    (if enabled then "1" else "0")
                , updateUrlWithSearchParams { model | autoQueryType = enabled }
                ]
            )

        DateFormatChanged format ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | dateFormat = format }
                )
                model
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
                                        , View.searchResultTableCellToString model.viewModel document column
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
                                , View.searchResultTableCellToString model.viewModel document column
                                    |> Encode.string
                                )
                            )
                            ("name" :: model.searchModel.tableColumns)
                            |> Encode.object
                    )
                |> Encode.encode 0
                |> File.Download.string "table-data.json" "application/json"
            )

        FilterRemoved filterType value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredValues =
                            Dict.update
                                filterType
                                (Maybe.withDefault Dict.empty
                                    >> Dict.remove value
                                    >> Just
                                )
                                searchModel.filteredValues
                    }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterToggled filterType value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredValues =
                            searchModel.filteredValues
                                |> Dict.update
                                    filterType
                                    (Maybe.withDefault Dict.empty
                                        >> toggleBoolDict value
                                        >> Just
                                    )
                                |> (\newFilteredValues ->
                                    case filterType of
                                        "item-categories" ->
                                            let
                                                newValue : Maybe Bool
                                                newValue =
                                                    nestedDictGet filterType value newFilteredValues

                                                includedItemCategories : List String
                                                includedItemCategories =
                                                    boolDictIncluded "item-categories" newFilteredValues
                                            in
                                            case newValue of
                                                Just True ->
                                                    nestedDictFilter
                                                        "item-subcategories"
                                                        (\source _ ->
                                                            searchModel.aggregations
                                                                |> Maybe.andThen Result.toMaybe
                                                                |> Maybe.map .itemSubcategories
                                                                |> Maybe.withDefault []
                                                                |> List.filter
                                                                    (\sc ->
                                                                        List.member sc.category includedItemCategories
                                                                    )
                                                                |> List.map .name
                                                                |> List.member source
                                                        )
                                                        newFilteredValues

                                                Just False ->
                                                    nestedDictFilter
                                                        "item-subcategories"
                                                        (\source _ ->
                                                            searchModel.aggregations
                                                                |> Maybe.andThen Result.toMaybe
                                                                |> Maybe.map .itemSubcategories
                                                                |> Maybe.andThen (List.Extra.find (.name >> ((==) source)))
                                                                |> Maybe.map .category
                                                                |> Maybe.map String.toLower
                                                                |> (/=) (Just value)
                                                        )
                                                        newFilteredValues

                                                Nothing ->
                                                    newFilteredValues

                                        "source-categories" ->
                                            let
                                                newValue : Maybe Bool
                                                newValue =
                                                    nestedDictGet filterType value newFilteredValues

                                                includedSourceCategories : List String
                                                includedSourceCategories =
                                                    boolDictIncluded "source-categories" newFilteredValues
                                            in
                                            case newValue of
                                                Just True ->
                                                    nestedDictFilter
                                                        "sources"
                                                        (\source _ ->
                                                            model.globalAggregations
                                                                |> Maybe.andThen Result.toMaybe
                                                                |> Maybe.map .sources
                                                                |> Maybe.withDefault []
                                                                |> List.filter
                                                                    (\s ->
                                                                        List.member s.category includedSourceCategories
                                                                    )
                                                                |> List.map .name
                                                                |> List.member source
                                                        )
                                                        newFilteredValues

                                                Just False ->
                                                    nestedDictFilter
                                                        "sources"
                                                        (\source _ ->
                                                            model.globalAggregations
                                                                |> Maybe.andThen Result.toMaybe
                                                                |> Maybe.map .sources
                                                                |> Maybe.andThen (List.Extra.find (.name >> ((==) source)))
                                                                |> Maybe.map .category
                                                                |> Maybe.map String.toLower
                                                                |> (/=) (Just value)
                                                        )
                                                        newFilteredValues

                                                Nothing ->
                                                    newFilteredValues

                                        _ ->
                                            newFilteredValues
                                   )
                    }
                )
                model
                |> updateUrlWithSearchParams
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

        FilterItemChildrenChanged value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterItemChildren = value }
                )
                model
                |> updateUrlWithSearchParams
            )

        FilterOperatorChanged filterType value ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | filterOperators = Dict.insert filterType value searchModel.filterOperators }
                )
                model
                |> updateUrlWithSearchParams
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
                |> fetchDocuments False (getLegacyMode model) (Set.toList model.documentsToFetch)

        GotDocuments alwaysParseMarkdown legacyMode ids result ->
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
                |> parseAndFetchDocuments alwaysParseMarkdown legacyMode ids

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
                    (getLegacyMode model)
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
                    (getLegacyMode model)
                    (result
                        |> Result.map .documentIds
                        |> Result.withDefault []
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
            ( updateViewModel
                (\viewModel ->
                    { viewModel | groupedShowHeightenable = enabled }
                )
                model
            , saveToLocalStorage
                "grouped-show-heightenable"
                (if enabled then "1" else "0")
            )

        GroupedShowPfsIconChanged enabled ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | groupedShowPfs = enabled }
                )
                model
            , saveToLocalStorage
                "grouped-show-pfs"
                (if enabled then "1" else "0")
            )

        GroupedShowRarityChanged enabled ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | groupedShowRarity = enabled }
                )
                model
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

                noRedirect : Bool
                noRedirect =
                    parsedUrl
                        |> Maybe.andThen .query
                        |> Maybe.map (String.contains "NoRedirect=1")
                        |> Maybe.withDefault False

                legacyMode : LegacyMode
                legacyMode =
                    if noRedirect then
                        NoRedirect

                     else
                        getLegacyMode model

                documentsWithParsedMarkdown : Dict String (Result Http.Error Document)
                documentsWithParsedMarkdown =
                    parseMarkdownAndCollectIdsToFetch
                        (Maybe.Extra.toList documentId)
                        []
                        model.documents
                        legacyMode
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
                                    , noRedirect = noRedirect
                                    }
                                )

                    else
                        Nothing
              }
            , case ( model.linkPreviewsEnabled, documentId ) of
                ( True, Just id ) ->
                    Process.sleep 150
                        |> Task.perform (\_ -> LinkEnteredDebouncePassed id legacyMode)

                _ ->
                    Cmd.none
            )

        LinkEnteredDebouncePassed documentId legacyMode ->
            if Maybe.map .documentId model.previewLink == Just documentId then
                ( model
                , Cmd.none
                )
                    |> parseAndFetchDocuments True legacyMode [ documentId ]

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

        MaskSourceGroupToggled sourceGroup ->
            let
                newModel =
                    updateViewModel
                        (\viewModel ->
                            { viewModel
                                | maskedSourceGroups =
                                    Set.Extra.toggle sourceGroup viewModel.maskedSourceGroups
                            }
                        )
                        model
            in
            ( newModel
            , saveToLocalStorage
                "masked-source-groups"
                (newModel.viewModel.maskedSourceGroups
                    |> Encode.set Encode.string
                    |> Encode.encode 0
                )
            )

        NoOp ->
            ( model
            , Cmd.none
            )

        OpenInNewTabChanged value ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | openInNewTab = value }
                )
                model
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

        RemoveAllFiltersOfTypePressed filterType ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredValues =
                            Dict.remove filterType searchModel.filteredValues
                    }
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

        RemoveAllRangeValueFiltersPressed ->
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

        ScrollToTopPressed  ->
            ( model
            , Task.perform (\_ -> NoOp) (Browser.Dom.setViewport 0 0)
            )

        SearchFilterChanged filterKey value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | searchFilters = Dict.insert filterKey value searchModel.searchFilters
                    }
                )
                model
            , Cmd.none
            )

        SelectValueChanged key value ->
            ( updateCurrentSearchModel
                (\searchModel ->
                    { searchModel | selectValues = Dict.insert key value searchModel.selectValues }
                )
                model
            , Cmd.none
            )

        ShowAdditionalInfoChanged value ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | showResultAdditionalInfo = value }
                )
                model
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
            ( updateViewModel
                (\viewModel ->
                    { viewModel | showResultIndex = value }
                )
                model
            , saveToLocalStorage
                "show-result-index"
                (if value then "1" else "0")
            )

        ShowShortPfsChanged value ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | showResultPfs = value }
                )
                model
            , saveToLocalStorage
                "show-short-pfs"
                (if value then "1" else "0")
            )

        ShowSpoilersChanged value ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | showResultSpoilers = value }
                )
                model
            , saveToLocalStorage
                "show-spoilers"
                (if value then "1" else "0")
            )

        ShowSummaryChanged value ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | showResultSummary = value }
                )
                model
            , saveToLocalStorage
                "show-summary"
                (if value then "1" else "0")
            )

        ShowTraitsChanged value ->
            ( updateViewModel
                (\viewModel ->
                    { viewModel | showResultTraits = value }
                )
                model
            , saveToLocalStorage
                "show-traits"
                (if value then "1" else "0")
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

        TraitGroupDeselectPressed traits ->
            ( model
            , updateCurrentSearchModel
                (\searchModel ->
                    { searchModel
                        | filteredValues =
                            nestedDictFilter
                                "traits"
                                (\trait _ -> not (List.member trait traits))
                                searchModel.filteredValues
                    }
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
                    (getLegacyMode model)
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
                    |> addCmd getGlobalAggregations
                    |> Cmd.Extra.add (saveToLocalStorage "index" index)

            else
                ( model, cmd )

        Nothing ->
            ( model, cmd )


parseAndFetchDocuments : Bool -> LegacyMode -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
parseAndFetchDocuments alwaysParseMarkdown legacyMode ids ( model, cmd ) =
    let
        ( parsedDocuments, idsToFetch ) =
            if model.searchModel.resultDisplay == Full || alwaysParseMarkdown then
                parseMarkdownAndCollectIdsToFetch
                    ids
                    []
                    model.documents
                    legacyMode
                    |> Tuple.mapFirst (flattenDocuments legacyMode)

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

        -- TODO: If teleport, fetch only first doc

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
                    |> Maybe.map (getUrl model.viewModel)

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
                fetchDocuments alwaysParseMarkdown legacyMode idsToFetch


fetchDocuments : Bool -> LegacyMode -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fetchDocuments alwaysParseMarkdown legacyMode ids ( model, cmd ) =
    if model.dataUrl /= "" then
        fetchDocumentsFromJson alwaysParseMarkdown legacyMode ids ( model, cmd )

    else
        fetchDocumentsFromElasticsearch alwaysParseMarkdown legacyMode ids ( model, cmd )


fetchDocumentsFromJson : Bool -> LegacyMode -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fetchDocumentsFromJson alwaysParseMarkdown legacyMode ids ( model, cmd ) =
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
            if Dict.isEmpty model.documentIndex then
                Set.union model.documentsToFetch (Set.fromList idsToFetch)

            else
                model.documentsToFetch
      }
    , filesToFetch
        |> List.map
            (\( file, fileIds ) ->
                Http.get
                    { expect =
                        Http.expectJson
                            (GotDocuments alwaysParseMarkdown legacyMode fileIds)
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


fetchDocumentsFromElasticsearch : Bool -> LegacyMode -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fetchDocumentsFromElasticsearch alwaysParseMarkdown legacyMode ids ( model, cmd ) =
    let
        idsToFetch : List String
        idsToFetch =
            List.filter
                (\id -> not (Dict.member id model.documents))
                ids
                |> List.Extra.unique
    in
    ( model
    , if List.isEmpty idsToFetch then
        cmd

      else
        Cmd.batch
            [ cmd
            , Http.post
                { body =
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
                        (GotDocuments alwaysParseMarkdown legacyMode idsToFetch)
                        (Decode.field
                            "docs"
                            (Decode.list
                                (Decode.oneOf
                                    [ Decode.field
                                        "_source"
                                        (Decode.map Ok documentDecoder)
                                    , Decode.field
                                        "_id"
                                        (Decode.map Err Decode.string)
                                    ]
                                )
                            )
                        )
                , url = model.elasticUrl ++ "/_mget"
                }
            ]
    )


parseMarkdown : Markdown -> Markdown
parseMarkdown markdown =
    case markdown of
        Parsed _ ->
            markdown

        ParsedWithUnflattenedChildren _ ->
            markdown

        NotParsed string ->
            string
                |> Markdown.Parser.parse
                |> Result.map (List.map (Markdown.Block.walk mergeInlines))
                |> Result.map (List.map (Markdown.Block.walk paragraphToInline))
                |> Result.mapError (List.map Markdown.Parser.deadEndToString)
                |> \result ->
                    case result of
                        Ok blocks ->
                            if List.any
                                (\block -> findDocumentIdsInBlock block [] |> List.isEmpty |> not)
                                blocks
                            then
                                ParsedWithUnflattenedChildren result

                            else
                                Parsed result

                        Err _ ->
                            Parsed result


parseDocumentMarkdown : Document -> Document
parseDocumentMarkdown document =
    { document | markdown = parseMarkdown document.markdown }


parseDocumentSearchMarkdown : Document -> Document
parseDocumentSearchMarkdown document =
    { document | searchMarkdown = parseMarkdown document.searchMarkdown }


parseMarkdownAndCollectIdsToFetch :
    List String
    -> List String
    -> Dict String (Result Http.Error Document)
    -> LegacyMode
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
                                ( LegacyMode, Just "0", _ ) ->
                                    id

                                ( LegacyMode, Just legacyId, _ ) ->
                                    legacyId

                                ( LegacyMode, Nothing, _ ) ->
                                    id

                                ( RemasterMode, _, Just "0" ) ->
                                    id

                                ( RemasterMode, _, Just remasterId ) ->
                                    remasterId

                                ( RemasterMode, _, _ ) ->
                                    id

                                ( NoRedirect, _, _ ) ->
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
            case getValueFromAttribute "id" attributes of
                Just value ->
                    value :: list

                Nothing ->
                    list

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement _ _ children) ->
            List.foldl
                findDocumentIdsInBlock
                list
                children

        _ ->
            list


flattenDocuments : LegacyMode -> Dict String (Result Http.Error Document) -> Dict String (Result Http.Error Document)
flattenDocuments legacyMode documents =
    Dict.map
        (\id documentResult ->
            Result.map
                (\document ->
                    { document
                        | markdown =
                            case document.markdown of
                                ParsedWithUnflattenedChildren (Ok blocks) ->
                                    case flattenMarkdown legacyMode documents 1 Nothing blocks of
                                        ( True, flattenedBlocks ) ->
                                            ParsedWithUnflattenedChildren (Ok flattenedBlocks)

                                        ( False, flattenedBlocks ) ->
                                            Parsed (Ok flattenedBlocks)

                                _ ->
                                    document.markdown
                    }
                )
                documentResult
        )
        documents


updateCurrentSearchModel : (SearchModel -> SearchModel) -> Model -> Model
updateCurrentSearchModel updateFun model =
    { model | searchModel = updateFun model.searchModel }


updateViewModel : (ViewModel -> ViewModel) -> Model -> Model
updateViewModel updateFun model =
    { model | viewModel = updateFun model.viewModel }


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
            updateViewModel
                (\viewModel ->
                    { viewModel | dateFormat = value }
                )
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

        "grouped-show-heightenable" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | groupedShowHeightenable = True }

                        "0" ->
                            { viewModel | groupedShowHeightenable = False }

                        _ ->
                            viewModel
                )
                model

        "grouped-show-pfs" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | groupedShowPfs = True }

                        "0" ->
                            { viewModel | groupedShowPfs = False }

                        _ ->
                            viewModel
                )
                model

        "grouped-show-rarity" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | groupedShowRarity = True }

                        "0" ->
                            { viewModel | groupedShowRarity = False }

                        _ ->
                            viewModel
                )
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

        "masked-source-groups" ->
            updateViewModel
                (\viewModel ->
                    case Decode.decodeString (DecodeExtra.set Decode.string) value of
                        Ok set ->
                            { viewModel | maskedSourceGroups = set }

                        _ ->
                            viewModel
                )
                model

        "open-in-new-tab" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | openInNewTab = True }

                        "0" ->
                            { viewModel | openInNewTab = False }

                        _ ->
                            viewModel
                )
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
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | showResultAdditionalInfo = True }

                        "0" ->
                            { viewModel | showResultAdditionalInfo = False }

                        _ ->
                            viewModel
                )
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
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | showResultIndex = True }

                        "0" ->
                            { viewModel | showResultIndex = False }

                        _ ->
                            viewModel
                )
                model

        "show-short-pfs" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | showResultPfs = True }

                        "0" ->
                            { viewModel | showResultPfs = False }

                        _ ->
                            viewModel
                )
                model

        "show-spoilers" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | showResultSpoilers = True }

                        "0" ->
                            { viewModel | showResultSpoilers = False }

                        _ ->
                            viewModel
                )
                model

        "show-summary" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | showResultSummary = True }

                        "0" ->
                            { viewModel | showResultSummary = False }

                        _ ->
                            viewModel
                )
                model

        "show-traits" ->
            updateViewModel
                (\viewModel ->
                    case value of
                        "1" ->
                            { viewModel | showResultTraits = True }

                        "0" ->
                            { viewModel | showResultTraits = False }

                        _ ->
                            viewModel
                )
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

        "/monstertemplates.aspx" ->
            withId "creature-adjustment"

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
    List.concat
    [ [ ( "q"
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
      ]
    , List.concatMap
        (\{ key } ->
            [ ( "include-" ++ key
              , boolDictIncluded key searchModel.filteredValues
              )
            , ( "exclude-" ++ key
              , boolDictExcluded key searchModel.filteredValues
              )
            ]
        )
        (filterFields searchModel)
    , List.map
        (\{ key } ->
            ( key ++ "-operator"
            , if Maybe.withDefault True (Dict.get key searchModel.filterOperators) then
                []

              else
                [ "or" ]
            )
        )
        (filterFields searchModel
            |> List.filter .useOperator
        )
    , [ ( "values-from"
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
      , ( "item-children"
        , if searchModel.filterItemChildren then
            []

          else
            [ "parent" ]
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
                                                            [ "Ancestry", "Class", "Versatile Heritage" ]
                                                      )
                                                    ]
                                              )
                                            ]
                                        )
                                      , ( "weight", Encode.float 1.2 )
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

        queries : List String
        queries =
            case searchModel.queryType of
                Standard ->
                    [ searchModel.query ]

                ElasticsearchQueryString ->
                    String.split "++" searchModel.query
                        |> List.map String.trim
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
                                    List.map buildElasticsearchQueryStringQueryBody queries
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
                    Just ( "minimum_should_match", Encode.int (List.length queries) )
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
            (\filter ->
                let
                    list : List String
                    list =
                        boolDictIncluded filter.key searchModel.filteredValues

                    isAnd : Bool
                    isAnd =
                        Dict.get filter.key searchModel.filterOperators
                            |> Maybe.withDefault False
                in
                if List.isEmpty list then
                    []

                else if isAnd then
                    List.map
                        (\value ->
                            [ ( "term"
                              , Encode.object
                                    [ ( filter.field
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
                                                    [ ( filter.field
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
                                                                    [ ( "field", Encode.string filter.field )
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
            (\filter ->
                let
                    list : List String
                    list =
                        boolDictExcluded filter.key searchModel.filteredValues
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
                                    [ ( filter.field
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
                                                    [ ( "field", Encode.string filter.field )
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
                                    (model.globalAggregations
                                        |> Maybe.andThen Result.toMaybe
                                        |> Maybe.map .sources
                                        |> Maybe.withDefault []
                                    )
                                )
                          )
                        ]
                  )
                ]
            )
            (boolDictExcluded "source-categories" searchModel.filteredValues)

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

        , [ [ ( "exists"
              , Encode.object
                    [ ( "field"
                      , if searchModel.filterItemChildren then
                            Encode.string "item_child_id"

                        else
                            Encode.string "item_parent_id"
                      )
                    ]
              )
            ]
          ]

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
    let
        regex : Regex.Regex
        regex =
            Regex.fromString "^~(\\d+) "
                |> Maybe.withDefault Regex.never

        -- ( String, Int ) =
        ( cleanedQueryString, minShouldMatch ) =
            case Regex.find regex queryString of
                match :: _ ->
                    ( String.replace match.match "" queryString
                    , List.head match.submatches
                        |> Maybe.Extra.join
                        |> Maybe.andThen String.toInt
                        |> Maybe.withDefault 0
                    )

                _ ->
                    ( queryString, 0 )
    in
    [ ( "query_string"
      , Encode.object
            [ ( "query", Encode.string cleanedQueryString )
            , ( "default_operator", Encode.string "AND" )
            , ( "fields", Encode.list Encode.string searchFields )
            , ( "minimum_should_match", Encode.int minShouldMatch )
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
    let
        searchHash : String
        searchHash =
            getSearchHash model model.searchModel
    in
    if (Just searchHash /= model.searchModel.lastSearchHash) || load /= LoadNew then
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
                            | lastSearchHash = Just searchHash
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


getSearchHash : Model -> SearchModel -> String
getSearchHash model searchModel =
    getSearchModelQueryParams model searchModel
        |> Dict.fromList
        |> Dict.map (\_ -> String.join "+")
        |> Dict.filter
            (\k v ->
                if k == "q" then
                    not (String.Extra.isBlank v)

                else
                    List.member k [ "columns", "display", "group-fields", "link-layout" ]
                        |> not
            )
        |> Dict.toList
        |> List.map (\( k, v ) -> k ++ "=" ++ v)
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
                        , "alignment"
                        , "area_type"
                        , "creature_family.keyword"
                        , "deity_category.keyword"
                        , "domain"
                        , "favored_weapon.keyword"
                        , "item_category.keyword"
                        , "hands.keyword"
                        , "region"
                        , "reload_raw.keyword"
                        , "size"
                        , "skill.keyword"
                        , "source.keyword"
                        , "trait"
                        , "type"
                        , "weapon_group"
                        ]
                    )
                    [ buildCompositeAggregation
                        "item_subcategory"
                        False
                        [ ( "category", "item_category.keyword" )
                        , ( "name", "item_subcategory.keyword" )
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
    if model.index /= "" && model.dataUrl /= "" then
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


getGlobalAggregations : Model -> Cmd Msg
getGlobalAggregations model =
    if model.index /= "" && model.dataUrl /= "" then
        Http.get
            { expect = Http.expectJson GotGlobalAggregationsResult globalAggregationsDecoder
            , url = model.dataUrl ++ "/" ++ model.index ++ "-aggs.json"
            }

    else if model.index /= "" then
        Task.map2
            (\sources traits ->
                { sources = sources
                , traits =
                    traits
                        |> Dict.Extra.groupBy .group
                        |> Dict.map (\_ v -> List.map .trait v)
                }
            )
            (aggregationsHttpTask
                model
                buildSourcesAggregationBody
                (Decode.at
                    ["aggregations", "source", "buckets"]
                    (Decode.list (Decode.field "key" sourceAggregationDecoder))
                )
            )
            (aggregationsHttpTask
                model
                buildTraitsAggregationBody
                (Decode.at
                    ["aggregations", "trait_group", "buckets"]
                    (Decode.list (Decode.field "key" traitAggregationDecoder))
                )
            )
            |> Task.attempt GotGlobalAggregationsResult

    else
        Cmd.none


aggregationsHttpTask : Model -> Encode.Value -> Decode.Decoder a -> Task Http.Error a
aggregationsHttpTask model body decoder =
    Http.task
        { method = "POST"
        , headers = []
        , url = model.elasticUrl ++ "/_search"
        , body = Http.jsonBody body
        , resolver = Http.stringResolver
            (\response ->
                case response of
                    Http.GoodStatus_ _ data ->
                        Decode.decodeString decoder data
                            |> Result.mapError (Decode.errorToString >> Http.BadBody)

                    Http.BadUrl_ a ->
                        Err (Http.BadUrl a)

                    Http.NetworkError_ ->
                        Err Http.NetworkError

                    Http.Timeout_ ->
                        Err Http.Timeout

                    Http.BadStatus_ { statusCode } _ ->
                        Err (Http.BadStatus statusCode)
            )
        , timeout = Just 10000
        }


buildSourcesAggregationBody : Encode.Value
buildSourcesAggregationBody =
    Encode.object
        [ ( "aggs"
          , Encode.object
                [ buildCompositeAggregation
                    "source"
                    True
                    [ ( "category", "source_category" )
                    , ( "group", "source_group.keyword" )
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


buildTraitsAggregationBody : Encode.Value
buildTraitsAggregationBody =
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
        , ( "query"
          , Encode.object
                [ ( "bool"
                  , Encode.object
                        [ ( "must"
                          , Encode.object
                                [ ( "term"
                                  , Encode.object [ ( "type", Encode.string "trait" ) ]
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
        , ( "size", Encode.int 0 )
        ]


whatsNewVersion : Int
whatsNewVersion =
    2
