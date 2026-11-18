"""Reject duplicate intrinsic registry identities and inconsistent storage counts."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parent

def validate_registry_text(source):
    names=re.findall(r'\bname\s*=\s*"([a-zA-Z0-9_]+)"',source)
    count=re.search(r'\bNUM_INTRINSICS\s*=\s*(\d+)',source)
    if not count or len(names)!=int(count.group(1)):
        raise ValueError('Intrinsic registry declared count differs')
    if len(set(names))!=len(names):raise ValueError('Duplicate intrinsic registry identity')
    for name in ('digits','new_line','rrspacing'):
        if names.count(name)!=1:raise ValueError(name.upper()+' must have exactly one registry identity')
    return len(names)

def verify_registry(path=None):
    source=path or ROOT.parents[1]/'vendor/fortfront/src/utilities/intrinsic_registry.f90'
    return validate_registry_text(source.read_text())
if __name__=='__main__':print(verify_registry(),'unique registered intrinsic identities verified')
