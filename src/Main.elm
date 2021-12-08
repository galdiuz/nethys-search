module Main exposing (main)

import Browser
import Browser.Navigation
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Decode.Field as Field
import Json.Encode as Encode
import Maybe.Extra
import Process
import Regex
import Task
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query


type alias Query =
    { fulltext : List String
    , must : List ( String, String )
    , mustNot : List ( String, String )
    , comparisons : List ( String, Comparison, Int )
    }


type QueryPart
    = Fulltext String
    | Must String String
    | MustNot String String
    | Comparison String Comparison Int


type alias Hit a =
    { id : String
    , score : Float
    , source : a
    }


type alias Document =
    { id : Int
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
    }


type Comparison
    = GT
    | GE
    | LT
    | LE


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
    | Weapon
    | WeaponGroup
    | Unknown


type Msg
    = NoOp
    | QueryChanged String
    | GotSearchResult (Result Http.Error (List (Hit Document)))
    | UrlChanged Url
    | UrlRequested Browser.UrlRequest
    | DebouncePassed Int


type alias Model =
    { query : String
    , searchResult : Maybe (Result Http.Error (List (Hit Document)))
    , navKey : Browser.Navigation.Key
    , debounce : Int
    , url : Url
    , elasticUrl : String
    , tracker : Maybe Int
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
    let
        query : String
        query =
            url
                |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string "q"))
                |> Maybe.Extra.join
                |> Maybe.withDefault ""

        model : Model
        model =
            { query = query
            , searchResult = Nothing
            , navKey = navKey
            , debounce = 0
            , url = url
            , elasticUrl = flags.elasticUrl
            , tracker = Nothing
            }
    in
    ( model, Cmd.none )
        |> searchWithCurrentQuery


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        QueryChanged str ->
            if String.isEmpty str then
                ( { model
                    | query = str
                    , searchResult = Nothing
                  }
                , setQueryParam "" model.url
                    |> Url.toString
                    |> Browser.Navigation.pushUrl model.navKey
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
                , setQueryParam model.query model.url
                    |> Url.toString
                    |> Browser.Navigation.pushUrl model.navKey
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

        UrlChanged url ->
            let
                query : String
                query =
                    url
                        |> Url.Parser.parse (Url.Parser.query (Url.Parser.Query.string "q"))
                        |> Maybe.Extra.join
                        |> Maybe.withDefault ""
            in
            ( { model | query = query }
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


parseQueryParts : String -> List QueryPart
parseQueryParts str =
    List.map
        (\part ->
            if String.contains ">=" part then
                case String.split ">=" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field GE int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains "<=" part then
                case String.split "<=" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field LE int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains ">" part then
                case String.split ">" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field GT int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains "<" part then
                case String.split "<" part of
                    [ field, value ] ->
                        case String.toInt value of
                            Just int ->
                                Comparison field LT int

                            Nothing ->
                                Fulltext part

                    _ ->
                        Fulltext part

            else if String.contains "!=" part then
                case String.split "!=" part of
                    [ field, value ] ->
                        MustNot field value

                    _ ->
                        Fulltext part

            else if String.contains "=" part then
                case String.split "=" part of
                    [ field, value ] ->
                        Must field value

                    _ ->
                        Fulltext part

            else
                Fulltext part
        )
        (String.split " " str)


buildQuery : List QueryPart -> Query
buildQuery parts =
    List.foldl
        (\part query ->
            case part of
                Fulltext str ->
                    { query | fulltext = List.append query.fulltext [str] }

                Must field value ->
                    { query | must =  ( field, value ) :: query.must }

                MustNot field value ->
                    { query | mustNot = ( field, value ) :: query.mustNot }

                Comparison field operator value ->
                    { query | comparisons = ( field, operator, value ) :: query.comparisons }

        )
        { fulltext = []
        , must = []
        , mustNot = []
        , comparisons = []
        }
        parts
        |> (\query ->
                { query | fulltext = List.filter (not << String.isEmpty) query.fulltext }
            )


setQueryParam : String -> Url -> Url
setQueryParam value url =
    { url
        | query =
            if value /= "" then
                Just ("q=" ++ Url.percentEncode value)

            else
                Nothing
    }


buildSearchBody : String -> Encode.Value
buildSearchBody queryString =
    let
        query =
            buildQuery (parseQueryParts queryString)
    in
    Encode.object
        [ ( "query"
          , Encode.object
                [ ( "bool"
                  , encodeObjectMaybe
                        [ if List.isEmpty query.fulltext then
                            Nothing

                          else
                            Just
                            ( "must"
                            , Encode.object
                                [ ( "multi_match"
                                  , Encode.object
                                        [ ( "query"
                                          , Encode.string (String.join " " query.fulltext)
                                          )
                                        , ( "fuzziness", Encode.string "auto" )
                                        , ( "type", Encode.string "most_fields" )
                                        , ( "fields"
                                          , Encode.list
                                                Encode.string
                                                [ "*"
                                                , "description^0.2"
                                                , "type^4"
                                                , "name^5"
                                                , "traits^2"
                                                ]
                                          )
                                        ]
                                  )
                                ]
                            )

                        , if List.isEmpty query.must && List.isEmpty query.comparisons then
                            Nothing

                          else
                            Just
                                ( "filter"
                                , Encode.list Encode.object
                                    (List.append
                                        (List.map
                                            (\( field, value ) ->
                                                ( "term"
                                                , Encode.object [ ( field, Encode.string value ) ]
                                                )
                                            )
                                            query.must
                                        )
                                        (List.map
                                            (\( field, comparison, value ) ->
                                                ( "range"
                                                , Encode.object
                                                    [ ( field
                                                      , Encode.object
                                                            [ ( comparisonToString comparison, Encode.int value ) ]
                                                      )
                                                    ]
                                                )
                                            )
                                            query.comparisons
                                        )
                                        |> List.map List.singleton
                                    )
                                )

                        , if List.isEmpty query.mustNot then
                            Nothing

                          else
                            Just
                                ( "must_not"
                                , Encode.list Encode.object
                                    (List.map
                                          (\( field, value ) ->
                                              ( "term"
                                              , Encode.object [ ( field, Encode.string value ) ]
                                              )
                                          )
                                          query.mustNot
                                          |> List.map List.singleton
                                    )
                                )
                        ]
                  )
                ]
          )
        , ( "size", Encode.int 100 )
        ]



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
                , body = Http.jsonBody (buildSearchBody model.query)
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
    Decode.succeed
        { id = id
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

                    "rlane" ->
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

                    "weapon" ->
                        Decode.succeed Weapon

                    "weapon-group" ->
                        Decode.succeed WeaponGroup

                    _ ->
                        Decode.succeed Unknown
            )


getUrl : Document -> String
getUrl doc =
    case doc.category of
        Action ->
            buildUrl "Actions" doc.id

        Ancestry ->
            buildUrl "Ancestrys" doc.id

        Archetype ->
            buildUrl "Archetypes" doc.id

        Armor ->
            buildUrl "Armors" doc.id

        ArmorGroup ->
            buildUrl "ArmorGroups" doc.id

        Background ->
            buildUrl "Backgrounds" doc.id

        Class ->
            buildUrl "Classs" doc.id

        Condition ->
            buildUrl "Conditions" doc.id

        Curse ->
            buildUrl "Curses" doc.id

        Deity ->
            buildUrl "Deities" doc.id

        Disease ->
            buildUrl "Diseases" doc.id

        Domain ->
            buildUrl "Domains" doc.id

        Equipment ->
            buildUrl "Equipment" doc.id

        Feat ->
            buildUrl "Feats" doc.id

        Hazard ->
            buildUrl "Hazards" doc.id

        Heritage ->
            buildUrl "Heritages" doc.id

        Language ->
            buildUrl "Languages" doc.id

        Monster ->
            buildUrl "Monsters" doc.id

        MonsterAbility ->
            buildUrl "MonsterAbilities" doc.id

        MonsterFamily ->
            buildUrl "MonsterFamilies" doc.id

        NPC ->
            buildUrl "NPCs" doc.id

        Plane ->
            buildUrl "Planes" doc.id

        Relic ->
            buildUrl "Relics" doc.id

        Ritual ->
            buildUrl "Rituals" doc.id

        Rules ->
            buildUrl "Rules" doc.id

        Shield ->
            buildUrl "Shields" doc.id

        Skill ->
            buildUrl "Skills" doc.id

        Spell ->
            buildUrl "Spells" doc.id

        Trait ->
            buildUrl "Traits" doc.id

        Weapon ->
            buildUrl "Weapons" doc.id

        WeaponGroup ->
            buildUrl "WeaponGroups" doc.id

        Unknown ->
            ""


buildUrl : String -> Int -> String
buildUrl category id =
    "https://2e.aonprd.com/" ++ category ++ ".aspx?ID=" ++ String.fromInt id


comparisonToString : Comparison -> String
comparisonToString comparison =
    case comparison of
        GT -> "gt"
        GE -> "gte"
        LT -> "lt"
        LE -> "lte"


view : Model -> Browser.Document Msg
view model =
    { title =
        if String.isEmpty model.query then
            "Nethys Search"

        else
            model.query ++ " - Nethys Search"
    , body =
        [ Html.div
            []
            [ Html.text "Search"
            , Html.input
                [ HE.onInput QueryChanged
                , HA.value model.query
                , HA.style "width" "90%"
                ]
                [ Html.text model.query ]
            ]
        , case model.searchResult of
            Just (Ok hits) ->
                Html.ul
                    []
                    (List.map
                        (\hit ->
                            Html.li
                                [ HA.style "display" "block"
                                , HA.style "margin-bottom" "5px"
                                ]
                                [ Html.a
                                    [ HA.href (getUrl hit.source)
                                    , HA.target "_blank"
                                    ]
                                    [ Html.text hit.source.name ]

                                , Html.div
                                    []
                                    [ Html.text hit.source.type_
                                    , Html.text " "
                                    , case hit.source.level of
                                        Just level ->
                                            Html.text (String.fromInt level)

                                        Nothing ->
                                            Html.text ""

                                    , case hit.source.category of
                                        Deity ->
                                            case hit.source.alignment of
                                                Just alignment ->
                                                    Html.span
                                                        []
                                                        [ Html.text " - "
                                                        , Html.text alignment
                                                        ]

                                                Nothing ->
                                                    Html.text ""

                                        Rules ->
                                            case hit.source.breadcrumbs of
                                                Just breadcrumbs ->
                                                    Html.span
                                                        []
                                                        [ Html.text " - "
                                                        , Html.text breadcrumbs
                                                        ]

                                                Nothing ->
                                                    Html.text ""

                                        Weapon ->
                                            Html.span
                                                []
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
                                                    |> List.append [ Html.text " - " ]
                                                )


                                        _ ->
                                            Html.text ""

                                    , if List.isEmpty hit.source.traits then
                                        Html.text ""

                                      else
                                        Html.span
                                            []
                                            [ Html.text " - "
                                            , Html.span
                                                []
                                                (List.map
                                                    (\trait ->
                                                        Html.text ("[" ++ trait ++ "] ")
                                                    )
                                                    hit.source.traits
                                                )
                                            ]
                                    ]
                                ]
                        )
                        hits
                    )

            _ ->
                Html.text ""
        ]
    }
