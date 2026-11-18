#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,argparse
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--original-source',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');a=ap.parse_args();original=a.original_source.read_bytes();lines=original.splitlines(keepends=True);body=b''.join(lines[1040:1048]);assert body.startswith(b'pure function repeat_char') and body.rstrip().endswith(b'end function repeat_char')
(ROOT/'cases').mkdir(exist_ok=True);cases=[]
def add(name,source,stdout='OK\n',stage='success',gnu='run',tier='core',reason=''):
 data=source.encode() if isinstance(source,str) else source;(ROOT/'cases'/(name+'.f90')).write_bytes(data);cases.append(dict(name=name,source='cases/'+name+'.f90',sha256=hashlib.sha256(data).hexdigest(),stage=stage,gnu=gnu,expected_stdout=stdout,tier=tier,reason=reason,diagnostic=None))
def prog(decl,code):return 'program p\nimplicit none\n'+decl+'\n'+code+'\nend program\n'
def module(decl,code,main,extra=''):
 return 'module m\nimplicit none\ncontains\nsubroutine f(x)\n'+decl+'\n'+code+'\nend subroutine\n'+extra+'end module\nprogram p\nuse m\nimplicit none\n'+main+'\nend program\n'
# Original source body bytes and CRLF preserved in every wrapper.
for name,value,n in [('word','ab',3),('single','Z',1),('zero_length','',4),('trailing_blanks','a  ',2),('zero_count','abc',0),('negative_count','abc',-2)]:
 prefix=b'module original_m\r\nimplicit none\r\ncontains\r\n';suffix=('subroutine check(x,n)\ncharacter(*),intent(in)::x\ninteger,intent(in)::n\ncharacter(len=len(x))::v(max(0,n))\nv=repeat_char(n,x)\nif(size(v)/=max(0,n).or.len(v)/=len(x))stop 1\nif(any(v/=x))stop 2\nwrite(*,"(i0,1x,i0)")size(v),len(v)\nwrite(*,"(*(a))")v\nend subroutine\nend module\nprogram p\nuse original_m\nimplicit none\ncall check('+repr(value).replace('"',"'")+','+str(n)+')\nend program\n').encode().replace(b'\n',b'\r\n')
 add('original_repeat_'+name,prefix+body+suffix,f'{max(0,n)} {len(value)}\n'+value*max(0,n)+'\n')
scalar='character(*),intent(in)::x\ninteger::i,j\ncharacter(len(x))::y(3)'
add('assumed_scalar_bracket',module(scalar,"y=[(x,i=1,3)]\nif(any(y/=x).or.len(y)/=len(x))stop 1\nwrite(*,'(*(a))')y","call f('ab ')") ,'ab ab ab \n')
add('assumed_scalar_legacy',module(scalar,"y=(/(x,i=1,3)/)\nif(any(y/=x))stop 1\nprint '(a)','OK'","call f('abcd')"))
add('assumed_scalar_plain',module(scalar,"y=[x,x,x]\nif(any(y/=x))stop 1\nprint '(a)','OK'","call f('ab')"))
add('assumed_scalar_siblings',module(scalar,"y=[(x,i=1,1),(x,i=1,2)]\nif(any(y/=x))stop 1\nprint '(a)','OK'","call f('ab')"))
add('assumed_scalar_nested',module('character(*),intent(in)::x\ninteger::i,j\ncharacter(len(x))::y(6)',"y=[((x,j=1,2),i=1,3)]\nif(any(y/=x))stop 1\nwrite(*,'(*(a))')y","call f('Q ')") ,'Q Q Q Q Q Q \n')
add('assumed_scalar_reverse',module(scalar,"y=[(x,i=3,1,-1)]\nif(any(y/=x))stop 1\nprint '(a)','OK'","call f('abc')"))
add('assumed_scalar_empty_len',module('character(*),intent(in)::x\ninteger::i',"if(size([(x,i=1,0)])/=0.or.len([(x,i=1,0)])/=len(x))stop 1\nprint '(a)','OK'","call f('abc')"))
add('assumed_undefined_empty',module('character(*),intent(in)::x\ninteger::i',"if(size([(x,i=1,0)])/=0.or.len([(x,i=1,0)])/=7)stop 1\nprint '(a)','OK'","character(7)::a\ncall f(a)"))
add('assumed_undefined_len_only',module('character(*),intent(in)::x\ninteger::i',"if(len([(x,i=1,3)])/=7)stop 1\nprint '(a)','OK'","character(7)::a\ncall f(a)"))
add('assumed_different_calls',module(scalar,"y=[(x,i=1,3)]\nif(any(y/=x).or.len(y)/=len(x))stop 1\nwrite(*,'(i0)')len(y)","call f('x')\ncall f('abcde')\ncall f('')"),'1\n5\n0\n')
arr='character(*),intent(in)::x(:)\ninteger::i\ncharacter(len(x))::y(2*size(x))'
add('assumed_array_leaf',module(arr,"y=[(x,i=1,2)]\nif(size(y)/=4.or.any(y/=['ab','cd','ab','cd']))stop 1\nwrite(*,'(*(a))')y","call f(['ab','cd'])"),'abcdabcd\n')
add('assumed_array_plain_empty',module('character(*),intent(in)::x(:)',"if(size([x])/=0.or.len([x])/=7)stop 1\nprint '(a)','OK'","character(7)::a(0)\ncall f(a)"))
add('assumed_array_empty_leaf',module(arr,"y=[(x,i=1,2)]\nif(size(y)/=0.or.len(y)/=7)stop 1\nprint '(a)','OK'","character(7)::a(0)\ncall f(a)"))
add('zero_length_array_leaf',module(arr,"y=[(x,i=1,2)]\nif(size(y)/=4.or.len(y)/=0)stop 1\nprint '(a)','OK'","character(0)::a(2)\na=''\ncall f(a)"))
for n in [0,1,5]:
 add('allocated_scalar_len'+str(n),prog('character(:),allocatable::x,y(:)\ninteger::i',f'allocate(character({n})::x)\nx=repeat("a",{n})\ny=[(x,i=1,3)]\nif(len(y)/={n}.or.size(y)/=3.or.any(y/=x))stop 1\nprint "(a)","OK"'))
add('allocated_scalar_reallocate',prog('character(:),allocatable::x,y(:)\ninteger::i','x="ab"\ny=[(x,i=1,2)]\nif(len(y)/=2)stop 1\nx="Q"\ny=[(x,i=1,3)]\nif(len(y)/=1.or.size(y)/=3.or.any(y/="Q"))stop 2\nprint "(a)","OK"'))
add('allocated_array_leaf',prog('character(:),allocatable::x(:),y(:)\ninteger::i','allocate(character(3)::x(2))\nx=["one","two"]\ny=[(x,i=1,2)]\nif(size(y)/=4.or.len(y)/=3)stop 1\nwrite(*,"(*(a))")y'),'onetwoonetwo\n')
add('allocated_array_empty',prog('character(:),allocatable::x(:),y(:)\ninteger::i','allocate(character(9)::x(0))\ny=[x]\nif(size(y)/=0.or.len(y)/=9)stop 1\nprint "(a)","OK"'))
add('allocated_empty_trip_scalar',prog('character(:),allocatable::x,y(:)\ninteger::i','allocate(character(5)::x)\nx="hello"\ny=[(x,i=1,0)]\nif(size(y)/=0.or.len(y)/=5)stop 1\nprint "(a)","OK"'))
add('fixed_and_dynamic_equal',module('character(*),intent(in)::x\ncharacter(3)::a(3)\ninteger::i','a=["abc",(x,i=1,2)]\nif(any(a/="abc"))stop 1\nprint "(a)","OK"','call f("abc")'))
add('dynamic_descriptors_equal', 'module m\ncontains\nsubroutine f(x,z)\ncharacter(*),intent(in)::x,z\ncharacter(len(x))::a(3)\ninteger::i\na=[x,(z,i=1,2)]\nif(any(a/="abc"))stop 1\nprint "(a)","OK"\nend subroutine\nend module\nprogram p\nuse m\ncall f("abc","abc")\nend program\n')
add('allocated_source_alias',prog('character(:),allocatable::x(:)\ninteger::i','x=["ab","cd"]\nx=[(x,i=1,2)]\nif(size(x)/=4.or.len(x)/=2)stop 1\nwrite(*,"(*(a))")x'),'abcdabcd\n')
add('counter_preserved',module('character(*),intent(in)::x\ninteger::i\ncharacter(len(x))::a(2)','i=77\na=[(x,i=1,2)]\nif(i/=77.or.any(a/=x))stop 1\nprint "(a)","OK"','call f("a")'))
# Semantically valid but potentially out-of-scope expression forms; separate tier.
for name,expr in [('element','x(i)'),('section','x(:)'),('concat','x(1)//x(2)')]:
 decl='character(*),intent(in)::x(:)\ninteger::i\ncharacter(4)::a(2)'
 code=f'a=[({expr},i=1,2)]\nwrite(*,"(*(a))")a'
 if name=='section':decl='character(*),intent(in)::x(:)\ninteger::i\ncharacter(2)::a(4)'
 add('descriptor_'+name,module(decl,code,'call f(["ab","cd"])'),stdout={'element':'ab  cd  \n','section':'abcdabcd\n','concat':'abcdabcd\n'}[name],tier='core')
add('descriptor_concat_zero_trip',module('character(*),intent(in)::x\ninteger::i','if(len([(x//x,i=1,0)])/=2*len(x))stop 1\nprint "(a)","OK"','call f("abc")'))
add('descriptor_concat_mixed',module('character(*),intent(in)::x\ninteger::i\ncharacter(len(x)+1)::a(2)','a=[(x//"!",i=1,2)]\nwrite(*,"(*(a))")a','call f("ab")'),'ab!ab!\n')
add('nested_constructor_length',module('character(*),intent(in)::x\ninteger::i,j\ncharacter(len(x))::a(4)','a=[([x,x],i=1,2)]\nif(any(a/=x))stop 1\nwrite(*,"(*(a))")a','call f("Q ")'),'Q Q Q Q \n')
add('nested_constructor_empty',module('character(*),intent(in)::x\ninteger::i,j','if(size([([(x,j=1,0)],i=1,2)])/=0)stop 1\nif(len([([(x,j=1,0)],i=1,2)])/=len(x))stop 2\nprint "(a)","OK"','call f("abc")'),gnu='compile',reason='Independent length oracle; GNU14 empty-array nested length limitation retained separately.')
add('array_zero_trip_length',module('character(*),intent(in)::x(:)\ninteger::i','if(size([(x,i=1,0)])/=0.or.len([(x,i=1,0)])/=7)stop 1\nprint "(a)","OK"','character(7)::a(0)\ncall f(a)'),gnu='compile',reason='Independent §7.8 type-parameter oracle; GNU14 reports length0, see gnu-semantics.json.')
add('undefined_loop_bound_len',module('character(*),intent(in)::x\ninteger::i,n','if(len([(x,i=1,n)])/=len(x))stop 1\nprint "(a)","OK"','call f("abc")'))
add('automatic_local_length','module m\ncontains\nsubroutine f(n)\ninteger,intent(in)::n\ncharacter(n)::x,y(2)\ninteger::i\nx=repeat("Q",n)\ny=[(x,i=1,2)]\nif(any(y/=x).or.len(y)/=n)stop 1\nprint "(a)","OK"\nend subroutine\nend module\nprogram p\nuse m\ncall f(4)\nend program\n')
add('optional_present_descriptor','module m\ncontains\nsubroutine f(x)\ncharacter(*),optional,intent(in)::x\ninteger::i\nif(present(x))then\n if(len([(x,i=1,0)])/=3)stop 1\nend if\nprint "(a)","OK"\nend subroutine\nend module\nprogram p\nuse m\ncall f("abc")\nend program\n')
add('optional_absent_descriptor','module m\ncontains\nsubroutine f(x)\ncharacter(*),optional,intent(in)::x\ninteger::i\nprint *,len([(x,i=1,0)])\nend subroutine\nend module\nprogram p\nuse m\ncall f()\nend program\n',stdout='',stage='runtime',gnu='compile',reason='Absent OPTIONAL descriptor cannot supply a runtime length.')
add('allocated_undefined_len',prog('character(:),allocatable::x\ninteger::i','allocate(character(8)::x)\nif(len([(x,i=1,3)])/=8)stop 1\nprint "(a)","OK"'))
add('allocated_uninitialized_empty',prog('character(:),allocatable::x,y(:)\ninteger::i','allocate(character(8)::x)\ny=[(x,i=1,0)]\nif(size(y)/=0.or.len(y)/=8)stop 1\nprint "(a)","OK"'))
add('descriptor_length_limit_exact',module('character(*),intent(in)::x\ninteger::i','if(len([(x,i=1,0)])/=65536)stop 1\nprint "(a)","OK"','character(65536)::a\ncall f(a)'))
add('unallocated_empty_trip',prog('character(:),allocatable::x,y(:)\ninteger::i','y=[(x,i=1,0)]'),stdout='',stage='runtime',gnu='compile',reason='Empty result still requires allocated deferred length descriptor.')
# Invalid at execution, not a GNU execution oracle. Exact candidate diagnostics pending implementation.
add('runtime_mismatch', 'module m\ncontains\nsubroutine f(x,z)\ncharacter(*),intent(in)::x,z\ncharacter(8)::a(2)\na=[x,z]\nprint "(a)","UNREACHED"\nend subroutine\nend module\nprogram p\nuse m\ncall f("a","bb")\nend program\n',stdout='',stage='runtime',gnu='compile',reason='Untyped ac-value lengths must match; GNU is compile-only.')
add('unallocated_scalar',prog('character(:),allocatable::x,y(:)\ninteger::i','y=[(x,i=1,2)]'),stdout='',stage='runtime',gnu='compile',reason='Required deferred-length descriptor is unavailable.')
add('unallocated_array',prog('character(:),allocatable::x(:),y(:)\ninteger::i','y=[(x,i=1,2)]'),stdout='',stage='runtime',gnu='compile',reason='Required deferred-length descriptor is unavailable.')
add('undefined_nonempty',module('character(*),intent(in)::x\ncharacter(len(x))::a(2)\ninteger::i','a=[(x,i=1,2)]\nprint "(a)","UNREACHED"','character(7)::a\ncall f(a)'),stdout='',stage='runtime',gnu='compile',reason='Data use is undefined although descriptor length exists.')
add('dynamic_trim_boundary',module('character(*),intent(in)::x\ninteger::i\ncharacter(8)::a(2)','a=[(trim(x),i=1,2)]\nprint "(a)","UNREACHED"','call f("ab ")'),stdout='',stage='reject',gnu='compile',reason='Valid nonempty dynamic value-dependent length, outside descriptor-only proposal.')
add('index_length_boundary',prog('character(5)::x(3)\ninteger::i','x=[(repeat("a",i),i=1,3)]'),stdout='',stage='reject',gnu='compile',reason='Varying lengths violate untyped constructor requirements; no GNU execution.')
add('mismatch_empty_branch','module m\ncontains\nsubroutine f(x,z)\ncharacter(*),intent(in)::x,z\ninteger::i\ncharacter(8)::a(1)\na=[(x,i=1,0),z]\nend subroutine\nend module\nprogram p\nuse m\ncall f("a","bb")\nend program\n',stdout='',stage='runtime',gnu='compile',reason='All ac-value length parameters must agree even for an empty impliedDO branch.')
add('mismatch_empty_array','module m\ncontains\nsubroutine f(x,z)\ncharacter(*),intent(in)::x(:),z\ncharacter(8)::a(1)\na=[x,z]\nend subroutine\nend module\nprogram p\nuse m\ncharacter(7)::x(0)\ncall f(x,"bb")\nend program\n',stdout='',stage='runtime',gnu='compile',reason='Empty rank-one ac-value still carries a length parameter.')
add('runtime_concat_length_cap',module('character(*),intent(in)::x\ninteger::i','print *,len([(x//x,i=1,0)])','character(32769)::a\ncall f(a)'),stdout='',stage='runtime',gnu='compile',reason='Descriptor sum exceeds unchanged65536 character-length cap; no data read required.')
add('runtime_constructor_byte_cap',prog('character(:),allocatable::x,y(:)\ninteger::i','allocate(character(65536)::x)\nx=repeat("a",65536)\ny=[(x,i=1,257)]'),stdout='',stage='runtime',gnu='compile',reason='Emitted CHARACTER payload exceeds16MiB existing constructor cap.')
# Exact original vector helper and its complete original dependency.
def extract_function(name):
 start=next(i for i,line in enumerate(lines) if line.strip().lower().startswith((('function '+name+'(').encode(),('pure function '+name+'(').encode())))
 end=next(i for i in range(start,len(lines)) if lines[i].strip().lower()==('end function '+name).encode())
 return b''.join(lines[start:end+1]),[start+1,end+1]
vecbody,vecrange=extract_function('repeat_char_vec')
depbody,deprange=extract_function('present_and_false')
vecnames=[]
for mode in ('absent','true','false'):
 for shape in ('trailing','zero_count','zero_size','zero_length'):
  name='original_repeat_vec_'+mode+'_'+shape;vecnames.append(name)
  n=0 if shape=='zero_count' else 2
  if shape=='zero_size':decl='character(3)::a(0)';values=[];width=3
  elif shape=='zero_length':decl='character(0)::a(2)';values=['',''];width=0
  else:decl='character(3)::a(2)';values=['a  ',' b '];width=3
  actual='n,xx'+('' if mode=='absent' else ',.'+mode+'.')
  suffix=('subroutine check(n,xx)\ninteger,intent(in)::n\ncharacter(*),intent(in)::xx(:)\ncharacter(len(xx))::y(n*size(xx))\ny=repeat_char_vec('+actual+')\nif(size(y)/=n*size(xx).or.len(y)/=len(xx))stop 1\nwrite(*,"(i0,1x,i0)")size(y),len(y)\nwrite(*,"(*(a))")y\nend subroutine\nend module\nprogram p\nuse original_vec_m\nimplicit none\n'+decl+'\n')
  if values:suffix+='a=['+','.join(repr(v) for v in values)+']\n'
  suffix+='call check('+str(n)+',a)\nend program\n'
  seq=([v for v in values for _ in range(n)] if mode=='false' else values*n)
  source=b'module original_vec_m\r\nimplicit none\r\ncontains\r\n'+depbody+vecbody+suffix.encode().replace(b'\n',b'\r\n')
  add(name,source,str(n*len(values))+' '+str(width)+'\n'+''.join(seq)+'\n',reason='Exact original repeat_char_vec and present_and_false closure; explicit result declaration retains descriptor length for zero-size cases.')
# Preserve GNU14 contextual empty-length anomalies as independent-oracle rows.
for c in cases:
 if c['name'] in ['assumed_scalar_empty_len','assumed_undefined_empty','allocated_empty_trip_scalar','descriptor_concat_zero_trip','optional_present_descriptor','allocated_uninitialized_empty','descriptor_length_limit_exact']:
  c['gnu']='compile';c['reason']='GNU14 zero-trip dynamic CHARACTER length differs by evaluation context; candidate expected descriptor length is independently derived from §7.8. Initial GNU failure retained.'
 if c['name']=='nested_constructor_empty':
  c['gnu']='reject';c['gnu_diagnostic']='must be CHARACTER';c['reason']='GNU14 rejects nested empty CHARACTER constructor LEN; independent candidate length oracle, not GNU execution agreement.'
# Exact candidate-first diagnostic contracts; fixture bytes remain unchanged.
DIAGNOSTICS={'optional_absent_descriptor': {'line': 4, 'column': 35, 'message': 'absent OPTIONAL dummy referenced: x'}, 'unallocated_empty_trip': {'line': 5, 'column': 5, 'message': 'reference to unallocated array x'}, 'runtime_mismatch': {'line': 6, 'column': 3, 'message': 'CHARACTER constructor item lengths differ'}, 'unallocated_scalar': {'line': 5, 'column': 5, 'message': 'reference to unallocated array x'}, 'unallocated_array': {'line': 5, 'column': 5, 'message': 'reference to unallocated array x'}, 'undefined_nonempty': {'line': 8, 'column': 5, 'message': 'read of uninitialized variable x'}, 'dynamic_trim_boundary': {'line': 8, 'column': 12, 'message': 'Untyped CHARACTER constructor requires descriptor-known item lengths'}, 'index_length_boundary': {'line': 5, 'column': 18, 'message': 'Untyped CHARACTER constructor requires descriptor-known item lengths'}, 'mismatch_empty_branch': {'line': 7, 'column': 3, 'message': 'CHARACTER constructor item lengths differ'}, 'mismatch_empty_array': {'line': 6, 'column': 3, 'message': 'CHARACTER constructor item lengths differ'}, 'runtime_concat_length_cap': {'line': 7, 'column': 16, 'message': 'invalid CHARACTER length descriptor'}, 'runtime_constructor_byte_cap': {'line': 7, 'column': 3, 'message': 'constructor CHARACTER staging limit exceeded (16 MiB)'}}
for c in cases:
 if c["name"] in DIAGNOSTICS:c["diagnostic"]=DIAGNOSTICS[c["name"]]
(ROOT/'manifest.json').write_text(json.dumps({'feature':'runtime descriptor-length CHARACTER constructors','cases':cases},indent=2)+'\n')
(ROOT/'provenance.json').write_text(json.dumps({'original_sha256':hashlib.sha256(original).hexdigest(),'original_lines':[1041,1048],'body_sha256':hashlib.sha256(body).hexdigest(),'original_cases':[c['name'] for c in cases if c['name'].startswith('original_repeat_') and not c['name'].startswith('original_repeat_vec_')],'additional_original_bodies':[{'name':'repeat_char_vec','lines':vecrange,'sha256':hashlib.sha256(vecbody).hexdigest(),'cases':vecnames},{'name':'present_and_false','lines':deprange,'sha256':hashlib.sha256(depbody).hexdigest(),'cases':vecnames}],'standard':'https://j3-fortran.org/doc/year/18/18-007r1.pdf','standard_clause':'7.8 paragraphs2,5,8','notes':'Original body bytes including CRLF retained; wrappers synthetic. Runtime-invalid fixtures GNU compile-only; exploratory rows not automatically claimed supported.'},indent=2)+'\n')
print(len(cases),'fixtures generated')
