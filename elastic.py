#!/usr/bin/env python3
from bs4 import BeautifulSoup
from elasticsearch_dsl import Document, Field, Float, Integer, Keyword, Object, Text
from elasticsearch_dsl.connections import connections
import re
import os


def main():
    connections.create_connection(hosts=['localhost'])
    Doc.init()

    for dir_name in sorted(os.listdir('data')):
        for file_name in sorted(os.listdir(f'data/{dir_name}/')):
            file_path = f'data/{dir_name}/{file_name}'

            if os.path.getsize(file_path) == 0:
                continue

            id = file_name.replace('.html', '')

            print(file_path)

            with open(file_path, 'r') as fp:
                soup = BeautifulSoup(fp, 'html5lib')

            parse_functions = {
                'actions': parse_action,
                'ancestries': parse_ancestry,
                'animal-companions': parse_animal_companion,
                'animal-companions-advanced': parse_animal_companion_advanced,
                'animal-companions-specialized': parse_animal_companion_specialized,
                'animal-companions-unique': parse_animal_companion_unique,
                'arcane-schools': parse_arcane_school,
                'archetypes': parse_archetype,
                'armor': parse_armor,
                'armor-groups': parse_armor_group,
                'articles': parse_article,
                'backgrounds': parse_background,
                'bloodlines': parse_bloodline,
                'causes': parse_cause,
                'class-kits': parse_class_kit,
                'class-samples': parse_class_sample,
                'classes': parse_class,
                'conditions': parse_condition,
                'curses': parse_curse,
                'deities': parse_deity,
                'deity-categories': parse_deity_category,
                'diseases': parse_disease,
                'doctrines': parse_doctrine,
                'domains': parse_domain,
                'druidic-orders': parse_druidic_order,
                'eidolons': parse_eidolon,
                'equipment': parse_equipment,
                'familiars': parse_familiar,
                'familiars-specific': parse_familiar_specific,
                'feats': parse_feat,
                'hazards': parse_hazard,
                'heritages': parse_heritage,
                'hunters-edge': parse_hunters_edge,
                'hybrid-studies': parse_hybrid_study,
                'innovations': parse_innovation,
                'instincts': parse_instinct,
                'languages': parse_language,
                'lessons': parse_lesson,
                'methodologies': parse_methodology,
                'monster-abilities': parse_monster_ability,
                'monster-families': parse_monster_family,
                'monsters': parse_monster,
                'muses': parse_muse,
                'mysteries': parse_mystery,
                'npc-theme-templates': parse_npc_theme_template,
                'npcs': parse_npc,
                'patrons': parse_patron,
                'planes': parse_plane,
                'rackets': parse_racket,
                'relics': parse_relic,
                'research-fields': parse_research_field,
                'rituals': parse_ritual,
                'rules': parse_rules,
                'shields': parse_shield,
                'siege-weapons': parse_siege_weapon,
                'skills': parse_skill,
                'sources': parse_source,
                'spells': parse_spell,
                'styles': parse_style,
                'tenets': parse_tenet,
                'traits': parse_trait,
                'vehicles': parse_vehicle,
                'ways': parse_way,
                'weapon-groups': parse_weapon_group,
                'weapons': parse_weapon,
            }

            if dir_name in parse_functions:
                parse_functions[dir_name](id, soup)


def build_url(category: str, id: int, params: [str] = []) -> str:
    return f'{category}.aspx?' + '&'.join([f"ID={id}"] + params)


def parse_generic(id: str, soup: BeautifulSoup, category: str, url: str, type: str, url_params: [str] = []):
    title = soup.find('h1', class_='title')

    name, title_type, level, pfs = get_title_data(title)
    sources = get_label_links(soup, 'Source')

    doc = Doc()
    doc.meta.id = category + '-' + id
    doc.id = id
    doc.url = build_url(url, id, url_params)
    doc.category = category
    doc.name = name.strip()
    doc.type = title_type or type
    doc.pfs = pfs
    doc.text = title.parent.get_text(' ', strip=True)
    doc.source = [ normalize_source(source) for source in sources ]
    doc.source_raw = sources
    doc.spoilers = get_spoilers(soup)
    doc.level = level

    return doc


def parse_action(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    if not title:
        return

    doc = parse_generic(id, soup, 'action', 'Actions', 'Action')
    traits = get_traits(soup)

    doc.type = 'Action'

    doc.actions = get_actions_from_title(title)
    doc.cost = get_label_text(soup, 'Cost')
    doc.frequency = get_label_text(soup, 'Frequency')
    doc.requirement = get_label_text(soup, 'Requirements')
    doc.school = get_school(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_ancestry(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'ancestry', 'Ancestries', 'Ancestry')
    traits = get_traits(soup)
    hp = get_values_under_title(soup, 'Hit Points')
    size = get_values_under_title(soup, 'Size')
    speed = get_values_under_title(soup, 'Speed')
    languages = get_values_under_title(soup, 'Languages')
    ability_boosts = get_values_under_title(soup, 'Ability Boosts')

    if ability_boosts == ['Two free ability boosts']:
        ability_boosts = ['Free', 'Free']

    cleaned_languages = []
    for language in languages:
        if language.startswith('Additional'):
            break

        cleaned_languages.append(language)

    doc.name = soup.find('h1', class_='title').text
    doc.type = 'Ancestry'
    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.ability_boost = ability_boosts
    doc.ability_flaw = get_values_under_title(soup, 'Ability Flaw(s)')
    doc.hp = hp[0] if hp else None
    doc.language = cleaned_languages
    doc.size = size[0].split(' or ') if size else None
    doc.speed = [ normalize_speed(s) for s in speed ] if speed else None
    doc.speed_raw = ', '.join(speed) if speed else None

    if soup.find('a', text='Darkvision'):
        doc.vision = 'Darkvision'

    elif soup.find('a', text='Low-light vision'):
        doc.vision = 'Low-light vision'

    doc.save()


def parse_animal_companion(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'animal-companion', 'AnimalCompanions', 'Animal Companion')
    traits = get_traits(soup)

    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_animal_companion_advanced(id: str, soup: BeautifulSoup):
    doc = parse_generic(
        id,
        soup,
        'animal-companion-advanced',
        'AnimalCompanions',
        'Animal Companion Advanced Option',
        ['Advanced=true'],
    )
    traits = get_traits(soup)

    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_animal_companion_specialized(id: str, soup: BeautifulSoup):
    doc = parse_generic(
        id,
        soup,
        'animal-companion-specialized',
        'AnimalCompanions',
        'Animal Companion Specialization',
        ['Specialized=true'],
    )

    doc.save()


def parse_animal_companion_unique(id: str, soup: BeautifulSoup):
    doc = parse_generic(
        id,
        soup,
        'animal-companion-unique',
        'AnimalCompanions',
        'Unique Animal Companion',
        ['Unique=true'],
    )
    traits = get_traits(soup)

    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_archetype(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'archetype', 'Archetypes', 'Archetype')

    doc.save()


def parse_arcane_school(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'arcane-school', 'ArcaneSchools', 'Wizard Arcane School')

    doc.save()


def parse_arcane_thesis(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'arcane-thesis', 'ArcaneThesis', 'Wizard Arcane Thesis')

    doc.save()


def parse_armor(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'armor', 'Armor', 'Armor')

    price = get_label_text(soup, 'Price')
    traits = split_comma(get_label_text(soup, 'Traits', '—'))
    ac = get_label_text(soup, 'AC Bonus')
    bulk = get_label_text(soup, 'Bulk', ';—')

    if int(ac) == 0:
        category = 'Unarmored'

    elif int(ac) <= 2:
        category = 'Light'

    elif int(ac) <= 4:
        category = 'Medium'

    else:
        category = 'Heavy'

    doc.type = 'Armor'
    doc.ac = ac
    doc.armor_category = category
    doc.armor_group = get_label_text(soup, 'Group', ';—')
    doc.bulk = normalize_bulk(bulk)
    doc.bulk_raw = bulk
    doc.check_penalty = get_label_text(soup, 'Check Penalty', ';—')
    doc.dex_cap = get_label_text(soup, 'Dex Cap', ';—')
    doc.item_category = 'Armor'
    doc.item_subcategory = 'Base Armor'
    doc.price = normalize_price(price)
    doc.price_raw = price
    doc.rarity = get_rarity(traits)
    doc.speed_penalty = get_label_text(soup, 'Speed Penalty', ';—')
    doc.strength = get_label_text(soup, 'Strength', ';—')
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_armor_group(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'armor-group', 'ArmorGroups', 'Armor Specialization')

    doc.armor_group = doc.name

    doc.save()


def parse_article(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'article', 'Articles', 'Setting Article')

    doc.save()


def parse_background(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'background', 'Backgrounds', 'Background')
    traits = get_traits(soup)

    abilities = []
    for ability in ['Strength', 'Dexterity', 'Constitution', 'Intelligence', 'Wisdom', 'Charisma']:
        if soup.find('b', text=ability):
            abilities.append(ability)

    feats = []
    for node in soup.find_all('a', href=re.compile('Feats')):
        feats.append(node.text)

    skills = []
    for node in soup.find_all('a', href=re.compile('Skills')):
        skills.append(node.text)

    doc.ability_boost = abilities
    doc.feat = feats
    doc.rarity = get_rarity(traits)
    doc.region = get_label_text(soup, 'Region')
    doc.skill = skills
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_bloodline(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'bloodline', 'Bloodlines', 'Sorcerer Bloodline')

    doc.blood_magic = split_comma(get_label_text(soup, 'Blood Magic'))
    doc.bloodline_spell = split_comma(get_label_text(soup, 'Bloodline Spells'))
    doc.granted_spell = split_comma(get_label_text(soup, 'Granted Spells'))
    doc.skill = split_comma(get_label_text(soup, 'Bloodline Skills'))
    doc.spell_list = get_label_text(soup, 'Spell List')

    doc.save()


def parse_cause(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'cause', 'Causes', 'Champion Cause')

    title = soup.find('h1', class_='title')
    alignment = ''.join([word[0] for word in title.text.split('[')[1].strip(']').split()])

    doc.name = title.text.split('[')[0].strip()
    doc.alignment = alignment
    doc.trait = normalize_traits([alignment])
    doc.trait_raw = [alignment]

    doc.save()


def parse_class(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'class', 'Classes', 'Class')

    traits = get_traits(soup)
    attacks = get_values_under_title(soup, 'Attacks')
    defenses = get_values_under_title(soup, 'Defenses')
    perception = get_values_under_title(soup, 'Perception')
    saving_throws = get_values_under_title(soup, 'Saving Throws')
    skills = get_values_under_title(soup, 'Skills')

    node = soup.find('b', string=re.compile(r'Hit Points: .*'))
    hp = ''.join([ c for c in node.text if c.isdigit() ])

    node = soup.find('b', string=re.compile(r'Key Ability: .*'))
    ability = node.text.replace('Key Ability: ', '').split(' OR ')
    ability = [ s.title() for s in ability ]

    doc.ability = ability
    doc.attack_proficiency = attacks
    doc.defense_proficiency = defenses
    doc.hp = hp
    doc.perception_proficiency = perception[0] if perception else None
    doc.rarity = get_rarity(traits)
    doc.saving_throw_proficiency = saving_throws
    doc.skill_proficiency = skills
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_class_kit(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'class-kit', 'ClassKits', 'Class Kit')

    doc.save()


def parse_class_sample(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'class-sample', 'ClassSamples', 'Class Sample')

    doc.save()


def parse_condition(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'condition', 'Conditions', 'Condition')

    doc.save()


def parse_curse(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'curse', 'Curses', 'Curse')
    traits = get_traits(soup)

    doc.effect = get_label_text(soup, 'Effect')
    doc.rarity = get_rarity(traits)
    doc.saving_throw = get_label_text(soup, 'Saving Throw')
    doc.school = get_school(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits
    doc.usage = get_label_text(soup, 'Usage')

    doc.save()


def parse_deity(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'deity', 'Deities', 'Deity')

    title = soup.find('h1', class_='title')

    doc.name = title.text.split('[')[0].strip()
    alignment = title.text.split('[')[1].strip(']')

    doc.ability = split_on(get_label_text(soup, 'Divine Ability'), ' or ')
    doc.alignment = alignment
    doc.anathema = get_label_text(soup, 'Anathema')
    doc.area_of_concern = get_label_text(soup, 'Areas of Concern')
    doc.cleric_spell = get_label_text(soup, 'Cleric Spells')
    doc.deity_category = get_label_text(soup, 'Category')
    doc.divine_font = split_on(get_label_text(soup, 'Divine Font'), ' or ')
    doc.skill = split_on(get_label_text(soup, 'Divine Skill'), ' or ')
    doc.domain = split_comma(get_label_text(soup, 'Domains')) + split_comma(get_label_text(soup, 'Alternate Domains'))
    doc.edict = get_label_text(soup, 'Edicts')
    doc.favored_weapon = split_on(get_label_text(soup, 'Favored Weapon'), ' or ')
    doc.follower_alignment = split_comma(get_label_text(soup, 'Follower Alignments'))
    doc.trait = normalize_traits([alignment])
    doc.trait_raw = [alignment]

    doc.save()


def parse_deity_category(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'deity-category', 'DeityCategories', 'Deity Category')

    doc.deity_category = doc.name

    doc.save()


def parse_disease(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'disease', 'Diseases', 'Disease')
    onset = get_label_text(soup, 'Onset')
    traits = get_traits(soup)

    doc.saving_throw = get_label_text(soup, 'Saving Throw')
    doc.onset = normalize_time(onset)
    doc.onset_raw = onset
    doc.rarity = get_rarity(traits)
    doc.stage = get_stages(soup)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_doctrine(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'doctrine', 'Doctrines', 'Cleric Doctrine')

    doc.save()


def parse_domain(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'domain', 'Domains', 'Domain')

    doc.advanced_domain_spell = get_label_text(soup, 'Advanced Domain Spell')
    doc.deity = split_comma(get_label_text(soup, 'Deities'))
    doc.domain_spell = get_label_text(soup, 'Domain Spell')

    doc.save()


def parse_druidic_order(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'druidic-order', 'DruidicOrders', 'Druidic Order')

    doc.save()


def parse_eidolon(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'eidolon', 'Eidolons', 'Summoner Eidolon')
    traits = get_traits(soup)
    speed = get_label_text(soup, 'Speed')

    doc.home_plane = get_label_text(soup, 'Home Plane')
    doc.language = get_label_text(soup, 'Languages')
    doc.sense = get_label_text(soup, 'Senses')
    doc.size = get_label_text(soup, 'Size')
    doc.skill = split_comma(get_label_text(soup, 'Skills'))
    doc.speed = normalize_speed(speed)
    doc.speed_raw = speed
    doc.tradition = get_label_text(soup, 'Tradition')
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_equipment(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type, level, pfs = get_title_data(title)
    has_sub_items = level[-1] == '+'
    item_category = get_category(soup.find(id='ctl00_RadDrawer1_Content_MainContent_Navigation'))
    item_subcategory = get_category(soup.find(id='ctl00_RadDrawer1_Content_MainContent_SubNavigation'))

    if has_sub_items:
        for idx, sub_title in enumerate(soup.find_all('h2', class_='title')):
            if len(list(sub_title.strings)) != 2:
                continue

            doc = parse_generic(id, soup, 'equipment', 'Equipment', 'Equipment')

            name, type, level, pfs = get_title_data(sub_title)
            bulk = get_label_text(sub_title, 'Bulk') or get_label_text(title, 'Bulk', ';(—')
            price = get_label_text(sub_title, 'Price')
            traits = get_traits(sub_title) or get_traits(soup)

            doc.meta.id = 'equipment-' + id + '-' + str(idx)
            doc.name = name
            doc.type = type
            doc.level = level

            doc.activate = get_actions(soup, 'Activate')
            doc.bulk = normalize_bulk(bulk)
            doc.bulk_raw = bulk
            doc.effect = get_label_text(soup, 'Effect')
            doc.frequency = get_label_text(soup, 'Frequency')
            doc.hands = get_label_text(sub_title, 'Hands')
            doc.item_category = item_category
            doc.item_subcategory = item_subcategory
            doc.price = normalize_price(price)
            doc.price_raw = price
            doc.rarity = get_rarity(traits)
            doc.school = get_school(traits)
            doc.trait = normalize_traits(traits)
            doc.trait_raw = traits
            doc.trigger = get_label_text(soup, 'Trigger')
            doc.usage = get_label_text(soup, 'Usage')

            doc.save()

    else:
        doc = parse_generic(id, soup, 'equipment', 'Equipment', 'Equipment')
        bulk = get_label_text(title, 'Bulk', ';(—')
        duration = get_label_text(soup, 'Maximum Duration')
        onset = get_label_text(soup, 'Onset')
        price = get_label_text(title, 'Price')
        traits = get_traits(soup)

        doc.bulk = normalize_bulk(bulk)
        doc.bulk_raw = bulk
        doc.duration = normalize_time(duration)
        doc.duration_raw = duration
        doc.hands = get_label_text(title, 'Hands')
        doc.item_category = item_category
        doc.item_subcategory = item_subcategory
        doc.onset = normalize_time(onset)
        doc.onset_raw = onset
        doc.price = normalize_price(price)
        doc.price_raw = price
        doc.rarity = get_rarity(traits)
        doc.saving_throw = get_label_text(soup, 'Saving Throw')
        doc.stage = get_stages(soup)
        doc.school = get_school(traits)
        doc.trait = normalize_traits(traits)
        doc.trait_raw = traits
        doc.usage = get_label_text(soup, 'Usage')

        doc.save()


def parse_familiar(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'familiar', 'Familiars', 'Familiar Ability')

    doc.ability_type = get_label_text(soup, 'Ability Type')

    doc.save()


def parse_familiar_specific(id: str, soup: BeautifulSoup):
    doc = parse_generic(
        id,
        soup,
        'familiar-specific',
        'Familiars',
        'Specific Familiar',
        ['Specific=true']
    )
    traits = get_traits(soup)

    doc.familiar_ability = split_comma(get_label_text(soup, 'Granted Abilities'))
    doc.rarity = get_rarity(traits)
    doc.required_abilities = get_label_text(soup, 'Required Number of Abilities')
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_feat(id: str, soup):
    doc = parse_generic(id, soup, 'feat', 'Feats', 'Feat')

    title = soup.find('h1', class_='title')
    traits = get_traits(soup)
    archetype = get_label_text(soup, 'Archetype')

    doc.actions = get_actions_from_title(title)
    doc.archetype = archetype.strip(' *') if archetype else None
    doc.frequency = get_label_text(soup, 'Frequency')
    doc.prerequisite = get_label_text(soup, 'Prerequisites', '')
    doc.rarity = get_rarity(traits)
    doc.requirement = get_label_text(soup, 'Requirements')
    doc.school = get_school(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_hazard(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'hazard', 'Hazards', 'Hazard')

    doc.ac = get_label_text(soup, 'AC', ';,')
    doc.complexity = get_label_text(soup, 'Complexity')
    doc.disable = get_label_text(soup, 'Disable', '')
    doc.fortitude_save = get_label_text(soup, 'Fort', ';,')
    doc.hardness = get_label_text(soup, 'Hardness', ';,')
    doc.hp = get_label_text(soup, 'HP', ';(')
    doc.immunity = split_comma(get_label_text(soup, 'Immunities'))
    doc.reflex_save = get_label_text(soup, 'Ref', ';,')
    doc.reset = get_label_text(soup, 'Reset')
    doc.stealth = get_label_text(soup, 'Stealth')
    doc.will_save = get_label_text(soup, 'Will')

    doc.save()


def parse_heritage(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'heritage', 'Heritages', 'Heritage')
    traits = get_traits(soup)

    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_hunters_edge(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'hunters-edge', 'HuntersEdge', "Hunter's Edge")

    doc.save()


def parse_hybrid_study(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'hybrid-study', 'HybridStudies', 'Magus Hybrid Study')

    doc.save()


def parse_innovation(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'innovation', 'Innovations', 'Inventor Innovation')

    doc.save()


def parse_instinct(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'instinct', 'Instincts', 'Barbarian Instinct')

    doc.save()


def parse_language(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'language', 'Languages', 'Language')

    doc.save()


def parse_lesson(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'lesson', 'Lessons', 'Witch Lesson')
    traits = get_traits(soup)

    doc.lesson_type = get_label_text(soup, 'Lesson Type')
    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_methodology(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'methodology', 'Methodologies', 'Investigator Methodology')

    doc.save()


def parse_monster_ability(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'creature-ability', 'MonsterAbilities', 'Creature Ability')

    title = soup.find('h1', class_='title')

    if title.img:
        doc.actions = title.img['alt']
    doc.requirement = get_label_text(soup, 'Requirements')
    doc.effect = get_label_text(soup, 'Effect')
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_monster_family(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'creature-family', 'MonsterFamilies', 'Creature Family')

    doc.creature_family = doc.name

    doc.save()


def parse_monster(id: str, soup: BeautifulSoup):
    parse_creature(id, soup, 'Monsters')


def parse_muse(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'muse', 'Muses', 'Bard Muse')

    doc.save()


def parse_mystery(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'mystery', 'Mysteries', 'Oracle Mystery')

    doc.save()


def parse_npc_theme_template(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'npc-theme-template', 'NPCThemeTemplates', 'Creature Theme Template')

    doc.save()


def parse_npc(id: str, soup: BeautifulSoup):
    parse_creature(id, soup, 'NPCs')


def parse_creature(id: str, soup: BeautifulSoup, url: str):
    doc = parse_generic(id, soup, 'creature', url, 'Creature')

    title = list(soup.find_all('h1', class_='title'))[1]
    name, type, level, pfs = get_title_data(title)
    traits = get_traits(soup)
    speed = get_label_text(soup, 'Speed')
    resistances = split_comma_special(get_label_text(soup, 'Resistances', ''))
    weaknesses = split_comma_special(get_label_text(soup, 'Weaknesses', ''))
    fort_save = int(get_label_text(soup, 'Fort', ';,('))
    reflex_save = int(get_label_text(soup, 'Ref', ';,('))
    will_save = int(get_label_text(soup, 'Will', ';,('))

    doc.name = name
    doc.type = type
    doc.level = level

    doc.alignment = soup.find('span', class_='traitalignment').text
    doc.rarity = get_rarity(traits)
    doc.size = soup.find('span', class_='traitsize').text
    doc.school = get_school(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.language = split_comma(get_label_text(soup, 'Languages'))
    doc.perception = get_label_text(soup, 'Perception')
    doc.sense = get_senses(get_label_text(soup, 'Perception', ''))
    doc.skill = split_comma(get_label_text(soup, 'Skills'))
    doc.speed = normalize_speed(speed)
    doc.speed_raw = speed
    doc.item = split_comma(get_label_text(soup, 'Items'))

    doc.strength = get_label_text(soup, 'Str', ',')
    doc.dexterity = get_label_text(soup, 'Dex', ',')
    doc.constitution = get_label_text(soup, 'Con', ',')
    doc.intelligence = get_label_text(soup, 'Int', ',')
    doc.wisdom = get_label_text(soup, 'Wis', ',')
    doc.charisma = get_label_text(soup, 'Cha')

    doc.ac = get_label_text(soup, 'AC', ';,( ')
    doc.fortitude_save = fort_save
    doc.reflex_save = reflex_save
    doc.will_save = will_save
    doc.hp = get_label_text(soup, 'HP', ';,(')
    doc.immunity = split_comma(get_label_text(soup, 'Immunities'))
    doc.resistance = normalize_resistance(resistances)
    doc.resistance_raw = resistances
    doc.weakness = normalize_resistance(weaknesses)
    doc.weakness_raw = weaknesses

    if soup.find('a', text='greater darkvision'):
        doc.vision = 'Greater darkvision'

    if soup.find('a', text='darkvision'):
        doc.vision = 'Darkvision'

    elif soup.find('a', text='low-light Vision'):
        doc.vision = 'Low-light vision'

    strongest_save_mod = max(fort_save, reflex_save, will_save)
    weakest_save_mod = min(fort_save, reflex_save, will_save)
    strongest_save = []
    weakest_save = []

    if fort_save == strongest_save_mod:
        strongest_save.append('fort')
        strongest_save.append('fortitude')

    if reflex_save == strongest_save_mod:
        strongest_save.append('ref')
        strongest_save.append('reflex')

    if will_save == strongest_save_mod:
        strongest_save.append('will')

    if fort_save == weakest_save_mod:
        weakest_save.append('fort')
        weakest_save.append('fortitude')

    if reflex_save == weakest_save_mod:
        weakest_save.append('ref')
        weakest_save.append('reflex')

    if will_save == weakest_save_mod:
        weakest_save.append('will')

    doc.strongest_save = strongest_save
    doc.weakest_save = weakest_save

    titles = list(soup.find_all('h1', class_='title'))
    if len(titles) >= 3:
        doc.creature_family = list(soup.find_all('h1', class_='title'))[2].text

    doc.save()


def parse_patron(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'patron', 'Patrons', 'Witch Patron Theme')
    traits = get_traits(soup)

    doc.granted_spell = get_label_text(soup, 'Granted Spell')
    doc.hex_cantrip = get_label_text(soup, 'Hex Cantrip')
    doc.rarity = get_rarity(traits)
    doc.skill = get_label_text(soup, 'Patron Skill')
    doc.spell_list = get_label_text(soup, 'Spell List')
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_plane(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'plane', 'Planes', 'Plane')
    traits = get_traits(soup)

    doc.alignment = soup.find('span', class_='traitalignment').text
    doc.divinity = get_label_text(soup, 'Divinities')
    doc.native_inhabitant = get_label_text(soup, 'Native Inhabitants')
    doc.plane_category = get_label_text(soup, 'Category')
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_racket(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'racket', 'Rackets', 'Rogue Racket')

    doc.save()


def parse_relic(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'relic', 'Relics', 'Relic')
    traits = get_traits(soup)

    doc.aspect = get_label_text(soup, 'Aspect')
    doc.prerequisite = get_label_text(soup, 'Prerequisite')
    doc.school = get_school(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_research_field(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'research-field', 'ResearchFields', 'Alchemist Research Field')

    doc.save()


def parse_ritual(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'ritual', 'Rituals', 'Ritual')
    duration = get_label_text(soup, 'Duration')
    range = get_label_text(soup, 'Range')
    secondary_casters = get_label_text(soup, 'Secondary Casters')
    traits = get_traits(soup)

    doc.actions = get_label_text(soup, 'Cast')
    doc.area = get_label_text(soup, 'Area')
    doc.cost = get_label_text(soup, 'Cost')
    doc.duration = normalize_time(duration)
    doc.duration_raw = duration
    doc.heighten = get_heighten(soup)
    doc.primary_check = get_label_text(soup, 'Primary Check', '', ';')
    doc.range = normalize_range(range)
    doc.range_raw = range
    doc.rarity = get_rarity(traits)
    doc.school = get_school(traits)
    doc.secondary_casters = [c for c in secondary_casters if c.isdigit()] if secondary_casters else None
    doc.secondary_casters_raw = secondary_casters
    doc.secondary_check = get_label_text(soup, 'Secondary Checks', '', ';')
    doc.target = get_label_text(soup, 'Target(s)')
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_rules(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'rules', 'Rules', 'Rules')

    title = soup.find('h1', class_='title')

    breadcrumbs = []
    if node := title.previous_sibling:
        while node := node.previous_sibling:
            breadcrumbs.append(node.text)

    if breadcrumbs:
        breadcrumbs.reverse()
        doc.breadcrumbs = ''.join(breadcrumbs)

    doc.save()


def parse_shield(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'shield', 'Shields', 'Shield')

    bulk = get_label_text(soup, 'Bulk')
    price = get_label_text(soup, 'Price')

    doc.ac = get_label_text(soup, 'AC Bonus', ';(')
    doc.bulk = normalize_bulk(bulk)
    doc.bulk_raw = bulk
    doc.hardness = get_label_text(soup, 'Hardness')
    doc.hp = get_label_text(soup, 'HP (BT)', ';(')
    doc.item_category = 'Shields'
    doc.item_subcategory = 'Base Shields'
    doc.price = normalize_price(price)
    doc.price_raw = price
    doc.speed_penalty = get_label_text(soup, 'Speed Penalty', ';', '—')

    doc.save()


def parse_siege_weapon(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'siege-weapon', 'SiegeWeapons', 'Siege Weapon')
    traits = get_traits(soup)

    doc.item_category = 'Siege Weapons'
    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_skill(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'skill', 'Skills', 'Skill')

    title = soup.find('h1', class_='title')

    doc.name = title.text.split('(')[0].strip()
    doc.ability = title.text.split('(')[1].strip(')')

    doc.save()


def parse_source(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'source', 'Sources', 'Source')

    doc.source = [ doc.name ]
    doc.source_raw = [ doc.name ]
    doc.source_category = get_category(soup.find(id='ctl00_RadDrawer1_Content_MainContent_Navigation'))

    doc.save()


def parse_spell(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'spell', 'Spells', 'Spell')
    duration = get_label_text(soup, 'Duration')
    range = get_label_text(soup, 'Range')
    traits = get_traits(soup)

    doc.actions = get_actions(soup, 'Cast')
    doc.area = get_label_text(soup, 'Area')
    doc.bloodline = split_comma(get_label_text(soup, 'Bloodline'))
    doc.component = get_label_links(soup, 'Cast')
    doc.deity = split_comma(get_label_text(soup, 'Deities')) or get_label_text(soup, 'Deity')
    doc.domain = get_label_text(soup, 'Domain')
    doc.duration = normalize_time(duration)
    doc.duration_raw = duration
    doc.heighten = get_heighten(soup)
    doc.mystery = get_label_text(soup, 'Mystery')
    doc.patron_theme = get_label_text(soup, 'Patron Theme')
    doc.range = normalize_range(range)
    doc.range_raw = range
    doc.rarity = get_rarity(traits)
    doc.requirement = get_label_text(soup, 'Requirements')
    doc.saving_throw = get_label_text(soup, 'Saving Throw')
    doc.school = get_school(traits)
    doc.target = get_label_text(soup, 'Targets')
    doc.tradition = split_comma(get_label_text(soup, 'Traditions'))
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_style(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'style', 'Styles', 'Swashbuckler Style')

    doc.save()


def parse_tenet(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'tenet', 'Tenets', 'Champion Tenet')

    doc.save()


def parse_trait(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'trait', 'Traits', 'Trait')

    doc.save()


def parse_vehicle(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'vehicle', 'Vehicles', 'Vehicle')
    traits = get_traits(soup)

    doc.item_category = 'Vehicles'
    doc.rarity = get_rarity(traits)
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits

    doc.save()


def parse_way(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'way', 'Ways', 'Gunslinger Way')

    doc.slingers_reload = get_label_text(soup, "Slinger's Reload")
    doc.deed = get_label_text(soup, 'Deeds', '')
    doc.skill = get_label_text(soup, 'Way Skill')

    doc.save()


def parse_weapon(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'weapon', 'Weapons', 'Weapon')

    title = soup.find('h1', class_='title')
    bulk = get_label_text(soup, 'Bulk', ';—')
    price = get_label_text(title, 'Price')
    range = get_label_text(soup, 'Range')
    reload = get_label_text(soup, 'Reload')
    traits = get_label_links(soup, 'Traits')
    weapon_category = get_label_text(soup, 'Category')
    weapon_group = get_label_text(soup, 'Group')

    doc.type = 'Weapon'
    doc.ammunition = get_label_text(soup, 'Ammunition')
    doc.bulk = normalize_bulk(bulk)
    doc.bulk_raw = bulk
    doc.damage = get_label_text(soup, 'Damage')
    doc.deity = split_comma(get_label_text(soup, 'Favored Weapon'))
    doc.hands = get_label_text(soup, 'Hands')
    doc.item_category = 'Weapons'
    doc.item_subcategory = 'Base Weapons'
    doc.price = normalize_price(price)
    doc.price_raw = price
    doc.range = normalize_range(range)
    doc.range_raw = range
    doc.rarity = get_rarity(traits)
    doc.reload = [c for c in reload if c.isdigit()] if reload else None
    doc.reload_raw = reload
    doc.trait = normalize_traits(traits)
    doc.trait_raw = traits
    doc.weapon_category = weapon_category
    doc.weapon_group = weapon_group

    if range or weapon_category.lower() == 'ammunition':
        doc.weapon_type = 'Ranged'

    else:
        doc.weapon_type = 'Melee'

    doc.save()


def parse_weapon_group(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'weapon-group', 'WeaponGroups', 'Weapon Critical Specialization')

    doc.weapon_group = doc.name

    doc.save()


def get_title_data(title: BeautifulSoup):
    strings = [s for s in list(title.strings) if s.strip()]
    name = strings[0]

    if len(strings) > 1:
        split = strings[-1].split()
        if len(split) >= 2 and split[-1].strip('+-').isnumeric():
            type = ' '.join(split[0:-1])
            level = split[-1]

        else:
            type = strings[-1].replace(' Level Varies', '')
            level = None

    else:
        type = None
        level = None

    img = title.find('img')
    if img:
        pfs = img['alt'].replace('PFS ', '') if img['alt'].startswith('PFS') else None
    else:
        pfs = None

    return name, type, level, pfs


def get_traits(soup: BeautifulSoup):
    traits = []
    node = soup
    while node := node.next_element:
        if node.name == 'span' and 'class' in node.attrs and node['class'][0].startswith('trait'):
            traits.append(node.text)

        elif (traits and node.name in ['h1', 'h2']) or node.name in ['h3']:
            break

    return traits


def normalize_source(source: str) -> str:
    if not source:
        return source

    index = source.find(' pg. ')

    if index != -1:
        source = source[:index]

    return source


def normalize_traits(traits: [str]) -> [str]:
    return list(map(normalize_trait, traits))


def normalize_trait(trait: str) -> str:
    prefixes = [
        'additive',
        'attached',
        'capacity',
        'deadly',
        'fatal aim',
        'fatal',
        'jousting',
        'legacy',
        'modular',
        'scatter',
        'thrown',
        'twin',
        'two-hand',
        'versatile',
        'volley',
    ]

    for prefix in prefixes:
        if trait.lower().startswith(prefix):
            return trait[:len(prefix)]

    return trait


def get_description(title: BeautifulSoup):
    desc = []
    skip_hr = False

    if node := title.next_sibling:
        while node := node.next_sibling:
            if node.name in ['h1', 'h2', 'h3']:
                skip_hr = True
                break

            elif node.name == 'hr':
                break

    if (node := title.find_next('hr')) and not skip_hr:
        while node := node.next_sibling:
            if node.name == 'h2':
                break

            elif node.text:
                desc.append(node.get_text(' ', strip=True))

    elif node := title.find_next_sibling('br'):
        while node := node.next_sibling:
            if node.name in ['h1', 'h2', 'h3']:
                break

            elif node.name == 'div':
                continue

            elif node.text:
                desc.append(node.get_text(' ', strip=True))

    return ' '.join([row.strip() for row in desc if row])


def join_and_strip(array: [str]) -> str:
    return ' '.join([s.strip() for s in array if s])


def get_sub_item_description(title: BeautifulSoup):
    breaks = []
    desc = []
    node = title

    while node := node.find_next_sibling('br'):
        if node.next_sibling.name != 'b':
            break

    if node == None:
        return ''

    while node := node.next_sibling:
        if node.name == 'h2':
            break

        if node.text:
            desc.append(node.get_text(' ', strip=True))

    return ' '.join([row.strip() for row in desc if row])


def normalize_bulk(value: str) -> float:
    if not value:
        return 0

    if value == 'L':
        return 0.1

    return float(value)


def normalize_time(value: str) -> int:
    if not value:
        return None

    match = re.match(r'(\d+) (\w+)', value)

    if not match:
        return None

    number = int(match.group(1))
    unit = match.group(2)

    if unit == "round" or unit == "rounds":
        return number * 6

    if unit == "minute" or unit == "minutes":
        return number * 60

    if unit == "hour" or unit == "hours":
        return number * 60 * 60

    if unit == "day" or unit == "days":
        return number * 60 * 60 * 24

    if unit == "week" or unit == "weeks":
        return number * 60 * 60 * 24 * 7

    if unit == "month" or unit == "months":
        return number * 60 * 60 * 24 * 30

    if unit == "year" or unit == "years":
        return number * 60 * 60 * 24 * 365

    return None


def normalize_price(price: str) -> int:
    if not price:
        return 0

    match = re.match(r'(((\d+),)?(\d+) gp)?(, )?((\d+) sp)?(, )?((\d+) cp)?', price)
    total = 0

    if match:
        if kgp := match.group(3):
            total += int(kgp) * 100000

        if gp := match.group(4):
            total += int(gp) * 100

        if sp := match.group(7):
            total += int(sp) * 10

        if cp := match.group(10):
            total += int(cp)

    return total


def normalize_range(value: str) -> int:
    if not value:
        return None

    if value == 'touch':
        return 0

    if value == 'planetary':
        return 10000000

    if value == 'unlimited':
        return 100000000

    value = value.replace('-', ' ').replace(',', '')
    numbers = [c for c in value.split() if c.isdigit()]

    if not numbers:
        return None

    number = int(numbers[0])

    if 'mile' in value:
        number *= 5280

    return number


def normalize_resistance(values: str):
    if not values:
        return None

    resistances = {}

    for resistance in values:
        match = re.match(r'^([\w ]+)( \(except (.*)\))? (\d+)( \(except (.*)\)?)?', resistance)

        if match:
            type = match.group(1)
            value = int(match.group(4))
            exceptions = match.group(3) or match.group(6)

            type = (type
                .replace(' damage', '')
                .replace(' energy', '')
                .replace('all physical', 'physical')
                .replace(' ', '_')
            )

            types = translate_damage_types(type, exceptions)

            for type in types:
                resistances[type] = value

    return resistances


def normalize_speed(value: str):
    speed = {
        'burrow': None,
        'climb': None,
        'fly': None,
        'land': None,
        'swim': None,
    }

    if not value:
        return speed

    values = value.split(', ')

    for s in values:
        match = re.match(r'((\w+) )?(\d+)( feet)?', s)

        if match:
            type = match.group(2)
            number = match.group(3)

            if type is None:
                speed['land'] = number

            elif type == 'burrow':
                speed['burrow'] = number

            elif type == 'climb':
                speed['climb'] = number

            elif type == 'fly':
                speed['fly'] = number

            elif type == 'swim':
                speed['swim'] = number

    return speed


def translate_damage_types(value: str, exceptions: str):
    if value == 'physical':
        types = physical_types()

    elif value == 'energy':
        types = energy_types()

    elif value == 'all':
        types = all_types()

    elif value in all_types():
        types = [value]

    else:
        types = []

    if exceptions:
        exceptions = (exceptions
            .replace(' or ', ',')
            .replace(';', ',')
            .replace(' ', '_')
            .split(',')
        )
        exceptions = [ ex.strip('_') for ex in exceptions ]

        types = [ type for type in types if type not in exceptions ]

    return types


def split_comma(string):
    return split_on(string, ',')


def split_comma_special(value: str):
    if not value:
        return None

    values = []
    in_parentheses = False
    part = ''

    for c in value:
        if c == ',' and not in_parentheses:
            values.append(part.strip())
            part = ''

        elif c == '(':
            in_parentheses = True
            part += c

        elif c == ')':
            in_parentheses = False
            part += c

        else:
            part += c

    if part:
        values.append(part.rstrip(';').strip())

    values = [ value.replace(' )', ')').replace(' ,', ',').replace(' ;', ';').replace('non- ', 'non-') for value in values ]

    return values


def split_on(string, split):
    if string:
        return [ s.strip() for s in string.split(split) ]

    else:
        return []


def get_label_text(soup, label, stop_at=';', strip=None):
    parts = []

    if node := soup.find_next('b', text=label):
        while node := node.next_sibling:
            if node.name in ['b', 'br', 'hr', 'h2']:
                break

            elif node.text:
                found_stop = False
                for c in node.text.lstrip():
                    if c in stop_at:
                        parts.append(node.text.lstrip().split(c)[0])
                        found_stop = True
                        break

                if found_stop:
                    break

                else:
                    parts.append(node.text.strip())

    parts = [s.strip() for s in parts if s]

    if parts:
        return (' '.join(parts)
            .strip(strip)
            .strip()
            .replace(' ,', ',')
            .replace(' ;', ';')
            .replace(' )', ')')
        )

    else:
        return None


def get_label_links(soup, label):
    parts = []

    if node := soup.find_next('b', text=label):
        while node := node.next_sibling:
            if node.name == 'br' or node.name == 'hr':
                break

            elif node.name == 'a' or node.name == 'u':
                parts.append(node.text.strip('; '))

                if node.text.strip().endswith(';'):
                    break

    if parts:
        return [ s.strip() for s in parts if s ]

    else:
        return []


def get_values_under_title(soup: BeautifulSoup, title: str):
    node = soup.find('h2', text=title)

    if not node:
        return []

    values = []
    value = ''

    while node := node.next_sibling:
        if node.name == 'h2':
            break

        elif node.name == 'br':
            values.append(value)
            value = ''

        elif node.text:
            value += node.text

    return [ v.strip() for v in values ]


def get_actions(soup, label):
    parts = []

    if node := soup.find_next('b', text=label):
        while node := node.next_sibling:
            if '(' in node.text:
                parts.append(node.text.split('(')[0].strip())

                break

            if ';' in node.text:
                parts.append(node.text.split(';')[0].strip())

                break

            if node.name in ['br', 'hr', 'a']:
                break

            if node.name == 'span' and 'action' in node['class']:
                parts.append(node['title'])

            elif node.name == 'img' and 'actiondark' in node['class']:
                parts.append(node['alt'])

            else:
                parts.append(node.text)

    if parts:
        return ' '.join([ s.strip() for s in parts if s.strip() ])

    else:
        return []


def get_actions_from_title(title: BeautifulSoup):
    actions = []

    if node := title.find('img', recursive=False):
        actions.append(node['alt'])

        while node := node.next_sibling:
            if node.name == 'span':
                break

            elif node.name == 'img':
                actions.append(node['alt'])

            else:
                actions.append(node.text)

    if actions:
        return ' '.join([ s.strip() for s in actions ])

    else:
        return None


def get_heighten(soup: BeautifulSoup):
    heighten = []

    for node in soup.find_all('b', string=re.compile('Heightened (.*)')):
        heighten.append(node.text.replace('Heightened (', '').replace(')', ''))

    return heighten


def get_rarity(traits) -> str:
    rarities = [
        'uncommon',
        'rare',
        'unique',
    ]
    traits = [ t.lower() for t in traits ]

    for rarity in rarities:
        if rarity in traits:
            return rarity

    return 'common'


def get_school(traits) -> str:
    if not traits:
        return None

    schools = [
        'abjuration',
        'conjuration',
        'divination',
        'enchantment',
        'evocation',
        'illusion',
        'necromancy',
        'transmutation',
    ]
    traits = [ t.lower() for t in traits ]

    for school in schools:
        if school in traits:
            return school

    return None


def get_senses(per):
    if not ';' in per:
        return None

    return [s.strip() for s in ''.join(per.split(';')[-1:]).split(',')]


def get_spoilers(soup: BeautifulSoup):
    for node in soup.find_all('h2', 'title', string=re.compile('may contain spoilers')):
        return node.text.split('from the ')[1].split(' Adventure')[0]

    return None


def get_stages(soup: BeautifulSoup):
    stages = [
        get_label_text(soup, 'Stage 1'),
        get_label_text(soup, 'Stage 2'),
        get_label_text(soup, 'Stage 3'),
        get_label_text(soup, 'Stage 4'),
        get_label_text(soup, 'Stage 5'),
        get_label_text(soup, 'Stage 6'),
        get_label_text(soup, 'Stage 7'),
    ]

    stages = [stage for stage in stages if stage]

    return stages


def get_category(soup: BeautifulSoup):
    if not soup:
        return None

    node = soup.find('u')

    if not node:
        return None

    return node.text


def physical_types():
    return ['bludgeoning', 'physical', 'piercing', 'slashing']


def energy_types():
    return ['acid', 'cold', 'electricity', 'fire', 'sonic', 'positive', 'negative', 'force']


def alignment_types():
    return['chaotic', 'evil', 'good', 'lawful']


def material_types():
    return ['cold_iron', 'orichalcum', 'silver']


def other_types():
    return ['area', 'bleed', 'mental', 'poison', 'precision', 'splash']


def all_types():
    return ['all'] + physical_types() + energy_types() + alignment_types() + material_types() + other_types()


class Alias(Field):
    name = "alias"


def damageTypesObject():
    fields = {}
    for type in all_types():
        fields[type] = Integer()

    return Object(properties=fields)


class Doc(Document):
    ability = Keyword(normalizer="lowercase")
    ability_boost = Keyword(normalizer="lowercase")
    ability_flaw = Keyword(normalizer="lowercase")
    ability_type = Keyword(normalizer="lowercase")
    ac = Integer()
    actions = Text(fields={'keyword': Keyword(normalizer="lowercase")})
    alignment = Keyword(normalizer="lowercase")
    archetype = Keyword(normalizer="lowercase")
    armor_category = Keyword(normalizer="lowercase")
    armor_group = Keyword(normalizer="lowercase")
    aspect = Keyword(normalizer="lowercase")
    bloodline = Keyword(normalizer="lowercase")
    bulk = Float()
    category = Keyword(normalizer="lowercase")
    cast = Alias(path="actions")
    cha = Alias(path="charisma")
    charisma = Integer()
    check_penalty = Integer()
    component = Keyword(normalizer="lowercase")
    con = Alias(path="constitution")
    constitution = Integer()
    creature_family = Keyword(normalizer="lowercase")
    deity = Keyword(normalizer="lowercase")
    deity_category = Keyword(normalizer="lowercase")
    dex = Alias(path="dexterity")
    dex_cap = Integer()
    dexterity = Integer()
    divine_font = Keyword(normalizer="lowercase")
    duration = Integer()
    favored_weapon = Keyword(normalizer="lowercase")
    follower_alignment = Keyword(normalizer="lowercase")
    fort = Alias(path="fortitude_save")
    fortitude = Alias(path="fortitude_save")
    fortitude_save = Integer()
    hardness = Integer()
    heighten = Keyword(normalizer="lowercase")
    hp = Integer()
    id = Integer()
    int = Alias(path="intelligence")
    intelligence = Integer()
    item_category = Keyword(normalizer="lowercase")
    item_subcategory = Keyword(normalizer="lowercase")
    level = Integer()
    mystery = Keyword(normalizer="lowercase")
    onset = Integer()
    patron_theme = Keyword(normalizer="lowercase")
    per = Alias(path="perception")
    perception = Integer()
    pfs = Keyword(normalizer="lowercase")
    plane_category = Keyword(normalizer="lowercase")
    price = Integer()
    range = Integer()
    rarity = Keyword(normalizer="lowercase")
    ref = Alias(path="reflex_save")
    reflex = Alias(path="reflex_save")
    reflex_save = Integer()
    region = Keyword(normalizer="lowercase")
    reload = Integer()
    required_abilities = Integer()
    resistance = damageTypesObject()
    secondary_casters = Integer()
    school = Keyword(normalizer="lowercase")
    size = Keyword(normalizer="lowercase")
    source = Keyword(normalizer="lowercase")
    source_category = Keyword(normalizer="lowercase")
    speed = Object(properties={
        'burrow': Integer(),
        'climb': Integer(),
        'fly': Integer(),
        'land': Integer(),
        'swim': Integer(),
    })
    spoilers = Keyword()
    str = Alias(path="strength")
    strength = Integer()
    strongest_save = Keyword(normalizer="lowercase")
    text = Text()
    tradition = Keyword(normalizer="lowercase")
    trait = Keyword(normalizer="lowercase")
    type = Keyword(normalizer="lowercase")
    url = Keyword()
    vision = Keyword(normalizer="lowercase")
    weakest_save = Keyword(normalizer="lowercase")
    weakness = damageTypesObject()
    weapon_category = Keyword(normalizer="lowercase")
    weapon_group = Keyword(normalizer="lowercase")
    weapon_type = Keyword(normalizer="lowercase")
    will = Alias(path="will_save")
    will_save = Integer()
    wis = Alias(path="wisdom")
    wisdom = Integer()

    class Index:
        name = 'aon'


if __name__ == "__main__":
    main()
