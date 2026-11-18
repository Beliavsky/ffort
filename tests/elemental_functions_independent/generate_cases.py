#!/usr/bin/env python3
"""Generate black-box elemental function tests without importing the interpreter."""
from pathlib import Path
from textwrap import dedent
from itertools import permutations
import json
import re

ROOT = Path(__file__).resolve().parent
CASES = []


def lower_simple(source):
    pattern = re.compile(r'^(\s*(?:(?:pure|simple|impure|recursive|non_recursive|elemental|integer|logical|real(?:\([^)]*\))?)\s+)*)((?:function|subroutine)\s+[a-z]\w*\s*\()', re.I)
    lines = []
    for line in source.splitlines(keepends=True):
        match = pattern.match(line)
        if match:
            prefix = match.group(1)
            if len(re.findall(r'\bsimple\b', prefix, re.I)) == 1 and re.search(r'\bpure\b', prefix, re.I):
                prefix = re.sub(r'\bsimple\b', '', prefix, flags=re.I)
            else:
                prefix = re.sub(r'\bsimple\b', 'pure', prefix, flags=re.I)
            line = prefix + line[len(match.group(1)):]
        lines.append(line)
    return ''.join(lines)


def add(name, source, expected='', category='success', baseline=None, diagnostic=None, **kw):
    source = dedent(source).strip()+'\n'
    if baseline is None:
        baseline = 'run' if category == 'success' else 'compile' if category in ('runtime','unsupported') else 'reject'
    has_simple = lower_simple(source) != source
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(source)
    if not isinstance(expected, str):
        expected = ' '.join(map(str, expected)) if isinstance(expected,(list,tuple)) else str(expected)
    case = dict(name=name, source=f'cases/{name}.f90', category=category,
                baseline=baseline, has_simple=has_simple, expected_stdout=expected, **kw)
    if has_simple:
        (ROOT/'pure_references').mkdir(exist_ok=True)
        (ROOT/'pure_references'/f'{name}.f90').write_text(lower_simple(source))
        case['pure_reference'] = f'pure_references/{name}.f90'
    if diagnostic:
        case['diagnostic'] = diagnostic
    CASES.append(case)


def prog(decl, body, procs=''):
    return 'program elemental_test\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+procs+'\n' if procs else '')+'end program\n'


def fun(prefix='elemental integer', args='xx', decl='integer,intent(in)::xx', body='rr=xx*xx+1', name='compute'):
    return f'{prefix} function {name}({args}) result(rr)\n{decl}\n{body}\nend function {name}\n'


def init1(name, values, lb=1):
    return '\n'.join(f'{name}({i+lb})={v}' for i,v in enumerate(values))


def init2(name, rows, cols, formula):
    return '\n'.join(f'{name}({i},{j})={formula(i,j)}' for j in cols for i in rows)


# Effective purity, all prefix orders, explicit and implicit function result names.
for order in permutations(('pure','elemental','integer')):
    add('prefix_'+'_'.join(order),prog('', 'print *,compute(4)',fun(' '.join(order))),17)
add('implicit_pure_scalar',prog('', 'print *,compute(5)',fun()),26)
add('elemental_typed_last',prog('', 'print *,compute(6)',fun('integer elemental')),37)
add('elemental_untyped_result',prog('', 'print *,compute(3)',fun('elemental',decl='integer,intent(in)::xx\ninteger::rr')),10)
add('unsupported_elemental_implicit_result_name',prog('', 'print *,compute(3)','elemental integer function compute(xx)\ninteger,intent(in)::xx\ncompute=xx+4\nend function\n'),category='unsupported')
add('simple_elemental_scalar',prog('', 'print *,compute(4)',fun('simple elemental integer')),17)
for order in permutations(('simple','elemental','real(8)')):
    add('prefix_'+'_'.join(order).replace('(8)','64'),prog('', 'print *,compute(0.5d0)',fun(' '.join(order),decl='real(8),intent(in)::xx',body='rr=xx+0.25d0')),0.75,rel_tol=1e-13,abs_tol=1e-14)
add('pure_simple_elemental_combined',prog('', 'print *,compute(3)',fun('simple pure elemental integer')),10)
add('uppercase_elemental',prog('', 'PRINT *,COMPUTE(2)',fun('ELEMENTAL INTEGER')),5)
add('zero_argument_scalar',prog('', 'print *,compute()',fun(args='',decl='',body='rr=8')),8)

# Shape is determined by array actuals; declared lower bounds are not conformability.
add('rank_one_nondefault_bounds',prog('integer::aa(-2:2)',init1('aa',[1,2,3,4,5],-2)+'\nprint *,compute(aa)',fun()),[2,5,10,17,26])
add('rank_two_column_major',prog('integer::aa(-1:0,4:6)',init2('aa',range(-1,1),range(4,7),lambda i,j:i+2*j)+'\nprint *,compute(aa)',fun()),[x*x+1 for x in [7,8,9,10,11,12]])
combine=fun(args='xx,yy',decl='integer,intent(in)::yy,xx',body='rr=10*xx+yy',name='combine')
for rank,decl,init,vals in [(1,'integer::aa(-1:1)',init1('aa',[1,2,3],-1),[1,2,3]),(2,'integer::aa(-1:0,4:5)',init2('aa',range(-1,1),range(4,6),lambda i,j:i+2*j),[7,8,9,10])]:
    for side,args,exp in [('first','aa,2',[10*x+2 for x in vals]),('second','2,aa',[20+x for x in vals])]:
        add(f'rank{rank}_array_{side}_scalar_expansion',prog(decl,init+'\nprint *,combine('+args+')',combine),exp)
    add(f'rank{rank}_array_expression',prog(decl,init+'\nprint *,combine(aa+1,compute(aa))',combine+fun()),[10*(x+1)+x*x+1 for x in vals])
add('array_bounds_conform',prog('integer::aa(-2:0),bb(4:6)',init1('aa',[1,2,3],-2)+'\n'+init1('bb',[4,5,6],4)+'\nprint *,combine(aa,bb)',combine),[14,25,36])
add('rank_two_bounds_conform',prog('integer::aa(-1:0,4:6),bb(9:10,-3:-1)','aa=2\nbb=3\nprint *,combine(aa,bb)',combine),[23]*6)
add('same_read_only_actual_twice',prog('integer::aa(3)',init1('aa',[2,4,6])+'\nprint *,combine(aa,aa)',combine),[22,44,66])

# Keyword order and array placement must not change the elemental shape source.
tri=fun(args='first,second,third',decl='integer,intent(in)::third,first,second',body='rr=100*first+10*second+third',name='combine')
for order in permutations(('first','second','third')):
    args=','.join(k+'='+dict(first='2',second='aa',third='4')[k] for k in order)
    add('keywords_'+''.join(k[0] for k in order),prog('integer::aa(3)',init1('aa',[1,3,5])+'\nprint *,combine('+args+')',tri),[214,234,254])
add('keywords_mixed_case',prog('integer::aa(3)','aa=3\nprint *,combine(2,ThIrD=4,SeCoNd=aa)',tri),[234]*3)
add('keywords_named_simple',prog('', 'print *,compute(simple=4)',fun('simple elemental integer',args='simple',decl='integer,intent(in)::simple',body='rr=simple+3')),category='unsupported')

# Reversed, noncontiguous, reduced rank and whole-result overlap use a value temporary.
add('reversed_rank_one_section',prog('integer::aa(-2:3)',init1('aa',[1,2,3,4,5,6],-2)+'\nprint *,compute(aa(3:-2:-2))',fun()),[37,17,5])
add('rank_two_sections',prog('integer::aa(3,4)',init2('aa',range(1,4),range(1,5),lambda i,j:i+10*j)+'\nprint *,compute(aa(3:1:-2,4:1:-2))',fun()),[x*x+1 for x in [43,41,23,21]])
add('rank_two_reduced_rows',prog('integer::aa(3,4)',init2('aa',range(1,4),range(1,5),lambda i,j:i+10*j)+'\nprint *,compute(aa(2,4:1:-1))',fun()),[x*x+1 for x in [42,32,22,12]])
add('rank_two_reduced_column',prog('integer::aa(3,4)',init2('aa',range(1,4),range(1,5),lambda i,j:i+10*j)+'\nprint *,compute(aa(3:1:-1,2))',fun()),[530,485,442])
add('overlap_whole_reverse',prog('integer::aa(5)',init1('aa',[1,2,3,4,5])+'\naa=compute(aa(5:1:-1))\nprint *,aa',fun()),[26,17,10,5,2])
add('overlap_section_shift',prog('integer::aa(5)',init1('aa',[1,2,3,4,5])+'\naa(2:5)=compute(aa(1:4))\nprint *,aa',fun()),[1,2,5,10,17])
add('overlap_rank_two_reverse',prog('integer::aa(2,3)',init2('aa',range(1,3),range(1,4),lambda i,j:i+2*(j-1))+'\naa=compute(aa(2:1:-1,3:1:-1))\nprint *,aa',fun()),[37,26,17,10,5,2])

# Elemental results compose with scalar/array procedures, reductions and metadata.
add('nested_elemental_calls',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,compute(compute(aa)),sum(compute(aa))',fun()),[5,26,101,17])
add('elemental_calls_pure',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,compute(aa)',fun(body='rr=helper(xx)+1')+fun('pure integer',body='rr=xx*2',name='helper')),[3,5,7])
add('pure_calls_elemental',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,helper(aa)',fun()+fun('pure integer',decl='integer,intent(in)::xx(:)',body='rr=sum(compute(xx))',name='helper')),17)
add('elemental_calls_simple',prog('integer::aa(2)','aa=3\nprint *,compute(aa)',fun(body='rr=helper(xx)+1')+fun('simple integer',body='rr=xx*2',name='helper')),[7,7])
add('simple_calls_simple_elemental',prog('integer::aa(2)','aa=3\nprint *,helper(aa)',fun('simple elemental integer')+fun('simple integer',decl='integer,intent(in)::xx(:)',body='rr=sum(compute(xx))',name='helper')),20)
add('simple_calls_pure_non_simple',prog('', 'print *,helper(3)',fun()+fun('simple integer',body='rr=compute(xx)',name='helper')),category='invalid',baseline='compile',diagnostic='simple')
add('elemental_calls_pure_subroutine',prog('integer::aa(2)','aa=3\nprint *,compute(aa)',fun(body='rr=xx\ncall bump(rr)')+'pure subroutine bump(xx)\ninteger,intent(inout)::xx\nxx=xx+2\nend subroutine'),[5,5])
add('metadata_result_bounds',prog('integer::aa(-2:0,4:5)','print *,size(compute(aa)),size(compute(aa),1),size(compute(aa),2)\nprint *,lbound(compute(aa),1),ubound(compute(aa),1),lbound(compute(aa),2),ubound(compute(aa),2)',fun()),[6,3,2,1,3,1,2])
add('module_elemental_function','''module transforms
implicit none
integer,parameter::offset=3
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+offset
end function
end module
program elemental_test
use transforms, only: compute
implicit none
integer::aa(2)
aa=4
print *,compute(xx=aa)
end program
''',[7,7])

# Empty iteration space must not execute the scalar body, including ERROR STOP.
stopfun=fun(body='error stop 77\nrr=xx')
for tag,decl,args,dims in [('rankone','integer::aa(0)','aa',[0]),('ranktwo_first','integer::aa(0,3)','aa',[0,3]),('ranktwo_second','integer::aa(2,0)','aa',[2,0])]:
    body='print *,compute('+args+')\nprint *,size(compute('+args+'))'
    if len(dims)==2: body+='\nprint *,size(compute('+args+'),1),size(compute('+args+'),2)'
    add('empty_'+tag,prog(decl,body,stopfun),[0]+(dims if len(dims)==2 else []))
add('empty_section',prog('integer::aa(3)','print *,compute(aa(2:1))\nprint *,size(compute(aa(2:1)))',stopfun),0)
add('empty_scalar_expansion',prog('integer::aa(0)','print *,combine(aa,5),combine(5,aa)\nprint *,size(combine(aa,5))',combine),0)

# Scalar type/kind is checked independently for each dummy; conversions are explicit.
add('real32_result',prog('real::aa(3)',init1('aa',['0.5','1.5','2.5'])+'\nprint *,compute(aa)',fun('elemental real',decl='real,intent(in)::xx',body='rr=xx*0.5')),[0.25,0.75,1.25])
add('real64_result',prog('real(8)::aa(3)',init1('aa',['0.125d0','0.375d0','0.625d0'])+'\nprint *,compute(aa)',fun('elemental real(8)',decl='real(8),intent(in)::xx',body='rr=xx+0.125d0')),[0.25,0.5,0.75],rel_tol=1e-13,abs_tol=1e-14)
add('mixed_dummy_kinds',prog('real::aa(2)\nreal(8)::bb(2)','aa=0.5\nbb=0.25d0\nprint *,combine(yy=bb,xx=aa)',fun('elemental real(8)',args='xx,yy',decl='real,intent(in)::xx\nreal(8),intent(in)::yy',body='rr=xx+yy',name='combine')),[0.75,0.75],rel_tol=1e-13,abs_tol=1e-14)
add('integer_to_real64_result',prog('integer::aa(2)','aa=3\nprint *,compute(aa)',fun('elemental real(8)',body='rr=xx*0.25d0')),[0.75,0.75])
add('logical_result',prog('integer::aa(4)',init1('aa',[0,1,2,3])+'\nprint *,compute(aa)',fun('elemental logical',body='rr=xx>1')),['F','F','T','T'])
add('logical_dummy',prog('logical::aa(3)','aa=.false.\naa(2)=.true.\nprint *,compute(aa)',fun('elemental logical',decl='logical,intent(in)::xx',body='rr=.not.xx')),['T','F','T'])

# Static validation must occur even for unused procedures or zero-sized calls.
for tag,prefix,decl,body in [
    ('missing_intent','elemental integer','integer::xx','rr=xx'),
    ('out_dummy','elemental integer','integer,intent(out)::xx','xx=1\nrr=xx'),
    ('inout_dummy','elemental integer','integer,intent(inout)::xx','xx=xx+1\nrr=xx'),
    ('array_dummy','elemental integer','integer,intent(in)::xx(:)','rr=sum(xx)'),
    ('array_result','elemental','integer,intent(in)::xx\ninteger::rr(2)','rr=xx'),
    ('duplicate_elemental','elemental elemental integer','integer,intent(in)::xx','rr=xx'),
    ('duplicate_pure','pure elemental pure integer','integer,intent(in)::xx','rr=xx'),
    ('conflicting_impure','pure impure elemental integer','integer,intent(in)::xx','rr=xx'),
    ('print','elemental integer','integer,intent(in)::xx','print *,xx\nrr=xx'),
    ('unreachable_print','elemental integer','integer,intent(in)::xx','if(.false.) print *,xx\nrr=xx'),
    ('ordinary_stop','elemental integer','integer,intent(in)::xx','stop 1\nrr=xx'),
    ('saved_local','elemental integer','integer,intent(in)::xx\ninteger,save::state','rr=xx'),
    ('initialized_local','elemental integer','integer,intent(in)::xx\ninteger::state=3','rr=xx+state'),
    ('input_write','elemental integer','integer,intent(in)::xx','xx=2\nrr=xx'),
    ('input_loop_variable','elemental integer','integer,intent(in)::xx','do xx=1,2\nend do\nrr=xx')]:
    add('invalid_'+tag,prog('', 'print *,991',fun(prefix,decl=decl,body=body)),category='invalid')
add('invalid_impure_callee',prog('', 'print *,991',fun(body='rr=helper(xx)')+fun('integer',body='rr=xx+1',name='helper')),category='invalid')
add('invalid_input_passed_out',prog('', 'print *,991',fun(body='call set_value(xx)\nrr=xx')+'pure subroutine set_value(xx)\ninteger,intent(out)::xx\nxx=2\nend subroutine'),category='invalid')
add('invalid_unknown_keyword',prog('', 'print *,compute(yy=2)',fun()),category='invalid')
add('invalid_duplicate_keyword',prog('', 'print *,compute(xx=2,xx=3)',fun()),category='invalid')
add('invalid_missing_argument',prog('', 'print *,combine(xx=2)',combine),category='invalid')
add('invalid_positional_after_keyword',prog('', 'print *,combine(xx=2,3)',combine),category='invalid')
add('invalid_kind_mismatch',prog('real::aa(2)','aa=2.0\nprint *,compute(aa)',fun('elemental real(8)',decl='real(8),intent(in)::xx',body='rr=xx')),category='invalid')
add('invalid_type_mismatch',prog('real::aa(2)','aa=2.0\nprint *,compute(aa)',fun()),category='invalid')
add('invalid_rank_mismatch',prog('integer::aa(2),bb(2,1)','aa=2\nbb=3\nprint *,combine(aa,bb)',combine),category='invalid')
add('invalid_extent_mismatch',prog('integer::aa(2),bb(3)','aa=2\nbb=3\nprint *,combine(aa,bb)',combine),category='invalid')
add('invalid_equal_size_wrong_shape',prog('integer::aa(2,3),bb(3,2)','aa=2\nbb=3\nprint *,combine(aa,bb)',combine),category='invalid')
add('invalid_empty_nonempty_shape',prog('integer::aa(0),bb(2)','bb=3\nprint *,combine(aa,bb)',combine),category='invalid')
add('invalid_empty_rank_two_shape',prog('integer::aa(0,3),bb(0,4)','print *,combine(aa,bb)',combine),category='invalid')

# Legal Fortran features remain explicit subset boundaries, not invalid language.
add('supported_impure_elemental',prog('', 'print *,compute(2)',fun('impure elemental integer')),5)
add('supported_elemental_subroutine',prog('integer::aa(2)','aa=2\ncall bump(aa)\nprint *,aa','elemental subroutine bump(xx)\ninteger,intent(inout)::xx\nxx=xx+1\nend subroutine'),[3,3])
add('unsupported_value_dummy',prog('', 'print *,compute(2)',fun(decl='integer,value::xx')),category='unsupported')
add('unsupported_optional_dummy',prog('', 'print *,compute(2)',fun(decl='integer,intent(in),optional::xx')),'5',category='success')
add('unsupported_character_result',prog('', 'print *,compute(2)',fun('elemental',decl='integer,intent(in)::xx\ncharacter(len=1)::rr',body='rr="a"')),category='unsupported')
add('unsupported_host_variable_read',prog('integer::host','host=4\nprint *,compute(2)',fun(body='rr=xx+host')),category='unsupported')
add('simple_elemental_host_read',prog('integer::host','host=4\nprint *,compute(2)',fun('simple elemental integer',body='rr=xx+host')),category='invalid',baseline='compile')

# Runtime policy: complete PRINT record remains atomic after any scalar failure.
add('runtime_uninitialized_result',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,112\nprint *,compute(aa)',fun(body='if(xx/=2) rr=xx')),112,category='runtime',baseline='skip',diagnostic='uninitialized')
add('runtime_uninitialized_input',prog('integer::aa(3)','aa(1)=1\naa(3)=3\nprint *,compute(aa)',fun()),category='runtime',baseline='skip',diagnostic='uninitialized')
add('runtime_error_stop_atomic',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,112\nprint *,compute(aa)',fun(body='if(xx==2) error stop 77\nrr=xx')),112,category='runtime',baseline='compile',diagnostic='77')
add('runtime_division_atomic',prog('integer::aa(3)',init1('aa',[1,0,2])+'\nprint *,112\nprint *,compute(aa)',fun(body='rr=10/xx')),112,category='runtime',baseline='skip',diagnostic='zero')
add('runtime_dynamic_extent_mismatch',prog('integer::aa(4),nn','aa=2\nnn=3\nprint *,112\nprint *,combine(aa(1:nn),aa(1:2))',combine),112,category='runtime',baseline='compile')
add('runtime_dynamic_ranktwo_mismatch',prog('integer::aa(2,3),nn','aa=2\nnn=2\nprint *,112\nprint *,combine(aa(:,1:nn),aa)',combine),112,category='runtime',baseline='compile')
add('runtime_dynamic_empty_mismatch',prog('integer::aa(0,3),nn','nn=2\nprint *,112\nprint *,combine(aa(:,1:nn),aa)',combine),112,category='runtime',baseline='compile')
add('runtime_shared_budget',prog('integer::aa(40)','aa=3\nprint *,compute(aa)',fun(decl='integer,intent(in)::xx\ninteger::ii',body='rr=xx\ndo ii=1,20\nrr=rr+1\nend do')),category='runtime',baseline='skip',diagnostic='step limit',args=['--max-steps','500'])
add('runtime_nested_budget',prog('integer::aa(20)','aa=3\nprint *,compute(compute(aa))',fun(decl='integer,intent(in)::xx\ninteger::ii',body='rr=xx\ndo ii=1,20\nrr=rr+1\nend do')),category='runtime',baseline='skip',diagnostic='step limit',args=['--max-steps','500'])

# Producer resolution must distinguish identically named procedures by module.
add('same_named_module_procedures', """module scalar_ops
implicit none
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+100
end function
end module
module array_ops
implicit none
contains
elemental logical function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx>2
end function
end module
program elemental_test
use array_ops, only: compute
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,compute(aa)
end program
""",['F','F','T'])
add('unused_undefined_scalar_input',prog('integer::aa','print *,compute(aa)',fun(body='rr=7')),7)
add('unused_undefined_array_input',prog('integer::aa(3)','print *,compute(aa)',fun(body='rr=7')),[7,7,7])
add('unused_undefined_section_input',prog('integer::aa(5)','print *,compute(aa(5:1:-2))',fun(body='rr=7')),[7,7,7])
add('runtime_parenthesized_undefined_input',prog('integer::aa(3)','print *,compute((aa))',fun(body='rr=7')),category='runtime',baseline='skip',diagnostic='uninitialized')
add('runtime_fresh_local_frame',prog('integer::aa(2)',init1('aa',[1,2])+'\nprint *,compute(aa)',fun(decl='integer,intent(in)::xx\ninteger::local',body='if(xx==1) local=8\nrr=local')),category='runtime',baseline='skip',diagnostic='uninitialized')
add('unsupported_rank_three_actual',prog('integer::aa(2,2,2)','aa=2\nprint *,compute(aa)',fun()),category='unsupported')

add('same_named_private_helpers', """module scalar_ops
implicit none
private
public::scalar_wrap
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+100
end function
pure integer function scalar_wrap(xx) result(rr)
integer,intent(in)::xx
rr=compute(xx)
end function
end module
module array_ops
implicit none
private
public::array_wrap
contains
elemental real(8) function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*0.5d0
end function
pure real(8) function array_wrap(xx) result(rr)
integer,intent(in)::xx(:)
rr=sum(compute(xx))
end function
end module
program elemental_test
use scalar_ops, only: scalar_wrap
use array_ops, only: array_wrap
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,scalar_wrap(5),array_wrap(aa)
end program
""",[105,3.0],rel_tol=1e-13,abs_tol=1e-14)
add('elemental_local_ranktwo_arrays',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,compute(aa)',fun(decl='integer,intent(in)::xx\ninteger::local(2,3)',body='local=xx\nrr=sum(local)')),[6,12,18])
add('scalar_call_in_array_expression',prog('integer::aa(3)','aa=2\nprint *,compute(3)+aa',fun()),[12,12,12])
add('array_call_in_scalar_element',prog('integer::aa(2),bb(2)','aa=2\nbb=1\nprint *,combine(compute(aa),bb)',combine+fun()),[51,51])
for case in CASES:
    if case['name'].startswith('runtime_dynamic_'):
        case['diagnostic']='conform'

# Composition with reductions/products and ordinary assumed-shape procedures.
mat_decl='integer::aa(2,3)'
mat_init=init2('aa',range(1,3),range(1,4),lambda i,j:i+2*(j-1))
add('elemental_result_sum_dim1',prog(mat_decl,mat_init+'\nprint *,sum(compute(aa),dim=1)',fun()),[7,27,63])
add('elemental_result_sum_dim2',prog(mat_decl,mat_init+'\nprint *,sum(dim=2,array=compute(aa))',fun()),[38,59])
add('elemental_result_matmul',prog('integer::aa(2,3),bb(3,2)','aa=2\nbb=3\nprint *,matmul(compute(aa),compute(bb))',fun()),[150]*4)
add('elemental_result_dot_product',prog('integer::aa(3),bb(3)','aa=2\nbb=3\nprint *,dot_product(compute(aa),compute(bb))',fun()),150)
add('elemental_result_assumed_shape_rankone',prog('integer::aa(3)',init1('aa',[1,2,3])+'\nprint *,take(compute(aa))',fun()+fun('pure integer',decl='integer,intent(in)::xx(:)',body='rr=sum(xx)',name='take')),17)
add('elemental_result_assumed_shape_ranktwo',prog(mat_decl,mat_init+'\nprint *,take(compute(aa))',fun()+fun('pure integer',decl='integer,intent(in)::xx(:,:)',body='rr=sum(xx)',name='take')),97)
add('elemental_actual_sum_dim1',prog(mat_decl,mat_init+'\nprint *,compute(sum(aa,dim=1))',fun()),[10,50,122])
add('elemental_actual_sum_dim2',prog(mat_decl,mat_init+'\nprint *,compute(sum(dim=2,array=aa))',fun()),[82,145])
add('elemental_actual_sum_runtime_dim',prog(mat_decl+'\ninteger::dd',mat_init+'\ndd=2\nprint *,compute(sum(dim=dd,array=aa))',fun()),[82,145])
add('elemental_actual_matmul',prog('integer::aa(2,3),bb(3,2)','aa=2\nbb=3\nprint *,compute(matmul(aa,bb))',fun()),[325]*4)
add('elemental_actual_matrix_vector_product',prog('integer::aa(2,3),bb(3)','aa=2\nbb=3\nprint *,compute(matmul(aa,bb))',fun()),[325]*2)
# This fixture also keeps a different same-named private INTEGER compute in a
# preceding module. The selected helper returns REAL(8), not its INTEGER input.
private_helpers=(ROOT/'cases/same_named_private_helpers.f90').read_text()
for label,actual in [('conversion','int(real(xx))'),('maximum','max(xx,0)')]:
    add('module_elemental_'+label,private_helpers.replace('rr=sum(compute(xx))','rr=sum(compute('+actual+'))'),[105,3.0],rel_tol=1e-13,abs_tol=1e-14)
add('module_elemental_composed_intrinsics',private_helpers.replace('rr=sum(compute(xx))','rr=sum(compute(int(real(xx))))+sum(compute(max(xx,0)))'),[105,6.0],rel_tol=1e-13,abs_tol=1e-14)

# Features supported in 0.17.0; preserve every original source fixture.
SUPPORTED_017 = {'unsupported_elemental_implicit_result_name': '7', 'unsupported_character_result': 'a'}
for row in CASES:
    if row['name'] in SUPPORTED_017:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_017[row['name']])

# Rank-three milestone: retain the original fixture as a positive oracle.
for row in CASES:
    if row['name'] == 'unsupported_rank_three_actual':
        row.update(category='success', baseline='run', expected_stdout='5 5 5 5 5 5 5 5')
        row['note']='Rank-three arrays are supported by the bounded rank-three milestone; original source is unchanged.'

(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} elemental function cases')
