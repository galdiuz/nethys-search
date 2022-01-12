module Main exposing (main)

import Browser
import Browser.Navigation
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


type Msg
    = NoOp
    | GotSearchResult (Result Http.Error (List (Hit Document)))
    | QueryChanged String
    | QueryTypeSelected QueryType
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | DebouncePassed Int


type alias Model =
    { debounce : Int
    , elasticUrl : String
    , navKey : Browser.Navigation.Key
    , query : String
    , queryType : QueryType
    , searchResult : Maybe (Result Http.Error (List (Hit Document)))
    , tracker : Maybe Int
    , url : Url
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( { debounce = 0
      , elasticUrl = flags.elasticUrl
      , navKey = navKey
      , query = ""
      , queryType = Standard
      , searchResult = Nothing
      , tracker = Nothing
      , url = url
      }
        |> updateModelFromQueryString url
    , Cmd.none
    )
        |> searchWithCurrentQuery


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        QueryChanged str ->
            if String.isEmpty (String.trim str) then
                ( { model
                    | query = str
                    , searchResult = Nothing
                  }
                , updateUrl model str model.queryType
                )

            else
                ( { model
                    | query = str
                    , debounce = model.debounce + 1
                  }
                , Process.sleep 250
                    |> Task.perform (\_ -> DebouncePassed (model.debounce + 1))
                )

        DebouncePassed debounce ->
            if model.debounce == debounce then
                ( model
                , updateUrl model model.query model.queryType
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

        QueryTypeSelected queryType ->
            ( model
            , updateUrl model model.query queryType
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


updateUrl : Model -> String -> QueryType -> Cmd Msg
updateUrl { url, navKey } query queryType =
    { url
        | query =
            [ ( "q", query )
            , ( "type"
              , case queryType of
                    Standard ->
                        ""

                    ElasticsearchQueryString ->
                        "eqs"
              )
            ]
                |> List.filter (Tuple.second >> String.isEmpty >> not)
                |> List.map (\(key, val) -> Url.Builder.string key val)
                |> Url.Builder.toQuery
                |> String.dropLeft 1
                |> String.Extra.nonEmpty
    }
        |> Url.toString
        |> Browser.Navigation.pushUrl navKey


buildSearchBody : String -> QueryType -> Encode.Value
buildSearchBody queryString queryType =
    Encode.object
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , encodeObjectMaybe
                        [ Just
                            ( "should"
                            , Encode.list Encode.object
                                (case queryType of
                                    Standard ->
                                        [ [ ( "match_phrase"
                                            , Encode.object
                                                [ ( "name"
                                                  , Encode.object
                                                        [ ( "query"
                                                          , Encode.string queryString
                                                          )
                                                        , ( "boost", Encode.int 10 )
                                                        ]
                                                  )
                                                ]
                                            )
                                          ]
                                        , [ ( "match_phrase_prefix"
                                          , Encode.object
                                                [ ( "name"
                                                  , Encode.object
                                                        [ ( "query"
                                                          , Encode.string queryString
                                                          )
                                                        , ( "boost", Encode.int 5 )
                                                        ]
                                                  )
                                                ]
                                          )
                                          ]
                                        , [ ( "multi_match"
                                            , Encode.object
                                                [ ( "query"
                                                  , Encode.string queryString
                                                  )
                                                , ( "type", Encode.string "most_fields" )
                                                , ( "fields"
                                                  , Encode.list
                                                        Encode.string
                                                        [ "*"
                                                        , "type^4"
                                                        , "name^5"
                                                        , "traits^2"
                                                        , "text^0.2"
                                                        ]
                                                  )
                                                ]
                                            )
                                          ]
                                        , [ ( "multi_match"
                                            , Encode.object
                                                [ ( "query"
                                                  , Encode.string queryString
                                                  )
                                                , ( "fuzziness", Encode.string "auto" )
                                                , ( "type", Encode.string "most_fields" )
                                                , ( "fields"
                                                  , Encode.list
                                                        Encode.string
                                                        [ "*"
                                                        , "type^4"
                                                        , "name^5"
                                                        , "traits^2"
                                                        , "text^0.2"
                                                        ]
                                                  )
                                                ]
                                            )
                                          ]
                                        ]

                                    ElasticsearchQueryString ->
                                        [ [ ( "query_string"
                                            , Encode.object
                                                [ ( "query"
                                                  , Encode.string queryString
                                                  )
                                                , ( "default_operator", Encode.string "AND" )
                                                , ( "fields"
                                                  , Encode.list
                                                        Encode.string
                                                        [ "*"
                                                        , "type^4"
                                                        , "name^5"
                                                        , "traits^2"
                                                        , "text^0.2"
                                                        ]
                                                  )
                                                ]
                                            )
                                          ]
                                        ]
                                )
                            )

                        -- , if List.isEmpty query.must then
                        --     Nothing

                        --   else
                        --     Just
                        --         ( "filter"
                        --         , Encode.list Encode.object
                        --             (List.map
                        --                 (\( field, value ) ->
                        --                     ( "term"
                        --                     , Encode.object [ ( field, Encode.string value ) ]
                        --                     )
                        --                 )
                        --                 query.must
                        --                 |> List.map List.singleton
                        --             )
                        --         )

                        -- , if List.isEmpty query.mustNot then
                        --     Nothing

                        --   else
                        --     Just
                        --         ( "must_not"
                        --         , Encode.list Encode.object
                        --             (List.map
                        --                 (\( field, value ) ->
                        --                     ( "term"
                        --                     , Encode.object [ ( field, Encode.string value ) ]
                        --                     )
                        --                 )
                        --                 query.mustNot
                        --                 |> List.map List.singleton
                        --             )
                        --         )
                        ]
                  )
                ]
          )
        , ( "size", Encode.int 100 )
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
                , body = Http.jsonBody (buildSearchBody model.query model.queryType)
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
    Field.attempt "traits" (Decode.list Decode.string) <| \maybeTraits ->
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
    Field.attempt "price" Decode.string <| \price ->
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
            , if True then
                Html.text cssDark

              else
                Html.text ""
            ]
        , Html.div
            [ HA.class "column"
            , HA.class "align-center"
            ]
            [ Html.div
                [ HA.class "column"
                , HA.class "gap-large"
                , HA.style "max-width" "1000px"
                , HA.style "width" "100%"
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


viewTitle : Html Msg
viewTitle =
    Html.header
        [ HA.class "column"
        , HA.class "align-center"
        ]
        [ Html.h1
            [ HA.class "title"
            ]
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
        , HA.class "gap-tiny"
        , HA.class "align-center"
        ]
        [ Html.input
            [ HE.onInput QueryChanged
            , HA.value model.query
            , HA.placeholder "Enter search query..."
            , HA.autofocus True
            , HA.style "width" "100%"
            ]
            [ Html.text model.query ]

        , Html.div
            [ HA.class "row"
            , HA.class "gap-medium"
            ]
            [ Html.label
                []
                [ Html.input
                    [ HA.type_ "radio"
                    , HA.checked (model.queryType == Standard)
                    , HE.onInput (\_ -> QueryTypeSelected Standard)
                    ]
                    []
                , Html.text "Standard Query"
                ]
            , Html.label
                []
                [ Html.input
                    [ HA.type_ "radio"
                    , HA.checked (model.queryType == ElasticsearchQueryString)
                    , HE.onInput (\_ -> QueryTypeSelected ElasticsearchQueryString)
                    ]
                    []
                , Html.text "Elasticsearch Query String"
                ]
            ]
        ]



viewSearchResults : Model -> Html msg
viewSearchResults model =
    if Maybe.Extra.isJust model.tracker then
        Html.div
            [ HA.class "loader" ]
            []

    else
        case model.searchResult of
            Just (Ok []) ->
                Html.div
                    [ HA.style "font-size" "24px"
                    ]
                    [ Html.text "No matches"
                    ]

            Just (Ok hits) ->
                Html.div
                    [ HA.class "column"
                    , HA.class "gap-large"
                    ]
                    (List.map viewSingleSearchResult hits)

            Just (Err (Http.BadStatus 400)) ->
                Html.div
                    [ HA.style "font-size" "24px"
                    ]
                    [ Html.text "Error: Failed to parse query"
                    ]

            _ ->
                Html.text ""


viewSingleSearchResult : Hit Document -> Html msg
viewSingleSearchResult hit =
    Html.section
        [ HA.class "column"
        , HA.class "gap-small"
        ]
        [ Html.h2
            [ HA.class "result-title" ]
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
                [ HA.class "result-title-type" ]
                [ Html.text hit.source.type_
                , case hit.source.level of
                    Just level ->
                        Html.text (" " ++ String.fromInt level)

                    Nothing ->
                        Html.text ""
                ]
            ]

        , Html.div
            [ HA.class "row"
            ]
            (List.map
                viewTrait
                (List.append
                    hit.source.traits
                    (case ( hit.source.category, hit.source.alignment ) of
                        ( Deity, Just alignment ) ->
                            [ alignment ]

                        ( Cause, Just alignment ) ->
                            [ alignment ]

                        _ ->
                            []
                    )
                )
            )

        , viewSearchResultAdditionalInfo hit
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

    body {
        font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif;
        margin: 8px;
    }

    input {
        border-style: solid;
        border-radius: 4px;
        padding: 4px;
        font-size: 24px;
    }

    a {
        color: inherit;
        text-decoration: none;
    }

    a:hover {
        text-decoration: underline;
    }

    h1 {
        font-weight: normal;
        margin: 0;
    }

    h2 {
        margin: 0;
    }

    .align-center {
        align-items: center;
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

    .column:empty, .row:empty {
        display: none;
    }

    .gap-large {
        gap: 20px;
    }

    .gap-medium {
        gap: 12px;
    }

    .gap-small {
        gap: 8px;
    }

    .gap-tiny {
        gap: 4px;
    }

    .column.gap-tiny .row.gap-medium {
        column-gap: 12px;
        row-gap: 4px;
    }

    .icon-font {
        font-family: "Pathfinder-Icons";
        font-variant-caps: normal;
        font-weight: normal;
    }

    .result-title {
        border-radius: 4px;
        display: flex;
        font-size: 24px;
        font-variant: small-caps;
        font-weight: 700;
        gap: 8px;
        justify-content: space-between;
        padding: 4px 9px;
    }

    .result-title-type {
        text-align: right;
    }

    .title {
        font-size: 48px;
    }

    .trait {
        border-color: #d8c483;
        border-style: double;
        border-width: 2px;
        background-color: #522e2c;
        padding: 3px 5px;
        font-variant: small-caps;
        font-weight: 700;
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
    body {
        background-color: #111111;
        color: #eeeeee;
    }

    input {
        background-color: #111111;
        color: #eeeeee;
    }

    .result-title {
        background-color: #522e2c;
        color: #cbc18f;
    }

    .icon-font {
        color: #cccccc;
    }
    """
