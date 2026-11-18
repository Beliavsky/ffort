import concurrent.futures,hashlib,json,pathlib,subprocess,sys
R=pathlib.Path(__file__).resolve().parents[2];W=R/'recovery/057-read-sections-work';B=R/'recovery/057-repl-array-intrinsics-work';E=pathlib.Path(__file__).resolve().parent
C=W/'build/gfortran_A86CEF2075723C1E/app/fortfront-interpreter';G=R/'scifort-verification/toolchain/bin/gfortran'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
expected=sys.argv[1];assert sha(C)==expected
suites=['internal_read','internal_read_element','external_list_read'];pin={}
for suite in suites:
 for p in (W/'tests'/suite).rglob('*'):
  if p.is_file() and ('__pycache__' not in str(p)) and (p.suffix=='.f90' or p.name in ('manifest.json','provenance.json','diagnostics.json','run_tests.py')):pin[str(p.relative_to(W))]=sha(p)
import difflib
changes=[]
for n,h in pin.items():
 p=B/n
 if p.exists() and sha(p)!=h:changes.append(n)
assert changes==['tests/internal_read/manifest.json'],changes
(E/'internal-read-manifest.diff').write_text(''.join(difflib.unified_diff((B/changes[0]).read_text().splitlines(True),(W/changes[0]).read_text().splitlines(True),fromfile='baseline/'+changes[0],tofile='candidate/'+changes[0])))
commands={}
for suite in suites:
 cmd=[sys.executable,str(W/'tests'/suite/'run_tests.py'),'--candidate',str(C),'--gfortran',str(G),'--result',str(E/(suite+'-final.json'))]
 if suite=='internal_read_element':cmd+=['--expected-candidate-sha256',expected,'--candidate-version','0.56.0','--evidence-dir',str(E/'internal-read-element-final-raw')]
 commands[suite]=cmd
(E/'affected-read-lanes-commands.json').write_text(json.dumps(commands,indent=2)+'\n')
def run(suite):
 r=subprocess.run(commands[suite],capture_output=True,text=True,cwd=W,timeout=600)
 (E/(suite+'-final.log')).write_text(r.stdout+r.stderr);(E/(suite+'-final.exit')).write_text(str(r.returncode)+'\n');return dict(suite=suite,exit=r.returncode)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(run,suites))
assert sha(C)==expected
assert all(sha(W/n)==h for n,h in pin.items())
original=W/'tests/utilities_slices/source/xutilities.f90';working=W/'tests/utilities_working/xutilities-nmax-100000.f90'
assert sha(original)=='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
assert sha(working)=='69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914'
report=dict(status='passed' if all(r['exit']==0 for r in results) else 'failed',candidate_sha256=expected,source_pins=pin,changed_inputs=changes,results=results,original_source_sha256=sha(original),working_source_sha256=sha(working),source_bytes=working.stat().st_size,utility_source_unchanged=True)
(E/'affected-read-lanes-final.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
