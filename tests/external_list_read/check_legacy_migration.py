#!/usr/bin/env python3
"""Execute unchanged external_read sources with reviewed 0.47 metadata, without editing their tree."""
from pathlib import Path
import argparse,datetime,hashlib,importlib.util,json,tempfile
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--source-root',required=True,type=Path)
ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',required=True,type=Path)
ap.add_argument('--result',default='legacy-external-second-migrated-results.json');a=ap.parse_args()
source_root=a.source_root.resolve();candidate=a.candidate.resolve();fc=a.gfortran.resolve()
spec=importlib.util.spec_from_file_location('legacy_harness',source_root/'run_tests.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
manifest=ROOT/'legacy-proposed/external-read-manifest.json';ledger=ROOT/'legacy-proposed/external-read-diagnostics.json'
cases=json.loads(manifest.read_text())['cases'];pins=json.loads(ledger.read_text())['negative_cases']
provenance=json.loads((source_root/'provenance.json').read_text())
original=(source_root.parent/'utilities_slices/source/xutilities.f90').read_bytes()
if hashlib.sha256(original).hexdigest()!=provenance['source_sha256']:raise SystemExit('Original provenance mismatch')
bodies=[]
for p in provenance['bodies']:
 body=b''.join(original.splitlines(keepends=True)[p['start_line']-1:p['end_line']])
 if hashlib.sha256(body).hexdigest()!=p['sha256']:raise SystemExit('Original body mismatch')
 bodies.append(body)
records=[]
for c0 in cases:
 c=dict(c0);source=source_root/c['source'];errors=[]
 if c.get('original_body') and any(b not in source.read_bytes() for b in bodies):raise SystemExit('Fixture provenance mismatch')
 if c['category']!='success':
  pin=pins[c['name']]
  if pin['source']!=c['source'] or pin['source_sha256']!=hashlib.sha256(source.read_bytes()).hexdigest():raise SystemExit('Pin source mismatch')
  c['expected_diagnostic']={k:pin[k] for k in ('line','column','message')}
 with tempfile.TemporaryDirectory(prefix='legacy-external-gnu-') as folder:
  t=Path(folder)
  for unit,data in c.get('inputs',{}).items():(t/('fort.'+unit)).write_bytes(data.encode())
  compiled=h.execute([fc,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',source,'-o',t/'ref'],t)
  if compiled['code']!=0 or compiled['out']!='' or compiled['err']!='':errors.append('GNU compilation mismatch')
  gnu=None
  if compiled['code']==0 and c['baseline']=='run':
   gnu=h.execute([t/'ref'],t)
   if gnu['code']!=0 or gnu['err']!='' or not h.compare(gnu['out'],c['expected_stdout'],c.get('compare_mode','tokens')):errors.append('GNU runtime mismatch')
  if c['baseline'] not in ('run','compile'):raise SystemExit('Unexpected legacy GNU category')
 with tempfile.TemporaryDirectory(prefix='legacy-external-candidate-') as folder:
  t=Path(folder);bindings=[]
  for unit,data in c.get('inputs',{}).items():
   path=t/('input-'+unit);path.write_bytes(data.encode());bindings+=['--input',unit+'='+str(path)]
  checked=h.execute([candidate,'--check']+bindings+[source],t)
  ran=h.execute([candidate]+bindings+c.get('args',[])+[source],t)
  for unit,data in c.get('inputs',{}).items():
   if (t/('input-'+unit)).read_bytes()!=data.encode():errors.append('Binding bytes modified')
  if list(t.glob('fort.*')):errors.append('Implicit file creation')
 errors+=h.candidate_errors(c,checked,ran)
 records.append(dict(case=c,gnu_compile=compiled,gnu_run=gnu,check=checked,run=ran,errors=errors))
 print(c['name']+(': FAIL '+str(errors) if errors else ': PASS'))
report=dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),source_root=str(source_root),
 candidate_sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(),candidate_version=h.execute([candidate,'--version']),
 gnu_version=h.execute([fc,'--version']),compiler_flags=['-std=f2018','-pedantic-errors','-fcheck=all','-O0'],
 summary=dict(total=len(records),failed=sum(bool(r['errors']) for r in records),gnu_executed=sum(r['gnu_run'] is not None for r in records)),
 actual_manifest_sha256=hashlib.sha256(manifest.read_bytes()).hexdigest(),actual_ledger_sha256=hashlib.sha256(ledger.read_bytes()).hexdigest(),
 original_manifest_sha256=hashlib.sha256((source_root/'manifest.json').read_bytes()).hexdigest(),
 source_sha256={c['source']:hashlib.sha256((source_root/c['source']).read_bytes()).hexdigest() for c in cases},records=records)
(ROOT/a.result).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report['summary']))
raise SystemExit(bool(report['summary']['failed']))
