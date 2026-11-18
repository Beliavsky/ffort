#!/usr/bin/env python3
"""Independent own-index inquiry fixtures; never build an interpreter or run negatives."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,runpy
ROOT=Path(__file__).resolve().parent
h=runpy.run_path(str(ROOT.parent/'run_tests.py'))
execute,compare,sha=h['execute'],h['compare'],h['sha']
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate',type=Path);ap.add_argument('--gfortran');ap.add_argument('--only',default='')
    ap.add_argument('--result',type=Path,default=ROOT/'verification.json');a=ap.parse_args()
    if not a.candidate and not a.gfortran:ap.error('Supply --candidate and/or --gfortran')
    candidate=a.candidate.resolve() if a.candidate else None
    candidate_hash=sha(candidate.read_bytes()) if candidate else None
    count=h['self_test']();h['check_original_sources']()
    manifest=json.loads((ROOT/'manifest.json').read_text());rows=[]
    folder=ROOT/('verification-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ'))
    if a.gfortran:folder.mkdir()
    for case in manifest['cases']:
        if not re.search(a.only,case['name']):continue
        src=ROOT/case['source'];assert sha(src.read_bytes())==case['source_sha256']
        expected=(ROOT/case['expected_file']).read_bytes().decode('latin1') if 'expected_file' in case else ''
        if 'expected_file' in case:assert sha(expected.encode('latin1'))==case['expected_sha256']
        row={'case':case,'errors':[]}
        if a.gfortran:
            exe=folder/case['name']
            argv=[a.gfortran,*h['FLAGS'],src]+(['-o',exe] if case['category']=='success' else ['-fsyntax-only'])
            c=execute(argv,folder);row['gnu_compile']=c;row['gnu_command']=[str(x) for x in argv]
            if case['category']=='success':
                if c['code']!=0 or c['out'] or c['err']:row['errors'].append('GNU success compilation failed or emitted output')
                else:
                    z=execute([exe],folder);row['gnu_run']=z
                    if z['code']!=0 or z['err'] or not compare(z['out'],expected,case['compare_mode']):row['errors'].append('GNU execution/oracle mismatch')
            elif case['baseline']=='reject':
                if c['code']!=1 or c['out'] or not c['err'].strip():row['errors'].append('GNU compile-rejection fixture did not reject')
            elif c['code']!=0 or c['out']:
                row['errors'].append('GNU compile-only fixture failed compilation')
        if candidate:
            checked=execute([candidate,'--check',src]);ran=execute([candidate,src])
            row.update(check=checked,run=ran);row['errors']+=h['candidate_errors'](case,checked,ran,expected)
        rows.append(row);print(case['name']+(': PASS' if not row['errors'] else ': FAIL '+', '.join(row['errors'])))
    if not rows:ap.error('No selected cases')
    if candidate:assert sha(candidate.read_bytes())==candidate_hash
    summary=dict(total=len(rows),failed=sum(bool(x['errors']) for x in rows),gnu_executed=sum('gnu_run' in x for x in rows),gnu_compile_only=sum(x['case']['baseline']=='compile' for x in rows) if a.gfortran else 0,gnu_compile_rejections=sum(x['case']['baseline']=='reject' for x in rows) if a.gfortran else 0,candidate_checked=len(rows) if candidate else 0,harness_self_tests=count)
    versions={str(path):execute([path,'--version']) for path in [candidate,a.gfortran] if path}
    report=dict(summary=summary,candidate_sha256=candidate_hash,manifest_sha256=sha((ROOT/'manifest.json').read_bytes()),compiler_flags=h['FLAGS'],tools=versions,records=rows)
    a.result.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(summary,indent=2));return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
