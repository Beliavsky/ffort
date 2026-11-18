#!/usr/bin/env python3
"""Independent section CLI corpus, reusing strict, self-tested scalar output checks."""
import importlib.util
from pathlib import Path
import re
import tempfile

ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('section_array_runner',ROOT.parent/'arrays'/'run_corpus.py')
base=importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)
base.ROOT=ROOT
base.shared.ROOT=ROOT
original_assess_candidate=base.assess_candidate
original_assess_baseline=base.assess_baseline


def assess_candidate(case,command,timeout):
    result=original_assess_candidate(case,command+case.get('candidate_args',[]),timeout)
    if 'diagnostic' in case:
        # A fixture filename such as zero_stride.f90 must not accidentally
        # satisfy the expected diagnostic when the actual error is unrelated.
        diagnostic='\n'.join(re.sub(r'^.*?:\d+:\d+:\s*','',line)
                             for line in result['run']['stderr'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower():
            result['errors'].append('Missing diagnostic text (excluding source path): '+case['diagnostic'])
            result['passed']=False
    return result


def assess_baseline(case,compiler,timeout):
    if case['baseline'] not in ('checked_runtime','bounds_runtime'):
        return original_assess_baseline(case,compiler,timeout)
    fragments=case.get('baseline_diagnostic',['bound','outside of expected range'])
    if isinstance(fragments,str): fragments=[fragments]
    with tempfile.TemporaryDirectory(prefix='section-reference-') as folder:
        binary=str(Path(folder)/'reference')
        compiled=base.execute([compiler,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',
                               str(ROOT/case['source']),'-o',binary],cwd=folder,timeout=timeout)
        errors=[]
        result=dict(compile=compiled,errors=errors)
        if compiled['timeout'] or compiled['returncode']!=0:
            errors.append('GNU reference did not compile runtime probe')
        else:
            ran=base.execute([binary],cwd=folder,timeout=timeout)
            result['run']=ran
            diagnostic='\n'.join(line.split(':',1)[1] for line in ran['stderr'].splitlines()
                                 if line.lower().startswith('fortran runtime error:'))
            if (ran['timeout'] or ran['returncode'] is None or ran['returncode']<=0 or
                not any(fragment.lower() in diagnostic.lower() for fragment in fragments)):
                errors.append('GNU reference did not report checked runtime failure')
        result['passed']=not errors
        return result


base.assess_candidate=assess_candidate
base.assess_baseline=assess_baseline

if __name__=='__main__':
    raise SystemExit(base.main())
