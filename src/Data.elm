module Data exposing (..)

import String.Extra


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
    , "splash"
    ]


fields : List ( String, String )
fields =
    [ ( "ability", "Ability related to a deity or skill" )
    , ( "ability_boost", "Ancestry ability boost" )
    , ( "ability_flaw", "Ancestry ability flaw" )
    , ( "ability_type", "Familiar ability type (Familiar / Master)" )
    , ( "ac", "[n] Armor class of an armor, creature, or shield" )
    , ( "actions", "Actions required to use an action, feat, or creature ability" )
    , ( "activate", "Activation requirements of an item" )
    , ( "advanced_domain_spell", "Advanced domain spell" )
    , ( "alignment", "Alignment" )
    , ( "ammunition", "Ammunition type used by a weapon" )
    , ( "archetype", "Archetypes associated with a feat" )
    , ( "area", "Area of a spell" )
    , ( "armor_group", "Armor group" )
    , ( "aspect", "Relic gift aspect type" )
    , ( "bloodline", "Sorcerer bloodlines associated with a spell" )
    , ( "bloodline_spell", "Sorcerer bloodline's spells" )
    , ( "bulk", "Item bulk ('L' is 0.1)" )
    , ( "cast", "Actions or time required to cast a spell or ritual" )
    , ( "cha", "[n] Alias for 'charisma'" )
    , ( "charisma", "[n] Charisma" )
    , ( "check_penalty", "[n] Armor check penalty" )
    , ( "cleric_spell", "Cleric spells granted by a deity" )
    , ( "complexity", "Hazard complexity" )
    , ( "component", "Spell casting components (Material / Somatic / Verbal)" )
    , ( "con", "[n] Alias for 'constitution'" )
    , ( "constitution", "[n] Constitution" )
    , ( "cost", "Cost to use an action or cast a ritual" )
    , ( "creature_family", "Creature family" )
    , ( "damage", "Weapon damage" )
    , ( "deed", "Gunslinger way deeds" )
    , ( "deity", "Deities associated with a domain, spell, or weapon" )
    , ( "dex", "[n] Alias for 'dexterity'" )
    , ( "dex_cap", "[n] Armor dex cap" )
    , ( "dexterity", "Dexterity" )
    , ( "disable", "Hazard disable requirements" )
    , ( "divine_font", "Deity's divine font" )
    , ( "divinity", "Plane divinities" )
    , ( "domain_spell", "Domain spell" )
    , ( "domain", "Domains related to deity or spell" )
    , ( "duration", "Duration of spell or poison" )
    , ( "familiar_ability", "Abilities granted by specific familiars" )
    , ( "favored_weapon", "Deity's favored weapon" )
    , ( "feat", "Related feat" )
    , ( "follower_alignment", "Deity's follower alignments" )
    , ( "fort", "[n] Alias for 'fortitude_save'" )
    , ( "fortitude", "[n] Alias for 'fortitude_save'" )
    , ( "fortitude_save", "[n] Fortitude save" )
    , ( "frequency", "Frequency of which something can be used" )
    , ( "granted_spell", "Spells granted by a sorcerer bloodline or witch patron theme" )
    , ( "hands", "Hands required to use item" )
    , ( "hardness", "[n] Hazard or shield hardness" )
    , ( "heighten", "Spell heightens available" )
    , ( "hex_cantrip", "Witch patron theme hex cantrip" )
    , ( "home_plane", "Summoner eidolon home plane" )
    , ( "hp", "[n] Hit points" )
    , ( "immunity", "Immunities" )
    , ( "int", "[n] Alias for 'intelligence'" )
    , ( "intelligence", "[n] Intelligence" )
    , ( "item", "Items carried by a creature" )
    , ( "item_category", "Category of an item" )
    , ( "item_subcategory", "Subcategory of an item" )
    , ( "language", "Languages spoken" )
    , ( "lesson_type", "Witch lesson type" )
    , ( "level", "[n] Level" )
    , ( "mystery", "Oracle mysteries associated with a spell" )
    , ( "name", "Name" )
    , ( "onset", "Onset of a disease or poison" )
    , ( "patron_theme", "Witch patron themes associated with a spell" )
    , ( "per", "[n] Alias for 'perception'" )
    , ( "perception", "[n] Perception" )
    , ( "pfs", "Pathfinder Society status (Standard / Limited / Restricted)" )
    , ( "plane_category", "Plane category" )
    , ( "prerequisite", "Prerequisites" )
    , ( "price", "[n] Item price in copper coins" )
    , ( "primary_check", "Primary check of a ritual" )
    , ( "range", "[n] Range of spell or weapon in feet" )
    , ( "ref", "[n] Alias for 'reflex_save'" )
    , ( "reflex", "[n] Alias for 'reflex_save'" )
    , ( "reflex_save", "[n] Reflex save" )
    , ( "region", "Background region" )
    , ( "reload", "[n] Weapon reload" )
    , ( "required_abilities", "[n] Number of required familiar abilities for a specific familiar" )
    , ( "requirement", "Requirements" )
    , ( "resistance.<type>", "[n] Resistance to <type>. See list of valid types below. Use resistance.\\* to match any type." )
    , ( "resistance_raw", "Resistances exactly as written" )
    , ( "saving_throw", "Saving throw for a disease, poison, or spell (Fortitude / Reflex / Will)" )
    , ( "secondary_casters", "[n] Secondary casters for a ritual" )
    , ( "secondary_check", "Secondary checks for a ritual" )
    , ( "sense", "Senses" )
    , ( "size", "Size" )
    , ( "skill", "Related skills" )
    , ( "slingers_reload", "Gunslinger way's slinger's reload" )
    , ( "source", "Source book name" )
    , ( "source_raw", "Source book exactly as written incl. page" )
    , ( "source_category", "Source book category" )
    , ( "speed.<type>", "[n] Speed of <type>. Valid types are burrow, climb, fly, land, and swim. Use speed.\\* to match any type." )
    , ( "speed_raw", "Speed exactly as written" )
    , ( "speed_penalty", "Speed penalty of armor or shield" )
    , ( "spell_list", "Spell list of a Sorcerer bloodline or witch patron theme" )
    , ( "spoilers", "Adventure path name if there is a spoiler warning on the page" )
    , ( "stage", "Stages of a disease or poison" )
    , ( "stealth", "Hazard stealth" )
    , ( "str", "[n] Alias for 'strength'" )
    , ( "strength", "[n] Creature strength or armor strength requirement" )
    , ( "strongest_save", "The strongest save(s) of a creature ( Fortitude / Reflex / Will )" )
    , ( "target", "Spell targets" )
    , ( "text", "All text on a page" )
    , ( "tradition", "Traditions of spell or summoner eidolon" )
    , ( "trait", "Traits with values removed, e.g. 'Deadly d6' is normalized as 'Deadly'" )
    , ( "trait_raw", "Traits exactly as written" )
    , ( "trigger", "Trigger" )
    , ( "type", "Type" )
    , ( "usage", "Usage of curse or item" )
    , ( "weakest_save", "The weakest save(s) of a creature (Fortitude / Reflex / Will)" )
    , ( "weakness.<type>", "[n] Weakness to <type>. See list of valid types below. Use weakness.\\* to match any type." )
    , ( "weakness_raw", "Weaknesses exactly as written" )
    , ( "weapon_category", "Weapon category (Simple / Martial / Advanced / Ammunition)" )
    , ( "weapon_group", "Weapon group" )
    , ( "will", "[n] Alias for 'will_save'" )
    , ( "will_save", "[n] Will save" )
    , ( "wis", "[n] Alias for 'wisdom'" )
    , ( "wisdom", "[n] Wisdom" )
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


sortFields : List ( String, String )
sortFields =
    [ ( "ac", "AC" )
    , ( "bulk", "Bulk" )
    , ( "charisma", "Charisma" )
    , ( "constitution", "Constitution" )
    , ( "dexterity", "Dexterity" )
    , ( "fortitude_save", "Fortitude" )
    , ( "hp", "HP" )
    , ( "intelligence", "Intelligence" )
    , ( "level", "Level" )
    , ( "name.keyword", "Name" )
    , ( "perception", "Perception" )
    , ( "price", "Price" )
    , ( "range", "Range" )
    , ( "reflex_save", "Reflex" )
    , ( "strength", "Strength" )
    , ( "type", "Type" )
    , ( "will_save", "Will" )
    , ( "wisdom", "Wisdom" )
    ]
        |> List.append
            (List.map
                (\type_ ->
                    ( "resistance." ++ type_
                    , (String.Extra.humanize type_) ++ " resistance"
                    )
                )
                damageTypes
            )
        |> List.append
            (List.map
                (\type_ ->
                    ( "weakness." ++ type_
                    , (String.Extra.humanize type_) ++ " weakness"
                    )
                )
                damageTypes
            )
        |> List.append
            (List.map
                (\speed ->
                    ( "speed." ++ speed
                    , (String.Extra.humanize speed) ++ " speed"
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
