#!/usr/bin/env python3
"""Independent bounded REAL(A[, KIND]) GNU differential source suite.

The GNU oracle runs only standard-conforming, defined positive inputs. For
invalid source, unsupported kinds, undefined operands and narrowing overflow it
is compile-only. Native public-IR mutation tests are maintained separately.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def program(declarations, statements):
    return 'program p\nimplicit none\n'+declarations+'\n'+statements+'\nend program p\n'


def source_cases():
    cases = []
    def add(name, source, mode='pass', diagnostic=''):
        cases.append(dict(name=name, source=source, mode=mode, diagnostic=diagnostic))
    add('scalars', program('integer :: i=42\ninteger(8)::j=9007199254740993_8\n'
                          'real(4)::a=1.25\nreal(8)::b=1.23456789012345_8',
        'print *,real(i),real(i,8),real(i,4)\n'
        'print *,real(j,8)==9007199254740992.0_8\n'
        'print *,real(a),real(a,8),real(b,8)\n'
        'print *,kind(real(b)),kind(real(b,8)),kind(real(a,8)),kind(real(i,4))\n'
        'print *,real(real(b),8)==1.2345678806304931640625_8\n'
        'print *,real(16777217,4)==16777216.0_4\n'
        'print *,real(-0.0_8,4),real(-0.0_4,8),real(tiny(0.0_4),8),real(tiny(0.0_8),8)'))
    add('keyword_reordering', program('integer,parameter::dp=kind(1.0d0)',
        'print *,real(a=17),real(a=17,kind=dp),real(kind=dp,a=17)\n'
        'print *,kind(real(kind=dp,a=1.0)),kind(real(1d0,kind=4))'))
    add('parameter_constants', program('integer,parameter::dp=kind(1.0d0),sp=dp/2\n'
        'real(dp),parameter::a=real(7,dp),b=real(a=a+1,kind=sp)\n'
        'real,parameter::c=real(16777217)\n'
        'integer,parameter::k=kind(real(1d0)),j=kind(real(1,dp))',
        'print *,a,b,c,k,j\nprint *,c==16777216.0'))
    add('rank1', program('integer::i(4)=[-2,0,1,16777217]\nreal(4)::a(4)\nreal(8)::b(4)',
        'a=real(i)\nb=real(i,8)\nprint *,kind(real(i)),size(real(i)),a,b\n'
        'print *,kind(real(i,8)),sum(real(i,8))\n'
        'print *,real([1,2,3],kind=8)\nprint *,real(kind=4,a=b)==a'))
    add('rank2', program('integer::i(2,2)\nreal(4)::a(2,2)\nreal(8)::b(2,2)',
        'i=reshape([1,2,3,16777217],[2,2])\na=real(i,4)\nb=real(i,8)\n'
        'print *,shape(real(i,8)),kind(real(i,8)),sum(b),sum(a)\n'
        'print *,b(:,1),b(:,2)\nprint *,real(b,4)==a'))
    add('rank3', program('integer::i(2,2,2)\nreal(4)::a(2,2,2)\nreal(8)::b(2,2,2)',
        'i(:,:,1)=reshape([1,2,3,4],[2,2])\ni(:,:,2)=reshape([5,6,7,8],[2,2])\n'
        'a=real(i)\nb=real(i,8)\n'
        'print *,shape(real(i,8)),kind(real(i,8)),sum(a(:,:,1)),sum(b(:,:,2))\n'
        'print *,b(:,:,1),b(:,:,2)\nprint *,real(b(2,2,2),4)==a(2,2,2)'))
    add('empty_arrays', program('integer::i(0),j(0,2),k(2,0,2)\nreal(8)::a(0),b(0,2),c(2,0,2)',
        'a=real(i,8)\nb=real(j,8)\nc=real(k,8)\n'
        'print *,size(real(i,8)),size(real(j,8)),size(real(k,8))\n'
        'print *,shape(b),shape(c),sum(a),sum(b),size(c)\n'
        'print *,kind(real(i)),kind(real(j,8)),kind(real(k,8))'))
    add('array_kinds', program('real(4)::a(3)=[1.25,-2.5,4.0]\nreal(8)::b(3),c(3)',
        'b=real(a,8)\nc=[1.23456789012345_8,2.0_8,3.0_8]\n'
        'print *,real(a,4),real(a,8),real(b),real(b,8)\n'
        'print *,real(real(c,4),8)\n'
        'print *,real(c(1),4)==1.2345678806304931640625_8'))
    add('iso_kind_aliases', 'program p\nuse, intrinsic :: iso_fortran_env, only: sp=>real32, dp=>real64\n'
        'implicit none\nreal(dp)::x=1.23456789012345_dp\n'
        'print *,kind(real(x,sp)),kind(real(17,dp)),real(kind=dp,a=17)\nend program p\n')
    add('module_kind_parameters', 'module constants\nimplicit none\ninteger,parameter::dp=kind(1d0)\n'
        'contains\nfunction convert(i) result(x)\ninteger,intent(in)::i\nreal(dp)::x\n'
        'x=real(i,dp)\nend function\nend module\nprogram p\nuse constants\nimplicit none\n'
        'print *,convert(17),kind(real(1,dp))\nend program\n')
    add('non_evaluation', program('real(8)::x,a(3),z=0.0_8\nreal(8),allocatable::b(:)\ninteger::i',
        'print *,kind(real(x)),kind(real(a,8)),kind(real(i,8))\n'
        'print *,kind(real(b,4)),kind(real(1.0_8/z,4))'))
    add('sliced_arrays', program('integer::i(5)=[1,2,3,4,5]\nreal(8)::a(3)',
        'a=real(i(5:1:-2),8)\nprint *,a,real(i(2:4),kind=8)\n'
        'print *,kind(real(i(5:1:-2),8)),sum(real(i(5:1:-2),8))'))
    add('integer8_double_rounding', program(
        'integer(8)::j(2)=[4611686293305294849_8,-4611686293305294849_8]\n'
        'real(4)::a(2)\n'
        'real(4),parameter::pos=real(4611686293305294849_8,4)\n'
        'real(4),parameter::neg=real(-4611686293305294849_8,4)',
        'a=real(j,4)\nprint *,a,pos,neg\n'
        'print *,all(real(j,4)/=real(real(j,8),4))\n'
        'print *,real(j(1),4)==pos,real(j(2))==neg\n'
        'print *,pos==4611686568183201792.0_4,neg==-4611686568183201792.0_4'))
    add('assignment_aliasing', program(
        'real(8)::a(3)=[1.23456789012345_8,2.0_8,3.123456789012345_8]\n'
        'real(4)::b(4)=[1.0,2.0,3.0,4.0]',
        'a=real(a(3:1:-1),4)\nprint *,a\n'
        'b=real(b(4:1:-1),8)\nprint *,b\n'
        'b(2:4)=real(b(1:3),8)\nprint *,b'))
    invalid = [
        ('empty','real()','requires'),
        ('excess','real(1,4,8)','requires'),
        ('unknown_keyword','real(x=1)','Unknown keyword'),
        ('missing_a','real(kind=8)','Missing'),
        ('duplicate_a','real(a=1,a=2)','Repeated'),
        ('duplicate_kind','real(1,kind=4,kind=8)','requires'),
        ('positional_after_keyword','real(a=1,8)','Positional'),
        ('logical_a','real(.true.)','INTEGER or REAL'),
        ('character_a',"real('1')",'INTEGER or REAL'),
        ('real_kind','real(1,kind=4.0)','INTEGER'),
        ('logical_kind','real(1,kind=.true.)','INTEGER'),
        ('character_kind',"real(1,kind='4')",'INTEGER'),
        ('array_kind','real(1,kind=[4])','scalar'),
    ]
    for name, expression, diagnostic in invalid:
        add('invalid_'+name,program('', 'print *,123, '+expression),'reject',diagnostic)
    add('invalid_variable_kind',program('integer::k=8','print *,123,real(1,k)'), 'reject','constant')
    for k in [-1,0,1,2,3,7,99]:
        add('invalid_kind_'+str(k).replace('-','neg'),program('',f'print *,123,real(1,kind={k})'),'reject','kind')
    for k in [10,16]:
        add('unsupported_result_kind_'+str(k),program('',f'print *,123,real(1,kind={k})'),'unsupported','kind')
    add('unsupported_real16_input',program('real(16)::x=1.0_16','print *,123,real(x,8)'), 'unsupported')
    add('unsupported_integer2_input',program('integer(2)::x=1_2','print *,123,real(x,8)'), 'unsupported')
    add('unsupported_complex',program('complex::z=(1.0,2.0)','print *,123,real(z)'), 'unsupported')
    add('runtime_uninitialized',program('real(8)::x','print *,123,real(x,8)'), 'runtime','uninitialized')
    add('runtime_narrow_overflow',program('real(8)::x=1.0e100_8','print *,123,real(x,4)'), 'runtime','overflow')
    return cases


def run(command, cwd):
    command=[str(x) for x in command]
    try:
        p=subprocess.run(command,cwd=cwd,text=True,capture_output=True,timeout=60)
        return dict(command=command,status=p.returncode,stdout=p.stdout,stderr=p.stderr)
    except subprocess.TimeoutExpired as exc:
        def decoded(value):
            return value.decode(errors='replace') if isinstance(value,bytes) else (value or '')
        return dict(command=command,status=None,stdout=decoded(exc.stdout),
                    stderr=decoded(exc.stderr)+'\nProcess timed out',timeout=True)
    except OSError as exc:
        return dict(command=command,status=None,stdout='',stderr=str(exc),launch_error=True)


def equal(candidate, oracle):
    a=candidate.split()
    b=oracle.split()
    if len(a)!=len(b):
        return False
    for x,y in zip(a,b):
        ix=bool(re.fullmatch(r'[+-]?\d+',x))
        iy=bool(re.fullmatch(r'[+-]?\d+',y))
        # An INTEGER field cannot silently match a REAL-formatted value.
        if ix or iy:
            if not (ix and iy) or int(x)!=int(y):
                return False
            continue
        try:
            fx=float(x.replace('D','E').replace('d','e'))
            fy=float(y.replace('D','E').replace('d','e'))
            if not math.isfinite(fx) or not math.isfinite(fy):
                return False
            if fx==0 and fy==0 and math.copysign(1.0,fx)!=math.copysign(1.0,fy):
                return False
            # GNU's default REAL(4) list formatting has at least 8 significant
            # digits. Exact narrowing behavior is checked by LOGICAL assertions.
            # No absolute tolerance: loss of even subnormal values must fail.
            if not math.isclose(fx,fy,rel_tol=3e-8,abs_tol=0.0):
                return False
        except ValueError:
            # Character/text output is case-sensitive; D/E normalization is
            # exclusively numeric and cannot mask changes to words.
            if x!=y:
                return False
    return True


def process_ok(result, expected_status, quiet_stdout=False, quiet_stderr=False, diagnostic=False):
    if result is None or result.get('timeout') or result.get('launch_error'):
        return False
    if result.get('status')!=expected_status:
        return False
    if quiet_stdout and result['stdout']:
        return False
    if quiet_stderr and result['stderr']:
        return False
    if diagnostic and not result['stderr'].strip():
        return False
    return True


def verify_case(case,g,oracle,check=None,result=None):
    mode=case['mode']
    if mode=='reject':
        if (g.get('status') is None or g['status']<=0 or g.get('timeout') or g.get('launch_error')
                or not g['stderr'].strip() or g['stdout'] or oracle is not None):
            return False
    else:
        if not process_ok(g,0,quiet_stdout=True):
            return False
        if mode=='pass':
            if not process_ok(oracle,0,quiet_stderr=True):
                return False
        elif oracle is not None:
            return False
    if check is None:
        return result is None
    if mode=='pass':
        return (process_ok(check,0,quiet_stdout=True,quiet_stderr=True)
                and process_ok(result,0,quiet_stderr=True)
                and equal(result['stdout'],oracle['stdout']))
    if mode in ['reject','unsupported']:
        return (process_ok(check,1,quiet_stdout=True,diagnostic=True)
                and process_ok(result,1,quiet_stdout=True,diagnostic=True))
    return (process_ok(check,0,quiet_stdout=True,quiet_stderr=True)
            and process_ok(result,2,quiet_stdout=True,diagnostic=True)
            and case['diagnostic'].lower() in result['stderr'].lower())


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate',type=Path)
    parser.add_argument('--gfortran',default='gfortran')
    parser.add_argument('--result',type=Path,default=ROOT/'results.json')
    parser.add_argument('--source-dir',type=Path,default=ROOT/'sources')
    args=parser.parse_args()
    compiler=shutil.which(args.gfortran) or args.gfortran
    if args.candidate:
        args.candidate=args.candidate.resolve()
    args.source_dir.mkdir(parents=True,exist_ok=True)
    records=[]
    with tempfile.TemporaryDirectory(prefix='real-conversion-') as folder:
        work=Path(folder)
        for case in source_cases():
            source=(args.source_dir/(case['name']+'.f90')).resolve()
            source.write_text(case['source'])
            exe=work/'oracle'
            g=run([compiler,'-std=f2018','-pedantic-errors','-fcheck=all','-fbacktrace',source,'-o',exe],work)
            oracle=run([exe],work) if g['status']==0 and case['mode']=='pass' else None
            check=run([args.candidate,'--check',source],work) if args.candidate else None
            result=run([args.candidate,source],work) if args.candidate else None
            passed=verify_case(case,g,oracle,check,result)
            record=dict(name=case['name'],mode=case['mode'],source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                        pass_=passed,gfortran=g,oracle=oracle,check=check,candidate=result)
            records.append(record)
            print(('PASS' if passed else 'FAIL')+': '+case['name'],flush=True)
    summary=dict(total=len(records),failed=sum(not c['pass_'] for c in records),
                 gnu_only=not bool(args.candidate),candidate=str(args.candidate) if args.candidate else None,
                 candidate_sha256=hashlib.sha256(args.candidate.read_bytes()).hexdigest() if args.candidate else None,
                 gnu_flags=['-std=f2018','-pedantic-errors','-fcheck=all','-fbacktrace'],
                 cases=records)
    args.result.parent.mkdir(parents=True,exist_ok=True)
    args.result.write_text(json.dumps(summary,indent=2)+'\n')
    print('Total:',summary['total'],'failed:',summary['failed'],flush=True)
    return bool(summary['failed'])


if __name__=='__main__':
    raise SystemExit(main())
