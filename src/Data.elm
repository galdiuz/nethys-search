module Data exposing (..)

import String.Extra


attributes : List String
attributes =
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


damageTypes : List String
damageTypes =
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
    [ 20, 50, 100, 250, 1000 ]


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


sizes : List String
sizes =
    [ "tiny"
    , "small"
    , "medium"
    , "large"
    , "huge"
    , "gargantuan"
    ]


skills : List String
skills =
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
                damageTypes
            )
        |> List.append
            (List.map
                (\type_ ->
                    ( "weakness." ++ type_
                    , "weakness." ++ type_
                    , True
                    )
                )
                damageTypes
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


traditions : List String
traditions =
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
