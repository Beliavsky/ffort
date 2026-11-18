from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;cases=[]
def add(n,text,out='OK\n',stage='success',gnu='run'):
 p=R/'cases'/(n+'.f90');p.write_text(text);cases.append(dict(name=n,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage=stage,gnu=gnu,expected=out,diagnostic=None,integer_records=[]))
for rank in ['scalar','array']:
 dim='' if rank=='scalar' else '(:)'
 for inquiry,expr,expected in [('direct','len(x)',5),('constructor','len([x])',5),('zero_trip','len([(x,i=1,0)])',5)]:
  text='module m\ncontains\nsubroutine f(n)\ninteger,intent(in)::n\ninteger::i\ncharacter(n),allocatable::x'+dim+'\nif(allocated(x))stop 1\nwrite(*,"(i0)")'+expr+'\nend subroutine\nend module\nprogram p\nuse m\ncall f(5)\nend program\n'
  add('runtime_local_'+rank+'_'+inquiry,text,str(expected)+'\n')
  text='module m\ncontains\nsubroutine f(x)\ncharacter(*),allocatable,intent(in)::x'+dim+'\ninteger::i\nif(allocated(x))stop 1\nwrite(*,"(i0)")'+expr+'\nend subroutine\nend module\nprogram p\nuse m\ncharacter(5),allocatable::x'+dim+'\ncall f(x)\nend program\n'
  add('assumed_dummy_'+rank+'_'+inquiry,text,str(expected)+'\n')
 for inquiry,expr in [('direct','len(x)'),('constructor','len([x])'),('zero_trip','len([(x,i=1,0)])')]:
  text='program p\ncharacter(:),allocatable::x'+dim+'\ninteger::i\nwrite(*,"(i0)")'+expr+'\nend program\n'
  add('deferred_'+rank+'_'+inquiry,text,'',stage='runtime',gnu='compile')
for name in ['runtime_local_fixed_length','fixed_optional_unallocated']:
 p=R/'source'/(name+'.f90');cases.append(dict(name='original_'+name,source='source/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='success',gnu='run',expected='',diagnostic=None,integer_records=[]))
for c in cases:
 if c['stage']=='success' and c['name'].endswith('_zero_trip'):
  c['gnu']='compile';c['reason']='GNU14 zero-trip runtime length returns0; independent descriptor length5 oracle. Initial output retained.'
DIAGNOSTICS={'deferred_scalar_direct': '4:20: reference to unallocated array x', 'deferred_scalar_constructor': '4:21: reference to unallocated array x', 'deferred_scalar_zero_trip': '4:22: reference to unallocated array x', 'deferred_array_direct': '4:20: reference to unallocated array x', 'deferred_array_constructor': '4:21: reference to unallocated array x', 'deferred_array_zero_trip': '4:22: reference to unallocated array x'}
for c in cases:
 if c["name"] in DIAGNOSTICS:c["diagnostic"]=DIAGNOSTICS[c["name"]]
(R/'manifest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');print(len(cases),'cases')
