module AoN exposing (main)

import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Attributes.Extra as HAE
import Http
import Regex
import Json.Decode as Decode
import Json.Decode.Field as Field
import Json.Encode as Encode
import List.Extra
import String.Extra
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Url


type alias Flags =
    { elasticUrl : String
    }


type alias Model =
    { documents : Dict String (Result Http.Error Document)
    , elasticUrl : String
    , navKey : Browser.Navigation.Key
    , page : Page
    }


type alias Document =
    { id : String
    , category : String
    , name : String
    , type_ : String
    , url : String
    , abilities : List String
    , abilityType : Maybe String
    , ac : Maybe Int
    , actions : Maybe String
    , activate : Maybe String
    , advancedDomainSpell : Maybe String
    , alignment : Maybe String
    , ammunition : Maybe String
    , area : Maybe String
    , aspect : Maybe String
    , bloodlines : List String
    , breadcrumbs : List String
    , bulk : Maybe String
    , cast : Maybe String
    , charisma : Maybe Int
    , components : List String
    , constitution : Maybe Int
    , cost : Maybe String
    , creatureFamily : Maybe String
    , damage : Maybe String
    , deities : List String
    , dexterity : Maybe Int
    , divineFont : Maybe String
    , domains : List String
    , domainSpell : Maybe String
    , duration : Maybe String
    , familiarAbilities : List String
    , favoredWeapon : Maybe String
    , feats : List String
    , fort : Maybe Int
    , frequency : Maybe String
    , hands : Maybe String
    , heighten : List String
    , hp : Maybe Int
    , immunities : List String
    , intelligence : Maybe Int
    , lessonType : Maybe String
    , level : Maybe Int
    , markdown : String
    , mysteries : List String
    , patronThemes : List String
    , perception : Maybe Int
    , prerequisites : Maybe String
    , price : Maybe String
    , primaryCheck : Maybe String
    , range : Maybe String
    , ref : Maybe Int
    , reload : Maybe String
    , requiredAbilities : Maybe String
    , requirements : Maybe String
    , resistances : List String
    , savingThrow : Maybe String
    , secondaryCasters : Maybe String
    , secondaryChecks : Maybe String
    , skills : List String
    , source : Maybe String
    , spellList : Maybe String
    , spoilers : Maybe String
    , strength : Maybe Int
    , targets : Maybe String
    , traditions : List String
    , traits : List String
    , trigger : Maybe String
    , usage : Maybe String
    , weaknesses : List String
    , weaponCategory : Maybe String
    , weaponGroup : Maybe String
    , will : Maybe Int
    , wisdom : Maybe Int
    }


type Page
    = Action String
    | Class String
    | Classes
    | ClassFeats String
    | Instinct String
    | Instincts
    | NotFound
    | Rule (List String)
    | Rules
    | SampleBuild String String
    | SampleBuilds String
    | Trait String
    | Traits


type Msg
    = GotDocument String (Result Http.Error Document)
    | GotDocuments (List String) (Result Http.Error (List Document))
    | NoOp
    | UrlChanged Url.Url
    | UrlRequested Browser.UrlRequest


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init flags url navKey =
    ( { documents = Dict.empty
      , elasticUrl = flags.elasticUrl
      , navKey = navKey
      , page = urlToPage url
      }
    , Cmd.none
    )
        |> fetchData


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDocument id result ->
            let
                result_ =
                    case result of
                        Ok doc ->
                            case doc.id of
                                "class-barbarian" ->
                                    Ok { doc | markdown = barbarian }

                                "action-rage" ->
                                    Ok { doc | markdown = rage }

                                _ ->
                                    result

                        _ ->
                            result

                _ =
                    case result_ of
                        Ok doc ->
                            getChildDocuments doc.markdown
                                |> Debug.log "child ids"

                        Err _ ->
                            []
            in
            ( { model | documents = Dict.insert id result_ model.documents }
            , result_
                |> Result.map .markdown
                |> Result.map getChildDocuments
                |> Result.map (fetchDocuments model)
                |> Result.withDefault Cmd.none
            )

        GotDocuments ids result ->
            let
                documents : Dict String (Result Http.Error Document)
                documents =
                    ids
                        |> List.map
                            (\id ->
                                ( id
                                , Result.andThen
                                    (\docs ->
                                        List.Extra.find
                                            (.id >> (==) id)
                                            docs
                                            |> Result.fromMaybe Http.Timeout
                                    )
                                    result
                                )
                            )
                        |> Dict.fromList
            in
            ( { model
                | documents =
                    Dict.union model.documents documents
              }
            , result
                |> Result.map (List.map .markdown)
                |> Result.map (List.concatMap getChildDocuments)
                |> Result.map (fetchDocuments model)
                |> Result.withDefault Cmd.none
            )

        NoOp ->
            ( model
            , Cmd.none
            )

        UrlChanged url ->
            ( { model | page = urlToPage url }
            , Cmd.none
            )
                |> fetchData

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Cmd.none
                    )


dasherize : String -> String
dasherize string =
    string
        |> String.trim
        |> Regex.replace (regexFromString "([A-Z])") (.match >> String.append "-")
        |> Regex.replace (regexFromString "[^a-zA-Z0-9]+") (\_ -> "-")
        |> Regex.replace (regexFromString "^-+|-+$") (\_ -> "")
        |> String.toLower


regexFromString : String -> Regex.Regex
regexFromString =
    Regex.fromString >> Maybe.withDefault Regex.never


urlToPage : Url.Url -> Page
urlToPage url =
    case String.split "/" (String.dropLeft 1 url.path) of
        [ "action", id ] ->
            Action id

        [ "classes" ] ->
            Classes

        [ "classes", id ] ->
            Class id

        [ "classes", class, "feats" ] ->
            ClassFeats class

        [ "classes", "barbarian", "instincts", id ] ->
            Instinct id

        [ "classes", "barbarian", "instincts" ] ->
            Instincts

        [ "classes", class, "sample-builds", id ] ->
            SampleBuild class id

        [ "classes", class, "sample-builds" ] ->
            SampleBuilds class

        [ "rules" ] ->
            Rules

        "rules" :: ids  ->
            Rule ids

        [ "traits", id ] ->
            Trait id

        [ "traits" ] ->
            Traits

        _ ->
            NotFound


documentToUrl : Document -> String
documentToUrl document =
    case document.category of
        "action" ->
            "/action/" ++ document.url

        "class" ->
            "/classes/" ++ document.url

        "rules" ->
            List.append document.breadcrumbs [ document.name ]
                |> List.map dasherize
                |> String.join "/"
                |> (++) "/rules/"

        _ ->
            ""


pageToDataKey : Page -> Maybe String
pageToDataKey page =
    case page of
        Action id ->
            Just ("action-" ++ id)

        Class id ->
            Just ("class-" ++ id)

        Instincts ->
            Just "instincts"

        Rule ids ->
            Just ("rules-" ++ String.join "-" ids)

        Trait id ->
            Just ("trait-" ++ id)

        NotFound ->
            Nothing

        _ ->
            Nothing


fetchData : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
fetchData ( model, cmd ) =
    ( model
    , case pageToDataKey model.page of
        Just id ->
            fetchDocument model id

        Nothing ->
            Cmd.none
    )


fetchDocument model id =
    case Dict.get id model.documents of
        Just _ ->
            Cmd.none

        Nothing ->
            Http.request
                { method = "GET"
                , url = model.elasticUrl ++ "/_doc/" ++ id
                , headers = []
                , body = Http.emptyBody
                , expect = Http.expectJson (GotDocument id) documentDecoder
                , timeout = Just 10000
                , tracker = Nothing
                }


fetchDocuments model ids =
    let
        idsToFetch : List String
        idsToFetch =
            List.filter
                (\id -> not (Dict.member id model.documents))
                ids
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
                    (GotDocuments idsToFetch)
                    (Decode.field "docs" (Decode.list documentDecoder))
            , timeout = Just 10000
            , tracker = Nothing
            }


documentDecoder : Decode.Decoder Document
documentDecoder =
    Field.requireAt [ "_id" ] Decode.string <| \id ->
    Field.requireAt [ "_source", "category" ] Decode.string <| \category ->
    Field.requireAt [ "_source", "name" ] Decode.string <| \name ->
    Field.requireAt [ "_source", "text" ] Decode.string <| \text ->
    Field.requireAt [ "_source", "type" ] Decode.string <| \type_ ->
    Field.requireAt [ "_source", "url" ] Decode.string <| \url ->
    Field.attemptAt [ "_source", "markdown" ] Decode.string <| \markdown ->
    Field.attemptAt [ "_source", "ability" ] stringListDecoder <| \abilities ->
    Field.attemptAt [ "_source", "ability_type" ] Decode.string <| \abilityType ->
    Field.attemptAt [ "_source", "ac" ] Decode.int <| \ac ->
    Field.attemptAt [ "_source", "actions" ] Decode.string <| \actions ->
    Field.attemptAt [ "_source", "activate" ] Decode.string <| \activate ->
    Field.attemptAt [ "_source", "advanced_domain_spell" ] Decode.string <| \advancedDomainSpell ->
    Field.attemptAt [ "_source", "alignment" ] Decode.string <| \alignment ->
    Field.attemptAt [ "_source", "ammunition" ] Decode.string <| \ammunition ->
    Field.attemptAt [ "_source", "area" ] Decode.string <| \area ->
    Field.attemptAt [ "_source", "aspect" ] Decode.string <| \aspect ->
    Field.attemptAt [ "_source", "breadcrumbs" ] stringListDecoder <| \breadcrumbs ->
    Field.attemptAt [ "_source", "bloodline" ] stringListDecoder <| \bloodlines ->
    Field.attemptAt [ "_source", "bulk_raw" ] Decode.string <| \bulk ->
    Field.attemptAt [ "_source", "cast" ] Decode.string <| \cast ->
    Field.attemptAt [ "_source", "charisma" ] Decode.int <| \charisma ->
    Field.attemptAt [ "_source", "component" ] (Decode.list Decode.string) <| \components ->
    Field.attemptAt [ "_source", "constitution" ] Decode.int <| \constitution ->
    Field.attemptAt [ "_source", "cost" ] Decode.string <| \cost ->
    Field.attemptAt [ "_source", "creature_family" ] Decode.string <| \creatureFamily ->
    Field.attemptAt [ "_source", "damage" ] Decode.string <| \damage ->
    Field.attemptAt [ "_source", "deity" ] stringListDecoder <| \deities ->
    Field.attemptAt [ "_source", "dexterity" ] Decode.int <| \dexterity ->
    Field.attemptAt [ "_source", "divine_font" ] Decode.string <| \divineFont ->
    Field.attemptAt [ "_source", "domain" ] (Decode.list Decode.string) <| \domains ->
    Field.attemptAt [ "_source", "domain_spell" ] Decode.string <| \domainSpell ->
    Field.attemptAt [ "_source", "duration" ] Decode.string <| \duration ->
    Field.attemptAt [ "_source", "familiar_ability" ] stringListDecoder <| \familiarAbilities ->
    Field.attemptAt [ "_source", "favored_weapon" ] Decode.string <| \favoredWeapon ->
    Field.attemptAt [ "_source", "feat" ] stringListDecoder <| \feats ->
    Field.attemptAt [ "_source", "fortitude_save" ] Decode.int <| \fort ->
    Field.attemptAt [ "_source", "frequency" ] Decode.string <| \frequency ->
    Field.attemptAt [ "_source", "hands" ] Decode.string <| \hands ->
    Field.attemptAt [ "_source", "heighten" ] (Decode.list Decode.string) <| \heighten ->
    Field.attemptAt [ "_source", "hp" ] Decode.int <| \hp ->
    Field.attemptAt [ "_source", "immunity" ] (Decode.list Decode.string) <| \immunities ->
    Field.attemptAt [ "_source", "intelligence" ] Decode.int <| \intelligence ->
    Field.attemptAt [ "_source", "lesson_type" ] Decode.string <| \lessonType ->
    Field.attemptAt [ "_source", "level" ] Decode.int <| \level ->
    Field.attemptAt [ "_source", "mystery" ] stringListDecoder <| \mysteries ->
    Field.attemptAt [ "_source", "patron_theme" ] stringListDecoder <| \patronThemes ->
    Field.attemptAt [ "_source", "perception" ] Decode.int <| \perception ->
    Field.attemptAt [ "_source", "prerequisite" ] Decode.string <| \prerequisites ->
    Field.attemptAt [ "_source", "price_raw" ] Decode.string <| \price ->
    Field.attemptAt [ "_source", "primaryCheck" ] Decode.string <| \primaryCheck ->
    Field.attemptAt [ "_source", "range_raw" ] Decode.string <| \range ->
    Field.attemptAt [ "_source", "reflex_save" ] Decode.int <| \ref ->
    Field.attemptAt [ "_source", "reload_raw" ] Decode.string <| \reload ->
    Field.attemptAt [ "_source", "required_abilities" ] Decode.string <| \requiredAbilities ->
    Field.attemptAt [ "_source", "requirement" ] Decode.string <| \requirements ->
    Field.attemptAt [ "_source", "resistance_raw" ] (Decode.list Decode.string) <| \resistances ->
    Field.attemptAt [ "_source", "saving_throw" ] Decode.string <| \savingThrow ->
    Field.attemptAt [ "_source", "secondary_casters_raw" ] Decode.string <| \secondaryCasters ->
    Field.attemptAt [ "_source", "secondary_check" ] Decode.string <| \secondaryChecks ->
    Field.attemptAt [ "_source", "skill" ] stringListDecoder <| \skills ->
    Field.attemptAt [ "_source", "source" ] Decode.string <| \source ->
    Field.attemptAt [ "_source", "spell_list" ] Decode.string <| \spellList ->
    Field.attemptAt [ "_source", "spoilers" ] Decode.string <| \spoilers ->
    Field.attemptAt [ "_source", "strength" ] Decode.int <| \strength ->
    Field.attemptAt [ "_source", "target" ] Decode.string <| \targets ->
    Field.attemptAt [ "_source", "tradition" ] (Decode.list Decode.string) <| \traditions ->
    Field.attemptAt [ "_source", "trait_raw" ] (Decode.list Decode.string) <| \maybeTraits ->
    Field.attemptAt [ "_source", "trigger" ] Decode.string <| \trigger ->
    Field.attemptAt [ "_source", "usage" ] Decode.string <| \usage ->
    Field.attemptAt [ "_source", "weakness_raw" ] (Decode.list Decode.string) <| \weaknesses ->
    Field.attemptAt [ "_source", "weapon_category" ] Decode.string <| \weaponCategory ->
    Field.attemptAt [ "_source", "weapon_group" ] Decode.string <| \weaponGroup ->
    Field.attemptAt [ "_source", "will_save" ] Decode.int <| \will ->
    Field.attemptAt [ "_source", "wisdom" ] Decode.int <| \wisdom ->
    Decode.succeed
        { id = id
        , category = category
        , name = name
        , type_ = type_
        , url = url
        , abilities = Maybe.withDefault [] abilities
        , abilityType = abilityType
        , ac = ac
        , actions = actions
        , activate = activate
        , advancedDomainSpell = advancedDomainSpell
        , alignment = alignment
        , ammunition = ammunition
        , area = area
        , aspect = aspect
        , breadcrumbs = Maybe.withDefault [] breadcrumbs
        , bloodlines = Maybe.withDefault [] bloodlines
        , bulk = bulk
        , cast = cast
        , charisma = charisma
        , components = Maybe.withDefault [] components
        , constitution = constitution
        , cost = cost
        , creatureFamily = creatureFamily
        , damage = damage
        , deities = Maybe.withDefault [] deities
        , dexterity = dexterity
        , divineFont = divineFont
        , domains = Maybe.withDefault [] domains
        , domainSpell = domainSpell
        , duration = duration
        , familiarAbilities = Maybe.withDefault [] familiarAbilities
        , favoredWeapon = favoredWeapon
        , feats = Maybe.withDefault [] feats
        , fort = fort
        , frequency = frequency
        , hands = hands
        , heighten = Maybe.withDefault [] heighten
        , hp = hp
        , immunities = Maybe.withDefault [] immunities
        , intelligence = intelligence
        , lessonType = lessonType
        , level = level
        , markdown = Maybe.withDefault text markdown
        , mysteries = Maybe.withDefault [] mysteries
        , patronThemes = Maybe.withDefault [] patronThemes
        , perception = perception
        , prerequisites = prerequisites
        , price = price
        , primaryCheck = primaryCheck
        , range = range
        , ref = ref
        , reload = reload
        , requiredAbilities = requiredAbilities
        , requirements = requirements
        , resistances = Maybe.withDefault [] resistances
        , savingThrow = savingThrow
        , secondaryCasters = secondaryCasters
        , secondaryChecks = secondaryChecks
        , skills = Maybe.withDefault [] skills
        , source = source
        , spellList = spellList
        , spoilers = spoilers
        , strength = strength
        , targets = targets
        , traditions = Maybe.withDefault [] traditions
        , traits = Maybe.withDefault [] maybeTraits
        , trigger = trigger
        , usage = usage
        , weaknesses = Maybe.withDefault [] weaknesses
        , weaponCategory = weaponCategory
        , weaponGroup = weaponGroup
        , will = will
        , wisdom = wisdom
        }


stringListDecoder : Decode.Decoder (List String)
stringListDecoder =
    Decode.oneOf
        [ Decode.list Decode.string
        , Decode.string
            |> Decode.map List.singleton
        ]


getChildDocuments : String -> List String
getChildDocuments markdown =
    case Markdown.Parser.parse markdown of
        Ok blocks ->
            List.foldl
                parseBlock
                []
                blocks

        Err _ ->
            []


parseBlock block list =
    case block of
        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement "document" attributes _) ->
            case List.Extra.find (.name >> (==) "id") attributes of
                Just id ->
                    id.value :: list

                Nothing ->
                    list

        Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement _ _ children) ->
            List.foldl
                parseBlock
                list
                children

        _ ->
            list


view : Model -> Browser.Document Msg
view model =
    { title = "AoN prototype"
    , body =
        [ Html.div
            [ HA.style "padding" "8px"
            , HA.class "column"
            , HA.class "align-center"
            ]
            [ Html.node "style"
                []
                [ Html.text css
                , Html.text cssDark
                ]
            , Html.div
                [ HA.style "max-width" "1000px" ]
                [ viewPage model ]
                -- [ renderMarkdown
                -- ]
            ]
        ]
    }



viewPage : Model -> Html Msg
viewPage model =
    Html.div
        [ HA.class "column"
        , HA.class "align-center"
        ]
        [ viewNavigation model
        , case pageToDataKey model.page of
            Just id ->
                viewDocument model id 0 True

            _ ->
                Html.text ""
        ]


viewNavigation model =
    Html.div
        [ HA.class "column"
        , HA.class "align-center"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "wrap"
            , HA.class "gap-small"
            ]
            (List.map
                (\{ href, label } ->
                    Html.a
                        [ HA.href href ]
                        [ Html.text label ]
                )
                [ { href = "/actions"
                  , label = "Actions/Activities"
                  }
                , { href = "/afflictions"
                  , label = "Afflictions"
                  }
                , { href = "/classes"
                  , label = "Classes"
                  }
                , { href = "/rules"
                  , label = "Rules"
                  }
                , { href = "/traits"
                  , label = "Traits"
                  }
                ]
                |> List.intersperse (Html.text "|")
            )
        , Html.hr [] []
        , case model.page of
            Class _ ->
                viewClassSubnav

            Classes ->
                viewClassSubnav

            ClassFeats _ ->
                viewClassSubnav

            Instinct _ ->
                viewClassSubnav

            Instincts ->
                viewClassSubnav

            SampleBuild _ _ ->
                viewClassSubnav

            SampleBuilds _ ->
                viewClassSubnav

            _ ->
                Html.text ""

        , Html.hr [] []

        , case model.page of
            Class "barbarian" ->
                viewBarbarianSubnav

            ClassFeats "barbarian" ->
                viewBarbarianSubnav

            Instinct _ ->
                viewBarbarianSubnav

            Instincts ->
                viewBarbarianSubnav

            SampleBuilds "barbarian" ->
                viewBarbarianSubnav

            _ ->
                Html.text ""

        , Html.hr [] []
        ]


viewClassSubnav =
    Html.div
        [ HA.class "column"
        , HA.class "gap-medium"
        ]
        [ Html.div
            [ HA.class "row"
            , HA.class "wrap"
            , HA.class "gap-small"
            , HA.class "justify-center"
            ]
            (List.map
                (\c ->
                    Html.a
                        [ HA.href ("/classes/" ++ String.toLower c) ]
                        [ Html.text c ]
                )
                [ "Alchemist"
                , "Barbarian"
                , "Bard"
                , "Champion"
                , "Cleric"
                , "Druid"
                , "Fighter"
                , "Gunslinger"
                , "Inventory"
                , "Investigator"
                , "Magus"
                , "Monk"
                , "Oracle"
                , "Ranger"
                , "Rogue"
                , "Sorcerer"
                , "Summoner"
                , "Swashbuckler"
                , "Witch"
                , "Wizard"
                ]
                |> List.intersperse (Html.text "|")
            )
        ]


viewBarbarianSubnav =
    Html.div
        [ HA.class "row"
        , HA.class "wrap"
        , HA.class "gap-small"
        ]
        (List.map
            (\{ href, label } ->
                Html.a
                    [ HA.href href ]
                    [ Html.text label ]
            )
            [ { href = "/classes/barbarian"
              , label = "Details"
              }
            , { href = "/classes/barbarian/feats"
              , label = "Feats"
              }
            , { href = "/classes/barbarian/kits"
              , label = "Kits"
              }
            , { href = "/classes/barbarian/sample-builds"
              , label = "Sample Builds"
              }
            , { href = "/classes/barbarian/instincts"
              , label = "Instincts"
              }
            ]
            |> List.intersperse (Html.text "|")
        )


viewDocument : Model -> String -> Int -> Bool -> Html Msg
viewDocument model id titleLevel isMain =
    case Dict.get id model.documents of
        Just (Ok document) ->
            Html.div
                [ HA.class "column"
                , HA.class "gap-medium"
                ]
                [ (if titleLevel <= 1 then
                    Html.h1
                        [ HA.class "title" ]

                   else if titleLevel == 2 then
                    Html.h2
                        [ HA.class "subtitle" ]

                   else if titleLevel == 3 then
                    Html.h3
                        [ HA.class "subsubtitle" ]

                   else
                    Html.h4
                        [ HA.class "subsubsubtitle" ]
                  )
                    [ Html.div
                        []
                        [ Html.a
                            [ HA.href (documentToUrl document) ]
                            [ Html.text document.name ]
                        , case ( document.actions, hasActionsInTitle document ) of
                            ( Just actions, True ) ->
                                viewTextWithActionIcons (" " ++ actions)

                            _ ->
                                Html.text ""
                        ]
                    , Html.div
                        []
                        [ Html.text document.type_ ]
                    ]
                , if isMain then
                    Html.div
                        [ HA.class "row"
                        , HA.class "gap-small"
                        ]
                        (List.foldl
                            (\breadcrumb ( prev, html ) ->
                                ( List.append prev [ breadcrumb ]
                                , List.append
                                    html
                                    [ Html.a
                                        [ HA.href
                                            (List.append prev [ breadcrumb ]
                                                |> List.map dasherize
                                                |> String.join "/"
                                                |> (++) "/rules/"
                                            )
                                        ]
                                        [ Html.text breadcrumb ]
                                    ]
                                )
                            )
                            ( [], [] )
                            document.breadcrumbs
                            |> Tuple.second
                            |> List.intersperse (Html.text "/")
                        )

                  else
                    Html.text ""
                , Html.div
                    [ HA.class "row" ]
                    (List.map viewTrait document.traits)
                , renderMarkdown model (titleLevel + 1) document.markdown
                ]

        Just (Err _) ->
            Html.text "err"

        Nothing ->
            Html.div
                [ HA.class "loader" ]
                []


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

            "No Alignment" ->
                HA.class "trait-alignment"

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


hasActionsInTitle : Document -> Bool
hasActionsInTitle document =
    List.member document.category [ "action", "creature-ability", "feat" ]


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



renderMarkdown : Model -> Int -> String -> Html Msg
renderMarkdown model titleLevel markdown =
    case Markdown.Parser.parse markdown of
        Ok blocks ->
            case Markdown.Renderer.render (renderer model titleLevel) blocks of
                Ok v ->
                    Html.div
                        [ HA.class "column"
                        , HA.class "gap-medium"
                        ]
                        v

                Err err ->
                    Html.text err

        Err errors ->
            Html.div
                []
                (List.map
                    (Markdown.Parser.deadEndToString >> Html.text)
                    errors
                )


renderer : Model -> Int ->  Markdown.Renderer.Renderer (Html Msg)
renderer model titleLevel =
    let
        defaultRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defaultRenderer
        | html =
            Markdown.Html.oneOf
                [ Markdown.Html.tag "h2"
                    (\right content ->
                        Html.h2
                            [ HA.class "row"
                            , HA.class "justify-between"
                            ]
                            [ Html.div
                                []
                                content
                            , Html.div
                                [ HA.class "align-right" ]
                                [ Html.text right ]
                            ]
                    )
                    |> Markdown.Html.withAttribute "right"
                , Markdown.Html.tag "row"
                    (\content ->
                        Html.div
                            [ HA.class "row"
                            , HA.class "gap-medium"
                            ]
                            content
                    )
                , Markdown.Html.tag "column"
                    (\content ->
                        Html.div
                            [ HA.class "column"
                            , HA.class "gap-medium"
                            ]
                            content
                    )
                , Markdown.Html.tag "document"
                    (\id _ ->
                        viewDocument model id titleLevel False
                    )
                    |> Markdown.Html.withAttribute "id"
                , Markdown.Html.tag "infobox"
                    (\content ->
                        Html.div
                            [ HA.class "option-container"
                            , HA.class "column"
                            ]
                            content
                    )
                , Markdown.Html.tag "trait"
                    (\content ->
                        Html.div
                            [ HA.class "trait"
                            ]
                            content
                    )
                ]
    }


barbarian : String
barbarian =
    """
<row>
<column>
*Rage consumes you in battle. You delight in wreaking havoc and using powerful weapons to carve through your enemies, relying on astonishing durability without needing complicated techniques or rigid training. Your rages draw upon a vicious instinct, which you might associate with an animal, a spirit, or some part of yourself. To many barbarians, brute force is a hammer and every problem looks like a nail, whereas others try to hold back the storm of emotions inside them and release their rage only when it matters most.*

**Key Ability: STRENGTH**  
At 1st level, your class gives you an ability boost to Strength.

**Hit Points: 12 plus your Constitution modifier**  
You increase your maximum number of HP by this number at 1st level and every level thereafter.
</column>
<column>
![Test](https://via.placeholder.com/200x300/)
</column>
</row>

<infobox>
## Key Terms
You'll see the following key terms in many barbarian class features.

[**Flourish**](/traits/flourish): Flourish actions are techniques that require too much exertion to perform a large number in a row. You can use only 1 action with the flourish trait per turn.

[**Instinct**](/traits/instinct): Instinct abilities require a specific [instinct](/classes/barbarian/instincts); you lose access if you perform acts anathema to your instinct.

[**Open**](/traits/open): These maneuvers work only as your first salvo on your turn. You can use an open action only if you haven't used an action with the attack or open trait yet this turn.

[**Rage**](/traits/rage): You must be [raging](/action/rage) to use abilities with the rage trait, and they end automatically when you stop raging.
</infobox>


# Roleplaying the Barbarian

## During Combat Encounters...
You summon your rage and rush to the front lines to smash your way through. Offense is your best defense—you’ll need to drop foes before they can exploit your relatively low defenses.

## During Social Encounters...
You use intimidation to get what you need, especially when gentler persuasion can’t get the job done.

## While Exploring...
You look out for danger, ready to rush headfirst into battle in an instant. You climb the challenging rock wall and drop a rope for others to follow, and you wade into the risky currents to reach the hidden switch beneath the water’s surface. If something needs breaking, you’re up to the task!

## In Downtime...
You might head to a tavern to carouse, build up the fearsome legend of your mighty deeds, or recruit followers to become a warlord in your own right.

## You Might...
* Have a deep-seated well of anger, hatred, or frustration.
* Prefer a straightforward approach to one requiring patience and tedium.
* Engage in a regimen of intense physical fitness—and punch anyone who says this conflicts with your distaste for patience and tedium.

## Others Probably...
* Rely on your courage and your strength, and trust that you can hold your own in a fight.
* See you as uncivilized or a boorish lout unfit for high society.
* Believe that you are loyal to your friends and allies and will never relent until the fight is done.

# Initial Proficiencies
At 1st level, you gain the listed proficiency ranks in the following statistics. You are untrained in anything not listed unless you gain a better proficiency rank in some other way.

## Perception
Expert in Perception

## Saving Throws
Expert in Fortitude  
Trained in Reflex  
Expert in Will

## Skills
Trained in Athletics  
Trained in a number of additional skills equal to 3 plus your Intelligence modifier

## Attacks
Trained in simple weapons  
Trained in martial weapons  
Trained in unarmed attacks

## Defenses
Trained in light armor  
Trained in medium armor  
Trained in unarmored defense

## Class DC
Trained in barbarian class DC


# Class Features
You gain these features as a Barbarian. Abilities gained at higher levels list the levels at which you gain them next to the features' names.

## Ancestry and Background
In addition to the abilities provided by your class at 1st level, you have the benefits of your selected ancestry and background, as described in Chapter 2.

## Barbarian Feats
At 1st level and every even-numbered level thereafter, you gain a barbarian class feat.

## Initial Proficiencies
At 1st level you gain a number of proficiencies that represent your basic training. These proficiencies are noted in at the start of this class.

## Instinct
Your rage wells up from a dominant instinct—one you learned from a tradition or that comes naturally to you. Your instinct gives you an ability, requires you to avoid certain behaviors, grants you increased damage and resistances at higher levels, and allows you to select feats tied to your instinct.

Instincts can be found here.

## Rage
You gain the Rage action, which lets you fly into a frenzy.

<document id="action-rage" />

<h2 right="Level 2">Skill Feats</h2>
At 2nd level and every 2 levels thereafter, you gain a skill feat. Skill feats appear in Chapter 5 and have the skill trait. You must be trained or better in the corresponding skill to select a skill feat.

<h2 right="Level 3">Deny Advantage</h2>
Your foes struggle to pass your defenses. You aren’t flat-footed to hidden, undetected, or flanking creatures of your level or lower, or creatures of your level or lower using surprise attack. However, they can still help their allies flank.

<h2 right="Level 3">General Feats</h2>
At 3rd level and every 4 levels thereafter, you gain a general feat. General feats are listed in Chapter 5.

<h2 right="Level 3">Skill Increases</h2>
At 3rd level and every 2 levels thereafter, you gain a skill increase. You can use this increase either to increase your proficiency rank to trained in one skill you’re untrained in, or to increase your proficiency rank in one skill in which you’re already trained to expert.

At 7th level, you can use skill increases to increase your proficiency rank to master in a skill in which you’re already an expert, and at 15th level, you can use them to increase your proficiency rank to legendary in a skill in which you’re already a master.

<h2 right="Level 5">Ability Boosts</h2>
At 5th level and every 5 levels thereafter, you boost four different ability scores. You can use these ability boosts to increase your ability scores above 18. Boosting an ability score increases it by 1 if it’s already 18 or above, or by 2 if it starts below 18.

<h2 right="Level 5">Ancestry Feats</h2>
In addition to the ancestry feat you started with, you gain an ancestry feat at 5th level and every 4 levels thereafter. The list of ancestry feats available to you can be found in your ancestry’s entry in Chapter 2.

<h2 right="Level 5">Brutality</h2>
Your fury makes your weapons lethal. Your proficiency ranks for simple weapons, martial weapons, and unarmed attacks increase to expert. While raging, you gain access to the critical specialization effects for melee weapons and unarmed attacks.

<h2 right="Level 7">Juggernaut</h2>
Your body is accustomed to physical hardship and resistant to ailments. Your proficiency rank for Fortitude saves increases to master. When you roll a success on a Fortitude save, you get a critical success instead.

<h2 right="Level 7">Weapon Specialization</h2>
Your rage helps you hit harder. You deal an additional 2 damage with weapons and unarmed attacks in which you have expert proficiency. This damage increases to 3 if you’re a master, and 4 if you’re legendary. You gain your instinct’s specialization ability.

See specific instincts for more information.

<h2 right="Level 9">Lightning Reflexes</h2>
Your reflexes are lightning fast. Your proficiency rank for Reflex saves increases to expert.

<h2 right="Level 9">Raging Resistance</h2>
Repeated exposure and toughened skin allow you to fend off harm. While raging, you gain resistance equal to 3 + your Constitution modifier to damage types based on your instinct.

See specific instincts for more information.

<h2 right="Level 11">Mighty Rage</h2>
Your rage intensifies and lets you burst into action. Your proficiency rank for your barbarian class DC increases to expert. You gain the Mighty Rage free action.

<document id="action-mighty-rage" />

<h2 right="Level 13">Greater Juggernaut</h2>
You have a stalwart physiology. Your proficiency rank for Fortitude saves increases to legendary. When you roll a critical failure on a Fortitude save, you get a failure instead. When you roll a failure on a Fortitude save against an effect that deals damage, you halve the damage you take.

<h2 right="Level 13">Medium Armor Expertise</h2>
You’ve learned to defend yourself better against attacks. Your proficiency ranks for light armor, medium armor, and unarmored defense increase to expert.


<h2 right="Level 13">Weapon Fury</h2>
Your rage makes you even more effective with the weapons you wield. Your proficiency ranks for simple weapons, martial weapons, and unarmed attacks increase to master.

<h2 right="Level 15">Greater Weapon Specialization</h2>
The weapons you’ve mastered become truly fearsome in your hands. Your damage from weapon specialization increases to 4 with weapons and unarmed attacks in which you’re an expert, 6 if you’re a master, and 8 if you’re legendary. You gain a greater benefit from your instinct’s specialization ability.

See specific instincts for more information.

<h2 right="Level 15">Indomitable Will</h2>
Your rage makes it difficult to control you. Your proficiency rank for Will saves increases to master. When you roll a success on a Will save, you get a critical success instead.

<h2 right="Level 17">Heightened Senses</h2>
Your instinct heightens each of your senses further. Your proficiency rank for Perception increases to master.

<h2 right="Level 17">Quick Rage</h2>
You recover from your Rage quickly, and are soon ready to begin anew. After you spend a full turn without raging, you can Rage again without needing to wait 1 minute.

<h2 right="Level 19">Armor of Fury</h2>
Your training and rage deepen your connection to your armor. Your proficiency ranks for light armor, medium armor, and unarmored defense increase to master.

<h2 right="Level 19">Devastator</h2>
Your Strikes are so devastating that you hardly care about resistance, and your barbarian abilities are unparalleled. Your proficiency rank for your barbarian class DC increases to master. Your melee Strikes ignore 10 points of a creature’s resistance to their physical damage.
    """


rage : String
rage =
    """
You tap into your inner fury and begin raging. You gain a number of temporary Hit Points equal to your level plus your Constitution modifier. This frenzy lasts for 1 minute, until there are no enemies you can perceive, or until you fall unconscious, whichever comes first. You can't voluntarily stop raging. While you are raging:

* You deal 2 additional damage with melee Strikes. This additional damage is halved if your weapon or unarmed attack is agile.
* You take a –1 penalty to AC.

You can't use actions with the concentrate trait unless they also have the rage trait. You can [Seek](/Actions.aspx?ID=84) while raging.

After you stop raging, you lose any remaining temporary Hit Points from Rage, and you can't Rage again for 1 minute.
    """


css : String
css =
    """
    @font-face {
        font-family: "Pathfinder-Icons";
        src: url("/Pathfinder-Icons.ttf");
        font-display: swap;
    }

    :root, :host {
        --gap-tiny: 4px;
        --gap-small: 8px;
        --gap-medium: 12px;
        --gap-large: 20px;
        --font-normal: 16px;
        --font-large: 20px;
        --font-very-large: 24px;
    }

    body {
        background-color: var(--color-bg);
        color: var(--color-text);
        font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif;
        margin: 0px;
    }

    a {
        color: inherit;
    }

    a:hover, button:hover {
        text-decoration: underline;
    }

    button {
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

    button.excluded {
        color: var(--color-inactive-text);
    }

    h1 {
        font-size: 48px;
        font-weight: normal;
        margin: 0;
    }

    h2 {
        font-size: var(--font-large);
        margin: 0;
    }

    h3 {
        font-size: var(--font-large);
        margin: 0;
    }

    h4 {
        margin: 0;
    }

    hr {
        width: 100%;
    }

    input[type=text] {
        background-color: var(--color-bg);
        border-style: solid;
        border-radius: 4px;
        color: var(--color-text);
        padding: 4px;
        width: 100%;
    }

    p {
        margin: 0;
    }

    ul {
        margin: 0;
    }

    select {
        font-size: var(--font-normal);
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

    .align-right {
        text-align: right;
    }

    .body-container {
        align-items: center;
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

    .content-container {
        box-sizing: border-box;
        max-width: 1000px;
        padding: 8px;
        width: 100%;
    }

    .row {
        display: flex;
        flex-direction: row;
    }

    .wrap {
        flex-wrap: wrap;
    }

    .column:empty, .row:empty {
        display: none;
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

    .gap-small {
        gap: var(--gap-small);
    }

    .gap-tiny {
        gap: var(--gap-tiny);
    }

    .icon-font {
        color: var(--color-icon);
        font-family: "Pathfinder-Icons";
        font-variant-caps: normal;
        font-weight: normal;
    }

    .input-button {
        aspect-ratio: 1 / 1;
        background-color: transparent;
        border-width: 0;
        color: var(--color-text);
        height: 100%;
        right: 0px;
        position: absolute;
    }

    .justify-between {
        justify-content: space-between;
    }

    .justify-center {
        justify-content: center;
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
        gap: var(--gap-small);
        padding: 8px;
    }

    .query-input {
        font-size: var(--font-very-large);
    }

    .query-options-container {
        transition: height ease-in-out 0.2s;
        overflow: hidden;
    }

    .query-options-dummy {
        opacity: 0;
        pointer-events: none;
        position: absolute;
        visibility: hidden;
    }

    .scrollbox {
        background-color: var(--color-bg-secondary);
        border-color: #767676;
        border-radius: 4px;
        border-style: solid;
        border-width: 1px;
        max-height: 150px;
        overflow-y: auto;
        padding: 4px;
    }

    .subtitle, h2 {
        border-radius: 4px;
        background-color: var(--color-subelement-bg);
        color: var(--color-subelement-text);
        font-variant: small-caps;
        line-height: 1rem;
        padding: 4px 9px;
        display: flex;
        flex-direction: row;
        justify-content: space-between;
    }

    .subsubtitle, h3 {
        border-radius: 4px;
        background-color: #627d62;
        color: var(--color-subelement-text);
        font-variant: small-caps;
        line-height: 1rem;
        padding: 4px 9px;
        display: flex;
        flex-direction: row;
        justify-content: space-between;
    }

    .subsubsubtitle, h4 {
        border-radius: 4px;
        background-color: #494e70;
        color: var(--color-subelement-text);
        font-variant: small-caps;
        line-height: 1rem;
        padding: 4px 9px;
        display: flex;
        flex-direction: row;
        justify-content: space-between;
    }

    .option-container h2 {
        background-color: inherit;
        color: inherit;
        padding: 0;
    }

    .subtitle:empty {
        display: none;
    }

    .title, h1 {
        border-radius: 4px;
        background-color: var(--color-element-bg);
        border-color: var(--color-container-border);
        color: var(--color-element-text);
        display: flex;
        flex-direction: row;
        font-size: var(--font-very-large);
        font-variant: small-caps;
        font-weight: 700;
        gap: var(--gap-small);
        justify-content: space-between;
        padding: 4px 9px;
    }

    .title .icon-font {
        color: var(--color-element-icon);
    }

    .title a {
        text-decoration: none;
    }

    .title a:hover {
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
        font-variant: small-caps;
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


cssDark : String
cssDark =
    """
    :root, :host {
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
        --color-subelement-bg: #806e45;
        --color-subelement-text: #111111;
        --color-icon: #cccccc;
        --color-inactive-text: #999999;
        --color-text: #eeeeee;
    }
    """
