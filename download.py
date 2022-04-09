#!/usr/bin/env python3
from pathlib import Path
import inflection
import os.path
import requests
import time
from bs4 import BeautifulSoup


def main():
    download_category('Actions', 25)
    download_category('Ancestries')
    download_category('AnimalCompanions')
    download_category('AnimalCompanions', params=['Advanced=true'], path_suffix='-advanced')
    download_category('AnimalCompanions', params=['Specialized=true'], path_suffix='-specialized')
    download_category('AnimalCompanions', 1, params=['Unique=true'], path_suffix='-unique')
    download_category('ArcaneSchools', 1)
    download_category('ArcaneThesis', 1)
    download_category('Archetypes')
    download_category('Armor')
    download_category('ArmorGroups', 1)
    download_category('Backgrounds')
    download_category('Bloodlines', 1)
    download_category('Causes', 1)
    download_category('Classes')
    download_category('ClassKits')
    download_category('ClassSamples')
    download_category('Conditions')
    download_category('Curses')
    download_category('Deities')
    download_category('DeityCategories')
    download_category('Diseases')
    download_category('Doctrines', 1)
    download_category('Domains')
    download_category('DruidicOrders', 1)
    download_category('Eidolons', 1)
    download_category('Equipment', 25)
    download_category('Familiars')
    download_category('Familiars', params=['Specific=true'], path_suffix='-specific')
    download_category('Feats', 25)
    download_category('Hazards')
    download_category('Heritages')
    download_category('HuntersEdge', 1)
    download_category('HybridStudies', 1)
    download_category('Innovations', 1)
    download_category('Instincts', 1)
    download_category('Languages')
    download_category('Lessons', 1)
    download_category('Methodologies', 1)
    download_category('MonsterAbilities')
    download_category('MonsterFamilies')
    download_category('Monsters')
    download_category('Muses', 1)
    download_category('Mysteries', 1)
    download_category('NPCThemeTemplates')
    download_category('Patrons', 1)
    download_category('Planes')
    download_category('Rackets', 1)
    download_category('Relics')
    download_category('ResearchFields', 1)
    download_category('Rituals')
    download_category('Rules', 25)
    download_category('Shields')
    download_category('SiegeWeapons')
    download_category('Skills')
    download_category('Spells', 25)
    download_category('Sources')
    download_category('Styles', 1)
    download_category('Tenets', 1)
    download_category('Traits')
    download_category('Vehicles')
    download_category('Ways', 1)
    download_category('Weapons')
    download_category('WeaponGroups', 1)


def download_category(category: str, max_failures: int = 5, params: [str] = [], path_suffix: str = '', id: int = None):
    path = inflection.dasherize(inflection.underscore(category)) + path_suffix
    Path(f"data/{path}").mkdir(parents=True, exist_ok=True)

    exists = [ int(file_name.replace('.html', '')) for file_name in os.listdir(f'data/{path}/') ]

    if category == 'Monsters':
        Path(f"data/npcs").mkdir(parents=True, exist_ok=True)
        exists = exists + [ int(file_name.replace('.html', '')) for file_name in os.listdir(f'data/npcs/') ]

    if id == None:
        id = max(exists) if exists else 0

    failures = 0
    just_switched = False

    while True:
        id += 1
        url = f"https://2e.aonprd.com/{category}.aspx?" + '&'.join([f"ID={id}"] + params)
        file_name = f"data/{path}/{id}.html"

        if id in exists:
            failures = 0

            continue

        print("Downloading " + url)

        if download_to_file(url, file_name):
            failures = 0
            just_switched = False

        else:
            print("Failed to download " + url)
            failures += 1

            if failures >= max_failures:
                print(f"Max failures exceeded, done with category {category}")

                break

            if category == 'Monsters':
                category = 'NPCs'
                path = 'npcs'
                just_switched = not just_switched

                if just_switched:
                    id -= 1

            elif category == 'NPCs':
                category = 'Monsters'
                path = 'monsters'
                just_switched = not just_switched

                if just_switched:
                    id -= 1

        time.sleep(2.0)


def download_to_file(url: str, file_name: str):
    response = requests.get(url)

    if response.status_code == 500:
        return False

    if response.status_code != 200:
        return False

    soup = BeautifulSoup(response.content, 'html5lib')
    content = soup.find('div', id="main")

    if not content:
        return False

    with open(file_name, 'w') as out_file:
        out_file.write(str(content))

    return True


if __name__ == "__main__":
    main()
