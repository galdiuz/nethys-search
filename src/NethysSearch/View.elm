module NethysSearch.View exposing (..)

import Dict exposing (Dict)
import FontAwesome
import FontAwesome.Attributes
import FontAwesome.Regular
import FontAwesome.Solid
import FontAwesome.Styles
import Html exposing (Html)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Attributes.Extra as HAE
import Html.Events as HE
import Html.Extra
import Html.Keyed
import Html.Lazy
import Http
import Json.Decode as Decode
import List.Extra
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Maybe.Extra
import NethysSearch.Data as Data exposing (..)
import Order.Extra
import Regex
import Set
import String.Extra
import Tuple3


type alias FilterBox =
    { id : String
    , label : String
    , view : Model -> SearchModel -> List (Html Msg)
    , visibleIf : SearchModel -> Bool
    }


view : Model -> Html Msg
view model =
    Html.div
        []
        [ viewCss model
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
                [ if model.showQueryControls then
                    viewQuery model model.searchModel

                  else
                    Html.button
                        [ HA.style "align-self" "center"
                        , HE.onClick ShowQueryControlsPressed
                        ]
                        [ Html.text "Show query controls" ]
                , viewSearchResults model model.searchModel
                ]
        , viewLinkPreview model
        ]


viewQuery : Model -> SearchModel -> Html Msg
viewQuery model searchModel =
    Html.div
        [ HA.class "column"
        , HA.class "align-stretch"
        , HA.class "limit-width"
        , HA.class "gap-medium"
        , HA.class "fill-width"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "input-container"
            , HA.style "position" "relative"
            ]
            [ Html.button
                [ HA.class "input-button"
                , HA.style "font-size" "var(--font-very-large)"
                , HA.title "Toggle filter menu [Ctrl+Space]"
                , HAE.attributeIf
                    (not searchModel.showDropdownFilter)
                    (HA.style "color" "#808080")
                , HE.onClick DropdownFilterToggled
                ]
                [ FontAwesome.view FontAwesome.Solid.list ]
            , Html.input
                [ HA.autofocus model.autofocus
                , HA.class "query-input"
                , HA.id "query"
                , HA.maxlength 8192
                , HA.placeholder "Enter search query"
                , HA.type_ "text"
                , HA.value searchModel.query
                , HA.attribute "autocomplete" "off"
                , HA.attribute "autocapitalize" "off"
                , HE.onInput QueryChanged
                , HE.onFocus QueryFieldFocused
                , HE.onBlur QueryFieldBlurred
                ]
                [ Html.text searchModel.query ]
            , Html.Extra.viewIf
                model.searchModel.showDropdownFilter
                (viewQueryDropdownFilter model searchModel)
            , viewQueryDropdownFilterHint model
            , Html.Extra.viewIf
                (not <| String.isEmpty searchModel.query)
                (Html.button
                    [ HA.class "input-button"
                    , HA.style "font-size" "var(--font-very-large)"
                    , HA.attribute "aria-label" "Clear query"
                    , HE.onClick (QueryChanged "")
                    ]
                    [ FontAwesome.view FontAwesome.Solid.times ]
                )
            ]
        , Html.a
            [ HA.class "skip-link"
            , HA.style "align-self" "center"
            , HA.href "#results"
            ]
            [ Html.text "Skip to results" ]
        , viewFilters model searchModel
        , viewActiveFiltersAndOptions model searchModel
        ]


viewQueryDropdownFilter : Model -> SearchModel -> Html Msg
viewQueryDropdownFilter model searchModel =
    let
        buttons : List (Html Msg)
        buttons =
            queryDropdownFilterButtons searchModel.dropdownFilterState

        filterFields : List { label : String, key : String, onSelect : Msg }
        filterFields =
            dropdownFilterFields model searchModel
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        , HA.class "dropdown-filter-container"
        ]
        [ if List.isEmpty buttons then
            Html.text ""

          else
            Html.div
                [ HA.class "row"
                , HA.class "gap-tiny"
                , HA.style "padding" "2px"
                ]
                buttons

        , Html.div
            [ HA.class "input-container" ]
            [ Html.input
                [ HA.id "dropdown-filter-input"
                , HA.placeholder "Filter"
                , HA.type_ "text"
                , HA.value searchModel.dropdownFilterInput
                , HA.attribute "autocomplete" "off"
                , HE.onInput DropdownFilterInputChanged
                ]
                []
            ]

        , case ( filterFields, searchModel.dropdownFilterState ) of
            ( [], SelectNumericValue _ _ _ ) ->
                Html.div
                    [ HA.class "dropdown-filter-item"
                    , HA.style "color" "var(--color-text-inactive)"
                    ]
                    [ Html.text "Type a number in the filter box"
                    ]

            ( [], _ ) ->
                Html.div
                    [ HA.class "dropdown-filter-item"
                    , HA.style "color" "var(--color-text-inactive)"
                    ]
                    [ Html.text "No matches"
                    ]

            _ ->
                Html.Keyed.ul
                    [ HA.style "overflow-y" "auto"
                    , HA.style "max-height" "100%"
                    , HA.style "list-style" "none"
                    , HA.style "padding-inline-start" "0"
                    , HA.style "margin" "0"
                    ]
                    (List.indexedMap
                        (\index field ->
                            ( field.key
                            , Html.li
                                []
                                [ Html.button
                                    [ HA.class "row"
                                    , HA.class "gap-small"
                                    , HA.class "dropdown-filter-item"
                                    , HA.style "justify-content" "space-between"
                                    , HA.id ("dropdown-filter-item-" ++ field.key)
                                    , HA.tabindex -1
                                    , HAE.attributeIf
                                        (searchModel.dropdownFilterSelectedIndex == index)
                                        (HA.class "selected")
                                    , HE.onClick field.onSelect
                                    -- TODO: Add class style depending on field
                                    ]
                                    -- TODO: Icons based on numeric / value
                                    [ Html.text field.label
                                    , Html.Extra.viewIf
                                        (searchModel.dropdownFilterSelectedIndex == index + 1)
                                        (Html.span
                                            [ HA.style "color" "var(--color-text-inactive)"
                                            ]
                                            [ Html.text "↑"
                                            ]
                                        )
                                    , Html.Extra.viewIf
                                        (searchModel.dropdownFilterSelectedIndex == index)
                                        (Html.span
                                            [ HA.style "color" "var(--color-text-inactive)"
                                            ]
                                            [ Html.text "Enter"
                                            ]
                                        )
                                    , Html.Extra.viewIf
                                        (searchModel.dropdownFilterSelectedIndex == index - 1)
                                        (Html.span
                                            [ HA.style "color" "var(--color-text-inactive)"
                                            ]
                                            [ Html.text "↓"
                                            ]
                                        )
                                    ]
                                ]
                            )
                        )
                        (dropdownFilterFields model searchModel)
                    )
        ]


queryDropdownFilterButtons : DropdownFilterState -> List (Html Msg)
queryDropdownFilterButtons dropdownFilterState =
    let
        button : String -> Msg -> Html Msg
        button label onClick =
            Html.button
                [ HA.class "row"
                , HA.class "gap-tiny"
                , HA.class "align-center"
                , HA.tabindex -1
                , HE.onClick onClick
                ]
                [ Html.text label
                , FontAwesome.view FontAwesome.Solid.times
                ]

    in
    case dropdownFilterState of
        SelectField ->
            []

        SelectNumericOperator field label ->
            [ button label (DropdownFilterOptionSelected SelectField)
            ]

        SelectNumericSubfield field label ->
            [ button label (DropdownFilterOptionSelected SelectField)
            ]

        SelectNumericValue field label operator ->
            [ button label (DropdownFilterOptionSelected SelectField)
            , button
                (case operator of
                    EQ ->
                        "is exactly"

                    LT ->
                        "is at most"

                    GT ->
                        "is at least"
                )
                (DropdownFilterOptionSelected (SelectNumericOperator field label))
            ]

        SelectValueOperator key label ->
            [ button label (DropdownFilterOptionSelected SelectField)
            ]

        SelectSortDirection field label isNumeric ->
            [ button label (DropdownFilterOptionSelected SelectField)
            , button
                "sort by"
                (if isNumeric then
                    DropdownFilterOptionSelected (SelectNumericOperator field label)

                 else
                    DropdownFilterOptionSelected (SelectValueOperator field label)
                )
            ]

        SelectValue key label operator ->
            [ button label (DropdownFilterOptionSelected SelectField)
            , button
                (case operator of
                    Is ->
                        "is"

                    IsAnd ->
                        "is all of"

                    IsOr ->
                        "is any of"

                    IsNot ->
                        "is not"
                )
                (DropdownFilterOptionSelected (SelectValueOperator key label))
            ]


viewQueryDropdownFilterHint : Model -> Html Msg
viewQueryDropdownFilterHint model =
    if model.searchModel.showDropdownFilterHint then
        Html.div
            [ HA.class "dropdown-filter-hint"
            , HA.class "row"
            , HA.class "gap-tiny"
            ]
            [ Html.text "Try the new filter menu!"
            , Html.button
                [ HA.class "input-button"
                , HA.attribute "aria-label" "Close"
                , HE.onClick CloseDropdownFilterHint
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
            ]

    else
        Html.text ""


viewFilters : Model -> SearchModel -> Html Msg
viewFilters model searchModel =
    let
        availableFilters : List FilterBox
        availableFilters =
            allFilters model
                |> List.filter (\filter -> not (List.member filter.id searchModel.removeFilters))
                |> List.filter (\filter -> filter.visibleIf searchModel)
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        (List.append
            (if searchModel.showFilters || model.alwaysShowFilters then
                [ Html.div
                    [ HA.class "row"
                    , HA.class "gap-small"
                    , HA.class "align-center"
                    ]
                    (List.append
                        [ Html.h3
                            []
                            [ Html.text "Filters:" ]
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
                            availableFilters
                        )
                    )
                , Html.div
                    [ HA.class "row"
                    , HA.class "gap-small"
                    , HA.class "align-center"
                    ]
                    (List.append
                        [ Html.h3
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
                ]

             else
                [ Html.button
                    [ HA.style "align-self" "center"
                    , HE.onClick ShowFilters
                    ]
                    [ Html.text "Show filters and options" ]
                ]
            )
            [ Html.Keyed.node "div"
                [ HA.class "column"
                , HA.class "gap-small"
                ]
                (allFilters model ++ allOptions
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
                    |> List.map (\filter -> ( filter.id, viewOptionBox model searchModel filter ))
                )
            ]
        )


allFilters : Model -> List FilterBox
allFilters model =
    [ { id = "actions"
      , label = "⏳ Actions / Cast time"
      , view = viewFilterActions
      , visibleIf = moreThanOneValueAggregation "actions"
      }
    , { id = "alignments"
      , label = "😇 Alignments"
      , view = viewFilterAlignments
      , visibleIf =
            \searchModel ->
                moreThanOneValueAggregation "alignment" searchModel
                    && model.showLegacyFilters
      }
    , { id = "armor"
      , label = "🛡 Armor"
      , view = viewFilterArmor
      , visibleIf = getAggregationValues "item_subcategory" >> List.any ((==) "base armor")
      }
    , { id = "attributes"
      , label = "💪 Attributes"
      , view = viewFilterAttributes
      , visibleIf =
            \searchModel ->
                moreThanOneValueAggregation "attribute" searchModel
                    || List.any
                        (\field -> Data.hasMultipleMinmaxValues field searchModel)
                        Data.allAttributes
      }
    , { id = "creature"
      , label = "🐉 Creatures"
      , view = viewFilterCreatures
      , visibleIf = getAggregationValues "type" >> List.any ((==) "creature")
      }
    , { id = "deities"
      , label = "🌓 Deities"
      , view = viewFilterDeities
      , visibleIf = getAggregationValues "type" >> List.any ((==) "deity")
      }
    , { id = "domains"
      , label = "🎭 Domains"
      , view = viewFilterDomains
      , visibleIf = moreThanOneValueAggregation "domain"
      }
    , { id = "items"
      , label = "🎒 Items"
      , view = viewFilterItems
      , visibleIf = getAggregationValues "type" >> List.any ((==) "item")
      }
    , { id = "legacy"
      , label = "🏛 Legacy / Remaster"
      , view = viewFilterLegacy
      , visibleIf = \_ -> True
      }
    , { id = "level"
      , label = "📊 Level / Rank"
      , view = viewFilterLevel
      , visibleIf = Data.hasMultipleMinmaxValues "level"
      }
    , { id = "pfs"
      , label = "🔵 PFS"
      , view = viewFilterPfs
      , visibleIf = moreThanOneValueAggregation "pfs" >> (&&) (not model.starfinder)
      }
    , { id = "rarities"
      , label = "💎 Rarities"
      , view = viewFilterRarities
      , visibleIf = moreThanOneValueAggregation "rarity"
      }
    , { id = "regions"
      , label = "🌐 Regions"
      , view = viewFilterRegions
      , visibleIf = moreThanOneValueAggregation "region"
      }
    , { id = "sfs"
      , label = "🔵 SFS"
      , view = viewFilterPfs
      , visibleIf = moreThanOneValueAggregation "pfs" >> (&&) model.starfinder
      }
    , { id = "sizes"
      , label = "🐥 Sizes"
      , view = viewFilterSizes
      , visibleIf = moreThanOneValueAggregation "size"
      }
    , { id = "skills"
      , label = "🏅 Skills"
      , view = viewFilterSkills
      , visibleIf = moreThanOneValueAggregation "skill"
      }
    , { id = "sources"
      , label = "📚 Sources / Spoilers"
      , view = viewFilterSources
      , visibleIf = moreThanOneValueAggregation "source"
      }
    , { id = "spells"
      , label = "✨  Spells / Rituals"
      , view = viewFilterSpells
      , visibleIf =
            \searchModel ->
                (getAggregationValues "type" searchModel |> List.any ((==) "spell"))
                    || (getAggregationValues "type" searchModel |> List.any ((==) "ritual"))
      }
    , { id = "traits"
      , label = "🔖 Traits"
      , view = viewFilterTraits
      , visibleIf = moreThanOneValueAggregation "trait"
      }
    , { id = "types"
      , label = "📋 Types / Categories"
      , view = viewFilterTypes
      , visibleIf = moreThanOneValueAggregation "type"
      }
    , { id = "weapons"
      , label = "⚔ Weapons"
      , view = viewFilterWeapons
      , visibleIf = getAggregationValues "item_subcategory" >> List.any ((==) "base weapons")
      }
    ]
        |> List.filter (\filterBox -> filterBox.id /= "legacy" || not model.starfinder)


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
    , { id = "default-params"
      , label = "Default params"
      , view = viewDefaultParams
      , visibleIf = \_ -> True
      }
    , { id = "settings"
      , label = "General settings"
      , view = viewGeneralSettings
      , visibleIf = \_ -> True
      }
    , { id = "whats-new"
      , label = "What's new?"
      , view = viewWhatsNew
      , visibleIf = \_ -> True
      }
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
                , HA.attribute "aria-label" ("Close " ++ filter.label)
                , HE.onClick (ShowFilterBox filter.id False)
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "gap-large"
            ]
            (filter.view model searchModel)
        ]


viewQueryType : Model -> SearchModel -> List (Html Msg)
viewQueryType model searchModel =
    let
        currentQuery : String
        currentQuery =
            currentQueryAsComplex searchModel
    in
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
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
            [ HA.class "column"
            , HA.class "gap-small"
            ]
            ("""
            The standard query type behaves like most search engines, searching on keywords. It
            includes results that are similar to what you searched for to help catch misspellings
            (a.k.a. fuzzy matching). Results matching by name are scored higher than results
            matching in the description.

            The complex query type allows you to write queries using Elasticsearch Query String
            syntax. It doesn't do fuzzy matching by default, and allows searching for phrases by
            surrounding them with quotes. It also allows searching in specific fields with the
            syntax `field:value`. For full documentation on how the query syntax works see
            [Elasticsearch's documentation][1]. In addition there's two syntax extensions:

            - Starting a query with a `~` followed by number specifies [`minimum_should_match`][2].
            - `++` starts a new query. This is useful in conjuction with the above
            `minimum_should_max` syntax.

            [1]: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-syntax
            [2]: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-min-should-match
            """
                |> String.Extra.unindent
                |> parseAndViewAsMarkdown model.viewModel
            )
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Available fields" ]
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
                        Data.allDamageTypes
                        |> List.intersperse (Html.text ", ")
                    )
                ]
            ]
        , Html.text "[n] means the field is numeric and supports range queries."
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Example queries" ]
        , Html.div
            [ HA.class "column"
            ]
            ("""
            Spells (or cantrips) unique to the arcane tradition:
            ```
            tradition:(arcane -divine -occult -primal) type:spell
            ```

            <br />

            Non-consumable items between 500 and 1000 gp (note that price is in copper):
            ```
            price:[50000 TO 100000] NOT trait:consumable
            ```

            <br />

            Spells up to level 5 with a range of at least 100 feet that are granted by any sorcerer bloodline:
            ```
            type:spell level:<=5 range:>=100 bloodline:*
            ```

            <br />

            Rules pages that mention 'mental damage':
            ```
            "mental damage" type:rules
            ```

            <br />

            Weapons with finesse and at least two of agile, disarm, and trip:
            ```
            trait:finesse ++ ~2 trait:agile OR trait:disarm OR trait:trip
            ```

            <br />

            Creatures resistant to fire but not all damage:
            ```
            resistance.fire:* NOT resistance.all:*
            ```
            """
                |> String.Extra.unindent
                |> parseAndViewAsMarkdown model.viewModel
            )
        ]
    ]


viewResultPageSize : Model -> SearchModel -> List (Html Msg)
viewResultPageSize model searchModel =
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
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
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text ("Default amount for " ++ model.pageId) ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            (List.append
                (List.map
                    (\size ->
                        viewRadioButton
                            { checked =
                                model.pageSizeDefaults
                                    |> Dict.get model.pageId
                                    |> Maybe.withDefault -1
                                    |> (==) size
                            , enabled = True
                            , name = "page-size-type"
                            , onInput = PageSizeDefaultsChanged model.pageId size
                            , text = String.fromInt size
                            }
                    )
                    Data.pageSizes
                )
                [ viewRadioButton
                    { checked =
                        model.pageSizeDefaults
                            |> Dict.get model.pageId
                            |> Maybe.withDefault 0
                            |> (==) 0
                    , enabled = True
                    , name = "page-size-type"
                    , onInput = PageSizeDefaultsChanged model.pageId 0
                    , text = "Use global"
                    }
                ]
            )
        ]
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Global default amount" ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            (List.map
                (\size ->
                    viewRadioButton
                        { checked =
                            model.pageSizeDefaults
                                |> Dict.get "global"
                                |> Maybe.withDefault 50
                                |> (==) size
                        , enabled = True
                        , name = "page-size-global"
                        , onInput = PageSizeDefaultsChanged "global" size
                        , text = String.fromInt size
                        }
                )
                Data.pageSizes
            )
        ]
    ]


viewGeneralSettings : Model -> SearchModel -> List (Html Msg)
viewGeneralSettings model searchModel =
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ viewCheckbox
            { checked = model.viewModel.openInNewTab
            , onCheck = OpenInNewTabChanged
            , text = "Links open in new tab"
            }
        , viewCheckbox
            { checked = model.alwaysShowFilters
            , onCheck = AlwaysShowFiltersChanged
            , text = "Always show filters and options"
            }
        , viewCheckbox
            { checked = model.showLegacyFilters
            , onCheck = ShowLegacyFiltersChanged
            , text = "Show legacy filters (alignment, casting components, spell schools)"
            }
        ]
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Date format" ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            [ viewRadioButton
                { checked = model.viewModel.dateFormat == "default"
                , enabled = True
                , name = "date-format"
                , onInput = DateFormatChanged "default"
                , text = "Browser default (" ++ model.viewModel.browserDateFormat ++ ")"
                }
            , viewRadioButton
                { checked = model.viewModel.dateFormat == "yyyy-MM-dd"
                , enabled = True
                , name = "date-format"
                , onInput = DateFormatChanged "yyyy-MM-dd"
                , text = "yyyy-MM-dd"
                }
            , viewRadioButton
                { checked = model.viewModel.dateFormat == "MM/dd/yyyy"
                , enabled = True
                , name = "date-format"
                , onInput = DateFormatChanged "MM/dd/yyyy"
                , text = "MM/dd/yyyy"
                }
            , viewRadioButton
                { checked = model.viewModel.dateFormat == "dd/MM/yyyy"
                , enabled = True
                , name = "date-format"
                , onInput = DateFormatChanged "dd/MM/yyyy"
                , text = "dd/MM/yyyy"
                }
            ]
        ]
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
        Default parameters are filters and options automatically applied when
        you visit a page without any search parameters in the URL. These
        defaults are saved per page type. You can view the defaults for the
        current page type below.
        """
    , Html.div
        [ HA.class "row"
        , HA.class "gap-small"
        ]
        [ Html.button
            [ HE.onClick SaveDefaultParamsPressed
            ]
            [ Html.text "Save current filters as default" ]
        , Html.button
            [ HE.onClick ResetDefaultParamsPressed
            , HA.disabled (not (Dict.member model.pageId model.pageDefaultParams))
            ]
            [ Html.text "Reset to site defaults" ]
        ]
    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text ("Defaults for " ++ model.pageId) ]
        , viewActiveFilters model pageDefaultSearchModel False
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
                        Short ->
                            "Short"

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

                Grouped ->
                    Html.div
                        []
                        [ Html.text "Group by: "
                        , Maybe.Extra.values
                            [ Just pageDefaultSearchModel.groupField1
                            , pageDefaultSearchModel.groupField2
                            , pageDefaultSearchModel.groupField3
                            ]
                            |> List.map String.Extra.humanize
                            |> List.map toTitleCase
                            |> String.join ", "
                            |> Html.text
                        ]

                _ ->
                    Html.text ""
            ]
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
            { checked = searchModel.resultDisplay == Short
            , enabled = True
            , name = "result-display"
            , onInput = ResultDisplayChanged Short
            , text = "Short"
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
        , HA.class "gap-large"
        ]
        (case searchModel.resultDisplay of
            Short ->
                viewResultDisplayShort model.viewModel

            Full ->
                viewResultDisplayFull model

            Table ->
                viewResultDisplayTable model searchModel

            Grouped ->
                viewResultDisplayGrouped model searchModel
        )
    ]


viewResultDisplayShort : ViewModel -> List (Html Msg)
viewResultDisplayShort viewModel =
    [ Html.h3
        []
        [ Html.text "Short configuration" ]
    , viewCheckbox
        { checked = viewModel.showResultIndex
        , onCheck = ShowResultIndexChanged
        , text = "Show result index"
        }
    , viewCheckbox
        { checked = viewModel.showResultPfs
        , onCheck = ShowShortPfsChanged
        , text = "Show PFS/SFS icon"
        }
    , viewCheckbox
        { checked = viewModel.showResultSpoilers
        , onCheck = ShowSpoilersChanged
        , text = "Show spoiler warning"
        }
    , viewCheckbox
        { checked = viewModel.showResultTraits
        , onCheck = ShowTraitsChanged
        , text = "Show traits"
        }
    , viewCheckbox
        { checked = viewModel.showResultAdditionalInfo
        , onCheck = ShowAdditionalInfoChanged
        , text = "Show additional info"
        }
    , viewCheckbox
        { checked = viewModel.showResultSummary
        , onCheck = ShowSummaryChanged
        , text = "Show summary"
        }
    ]
        |> Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
        |> List.singleton


viewResultDisplayFull : Model -> List (Html Msg)
viewResultDisplayFull model =
    []


viewResultDisplayTable : Model -> SearchModel -> List (Html Msg)
viewResultDisplayTable model searchModel =
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Table columns" ]
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
                                    , HA.attribute "aria-label" ("Remove " ++ column ++ " column")
                                    ]
                                    [ FontAwesome.view FontAwesome.Solid.times
                                    ]
                                , Html.button
                                    [ HA.disabled (index == 0)
                                    , HE.onClick (TableColumnMoved index (index - 1))
                                    , HA.attribute "aria-label" ("Move " ++ column ++ " column up")
                                    ]
                                    [ FontAwesome.view FontAwesome.Solid.chevronUp
                                    ]
                                , Html.button
                                    [ HA.disabled (index + 1 == List.length searchModel.tableColumns)
                                    , HE.onClick (TableColumnMoved index (index + 1))
                                    , HA.attribute "aria-label" ("Move " ++ column ++ " column down")
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
                , viewFilterSearch searchModel "table-columns"
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
                                (String.replace "_" " "
                                    >> caseInsensitiveContains
                                        (dictGetString "table-columns" searchModel.searchFilters)
                                )
                            |> List.filter
                                (\field ->
                                    if model.showLegacyFilters then
                                        True

                                    else
                                        List.member
                                            field
                                            [ "alignment"
                                            , "component"
                                            , "follower_alignment"
                                            , "school"
                                            ]
                                            |> not
                                )
                        )
                    )
                ]
            ]
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Predefined column sets" ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-small"
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

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Export table data" ]
        , Html.text "Note that only loaded rows are exported. If you want to include all rows make sure to load everything first."
        , Html.div
            [ HA.class "row"
            , HA.class "gap-small"
            ]
            [ Html.button
                [ HA.style "align-self" "flex-start"
                , HE.onClick ExportAsCsvPressed
                ]
                [ Html.text "Export as CSV" ]
            , Html.button
                [ HA.style "align-self" "flex-start"
                , HE.onClick ExportAsJsonPressed
                ]
                [ Html.text "Export as JSON" ]
            ]
        ]
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
            , HA.attribute "aria-label" ("Toggle " ++ column ++ " column")
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
                , onInput = SelectValueChanged "resistance"
                , selected =
                    Dict.get "resistance" searchModel.selectValues
                        |> Maybe.withDefault "acid"
                , types = Data.allDamageTypes
                }

        "speed" ->
            viewResultDisplayTableColumnWithSelect
                searchModel
                { column = column
                , onInput = SelectValueChanged "speed"
                , selected =
                    Dict.get "speed" searchModel.selectValues
                        |> Maybe.withDefault "land"
                , types = Data.speedTypes
                }

        "weakness" ->
            viewResultDisplayTableColumnWithSelect
                searchModel
                { column = column
                , onInput = SelectValueChanged "weakness"
                , selected =
                    Dict.get "weakness" searchModel.selectValues
                        |> Maybe.withDefault "acid"
                , types = Data.allDamageTypes
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
            [ HAE.attributeIf (List.member columnWithType searchModel.tableColumns) (HA.class "active")
            , if List.member columnWithType searchModel.tableColumns then
                HE.onClick (TableColumnRemoved columnWithType)

              else
                HE.onClick (TableColumnAdded columnWithType)
            , HA.attribute "aria-label" ("Toggle " ++ selected ++ " " ++ column ++ " column")
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
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Group by" ]
        , viewFilterSearch searchModel "group-by"
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
                    (Data.groupFields
                        |> List.filter
                            (String.replace "_" " "
                                >> caseInsensitiveContains
                                    (dictGetString "group-by" searchModel.searchFilters)
                            )
                        |> List.filter
                            (\field ->
                                if model.showLegacyFilters then
                                    True

                                else
                                    List.member
                                        field
                                        [ "alignment"
                                        , "school"
                                        ]
                                        |> not
                            )
                    )
                )
            ]
        , Html.div
            []
            [ Html.span
                [ HA.class "bold" ]
                [ Html.text "First" ]
            , Html.text ": "
            , Html.text (toTitleCase (String.Extra.humanize searchModel.groupField1))
            ]
        , case searchModel.groupField2 of
            Just groupField2 ->
                Html.div
                    []
                    [ Html.span
                        [ HA.class "bold" ]
                        [ Html.text "Second" ]
                    , Html.text ": "
                    , Html.text (toTitleCase (String.Extra.humanize groupField2))
                    ]

            Nothing ->
                Html.text ""
        , case searchModel.groupField3 of
            Just groupField3 ->
                Html.div
                    []
                    [ Html.span
                        [ HA.class "bold" ]
                        [ Html.text "Third" ]
                    , Html.text ": "
                    , Html.text (toTitleCase (String.Extra.humanize groupField3))
                    ]

            Nothing ->
                Html.text ""
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Badge configuration" ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            [ viewCheckbox
                { checked = model.viewModel.groupedShowPfs
                , onCheck = GroupedShowPfsIconChanged
                , text = "PFS/SFS icons"
                }
            , viewCheckbox
                { checked = model.viewModel.groupedShowHeightenable
                , onCheck = GroupedShowHeightenableChanged
                , text = "Heightenable"
                }
            , viewCheckbox
                { checked = model.viewModel.groupedShowRarity
                , onCheck = GroupedShowRarityChanged
                , text = "Rarity"
                }
            ]
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
            , Html.Keyed.node "div"
                [ HA.class "scrollbox"
                , HA.class "column"
                , HA.class "gap-small"
                ]
                (List.indexedMap
                    (\index ( field, dir ) ->
                        ( field
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            , HA.class "align-center"
                            ]
                            [ Html.button
                                [ HE.onClick (SortRemoved field)
                                , HA.attribute "aria-label" ("Remove " ++ field ++ " sort")
                                , HA.title "Remove"
                                ]
                                [ FontAwesome.view FontAwesome.Solid.times
                                ]
                            , if field == "random" then
                                Html.text ""

                              else
                                Html.button
                                    [ HE.onClick (SortAdded field (if dir == Asc then Desc else Asc))
                                    , HA.attribute "aria-label" ("Toggle " ++ field ++ " sort direction")
                                    , HA.title "Toggle sort direction"
                                    ]
                                    [ viewSortIcon field (Just dir)
                                    ]
                            , if field == "random" then
                                Html.text ""

                              else
                                Html.button
                                    [ HA.disabled (index == 0)
                                    , HE.onClick (SortOrderChanged index (index - 1))
                                    , HA.attribute "aria-label" ("Move " ++ field ++ " sort up")
                                    , HA.title "Move up"
                                    ]
                                    [ FontAwesome.view FontAwesome.Solid.chevronUp
                                    ]
                            , if field == "random" then
                                Html.text ""

                              else
                                Html.button
                                    [ HA.disabled (index + 1 == List.length searchModel.sort)
                                    , HE.onClick (SortOrderChanged index (index + 1))
                                    , HA.attribute "aria-label" ("Move " ++ field ++ " sort down")
                                    , HA.title "Move down"
                                    ]
                                    [ FontAwesome.view FontAwesome.Solid.chevronDown
                                    ]
                            , Html.text (sortFieldToLabel field)
                            ]
                        )
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
            , viewFilterSearch searchModel "sort-fields"
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
                        |> List.filter
                            (String.replace "_" " "
                                >> caseInsensitiveContains
                                    (dictGetString "sort-fields" searchModel.searchFilters)
                            )
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
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
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
    ]


viewSortResultsField : SearchModel -> String -> Html Msg
viewSortResultsField searchModel field =
    case field of
        "resistance" ->
            viewSortResultsFieldWithSelect
                searchModel
                { field = field
                , onInput = SelectValueChanged "resistance"
                , selected =
                    Dict.get "resistance" searchModel.selectValues
                        |> Maybe.withDefault "acid"
                , types = Data.allDamageTypes
                }

        "speed" ->
            viewSortResultsFieldWithSelect
                searchModel
                { field = field
                , onInput = SelectValueChanged "speed"
                , selected =
                    Dict.get "speed" searchModel.selectValues
                        |> Maybe.withDefault "land"
                , types = Data.speedTypes
                }

        "weakness" ->
            viewSortResultsFieldWithSelect
                searchModel
                { field = field
                , onInput = SelectValueChanged "weakness"
                , selected =
                    Dict.get "weakness" searchModel.selectValues
                        |> Maybe.withDefault "acid"
                , types = Data.allDamageTypes
                }

        _ ->
            Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                ]
                (List.append
                    (viewSortButtons searchModel field)
                    [ Html.text
                        (field
                            |> String.Extra.humanize
                            |> toTitleCase
                        )
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
        , HA.class "align-center"
        ]
        [ Html.text "Asc"
        , viewSortIcon field (Just Asc)
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
        , HA.class "align-center"
        ]
        [ Html.text "Desc"
        , viewSortIcon field (Just Desc)
        ]
    ]


viewWhatsNew : Model -> SearchModel -> List (Html Msg)
viewWhatsNew model _ =
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        , HA.class "header-margins"
        , HA.class "no-ul-margin"
        ]
        ("""
        ### Field changes
        - `vehicle_type` - new

        ### Previous updates

        <details summary="2025-07-31">
        ### Field changes

        <details summary="Show details">
        - `epithet` - new
        - `expend` - new
        - `grade` - new
        - `location` - new
        - `tactic_type` - new
        - `upgrades` - new
        </details>

        </details>

        <details summary="2024-07-21">
        ### Filter menu

        A new way to apply filters and sorting has been added. Use the button to the left of the
        query box or press Ctrl+Space to show the filter menu. This also allows for filtering things
        that was previously only possible with complex queries, like for example creature spells,
        hazard complexity, or poison onset duration.


        ### Min and max values

        Numeric inputs now display minimum and maximum values.


        ### Show parent items

        A filter has been added to the _Items_ filter menu to only show the parent item for items
        with multiple children variants (e.g. runes).
        </details>

        <details summary="2024-05-27">
        ### Filter button changes &amp; new filters

        Filter buttons have been reorganized in an effort to reduce the number of buttons.

        <details summary="Show details">
        - **Armor**: Now has filters related to armors like AC, Dex Cap and Check Penalty.
        - **Attributes**: Now also has numerical attribute filters.
        - **Creatures**: New button that has everything creature-related, including new scale
          filters that match statistics relative to creature building rules.
        - **Deities**: New button that has everything deity-related.
        - **Items**: Item categories has been moved here, together with Level, Price, and Bulk
          filters.
        - **Legacy / Remaster**: New filter that allows you to temporarily get results from legacy
          or remaster without using the side-wide setting in Shelyn's Corner.
        - **Level**: New button. It's universal enough to warrant its own button.
        - **Skills**: Now also has filters for Lore Skills.
        - **Sources / Spoilers**: Release Date now lives here.
        - **Spells / Rituals**: New button that has everything magic-related, including new
          filters for areas.
        - **Weapons**: Filters related to weapons have been moved here, like Reload, Hands, and
          Damage Die. A new Damage Types filter has also been added.
        </details>

        Filters buttons are now hidden behind a button by default. There's a setting under _General
        settings_ to disable this and always show them.

        Emojis has been added to the buttons to make them easier to distinguish.


        ### Grouped display updated

        Grouped display now lists number of results not loaded in a more obvious way, and groups can
        be individually loaded.


        ### Mask spoilers

        You can now select a set of source groups for spoiler masking. Results from the selected
        groups will be masked in search results and hover previews. This option is found under
        _Sources / Spoilers_.


        ### Complex query syntax extension

        The complex query syntax has been extended with syntax for specifying the minimum number of
        terms that should match. This allows queries like "at least 2 of these 4 things". Read more
        under _Query type_.


        ### Search optimization

        The search has become faster and more efficient. Read more in [this reddit post].

        [this reddit post]:
        https://www.reddit.com/r/Pathfinder2e/comments/1c33xhv/aons_search_is_going_to_become_even_faster/


        ### Field changes

        <details summary="Show details">
        - `ac_scale` - new
        - `area` - changed: Now holds numerical area values.
        - `area_raw` - new: Holds what was previously in `area`.
        - `area_type` - new
        - `attack_bonus` - new
        - `attack_bonus_scale` - new
        - `charisma_scale` - new
        - `constitution_scale` - new
        - `damage_type` - new
        - `dexterity_scale` - new
        - `fortitude_save_scale` - new
        - `hp_scale` - new
        - `intelligence_scale` - new
        - `perception_scale` - new
        - `reflex_save_scale` - new
        - `sanctification` - new
        - `sanctification_raw` - new
        - `spell_attack_bonus` - new
        - `spell_attack_bonus_scale` - new
        - `spell_dc` - new
        - `spell_dc_scale` - new
        - `strength_scale` - new
        - `strike_damage_average`- new
        - `strike_damage_scale` - new
        - `warden_spell_tier` - new
        - `will_save_scale` - new
        - `wisdom_scale` - new
        </details>

        </details>

        <details summary="2024-03-13">
        - Added option under _General settings_ to hide legacy filters (hides alignment, casting component, and spell school filters).
        - Added table data export functionality. Found under _Result display_ when set to "Table", where you can export to CSV or JSON.
        - "List" display option renamed to "Short". The old name made more sense when there only was it and "Table", but now "Grouped" is probably more list-y than "Short".
        - Added result indices to "Short" and "Full" (and an option to hide them).
        - Added option to hide PFS icons in "Short" display.
        - Date format is now configurable under _General settings_. Defaults to your browser's default format.
        - Default result amount can now be set per page type.
        - Removed "Cantrip" and "Focus" types; they now use the "Spell" type. You can use the respective traits or the new `spell_type` field to filter them. The goal of this change is to reduce confusion. A user might've thought that filtering for "Spell" would give them all spells including cantrips, which it now will.
        - Removed "Armor", "Shield", and "Weapon" types; they now use the "Item" type. You can use item categories to filter them. Same reasoning as above, but in regards to specific variants.
        - Actions, rarities, and sizes are now sorted "numerically" instead of alphabetically.
        - Items with no bulk are now treated as 0 bulk.
        - Added domain filter buttons.
        - Added trait group filter buttons.
        - Added filter under _Sources / Spoilers_ that hides creatures from Adventure Paths.
        - In "Grouped" display "N/A" group headers are no longer displayed if they're the sole group on that level. This reduces clutter when grouping on item category + item subcategory, for example.
        - Added a "skip to results"-link when tabbing from the query input field.
        - New/changed fields:
            - `ac` - changed: now available as a grouped field
            - `armor_category` - changed: now available as a grouped field
            - `armor_group` - changed: now available as a grouped field
            - `attribute` - new: available as table column
            - `attribute_boost` - new: alias for `attribute`, available as table column
            - `attribute_flaw` - new: available as a table column
            - `bulk` - changed: now available as a grouped field
            - `deity_category` - changed: now available as a grouped field
            - `defense` - new: alias for `saving_throw`, available as a table column
            - `element` - changed: spells in the elementalist spell list without an elemental trait are now matched by `element:universal`
            - `heighten_group` - new: for grouping spells by heightenable rank
            - `legacy_name` - new: name of legacy equivalent
            - `pantheon` - new: available as a table column
            - `pantheon_member` - new: available as a table column
            - `rank` - new: alias for `level`, available as a table column and grouped field
            - `remaster_name` - new: name of remaster equivalent
            - `sanctification` - new: deity sanctification, available as table column and grouped field
            - `spell_type` - new: matches Cantrip / Focus / Spell, available as a table column
            - `skill_mod` - new: can be used to find creatures with a specific skill modifier, except lore skills for technical reasons
            - `trait_group` - changed: is now indexed on everything, e.g. `type:feat trait_group:ancestry` matches all feats with an ancestry trait
            - `url` - changed: now available as a table column
        </details>
        """
            |> String.Extra.unindent
            |> parseAndViewAsMarkdown model.viewModel
        )
    ]


viewFilterActions : Model -> SearchModel -> List (Html Msg)
viewFilterActions model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "actions"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "actions" searchModel
                |> List.sortBy actionsToInt
        }
    ]


viewFilterAlignments : Model -> SearchModel -> List (Html Msg)
viewFilterAlignments model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "alignments"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "alignment" searchModel
                |> List.filter (\a -> List.member a (List.map Tuple.first Data.allAlignments))
                |> List.sort
        }
    ]


viewFilterArmor : Model -> SearchModel -> List (Html Msg)
viewFilterArmor model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = "Armor categories"
        , filterKey = "armor-categories"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "armor_category" searchModel
                |> List.sortWith (Order.Extra.explicit armorCategories)
        }
    , viewFilterList
        model
        searchModel
        { label = "Armor groups"
        , filterKey = "armor-groups"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "armor_group" searchModel
                |> List.sort
        }
    , Html.div
        [ HA.class "numbers-grid" ]
        (List.map
            (viewFilterNumber searchModel)
            [ { field = "ac"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "dex_cap"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "check_penalty"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "strength"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "bulk"
              , hint = Just "(L bulk is 0.1)"
              , step = "0.1"
              , suffix = Nothing
              }
            , { field = "price"
              , hint = Nothing
              , step = "1"
              , suffix = if model.starfinder then Nothing else Just "cp"
              }
            ]
        )
    ]


viewFilterAttributes : Model -> SearchModel -> List (Html Msg)
viewFilterAttributes model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "attributes"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "attribute" searchModel
                |> List.filter (\trait -> List.member trait Data.allAttributes)
                |> List.sortWith (Order.Extra.explicit Data.allAttributes)
        }
    , Html.div
        [ HA.class "numbers-grid"
        ]
        (List.map
            (\attribute ->
                viewFilterNumber
                    searchModel
                    { field = attribute
                    , hint = Nothing
                    , step = "1"
                    , suffix = Nothing
                    }
            )
            Data.allAttributes
        )
    ]


viewFilterCreatures : Model -> SearchModel -> List (Html Msg)
viewFilterCreatures model searchModel =
    let
        details : String -> List (Html msg) -> Html msg
        details label children =
            Html.details
                []
                [ Html.summary
                    [ HA.class "h3" ]
                    [ Html.text label ]
                , Html.div
                    [ HA.class "column"
                    , HA.class "gap-medium"
                    , HA.style "margin-top" "var(--gap-small)"
                    , HA.style "margin-left" "var(--gap-large)"
                    ]
                    children
                ]

        scaleDetails : String -> List ( String, String, List String ) -> Html Msg
        scaleDetails detailsLabel scales =
            details
                detailsLabel
                [ Html.div
                    [ HA.class "scale-grid" ]
                    (List.map
                        (\( filterType, label, values ) ->
                            viewFilterList
                                model
                                searchModel
                                { label = label
                                , filterKey = filterType
                                , showOperator = False
                                , showSearch = False
                                , values = values
                                }
                        )
                        scales
                    )
                ]
    in
    [ details
        "Statistics"
        [ Html.div
            [ HA.class "numbers-grid" ]
            (List.concat
                [ List.map
                    (viewFilterNumber searchModel)
                    [ { field = "level"
                      , hint = Nothing
                      , step = "1"
                      , suffix = Nothing
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
                , List.map
                    (viewFilterNumberWithSelect searchModel)
                    [ { field = "speed"
                      , values = Data.speedTypes
                      , default = "land"
                      , hint = Nothing
                      , step = "1"
                      , suffix = Nothing
                      }
                    , { field = "resistance"
                      , values = Data.allDamageTypes
                      , default = "acid"
                      , hint = Nothing
                      , step = "1"
                      , suffix = Nothing
                      }
                    , { field = "weakness"
                      , values = Data.allDamageTypes
                      , default = "acid"
                      , hint = Nothing
                      , step = "1"
                      , suffix = Nothing
                      }
                    , { field = "skill_mod"
                      , values =
                            Data.allSkills
                                |> List.Extra.remove "lore"
                      , default = "acrobatics"
                      , hint = Nothing
                      , step = "1"
                      , suffix = Nothing
                      }
                    ]
                ]
            )
        ]

    , details
        "Creature families"
        [ viewFilterList
            model
            searchModel
            { label = ""
            , filterKey = "creature-families"
            , showOperator = False
            , showSearch = True
            , values =
                getAggregationValues "creature_family" searchModel
                    |> List.sort
            }
        ]


    -- TODO: From aggs
    , scaleDetails
        "Offensive scales"
        [ ( "attack-bonus-scales", "Attack bonus scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "strike-damage-scales", "Strike damage scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "spell-attack-bonus-scales", "Spell attack bonus scale", [ "moderate", "high", "extreme" ] )
        , ( "spell-dc-scales", "Spell DC scale", [ "moderate", "high", "extreme" ] )
        ]

    , scaleDetails
        "Defensive scales"
        [ ( "hp-scales", "HP scale", [ "low", "moderate", "high" ] )
        , ( "ac-scales", "AC scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "fortitude-scales", "Fortitude save scale", [ "terrible", "low", "moderate", "high", "extreme" ] )
        , ( "reflex-scales", "Reflex save scale", [ "terrible", "low", "moderate", "high", "extreme" ] )
        , ( "will-scales", "Will save scale", [ "terrible", "low", "moderate", "high", "extreme" ] )
        , ( "perception-scales", "Perception scale", [ "terrible", "low", "moderate", "high", "extreme" ] )
        ]

    , scaleDetails
        "Attribute scales"
        [ ( "strength-scales", "Strength scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "dexterity-scales", "Dexterity scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "constitution-scales", "Constitution scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "intelligence-scales", "Intelligence scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "wisdom-scales", "Wisdom scale", [ "low", "moderate", "high", "extreme" ] )
        , ( "charisma-scales", "Charisma scale", [ "low", "moderate", "high", "extreme" ] )
        ]

    , details
        "Strongest save"
        [ viewFilterList
            model
            searchModel
            { label = ""
            , filterKey = "strongest-saves"
            , showOperator = False
            , showSearch = False
            , values =
                getAggregationValues "strongest_save" searchModel
                    |> List.filter (\s -> List.Extra.notMember s [ "fort", "ref" ])
                    |> List.sort
            }
        ]

    , details
        "Weakest save"
        [ viewFilterList
            model
            searchModel
            { label = ""
            , filterKey = "weakest-saves"
            , showOperator = False
            , showSearch = False
            , values =
                getAggregationValues "weakest_save" searchModel
                    |> List.filter (\s -> List.Extra.notMember s [ "fort", "ref" ])
                    |> List.sort
            }
        ]

    , details
        "Spells"
        [ viewFilterList
            model
            searchModel
            { label = ""
            , filterKey = "spells"
            , showOperator = False
            , showSearch = True
            , values =
                getAggregationValues "spell" searchModel
                    |> List.sort
            }
        ]

    , details
        "Spellcasting traditions"
        [ viewFilterList
            model
            searchModel
            { label = ""
            , filterKey = "traditions"
            , showOperator = True
            , showSearch = False
            , values =
                getAggregationValues "tradition" searchModel
                    |> List.sort
            }
        ]
    ]


viewFilterDeities : Model -> SearchModel -> List (Html Msg)
viewFilterDeities model searchModel =
    [  viewFilterList
        model
        searchModel
        { label = "Deity categories"
        , filterKey = "deity-categories"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "deity_category" searchModel
                |> List.sort
        }

    , viewFilterList
        model
        searchModel
        { label = "Divine font"
        , filterKey = "divine-fonts"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "divine_font" searchModel
                |> List.sort
        }

    , viewFilterList
        model
        searchModel
        { label = "Sanctification"
        , filterKey = "sanctifications"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "sanctification" searchModel
                |> List.sort
        }

    , viewFilterList
        model
        searchModel
        { label = "Favored weapons"
        , filterKey = "favored-weapons"
        , showOperator = False
        , showSearch = True
        , values =
            getAggregationValues "favored_weapon" searchModel
                |> List.sort
        }

    , viewFilterList
        model
        searchModel
        { label = "Pantheons"
        , filterKey = "pantheons"
        , showOperator = False
        , showSearch = True
        , values =
            getAggregationValues "pantheon" searchModel
                |> List.sort
        }
    ]


viewFilterDomains : Model -> SearchModel -> List (Html Msg)
viewFilterDomains model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "domains"
        , showOperator = True
        , showSearch = True
        , values =
            getAggregationValues "domain" searchModel
                |> List.sort
        }
    ]


viewFilterItems : Model -> SearchModel -> List (Html Msg)
viewFilterItems model searchModel =
    let
        searchValue : String
        searchValue =
            dictGetString "item-subcategories" searchModel.searchFilters
    in
    [ Html.div
        [ HA.class "numbers-grid"
        ]
        (List.map
            (viewFilterNumber searchModel)
            [ { field = "level"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "price"
              , hint = Nothing
              , step = "1"
              , suffix = if model.starfinder then Nothing else Just "cp"
              }
            , { field = "bulk"
              , hint = Just "(L bulk is 0.1)"
              , step = "0.1"
              , suffix = Nothing
              }
            , { field = "item_bonus_value"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            ]
        )

    , viewFilterList
        model
        searchModel
        { label = "Item categories"
        , filterKey = "item-categories"
        , showOperator = False
        , showSearch = True
        , values =
            getAggregationValues "item_category" searchModel
                |> List.sort
        }

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Item subcategories" ]
        , viewFilterButtons searchModel "item-subcategories" False
        , viewFilterSearch searchModel "item-subcategories"
        , viewFilterScrollbox
            model
            searchModel
            "item-subcategories"
            (case searchModel.aggregations of
                Just (Ok aggregations) ->
                    aggregations.itemSubcategories
                        |> List.filter
                            (\{ category } ->
                                (&&)
                                    (case boolDictIncluded "item-categories" searchModel.filteredValues of
                                        [] ->
                                            True

                                        categories ->
                                            List.member category categories
                                    )
                                    (case boolDictExcluded "item-categories" searchModel.filteredValues of
                                        [] ->
                                            True

                                        categories ->
                                            not (List.member category categories)
                                    )
                            )
                        |> List.map .name
                        |> List.sort

                Just (Err _) ->
                    []

                Nothing ->
                    []
            )
        ]

    , viewFilterList
        model
        searchModel
        { label = "Item Bonus Actions"
        , filterKey = "item-bonus-actions"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "item_bonus_action" searchModel
                |> List.sort
        }

    , viewFilterList
        model
        searchModel
        { label = "Item Bonus Consumable"
        , filterKey = "item-bonus-consumable"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "item_bonus_consumable" searchModel
                |> List.sort
                |> List.reverse
        }

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Items with children variants" ]
        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            [ viewRadioButton
                { checked = searchModel.filterItemChildren
                , enabled = True
                , name = "item-children"
                , onInput = FilterItemChildrenChanged True
                , text = "Show separately"
                }
            , viewRadioButton
                { checked = not searchModel.filterItemChildren
                , enabled = True
                , name = "item-children"
                , onInput = FilterItemChildrenChanged False
                , text = "Show parent"
                }
            ]
        ]
    ]


viewFilterLegacy : Model -> SearchModel -> List (Html Msg)
viewFilterLegacy model searchModel =
    [ Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        ]
        [ viewRadioButton
            { checked = searchModel.legacyMode == Nothing
            , enabled = True
            , name = "legacy"
            , onInput = LegacyModeChanged Nothing
            , text = "Use site mode (" ++ (if model.legacyMode then "Legacy" else "Remaster") ++ ")"
            }
        , viewRadioButton
            { checked = searchModel.legacyMode == Just True
            , enabled = True
            , name = "legacy"
            , onInput = LegacyModeChanged (Just True)
            , text = "Legacy"
            }
        , viewRadioButton
            { checked = searchModel.legacyMode == Just False
            , enabled = True
            , name = "legacy"
            , onInput = LegacyModeChanged (Just False)
            , text = "Remaster"
            }
        ]
    ]


viewFilterLevel : Model -> SearchModel -> List (Html Msg)
viewFilterLevel model searchModel =
    [ viewFilterNumber
        searchModel
            { field = "level"
            , hint = Just "/ Rank"
            , step = "1"
            , suffix = Nothing
            }
    ]


viewFilterPfs : Model -> SearchModel -> List (Html Msg)
viewFilterPfs model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = if model.starfinder then "sfs" else "pfs"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "pfs" searchModel
                |> (::) "none"
        }
    ]


viewFilterRarities : Model -> SearchModel -> List (Html Msg)
viewFilterRarities model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "rarities"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "rarity" searchModel
                |> List.sortWith (Order.Extra.explicit Data.rarities)
        }
    ]


viewFilterRegions : Model -> SearchModel -> List (Html Msg)
viewFilterRegions model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "regions"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "region" searchModel
                |> List.sort
        }
    ]


viewFilterSizes : Model -> SearchModel -> List (Html Msg)
viewFilterSizes model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "sizes"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "size" searchModel
                |> List.sortWith (Order.Extra.explicit Data.allSizes)
        }
    ]


viewFilterSkills : Model -> SearchModel -> List (Html Msg)
viewFilterSkills model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "skills"
        , showOperator = True
        , showSearch = False
        , values =
            getAggregationValues "skill" searchModel
                |> List.filter (\skill -> List.member skill Data.allSkills)
                |> List.sort
        }
    , viewFilterList
        model
        searchModel
        { label = "Lore skills"
        , filterKey = "lore-skills"
        , showOperator = True
        , showSearch = True
        , values =
            getAggregationValues "skill" searchModel
                |> List.filter (String.endsWith "lore")
                |> List.filter ((/=) "lore")
                |> List.sort
        }
    ]


viewFilterSources : Model -> SearchModel -> List (Html Msg)
viewFilterSources model searchModel =
    let
        searchValue : String
        searchValue =
            dictGetString "sources" searchModel.searchFilters
    in
    [ Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ viewCheckbox
            { checked = searchModel.filterSpoilers
            , onCheck = FilterSpoilersChanged
            , text = "Hide results with spoilers"
            }
        , viewCheckbox
            { checked = searchModel.filterApCreatures
            , onCheck = FilterApCreaturesChanged
            , text = "Hide creatures from Adventure Paths"
            }
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "gap-small"
            , HA.class "align-center"
            ]
            [ Html.h3
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
                    , HA.value (dictGetString "release_date" searchModel.filteredFromValues)
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
                    , HA.value (dictGetString "release_date" searchModel.filteredToValues)
                    , HE.onInput (FilteredToValueChanged "release_date")
                    ]
                    []
                ]
            ]
        ]

    , viewFilterList
        model
        searchModel
        { label = "Source categories"
        , filterKey = "source-categories"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "source_category" searchModel
                |> List.sort
        }

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Sources" ]
        , viewFilterButtons searchModel "sources" False
        , viewFilterSearch searchModel "sources"
        , viewFilterScrollbox
            model
            searchModel
            "sources"
            (case ( model.globalAggregations, searchModel.aggregations ) of
                ( Just (Ok globalAggregations), Just (Ok aggregations) ) ->
                    globalAggregations.sources
                        |> List.filter (\source -> List.member source.name (getAggregationValues "source" searchModel))
                        |> List.filter
                            (\{ category } ->
                                (&&)
                                    (case boolDictIncluded "source-categories" searchModel.filteredValues of
                                        [] ->
                                            True

                                        categories ->
                                            List.member category categories
                                    )
                                    (case boolDictExcluded "source-categories" searchModel.filteredValues of
                                        [] ->
                                            True

                                        categories ->
                                            not (List.member category categories)
                                    )
                            )
                        |> List.map .name
                        |> List.sort

                ( Just (Err _), _ ) ->
                    []

                ( _, Just (Err _) ) ->
                    []

                _ ->
                    []
            )
        ]

    , Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h3
            []
            [ Html.text "Mask Spoilers" ]
        , Html.text "Masks results and previews from the selected source groups. This is saved between page visits."
        , viewFilterSearch model.searchModel "mask-spoilers"
        , Html.div
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "scrollbox"
            ]
            (case model.globalAggregations of
                Just (Ok globalAggregations) ->
                    List.map
                        (\sourceGroup ->
                            Html.button
                                [ HA.class "row"
                                , HA.class "gap-tiny"
                                , HA.class "align-center"
                                , HE.onClick (MaskSourceGroupToggled sourceGroup)
                                ]
                                [ Html.text (toTitleCase sourceGroup)
                                , viewFilterIcon
                                    (if Set.member sourceGroup model.viewModel.maskedSourceGroups then
                                        Just False

                                     else
                                         Nothing
                                    )
                                ]
                        )
                        (globalAggregations.sources
                            |> List.filterMap .group
                            |> List.filter
                                (caseInsensitiveContains
                                    (dictGetString "mask-spoilers" searchModel.searchFilters)
                                )
                            |> List.Extra.unique
                            |> List.sort
                        )

                Just (Err _) ->
                    []

                Nothing ->
                    [ viewScrollboxLoader ]
            )
        ]
    ]


viewFilterSpells : Model -> SearchModel -> List (Html Msg)
viewFilterSpells model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = "Traditions / Spell lists"
        , filterKey = "traditions"
        , showOperator = True
        , showSearch = False
        , values =
            getAggregationValues "tradition" searchModel
                |> List.sort
        }

    , if model.showLegacyFilters then
        viewFilterList
            model
            searchModel
            { label = "Magic schools"
            , filterKey = "schools"
            , showOperator = False
            , showSearch = False
            , values =
                getAggregationValues "school" searchModel
                    |> List.sort
            }

        else
            Html.text ""

    , if model.showLegacyFilters then
        viewFilterList
            model
            searchModel
            { label = "Casting components"
            , filterKey = "components"
            , showOperator = False
            , showSearch = False
            , values =
                getAggregationValues "component" searchModel
                    |> List.filter (\v -> List.member v Data.castingComponents)
                    |> List.sort
            }

        else
            Html.text ""

    , viewFilterList
        model
        searchModel
        { label = "Defenses / Saving throws"
        , filterKey = "saving-throws"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "saving_throw" searchModel
                |> List.concatMap Data.explodeSaves
                |> List.Extra.unique
                |> List.sort
        }

    , viewFilterList
        model
        searchModel
        { label = "Area types"
        , filterKey = "area-types"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "area_type" searchModel
                |> List.sort
        }

    , Html.div
        [ HA.class "numbers-grid"
        ]
        (List.map
            (viewFilterNumber searchModel)
            [ { field = "rank"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "range"
              , hint = Nothing
              , step = "1"
              , suffix = Just "ft."
              }
            , { field = "area"
              , hint = Nothing
              , step = "1"
              , suffix = Just "ft."
              }
            , { field = "duration"
              , hint = Just "(1 round is 6s)"
              , step = "1"
              , suffix = Just "s"
              }
            ]
        )
    ]


viewFilterTraits : Model -> SearchModel -> List (Html Msg)
viewFilterTraits model searchModel =
    let
        searchValue : String
        searchValue =
            dictGetString "traits" searchModel.searchFilters
    in
    [ viewCheckbox
        { checked = model.groupTraits
        , onCheck = GroupTraitsChanged
        , text = "Group traits by category"
        }
    , viewFilterButtons searchModel "traits" True
    , viewFilterSearch searchModel "traits"
    , if model.groupTraits then
        Html.div
            [ HA.class "column"
            , HA.class "gap-large"
            ]
            (case ( model.globalAggregations, searchModel.aggregations ) of
                ( Just (Ok globalAggregations), Just (Ok aggregations) ) ->
                    let
                        categorizedTraits : List String
                        categorizedTraits =
                            globalAggregations.traits
                                |> Dict.values
                                |> List.concat

                        uncategorizedTraits : List String
                        uncategorizedTraits =
                            getAggregationValues "trait" searchModel
                                |> List.filter (\trait -> List.Extra.notMember trait categorizedTraits)
                                |> List.filter (\trait -> List.Extra.notMember trait (List.map Tuple.first Data.allAlignments))
                                |> List.filter (\trait -> List.Extra.notMember trait Data.allSizes)
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
                                    [ Html.h3
                                        []
                                        [ Html.text (toTitleCase group) ]
                                    , Html.Extra.viewIf
                                        (group /= "uncategorized")
                                        (Html.button
                                            [ HA.class "row"
                                            , HA.class "gap-tiny"
                                            , HE.onClick (FilterToggled "trait-groups" group)
                                            ]
                                            [ Html.text "Filter group"
                                            , viewFilterIcon (nestedDictGet "trait-groups" group searchModel.filteredValues)
                                            ]
                                        )
                                    , Html.button
                                        [ HE.onClick (TraitGroupDeselectPressed traits)
                                        ]
                                        [ Html.text "Reset group selection" ]
                                    ]
                                , viewFilterScrollbox model searchModel "traits" (List.sort traits)
                                ]
                        )
                        (globalAggregations.traits
                            |> Dict.filter
                                (\group traits ->
                                    not (List.member group [ "half-elf", "half-orc", "aon-special", "settlement" ])
                                )
                            |> Dict.toList
                            |> (::) ( "uncategorized", uncategorizedTraits )
                            |> List.map (Tuple.mapSecond (List.filter (caseInsensitiveContains searchValue)))
                            |> List.map (Tuple.mapSecond (List.filter ((/=) "common")))
                            |> List.map (Tuple.mapSecond (List.filter (\trait -> List.member trait (getAggregationValues "trait" searchModel))))
                            |> List.filter (Tuple.second >> List.isEmpty >> not)
                        )
                    )

                ( Nothing, Nothing ) ->
                    [ viewScrollboxLoader ]

                _ ->
                    []

            )

      else
        viewFilterScrollbox
            model
            searchModel
            "traits"
            (getAggregationValues "trait" searchModel
                |> List.filter (\trait -> List.Extra.notMember trait (List.map Tuple.first Data.allAlignments))
                |> List.filter (\trait -> List.Extra.notMember trait Data.allSizes)
                |> List.filter (\trait -> List.Extra.notMember trait Data.settlementSizes)
                |> List.sort
            )
    ]
        |> Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
        |> List.singleton


viewFilterTypes : Model -> SearchModel -> List (Html Msg)
viewFilterTypes model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = ""
        , filterKey = "types"
        , showOperator = False
        , showSearch = True
        , values =
            getAggregationValues "type" searchModel
                |> List.sort
        }
    ]


viewFilterWeapons : Model -> SearchModel -> List (Html Msg)
viewFilterWeapons model searchModel =
    [ viewFilterList
        model
        searchModel
        { label = "Weapon categories"
        , filterKey = "weapon-categories"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "weapon_category" searchModel
                |> List.sortWith (Order.Extra.explicit Data.weaponCategories)
        }
    , viewFilterList
        model
        searchModel
        { label = "Weapon groups"
        , filterKey = "weapon-groups"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "weapon_group" searchModel
                |> List.sort
        }
    , viewFilterList
        model
        searchModel
        { label = "Weapon types"
        , filterKey = "weapon-types"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "weapon_type" searchModel
                |> List.sort
        }
    , viewFilterList
        model
        searchModel
        { label = "Damage types"
        , filterKey = "damage-types"
        , showOperator = True
        , showSearch = False
        , values =
            getAggregationValues "damage_type" searchModel
                |> List.sort
        }
    , viewFilterList
        model
        searchModel
        { label = "Reload"
        , filterKey = "reloads"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "reload_raw" searchModel
                |> List.sort
        }
    , viewFilterList
        model
        searchModel
        { label = "Hands"
        , filterKey = "hands"
        , showOperator = False
        , showSearch = False
        , values =
            getAggregationValues "hands" searchModel
                |> List.sort
        }
    , Html.div
        [ HA.class "numbers-grid"
        ]
        (List.map
            (viewFilterNumber searchModel)
            [ { field = "bulk"
              , hint = Just "(L bulk is 0.1)"
              , step = "0.1"
              , suffix = Nothing
              }
            , { field = "damage_die"
              , hint = Nothing
              , step = "1"
              , suffix = Nothing
              }
            , { field = "price"
              , hint = Nothing
              , step = "1"
              , suffix = if model.starfinder then Nothing else Just "cp"
              }
            , { field = "range"
              , hint = Nothing
              , step = "1"
              , suffix = Just "ft."
              }
            ]
        )
    ]


viewFilterNumber :
    SearchModel
    -> { field : String
       , hint : Maybe String
       , step : String
       , suffix : Maybe String
       }
    -> Html Msg
viewFilterNumber searchModel { field, hint, step, suffix } =
    case getAggregationMinmax field searchModel of
        Just ( min, max ) ->
            if min < max then
                viewFilterNumberWithMinmax
                    searchModel
                    { field = field
                    , hint = hint
                    , min = min
                    , max = max
                    , step = step
                    , suffix = suffix
                    }

            else
                Html.text ""

        Nothing ->
            Html.text ""


viewFilterNumberWithMinmax :
    SearchModel
    -> { field : String
       , hint : Maybe String
       , min : Float
       , max : Float
       , step : String
       , suffix : Maybe String
       }
    -> Html Msg
viewFilterNumberWithMinmax searchModel { field, hint, step, suffix } =
    Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "gap-small"
            , HA.class "align-center"
            ]
            [ Html.h3
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
                    , HA.value (dictGetString field searchModel.filteredFromValues)
                    , HA.placeholder
                        (getAggregationMinmax field searchModel
                            |> Maybe.map Tuple.first
                            |> Maybe.map String.fromFloat
                            |> Maybe.withDefault ""
                        )
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
                    , HA.value (dictGetString field searchModel.filteredToValues)
                    , HA.placeholder
                        (getAggregationMinmax field searchModel
                            |> Maybe.map Tuple.second
                            |> Maybe.map String.fromFloat
                            |> Maybe.withDefault ""
                        )
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


viewFilterNumberWithSelect :
    SearchModel
    -> { field : String
       , values : List String
       , default : String
       , hint : Maybe String
       , step : String
       , suffix : Maybe String
       }
    -> Html Msg
viewFilterNumberWithSelect searchModel { field, hint, step, suffix, values, default }=
    let
        selected : String
        selected =
            Maybe.withDefault default (Dict.get field searchModel.selectValues)

        currentField : String
        currentField =
            field ++ "." ++ selected
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-tiny"
        ]
        [ Html.h3
            [ HA.class "row"
            , HA.class "gap-tiny"
            , HA.class "align-center"
            ]
            [ Html.select
                [ HA.class "input-container"
                , HA.value selected
                , HE.onInput (SelectValueChanged field)
                ]
                (List.map
                    (\value ->
                        Html.option
                            [ HA.value value ]
                            [ Html.text (String.Extra.humanize value)
                            ]
                    )
                    values
                )
            , Html.text (String.replace "_" " " field)
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
                    , HA.step step
                    , HA.value (dictGetString currentField searchModel.filteredFromValues)
                    , HA.placeholder
                        (getAggregationMinmax currentField searchModel
                            |> Maybe.map Tuple.first
                            |> Maybe.map String.fromFloat
                            |> Maybe.withDefault ""
                        )
                    , HE.onInput (FilteredFromValueChanged currentField)
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
                    , HA.value (dictGetString currentField searchModel.filteredToValues)
                    , HA.placeholder
                        (getAggregationMinmax currentField searchModel
                            |> Maybe.map Tuple.second
                            |> Maybe.map String.fromFloat
                            |> Maybe.withDefault ""
                        )
                    , HE.onInput (FilteredToValueChanged currentField)
                    ]
                    []
                ]
            ]
        ]


viewFilterList :
    Model
    -> SearchModel
    -> { label : String
       , filterKey : String
       , showOperator : Bool
       , showSearch : Bool
       , values : List String
       }
    -> Html Msg
viewFilterList model searchModel { label, filterKey, showOperator, showSearch, values } =
    if List.isEmpty values then
        Html.text ""

    else
        Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
            [ Html.Extra.viewIf
                (label /= "")
                (Html.h3
                    []
                    [ Html.text label ]
                )
            , viewFilterButtons searchModel filterKey showOperator
            , Html.Extra.viewIf showSearch (viewFilterSearch searchModel filterKey)
            , viewFilterScrollbox model searchModel filterKey values
            ]


viewFilterButtons : SearchModel -> String -> Bool -> Html Msg
viewFilterButtons searchModel filterKey showOperator =
    Html.div
        [ HA.class "row"
        , HA.class "align-center"
        , HA.class "gap-medium"
        ]
        [ Html.button
            [ HA.style "align-self" "flex-start"
            , HE.onClick (RemoveAllFiltersOfTypePressed filterKey)
            ]
            [ Html.text "Reset selection" ]
        , Html.Extra.viewIf
            showOperator
            (viewRadioButton
                { checked =
                    Dict.get filterKey searchModel.filterOperators
                        |> Maybe.withDefault True
                , enabled = True
                , name = "operator-" ++ filterKey
                , onInput = FilterOperatorChanged filterKey True
                , text = "Include all (AND)"
                }
            )
        , Html.Extra.viewIf
            showOperator
            (viewRadioButton
                { checked =
                    Dict.get filterKey searchModel.filterOperators
                        |> Maybe.withDefault True
                        |> not
                , enabled = True
                , name = "operator-" ++ filterKey
                , onInput = FilterOperatorChanged filterKey False
                , text = "Include any (OR)"
                }
            )
        ]


viewFilterSearch : SearchModel -> String -> Html Msg
viewFilterSearch searchModel filterKey =
    let
        searchValue : String
        searchValue =
            dictGetString filterKey searchModel.searchFilters
    in
    Html.div
        [ HA.class "row"
        , HA.class "input-container"
        ]
        [ Html.input
            [ HA.placeholder "Search"
            , HA.value searchValue
            , HA.type_ "text"
            , HE.onInput (SearchFilterChanged filterKey)
            ]
            []
        , Html.Extra.viewIf
            (searchValue /= "")
            (Html.button
                [ HA.class "input-button"
                , HA.attribute "aria-label" "Clear search"
                , HE.onClick (SearchFilterChanged filterKey "")
                ]
                [ FontAwesome.view FontAwesome.Solid.times ]
            )
        ]


viewFilterScrollbox : Model -> SearchModel -> String -> List String -> Html Msg
viewFilterScrollbox model searchModel filterKey values =
    Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        , HA.class "scrollbox"
        ]
        (List.map
            (\value ->
                Html.button
                    [ HA.class "row"
                    , HA.class "gap-tiny"
                    , HA.class "align-center"
                    , HE.onClick (FilterToggled filterKey value)
                    , case filterKey of
                        "alignments" ->
                            HA.class "trait trait-alignment"

                        "schools" ->
                            HA.class "trait"

                        "sizes" ->
                            HA.class "trait trait-size"

                        "rarities" ->
                            HA.class ("trait trait-" ++ value)

                        "traits" ->
                            HA.class "trait"

                        "types" ->
                            HA.class "filter-type"

                        _ ->
                            HAE.empty
                    , HAE.attributeIf (filterKey == "traits") (getTraitClass value)
                    ]
                    [ if filterKey == "pfs" || filterKey == "sfs" then
                        viewPfsIcon model.starfinder 16 value

                      else
                        Html.text ""

                    , case filterKey of
                        "actions" ->
                            Html.span
                                []
                                (viewTextWithActionIcons value)

                        "alignments" ->
                            Dict.fromList Data.allAlignments
                                |> Dict.get value
                                |> Maybe.withDefault value
                                |> toTitleCase
                                |> Html.text

                        _ ->
                            Html.text (toTitleCase value)

                    , viewFilterIcon (nestedDictGet filterKey value searchModel.filteredValues)
                    ]
            )
            (List.filter
                (caseInsensitiveContains (dictGetString filterKey searchModel.searchFilters))
                values
            )
        )


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
        [ Html.h3
            []
            [ Html.text "Active filters and options:" ]

        , if String.isEmpty currentQuery then
            Html.text ""

          else
            viewActiveFilters model searchModel True

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
                    [ HA.style "font-size" "1.5em"
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


viewActiveFilters : Model -> SearchModel -> Bool -> Html Msg
viewActiveFilters model searchModel canClick =
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
                                            , HA.class "align-center"
                                            , HAE.attributeMaybe HA.class class
                                            , getTraitClass value
                                            , HAE.attributeIf canClick (HE.onClick (removeMsg value))
                                            ]
                                            (List.append
                                                [ viewPfsIcon model.starfinder 16 value
                                                ]
                                                (viewTextWithActionIcons (toTitleCase value))
                                            )
                                    )
                                    list
                                )
                            )
                )
                (List.append
                    (List.concatMap
                        (\filter ->
                            let
                                class : Maybe String
                                class =
                                    case filter.key of
                                        "alignments" ->
                                            Just "trait trait-alignment"

                                        "rarities" ->
                                            Just "trait"

                                        "sizes" ->
                                            Just "trait trait-size"

                                        "schools" ->
                                            Just "trait"

                                        "traits" ->
                                            Just "trait"

                                        "types" ->
                                            Just "filter-type"

                                        _ ->
                                            Nothing

                                isAnd : Bool
                                isAnd =
                                    Dict.get filter.key searchModel.filterOperators
                                        |> Maybe.withDefault True

                                label : String
                                label =
                                    filter.field
                                        |> String.replace ".keyword" ""
                                        |> String.Extra.humanize
                                        |> toTitleCase
                            in
                            [ { class = class
                              , label =
                                    -- TODO: Dynamic based on no. of values
                                    if filter.useOperator then
                                        if isAnd then
                                            label ++ " is:"

                                        else
                                            label ++ " is any of:"

                                    else
                                        label ++ " is:"
                              , list = boolDictIncluded filter.key searchModel.filteredValues
                              , removeMsg = FilterRemoved filter.key
                              }
                            , { class = class
                              , label = label ++ " is not:"
                              , list = boolDictExcluded filter.key searchModel.filteredValues
                              , removeMsg = FilterRemoved filter.key
                              }
                            ]
                        )
                        filterFields
                    )
                    [ { class = Nothing
                      , label = "AP creatures:"
                      , list =
                            if searchModel.filterApCreatures then
                                [ "Hidden" ]

                            else
                                []
                      , removeMsg = \_ -> FilterApCreaturesChanged False
                      }
                    , { class = Nothing
                      , label = "Items with children:"
                      , list =
                            if searchModel.filterItemChildren then
                                []

                            else
                                [ "Show parent" ]
                      , removeMsg = \_ -> FilterItemChildrenChanged True
                      }
                    , { class = Nothing
                      , label = "Legacy / Remaster:"
                      , list =
                            case searchModel.legacyMode of
                                Just True ->
                                    [ "Legacy" ]

                                Just False ->
                                    [ "Remaster" ]

                                Nothing ->
                                    []
                      , removeMsg = \_ -> LegacyModeChanged Nothing
                      }
                    , { class = Nothing
                      , label = "Spoilers:"
                      , list =
                            if searchModel.filterSpoilers then
                                [ "Hidden" ]

                            else
                                []
                      , removeMsg = \_ -> FilterSpoilersChanged False
                      }
                    ]
                )
            )
            (mergeFromToValues searchModel
                |> List.map
                    (\( field, maybeFrom, maybeTo ) ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "align-baseline"
                            ]
                            (if maybeFrom == maybeTo then
                                [ Html.text (sortFieldToLabel field ++ ":")
                                , maybeFrom
                                    |> Maybe.map
                                        (\from ->
                                            Html.button
                                                [ HAE.attributeIf canClick (HE.onClick (FilteredBothValuesChanged field ""))
                                                ]
                                                [ Html.text ("exactly " ++ from ++ " " ++ sortFieldSuffix field) ]
                                        )
                                    |> Maybe.withDefault (Html.text "")
                                ]

                             else
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
                                                [ Html.text ("at most " ++ to ++ " " ++ sortFieldSuffix field) ]
                                        )
                                    |> Maybe.withDefault (Html.text "")
                                ]
                            )
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
                [ [ Html.text "Sorting by:" ]
                , List.map
                    (\( field, dir ) ->
                        Html.button
                            [ HA.class "row"
                            , HA.class "gap-tiny"
                            , HA.class "align-center"
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
                            , viewSortIcon field (Just dir)
                            ]
                    )
                    searchModel.sort
                ]
            )


viewSearchResults : Model -> SearchModel -> Html Msg
viewSearchResults model searchModel =
    let
        total : Maybe Int
        total =
            searchModel.searchResults
                |> List.head
                |> Maybe.andThen Result.toMaybe
                |> Maybe.map .total

        groupedResults : List String
        groupedResults =
            case searchModel.resultDisplay of
                Grouped ->
                    searchModel.searchGroupResults

                _ ->
                    []

        resultCount : Int
        resultCount =
            searchModel.searchResults
                |> List.filterMap Result.toMaybe
                |> List.concatMap .documentIds
                |> List.append groupedResults
                |> Set.fromList
                |> Set.size

        remaining : Int
        remaining =
            Maybe.withDefault 0 total - resultCount
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-medium"
        , HA.class "align-center"
        , HA.style "align-self" "stretch"
        , HA.style "padding-bottom" "8px"
        , HA.id "results"
        , HA.tabindex -1
        ]
        (List.append
            [ Html.div
                [ HA.class "limit-width"
                , HA.class "fill-width"
                , HA.class "fade-in"
                ]
                [ case total of
                    Just count ->
                        Html.text ("Showing " ++ String.fromInt resultCount ++ " of " ++ String.fromInt count ++ " results")

                    _ ->
                        Html.text ""
                ]
            ]
            (case searchModel.resultDisplay of
                Short ->
                    viewSearchResultsShort model searchModel remaining resultCount

                Full ->
                    viewSearchResultsFull model searchModel remaining

                Table ->
                    viewSearchResultsTableContainer model searchModel remaining

                Grouped ->
                    viewSearchResultsGrouped model searchModel remaining
            )
        )


viewLoadMoreButtons : Int -> Int -> Html Msg
viewLoadMoreButtons pageSize remaining =
    Html.div
        [ HA.class "row"
        , HA.class "gap-medium"
        , HA.style "justify-content" "center"
        ]
        [ if remaining > pageSize then
            Html.button
                [ HE.onClick (LoadMorePressed pageSize)
                ]
                [ Html.text ("Load " ++ String.fromInt pageSize ++ " more") ]

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


viewSearchResultsShort : Model -> SearchModel -> Int -> Int -> List (Html Msg)
viewSearchResultsShort model searchModel remaining resultCount =
    [ Html.Keyed.ol
        [ HA.class "fill-width"
        , HA.class "limit-width"
        , HA.class "results-list"
        , if model.viewModel.showResultIndex then
            HA.class "item-gap-small"

          else
            HA.class "item-gap-large"
        , HAE.attributeIf searchModel.loadingNew (HA.class "dim")
        ]
        (List.concatMap
            (\result ->
                case result of
                    Ok r ->
                        List.map
                            (\id ->
                                ( id
                                , Html.li
                                    []
                                    [ Dict.get id model.documents
                                        |> Maybe.andThen Result.toMaybe
                                        |> viewSingleShortResult model.viewModel
                                    ]
                                )
                            )
                            r.documentIds

                    Err err ->
                        [ ( "err"
                          , Html.h2
                                []
                                [ Html.text (httpErrorToString err) ]
                          )
                        ]
            )
            searchModel.searchResults
        )

    , if Maybe.Extra.isJust searchModel.tracker then
        Html.div
            [ HA.class "loader"
            ]
            []

      else
        viewLoadMoreButtons model.pageSize remaining

    , if resultCount > 0 then
        Html.button
            [ HE.onClick ScrollToTopPressed
            ]
            [ Html.text "Scroll to top" ]

      else
        Html.text ""
    ]


viewSingleShortResult : ViewModel -> Maybe Document -> Html Msg
viewSingleShortResult viewModel maybeDocument =
    case maybeDocument of
        Just document ->
            if documentShouldBeMasked viewModel document then
                Html.Lazy.lazy2
                    viewMaskedDocument
                    viewModel
                    document

            else
                Html.Lazy.lazy2
                    viewSingleShortResultLoaded
                    viewModel
                    document

        Nothing ->
            Html.article
                [ HA.class "column"
                , HA.class "gap-small"
                , HA.class "fade-in"
                , HA.style "margin-top" "2px"
                ]
                [ Html.h1
                    [ HA.class "title" ]
                    [ Html.text "Loading..." ]
                ]


viewSingleShortResultLoaded : ViewModel -> Document -> Html Msg
viewSingleShortResultLoaded viewModel document =
    let
        hasActionsInTitle : Bool
        hasActionsInTitle =
            List.member document.category [ "action", "creature-ability", "familiar-ability", "feat", "spell", "tactic" ]

        hasEpithetInTitle : Bool
        hasEpithetInTitle =
            List.member document.category [ "deity" ]

    in
    Html.article
        [ HA.class "column"
        , HA.class "gap-small"
        , HA.class "fade-in"
        , HA.style "margin-top" "2px"
        ]
        [ Html.h1
            [ HA.class "title" ]
            [ Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                , HA.class "nowrap"
                ]
                [ if viewModel.showResultPfs then
                    viewPfsIconWithLink viewModel.starfinder 25 (Maybe.withDefault "" document.pfs)

                  else
                    Html.text ""
                , Html.p
                    []
                    (List.append
                        [ Html.a
                            (List.append
                                [ HA.href (getUrl viewModel document)
                                , HAE.attributeIf viewModel.openInNewTab (HA.target "_blank")
                                ]
                                (linkEventAttributes document.url)
                            )
                            [ Html.text document.name
                            , case ( hasEpithetInTitle, document.epithet ) of
                                ( True, Just epithet ) ->
                                    Html.text <| " (" ++ epithet ++ ")"

                                _ ->
                                    Html.text ""
                            ]
                        ]
                        (case ( document.actions, hasActionsInTitle ) of
                            ( Just actions, True ) ->
                                case String.uncons actions of
                                    Just ( first, _ ) ->
                                        if Char.isDigit first then
                                            []

                                        else
                                            viewTextWithActionIcons actions

                                    _ ->
                                        []

                            _ ->
                                []
                        )
                    )
                ]
            , Html.div
                [ HA.class "title-type"
                ]
                [ case document.type_ of
                    "Item" ->
                        case document.itemSubcategory of
                            Just "Base Armor" ->
                                Html.text "Armor"

                            Just "Base Shields" ->
                                Html.text "Shield"

                            Just "Base Weapons" ->
                                Html.text "Weapon"

                            _ ->
                                Html.text document.type_

                    "Spell" ->
                        Html.text (Maybe.withDefault document.type_ document.spellType)

                    _ ->
                        Html.text document.type_
                , case ( document.level, document.itemHasChildren ) of
                    ( Just level, True ) ->
                        Html.text (" " ++ String.fromInt level ++ "+")

                    ( Just level, False ) ->
                        Html.text (" " ++ String.fromInt level)

                    ( Nothing, _ ) ->
                        Html.text ""
                ]
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "gap-small"
            ]
            (case document.searchMarkdown of
                Parsed parsed ->
                    viewMarkdown viewModel document.id parsed

                ParsedWithUnflattenedChildren parsed ->
                    viewMarkdown viewModel document.id parsed

                NotParsed _ ->
                    [ Html.div
                        [ HA.style "color" "red" ]
                        [ Html.text ("Not parsed: " ++ document.id) ]
                    ]
            )
        ]


viewMaskedDocument : ViewModel -> Document -> Html Msg
viewMaskedDocument viewModel document =
    Html.article
        [ HA.class "column"
        , HA.class "gap-small"
        , HA.class "fade-in"
        , HA.style "margin-top" "2px"
        ]
        [ Html.h1
            [ HA.class "title" ]
            [ Html.div
                [ HA.class "row"
                , HA.class "gap-small"
                , HA.class "align-center"
                , HA.class "nowrap"
                ]
                [ if viewModel.showResultPfs then
                    viewPfsIconWithLink viewModel.starfinder 25 (Maybe.withDefault "" document.pfs)

                  else
                    Html.text ""
                , Html.a
                    (List.append
                        [ HA.href (getUrl viewModel document)
                        , HAE.attributeIf viewModel.openInNewTab (HA.target "_blank")
                        ]
                        (linkEventAttributes document.url)
                    )
                    [ Html.text "<Spoiler>"
                    ]
                ]
            , Html.div
                [ HA.class "title-type"
                ]
                [ case document.type_ of
                    "Item" ->
                        case document.itemSubcategory of
                            Just "Base Armor" ->
                                Html.text "Armor"

                            Just "Base Shields" ->
                                Html.text "Shield"

                            Just "Base Weapons" ->
                                Html.text "Weapon"

                            _ ->
                                Html.text document.type_

                    "Spell" ->
                        Html.text (Maybe.withDefault document.type_ document.spellType)

                    _ ->
                        Html.text document.type_
                , case ( document.level, document.itemHasChildren ) of
                    ( Just level, True ) ->
                        Html.text (" " ++ String.fromInt level ++ "+")

                    ( Just level, False ) ->
                        Html.text (" " ++ String.fromInt level)

                    ( Nothing, _ ) ->
                        Html.text ""
                ]
            ]
        , Html.div
            [ HA.class "row"
            , HA.class "traits"
            ]
            [ case document.rarity of
                Just "common" ->
                    Html.text ""

                Just rarity ->
                    viewTrait Nothing (String.Extra.toTitleCase rarity)

                Nothing ->
                    Html.text ""
            ]
        , Html.div
            [ HA.class "inline"
            ]
            [ Html.span
                [ HA.class "bold" ]
                [ Html.text "Source" ]
            , Html.text " "
            , Html.span
                []
                (document.sources
                    |> Maybe.withDefault ""
                    |> parseAndViewAsMarkdown viewModel
                )
            ]
        ]


viewSearchResultsFull : Model -> SearchModel -> Int -> List (Html Msg)
viewSearchResultsFull model searchModel remaining =
    [ Html.Keyed.ol
        [ HA.class "fill-width"
        , HA.class "limit-width"
        , HA.class "results-list"
        , if model.viewModel.showResultIndex then
            HA.class "item-gap-small"

          else
            HA.class "item-gap-large"
        , HAE.attributeIf searchModel.loadingNew (HA.class "dim")
        ]
        (List.concatMap
            (\result ->
                case result of
                    Ok r ->
                        List.map
                            (\id ->
                                ( id
                                , Html.li
                                    []
                                    [ Html.article
                                        [ HA.class "column"
                                        , HA.class "gap-small"
                                        , HA.class "fade-in"
                                        , HA.style "margin-top" "2px"
                                        ]
                                        [ viewDocument model id
                                        ]
                                    ]
                                )
                            )
                            r.documentIds

                    Err err ->
                        [ ( "err"
                          , Html.h2
                                []
                                [ Html.text (httpErrorToString err) ]
                          )
                        ]
            )
            searchModel.searchResults
        )
    , if Maybe.Extra.isJust searchModel.tracker then
        Html.div
            [ HA.class "loader"
            ]
            []

      else
        viewLoadMoreButtons model.pageSize remaining
    ]


viewSearchResultsTableContainer : Model -> SearchModel -> Int -> List (Html Msg)
viewSearchResultsTableContainer model searchModel remaining =
    [ Html.div
        [ HA.class "fill-width"
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
            , HAE.attributeIf searchModel.loadingNew (HA.class "dim")
            ]
            [ viewSearchResultTable model searchModel

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


viewSearchResultTable : Model -> SearchModel -> Html Msg
viewSearchResultTable model searchModel =
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
                                    , viewSortIcon
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
        , Html.Keyed.node
            "tbody"
            []
            (searchModel.searchResults
                |> List.map (Result.map .documentIds)
                |> List.concatMap (Result.withDefault [])
                |> List.map
                    (\id ->
                        ( id
                        , case Dict.get id model.documents of
                            Just (Ok document) ->
                                Html.Lazy.lazy3
                                    viewSearchResultTableRow
                                    model.viewModel
                                    searchModel.tableColumns
                                    document

                            Just (Err _) ->
                                Html.text ""

                            Nothing ->
                                Html.tr
                                    []
                                    (List.append
                                        [ Html.td
                                            []
                                            [ Html.text "Loading..." ]
                                        ]
                                        (List.repeat
                                            (List.length searchModel.tableColumns)
                                            (Html.td [] [])
                                        )
                                    )
                        )
                    )
            )
        ]


viewSearchResultTableRow : ViewModel -> List String -> Document -> Html Msg
viewSearchResultTableRow viewModel tableColumns document =
    Html.Keyed.node "tr"
        []
        (List.map
            (\column ->
                ( document.id ++ column
                , if documentShouldBeMasked viewModel document then
                    if column == "name" then
                        Html.td
                            []
                            [ Html.a
                                (List.append
                                    [ HA.href (getUrl viewModel document)
                                    , HAE.attributeIf viewModel.openInNewTab (HA.target "_blank")
                                    ]
                                    (linkEventAttributes (getUrl viewModel document))
                                )
                                [ Html.text "<Spoiler>"
                                ]
                            ]

                    else if
                        List.member
                            column
                            [ "level"
                            , "pfs"
                            , "rank"
                            , "rarity"
                            , "source"
                            , "source_category"
                            , "source_group"
                            , "sfs"
                            , "type"
                            ]
                    then
                        Html.Lazy.lazy3
                            viewSearchResultTableCell
                            viewModel
                            document
                            column

                    else
                        Html.td [] []

                  else
                    Html.Lazy.lazy3
                        viewSearchResultTableCell
                        viewModel
                        document
                        column
                )
            )
            ("name" :: tableColumns)
        )


viewSearchResultTableCell : ViewModel -> Document -> String -> Html Msg
viewSearchResultTableCell viewModel document column =
    let
        maybeAsMarkdown : Maybe String -> List (Html Msg)
        maybeAsMarkdown maybeString =
            maybeString
                |> Maybe.withDefault ""
                |> parseAndViewAsMarkdown viewModel

        cellString : String
        cellString =
            searchResultTableCellToString viewModel document column
    in
    Html.td
        [ HAE.attributeIf (column == "name") (HA.class "sticky-left")
        , if String.length cellString > 100 && column /= "name" then
            HA.style "min-width" "300px"

          else if String.length cellString > 75 && column /= "name" then
            HA.style "min-width" "250px"

          else if String.length cellString > 50 && column /= "name" then
            HA.style "min-width" "200px"

          else if String.length cellString > 20 && column /= "name" then
            HA.style "min-width" "150px"

          else
            HAE.empty
        ]
        (case String.split "." column of
            [ "actions" ] ->
                document.actions
                    |> Maybe.withDefault ""
                    |> viewTextWithActionIcons

            [ "advanced_apocryphal_spell" ] ->
                maybeAsMarkdown document.advancedApocryphalSpell

            [ "advanced_domain_spell" ] ->
                maybeAsMarkdown document.advancedDomainSpell

            [ "anathema" ] ->
                maybeAsMarkdown document.anathemas

            [ "apocryphal_spell" ] ->
                maybeAsMarkdown document.apocryphalSpell

            [ "armor_group" ] ->
                maybeAsMarkdown document.armorGroup

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

            [ "creature_family" ] ->
                maybeAsMarkdown document.creatureFamilyMarkdown

            [ "cost" ] ->
                maybeAsMarkdown document.cost

            [ "deity" ] ->
                maybeAsMarkdown document.deities

            [ "defense" ] ->
                maybeAsMarkdown document.savingThrow

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

            [ "domain" ] ->
                maybeAsMarkdown document.domains

            [ "domain_alternate" ] ->
                maybeAsMarkdown document.domainsAlternate

            [ "domain_primary" ] ->
                maybeAsMarkdown document.domainsPrimary

            [ "domain_spell" ] ->
                maybeAsMarkdown document.domainSpell

            [ "edict" ] ->
                maybeAsMarkdown document.edicts

            [ "favored_weapon" ] ->
                maybeAsMarkdown document.favoredWeapons

            [ "feat" ] ->
                maybeAsMarkdown document.feats

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

            [ "item_bonus_note" ] ->
                maybeAsMarkdown document.itemBonusNote

            [ "language" ] ->
                maybeAsMarkdown document.languages

            [ "lesson" ] ->
                maybeAsMarkdown document.lessons

            [ "magazine" ] ->
                maybeAsMarkdown document.ammunition

            [ "mystery" ] ->
                maybeAsMarkdown document.mysteries

            [ "name" ] ->
                [ Html.a
                    (List.append
                        [ HA.href (getUrl viewModel document)
                        , HAE.attributeIf viewModel.openInNewTab (HA.target "_blank")
                        ]
                        (linkEventAttributes (getUrl viewModel document))
                    )
                    [ Html.text document.name
                    ]
                ]

            [ "pantheon" ] ->
                maybeAsMarkdown document.pantheonMarkdown

            [ "pantheon_member" ] ->
                maybeAsMarkdown document.pantheonMembers

            [ "patron_theme" ] ->
                maybeAsMarkdown document.patronThemes

            [ "pfs" ] ->
                document.pfs
                    |> Maybe.withDefault ""
                    |> viewPfsIconWithLink viewModel.starfinder 20
                    |> List.singleton
                    |> Html.div
                        [ HA.class "column"
                        , HA.class "align-center"
                        ]
                    |> List.singleton

            [ "piloting_check" ] ->
                maybeAsMarkdown document.pilotingCheck

            [ "prerequisite" ] ->
                maybeAsMarkdown document.prerequisites

            [ "primary_check" ] ->
                maybeAsMarkdown document.primaryCheck

            [ "requirement" ] ->
                maybeAsMarkdown document.requirements

            [ "resistance" ] ->
                maybeAsMarkdown document.resistances

            [ "saving_throw" ] ->
                maybeAsMarkdown document.savingThrow

            [ "secondary_check" ] ->
                maybeAsMarkdown document.secondaryChecks

            [ "sense" ] ->
                maybeAsMarkdown document.senses

            [ "sfs" ] ->
                document.pfs
                    |> Maybe.withDefault ""
                    |> viewPfsIconWithLink viewModel.starfinder 20
                    |> List.singleton
                    |> Html.div
                        [ HA.class "column"
                        , HA.class "align-center"
                        ]
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

            [ "speed" ] ->
                maybeAsMarkdown document.speed

            [ "spell" ] ->
                maybeAsMarkdown document.spell

            [ "stage" ] ->
                maybeAsMarkdown document.stages

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

            [ "url" ] ->
                [ Html.a
                    (List.append
                        [ HA.href (getUrl viewModel document)
                        , HAE.attributeIf viewModel.openInNewTab (HA.target "_blank")
                        ]
                        (linkEventAttributes (getUrl viewModel document))
                    )
                    [ Html.text document.url
                    ]
                ]

            [ "usage" ] ->
                maybeAsMarkdown document.usage

            [ "weapon_group" ] ->
                maybeAsMarkdown document.weaponGroupMarkdown

            [ "weakness" ] ->
                maybeAsMarkdown document.weaknesses

            _ ->
                [ Html.text cellString ]
        )


searchResultTableCellToString : ViewModel -> Document -> String -> String
searchResultTableCellToString viewModel document column =
    case String.split "." column of
        [ "ability" ] ->
            document.attributes
                |> String.join ", "

        [ "ability_boost" ] ->
            document.attributes
                |> String.join ", "

        [ "ability_flaw" ] ->
            document.attributeFlaws
                |> String.join ", "

        [ "ability_type" ] ->
            maybeAsString document.abilityType

        [ "ac" ] ->
            document.ac
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "ac_scale" ] ->
            document.acScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "actions" ] ->
            maybeAsString document.actions

        [ "advanced_apocryphal_spell" ] ->
            maybeAsStringWithoutMarkdown document.advancedApocryphalSpell

        [ "advanced_domain_spell" ] ->
            maybeAsStringWithoutMarkdown document.advancedDomainSpell

        [ "alignment" ] ->
            maybeAsString document.alignment

        [ "anathema" ] ->
            maybeAsStringWithoutMarkdown document.anathemas

        [ "apocryphal_spell" ] ->
            maybeAsStringWithoutMarkdown document.apocryphalSpell

        [ "archetype" ] ->
            document.archetypes
                |> String.join ", "

        [ "area" ] ->
            maybeAsString document.area

        [ "area_type" ] ->
            document.areaTypes
                |> List.map toTitleCase
                |> String.join ", "

        [ "area_of_concern" ] ->
            maybeAsString document.areasOfConcern

        [ "armor_category" ] ->
            maybeAsString document.armorCategory

        [ "armor_group" ] ->
            maybeAsStringWithoutMarkdown document.armorGroup

        [ "aspect" ] ->
            document.aspect
                |> maybeAsString
                |> toTitleCase

        [ "attack_bonus" ] ->
            document.attackBonus
                |> List.map numberWithSign
                |> String.join ", "

        [ "attack_bonus_scale" ] ->
            document.attackBonusScale
                |> List.map scaleToString
                |> String.join ", "

        [ "attack_proficiency" ] ->
            document.attackProficiencies
                |> String.join "\n"

        [ "attribute" ] ->
            document.attributes
                |> String.join ", "

        [ "attribute_boost" ] ->
            document.attributes
                |> String.join ", "

        [ "attribute_flaw" ] ->
            document.attributeFlaws
                |> String.join ", "

        [ "base_item" ] ->
            maybeAsStringWithoutMarkdown document.baseItems

        [ "bloodline" ] ->
            maybeAsStringWithoutMarkdown document.bloodlines

        [ "bulk" ] ->
            maybeAsString document.bulkRaw

        [ "charisma" ] ->
            document.charisma
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "charisma_scale" ] ->
            document.charismaScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "check_penalty" ] ->
            document.checkPenalty
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "creature_ability" ] ->
            document.creatureAbilities
                |> List.sort
                |> String.join ", "

        [ "creature_family" ] ->
            maybeAsStringWithoutMarkdown document.creatureFamilyMarkdown

        [ "crew" ] ->
            maybeAsString document.crew

        [ "complexity" ] ->
            maybeAsString document.complexity

        [ "component" ] ->
            document.components
                |> List.map toTitleCase
                |> String.join ", "

        [ "constitution" ] ->
            document.constitution
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "constitution_scale" ] ->
            document.constitutionScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "cost" ] ->
            maybeAsStringWithoutMarkdown document.cost

        [ "deity" ] ->
            maybeAsStringWithoutMarkdown document.deities

        [ "deity_category" ] ->
            maybeAsString document.deityCategory

        [ "damage" ] ->
            maybeAsString document.damage

        [ "damage_type" ] ->
            document.damageTypes
                |> List.map toTitleCase
                |> List.sort
                |> String.join ", "

        [ "defense" ] ->
            maybeAsStringWithoutMarkdown document.savingThrow

        [ "defense_proficiency" ] ->
            document.defenseProficiencies
                |> String.join "\n"

        [ "dexterity" ] ->
            document.dexterity
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "dex_cap" ] ->
            document.dexCap
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "dexterity_scale" ] ->
            document.dexterityScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "divine_font" ] ->
            document.divineFonts
                |> List.map toTitleCase
                |> String.join " or "

        [ "domain" ] ->
            maybeAsStringWithoutMarkdown document.domains

        [ "domain_alternate" ] ->
            maybeAsStringWithoutMarkdown document.domainsAlternate

        [ "domain_primary" ] ->
            maybeAsStringWithoutMarkdown document.domainsPrimary

        [ "domain_spell" ] ->
            maybeAsStringWithoutMarkdown document.domainSpell

        [ "duration" ] ->
            maybeAsString document.duration

        [ "edict" ] ->
            maybeAsStringWithoutMarkdown document.edicts

        [ "element" ] ->
            document.elements
                |> List.map toTitleCase
                |> String.join ", "

        [ "epithet" ] ->
            maybeAsString document.epithet

        [ "expend" ] ->
            document.expend
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "favored_weapon" ] ->
            maybeAsStringWithoutMarkdown document.favoredWeapons

        [ "feat" ] ->
            maybeAsStringWithoutMarkdown document.feats

        [ "follower_alignment" ] ->
            document.followerAlignments
                |> String.join ", "

        [ "fortitude" ] ->
            document.fort
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "fortitude_proficiency" ] ->
            maybeAsString document.fortitudeProficiency

        [ "fortitude_scale" ] ->
            document.fortitudeScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "frequency" ] ->
            maybeAsString document.frequency

        [ "hands" ] ->
            maybeAsString document.hands

        [ "hardness" ] ->
            maybeAsString document.hardness

        [ "hazard_type" ] ->
            maybeAsString document.hazardType

        [ "heighten" ] ->
            document.heighten
                |> String.join ", "

        [ "heighten_level" ] ->
            document.heightenLevels
                |> List.map String.fromInt
                |> String.join ", "

        [ "hp" ] ->
            maybeAsString document.hp

        [ "hp_scale" ] ->
            document.hpScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "icon_image" ] ->
            ""

        [ "image" ] ->
            ""

        [ "immunity" ] ->
            maybeAsStringWithoutMarkdown document.immunities

        [ "intelligence" ] ->
            document.intelligence
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "intelligence_scale" ] ->
            document.intelligenceScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "item_bonus_action" ] ->
            maybeAsString document.itemBonusAction

        [ "item_bonus_consumable" ] ->
            case document.itemBonusConsumable of
                Just True ->
                    "True"

                Just False ->
                    "False"

                Nothing ->
                    ""

        [ "item_bonus_note" ] ->
            maybeAsStringWithoutMarkdown document.itemBonusNote

        [ "item_bonus_value" ] ->
            if document.itemBonusValue == Just -1 then
                "Varies"

            else
                document.itemBonusValue
                    |> Maybe.map numberWithSign
                    |> Maybe.withDefault ""

        [ "item_category" ] ->
            maybeAsString document.itemCategory

        [ "item_subcategory" ] ->
            maybeAsString document.itemSubcategory

        [ "language" ] ->
            maybeAsStringWithoutMarkdown document.languages

        [ "lesson" ] ->
            maybeAsStringWithoutMarkdown document.lessons

        [ "level" ] ->
            document.level
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "location" ] ->
            maybeAsString document.location

        [ "magazine" ] ->
            maybeAsStringWithoutMarkdown document.ammunition

        [ "mount" ] ->
            case document.mount of
                Just True ->
                    "True"

                Just False ->
                    "False"

                Nothing ->
                    ""

        [ "mystery" ] ->
            maybeAsStringWithoutMarkdown document.mysteries

        [ "name" ] ->
            document.name

        [ "onset" ] ->
            maybeAsString document.onset

        [ "pantheon" ] ->
            maybeAsStringWithoutMarkdown document.pantheonMarkdown

        [ "pantheon_member" ] ->
            maybeAsStringWithoutMarkdown document.pantheonMembers

        [ "passengers" ] ->
            maybeAsString document.passengers

        [ "patron_theme" ] ->
            maybeAsStringWithoutMarkdown document.patronThemes

        [ "perception" ] ->
            document.perception
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "perception_proficiency" ] ->
            maybeAsString document.perceptionProficiency

        [ "perception_scale" ] ->
            document.perceptionScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "pfs" ] ->
            document.pfs
                |> Maybe.withDefault ""

        [ "piloting_check" ] ->
            maybeAsStringWithoutMarkdown document.pilotingCheck

        [ "plane_category" ] ->
            maybeAsString document.planeCategory

        [ "prerequisite" ] ->
            maybeAsStringWithoutMarkdown document.prerequisites

        [ "price" ] ->
            maybeAsString document.price

        [ "primary_check" ] ->
            maybeAsStringWithoutMarkdown document.primaryCheck

        [ "range" ] ->
            maybeAsString document.range

        [ "rank" ] ->
            document.level
                |> Maybe.map toOrdinal
                |> maybeAsString

        [ "rarity" ] ->
            document.rarity
                |> Maybe.map toTitleCase
                |> maybeAsString

        [ "reflex" ] ->
            document.ref
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "reflex_proficiency" ] ->
            maybeAsString document.reflexProficiency

        [ "reflex_scale" ] ->
            document.reflexScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "region" ] ->
            maybeAsString document.region

        [ "release_date" ] ->
            document.releaseDate
                |> Maybe.map (formatDate viewModel)
                |> maybeAsString

        [ "religious_symbol" ] ->
            maybeAsString document.religiousSymbol

        [ "reload" ] ->
            maybeAsString document.reload

        [ "requirement" ] ->
            maybeAsStringWithoutMarkdown document.requirements

        [ "resistance" ] ->
            maybeAsStringWithoutMarkdown document.resistances

        [ "resistance", type_ ] ->
            document.resistanceValues
                |> Maybe.andThen (getDamageTypeValue type_)
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "sacred_animal" ] ->
            maybeAsStringWithoutMarkdown document.sacredAnimal

        [ "sacred_color" ] ->
            document.sacredColors
                |> String.join ", "
                |> toTitleCase

        [ "sanctification" ] ->
            maybeAsString document.sanctification

        [ "saving_throw" ] ->
            maybeAsStringWithoutMarkdown document.savingThrow

        [ "school" ] ->
            document.school
                |> Maybe.map toTitleCase
                |> maybeAsString

        [ "secondary_casters" ] ->
            maybeAsString document.secondaryCasters

        [ "secondary_check" ] ->
            maybeAsStringWithoutMarkdown document.secondaryChecks

        [ "sense" ] ->
            maybeAsStringWithoutMarkdown document.senses

        [ "sfs" ] ->
            document.pfs
                |> Maybe.withDefault ""

        [ "size" ] ->
            document.sizes
                |> String.join ", "

        [ "skill" ] ->
            maybeAsStringWithoutMarkdown document.skills

        [ "skill_proficiency" ] ->
            document.skillProficiencies
                |> String.join "\n"

        [ "source" ] ->
            maybeAsStringWithoutMarkdown document.sources

        [ "source_category" ] ->
            document.sourceCategories
                |> String.join ", "

        [ "source_group" ] ->
            document.sourceGroups
                |> String.join ", "

        [ "space" ] ->
            maybeAsString document.space

        [ "speed" ] ->
            maybeAsStringWithoutMarkdown document.speed

        [ "speed", type_ ] ->
            document.speedValues
                |> Maybe.andThen (getSpeedTypeValue type_)
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "speed_penalty" ] ->
            maybeAsString document.speedPenalty

        [ "spell" ] ->
            maybeAsStringWithoutMarkdown document.spell

        [ "spell_attack_bonus" ] ->
            document.spellAttackBonus
                |> List.map String.fromInt
                |> String.join ", "

        [ "spell_attack_bonus_scale" ] ->
            document.spellAttackBonusScale
                |> List.map scaleToString
                |> String.join ", "

        [ "spell_dc" ] ->
            document.spellDc
                |> List.map String.fromInt
                |> String.join ", "

        [ "spell_dc_scale" ] ->
            document.spellDcScale
                |> List.map scaleToString
                |> String.join ", "

        [ "spell_type" ] ->
            maybeAsString document.spellType

        [ "spoilers" ] ->
            maybeAsString document.spoilers

        [ "stage" ] ->
            maybeAsStringWithoutMarkdown document.stages

        [ "strength" ] ->
            document.strength
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "strength_req" ] ->
            document.strength
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "strength_scale" ] ->
            document.strengthScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "strike_damage_average" ] ->
            document.strikeDamageAverage
                |> List.map String.fromInt
                |> String.join ", "

        [ "strike_damage_scale" ] ->
            document.strikeDamageScale
                |> List.map scaleToString
                |> String.join ", "

        [ "strongest_save" ] ->
            document.strongestSaves
                |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                |> List.map toTitleCase
                |> String.join ", "

        [ "summary" ] ->
            maybeAsStringWithoutMarkdown document.summary

        [ "target" ] ->
            maybeAsStringWithoutMarkdown document.targets

        [ "tradition" ] ->
            maybeAsStringWithoutMarkdown document.traditions

        [ "trait" ] ->
            maybeAsStringWithoutMarkdown document.traits

        [ "trigger" ] ->
            maybeAsStringWithoutMarkdown document.trigger

        [ "type" ] ->
            document.type_

        [ "url" ] ->
            document.url

        [ "usage" ] ->
            maybeAsStringWithoutMarkdown document.usage

        [ "upgrades" ] ->
            document.upgrades
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "vehicle_type" ] ->
            maybeAsString document.vehicleType

        [ "vision" ] ->
            maybeAsString document.vision

        [ "warden_spell_tier" ] ->
            maybeAsString document.wardenSpellTier

        [ "weapon_category" ] ->
            maybeAsString document.weaponCategory

        [ "weapon_group" ] ->
            maybeAsStringWithoutMarkdown document.weaponGroupMarkdown

        [ "weapon_type" ] ->
            maybeAsString document.weaponType

        [ "weakest_save" ] ->
            document.weakestSaves
                |> List.filter (\s -> not (List.member s [ "fort", "ref" ]))
                |> List.map toTitleCase
                |> String.join ", "

        [ "weakness" ] ->
            maybeAsStringWithoutMarkdown document.weaknesses

        [ "weakness", type_ ] ->
            document.weaknessValues
                |> Maybe.andThen (getDamageTypeValue type_)
                |> Maybe.map String.fromInt
                |> maybeAsString

        [ "will" ] ->
            document.will
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "will_proficiency" ] ->
            maybeAsString document.willProficiency

        [ "will_scale" ] ->
            document.willScale
                |> Maybe.map scaleToString
                |> maybeAsString

        [ "wisdom" ] ->
            document.wisdom
                |> Maybe.map numberWithSign
                |> maybeAsString

        [ "wisdom_scale" ] ->
            document.wisdomScale
                |> Maybe.map scaleToString
                |> maybeAsString

        _ ->
            ""


maybeAsString : Maybe String -> String
maybeAsString maybeString =
    maybeString
        |> Maybe.withDefault ""


maybeAsStringWithoutMarkdown : Maybe String -> String
maybeAsStringWithoutMarkdown maybeString =
    let
        markdownLinkRegex : Regex.Regex
        markdownLinkRegex =
            Regex.fromString "\\[(.+?)\\]\\(.+?\\)"
                |> Maybe.withDefault Regex.never
    in
    maybeString
        |> Maybe.withDefault ""
        |> Regex.replace
            markdownLinkRegex
            (\match ->
                match.submatches
                    |> List.head
                    |> Maybe.Extra.join
                    |> Maybe.withDefault match.match
            )


viewSearchResultsGrouped : Model -> SearchModel -> Int -> List (Html Msg)
viewSearchResultsGrouped model searchModel remaining =
    let
        allDocuments : List Document
        allDocuments =
            searchModel.searchResults
                |> List.concatMap (Result.map .documentIds >> Result.withDefault [])
                |> List.append searchModel.searchGroupResults
                |> Set.fromList
                |> Set.toList
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
        viewLoadMoreButtons 100000 remaining

    , Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        , HA.class "limit-width"
        , HA.class "fill-width"
        , HAE.attributeIf searchModel.loadingNew (HA.class "dim")
        ]
        (List.map
            (\( key1, documents1 ) ->
                let
                    loaded : Int
                    loaded =
                        List.length documents1

                    total : Int
                    total =
                        Dict.get key1 counts
                            |> Maybe.withDefault 0

                    loadButton : Html Msg
                    loadButton =
                        if loaded < total then
                            viewLoadGroupButton
                                model
                                searchModel
                                [ ( searchModel.groupField1, key1 ) ]

                          else
                            Html.text ""
                in
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length documents1 == 0) (groupedDisplayAttribute model)
                    ]
                    [ Html.h1
                        [ HA.class "title" ]
                        [ Html.div
                            []
                            [ viewGroupedTitle model.starfinder searchModel.groupField1 key1
                            ]
                        , Html.div
                            [ HA.class "row"
                            , HA.class "gap-small"
                            , HA.class "align-center"
                            , HA.class "nowrap"
                            ]
                            [ loadButton
                            , Html.div
                                []
                                [ Html.text (String.fromInt loaded)
                                , Html.text "/"
                                , Html.text (String.fromInt total)
                                ]
                            ]
                        ]

                    , case searchModel.groupField2 of
                        Just field2 ->
                            viewSearchResultsGroupedLevel2 model searchModel key1 field2 documents1

                        Nothing ->
                            viewSearchResultsGroupedLinkList model searchModel documents1 (total - loaded) loadButton
                    ]
            )
            (if searchModel.searchResultGroupAggs == Nothing then
                []

             else
                groupDocumentsByField keys searchModel.groupField1 allDocuments
                    |> Dict.toList
                    |> sortGroupedList model searchModel.groupField1 "" counts
            )
        )

    , if Maybe.Extra.isJust searchModel.tracker || searchModel.searchResultGroupAggs == Nothing then
        Html.div
            [ HA.class "loader"
            ]
            []

      else
        viewLoadMoreButtons 100000 remaining
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
                        ( String.join
                            "--"
                            [ Maybe.withDefault "" agg.key1
                            , Maybe.withDefault "" agg.key2
                            ]
                        , agg.count
                        )
                    )
                |> Dict.fromList

        groupedDocuments : List ( String, List Document )
        groupedDocuments =
            groupDocumentsByField keys field2 documents1
                |> Dict.toList
                |> sortGroupedList model field2 (key1 ++ "--") counts
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        ]
        (List.map
            (\( key2, documents2 ) ->
                let
                    loaded : Int
                    loaded =
                        List.length documents2

                    total : Int
                    total =
                        Dict.get (key1 ++ "--" ++ key2) counts
                            |> Maybe.withDefault 0

                    loadButton : Html Msg
                    loadButton =
                        if loaded < total then
                            viewLoadGroupButton
                                model
                                searchModel
                                [ ( searchModel.groupField1, key1 )
                                , ( field2, key2 )
                                ]

                        else
                            Html.text ""
                in
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length documents2 == 0) (groupedDisplayAttribute model)
                    ]
                    [ if List.length groupedDocuments == 1 && key2 == "" then
                        Html.text ""

                      else
                        Html.h2
                            [ HA.class "title" ]
                            [ Html.div
                                []
                                [ viewGroupedTitle model.starfinder field2 key2
                                ]
                            , Html.div
                                [ HA.class "row"
                                , HA.class "gap-small"
                                , HA.class "align-center"
                                , HA.class "nowrap"
                                ]
                                [ loadButton
                                , Html.div
                                    []
                                    [ Html.text (String.fromInt loaded)
                                    , Html.text "/"
                                    , Html.text (String.fromInt total)
                                    ]
                                ]
                            ]
                    , case searchModel.groupField3 of
                        Just field3 ->
                            viewSearchResultsGroupedLevel3 model searchModel key1 key2 field3 documents2

                        Nothing ->
                            viewSearchResultsGroupedLinkList model searchModel documents2 (total - loaded) loadButton
                    ]
            )
            groupedDocuments
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
                        ( String.join
                            "--"
                            [ Maybe.withDefault "" agg.key1
                            , Maybe.withDefault "" agg.key2
                            , Maybe.withDefault "" agg.key3
                            ]
                        , agg.count
                        )
                    )
                |> Dict.fromList

        groupedDocuments : List ( String, List Document )
        groupedDocuments =
            groupDocumentsByField keys field3 documents2
                |> Dict.toList
                |> sortGroupedList model field3 (key1 ++ "--" ++ key2 ++ "--") counts
    in
    Html.div
        [ HA.class "column"
        , HA.class "gap-large"
        ]
        (List.map
            (\( key3, documents3 ) ->
                let
                    loaded : Int
                    loaded =
                        List.length documents3

                    total : Int
                    total =
                        Dict.get (key1 ++ "--" ++ key2 ++ "--" ++ key3) counts
                            |> Maybe.withDefault 0

                    loadButton : Html Msg
                    loadButton =
                        if loaded < total then
                            viewLoadGroupButton
                                model
                                searchModel
                                [ ( searchModel.groupField1, key1 )
                                , ( Maybe.withDefault "" searchModel.groupField2, key2 )
                                , ( field3, key3 )
                                ]

                        else
                            Html.text ""
                in
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-small"
                    , HAE.attributeIf (List.length documents3 == 0) (groupedDisplayAttribute model)
                    ]
                    [ if List.length groupedDocuments == 1 && key3 == "" then
                        Html.text ""

                      else
                        Html.h3
                            [ HA.class "title"
                            ]
                            [ Html.div
                                []
                                [ viewGroupedTitle model.starfinder field3 key3
                                ]
                            , Html.div
                                [ HA.class "row"
                                , HA.class "gap-small"
                                , HA.class "align-center"
                                , HA.class "nowrap"
                                ]
                                [ loadButton
                                , Html.div
                                    []
                                    [ Html.text (String.fromInt loaded)
                                    , Html.text "/"
                                    , Html.text (String.fromInt total)
                                    ]
                                ]
                            ]
                    , viewSearchResultsGroupedLinkList model searchModel documents3 (total - loaded) loadButton
                    ]
            )
            groupedDocuments
        )


viewLoadGroupButton : Model -> SearchModel -> List ( String, String ) -> Html Msg
viewLoadGroupButton model searchModel groups =
    if Maybe.Extra.isJust searchModel.tracker then
        Html.div
            [ HA.class "loader-small"
            ]
            []

    else
        Html.button
            [ HE.onClick (LoadGroupPressed groups)
            , HA.style "font-size" "1rem"
            ]
            [ Html.text "Load" ]


viewSearchResultsGroupedLinkList : Model -> SearchModel -> List Document -> Int -> Html Msg -> Html Msg
viewSearchResultsGroupedLinkList model searchModel documents remaining loadButton =
    Html.div
        [ case searchModel.groupedLinkLayout of
            Horizontal ->
                HA.class "row align-center"

            _ ->
                HA.class "column"
        , HA.class "gap-small"
        ]
        (List.append
            (List.map
                (Html.Lazy.lazy2
                    (case searchModel.groupedLinkLayout of
                        Horizontal ->
                            viewSearchResultGroupedHorizontal

                        Vertical ->
                            viewSearchResultGroupedVertical

                        VerticalWithSummary ->
                            viewSearchResultGroupedVerticalWithSummary
                    )
                    model.viewModel
                )
                (List.sortBy .name documents)
            )
            [ if remaining > 0 then
                Html.div
                    [ HA.class "row"
                    , HA.class "gap-small"
                    , HA.class "align-center"
                    ]
                    [ Html.div
                        [ HA.style "color" "var(--color-text-inactive)"
                        ]
                        [ Html.text (String.Extra.pluralize "result" "results" remaining ++ " not loaded")
                        ]
                    , loadButton
                    ]

              else
                Html.text ""
            ]
        )


viewSearchResultGroupedHorizontal : ViewModel -> Document -> Html Msg
viewSearchResultGroupedHorizontal viewModel document =
    Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ if viewModel.groupedShowPfs then
            document.pfs
                |> Maybe.withDefault ""
                |> viewPfsIcon viewModel.starfinder 0

          else
              Html.text ""
        , viewGroupedLink viewModel document
        , viewGroupedHeightenableBadge viewModel document
        , viewGroupedRarityBadge viewModel document
        ]


viewSearchResultGroupedVertical : ViewModel -> Document -> Html Msg
viewSearchResultGroupedVertical viewModel document =
    Html.div
        [ HA.class "row"
        , HA.class "gap-tiny"
        ]
        [ if viewModel.groupedShowPfs then
            document.pfs
                |> Maybe.withDefault ""
                |> viewPfsIcon viewModel.starfinder 0
          else
            Html.text ""
        , viewGroupedLink viewModel document
        , viewGroupedHeightenableBadge viewModel document
        , viewGroupedRarityBadge viewModel document
        ]


viewSearchResultGroupedVerticalWithSummary : ViewModel -> Document -> Html Msg
viewSearchResultGroupedVerticalWithSummary viewModel document =
    Html.div
        [ HA.class "inline" ]
        (List.concat
            [ if viewModel.groupedShowPfs then
                [ document.pfs
                    |> Maybe.withDefault ""
                    |> viewPfsIcon viewModel.starfinder 0
                , Html.text " "
                ]

              else
                  []
            , [ viewGroupedLink viewModel document
              , Html.text " "
              , viewGroupedHeightenableBadge viewModel document
              , Html.text " "
              , viewGroupedRarityBadge viewModel document
              ]
            , case document.summary of
                Just summary ->
                    if documentShouldBeMasked viewModel document then
                        []

                    else
                        List.append
                            [ Html.text " - " ]
                            (parseAndViewAsMarkdown viewModel summary)

                Nothing ->
                    []
            ]
        )


viewGroupedLink : ViewModel -> Document -> Html Msg
viewGroupedLink viewModel document =
    Html.a
        (List.append
            [ HA.href (getUrl viewModel document)
            ]
            (linkEventAttributes (getUrl viewModel document))
        )
        [ if documentShouldBeMasked viewModel document then
            Html.text "<Spoiler>"

          else
            Html.text document.name
        ]


viewGroupedHeightenableBadge : ViewModel -> Document -> Html msg
viewGroupedHeightenableBadge viewModel document =
    if viewModel.groupedShowHeightenable && List.length document.heightenLevels >= 2 then
        Html.div
            [ HA.style "vertical-align" "super"
            , HA.style "font-size" "0.625em"
            , HA.title "Heightenable"
            ]
            [ Html.text "H" ]

    else
        Html.text ""


viewGroupedRarityBadge : ViewModel -> Document -> Html msg
viewGroupedRarityBadge viewModel document =
    if viewModel.groupedShowRarity then
        case Maybe.map String.toLower document.rarity of
            Just "uncommon" ->
                Html.div
                    [ HA.class "trait"
                    , HA.class "trait-uncommon"
                    , HA.class "traitbadge"
                    , HA.title "Uncommon"
                    ]
                    [ Html.text "U" ]

            Just "rare" ->
                Html.div
                    [ HA.class "trait"
                    , HA.class "trait-rare"
                    , HA.class "traitbadge"
                    , HA.title "Rare"
                    ]
                    [ Html.text "R" ]

            Just "unique" ->
                Html.div
                    [ HA.class "trait"
                    , HA.class "trait-unique"
                    , HA.class "traitbadge"
                    , HA.title "Unique"
                    ]
                    [ Html.text "Q" ]

            _ ->
                Html.text ""

    else
        Html.text ""


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
                    if List.isEmpty document.attributes then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\attribute ->
                                insertToListDict (String.toLower attribute) document
                            )
                            dict
                            (List.Extra.unique document.attributes)

                "ac" ->
                    insertToListDict
                        (document.ac
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "ac_scale" ->
                    insertToListDict
                        (document.acScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "actions" ->
                    insertToListDict
                        (document.actions
                            |> Maybe.withDefault ""
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

                "area_type" ->
                    if List.isEmpty document.areaTypes then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\areaType ->
                                insertToListDict areaType document
                            )
                            dict
                            document.areaTypes

                "armor_category" ->
                    insertToListDict
                        (document.armorCategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "armor_group" ->
                    insertToListDict
                        (document.armorGroup
                            |> maybeAsStringWithoutMarkdown
                            |> String.toLower
                        )
                        document
                        dict

                "attack_bonus_scale" ->
                    if List.isEmpty document.attackBonusScale then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\scale ->
                                insertToListDict (String.fromInt scale) document
                            )
                            dict
                            document.attackBonusScale

                "attribute" ->
                    if List.isEmpty document.attributes then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\attribute ->
                                insertToListDict (String.toLower attribute) document
                            )
                            dict
                            (List.Extra.unique document.attributes)

                "bulk" ->
                    insertToListDict
                        (document.bulk
                            |> Maybe.map String.fromFloat
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "charisma_scale" ->
                    insertToListDict
                        (document.charismaScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "constitution_scale" ->
                    insertToListDict
                        (document.constitutionScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
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

                "damage_type" ->
                    if List.isEmpty document.damageTypes then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\damageType ->
                                insertToListDict (String.toLower damageType) document
                            )
                            dict
                            document.damageTypes

                "deity" ->
                    if List.isEmpty document.deitiesList then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\deity ->
                                insertToListDict (String.toLower deity) document
                            )
                            dict
                            document.deitiesList

                "deity_category" ->
                    insertToListDict
                        (document.deityCategory
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "dexterity_scale" ->
                    insertToListDict
                        (document.dexterityScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "domain" ->
                    if List.isEmpty document.domainsList then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\domain ->
                                insertToListDict (String.toLower domain) document
                            )
                            dict
                            document.domainsList

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

                "fortitude_scale" ->
                    insertToListDict
                        (document.fortitudeScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

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

                "heighten_group" ->
                    if List.isEmpty document.heightenGroups then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\group ->
                                insertToListDict (String.toLower group) document
                            )
                            dict
                            document.heightenGroups

                "hp" ->
                    insertToListDict
                        (document.hp
                            |> Maybe.andThen getIntFromString
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "hp_scale" ->
                    insertToListDict
                        (document.hpScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "intelligence_scale" ->
                    insertToListDict
                        (document.intelligenceScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

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

                "pantheon" ->
                    if List.isEmpty document.pantheons then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\pantheon ->
                                insertToListDict (String.toLower pantheon) document
                            )
                            dict
                            document.pantheons

                "perception_scale" ->
                    insertToListDict
                        (document.perceptionScale
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

                "rank" ->
                    insertToListDict
                        (document.level
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "rarity" ->
                    insertToListDict
                        (document.rarityId
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "reflex_scale" ->
                    insertToListDict
                        (document.reflexScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "sanctification" ->
                    insertToListDict
                        (document.sanctification
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

                "sfs" ->
                    insertToListDict
                        (document.pfs
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "size" ->
                    if List.isEmpty document.sizeIds then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\size ->
                                insertToListDict (String.fromInt size) document
                            )
                            dict
                            document.sizeIds

                "source" ->
                    List.foldl
                        (\source ->
                            insertToListDict (String.toLower source) document
                        )
                        dict
                        document.sourceList

                "source_category" ->
                    insertToListDict
                        (document.primarySourceCategory
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "source_group" ->
                    insertToListDict
                        (document.primarySourceGroup
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

                "spell_attack_bonus_scale" ->
                    if List.isEmpty document.spellAttackBonusScale then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\scale ->
                                insertToListDict (String.fromInt scale) document
                            )
                            dict
                            document.spellAttackBonusScale

                "spell_dc_scale" ->
                    if List.isEmpty document.spellDcScale then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\scale ->
                                insertToListDict (String.fromInt scale) document
                            )
                            dict
                            document.spellDcScale

                "strength_scale" ->
                    insertToListDict
                        (document.strengthScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "strike_damage_scale" ->
                    if List.isEmpty document.strikeDamageScale then
                        insertToListDict "" document dict

                    else
                        List.foldl
                            (\scale ->
                                insertToListDict (String.fromInt scale) document
                            )
                            dict
                            document.strikeDamageScale

                "spell_type" ->
                    insertToListDict
                        (document.spellType
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

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

                "warden_spell_tier" ->
                    insertToListDict
                        (document.wardenSpellTier
                            |> Maybe.withDefault ""
                            |> String.toLower
                        )
                        document
                        dict

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

                "will_scale" ->
                    insertToListDict
                        (document.willScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                        )
                        document
                        dict

                "wisdom_scale" ->
                    insertToListDict
                        (document.wisdomScale
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
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


sortGroupedList : Model -> String -> String -> Dict String Int -> List ( String, List a ) -> List ( String, List a )
sortGroupedList model field keyPrefix counts list =
    List.sortWith
        (\( k1, v1 ) ( k2, v2 ) ->
            case model.groupedSort of
                Alphanum ->
                    case ( k1, k2 ) of
                        ( "", _ ) ->
                            GT

                        ( _, "" ) ->
                            LT

                        _ ->
                            compareAlphanum field k1 k2

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


compareAlphanum : String -> String -> String -> Order
compareAlphanum field a b =
    case field of
        "actions" ->
            compare (actionsToInt a) (actionsToInt b)

        "armor_category" ->
            let
                armorCategoryToInt : String -> Int
                armorCategoryToInt category =
                    List.Extra.find
                        (Tuple.first >> String.toLower >> (==) category)
                        [ ( "unarmored", 0 )
                        , ( "light", 1 )
                        , ( "medium", 2 )
                        , ( "heavy", 3 )
                        ]
                        |> Maybe.map Tuple.second
                        |> Maybe.withDefault 4
            in
            compare (armorCategoryToInt a) (armorCategoryToInt b)

        "heighten_group" ->
            Maybe.map2 compare (getIntFromString a) (getIntFromString b)
                |> Maybe.withDefault (compare a b)

        "warden_spell_tier" ->
            let
                tierToInt : String -> Int
                tierToInt tier =
                    List.Extra.find
                        (Tuple.first >> String.toLower >> (==) tier)
                        [ ( "initiate", 0 )
                        , ( "advanced", 1 )
                        , ( "master", 2 )
                        , ( "peerless", 3 )
                        ]
                        |> Maybe.map Tuple.second
                        |> Maybe.withDefault 4
            in
            compare (tierToInt a) (tierToInt b)

        "weapon_category" ->
            let
                weaponCategoryToInt : String -> Int
                weaponCategoryToInt category =
                    List.Extra.find
                        (Tuple.first >> String.toLower >> (==) category)
                        [ ( "unarmed", 0 )
                        , ( "simple", 1 )
                        , ( "martial", 2 )
                        , ( "advanced", 3 )
                        , ( "ammunition", 3 )
                        ]
                        |> Maybe.map Tuple.second
                        |> Maybe.withDefault 5
            in
            compare (weaponCategoryToInt a) (weaponCategoryToInt b)

        _ ->
            Maybe.map2 compare (String.toInt a) (String.toInt b)
                |> Maybe.withDefault (compare a b)


viewGroupedTitle : Bool -> String -> String -> Html msg
viewGroupedTitle starfinder field value =
    let
        textFrom : (Int -> String) -> String -> Html msg
        textFrom fun v =
            case String.toInt v of
                Just int ->
                    Html.text (fun int)

                Nothing ->
                    Html.text v
    in
    if value == "" then
        Html.text "N/A"

    else if field == "ac" then
        Html.text (value ++ " AC")

    else if field == "actions" then
        Html.span
            []
            (viewTextWithActionIcons value)

    else if field == "alignment" then
        Html.text
            (Dict.fromList Data.allAlignments
                |> Dict.get value
                |> Maybe.withDefault value
                |> toTitleCase
            )

    else if field == "bulk" then
        if value == "0.1" then
            Html.text "L bulk"

        else
            Html.text (value ++ " bulk")

    else if field == "duration" then
        textFrom durationToString value

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
            [ viewPfsIcon starfinder 0 value
            , Html.text (toTitleCase value)
            ]

    else if field == "range" then
        case String.toInt value of
            Just range ->
                Html.text (rangeToString range)

            Nothing ->
                Html.text value

    else if field == "rank" then
        case String.toInt value of
            Just rank ->
                Html.text (toOrdinal rank ++ " rank")

            Nothing ->
                Html.text value

    else if field == "rarity" then
        case value of
            "1" ->
                Html.text "Common"

            "2" ->
                Html.text "Uncommon"

            "3" ->
                Html.text "Rare"

            "4" ->
                Html.text "Unique"

            _ ->
                Html.text value

    else if field == "size" then
        case value of
            "1" ->
                Html.text "Tiny"

            "2" ->
                Html.text "Small"

            "3" ->
                Html.text "Medium"

            "4" ->
                Html.text "Large"

            "5" ->
                Html.text "Huge"

            "6" ->
                Html.text "Gargantuan"

            _ ->
                Html.text value

    else if String.endsWith "_scale" field then
        textFrom scaleToString value

    else
        Html.text (toTitleCase value)


parseAndViewAsMarkdown : ViewModel -> String -> List (Html Msg)
parseAndViewAsMarkdown viewModel string =
    if String.isEmpty string then
        []

    else
        string
            |> Markdown.Parser.parse
            |> Result.map (List.map (Markdown.Block.walk mergeInlines))
            |> Result.map (List.map (Markdown.Block.walk paragraphToInline))
            |> Result.mapError (List.map Markdown.Parser.deadEndToString)
            |> viewMarkdown viewModel ""


viewMarkdown : ViewModel -> String -> ParsedMarkdownResult -> List (Html Msg)
viewMarkdown viewModel id markdown =
    case markdown of
        Ok blocks ->
            case Markdown.Renderer.render (markdownRenderer viewModel) blocks of
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


markdownRenderer : ViewModel -> Markdown.Renderer.Renderer (List (Html Msg))
markdownRenderer viewModel =
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
    , html = markdownHtmlRenderer viewModel
    , image =
        \image ->
            [ viewImage 150 image.src
            ]
    , link =
        \linkData children ->
            [ Html.a
                (List.append
                    [ if String.startsWith "/" linkData.destination then
                        HA.href (viewModel.resultBaseUrl ++ linkData.destination)

                      else
                        HA.href linkData.destination
                    , HAE.attributeIf (viewModel.openInNewTab) (HA.target "_blank")
                    , HAE.attributeMaybe HA.title linkData.title
                    ]
                    (linkEventAttributes linkData.destination)
                )
                (List.concat children)
            ]
    , orderedList = \startingIndex -> List.concat >> defaultRenderer.orderedList startingIndex >> List.singleton
    , paragraph = List.concat >> defaultRenderer.paragraph >> List.singleton
    , inlines = List.concat
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


markdownHtmlRenderer : ViewModel -> Markdown.Html.Renderer (List (List (Html Msg)) -> List (Html Msg))
markdownHtmlRenderer viewModel =
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
        , Markdown.Html.tag "date"
            (\value _ ->
                [ Html.text " "
                , Html.text (formatDate viewModel value)
                , Html.text " "
                ]
            )
            |> Markdown.Html.withAttribute "value"
        , Markdown.Html.tag "details"
            (\summary children ->
                [ Html.details
                    []
                    (List.append
                        [ Html.summary
                            []
                            [ Html.text summary ]
                        ]
                        (List.concat children)
                    )
                ]
            )
            |> Markdown.Html.withAttribute "summary"
        , Markdown.Html.tag "document"
            (\id _ ->
                [ Html.div
                    [ HA.class "loader"
                    , HA.style "margin-top" "20px"
                    ]
                    []
                ]
            )
            |> Markdown.Html.withAttribute "id"
        , Markdown.Html.tag "document-flattened"
            (\children ->
                List.concat children
            )
        , Markdown.Html.tag "filter-button"
            (\_ ->
                []
            )
        , Markdown.Html.tag "li"
            (\children ->
                [ Html.li
                    []
                    (List.concat children)
                ]
            )
        , Markdown.Html.tag "ol"
            (\start children ->
                [ Html.ol
                    [ HAE.attributeMaybe HA.start (Maybe.andThen String.toInt start) ]
                    (List.concat children)
                ]
            )
            |> Markdown.Html.withOptionalAttribute "start"
        , Markdown.Html.tag "query-button"
            (\_ ->
                []
            )
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
                            Maybe.Extra.or Nothing maybeRight

                        else
                            maybeRight
                in
                [ (String.toInt level
                    |> Maybe.map ((+) 0) -- titleLevel
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
                            , HA.class "nowrap"
                            ]
                            (List.concat
                                [ case maybePfs of
                                    Just pfs ->
                                        [ viewPfsIconWithLink viewModel.starfinder 0 pfs ]

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


viewImage : Int -> String -> Html msg
viewImage maxWidth url =
    Html.img
        [ HA.src url
        , HA.alt ""
        , HA.style "max-width" (String.fromInt maxWidth ++ "px")
        ]
        []


viewDocument : Model -> String -> Html Msg
viewDocument model id =
    case Dict.get id model.documents of
        Just (Ok document) ->
            if documentShouldBeMasked model.viewModel document then
                Html.Lazy.lazy2
                    viewMaskedDocument
                    model.viewModel
                    document

            else
                case document.markdown of
                    Parsed parsed ->
                        Html.Lazy.lazy3
                            viewParsedDocument
                            model.viewModel
                            document.id
                            parsed

                    ParsedWithUnflattenedChildren parsed ->
                        Html.Lazy.lazy3
                            viewParsedDocument
                            model.viewModel
                            document.id
                            parsed

                    NotParsed _ ->
                        Html.div
                            [ HA.style "color" "red" ]
                            [ Html.text ("Not parsed: " ++ document.id) ]

        Just (Err (Http.BadStatus 404)) ->
            Html.div
                [ HA.class "row"
                , HA.class "justify-center"
                , HA.style "font-size" "var(--font-very-large)"
                , HA.style "font-variant" "small-caps"
                ]
                [ Html.text "Page not found" ]

        Just (Err _) ->
            Html.div
                [ HA.style "color" "red" ]
                [ Html.text ("Failed to load " ++ id) ]

        Nothing ->
            Html.div
                [ HA.class "loader"
                , HA.style "margin-top" "20px"
                ]
                []


viewParsedDocument : ViewModel -> String -> Result (List String) (List Markdown.Block.Block) -> Html Msg
viewParsedDocument viewModel documentId parsed =
    Html.div
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        (viewMarkdown viewModel documentId parsed)



viewLinkPreview : Model -> Html Msg
viewLinkPreview model =
    case model.previewLink of
        Just link ->
            case getPreviewDocument model link of
                Just doc ->
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
                        , HA.class "gap-small"
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
                        [ viewDocument model doc.id ]

                _ ->
                    Html.text ""

        Nothing ->
            Html.text ""


getPreviewDocument : Model -> PreviewLink -> Maybe Document
getPreviewDocument model link =
    case Dict.get link.documentId model.documents of
        Just (Ok doc) ->
            if link.noRedirect || Maybe.Extra.isJust model.searchModel.legacyMode then
                Just doc

            else
                case ( model.legacyMode, doc.legacyIds, doc.remasterIds ) of
                    ( True, legacyId :: _, _ ) ->
                        Dict.get legacyId model.documents
                            |> Maybe.andThen Result.toMaybe

                    ( True, [], _ ) ->
                        Just doc

                    ( False, _, remasterId :: _ ) ->
                        Dict.get remasterId model.documents
                            |> Maybe.andThen Result.toMaybe

                    ( False, _, [] ) ->
                        Just doc

        _ ->
            Nothing


viewSortIcon : String -> Maybe SortDir -> Html msg
viewSortIcon field dir =
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


viewFilterIcon : Maybe Bool -> Html msg
viewFilterIcon value =
    case value of
        Just True ->
            Html.div
                [ HA.style "color" "#00cc00"
                , HA.attribute "aria-label" "Positive active filter"
                ]
                [ FontAwesome.view FontAwesome.Solid.checkCircle ]

        Just False ->
            Html.div
                [ HA.style "color" "#dd0000"
                , HA.attribute "aria-label" "Negative active filter"
                ]
                [ FontAwesome.view FontAwesome.Solid.minusCircle ]

        Nothing ->
            Html.div
                [ HA.attribute "aria-label" "Inactive filter"
                ]
                [ FontAwesome.view FontAwesome.Regular.circle ]


viewPfsIcon : Bool -> Int -> String -> Html msg
viewPfsIcon starfinder height pfs =
    case getPfsIconUrl starfinder pfs of
        Just url ->
            Html.img
                [ HA.src url
                , if starfinder then
                    HA.alt ("SFS " ++ pfs)

                  else
                    HA.alt ("PFS " ++ pfs)
                , if height == 0 then
                    HA.style "height" "1em"

                  else
                    HA.style "height" (String.fromInt height ++ "px")
                ]
                []

        Nothing ->
            Html.text ""


viewPfsIconWithLink : Bool -> Int -> String -> Html msg
viewPfsIconWithLink starfinder height pfs =
    case getPfsIconUrl starfinder pfs of
        Just url ->
            Html.a
                [ if starfinder then
                    HA.href "/sfs"

                  else
                    HA.href "/PFS.aspx"
                , HA.target "_blank"
                , HA.style "display" "flex"
                , if starfinder then
                    HA.attribute "aria-label" ("SFS " ++ pfs)

                  else
                    HA.attribute "aria-label" ("PFS " ++ pfs)
                ]
                [ viewPfsIcon starfinder height pfs
                ]

        Nothing ->
            Html.text ""


getPfsIconUrl : Bool -> String -> Maybe String
getPfsIconUrl starfinder pfs =
    case ( starfinder, String.toLower pfs ) of
        ( True, "standard" ) ->
            Just "/images/icons/sfs-standard.png"

        ( True, "limited" ) ->
            Just "/images/icons/sfs-limited.png"

        ( True, "restricted" ) ->
            Just "/images/icons/sfs-restricted.png"

        ( False, "standard" ) ->
            Just "/Images/Icons/PFS_Standard.png"

        ( False, "limited" ) ->
            Just "/Images/Icons/PFS_Limited.png"

        ( False, "restricted" ) ->
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

        "city" ->
            HA.class "trait-size"

        "metropolis" ->
            HA.class "trait-size"

        "town" ->
            HA.class "trait-size"

        "village" ->
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

        "universal ancestry" ->
            HA.class "trait-aon-special"

        _ ->
            HAE.empty


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


viewTextWithActionIcons : String -> List (Html msg)
viewTextWithActionIcons text =
    List.concat
        [ [ Html.text " " ]
        , replaceActionLigatures
            text
            ( "single action", "[one-action]" )
            [ ( "two actions", "[two-actions]" )
            , ( "three actions", "[three-actions]" )
            , ( "reaction", "[reaction]" )
            , ( "free action", "[free-action]" )
            ]
        , [ Html.text " " ]
        ]


replaceActionLigatures : String -> ( String, String ) -> List ( String, String ) -> List (Html msg)
replaceActionLigatures text ( find, replace ) rem =
    if String.contains find (String.toLower text) then
        case String.split find (String.toLower text) of
            before :: after ->
                List.concat
                    [ replaceActionLigatures
                        before
                        ( find, replace )
                        rem
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


documentShouldBeMasked : ViewModel -> Document -> Bool
documentShouldBeMasked viewModel document =
    List.all
        identity
        [ document.sourceGroups
            |> List.map String.toLower
            |> List.any (\sourceGroup -> Set.member sourceGroup viewModel.maskedSourceGroups)
        , List.any
            (\source -> not (caseInsensitiveContains "player's guide" source))
            document.sourceList
        , String.toLower document.type_ /= "source"
        ]


viewCss : Model -> Html msg
viewCss model =
    Html.node "style"
        []
        [ Html.text
            (css
                { pageWidth = model.pageWidth
                }
            )

        , if model.viewModel.showResultAdditionalInfo then
            Html.text ""

          else
            Html.text ".additional-info { display:none; }"

        , if model.viewModel.showResultSpoilers then
            Html.text ""

          else
            Html.text ".spoilers { display:none; }"

        , if model.viewModel.showResultSummary then
            Html.text ""

          else
            Html.text ".summary { display:none; }"

        , if model.viewModel.showResultTraits then
            Html.text ""

          else
            Html.text ".traits { display:none; }"

        , if model.viewModel.showResultAdditionalInfo && model.viewModel.showResultSummary then
            Html.text ""

          else
            Html.text ".additional-info + hr { display:none; }"

        , if model.viewModel.showResultIndex then
            Html.text ""

          else
            Html.text ".results-list { list-style-type: none; }"
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
        --color-box-bg-alt: color-mix(in lch, 85% var(--color-box-bg), black);
        --color-box-border: var(--text-1, #eeeeee);
        --color-box-text: var(--text-1, --color-text);
        --color-table-border: var(--color-text);
        --color-table-head-bg: var(--color-title1-bg);
        --color-table-head-text: var(--color-title1-text);
        --color-table-row-bg-alt: var(--bg-1, #64542f);
        --color-table-row-bg: var(--bg-2, #342c19);
        --color-table-row-text: var(--text-2, --color-text);
        --color-text: var(--text-1, #eeeeee);
        --color-text-inactive: color-mix(in lch, var(--color-text), #808080);
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
        --font-normal: 1em;
        --font-large: 1.25em;
        --font-very-large: 1.5em;
        --gap-tiny: 4px;
        --gap-small: 8px;
        --gap-medium: 12px;
        --gap-large: 20px;
        color: var(--color-text);
        color-scheme: var(--color-scheme, dark);
        font-family: var(--font-1, "Century Gothic", CenturyGothic, AppleGothic, sans-serif);
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
        border-color: var(--color-text-inactive);
        border-width: 1px;
        border-style: solid;
        border-radius: 4px;
        background-color: transparent;
        color: var(--color-text);
        font-family: inherit;
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

    h1, h2, h3, .h3, h4, .h4, h5, h6 {
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

    h3, .h3 {
        font-size: 1.125em;
    }

    h3.title, h3 .title {
        background-color: var(--color-title3-bg);
        color: var(--color-title3-text);
        line-height: 1;
    }

    h4, .h4 {
        font-size: 1.125em;
    }

    h4.title, h4 .title {
        background-color: var(--color-title4-bg);
        color: var(--color-title4-text);
        line-height: 1;
    }

    h5 {
        font-size: 1.125em;
    }

    h5.title, h5 .title {
        background-color: var(--color-title5-bg);
        color: var(--color-title5-text);
        line-height: 1;
    }

    h6 {
        font-size: 1.125em;
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

    .inline p {
        display: inline;
    }

    .inline div {
        display: inline;
    }

    pre {
        margin: 0;
        display: flex;
        flex-direction: column;
    }

    select {
        color: var(--color-text);
        font-family: inherit;
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

    ul, ol {
        list-style-position: outside;
        margin-block-start: 0.5em;
        margin-block-end: 0.5em;
    }

    ol ol {
        margin-block-start: 0.5em;
        margin-block-end: 0.5em;
    }

    ol ul {
        list-style-type: disc;
    }

    ol {
        list-style-type: decimal;
    }

    ol.results-list {
        padding-inline-start: 0;
    }

    #results:focus {
        outline: none;
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

    .numbers-grid {
        display: grid;
        column-gap: var(--gap-large);
        row-gap: var(--gap-small);
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    }

    .scale-grid {
        display: grid;
        column-gap: var(--gap-large);
        row-gap: var(--gap-small);
        grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
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

    .dropdown-filter-container {
        background-color: var(--color-box-bg);
        border-color: var(--color-box-border);
        border-style: solid;
        border-width: 1px;
        box-shadow: 0px 0px 10px black;
        color: var(--color-box-text);
        max-height: 250px;
        min-width: 200px;
        padding: 2px;
        position: absolute;
        top: calc(100% + 6px);
        z-index: 2;
    }

    .dropdown-filter-item {
        border: 0;
        padding: 8px;
        width: 100%;
        text-align: start;
    }

    .dropdown-filter-item.selected {
        border: solid 1px white;
        padding: 7px;
    }

    .dropdown-filter-hint {
        background-color: var(--color-box-bg);
        border: solid 1px var(--color-box-border);
        box-shadow: 0px 0px 10px black;
        color: var(--color-box-text);
        padding: 8px;
        font-size: 1.125em;
        position: absolute;
        top: calc(100% + 8px);
        z-index: 2;
    }

    .dropdown-filter-hint:after, .dropdown-filter-hint:before {
        content: "";
        width: 0;
        height: 0;
        position: absolute;
        bottom: 100%;
        left: 20px;
        border: solid transparent;
        pointer-events: none;
    }

    .dropdown-filter-hint:after {
        border-color: rgba(136, 183, 213, 0);
        border-bottom-color: var(--color-box-bg);
        border-width: 12px;
        margin-left: -12px;
    }

    .dropdown-filter-hint:before {
        border-color: rgba(194, 225, 245, 0);
        border-bottom-color: var(--color-box-border);
        border-width: 13px;
        margin-left: -13px;
    }

    .fade-in {
        animation: 0.3s fade-in;
    }

    .fill-width {
        box-sizing: border-box;
        width: 100%;
    }

    .filter-type {
        border-radius: 4px;
        border-width: 0;
        background-color: var(--color-title1-bg);
        color: var(--color-title1-text);
        font-size: 1em;
        font-variant: small-caps;
        font-weight: 700;
        padding: 4px 9px;
    }

    .foldable-container {
        transition: height ease-in-out 0.2s;
        overflow: hidden;
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

    .header-margins h3:not(:first-child) {
        margin-top: var(--gap-medium);
    }

    .input-container {
        background-color: var(--color-bg);
        border-style: solid;
        border-radius: 4px;
        border-width: 2px;
        border-color: #808080;
        flex-wrap: nowrap;
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
        white-space: nowrap;
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

    .monospace, code {
        background-color: var(--color-box-bg-alt);
        font-family: monospace;
        font-size: var(--font-normal);
    }

    .nowrap {
        flex-wrap: nowrap;
    }

    .no-ul-margin ul {
        margin: 0;
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
        min-width: 0;
    }

    .results-list {
        margin: 0;
        list-style-position: inside;
    }

    .results-list.item-gap-small > li + li {
        margin-top: var(--gap-small);
    }

    .results-list.item-gap-large > li + li {
        margin-top: var(--gap-large);
    }

    .results-list > li::marker {
        color: var(--color-text-inactive);
        font-size: 0.875em;
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

    .skip-link {
        position: absolute;
        left: -1000px;
    }

    .skip-link:focus {
        position: static;
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
        font-size: 1em;
        font-variant: var(--element-font-variant);
        font-weight: 700;
    }

    .traitbadge {
        font-size: 0.5em;
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

    .loader-small {
        width: 16px;
        height: 16px;
        border: 2px solid #FFF;
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
