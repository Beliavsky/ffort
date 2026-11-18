#!/usr/bin/env python3
"""Verify generated fixture, manifest, provenance and diagnostic bytes are replayable."""
from pathlib import Path
import argparse,hashlib,json,tempfile
import generate_cases
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--original-source',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');args=ap.parse_args()
expected=['manifest.json','diagnostics.json','provenance.json']
expected += ['cases/'+p.name for p in sorted((ROOT/'cases').glob('*.f90'))]
with tempfile.TemporaryDirectory(prefix='external-list-generator-') as folder:
 target=Path(folder);generate_cases.generate(args.original_source,target)
 actual=['manifest.json','diagnostics.json','provenance.json']+['cases/'+p.name for p in sorted((target/'cases').glob('*.f90'))]
 errors=[]
 if actual!=expected:errors.append('Generated file inventory differs')
 for name in expected:
  if not (target/name).is_file() or (target/name).read_bytes()!=(ROOT/name).read_bytes():errors.append(name+': byte drift')
 report=dict(files_checked=len(expected),errors=errors,sha256={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in expected})
(ROOT/'generator-replay-results.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(dict(files_checked=len(expected),errors=errors)))
raise SystemExit(bool(errors))
