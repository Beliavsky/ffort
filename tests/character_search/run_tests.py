#!/usr/bin/env python3
"""Independent differential checks for bounded SCAN and VERIFY."""
from pathlib import Path
import argparse,datetime,hashlib,importlib.util,json,tempfile
from generate_matrix import verify_matrix
ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('character_runner',ROOT.parent/'character_intrinsics'/'run_tests.py')
common=importlib.util.module_from_spec(spec)
spec.loader.exec_module(common)

def verify_provenance():
    mapping=json.loads((ROOT/'source-map.json').read_text())
    original=(ROOT/mapping['source']).read_bytes()
    assert hashlib.sha256(original).hexdigest()==mapping['source_sha256'],'Original utilities source changed'
    lines=original.decode().splitlines()
    for item in mapping['expressions']:
        assert item['expression'] in lines[item['line']-1],'Original SCAN expression changed'
        assert (ROOT/item['fixture']).read_text().count(item['expression'])==1,'Fixture expression changed'

def main():
    verify_provenance()
    verify_matrix()
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate',required=True,type=Path)
    ap.add_argument('--gfortran',default='gfortran')
    ap.add_argument('--result',default='results.json')
    a=ap.parse_args();candidate=a.candidate.resolve();records=[]
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        source=ROOT/case['source'];row={'case':case,'errors':[]}
        with tempfile.TemporaryDirectory(prefix='character-search-') as folder:
            exe=Path(folder)/'reference'
            compiled=common.execute([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',source,'-o',exe],folder)
            row['gnu_compile']=compiled
            if case['baseline']=='reject':
                if compiled['code']!=1:row['errors'].append('GNU did not reject invalid source')
            elif compiled['code']!=0:row['errors'].append('GNU compile failed')
            elif case['baseline']=='run':
                ran=common.execute([exe],folder);row['gnu_run']=ran
                if ran['code']!=0:row['errors'].append('GNU execution failed')
                row['errors']+=['GNU '+e for e in common.output_errors(case,ran['out'])]
        row['check']=common.execute([candidate,'--check',source])
        row['run']=common.execute([candidate,source])
        row['errors']+=common.candidate_errors(case,row['check'],row['run'])
        print(case['name']+': '+('FAIL '+', '.join(row['errors']) if row['errors'] else 'PASS'),flush=True)
        records.append(row)
    summary={'total':len(records),'failed':sum(bool(r['errors']) for r in records),
        'gnu_executed':sum('gnu_run' in r for r in records),
        'gnu_compile_rejections':sum(r['case']['baseline']=='reject' for r in records),
        'gnu_compile_only':sum(r['case']['baseline']=='compile' for r in records),
        'independent_matrix_values':sum(r['case'].get('oracle_values',0) for r in records)}
    result={'summary':summary,'records':records,'candidate_sha256':hashlib.sha256(candidate.read_bytes()).hexdigest(),
        'candidate_version':common.execute([candidate,'--version']),
        'gfortran_version':common.execute([a.gfortran,'--version']),
        'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'limits':'Default CHARACTER, rank zero through two, INTEGER(4/8) results. Undefined-value cases compile only under GNU. The utility driver retains two expressions, not an original routine.',
        'manifest_sha256':hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
        'source_sha256':{r['case']['source']:hashlib.sha256((ROOT/r['case']['source']).read_bytes()).hexdigest() for r in records}}
    output=Path(a.result);output=output if output.is_absolute() else ROOT/output
    output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(summary,indent=2))
    return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
