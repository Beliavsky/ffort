#!/usr/bin/env python3
"""Manually link the independent mutation test to an already built merged library."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[1]/'test/test_release044_composition.f90'
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def execute(argv,folder):
    try:
        p=subprocess.run(list(map(str,argv)),cwd=folder,stdin=subprocess.DEVNULL,capture_output=True,timeout=120)
        return dict(code=p.returncode,out=p.stdout.decode('utf8','surrogateescape'),err=p.stderr.decode('utf8','surrogateescape'),argv=list(map(str,argv)))
    except (OSError,subprocess.TimeoutExpired) as exc:return dict(code=None,out='',err=type(exc).__name__+': '+str(exc),argv=list(map(str,argv)))
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gfortran',required=True,type=Path)
    ap.add_argument('--module-dir',required=True,type=Path)
    ap.add_argument('--library',required=True,type=Path)
    ap.add_argument('--result',default='native-results.json',type=Path)
    a=ap.parse_args();compiler=a.gfortran.resolve(strict=True);modules=a.module_dir.resolve(strict=True);library=a.library.resolve(strict=True)
    paths=[SOURCE,library,*sorted(modules.glob('*.mod'))]
    if not list(modules.glob('fi_ir.mod')):ap.error('module directory does not contain fi_ir.mod')
    pins={str(p):digest(p) for p in paths};errors=[]
    flags=['-std=f2018','-pedantic-errors','-fcheck=all','-fbacktrace','-ffpe-trap=invalid,zero,overflow','-O0']
    with tempfile.TemporaryDirectory(prefix='release044-native-') as tmp:
        tmp=Path(tmp);binary=tmp/'test_release044_composition'
        build=execute([compiler,*flags,'-I',modules,SOURCE,library,'-o',binary],tmp)
        run=None
        if build['code']!=0 or build['out'] or build['err']:errors.append('native compile was not silent success')
        else:
            run=execute([binary],tmp)
            if run['code']!=0 or run['out'] or run['err']!='release044 composition native: 34 checks passed\n':errors.append('native result/status/diagnostic differs')
    errors += ['changed input '+p for p,h in pins.items() if digest(Path(p))!=h]
    result=dict(errors=errors,checks=34 if not errors else 0,source_sha256=pins[str(SOURCE)],library_sha256=pins[str(library)],input_hashes=pins,compile=build,run=run)
    (ROOT/a.result).write_text(json.dumps(result,indent=2)+'\n')
    print('release044 native: '+('FAIL '+str(errors) if errors else '34 checks passed'))
    return bool(errors)
if __name__=='__main__':raise SystemExit(main())
