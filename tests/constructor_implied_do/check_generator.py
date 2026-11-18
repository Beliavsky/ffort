#!/usr/bin/env python3
"""Replay generator in a retained isolated tree, never replacing committed inputs."""
from pathlib import Path
import argparse,datetime,hashlib,json,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parent

def sha(raw):return hashlib.sha256(raw).hexdigest()
def check():
    manifest=json.loads((ROOT/'manifest.json').read_text())
    names=[c['source'] for c in manifest['cases']]+['manifest.json','provenance.json']
    before={n:(ROOT/n).read_bytes() for n in names}
    protected={n:(ROOT/n).read_bytes() for n in ['generate_cases.py','source/xutilities.f90']}
    isolated=ROOT/'evidence'/('replay-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ'))
    (isolated/'source').mkdir(parents=True)
    for n in protected:shutil.copyfile(ROOT/n,isolated/n)
    p=subprocess.run([sys.executable,str(isolated/'generate_cases.py')],cwd=isolated,capture_output=True,timeout=30)
    errors=[];rows=[]
    if p.returncode or p.stderr:errors.append('Generator failed or emitted stderr')
    generated={str(p.relative_to(isolated)) for p in (isolated/'cases').glob('*.f90')}
    if generated!={c['source'] for c in manifest['cases']}:errors.append('Generated fixture name set differs')
    for n,raw in before.items():
        new=(isolated/n).read_bytes() if (isolated/n).exists() else None
        same=new==raw;untouched=(ROOT/n).read_bytes()==raw
        rows.append(dict(file=n,sha256=sha(raw),replay_sha256=sha(new) if new is not None else None,exact=same,original_unchanged=untouched))
        if not same or not untouched:errors.append('Byte mismatch or original change: '+n)
    for n,raw in protected.items():
        if (ROOT/n).read_bytes()!=raw:errors.append('Protected generator/input changed: '+n)
    return dict(summary=dict(fixtures=len(manifest['cases']),exact_files=sum(r['exact'] for r in rows),originals_unchanged=all(r['original_unchanged'] for r in rows),failed=len(errors)),errors=errors,isolated_directory=str(isolated),process=dict(code=p.returncode,stdout=p.stdout.decode('latin1'),stderr=p.stderr.decode('latin1')),files=rows)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--result',type=Path,default=ROOT/'evidence/generator-replay.json');args=ap.parse_args();r=check();args.result.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r['summary'],indent=2));return bool(r['errors'])
if __name__=='__main__':raise SystemExit(main())
