from pathlib import Path
import subprocess,tempfile,shutil,argparse,json,hashlib
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--original-source',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');args=ap.parse_args()
with tempfile.TemporaryDirectory(prefix='dynamic-char-replay-') as tmp:
 dst=Path(tmp);shutil.copy2(ROOT/'generate_cases.py',dst/'generate_cases.py');q=subprocess.run(['python3',dst/'generate_cases.py','--original-source',args.original_source.resolve()],capture_output=True,text=True)
 if q.returncode:raise RuntimeError(q.stderr)
 files=sorted([*Path('cases').glob('nonexistent')])
 files=[Path('manifest.json'),Path('provenance.json')]+[p.relative_to(dst) for p in (dst/'cases').glob('*.f90')]
 for f in files:assert (ROOT/f).read_bytes()==(dst/f).read_bytes(),f
 report=dict(generated_files=len(files),exact=True,sha256={str(f):hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in files})
(ROOT/'generator-replay-results.json').write_text(json.dumps(report,indent=2)+'\n');print(len(files),'files match byte for byte')
