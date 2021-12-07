#!/usr/bin/env python3
from pathlib import Path
import inflection
import os.path
import requests
import time
from bs4 import BeautifulSoup


def main():
    download_category("Actions")
    download_category("Ancestries")
    download_category("Archetypes")
    download_category("Armor")
    download_category("ArmorGroups")
    download_category("Backgrounds")
    download_category("Classes")
    download_category("Conditions")
    download_category("Curses")
    download_category("Deities")
    download_category("Diseases")
    download_category("Domains")
    download_category("Equipment")
    download_category("Feats")
    download_category("Hazards")
    download_category("Heritages")
    download_category("Languages")
    download_category("MonsterAbilities")
    download_category("MonsterFamilies")
    download_category("Monsters")
    download_category("NPCs")
    download_category("Planes")
    download_category("Relics")
    download_category("Rituals")
    download_category("Rules")
    download_category("Shields")
    download_category("Skills")
    download_category("Spells")
    download_category("Traits")
    download_category("Weapons")
    download_category("WeaponGroups")

    # TODO: Ancestry Heritage pages?


def download_category(category: str):
    path = inflection.dasherize(inflection.underscore(category))
    Path(f"data/{path}").mkdir(parents=True, exist_ok=True)

    id = 1
    failures = 0

    while True:
        url = f"https://2e.aonprd.com/{category}.aspx?ID={id}"
        file_name = f"data/{path}/{id}.html"

        if Path(file_name).is_file() or Path(file_name.replace('.html', '.404')).is_file():
            id += 1

            continue

        print("Downloading " + url)

        if download_to_file(url, file_name):
            failures = 0
            id += 1
            time.sleep(2.0)

        else:
            print("Failed to download " + url)
            failures += 1

            if failures >= 10:
                print(f"Max failures exceeded, done with category {category}")

                break


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
