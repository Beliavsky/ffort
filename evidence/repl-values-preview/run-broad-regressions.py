import argparse,concurrent.futures,hashlib,json,pathlib,re,subprocess,sys
p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--sha256',required=True);p.add_argument('--label',default='final');a=p.parse_args()
E=pathlib.Path(__file__).resolve().parent;W=E.parent/'057-repl-values-work';B=E.parent/'057-read-sections-work';C=pathlib.Path(a.candidate).resolve(strict=True);sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();assert sha(C)==a.sha256
scripts=[W/'tests/repl'/p.name for p in sorted((B/'tests/repl').glob('test_*.py'))];pins={str(p.relative_to(W)):sha(p) for p in scripts};read=W/'tests/internal_read_sections/test_read_sections.py';pins[str(read.relative_to(W))]=sha(read)
assert not (E/f'{a.label}-broad-regressions.json').exists()
def mode_run(mode):
 rows=[]
 for test in scripts:
  n=test.stem.removeprefix('test_');log=E/f'{a.label}-{n}-{mode}.log';report=E/f'{a.label}-{n}-{mode}.json';assert not log.exists() and not report.exists()
  cmd=[sys.executable]+(['-O'] if mode=='optimized' else [])+[str(test),'--candidate',str(C)]
  if n not in ('editor_smoke','immediate','vars'):cmd+=['--report',str(report)]
  r=subprocess.run(cmd,capture_output=True,text=True,cwd=W,timeout=300);text=r.stdout+r.stderr;log.write_text(text)
  m=re.search(r'Ran (\d+) tests?',text);count=int(m.group(1)) if m else 0
  rows.append(dict(suite=n,exit=r.returncode,tests=count,passed=r.returncode==0 and bool(re.search(r'^OK$',text,re.M)),command=cmd))
 return rows
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:res=dict(zip(('normal','optimized'),pool.map(mode_run,('normal','optimized'))))
cmd=[sys.executable,str(read),'--candidate',str(C),'--report',str(E/f'{a.label}-read-smoke.json')];r=subprocess.run(cmd,capture_output=True,text=True,cwd=W,timeout=120);(E/f'{a.label}-read-smoke.log').write_text(r.stdout+r.stderr);rd=json.loads((E/f'{a.label}-read-smoke.json').read_text());rd['exit']=r.returncode
assert sha(C)==a.sha256 and all(sha(W/n)==h for n,h in pins.items())
totals={k:sum(r['tests'] for r in v) for k,v in res.items()};ok=all(all(r['passed'] for r in v) for v in res.values()) and all(v==338 for v in totals.values()) and rd['tests']==18 and rd['status']=='passed' and r.returncode==0
report=dict(status='passed' if ok else 'failed',candidate_sha256=a.sha256,source_pins=pins,per_mode=totals,results=res,read_smoke=rd)
(E/f'{a.label}-broad-regressions.json').write_text(json.dumps(report,indent=2)+'\n');(E/f'{a.label}-broad-regressions.exit').write_text(('0' if ok else '1')+'\n');print(json.dumps({k:v for k,v in report.items() if k not in ('source_pins','results')}));raise SystemExit(not ok)
