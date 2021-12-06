#!/usr/bin/env python3
from bs4 import BeautifulSoup
from elasticsearch_dsl import Document, Integer, Text, Keyword
from elasticsearch_dsl.connections import connections
import re
import os

connections.create_connection(hosts=['localhost'])

def main():
    for dir_name in sorted(os.listdir('data')):
        if dir_name != 'equipment':
        # if dir_name != 'feats' and dir_name != 'spells':
            continue

        for file_name in sorted(os.listdir(f'data/{dir_name}/')):
            file_path = f'data/{dir_name}/{file_name}'

            if os.path.getsize(file_path) == 0 or file_name.endswith('.404'):
                continue

            id = file_name.replace('.html', '')

            # if id != '474':
            #     continue

            # if int(id) >= 100:
            #     continue

            print(file_path)

            with open(file_path, 'r') as fp:
                soup = BeautifulSoup(fp, 'html5lib')

            if dir_name == 'equipment':
                parse_equipment(id, soup)

            elif dir_name == 'spells':
                parse_spell(id, soup)

            elif dir_name == 'feats':
                parse_feat(id, soup)


def parse_equipment(id: str, soup: BeautifulSoup):
    title = soup.find('h1', class_='title')
    name, level = get_name_and_level(title)
    has_sub_items = level[-1] == '+'

    if has_sub_items:
        for idx, sub_title in enumerate(soup.find_all('h2', class_='title')):
            if len(list(sub_title.strings)) != 2:
                continue

            name, level = get_name_and_level(sub_title)

            doc = Doc()
            doc.meta.id = 'equipment-' + id + '-' + str(idx)
            doc.id = id
            doc['type'] = 'equipment'
            doc.name = name
            doc.level = level
            price = text_until_next_br(sub_title, 'Price')
            doc.price = price
            doc.normalized_price = parse_price(price)
            doc.hands = text_until_next_br(sub_title, 'Hands')
            doc.bulk = text_until_next_br(sub_title, 'Bulk')
            doc.usage = text_until_next_br(soup, 'Usage')
            # TODO: Activate actions (id 74)
            doc.traits = get_traits(soup)

            doc.description = join_and_strip([
                get_description(title),
                get_sub_item_description(sub_title)
            ])

            doc.save()

    else:
        doc = Doc()
        doc.meta.id = 'equipment-' + id
        doc.id = id
        doc['type'] = 'equipment'
        doc.name = name
        doc.level = level
        price = text_until_next_br(title, 'Price')
        doc.price = price
        doc.normalized_price = parse_price(price)
        doc.hands = text_until_next_br(title, 'Hands')
        doc.bulk = text_until_next_br(title, 'Bulk')
        doc.usage = text_until_next_br(soup, 'Usage')
        doc.description = get_description(title)
        doc.traits = get_traits(soup)

        doc.save()


def parse_feat(id: str, soup):
    doc = Doc()
    doc.meta.id = 'feat-' + id
    doc.id = id
    doc['type'] = 'feat'
    doc.name = soup.find('h1', class_='title').find('a', href=('Feats.aspx?ID=' + id)).text
    doc.level = re.sub(r'[^0-9]', '', soup.find('h1', class_='title').find_all('span')[-1].text)
    doc.traits = []

    for trait in soup.find_all('span', class_='trait'):
        doc.traits.append(trait.a.text)

    doc.prerequisites = text_until_next_br(soup, 'Prerequisites')
    doc.trigger = text_until_next_br(soup, 'Trigger')
    doc.requirements = text_until_next_br(soup, 'Requirements')
    doc.frequency = text_until_next_br(soup, 'Frequency')
    doc.archetype = text_until_next_br(soup, 'Archetype')

    desc = []
    if node := soup.findAll('hr')[1]:
        while node := node.next_sibling:
            if node.name == 'h2':
                break

            if node.text:
                desc.append(node.text)

    doc.description = ' '.join([row.strip() for row in desc if row])

    doc.save()


def get_name_and_level(soup: BeautifulSoup):
    name = list(soup.strings)[0]
    level = re.match(r'[^\d]*(\d+\+?)$', list(soup.strings)[1]).group(1)

    return name, level


def get_traits(soup: BeautifulSoup):
    traits = []
    for node in soup.find_all('span'):
        if 'class' in node.attrs and node['class'][0] in ['trait', 'traituncommon', 'traitrare', 'traitunique']:
            traits.append(node.text)

    return traits


def get_description(soup: BeautifulSoup):
    desc = []
    if node := soup.find_next('hr'):
        while node := node.next_sibling:
            if node.name == 'h2':
                break

            if node.text:
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


def text_until_next_br(soup, label):
    parts = []

    if node := soup.find_next('b', text=label):
        while node := node.next_sibling:
            if node.name == 'br' or node.name == 'hr':
                break

            if node.text:
                parts.append(node.text.strip('; '))

                if node.text.strip().endswith(';'):
                    break

    if parts:
        return ' '.join([s.strip() for s in parts if s]).strip()

    else:
        return None


def parse_spell(id, soup):
    title = str(soup.find('h1', class_='title'))
    match = re.match(r'<h1[^>]*>(<a.*<\/a>)?([^<]*)<span[^>]*>(Cantrip|Focus|Spell) (\d*)', title)

    if not match:
        return

    doc = Doc()
    doc.meta.id = 'spell-' + id
    doc.id = id
    doc['type'] = 'spell'
    doc.name = match.group(2)
    doc.level = match.group(4)
    doc.bloodlines = []
    doc.components = []
    doc.deities = []
    doc.traditions = []
    doc.traits = []

    for trait in soup.find_all('span', class_='trait'):
        doc.traits.append(trait.a.text)

    if node := soup.find('b', text='Traditions'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.traditions.append(node.text)

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Bloodline'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.bloodlines.append(node.text)

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Bloodlines'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.bloodlines.append(node.text)

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Deity'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.deities.append(node.text)

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Deities'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.deities.append(node.text)

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Patron Theme'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.patronTheme = node.text

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Mystery'):
        while node := node.next_sibling:
            if node.name == 'u':
                doc.mystery = node.text

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Cast'):
        while node := node.next_sibling:
            if node.name == 'img':
                doc.actions = node['alt']

            elif node.name == 'a':
                doc.components.append(node.text)

            elif node.name == 'br':
                break

    if node := soup.find('b', text='Range'):
        doc.range = node.next_sibling.lstrip().rstrip('; ')

    if node := soup.find('b', text='Area'):
        doc.area = node.next_sibling.strip()

    if node := soup.find('b', text='Targets'):
        doc.targets = node.next_sibling.strip()

    if node := soup.find('b', text='Saving Throw'):
        doc.savingThrow = node.next_sibling.strip()

    if node := soup.find('b', text='Duration'):
        doc.duration = node.next_sibling.strip()

    desc = []
    if node := soup.findAll('hr')[1]:
        while node := node.next_sibling:
            if node.text:
                desc.append(node.text)

    doc.description = ' '.join([row.strip() for row in desc if row]).strip()

    doc.save()


class Doc(Document):
    id = Integer()
    name = Text()
    level = Integer()
    type_ = Keyword()
    description = Text()
    traits = Keyword()

    class Index:
        name = 'aon'


Doc.init()


if __name__ == "__main__":
    main()
