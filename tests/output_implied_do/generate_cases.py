#!/usr/bin/env python3
"""Reconstruct synthetic fixtures and byte-exact upstream wrappers (no builds)."""
from pathlib import Path
import hashlib
import json
import argparse
ROOT=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--demo-source',type=Path,default=ROOT/'cases/demo_trim_original.f90',help='Byte-exact upstream demo_trim source; defaults to the committed untouched copy')
options=parser.parse_args()
cases=[]
def add(name, source, category='success', baseline=None, mode='numeric_records', **extra):
    path=ROOT/'cases'/(name+'.f90')
    path.write_bytes(source.encode() if isinstance(source,str) else source)
    cases.append(dict(name=name,source='cases/'+path.name,category=category,baseline=baseline or ('run' if category=='success' else 'compile'),compare_mode=mode,**extra))
def prog(decl,body,contains=''):
    return 'program main\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+contains+'\n' if contains else '')+'end program\n'
add('print_forward_final',prog('integer::i','i=99\nprint *, (i,i=1,4)\nprint *,i'))
add('print_reverse_final',prog('integer::i','i=99\nprint *, (i,i=7,-2,-3)\nprint *,i'))
add('zero_trip_initial_assignment',prog('integer::i,j','i=99\nj=99\nprint *, (i,i=4,1), (j,j=-4,1,-2)\nprint *,i,j'))
add('integer8_and_cross_kind',prog('integer(8)::i\ninteger::j','print *, (i,i=9007199254740993_8,9007199254740997_8,2_8)\nprint *,i\nprint *, (j,j=1_8,3_8)\nprint *,j'))
add('counter_initial_value_in_controls',prog('integer::i','i=2\nprint *, (i,i=i,3*i,i)\nprint *,i'))
add('source_order_and_reuse',prog('integer::i,j','i=20\nj=30\nprint *,i,(i,i=1,2),i,(i,i=4,5),i,(j,j=2,1,-1),j'))
add('nested_dependent_bounds',prog('integer::i,j,k','print *, ((10*i+j,j=1,i),i=1,4)\nprint *,i,j\nprint *, (((100*i+10*j+k,k=j,1,-1),j=i,1,-1),i=1,3)\nprint *,i,j,k'))
add('nested_zero_trip',prog('integer::i,j','j=88\nprint *, ((j,j=3,i),i=1,2)\nprint *,i,j'))
add('mixed_numeric_types',prog('integer::i\ninteger(8)::big\nreal::r\nreal(8)::d\nlogical::t','big=9223372036854775805_8\nr=-0.0\nd=0.125_8\nt=.true.\nprint *, (big+i,r,d*i,t,i=0,2)'))
add('stdout_write_list',prog('integer::i','write(*,*) -1,(i,10*i,i=1,3),-2\nprint *,i'))
add('literal_format_source_order',prog('integer::i','write(*,\'(a,6(i0,a))\') "<",(i,",",i=1,3),9,">"'),mode='exact')
add('print_parameter_format',prog('integer::i\ncharacter(*),parameter::fmt=\'(3("[",i0,"]"))\'','print fmt, (i,i=1,3)'),mode='exact')
add('nested_format_reversion',prog('integer::i,j','write(*,\'(2(i0,1x))\') ((10*i+j,j=1,2),i=1,3)'),mode='exact')
add('unlimited_format_colon',prog('integer::i\ncharacter(4)::a(3)','a=["ab  "," c  ","    "]\nprint \'(*( "[",a,"]":,1x))\', (trim(a(i)),i=1,3)'),mode='exact')
add('quoted_control_punctuation',prog('integer::i','write(*,\'(6a)\') ("i=1,2", "(x,y)",i=1,3)'),mode='exact')
add('character_array_leaf',prog('integer::i\ncharacter(2)::a(2)','a=["ab"," c"]\nprint \'(8a)\', "<",(a,i=1,2),">"'),mode='exact')
add('character_zero_length_leaf',prog('integer::i\ncharacter(0)::a(2)','a=""\nwrite(*,\'(a,4a,a)\') "<",(a,i=1,2),">"'),mode='exact')
add('whole_array_leaf',prog('integer::i\ninteger::a(3)','a=[3,4,5]\nprint *, (i,a,i=1,2)'))
add('rank_two_leaf',prog('integer::i\ninteger::a(2,3)','a=reshape([1,2,3,4,5,6],[2,3])\nprint *, (a,i=1,2)'))
add('rank_three_leaf',prog('integer::i\ninteger::a(2,2,2)','a=1\na(2,1,1)=2\na(1,2,1)=3\na(2,2,1)=4\na(1,1,2)=5\na(2,1,2)=6\na(1,2,2)=7\na(2,2,2)=8\nprint *, (a,i=1,2)'))
add('dynamic_reverse_sections',prog('integer::i\ninteger::a(5)','a=[10,20,30,40,50]\nprint *, (a(i:1:-1),i=1,5)'))
add('outer_dependent_rank_two_sections',prog('integer::i\ninteger::a(2,3)','a=reshape([1,2,3,4,5,6],[2,3])\nprint *, (a(:,i),i=3,1,-1)'))
add('empty_array_and_sections',prog('integer::i\ninteger::a(0),b(3)','b=[1,2,3]\nprint *, -1,(a,b(2:1),i=1,3),-2\nprint *,i'))
add('subroutine_local_counter',prog('integer::n','n=4\ncall work(n)', 'subroutine work(n)\ninteger,intent(in)::n\ninteger::i\nwrite(*,*) (i*i,i=1,n)\nprint *,i\nend subroutine'))
add('main_initialized_counter',prog('integer::i=88','print *, (i,i=1,3)\nprint *,i'))
add('internal_character_write',prog('integer::i\ncharacter(24)::buffer','buffer="old"\nwrite(buffer,\'(3(i0,a))\') (i,":",i=1,3)\nwrite(*,\'(a)\') "["//buffer//"]"\nprint *,i'),mode='mixed_last_numeric')
add('internal_substring_write',prog('integer::i\ncharacter(12)::buffer','buffer="abcdefghijkl"\nwrite(buffer(3:8),\'(3(i0,a))\') (i,":",i=1,3)\nwrite(*,\'(a)\') "["//buffer//"]"'),category='reject',mode='exact')
add('internal_zero_trip_blank_fill',prog('integer::i\ncharacter(8)::buffer','buffer="abcdefgh"\nwrite(buffer,\'(8a)\') ("x",i=2,1)\nwrite(*,\'(a)\') "["//buffer//"]"'),mode='exact')
add('function_internal_write_local_counter',prog('character(12)::s','s=render(3)\nwrite(*,\'(a)\') "["//s//"]"','function render(n) result(s)\ninteger,intent(in)::n\ninteger::i\ncharacter(12)::s\nwrite(s,\'(6(i0,a))\') (i,":",i=1,n)\nend function'),mode='exact')
add('nested_function_internal_write',prog('integer::i','print \'(3a)\', (render(i),i=1,3)','function render(n) result(s)\ninteger,intent(in)::n\ninteger::i\ncharacter(12)::s\nwrite(s,\'(6(i0,a))\') (i,":",i=1,n)\nend function'),mode='exact')
module_prefix='module m\nimplicit none\ninteger::calls=0\ncontains\nimpure elemental integer function tick(x) result(r)\ninteger,intent(in)::x\ncalls=calls+1\nr=x\nend function\nend module\n'
add('function_calls_per_iteration',module_prefix+'program main\nuse m\nimplicit none\ninteger::i\nprint *, (tick(i),i=1,4)\nprint *,calls\nend program\n')
add('control_calls_once',module_prefix+'program main\nuse m\nimplicit none\ninteger::i\nprint *, (tick(i),i=tick(1),tick(3),tick(1))\nprint *,calls,i\nend program\n')
add('nested_control_calls',module_prefix+'program main\nuse m\nimplicit none\ninteger::i,j\nprint *, ((tick(j),j=1,tick(i)),i=1,3)\nprint *,calls,i,j\nend program\n')
add('empty_function_array_leaf',module_prefix+'program main\nuse m\nimplicit none\ninteger::i,a(0)\nprint *, (tick(a),i=1,3)\nprint *,calls,i\nend program\n')
add('array_function_cache_each_iteration',module_prefix+'program main\nuse m\nimplicit none\ninteger::i,a(3)\na=[1,2,3]\nprint *, (tick(a+i),i=1,3)\nprint *,calls\nend program\n')
add('controls_frozen_despite_leaf_changes','module m\nimplicit none\ninteger::last=3,step=1\ncontains\nimpure elemental integer function change(x) result(r)\ninteger,intent(in)::x\nlast=0\nstep=0\nr=x\nend function\nend module\nprogram main\nuse m\nimplicit none\ninteger::i\nprint *, (change(i),i=1,last,step)\nprint *,i,last,step\nend program\n')
add('array_alias_snapshot_source_order','module m\nimplicit none\ninteger::a(2)\ncontains\nimpure elemental integer function bump(x) result(r)\ninteger,intent(in)::x\na=a+1\nr=x\nend function\nend module\nprogram main\nuse m\nimplicit none\ninteger::i\na=[10,20]\nprint *, (a,bump(i),i=1,2)\nprint *,a\nend program\n')
add('eight_nested_loops',prog('integer::'+','.join('i'+str(n) for n in range(1,9)), 'print *, '+''.join('(' for n in range(8))+'i1+i2+i3+i4+i5+i6+i7+i8'+''.join(',i'+str(n)+'=1,1)' for n in range(8,0,-1))))
add('objects64',prog('integer::i','print *, ('+', &\n &'.join(','.join(str(n) for n in range(k,min(k+16,65))) for k in range(1,65,16))+',i=1,1)'))
add('expanded_values65536',prog('integer::i\ninteger::a(32768)','a=7\nprint *, (a,i=1,2)\nprint *,i'),args=['--max-steps','10000000'])
add('empty_iterations65536',prog('integer::i\ninteger::a(0)','print *, (a,i=1,65536)\nprint *,i'),args=['--max-steps','10000000'])
add('nested_total_iterations65536',prog('integer::i,j\ninteger::a(0)','print *, ((a,j=1,32767),i=1,2)\nprint *,i,j'),args=['--max-steps','10000000'])
add('character_staging16mib',prog('integer::i\ncharacter(4096)::a','a="x"\nprint \'(4096a1)\', (a,i=1,4096)'),mode='exact',args=['--max-steps','10000000'])
add('shadowed_intrinsic_array_names',prog('integer::i,char(3),cshift(3)','char=[10,20,30]\ncshift=[1,2,3]\nprint *, (char(i),cshift(i),i=1,3)'))
add('nested_size_controls',prog('integer::i,j,a(3)','a=[10,20,30]\nprint *, ((a(j),j=1,size(a(:i))),i=1,size(a))'))
add('local_counter_shadows_module','module m\nimplicit none\ninteger::i=88\ncontains\nsubroutine work()\ninteger::i\nprint *, (i,i=1,3)\nprint *,i\nend subroutine\nend module\nprogram main\nuse m\nimplicit none\ncall work()\nprint *,i\nend program\n')
add('reserved_trim_name',prog('integer::i,trim(3)','trim=[1,2,3]\nprint *, (trim(i),i=1,3)'),category='reject',diagnostic='reserved')
# GNU-valid language features deliberately outside the bounded output subset.
for name,decl,body in [
('dummy_counter','integer::j','j=0\ncall work(j)'),
]:
 add(name,prog(decl,body,'subroutine work(i)\ninteger,intent(inout)::i\nprint *, (i,i=1,3)\nend subroutine'),category='reject')
add('module_counter','module m\nimplicit none\ninteger::i\nend module\nprogram main\nuse m\nimplicit none\nprint *, (i,i=1,3)\nend program\n',category='reject')
add('host_counter',prog('integer::i','i=0\ncall work()','subroutine work()\nprint *, (i,i=1,3)\nend subroutine'),category='reject')
add('allocatable_counter',prog('integer,allocatable::i','allocate(i)\nprint *, (i,i=1,3)'),category='reject')
add('pointer_counter',prog('integer,pointer::i\ninteger,target::j','i=>j\nprint *, (i,i=1,3)'),category='reject')
for name,decl in [('saved_counter','integer,save::i'),('initialized_procedure_counter','integer::i=1')]:
 add(name,prog('','call work()','subroutine work()\n'+decl+'\nprint *, (i,i=1,3)\nend subroutine'),category='reject')
add('derived_leaf',prog('type t\ninteger::x\nend type\ntype(t)::a\ninteger::i','a%x=1\nprint *, (a,i=1,3)'),category='reject')
add('constructor_implied_do',prog('integer::i,a(3)','a=[(i,i=1,3)]\nprint *,a'))
add('read_implied_do',prog('integer::i,a(3)\ncharacter(5)::s','s="1 2 3"\nread(s,*) (a(i),i=1,3)'),category='reject')
add('nine_nested_loops',prog('integer::'+','.join('i'+str(n) for n in range(1,10)), 'print *, '+''.join('(' for n in range(9))+'1'+''.join(',i'+str(n)+'=1,1)' for n in range(9,0,-1))),category='reject')
add('objects65',prog('integer::i','print *, ('+', &\n &'.join(','.join(str(n) for n in range(k,min(k+16,66))) for k in range(1,66,16))+',i=1,1)'),category='reject')
# Invalid Fortran: require GNU compilation rejection, never execute it.
invalid=[
('parameter_counter','integer,parameter::i=1','print *, (i,i=1,3)'),
('undeclared_counter','','print *, (i,i=1,3)'),
('logical_counter','logical::i','print *, (i,i=1,3)'),
('real_counter','real::i','print *, (i,i=1,3)'),
('array_counter','integer::i(2)','print *, (i,i=1,3)'),
('active_counted_counter','integer::i','do i=1,2\nprint *, (i,i=1,3)\nend do'),
('nested_counter_reuse','integer::i','print *, ((i,i=1,2),i=1,3)'),
('real_start','integer::i','print *, (i,i=1.5,3)'),
('real_end','integer::i','print *, (i,i=1,3.5)'),
('real_stride','integer::i','print *, (i,i=1,3,0.5)'),
('array_start','integer::i,a(2)','a=[1,2]\nprint *, (i,i=a,3)'),
('missing_end','integer::i','print *, (i,i=1)'),
('missing_object','integer::i','print *, (,i=1,3)'),
('missing_close','integer::i','print *, (i,i=1,3'),
('extra_control','integer::i','print *, (i,i=1,3,1,2)'),
]
for name,decl,body in invalid:
 add(name,prog(decl,body),category='reject',baseline='compile' if name=='nested_counter_reuse' else 'reject',**({'gnu_note':'GNU accepts nested counter reuse syntactically; compile only, never execute this invalid control reuse.'} if name=='nested_counter_reuse' else {}))
# Checked safety failures: valid syntax, compile-only GNU reference. No undefined execution.
runtime=[
('zero_step','integer::i,s','s=0\nprint *, (i,i=1,3,s)','step is zero'),
('undefined_start','integer::i,n','print *, (i,i=n,3)','uninitialized'),
('undefined_end','integer::i,n','print *, (i,i=1,n)','uninitialized'),
('undefined_step','integer::i,n','print *, (i,i=1,3,n)','uninitialized'),
('start_conversion_overflow','integer::i\ninteger(8)::n','n=2147483648_8\nprint *, (i,i=n,1)','overflow'),
('end_conversion_overflow','integer::i\ninteger(8)::n','n=2147483648_8\nprint *, (i,i=1,n)','overflow'),
('step_conversion_overflow','integer::i\ninteger(8)::n','n=2147483648_8\nprint *, (i,i=1,2,n)','overflow'),
('final_increment_overflow4','integer::i,n','n=huge(1)\nprint *, (i,i=n,n)','overflow'),
('final_decrement_overflow4','integer::i,n','n=-huge(1)-1\nprint *, (i,i=n,n,-1)','overflow'),
('final_increment_overflow8','integer(8)::i,n','n=huge(1_8)\nprint *, (i,i=n,n)','overflow'),
('final_decrement_overflow8','integer(8)::i,n','n=-huge(1_8)-1_8\nprint *, (i,i=n,n,-1_8)','overflow'),
('undefined_late_leaf','integer::i,n','print *, 123,(i,i=1,3),n','uninitialized'),
('undefined_late_array','integer::i,a(2)','a(1)=1\nprint *, (a(i),i=1,2)','uninitialized'),
('late_bounds_failure','integer::i,a(2)','a=[1,2]\nprint *, (a(i),i=1,3)','bounds'),
('expanded_values65537','integer::i,a(32768)','a=7\nprint *, 8,(a,i=1,2)','value limit'),
('empty_iterations65537','integer::i,a(0)','print *, (a,i=1,65537)','iteration limit'),
('nested_total_iterations65538','integer::i,j,a(0)','print *, ((a,j=1,32768),i=1,2)','iteration limit'),
('character_staging16mib_plus_one','integer::i\ncharacter(4096)::a','a="x"\nprint \'(4096a1,a1)\', (a,i=1,4096),"z"','CHARACTER'),
('internal_short_target','integer::i\ncharacter(3)::s','s="old"\nwrite(s,\'(4a)\') ("xx",i=1,2)',''),
('internal_late_undefined','integer::i,n\ncharacter(20)::s','s="original"\nwrite(s,\'(4i0)\') (i,i=1,3),n','uninitialized'),
('format_late_type_mismatch','integer::i','print \'(2i0,a)\', (i,i=1,3)','descriptor'),
]
for name,decl,body,diagnostic in runtime:
 add(name,prog(decl,'write(*,\'(a)\') "before"\n'+body),category='runtime',mode='exact',completed_stdout='before\n',diagnostic=diagnostic,args=['--max-steps','10000000'])
add('work_budget_atomic',prog('integer::i,a(0)','write(*,\'(a)\') "before"\nprint *, (a,i=1,1000)'),category='runtime',mode='exact',completed_stdout='before\n',diagnostic='budget',args=['--max-steps','200'])
# Preserve exact CRLF procedure bodies from the unchanged supplied xutilities source.
original=ROOT.parent/'utilities_slices/source/xutilities.f90'
raw=original.read_bytes(); lines=raw.splitlines(keepends=True)
assert hashlib.sha256(raw).hexdigest()=='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
extracts=[]
for name,first,last,args in [('join',844,861,'a,"::"'),('join_csv',884,896,'a'),('join_csv_suffix',898,912,'a,"!"'),('join_suffix',914,925,'a,"!"')]:
 body=b''.join(lines[first-1:last]);assert body.startswith(('function '+name+'(').encode());assert body.endswith(('end function '+name+'\r\n').encode())
 call=lambda var: name+'('+args.replace('a',var,1)+')'
 driver='program main\nuse utility_case\nimplicit none\ncharacter(5)::a(3),one(1),empty(0),blanks(2)\na=["alpha"," b   ","     "]\none=["only "]\nblanks=""\n'
 for var in ['a','one','empty','blanks']:driver+='write(*,\'(a)\') "["//'+call(var)+'//"]"\n'
 driver+='end program\n'
 source=b'module utility_case\nimplicit none\ncontains\n'+body+b'end module\n'+driver.encode()
 add('original_'+name,source,mode='exact')
 extracts.append(dict(name=name,source='cases/original_'+name+'.f90',original_lines=[first,last],body_sha256=hashlib.sha256(body).hexdigest(),body_bytes=len(body)))
# This exact demo is copied only from the supplied upstream source, never normalized.
demo=options.demo_source.read_bytes()
assert hashlib.sha256(demo).hexdigest()=='9d8b003fbaadf085f7e73239c1685a12df49aa55d7fa21940e189566a6c4e83c'
add('demo_trim_original',demo,mode='demo_trim_records',comparison_note='Every byte of records other than record 4 must match GNU. Record 4 contains processor-dependent list-directed integer padding; compare its two INTEGER tokens exactly and preserve its newline.')
for c in cases:
 if c['name']=='objects65':c['diagnostic']='object limit'
 if c['name']=='nine_nested_loops':c['diagnostic']='nesting limit'
 c['source_sha256']=hashlib.sha256((ROOT/c['source']).read_bytes()).hexdigest()
 if c['category']=='success':c['expected_file']='expected/'+c['name']+'.stdout'
 else:c['expected_stdout']=c.get('completed_stdout','')
(ROOT/'manifest.json').write_text(json.dumps(dict(schema_version=1,cases=cases),indent=2)+'\n')
(ROOT/'provenance.json').write_text(json.dumps(dict(original_utility_source='../utilities_slices/source/xutilities.f90',original_utility_sha256=hashlib.sha256(raw).hexdigest(),extracts=extracts,demo_trim=dict(source='cases/demo_trim_original.f90',upstream_path='example/demo_trim.f90',upstream_commit='fc14233036d910e3678d350efc24609e11475067',upstream_url='https://github.com/urbanjost/M_intrinsics/blob/fc14233036d910e3678d350efc24609e11475067/example/demo_trim.f90',sha256=hashlib.sha256(demo).hexdigest(),bytes=len(demo))),indent=2)+'\n')
print('Generated',len(cases),'fixtures')
