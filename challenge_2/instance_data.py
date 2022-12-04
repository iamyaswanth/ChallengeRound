#!/usr/bin/env python3

import json
import requests

base_url = "http://169.254.169.254"

api_version = "2021-02-01"
end_point = base_url + "/metadata/instance?api-version=" + api_version

# Proxies must be bypassed when calling Azure IMDS
proxies = {
    "http": None,
    "https": None
}

# Function to make an api call
def api_call(endpoint):
    headers = {'Metadata': 'True'}
    return requests.get(endpoint, headers=headers, proxies=proxies).json() 

def main():
    obj = api_call(end_point)
    print("DEBUG: response from instance api:")
    print(json.dumps(obj, sort_keys=True, indent=4, separators=(',', ': ')))

def get_value_by_path(obj, path):
    '''
    path here is a UNIQUE key
    '''
    return _get_value_by_path_recursive(obj, path)
    
def _find_key_in_dict(d, key):
    for k, v in d.items():
        print(f"try to find in d[{k}]")
        try:
            # find value of key `key` in the member of the dictionary
            return _get_value_by_path_recursive(v, key)
        except:
            # if we cannot find any value in the `v`, try next value in `d`
            continue
    # try all value in the members recursively but still cannot found the key
    raise Exception("attribute doesn't exist")
    
def _get_value_by_path_recursive(obj, key):
    '''
    Return a value inside a nested object with a given key
    In case the key is invalid, return None
    '''
    if key == "":
        return "key shouldn't be empty"
    
    # if object is a dictionary, try to get the value by key
    if isinstance(obj, dict):
        if key in obj:
            return obj[key] 
        else:
            return _find_key_in_dict(obj, key)
    elif isinstance(obj, list):
        print("processing list")
        result = []
        # if obj is a list, try to scan through each of its item
        for item in obj:
            try:
                print("try to find in ", item)
                result.append(_get_value_by_path_recursive(item, key))
            except:
                continue
        # if after scanning recursively, the result is still empty ==> the key doesn't exist
        if len(result) == 0:
            raise Exception("attribute doesn't exist")
        return result
    elif hasattr(obj, key):
        # if it is an object, and has attribute `key`, just return the associated value
        return getattr(obj, key)
    else:
        # convert object to dictionary and find key in it (to reuse the code)
        return _find_key_in_dict(obj.__dict__, key)

if __name__ == "__main__":
    main()