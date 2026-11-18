#!/usr/bin/env python3
"""Bounded RESHAPE: independent GNU oracle, literal expectations and safety negatives."""
import argparse, hashlib, json, re, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def run(cmd,cwd):
 p=subprocess.run([str(x) for x in cmd],cwd=cwd,text=True,capture_output=True,timeout=30)
 return dict(status=p.returncode,stdout=p.stdout,stderr=p.stderr)
def equal(a,b):
 a=a.lower().replace('d','e').split();b=b.lower().replace('d','e').split()
 if len(a)!=len(b):return False
 for x,y in zip(a,b):
  try:
   if x.lstrip('+-').isdigit() and y.lstrip('+-').isdigit():
    if int(x)!=int(y):return False
   elif float(x)!=float(y):return False
  except ValueError:
   if x!=y:return False
 return True

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path,required=True);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',default='results.json');args=ap.parse_args();args.candidate=args.candidate.resolve()
 # These three synthetic negatives exercise array-product policy, not PRINT's
 # independent cap. Derive their shape from the one configured source constant;
 # historical legal 131072-element positives below remain unchanged.
 limits=re.findall(r'(?m)^\s*integer,\s*parameter\s*::\s*max_array_elements\s*=\s*(\d+)\s*$',
                   (ROOT.parents[1]/'src/fi_ir.f90').read_text(),re.I)
 if len(limits)!=1 or not 0<int(limits[0])<2147483647:
  raise SystemExit('Expected one positive max_array_elements below default INTEGER HUGE')
 oversized_shape='['+limits[0]+',2]'
 original=(ROOT.parent/'utilities_slices/source_parts/routines/093_vector.f90').read_text()
 assert original in (ROOT/'original_vector.f90').read_text(), 'Original vector procedure changed'
 declarations=(ROOT/'demo_unpack_initializers.f90').read_bytes().split(b'program demo_unpack_initializers\n',1)[1].split(b'print *, mask\n',1)[0]
 assert hashlib.sha256(declarations).hexdigest()=='e5438c59ea98e1de242c70b5af67b382e183b2b743851d5898e92cdf60cae47b', 'Original demo_unpack declarations changed'
 cases=[]
 for name in ('basic','original_vector','procedures','initializers','demo_unpack_initializers'):
  cases.append((name,(ROOT/(name+'.f90')).read_text(),'pass',(ROOT/(name+'.out')).read_text()))
 for name,expr,diag in [
  ('scalar_source','reshape(1,[1])','SOURCE must be'),
  ('real_shape','reshape([1],[1.0])','SHAPE must be'),
  ('scalar_shape','reshape([1],1)','SHAPE must be'),
  ('rank_three','reshape([1],[1,1,1])','known size 1 or 2'),
  ('pad_type','reshape([1],[2],pad=[1.0])','PAD must be'),
  ('pad_kind','reshape([1],[2],pad=[1_8])','PAD must be'),
  ('scalar_pad','reshape([1],[2],pad=2)','PAD must be'),
  ('order_type','reshape([1],[1],order=[1.0])','ORDER must be'),
  ('order_scalar','reshape([1],[1],order=1)','ORDER must be'),
  ('order_length','reshape([1],[1],order=[1,2])','ORDER size'),
  ('unknown_keyword','reshape([1],[1],extra=[1])','Unknown keyword'),
  ('duplicate','reshape([1],[1],shape=[1])','Repeated actual'),
  ('missing_source','reshape(shape=[1])','Missing required'),
  ('missing_shape','reshape([1])','Missing required'),
  ('too_many','reshape([1],[1],[1],[1],[1])','Unknown keyword'),
  ('positional_after_keyword','reshape(source=[1],[1])','Positional argument'),
  ('char_length',"reshape(['ab'],[2],pad=['x'])",'lengths must match')]:
  cases.append((name,'program p\nprint *,'+expr+'\nend program\n','reject',diag))
 for name,decl,stmt,diag in [
  ('negative','integer::s(1)','s=[-1];print *,reshape([1],s)','nonnegative'),
  ('short_source','integer::s(1)','s=[3];print *,reshape([1,2],s)','SOURCE too small'),
  ('empty_pad','integer::s(1),z(0)','s=[3];print *,reshape([1],s,pad=z)','nonempty PAD'),
  ('duplicate_order','integer::o(2)','o=[1,1];print *,reshape([1,2],[1,2],order=o)','permutation'),
  ('low_order','integer::o(2)','o=[0,2];print *,reshape([1,2],[1,2],order=o)','permutation'),
  ('high_order','integer::o(2)','o=[1,3];print *,reshape([1,2],[1,2],order=o)','permutation'),
  ('zero_bad_order','integer::o(2),z(0)','o=[1,1];print *,size(reshape(z,[0,2],order=o))','permutation'),
  ('dynamic_order_size','integer::o(2),n','o=[1,2];n=1;print *,reshape([1,2],[1,2],order=o(:n))','ORDER size'),
  ('product_cap','integer::s(2)','s='+oversized_shape+';print *,size(reshape([1],s,pad=[1]))','element limit'),
  ('int64_overflow','integer(8)::s(2)','s=[9223372036854775807_8,9223372036854775807_8];print *,size(reshape([1],s,pad=[1]))','extent limit'),
  ('zero_huge','integer(8)::s(2)','s=[0_8,9223372036854775807_8];print *,size(reshape([1],s))','extent limit'),
  ('undefined_shape','integer::s(1)','print *,size(reshape([1],s))','uninitialized'),
  ('undefined_source','integer::s(1)','print *,reshape(s,[1])','uninitialized'),
  ('undefined_pad','integer::s(1)','print *,reshape([1],[2],pad=s)','uninitialized')]:
  cases.append((name,'program p\nimplicit none\n'+decl+'\n'+stmt+'\nend program\n','runtime',diag))
 for nrow in range(1,5):
  for ncol in range(1,4):
   for order in ('1,2','2,1'):
    label='mapping_%s_%s_%s'%(nrow,ncol,order.replace(',',''))
    shape='%s,%s'%(nrow,ncol)
    source='program p\nprint *,reshape([1,2,3],['+shape+'],pad=[7,8],order=['+order+'])\nend program\n'
    cases.append((label,source,'pass',''))
 cases.append(('optional_pad', 'module m\ncontains\nsubroutine f(pad)\ninteger,optional,intent(in)::pad(:)\ninteger::a(2)\na=reshape([1],[2],pad=pad)\nend subroutine\nend module\nprogram p\nend program\n','reject','RESHAPE direct OPTIONAL PAD or ORDER is unsupported'))
 cases.append(('parameter_initializer',(ROOT/'parameter.f90').read_text(),'pass','1 3 2 4 1 3 2 4'))
 for mode in ('mutable','parameter'):
  attr=',parameter' if mode=='parameter' else ''
  for name,bounds,expr,diag in [
   ('swapped_dimensions','2,3','reshape([1,2,3,4,5,6],[3,2])','shapes do not conform'),
   ('empty_dimensions','0,2','reshape([1],[0,3])','shapes do not conform'),
   ('negative_shape','1,1','reshape([1],[-1,1])','nonnegative'),
   ('too_few_values','2,2','reshape([1],[2,2])','SOURCE too small'),
   ('bad_order','2,2','reshape([1,2,3,4],[2,2],order=[1,1])','permutation'),
   ('empty_bad_order','0,2','reshape([1],[0,2],order=[1,1])','permutation'),
   ('oversized_shape','1,1','reshape([1],'+oversized_shape+',pad=[1])','element limit'),
   ('empty_huge_shape','0,1','reshape([1],[0_8,9223372036854775807_8])','extent limit'),
   ('nonconstant_shape','1,1','reshape([1],[n,1])','constant expressions'),
   ('nested_bad_shape','2,2','reshape([1,2,3,4],[2,2])+reshape([1,2,3,4],[1,4])','shapes do not conform')]:
   source='program p\ninteger::n=1\ninteger'+attr+'::a('+bounds+')='+expr+'\nprint *,a\nend program\n'
   cases.append((mode+'_'+name,source,'reject',diag))
 for mode in ('mutable','parameter'):
  attr=',parameter' if mode=='parameter' else ''
  source='program p\ninteger,parameter::m(2,3)=1\ninteger'+attr+'::a(3,2)=m(:,:)\nprint *,a\nend program\n'
  cases.append((mode+'_section_swapped_dimensions',source,'reject','shapes do not conform'))
 cases.append(('unknown_shape_size','program p\ninteger::s(2),n\ns=[1,2];n=2\nprint *,reshape([1,2],s(:n))\nend program\n','reject','known size 1 or 2'))
 cases.append(('initializer_cap_boundary','program p\ninteger,parameter::a(512,256)=reshape([1],[512,256],pad=[2])\nprint *,size(a),sum(a)\nend program\n','pass','131072 262143'))
 cases.append(('cap_boundary','program p\ninteger::a(131072)\na=reshape([1],[131072],pad=[2])\nprint *,size(a),sum(a)\nend program\n','pass','131072 262143'))
 cases.append(('zero_unused_values','program p\ninteger::a(1),z(0)\nprint *,size(reshape(a,[0],pad=z)),kind(reshape(a,[1]))\nend program\n','pass','0 4'))
 results=[]
 with tempfile.TemporaryDirectory(prefix='reshape-') as td:
  tmp=Path(td)
  for name,source,expected,diag in cases:
   src=tmp/(name+'.f90');src.write_text(source);exe=tmp/'oracle'
   compiler_limit=['-fmax-array-constructor=131072'] if name=='initializer_cap_boundary' else []
   g=run([args.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all',*compiler_limit,src,'-o',exe],tmp)
   # Invalid/safety sources are not executed by the compiler oracle.
   o=run([exe],tmp) if expected=='pass' and g['status']==0 else None
   check=run([args.candidate,'--check',src],tmp);r=run([args.candidate,src],tmp)
   if expected=='pass':ok=g['status']==0 and o['status']==0 and check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==0 and not r['stderr'] and equal(r['stdout'],o['stdout']) and (not diag or equal(r['stdout'],diag))
   elif expected=='reject':ok=check['status']==1 and r['status']==1 and not r['stdout'] and not check['stdout'] and diag.lower() in check['stderr'].lower() and diag.lower() in r['stderr'].lower()
   else:ok=check['status']==0 and not check['stdout'] and not check['stderr'] and r['status']==2 and not r['stdout'] and diag.lower() in r['stderr'].lower()
   results.append(dict(name=name,expected=expected,pass_=ok,gfortran=g,oracle=o,check=check,candidate=r))
   print(('PASS' if ok else 'FAIL')+': '+name,flush=True)
 result=dict(candidate_sha256=hashlib.sha256(args.candidate.read_bytes()).hexdigest(),total=len(results),failed=sum(not c['pass_'] for c in results),cases=results)
 out=Path(args.result);out=out if out.is_absolute() else ROOT/out;out.write_text(json.dumps(result,indent=2)+'\n');print('Total:',result['total'],'failed:',result['failed']);return bool(result['failed'])
if __name__=='__main__':raise SystemExit(main())
