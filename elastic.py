#!/usr/bin/env python3
from bs4 import BeautifulSoup
from elasticsearch_dsl import Document, Integer, Text, Keyword
from elasticsearch_dsl.connections import connections
import re
import os


def main():
    connections.create_connection(hosts=['localhost'])
    Doc.init()

    for dir_name in sorted(os.listdir('data')):
        # if not dir_name in ['monster-families']:
        #     continue

        for file_name in sorted(os.listdir(f'data/{dir_name}/')):
            file_path = f'data/{dir_name}/{file_name}'

            if os.path.getsize(file_path) == 0 or file_name.endswith('.404'):
                continue

            id = file_name.replace('.html', '')

            if id != '1':
                continue

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
                'backgrounds': parse_background,
                'causes': parse_cause,
                'class-kits': parse_class_kit,
                'class-samples': parse_class_sample,
                'classes': parse_class,
                'conditions': parse_condition,
                'curses': parse_curse,
                'deities': parse_deity,
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
                'skills': parse_skill,
                'spells': parse_spell,
                'styles': parse_style,
                'tenets': parse_tenet,
                'traits': parse_trait,
                'ways': parse_way,
                'weapon-groups': parse_weapon_group,
                'weapons': parse_weapon,
            }

            if dir_name in parse_functions:
                parse_functions[dir_name](id, soup)


def build_url(category: str, id: int, params: [str] = []) -> str:
    return f'{category}.aspx?' + '&'.join([f"ID={id}"] + params)


def parse_generic(id: str, soup: BeautifulSoup, category: str, url: str, type_: str, url_params: [str] = []):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = category + '-' + id
    doc.id = id
    doc.url = build_url(url, id, url_params)
    doc.category = category
    doc.name = title.get_text(strip=True)
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)

    return doc


def parse_action(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    if not title:
        return

    doc = parse_generic(id, soup, 'action', 'Actions', 'Action')

    if title.img:
        doc.actions = title.img['alt']
    doc.cost = get_label_text(soup, 'Cost')
    # doc.description = get_description(title)
    doc.frequency = get_label_text(soup, 'Frequency')
    doc.requirements = get_label_text(soup, 'Requirements')
    doc.traits = get_traits(soup)
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_ancestry(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'ancestry', 'Ancestries', 'Ancestry')

    doc.traits = get_traits(soup)

    doc.save()


def parse_animal_companion(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'animal-companion', 'AnimalCompanions', 'Animal Companion')

    doc.traits = get_traits(soup)

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

    doc.traits = get_traits(soup)

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

    doc.traits = get_traits(soup)

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

    doc.price = price
    doc.normalized_price = parse_price(price)
    doc.acBonus = get_label_text(soup, 'AC Bonus')
    doc.dexCap = get_label_text(soup, 'Dex Cap')
    doc.checkPenalty = get_label_text(soup, 'Check Penalty')
    doc.speedPenalty = get_label_text(soup, 'Speed Penalty')
    doc.strength = get_label_text(soup, 'Strength')
    doc.bulk = get_label_text(soup, 'Bulk')
    doc.armorGroup = get_label_text(soup, 'Group')
    doc.traits = split_comma(get_label_text(soup, 'Traits'))

    doc.save()


def parse_armor_group(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'armor-group', 'ArmorGroups', 'Armor Specialization')

    doc.save()


def parse_background(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, _ = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'background-' + id
    doc.id = id
    doc.url = build_url('Backgrounds', id)
    doc.category = 'background'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)

    # doc.description = get_description(title)
    doc.region = get_label_text(soup, 'Region')
    doc.traits = get_traits(soup)

    doc.save()


def parse_cause(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'cause', 'Causes', 'Champion Cause')

    title = soup.find('h1', class_='title')

    doc.name = title.text.split('[')[0].strip()
    doc.alignment = ''.join([word[0] for word in title.text.split('[')[1].strip(']').split()])

    doc.save()


def parse_class(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'class', 'Classes', 'Class')

    doc.traits = get_traits(soup)

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
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'curse-' + id
    doc.id = id
    doc.url = build_url('Curses', id)
    doc.category = 'curse'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)
    doc.level = level

    # doc.description = get_description(title)
    doc.traits = get_traits(soup)
    doc.usage = get_label_text(soup, 'Usage')

    doc.save()


def parse_deity(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'deity-' + id
    doc.id = id
    doc.url = build_url('Deities', id)
    doc.category = 'deity'
    doc.name = title.text.split('[')[0].strip()
    doc['type'] = 'Deity'
    doc.text = title.parent.get_text(' ', strip=True)

    doc.alignment = title.text.split('[')[1].strip(']')
    doc.anathema = get_label_text(soup, 'Anathema')
    doc.areasOfConcern = get_label_text(soup, 'Areas of Concern')
    doc.clericSpells = get_label_text(soup, 'Cleric Spells')
    # doc.description = get_description(title)
    doc.divineAbility = get_label_text(soup, 'Divine Ability')
    doc.divineFont = get_label_text(soup, 'Divine Font')
    doc.divineSkill = get_label_text(soup, 'Divine Skill')
    doc.domains = split_comma(get_label_text(soup, 'Domains')) + split_comma(get_label_text(soup, 'Alternate Domains'))
    doc.edicts = get_label_text(soup, 'Edicts')
    doc.favoredWeapon = get_label_text(soup, 'Favored Weapon')
    doc.followerAlignments = split_comma(get_label_text(soup, 'Follower Alignments'))

    doc.save()


def parse_disease(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'disease-' + id
    doc.id = id
    doc.url = build_url('Diseases', id)
    doc.category = 'disease'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)
    doc.level = level

    doc.savingThrow = get_label_text(soup, 'Saving Throw')
    doc.onset = get_label_text(soup, 'Onset')
    doc.stage1 = get_label_text(soup, 'Stage 1')
    doc.stage2 = get_label_text(soup, 'Stage 2')
    doc.stage3 = get_label_text(soup, 'Stage 3')
    doc.stage4 = get_label_text(soup, 'Stage 4')
    doc.stage5 = get_label_text(soup, 'Stage 5')
    doc.stage6 = get_label_text(soup, 'Stage 6')
    doc.stage7 = get_label_text(soup, 'Stage 7')
    # doc.description = get_description(title)
    doc.traits = get_traits(soup)

    doc.save()


def parse_doctrine(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'doctrine', 'Doctrines', 'Cleric Doctrine')

    doc.save()


def parse_domain(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'domain', 'Domains', 'Domain')

    doc.advancedDomainSpell = get_label_text(soup, 'Advanced Domain Spell')
    doc.deities = split_comma(get_label_text(soup, 'Deities'))
    doc.domainSpell = get_label_text(soup, 'Domain Spell')
    # doc.description = get_description(title)

    doc.save()


def parse_druidic_order(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'druidic-order', 'DruidicOrders', 'Druidic Order')

    doc.save()


def parse_eidolon(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'eidolon-' + id
    doc.id = id
    doc.url = build_url('Eidolons', id)
    doc.category = 'eidolon'
    doc.name = title.text
    doc['type'] = 'Summoner Eidolon'
    doc.text = title.parent.get_text(' ', strip=True)

    doc.homePlane = get_label_text(soup, 'Home Plane')
    doc.languages = get_label_text(soup, 'Languages')
    doc.senses = get_label_text(soup, 'Senses')
    doc.size = get_label_text(soup, 'Size')
    doc.skills = split_comma(get_label_text(soup, 'Skills'))
    doc.speed = get_label_text(soup, 'Speed')
    doc.tradition = get_label_text(soup, 'Tradition')
    doc.traits = get_traits(soup)

    doc.save()


def parse_equipment(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)
    has_sub_items = level[-1] == '+'

    if has_sub_items:
        for idx, sub_title in enumerate(soup.find_all('h2', class_='title')):
            if len(list(sub_title.strings)) != 2:
                continue

            name, type_, level = get_title_data(sub_title)

            doc = Doc()
            doc.meta.id = 'equipment-' + id + '-' + str(idx)
            doc.id = id
            doc.url = build_url('Equipment', id)
            doc.category = 'equipment'
            doc.name = name
            doc['type'] = type_
            doc.text = title.parent.get_text(' ', strip=True)

            doc.level = level
            price = get_label_text(sub_title, 'Price')
            doc.price = price
            doc.normalized_price = parse_price(price)
            doc.hands = get_label_text(sub_title, 'Hands')
            doc.bulk = get_label_text(sub_title, 'Bulk')
            doc.usage = get_label_text(soup, 'Usage')
            doc.activate = get_actions(soup, 'Activate')
            doc.traits = get_traits(sub_title) or get_traits(soup)

            # doc.description = join_and_strip([
            #     get_description(title),
            #     get_sub_item_description(sub_title)
            # ])

            doc.save()

    else:
        doc = Doc()
        doc.meta.id = 'equipment-' + id
        doc.id = id
        doc.url = build_url('Equipment', id)
        doc.category = 'equipment'
        doc.name = name
        doc['type'] = type_
        doc.text = title.parent.get_text(' ', strip=True)

        doc.level = level
        price = get_label_text(title, 'Price')
        doc.price = price
        doc.normalized_price = parse_price(price)
        doc.hands = get_label_text(title, 'Hands')
        doc.bulk = get_label_text(title, 'Bulk')
        doc.usage = get_label_text(soup, 'Usage')
        # doc.description = get_description(title)
        doc.traits = get_traits(soup)

        doc.save()


def parse_familiar(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'familiar', 'Familiars', 'Familiar Ability')

    doc.abilityType = get_label_text(soup, 'Ability Type')

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

    doc.abilities = split_comma(get_label_text(soup, 'Granted Abilities'))
    doc.requiredAbilities = get_label_text(soup, 'Required Number of Abilities')
    doc.traits = get_traits(soup)

    doc.save()


def parse_feat(id: str, soup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'feat-' + id
    doc.id = id
    doc.url = build_url('Feats', id)
    doc.category = 'feat'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)

    doc.level = level
    doc.traits = get_traits(soup)
    doc.actions = get_actions_from_title(title)
    doc.archetype = get_label_text(soup, 'Archetype')
    # doc.description = get_description(title)
    doc.frequency = get_label_text(soup, 'Frequency')
    doc.prerequisites = get_label_text(soup, 'Prerequisites')
    doc.requirements = get_label_text(soup, 'Requirements')
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_hazard(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'hazard-' + id
    doc.id = id
    doc.url = build_url('Hazards', id)
    doc.category = 'hazard'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)

    doc.level = level
    doc.ac = get_label_text(soup, 'AC')
    doc.complexity = get_label_text(soup, 'Complexity')
    # doc.description = get_label_text(soup, 'Description')
    doc.disable = get_label_text(soup, 'Disable')
    doc.fortitude = get_label_text(soup, 'Fort')
    doc.hardness = get_label_text(soup, 'Hardness')
    doc.hp = get_label_text(soup, 'HP')
    doc.immunities = split_comma(get_label_text(soup, 'Immunities'))
    doc.reflexSave = get_label_text(soup, 'Ref')
    doc.reset = get_label_text(soup, 'Reset')
    doc.stealth = get_label_text(soup, 'Stealth')

    doc.save()


def parse_heritage(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'heritage', 'Heritages', 'Heritage')

    # doc.description = get_description(title)
    doc.traits = get_traits(soup)

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

    doc.lessonType = get_label_text(soup, 'Lesson Type')
    doc.traits = get_traits(soup)

    doc.save()


def parse_methodology(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'methodology', 'Methodologies', 'Investigator Methodology')

    doc.save()


def parse_monster_ability(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'creature-ability', 'MonsterAbilities', 'Creature Ability')

    title = soup.find('h1', class_='title')

    if title.img:
        doc.actions = title.img['alt']
    # doc.description = get_description(title)
    doc.requirements = get_label_text(soup, 'Requirements')
    doc.effect = get_label_text(soup, 'Effect')
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_monster_family(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'creature-family', 'MonsterFamilies', 'Creature Family')

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
    title = list(soup.find_all('h1', class_='title'))[1]
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'creature-' + id
    doc.id = id
    doc.url = build_url(url, id)
    doc.category = 'creature'
    doc.name = name
    doc['type'] = type_
    doc.level = level
    doc.text = title.parent.get_text(' ', strip=True)

    doc.alignment = soup.find('span', class_='traitalignment').text
    doc.size = soup.find('span', class_='traitsize').text
    doc.traits = get_traits(soup)

    doc.languages = split_comma(get_label_text(soup, 'Languages'))
    doc.perception = get_label_text(soup, 'Perception')
    doc.skills = split_comma(get_label_text(soup, 'Skills'))
    doc.speed = get_label_text(soup, 'Speed')
    doc.items = split_comma(get_label_text(soup, 'Items'))

    doc.strength = get_label_text(soup, 'Str', ',')
    doc.dexterity = get_label_text(soup, 'Dex', ',')
    doc.constitution = get_label_text(soup, 'Con', ',')
    doc.intelligence = get_label_text(soup, 'Int', ',')
    doc.wisdom = get_label_text(soup, 'Wis', ',')
    doc.charisma = get_label_text(soup, 'Cha'' ,')

    doc.ac = get_label_text(soup, 'AC')
    doc.fortitudeSave = get_label_text(soup, 'Fort', ',')
    doc.reflexSave = get_label_text(soup, 'Ref', ',')
    doc.willSave = get_label_text(soup, 'Will', ',;')
    doc.hp = get_label_text(soup, 'HP')
    doc.immunities = split_comma(get_label_text(soup, 'Immunities'))
    doc.resistances = split_comma(get_label_text(soup, 'Resistances'))
    doc.weaknesses = split_comma(get_label_text(soup, 'Weaknesses'))

    titles = list(soup.find_all('h1', class_='title'))
    if len(titles) >= 3:
        doc.creatureFamily = list(soup.find_all('h1', class_='title'))[2].text

    doc.save()


def parse_patron(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'patron', 'Patrons', 'Witch Patron Theme')

    doc.grantedSpell = get_label_text(soup, 'Patron Skill')
    doc.hexCantrip = get_label_text(soup, 'Hex Cantrip')
    doc.skills = get_label_text(soup, 'Patron Skill')
    doc.spellList = get_label_text(soup, 'Spell List')
    doc.traits = get_traits(soup)

    doc.save()


def parse_plane(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, _ = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'plane-' + id
    doc.id = id
    doc.url = build_url('Planes', id)
    doc.category = 'plane'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)

    doc.alignment = soup.find('span', class_='traitalignment').text
    # doc.description = get_description(title)
    doc.divinities = get_label_text(soup, 'Divinities')
    doc.nativeInhabitants = get_label_text(soup, 'Native Inhabitants')
    doc.planeCategory = get_label_text(soup, 'Category')
    doc.traits = get_traits(soup)

    doc.save()


def parse_racket(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'racket', 'Rackets', 'Rogue Rackets')

    doc.save()


def parse_relic(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, _ = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'relic-' + id
    doc.id = id
    doc.url = build_url('Relics', id)
    doc.category = 'relic'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)

    doc.prerequisites = get_label_text(soup, 'Preprequisite')
    # doc.description = get_description(title)
    doc.aspect = get_label_text(soup, 'Aspect')
    doc.traits = get_traits(soup)

    doc.save()


def parse_research_field(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'research-field', 'ResearchFields', 'Alchemist Research Field')

    doc.save()


def parse_ritual(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'ritual-' + id
    doc.id = id
    doc.url = build_url('Rituals', id)
    doc.category = 'ritual'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)
    doc.level = level

    doc.area = get_label_text(soup, 'Area')
    doc.cast = get_label_text(soup, 'Cast')
    doc.cost = get_label_text(soup, 'Cost')
    # doc.description = get_description(title)
    doc.duration = get_label_text(soup, 'Duration')
    doc.primaryCheck = get_label_text(soup, 'Primary Check')
    doc.range = get_label_text(soup, 'Range')
    doc.secondaryCasters = get_label_text(soup, 'Secondary Casters')
    doc.secondaryChecks = get_label_text(soup, 'Secondary Checks')
    doc.target = get_label_text(soup, 'Target(s)')
    doc.traits = get_traits(soup)

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

    price = get_label_text(soup, 'Price')

    doc.acBonus = get_label_text(soup, 'AC Bonus')
    doc.bulk = get_label_text(soup, 'Bulk')
    doc.hardness = get_label_text(soup, 'Hardness')
    doc.hp = get_label_text(soup, 'HP (BT)')
    doc.normalized_price = parse_price(price)
    doc.price = price
    doc.speedPenalty = get_label_text(soup, 'Speed Penalty')

    doc.save()


def parse_skill(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'skill', 'Skills', 'Skill')

    title = soup.find('h1', class_='title')

    doc.name = title.text.split('(')[0].strip()
    doc.attribute = title.text.split('(')[1].strip(')')
    # doc.description = get_description(title)

    doc.save()


def parse_spell(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'spell-' + id
    doc.id = id
    doc.url = build_url('Spells', id)
    doc.category = 'spell'
    doc.name = name
    doc['type'] = type_
    doc.text = title.parent.get_text(' ', strip=True)
    doc.level = level

    doc.actions = get_actions(soup, 'Cast')
    doc.area = get_label_text(soup, 'Area')
    doc.bloodlines = split_comma(get_label_text(soup, 'Bloodline'))
    doc.components = get_label_links(soup, 'Cast')
    doc.deities = split_comma(get_label_text(soup, 'Deities')) or get_label_text(soup, 'Deity')
    # doc.description = get_description(title)
    doc.duration = get_label_text(soup, 'Duration')
    doc.mystery = get_label_text(soup, 'Mystery')
    doc.patronTheme = get_label_text(soup, 'Patron Theme')
    doc.range = get_label_text(soup, 'Range')
    doc.requirements = get_label_text(soup, 'Requirements')
    doc.savingThrow = get_label_text(soup, 'Saving Throw')
    doc.targets = get_label_text(soup, 'Targets')
    doc.traditions = split_comma(get_label_text(soup, 'Traditions'))
    doc.traits = get_traits(soup)
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_style(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'style', 'Styles', 'Swashbuckler Style')

    doc.save()


def parse_trait(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'trait', 'Traits', 'Trait')

    doc.save()


def parse_tenet(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'tenet', 'Tenets', 'Champion Tenet')

    doc.save()


def parse_way(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'way', 'Ways', 'Gunslinger Way')

    doc.slingersReload = get_label_text(soup, "Slinger's Reload")
    doc.deeds = get_label_text(soup, 'Deeds')
    doc.skills = get_label_text(soup, 'Way Skill')

    doc.save()


def parse_weapon(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)
    price = get_label_text(title, 'Price')

    doc = Doc()
    doc.meta.id = 'weapon-' + id
    doc.id = id
    doc.url = build_url('Weapons', id)
    doc.category = 'weapon'
    doc.name = name
    doc['type'] = 'Weapon'
    doc.text = title.parent.get_text(' ', strip=True)
    doc.level = level

    doc.ammunition = get_label_text(soup, 'Ammunition')
    doc.bulk = get_label_text(soup, 'Bulk')
    doc.damage = get_label_text(soup, 'Damage')
    # doc.description = get_description(title)
    doc.favoredWeapon = split_comma(get_label_text(soup, 'Favored Weapon'))
    doc.hands = get_label_text(soup, 'Hands')
    doc.normalized_price = parse_price(price)
    doc.price = price
    doc.range = get_label_text(soup, 'Range')
    doc.reload = get_label_text(soup, 'Reload')
    doc.traits = get_label_links(soup, 'Traits')
    doc.weaponCategory = get_label_text(soup, 'Category')
    doc.weaponGroup = get_label_text(soup, 'Group')

    doc.save()


def parse_weapon_group(id: str, soup: BeautifulSoup):
    doc = parse_generic(id, soup, 'weapon-group', 'WeaponGroups', 'Weapon Critical Specialization')

    doc.save()


def get_title_data(title: BeautifulSoup):
    strings = [s for s in list(title.strings) if s.strip()]
    name = strings[0]

    if len(strings) > 1:
        split = strings[-1].split()
        if len(split) >= 2 and split[-1].rstrip('+').isnumeric():
            type_ = ' '.join(split[0:-1])
            level = split[-1]

        else:
            type_ = strings[-1]
            level = None

    else:
        type_ = None
        level = None

    return name, type_, level


def get_traits(soup: BeautifulSoup):
    traits = []
    node = soup
    while node := node.next_element:
        if node.name == 'span' and 'class' in node.attrs and node['class'][0].startswith('trait'):
            traits.append(node.text)

        elif traits and node.name in ['h2', 'h3']:
            break

    return traits


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


def parse_price(price: str) -> int:
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


def split_comma(string):
    if string:
        return [ s.strip() for s in string.split(',') ]

    else:
        return []


def get_label_text(soup, label, stop_at=';'):
    parts = []

    if node := soup.find_next('b', text=label):
        while node := node.next_sibling:
            if node.name in ['br', 'hr', 'h2']:
                break

            elif node.text:
                found_stop = False
                for c in stop_at:
                    if c in node.text:
                        parts.append(node.text.split(c)[0])
                        found_stop = True
                        break

                if found_stop:
                    break

                else:
                    parts.append(node.text.strip())

    if parts:
        return ' '.join([s.strip() for s in parts if s]).strip()

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


def get_actions(soup, label):
    parts = []

    if node := soup.find_next('b', text=label):
        while node := node.next_sibling:
            if '(' in node.text:
                parts.append(node.text.split('(')[0].strip())

                break

            if node.name in ['br', 'hr', 'a']:
                break

            if node.name == 'img' and 'actiondark' in node['class'] :
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


class Doc(Document):
    id = Integer()
    url = Keyword()
    name = Text()
    level = Integer()
    category = Keyword()
    type_ = Keyword()
    description = Text()
    text = Text()
    traits = Keyword()

    class Index:
        name = 'aon'


if __name__ == "__main__":
    main()
