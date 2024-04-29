#!/usr/bin/env python3

import argparse
import hashlib
import itertools
import json
import os
import requests


def fetch_index_name(url):
    print('Fetching index name')

    response = requests.post(url)
    data = response.json()

    return data['hits']['hits'][0]['_index']


def fetch_docs(url):
    size = 10000
    all_docs = []
    after = None

    print('Fetching docs')

    while True:
        postdata = {
            '_source': {
                'include': [
                    'category',
                    'id',
                    'name',
                    'type',
                    'url',
                    'ability_type',
                    'ac',
                    'ac_scale_number',
                    'actions',
                    'activate',
                    'advanced_apocryphal_spell_markdown',
                    'advanced_domain_spell_markdown',
                    'alignment',
                    'anathema',
                    'apocryphal_spell_markdown',
                    'archetype',
                    'area_raw',
                    'area_type',
                    'armor_category',
                    'armor_group_markdown',
                    'aspect',
                    'attack_bonus',
                    'attack_bonus_scale_number',
                    'attack_proficiency',
                    'attribute',
                    'attribute_flaw',
                    'base_item_markdown',
                    'bloodline_markdown',
                    'breadcrumbs',
                    'bulk',
                    'bulk_raw',
                    'charisma',
                    'charisma_scale_number',
                    'check_penalty',
                    'complexity',
                    'component',
                    'constitution',
                    'constitution_scale_number',
                    'cost_markdown',
                    'creature_ability',
                    'creature_family',
                    'creature_family_markdown',
                    'damage',
                    'damage_type',
                    'defense_proficiency',
                    'deity',
                    'deity_category',
                    'deity_markdown',
                    'dex_cap',
                    'dexterity',
                    'dexterity_scale_number',
                    'divine_font',
                    'domain',
                    'domain_markdown',
                    'domain_spell_markdown',
                    'duration',
                    'duration_raw',
                    'edict',
                    'element',
                    'familiar_ability',
                    'favored_weapon_markdown',
                    'feat_markdown',
                    'follower_alignment',
                    'fortitude_proficiency',
                    'fortitude_save',
                    'fortitude_save_scale_number',
                    'frequency',
                    'hands',
                    'hardness_raw',
                    'hazard_type',
                    'heighten',
                    'heighten_group',
                    'heighten_level',
                    'hp_raw',
                    'hp_scale_number',
                    'icon_image',
                    'image',
                    'immunity_markdown',
                    'intelligence',
                    'intelligence_scale_number',
                    'item_category',
                    'item_subcategory',
                    'language_markdown',
                    'legacy_id',
                    'lesson_markdown',
                    'lesson_type',
                    'level',
                    'markdown',
                    'mystery_markdown',
                    'onset_raw',
                    'pantheon',
                    'pantheon_markdown',
                    'pantheon_member_markdown',
                    'patron_theme_markdown',
                    'perception',
                    'perception_proficiency',
                    'perception_scale_number',
                    'pfs',
                    'plane_category',
                    'prerequisite_markdown',
                    'price_raw',
                    'primary_check_markdown',
                    'range',
                    'range_raw',
                    'rarity',
                    'rarity_id',
                    'reflex_proficiency',
                    'reflex_save',
                    'reflex_save_scale_number',
                    'region',
                    'release_date',
                    'reload_raw',
                    'remaster_id',
                    'required_abilities',
                    'requirement_markdown',
                    'resistance',
                    'resistance_markdown',
                    'sanctification_raw',
                    'saving_throw_markdown',
                    'school',
                    'search_markdown',
                    'secondary_casters_raw',
                    'secondary_check_markdown',
                    'sense_markdown',
                    'size',
                    'size_id',
                    'skill_markdown',
                    'skill_proficiency',
                    'source',
                    'source_category',
                    'source_group',
                    'source_markdown',
                    'speed',
                    'speed_markdown',
                    'speed_penalty',
                    'spell_attack_bonus',
                    'spell_attack_bonus_scale_number',
                    'spell_dc',
                    'spell_dc_scale_number',
                    'spell_list',
                    'spell_markdown',
                    'spell_type',
                    'spoilers',
                    'stage_markdown',
                    'strength',
                    'strength_scale_number',
                    'strike_damage_average',
                    'strike_damage_scale_number',
                    'strongest_save',
                    'summary_markdown',
                    'target_markdown',
                    'tradition',
                    'tradition_markdown',
                    'trait',
                    'trait_markdown',
                    'trigger_markdown',
                    'usage_markdown',
                    'vision',
                    'warden_spell_tier',
                    'weakest_save',
                    'weakness',
                    'weakness_markdown',
                    'weapon_category',
                    'weapon_group',
                    'weapon_group_markdown',
                    'weapon_type',
                    'will_proficiency',
                    'will_save',
                    'will_save_scale_number'
                    'wisdom',
                    'wisdom_scale_number',
                ]
            },
            'sort': ['_doc'],
            'size': size,
        }

        if after:
            postdata['search_after'] = after

        response = requests.post(url, json=postdata)
        data = response.json()

        hits = data['hits']['hits']
        docs = [hit['_source'] for hit in hits]
        all_docs += docs

        print(len(all_docs))

        if len(hits) < size:
            break

        if hits:
            last = hits[-1]
            after = last['sort']

    return all_docs


def fetch_source_agg(url):
    print('Fetching source agg')

    postdata = {
        'aggs': {
            'source': {
                'composite': {
                    'size': 10000,
                    'sources': [
                        {
                            'category': {
                                'terms': {
                                    'field': 'source_category',
                                    'missing_bucket': False,
                                }
                            }
                        },
                        {
                            'name': {
                                'terms': {
                                    'field': 'name.keyword',
                                    'missing_bucket': False,
                                }
                            }
                        }
                    ]
                }
            }
        },
        'query': {
            'bool': {
                'must': {
                    'term': {
                        'type': 'source'
                    }
                },
                'must_not': {
                    'term': {
                        'exclude_from_search': True
                    }
                }
            }
        },
        'size': 0,
    }

    response = requests.post(url, json=postdata)
    data = response.json()

    return [bucket['key'] for bucket in data['aggregations']['source']['buckets']]


def fetch_trait_agg(url):
    print('Fetching trait agg')

    postdata = {
        'aggs': {
            'trait_group': {
                'composite': {
                    'size': 10000,
                    'sources': [
                        {
                            'group': {
                                'terms': {
                                    'field': 'trait_group',
                                    'missing_bucket': False,
                                }
                            }
                        },
                        {
                            'trait': {
                                'terms': {
                                    'field': 'name.keyword',
                                    'missing_bucket': False,
                                }
                            }
                        }
                    ]
                }
            }
        },
        'query': {
            'bool': {
                'must': {
                    'term': {
                        'type': 'trait'
                    }
                },
                'must_not': {
                    'term': {
                        'exclude_from_search': True
                    }
                }
            }
        },
        'size': 0,
    }

    response = requests.post(url, json=postdata)
    data = response.json()

    return [bucket['key'] for bucket in data['aggregations']['trait_group']['buckets']]


if __name__ == '__main__':
    if not 'batched' in dir(itertools):
        exit('Python 3.12 or greater is required')

    parser = argparse.ArgumentParser()
    parser.add_argument('url')
    args = parser.parse_args()

    url = args.url + '/_search'

    index_name = fetch_index_name(url)
    source_agg = fetch_source_agg(url)
    trait_agg = fetch_trait_agg(url)
    docs = fetch_docs(url)

    print('Writing files for index ' + index_name)

    index = {}
    dir_path = 'json-data'

    if not os.path.exists(dir_path):
        os.makedirs(dir_path)

    with open(dir_path + '/' + index_name + '-aggs.json', 'w') as fp:
        aggs = {
            "sources": source_agg,
            "traits": trait_agg,
        }
        json.dump(aggs, fp)

    docs.sort(key=lambda doc: doc['category'])
    by_cat = {k: list(v) for k, v in itertools.groupby(docs, lambda doc: doc['category'])}

    chunks = []
    cats_to_add = []

    for cat in by_cat:
        cat_docs = by_cat[cat]

        if len(cat_docs) > 200:
            chunks += itertools.batched(cat_docs, 200)

        elif len(cat_docs) >= 50:
            chunks.append(cat_docs)

        else:
            cats_to_add.append(cat)

    cats_to_add.sort(key=lambda cat: len(by_cat[cat]), reverse=True)

    while len(cats_to_add):
        chunk = []

        for cat in cats_to_add.copy():
            cat_docs = by_cat[cat]

            if len(chunk) + len(cat_docs) <= 200:
                chunk += cat_docs

                cats_to_add.remove(cat)

                if (len(chunk) == 200):
                    break

        if chunk:
            chunks.append(chunk)

    for chunk in chunks:
        chunk_json = json.dumps(chunk)
        chunk_hash = hashlib.md5(chunk_json.encode('utf-8')).hexdigest()

        with open(f'{dir_path}/{chunk_hash}.json', 'w') as fp:
            json.dump(chunk, fp)

        ids = [doc['id'] for doc in chunk]
        index[chunk_hash] = ids

    with open(dir_path + '/' + index_name + '-index.json', 'w') as fp:
        json.dump(index, fp)

    print('Done')
