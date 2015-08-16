#!/usr/bin/env python

import json
import os
import sys

def find_by_name(source_files_json, name):
    for j in source_files_json:
        if j['name'] == name:
            return j

    return None

def merge_source_files(master, source):
    for sf in source:
        dest_sf = find_by_name(master, sf['name'])
        if dest_sf is None:
            master.append(sf)
            continue

        assert len(dest_sf['coverage']) == len(sf['coverage'])

        for i, line in enumerate(sf['coverage']):
            if line is None:
                continue

            if dest_sf['coverage'][i] is None:
                dest_sf['coverage'][i] = 0


            dest_sf['coverage'][i] += line

def get_json_from_file(fpath):
    with open(fpath, 'rb') as fp:
        return json.load(fp)

def main():
    out = {}
    out['source_files'] = []

    sources = []

    for f in sys.argv[1:]:
        assert os.path.isfile(f)
        sources.append(get_json_from_file(f))

    for s in sources:
        merge_source_files(out['source_files'], s['source_files'])

    print(json.dumps(out))

if __name__ == '__main__':
    main()