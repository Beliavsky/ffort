import argparse,hashlib,json,pathlib,subprocess,time
p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--label',required=True);a=p.parse_args()
E=pathlib.Path(__file__).resolve().parent;W=E.parent/'057-read-sections-work';S=W/'tests/utilities_working/xutilities-nmax-100000.f90';O=W/'tests/utilities_slices/source/xutilities.f90';C=pathlib.Path(a.candidate).resolve(strict=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
expected='69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914';original='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
assert sha(S)==expected and sha(O)==original
b=S.read_bytes();o=O.read_bytes();diff=[i for i,(x,y) in enumerate(zip(o,b)) if x!=y]
assert len(b)==len(o)==338883 and diff==[322447] and o[diff[0]:diff[0]+1]==b'8' and b[diff[0]:diff[0]+1]==b'5'
ch=sha(C);results=[]
for name,args in [('check',['--check']),('run',['--max-steps','100000000'])]:
 cmd=[str(C),*args,str(S)];t=time.monotonic();r=subprocess.run(cmd,capture_output=True,text=True,cwd=W,timeout=180)
 (E/f'{a.label}-utilities-{name}.stdout').write_text(r.stdout);(E/f'{a.label}-utilities-{name}.stderr').write_text(r.stderr)
 results.append(dict(stage=name,command=cmd,exit=r.returncode,stdout=r.stdout,stderr=r.stderr,seconds=time.monotonic()-t))
assert sha(C)==ch and sha(S)==expected and sha(O)==original
result=dict(status='observation_recorded',candidate_sha256=ch,working_source_sha256=expected,original_source_sha256=original,source_bytes=338883,one_byte_authorized_adaptation_preserved=True,results=results)
(E/f'{a.label}-utilities.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
