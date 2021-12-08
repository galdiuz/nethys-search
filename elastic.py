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
                'archetypes': parse_archetype,
                'armor': parse_armor,
                'armor-groups': parse_armor_group,
                'backgrounds': parse_background,
                'classes': parse_class,
                'conditions': parse_condition,
                'curses': parse_curse,
                'deities': parse_deity,
                'diseases': parse_disease,
                'domains': parse_domain,
                'equipment': parse_equipment,
                'feats': parse_feat,
                'hazards': parse_hazard,
                'heritages': parse_heritage,
                'languages': parse_language,
                'monster-abilities': parse_monster_ability,
                'monster-families': parse_monster_family,
                'monsters': parse_monster,
                'np-cs': parse_npc,
                'planes': parse_plane,
                'relics': parse_relic,
                'rituals': parse_ritual,
                'rules': parse_rule,
                'shields': parse_shield,
                'skills': parse_skill,
                'spells': parse_spell,
                'traits': parse_trait,
                'weapon-groups': parse_weapon_group,
                'weapons': parse_weapon,
            }

            if dir_name in parse_functions:
                parse_functions[dir_name](id, soup)



def parse_action(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    if not title:
        return

    doc = Doc()
    doc.meta.id = 'action-' + id
    doc.id = id
    doc.category = 'action'
    doc.name = title.text.strip()
    doc['type'] = 'Action'

    if title.img:
        doc.actions = title.img['alt']
    doc.cost = get_label_text(soup, 'Cost')
    doc.description = get_description(title)
    doc.frequency = get_label_text(soup, 'Frequency')
    doc.requirements = get_label_text(soup, 'Requirements')
    doc.traits = get_traits(soup)
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_ancestry(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'ancestry-' + id
    doc.id = id
    doc.category = 'ancestry'
    doc.name = title.text.strip()
    doc['type'] = 'Ancestry'

    doc.traits = get_traits(soup)

    doc.save()


def parse_archetype(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'archetype-' + id
    doc.id = id
    doc.category = 'archetype'
    doc.name = title.text.strip()
    doc['type'] = 'Archetype'
    doc.description = get_description(title)

    doc.save()


def parse_armor(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    price = get_label_text(title, 'Price')

    doc = Doc()
    doc.meta.id = 'armor-' + id
    doc.id = id
    doc.category = 'armor'
    doc.name = title.text.strip()
    doc['type'] = 'Armor'
    doc.description = get_description(title)
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
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'armor-group-' + id
    doc.id = id
    doc.category = 'armor-group'
    doc.name = title.text.strip()
    doc['type'] = 'Armor Specialization'
    doc.description = get_description(title)

    doc.save()


def parse_background(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, _ = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'background-' + id
    doc.id = id
    doc.category = 'background'
    doc.name = name
    doc['type'] = type_

    doc.description = get_description(title)
    doc.region = get_label_text(soup, 'Region')
    doc.traits = get_traits(soup)

    doc.save()


def parse_class(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'class-' + id
    doc.id = id
    doc.category = 'class'
    doc.name = title.text
    doc['type'] = 'Class'
    doc.traits = get_traits(soup)

    doc.save()


def parse_condition(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'condition-' + id
    doc.id = id
    doc.category = 'condition'
    doc.name = title.text
    doc['type'] = 'Condition'
    doc.description = get_description(title)

    doc.save()


def parse_curse(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'curse-' + id
    doc.id = id
    doc.category = 'curse'
    doc.name = name
    doc['type'] = type_
    doc.level = level

    doc.description = get_description(title)
    doc.traits = get_traits(soup)
    doc.usage = get_label_text(soup, 'Usage')

    doc.save()


def parse_deity(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'deity-' + id
    doc.id = id
    doc.category = 'deity'
    doc.name = title.text.split('[')[0].strip()
    doc['type'] = 'Deity'

    doc.alignment = title.text.split('[')[1].strip(']')
    doc.anathema = get_label_text(soup, 'Anathema')
    doc.areasOfConcert = get_label_text(soup, 'Areas of Concern')
    doc.clericSpells = get_label_text(soup, 'Cleric Spells')
    doc.description = get_description(title)
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
    doc.category = 'disease'
    doc.name = name
    doc['type'] = type_
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
    doc.description = get_description(title)
    doc.traits = get_traits(soup)

    doc.save()


def parse_domain(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'domain-' + id
    doc.id = id
    doc.category = 'domain'
    doc.name = title.text
    doc['type'] = 'Domain'

    doc.advancedDomainSpell = get_label_text(soup, 'Advanced Domain Spell')
    doc.deities = split_comma(get_label_text(soup, 'Deities'))
    doc.domainSpell = get_label_text(soup, 'Domain Spell')
    doc.description = get_description(title)

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
            doc.category = 'equipment'
            doc.name = name
            doc['type'] = type_
            doc.level = level
            price = get_label_text(sub_title, 'Price')
            doc.price = price
            doc.normalized_price = parse_price(price)
            doc.hands = get_label_text(sub_title, 'Hands')
            doc.bulk = get_label_text(sub_title, 'Bulk')
            doc.usage = get_label_text(soup, 'Usage')
            doc.activate = get_actions(soup, 'Activate')
            doc.traits = get_traits(sub_title) or get_traits(soup)

            doc.description = join_and_strip([
                get_description(title),
                get_sub_item_description(sub_title)
            ])

            doc.save()

    else:
        doc = Doc()
        doc.meta.id = 'equipment-' + id
        doc.id = id
        doc.category = 'equipment'
        doc.name = name
        doc['type'] = type_
        doc.level = level
        price = get_label_text(title, 'Price')
        doc.price = price
        doc.normalized_price = parse_price(price)
        doc.hands = get_label_text(title, 'Hands')
        doc.bulk = get_label_text(title, 'Bulk')
        doc.usage = get_label_text(soup, 'Usage')
        doc.description = get_description(title)
        doc.traits = get_traits(soup)

        doc.save()


def parse_feat(id: str, soup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'feat-' + id
    doc.id = id
    doc.category = 'feat'
    doc.name = name
    doc['type'] = type_
    doc.level = level
    doc.traits = get_traits(soup)
    doc.actions = get_actions_from_title(title)
    doc.archetype = get_label_text(soup, 'Archetype')
    doc.description = get_description(title)
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
    doc.category = 'hazard'
    doc.name = name
    doc['type'] = type_
    doc.level = level

    doc.ac = get_label_text(soup, 'AC')
    doc.complexity = get_label_text(soup, 'Complexity')
    doc.description = get_label_text(soup, 'Description')
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
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'heritage-' + id
    doc.id = id
    doc.category = 'heritage'
    doc.name = title.text
    doc['type'] = 'Heritage'

    doc.description = get_description(title)
    doc.traits = get_traits(soup)

    doc.save()


def parse_language(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'language-' + id
    doc.id = id
    doc.category = 'language'
    doc.name = title.text
    doc['type'] = 'Language'

    doc.description = get_description(title)

    doc.save()


def parse_monster_ability(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'monster-ability-' + id
    doc.id = id
    doc.category = 'monster-ability'
    doc.name = title.text
    doc['type'] = 'Monster Ability'

    if title.img:
        doc.actions = title.img['alt']
    doc.description = get_description(title)
    doc.requirements = get_label_text(soup, 'Requirements')
    doc.effect = get_label_text(soup, 'Effect')
    doc.trigger = get_label_text(soup, 'Trigger')

    doc.save()


def parse_monster_family(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'monster-family-' + id
    doc.id = id
    doc.category = 'monster-family'
    doc.name = title.text
    doc['type'] = 'Monster Family'
    doc.description = get_description(title)

    doc.save()


def parse_monster(id: str, soup: BeautifulSoup):
    title = list(soup.find_all('h1', class_='title'))[1]
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'monster-' + id
    doc.id = id
    doc.category = 'monster'
    doc.name = name
    doc['type'] = type_
    doc.level = level

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
        doc.monsterFamily = list(soup.find_all('h1', class_='title'))[2].text

    doc.save()


def parse_npc(id: str, soup: BeautifulSoup):
    pass # TODO


def parse_plane(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, _ = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'plane-' + id
    doc.id = id
    doc.category = 'plane'
    doc.name = name
    doc['type'] = type_

    doc.alignment = soup.find('span', class_='traitalignment').text
    doc.description = get_description(title)
    doc.divinities = get_label_text(soup, 'Divinities')
    doc.nativeInhabitants = get_label_text(soup, 'Native Inhabitants')
    doc.planeCategory = get_label_text(soup, 'Category')
    doc.traits = get_traits(soup)

    doc.save()


def parse_relic(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, _ = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'relic-' + id
    doc.id = id
    doc.category = 'relic'
    doc.name = name
    doc['type'] = type_

    doc.prerequisites = get_label_text(soup, 'Preprequisite')
    doc.description = get_description(title)
    doc.aspect = get_label_text(soup, 'Aspect')
    doc.traits = get_traits(soup)

    doc.save()


def parse_ritual(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'ritual-' + id
    doc.id = id
    doc.category = 'ritual'
    doc.name = name
    doc['type'] = type_
    doc.level = level

    doc.area = get_label_text(soup, 'Area')
    doc.cast = get_label_text(soup, 'Cast')
    doc.cost = get_label_text(soup, 'Cost')
    doc.description = get_description(title)
    doc.duration = get_label_text(soup, 'Duration')
    doc.primaryCheck = get_label_text(soup, 'Primary Check')
    doc.range = get_label_text(soup, 'Range')
    doc.secondaryCasters = get_label_text(soup, 'Secondary Casters')
    doc.secondaryChecks = get_label_text(soup, 'Secondary Checks')
    doc.target = get_label_text(soup, 'Target(s)')
    doc.traits = get_traits(soup)

    doc.save()


def parse_rule(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'rules-' + id
    doc.id = id
    doc.category = 'rules'
    doc.name = title.text
    doc['type'] = 'Rules'

    breadcrumbs = []
    if node := title.previous_sibling:
        while node := node.previous_sibling:
            breadcrumbs.append(node.text)

    if breadcrumbs:
        breadcrumbs.reverse()
        doc.breadcrumbs = ''.join(breadcrumbs)

    doc.save()


def parse_shield(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    price = get_label_text(title, 'Price')

    doc = Doc()
    doc.meta.id = 'shield-' + id
    doc.id = id
    doc.category = 'shield'
    doc.name = title.text
    doc['type'] = 'Shield'

    doc.acBonus = get_label_text(soup, 'AC Bonus')
    doc.bulk = get_label_text(soup, 'Bulk')
    doc.description = get_description(title)
    doc.hardness = get_label_text(soup, 'Hardness')
    doc.hp = get_label_text(soup, 'HP (BT)')
    doc.normalized_price = parse_price(price)
    doc.price = price
    doc.speedPenalty = get_label_text(soup, 'Speed Penalty')

    doc.save()


def parse_skill(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    price = get_label_text(title, 'Price')

    doc = Doc()
    doc.meta.id = 'skill-' + id
    doc.id = id
    doc.category = 'skill'
    doc.name = title.text.split('(')[0].strip()
    doc['type'] = 'Skill'

    doc.attribute = title.text.split('(')[1].strip(')')
    doc.description = get_description(title)

    doc.save()


def parse_spell(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)

    doc = Doc()
    doc.meta.id = 'spell-' + id
    doc.id = id
    doc.category = 'spell'
    doc.name = name
    doc['type'] = type_
    doc.level = level

    doc.actions = get_actions(soup, 'Cast')
    doc.area = get_label_text(soup, 'Area')
    doc.bloodlines = split_comma(get_label_text(soup, 'Bloodline'))
    doc.components = get_label_links(soup, 'Cast')
    doc.deities = split_comma(get_label_text(soup, 'Deities')) or get_label_text(soup, 'Deity')
    doc.description = get_description(title)
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


def parse_trait(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'trait-' + id
    doc.id = id
    doc.category = 'trait'
    doc.name = title.text
    doc['type'] = 'Trait'
    doc.description = get_description(title)

    doc.save()


def parse_weapon(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, type_, level = get_title_data(title)
    price = get_label_text(title, 'Price')

    doc = Doc()
    doc.meta.id = 'weapon-' + id
    doc.id = id
    doc.category = 'weapon'
    doc.name = name
    doc['type'] = 'Weapon'
    doc.level = level

    doc.ammunition = get_label_text(soup, 'Ammunition')
    doc.bulk = get_label_text(soup, 'Bulk')
    doc.damage = get_label_text(soup, 'Damage')
    doc.description = get_description(title)
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
    title = soup.find('h1', class_='title')

    doc = Doc()
    doc.meta.id = 'weapon-group-' + id
    doc.id = id
    doc.category = 'weapon-group'
    doc.name = title.text
    doc['type'] = 'Weapon Critical Specialization'
    doc.description = get_description(title)

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

        elif traits and node.name in ['h2']:
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
            if node.name in ['br', 'hr', 'a'] or '(' in node.text:
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
    name = Text()
    level = Integer()
    category = Keyword()
    type_ = Keyword()
    description = Text()
    traits = Keyword()

    class Index:
        name = 'aon'


if __name__ == "__main__":
    main()
