#!/usr/bin/env python3
"""Regenerate only the synthetic zero-length CHARACTER cap+1 STAT fixture.

The exact original utility bodies and all other Fortran fixtures are untouched.
Run explicitly after changing src/fi_ir.f90 and rebuilding; --check is read-only.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parent
CASE_NAME='element_cap_stat'
CASE_SOURCE='cases/element_cap_stat.f90'
TEMPLATE='''program p
implicit none
character(0),allocatable :: x(:)
call fill(0,x)
if (allocated(x)) error stop 1
print *,1
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),allocatable,intent(out) :: a(:)
integer :: status
allocate(a(@ELEMENTS@),stat=status)
if (status==0) error stop 2
if (allocated(a)) error stop 3
end subroutine
end program
'''

def configured_cap(text):
    values=re.findall(r'^\s*integer\s*,\s*parameter\s*::\s*max_array_elements\s*=\s*([0-9]+)\s*(?:!.*)?$',text,re.I|re.M)
    if len(values)!=1:
        raise ValueError('Require exactly one literal max_array_elements source constant')
    cap=int(values[0])
    if not 1<=cap<2147483647:
        raise ValueError('Array cap must be positive and below HUGE(default INTEGER)')
    return cap

def generated_source(cap):
    if not 1<=cap<2147483647:
        raise ValueError('Unsupported array cap')
    return TEMPLATE.replace('@ELEMENTS@',str(cap+1)).encode()

def generated_metadata(cap):
    return dict(generator='generate_cap_case.py',source=CASE_SOURCE,
                configured_cap_source='src/fi_ir.f90:max_array_elements',
                configured_cap=cap,requested_elements=cap+1,
                source_sha256=hashlib.sha256(generated_source(cap)).hexdigest(),
                scope='Synthetic interpreter resource-policy fixture; no original utility body; GNU compile-only.')

def check_generated(root=ROOT):
    cap=configured_cap((root.parents[1]/'src/fi_ir.f90').read_text())
    manifest=json.loads((root/'manifest.json').read_text())
    cases=[c for c in manifest['cases'] if c['name']==CASE_NAME]
    if len(cases)!=1 or cases[0].get('generated')!=generated_metadata(cap):
        raise ValueError('Cap fixture manifest differs; run generate_cap_case.py after reconfiguration')
    if (root/CASE_SOURCE).read_bytes()!=generated_source(cap):
        raise ValueError('Cap fixture source differs; run generate_cap_case.py after reconfiguration')
    provenance=json.loads((root/'provenance.json').read_text())
    if provenance.get('synthetic_generated_cases',{}).get(CASE_NAME)!=generated_metadata(cap):
        raise ValueError('Cap fixture provenance differs; run generate_cap_case.py after reconfiguration')
    return generated_metadata(cap)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    if not args.check:
        cap=configured_cap((ROOT.parents[1]/'src/fi_ir.f90').read_text())
        manifest=json.loads((ROOT/'manifest.json').read_text())
        cases=[c for c in manifest['cases'] if c['name']==CASE_NAME]
        if len(cases)!=1:
            parser.error('Expected exactly one maintained cap case')
        cases[0]['generated']=generated_metadata(cap)
        cases[0]['oracle_note']='Configured element cap applies even with zero-length CHARACTER elements; generated cap+1 STAT probe. GNU compiles but does not execute this resource-policy case.'
        provenance=json.loads((ROOT/'provenance.json').read_text())
        provenance.setdefault('synthetic_generated_cases',{})[CASE_NAME]=generated_metadata(cap)
        (ROOT/CASE_SOURCE).write_bytes(generated_source(cap))
        (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        (ROOT/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    try:
        result=check_generated()
    except ValueError as exc:
        parser.error(str(exc))
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
