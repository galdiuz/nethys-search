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
    download_category('ArcaneSchools')
    download_category('ArcaneThesis')
    download_category('Archetypes')
    download_category('Armor')
    download_category('ArmorGroups')
    download_category('Backgrounds')
    download_category('Bloodlines')
    download_category('Causes')
    download_category('Classes')
    download_category('ClassKits')
    download_category('ClassSamples')
    download_category('Conditions')
    download_category('Curses')
    download_category('Deities')
    download_category('Diseases')
    download_category('Doctrines')
    download_category('Domains')
    download_category('DruidicOrders')
    download_category('Eidolons')
    download_category('Equipment')
    download_category('Familiars')
    download_category('Feats', 25)
    download_category('Hazards')
    download_category('Heritages')
    download_category('HuntersEdge')
    download_category('HybridStudies')
    download_category('Innovations')
    download_category('Instincts')
    download_category('Languages')
    download_category('Lessons')
    download_category('Methodologies')
    download_category('MonsterAbilities')
    download_category('MonsterFamilies')
    download_category('Monsters')
    download_category('Muses')
    download_category('Mysteries')
    download_category('NPCThemeTemplates')
    download_category('Patrons')
    download_category('Planes')
    download_category('Rackets')
    download_category('Relics')
    download_category('ResearchFields')
    download_category('Rituals')
    download_category('Rules')
    download_category('Shields')
    download_category('Skills')
    download_category('Spells', 25)
    download_category('Styles')
    download_category('Tenets')
    download_category('Traits')
    download_category('Ways')
    download_category('Weapons')
    download_category('WeaponGroups')

    # TODO: Ancestry Heritage pages?
    # TODO: Advanced/Specialized/Unique companions?
    # TODO: Specific familiars?


def download_category(category: str, max_failures: int = 5, id: int = 0):
    path = inflection.dasherize(inflection.underscore(category))
    Path(f"data/{path}").mkdir(parents=True, exist_ok=True)

    if category == 'Monsters':
        Path(f"data/npcs").mkdir(parents=True, exist_ok=True)

    failures = 0
    just_switched = False

    while True:
        id += 1
        url = f"https://2e.aonprd.com/{category}.aspx?ID={id}"
        file_name = f"data/{path}/{id}.html"

        if Path(file_name).is_file() or Path(file_name.replace('.html', '.404')).is_file():
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
        Path(file_name.replace('.html', '.404')).touch()

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
