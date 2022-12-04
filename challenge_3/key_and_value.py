def get_value(obj, key):
    '''
    Return a value inside a nested object with a given key path
    In case the key is invalid, reutrn None
    '''
    current_value = obj
    for p in key.split("/"):
        if isinstance(current_value, dict):
            if p in current_value:
                current_value = current_value[p] 
            else: 
                return None
        elif hasattr(current_value, p):
            current_value = getattr(current_value, p)
        else:
            return None
    return current_value