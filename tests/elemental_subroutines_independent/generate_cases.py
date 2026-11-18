#!/usr/bin/env python3
"""Independent specifications for elemental writable calls and impure evaluation."""
from pathlib import Path
from textwrap import dedent
from itertools import permutations
import json
import re
ROOT=Path(__file__).resolve().parent
CASES=[]

def lower_simple(source):
    return re.sub(r'(?mi)^(\s*)simple elemental',r'\1pure elemental',source)

def add(name,source,expected='',category='success',baseline=None,diagnostic=None,**kw):
    source=dedent(source).strip()+'\n'
    if baseline is None:
        baseline='run' if category=='success' else 'compile' if category in ('runtime','unsupported') else 'reject'
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(source)
    if not isinstance(expected,str): expected=' '.join(map(str,expected)) if isinstance(expected,(list,tuple)) else str(expected)
    simple=lower_simple(source)!=source
    case=dict(name=name,source=f'cases/{name}.f90',category=category,baseline=baseline,has_simple=simple,expected_stdout=expected,**kw)
    if simple:
        (ROOT/'pure_references').mkdir(exist_ok=True)
        (ROOT/'pure_references'/f'{name}.f90').write_text(lower_simple(source))
        case['pure_reference']=f'pure_references/{name}.f90'
    if diagnostic: case['diagnostic']=diagnostic
    CASES.append(case)

def prog(decl,body,procs=''):
    return f'program elemental_actions\nimplicit none\n{decl}\n{body}\n'+('contains\n'+procs if procs else '')+'\nend program\n'
def sub(prefix='elemental',args='xx',decl='integer,intent(inout)::xx',body='xx=xx+1',name='bump'):
    return f'{prefix} subroutine {name}({args})\n{decl}\n{body}\nend subroutine {name}\n'
def fun(prefix='impure elemental integer',body='rr=xx+10',decl='integer,intent(in)::xx',args='xx',name='compute'):
    return f'{prefix} function {name}({args}) result(rr)\n{decl}\n{body}\nend function {name}\n'
def init(name,values,lo=1):
    return '\n'.join(f'{name}({i+lo})={v}' for i,v in enumerate(values))
def init2(name,n,m):
    return '\n'.join(f'{name}({i},{j})={i+10*j}' for j in range(1,m+1) for i in range(1,n+1))

# Scalar and lifted declarations, directionality and independent prefix permutations.
for prefix in ('elemental','pure elemental','elemental pure','simple elemental','impure elemental','elemental impure'):
    add('prefix_'+prefix.replace(' ','_'),prog('integer::aa(3)','aa=2\ncall bump(aa)\nprint *,aa',sub(prefix)),[3]*3)
add('simple_elemental_scalar',prog('integer::aa','aa=2\ncall bump(aa)\nprint *,aa',sub('simple elemental')),3)
add('simple_calls_pure_non_simple',prog('integer::aa','aa=2\ncall wrap(aa)',sub()+sub('simple elemental',name='wrap',body='call bump(xx)')),category='invalid',baseline='compile')
add('scalar_all_intents',prog('integer::aa,bb','aa=3\ncall work(aa,4,bb)\nprint *,aa,bb',sub(args='xx,yy,zz',decl='integer,intent(inout)::xx\ninteger,intent(in)::yy\ninteger,intent(out)::zz',body='zz=xx+yy\nxx=xx*yy',name='work')),[12,7])
add('scalar_out_uninitialized',prog('integer::aa','call bump(aa)\nprint *,aa',sub(decl='integer,intent(out)::xx',body='xx=7')),7)
add('scalar_inout_overwrite_undefined',prog('integer::aa','call bump(aa)\nprint *,aa',sub(body='xx=8')),8)
add('array_inout_overwrite_undefined',prog('integer::aa(3)','call bump(aa)\nprint *,aa',sub(body='xx=8')),[8]*3)
add('array_out_uninitialized',prog('integer::aa(3)','call bump(aa)\nprint *,aa',sub(decl='integer,intent(out)::xx',body='xx=7')),[7]*3)
add('scalar_zero_arg_impure',prog('','call announce()',sub('impure elemental',args='',decl='',body='print *,91',name='announce')),91)
add('scalar_only_in_impure',prog('','call announce(7)',sub('impure elemental',decl='integer,intent(in)::xx',body='print *,xx',name='announce')),7)
work=sub(args='xx,yy,zz',decl='integer,intent(inout)::xx\ninteger,intent(in)::yy\ninteger,intent(out)::zz',body='zz=xx+yy\nxx=xx*yy',name='work')
add('rank_one_bounds',prog('integer::aa(-2:0),bb(4:6),cc(9:11)',init('aa',[2,3,4],-2)+'\n'+init('bb',[5,6,7],4)+'\ncall work(aa,bb,cc)\nprint *,aa,cc',work),[10,18,28,7,9,11])
add('rank_two_bounds',prog('integer::aa(-1:0,4:6),bb(2,3)','aa=3\ncall work(aa,2,bb)\nprint *,aa,bb',work),[6]*6+[5]*6)
for order in permutations(('xx','yy','zz')):
    actuals=','.join(k+'='+dict(xx='aa',yy='3',zz='bb')[k] for k in order)
    add('keywords_'+''.join(k[0] for k in order),prog('integer::aa(2),bb(2)','aa=2\ncall work('+actuals+')\nprint *,aa,bb',work),[6,6,5,5])
add('mixed_case_keywords',prog('integer::aa(2),bb(2)','aa=2\ncall work(aa,Zz=bb,yY=4)\nprint *,aa,bb',work),[8,8,6,6])
# Scalar expansion, expressions, and direct versus expression alias policy.
add('input_expression_snapshot',prog('integer::aa(4)',init('aa',[1,2,3,4])+'\ncall copy_to(aa+aa(1),aa)\nprint *,aa',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')),[2,3,4,5])
add('readonly_aliases',prog('integer::aa(3),bb(3)',init('aa',[2,4,6])+'\ncall work(aa,aa,bb)\nprint *,bb',sub(args='xx,yy,zz',decl='integer,intent(in)::xx,yy\ninteger,intent(out)::zz',body='zz=xx+yy',name='work')),[4,8,12])
add('disjoint_strides',prog('integer::aa(6)',init('aa',[1,2,3,4,5,6])+'\ncall exchange(aa(1:6:2),aa(2:6:2))\nprint *,aa',sub(args='xx,yy',decl='integer,intent(inout)::xx,yy\ninteger::temp',body='temp=xx\nxx=yy\nyy=temp',name='exchange')),[2,1,4,3,6,5])
add('reverse_destination',prog('integer::aa(5),bb(3)',init('aa',[1,2,3,4,5])+'\nbb=2\ncall work(aa(5:1:-2),bb,aa(2:4:2))',work),category='runtime',baseline='reject')
add('reverse_source_and_destination',prog('integer::aa(5),bb(3)',init('aa',[1,2,3,4,5])+'\ncall copy_to(aa(5:1:-2),bb(3:1:-1))\nprint *,bb',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=10*src',name='copy_to')),[10,30,50])
add('rank_two_strided_destinations',prog('integer::aa(3,4),bb(2,2)',init2('aa',3,4)+'\ncall copy_to(aa(3:1:-2,4:1:-2),bb)\nprint *,bb',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')),[43,41,23,21])
add('rank_reduced_destination',prog('integer::aa(3,4)','aa=0\ncall bump(aa(2,4:1:-1))\nprint *,aa',sub()),[0,1,0]*4)
add('real64_output',prog('real(8)::aa(3),bb(3)','aa=0.5d0\ncall work(aa,2.0d0,bb)\nprint *,aa,bb',sub(args='xx,yy,zz',decl='real(8),intent(inout)::xx\nreal(8),intent(in)::yy\nreal(8),intent(out)::zz',body='zz=xx+yy\nxx=xx*yy',name='work')),[1.0]*3+[2.5]*3,rel_tol=1e-13,abs_tol=1e-14)
add('logical_output',prog('logical::aa(3),bb(3)','aa=.true.\ncall invert(aa,bb)\nprint *,aa,bb',sub(args='xx,yy',decl='logical,intent(inout)::xx\nlogical,intent(out)::yy',body='yy=.not.xx\nxx=yy',name='invert')),'F F F F F F')
# I/O is an order witness. First dimension varies fastest, including negative triplets.
order=sub('impure elemental',body='print *,xx\nxx=xx+100')
add('impure_order_rank_one',prog('integer::aa(3)',init('aa',[2,4,6])+'\ncall bump(aa)\nprint *,aa',order),[2,4,6,102,104,106])
add('impure_order_rank_two',prog('integer::aa(2,3)',init2('aa',2,3)+'\ncall bump(aa)\nprint *,aa',order),[11,12,21,22,31,32,111,112,121,122,131,132])
add('impure_order_reverse_section',prog('integer::aa(3,4)',init2('aa',3,4)+'\ncall bump(aa(3:1:-2,4:1:-2))\nprint *,aa',order),[43,41,23,21,11,12,13,121,22,123,31,32,33,141,42,143])
add('impure_calls_ordinary_subroutine',prog('integer::aa(2)',init('aa',[3,7])+'\ncall bump(aa)\nprint *,aa',sub('impure elemental',body='call ordinary(xx)')+sub('',body='print *,xx\nxx=xx+1',name='ordinary')),[3,7,4,8])
add('elemental_nested_pure_call',prog('integer::aa(3)','aa=1\ncall outer(aa)\nprint *,aa',sub('elemental',body='call bump(xx)\ncall bump(xx)',name='outer')+sub()),[3]*3)
add('impure_nested_call_order',prog('integer::aa(2)',init('aa',[2,5])+'\ncall outer(aa)\nprint *,aa',sub('impure elemental',body='call bump(xx)\ncall bump(xx)',name='outer')+order),[2,102,5,105,202,205])
# Impure functions are evaluated by assignment, separate from the output witness.
ff=fun(body='print *,xx\nrr=xx+10')
for p in permutations(('impure','elemental','integer')):
    add('function_prefix_'+'_'.join(p),prog('integer::rr','rr=compute(3)\nprint *,rr',fun(' '.join(p))),13)
add('impure_function_no_io_print',prog('','print *,compute(2)',fun()),12)
add('impure_function_rank_two',prog('integer::aa(2,2),bb(2,2)',init2('aa',2,2)+'\nbb=compute(aa)\nprint *,bb',ff),[11,12,21,22,21,22,31,32])
add('impure_function_reverse',prog('integer::aa(3),bb(3)',init('aa',[1,2,3])+'\nbb=compute(aa(3:1:-1))\nprint *,bb',ff),[3,2,1,13,12,11])
add('impure_function_sum',prog('integer::aa(3),rr',init('aa',[1,2,3])+'\nrr=sum(compute(aa))\nprint *,rr',ff),[1,2,3,36])
add('impure_function_product',prog('integer::aa(3),rr',init('aa',[1,2,3])+'\nrr=product(compute(aa))\nprint *,rr',ff),[1,2,3,1716])
add('impure_function_matmul_once',prog('integer::aa(2,2),bb(2,2),cc(2,2)',init2('aa',2,2)+'\nbb=1\ncc=matmul(compute(aa),bb)\nprint *,cc',ff),[11,12,21,22,52,54,52,54])
add('impure_function_dot_once',prog('integer::aa(3),bb(3),rr',init('aa',[1,2,3])+'\nbb=2\nrr=dot_product(compute(aa),bb)\nprint *,rr',ff),[1,2,3,72])
add('impure_function_nested',prog('integer::aa(2),bb(2)',init('aa',[1,2])+'\nbb=compute(compute(aa))\nprint *,bb',ff),[1,2,11,12,21,22],baseline='compile')
add('impure_function_cache_statement_reset',prog('integer::aa(2),bb(2)',init('aa',[1,2])+'\nbb=compute(aa)\naa=aa+1\nbb=compute(aa)\nprint *,bb',ff),[1,2,2,3,12,13])
add('impure_function_scalar_expansion_once',prog('integer::bb(3)','bb=compute(7)\nprint *,bb',ff),[7,17,17,17])
add('impure_function_overlap_assignment',prog('integer::aa(3)',init('aa',[1,2,3])+'\naa=compute(aa(3:1:-1))\nprint *,aa',ff),[3,2,1,13,12,11])
# Zero-size calls validate shape/descriptors but do not touch data or invoke bodies.
add('empty_impure_subroutine',prog('integer::aa(0)','call bump(aa)\nprint *,size(aa)',order),0)
add('empty_rank_two_subroutine',prog('integer::aa(0,3)','call bump(aa)\nprint *,size(aa)',order),0)
add('empty_writable_no_scalar_read',prog('integer::aa(0),zz','call copy_to(zz,aa)\nprint *,size(aa)',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')),0)
add('empty_impure_function',prog('integer::aa(0),bb(0)','bb=compute(aa)\nprint *,size(bb)',ff),0)
add('empty_function_scalar_expansion',prog('integer::bb(0)','bb=compute(7)\nprint *,size(bb)',ff),[7,0],baseline='compile')
add('undefined_in_unused',prog('integer::aa(3),zz','call copy_to(zz,aa)\nprint *,aa',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=9',name='copy_to')),[9]*3)
add('inout_partial_definition_preserved',prog('integer::aa(3)','aa(1)=7\ncall keep(aa)\nprint *,aa(1)',sub(body='return',name='keep')),7)
# Static errors distinguish language constraints from deliberately unsupported constructs.
for name,decl,body,procs in [
 ('writable_scalar_with_array','integer::aa(2),bb','aa=2\ncall copy_to(aa,bb)',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')),
 ('only_in_array','integer::aa(2)','aa=2\ncall announce(aa)',sub('impure elemental',decl='integer,intent(in)::xx',body='print *,xx',name='announce')),
 ('array_dummy','integer::aa(2)','call bump(aa)',sub(decl='integer,intent(inout)::xx(:)')),
 ('missing_intent','integer::aa','call bump(aa)',sub(decl='integer::xx')),
 ('out_expression','integer::aa(2)','aa=2\ncall bump(aa+1)',sub(decl='integer,intent(out)::xx',body='xx=3')),
 ('inout_literal','','call bump(2)',sub()),
 ('out_parameter','integer,parameter::aa=2','call bump(aa)',sub(decl='integer,intent(out)::xx',body='xx=3')),
 ('kind_mismatch','real(8)::aa(2)','aa=2.0d0\ncall bump(aa)',sub(decl='real,intent(inout)::xx')),
 ('rank_shape_static','integer::aa(2,3),bb(3,2)','aa=2\ncall copy_to(aa,bb)',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')),
 ('pure_print','integer::aa','aa=2\ncall bump(aa)',sub(body='print *,xx')),
 ('pure_calls_impure','integer::aa','aa=2\ncall outer(aa)',sub(body='call bump(xx)',name='outer')+order),
 ('conflict_pure_impure','integer::aa','aa=2\ncall bump(aa)',sub('pure impure elemental')),
 ('duplicate_impure','integer::aa','aa=2\ncall bump(aa)',sub('impure impure elemental')),
 ('duplicate_elemental','integer::aa','aa=2\ncall bump(aa)',sub('elemental elemental')),
 ('unknown_keyword','integer::aa','aa=2\ncall bump(zz=aa)',sub()),
 ('duplicate_keyword','integer::aa','aa=2\ncall bump(aa,xx=aa)',sub()),
 ('position_after_keyword','integer::aa,bb','aa=2\ncall copy_to(src=aa,bb)',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')),
]:
    add('invalid_'+name,prog(decl,'print *,991\n'+body,procs),category='invalid',baseline='compile' if name in ('only_in_array','duplicate_impure') else 'reject')
add('unsupported_writable_impure_function',prog('integer::aa,rr','aa=2\nrr=compute(aa)\nprint *,aa,rr',fun(decl='integer,intent(inout)::xx',body='xx=xx+1\nrr=xx')),category='unsupported')
add('unsupported_impure_nonelemental',prog('integer::aa','aa=2\ncall bump(aa)',sub('impure')),category='unsupported')
# Runtime safety policy is separately classified and never inferred from GNU UB.
copy=sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='dst=src',name='copy_to')
for name,decl,body,procs,expected,kw in [
 ('overlap_same','integer::aa(3)','aa=2\ncall copy_to(aa,aa)',copy,'',{}),
 ('overlap_cross_elements','integer::aa(4)',init('aa',[1,2,3,4])+'\ncall copy_to(aa(1:3),aa(2:4))',copy,'',{}),
 ('overlap_scalar_input','integer::aa(3)','aa=2\ncall copy_to(aa(1),aa)',copy,'',{}),
 ('undefined_in_read','integer::aa(3),bb(3)','call copy_to(aa,bb)',copy,'',{'diagnostic':'uninitialized'}),
 ('undefined_inout_read','integer::aa(3)','call bump(aa)',sub(),'',{'diagnostic':'uninitialized'}),
 ('out_read_old','integer::aa(2)','aa=9\ncall bump(aa)',sub(decl='integer,intent(out)::xx'),'',{'diagnostic':'uninitialized'}),
 ('out_partial_reset','integer::aa(3)','aa=7\ncall keep(aa)\nprint *,aa',sub(decl='integer,intent(out)::xx',body='return',name='keep'),'',{'diagnostic':'uninitialized'}),
 ('shape_dynamic','integer::aa(4),bb(4),n','aa=2\nn=3\ncall copy_to(aa(1:n),bb(1:2))',copy,'',{}),
 ('empty_zero_stride','integer::aa(0),stride','stride=0\ncall bump(aa(1:0:stride))',order,'',{}),
 ('section_oob','integer::aa(3),n','aa=2\nn=4\ncall bump(aa(1:n))',order,'',{}),
 ('active_loop_scalar','integer::i','do i=1,2\ncall bump(i)\nend do',sub(),'',{}),
 ('impure_print_recursive','integer::aa','aa=2\nprint *,compute(aa)',ff,'',{}),
 ('impure_print_transitive','integer::aa','aa=2\nprint *,compute(aa)',fun(body='call emit(xx)\nrr=xx')+sub('',decl='integer,intent(in)::xx',body='print *,xx',name='emit'),'',{}),
 ('budget_array_call','integer::aa(30)','aa=1\ncall bump(aa)\nprint *,aa',sub(),'',{'args':['--max-steps','40']}),
 ('budget_impure_function','integer::aa(30),bb(30)','aa=1\nbb=compute(aa)\nprint *,bb',fun(),'',{'args':['--max-steps','40']}),
 ('late_function_divide','integer::aa(3),bb(3)',init('aa',[1,0,2])+'\nbb=compute(aa)\nprint *,bb',fun(body='print *,xx\nrr=10/xx'),'1 0',{}),
]:
    add('runtime_'+name,prog(decl,body,procs),expected,category='invalid' if name=='active_loop_scalar' else 'runtime',baseline='reject' if name=='active_loop_scalar' else 'skip',**kw)


# Reproducible Cartesian stride matrix, computed independently in Python.
for sr in (1,2,-1,-2):
    for sc in (1,2,-1,-2):
        ir=list(range(1,4,sr)) if sr>0 else list(range(3,0,sr))
        jc=list(range(1,5,sc)) if sc>0 else list(range(4,0,sc))
        a=f'aa({ir[0]}:{ir[-1]}:{sr},{jc[0]}:{jc[-1]}:{sc})'
        vals=[i+10*j for j in jc for i in ir]
        add(f'matrix_stride_{sr}_{sc}'.replace('-','m'),
            prog(f'integer::aa(3,4),bb({len(ir)},{len(jc)})',
                 init2('aa',3,4)+'\ncall copy_to('+a+',bb)\nprint *,bb',copy),vals)
add('impure_function_masked_reduction',prog('integer::aa(3),rr\nlogical::mm(3)',
    init('aa',[1,2,3])+'\nmm=.false.\nmm(2)=.true.\nrr=sum(compute(aa),mask=mm)\nprint *,rr',ff),[1,2,3,12],baseline='compile')
add('module_impure_elemental','''module actions
implicit none
contains
impure elemental subroutine step(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+1
end subroutine
end module
program main
use actions,only:step
implicit none
integer::aa(2)
aa=5
call step(aa)
print *,aa
end program
''',[5,5,6,6])
add('assumed_shape_elemental_call',prog('integer::aa(3)',init('aa',[1,2,3])+'\ncall wrapper(aa)\nprint *,aa',
    sub('pure',args='xx',decl='integer,intent(inout)::xx(:)',body='call bump(xx)',name='wrapper')+sub()),[2,3,4])
add('impure_function_array_argument',prog('integer::aa(3),rr',init('aa',[1,2,3])+'\nrr=reduce(compute(aa))\nprint *,rr',ff+
    fun('pure integer',name='reduce',decl='integer,intent(in)::xx(:)',body='rr=sum(xx)')),[1,2,3,36])
add('impure_function_two_references',prog('integer::aa(2),bb(2)',init('aa',[1,2])+'\nbb=compute(aa)+compute(aa)\nprint *,bb',ff),[1,2,1,2,22,24],baseline='compile')

add('character_scalar_input',prog('integer::aa(2)','call tag(aa,"item")\nprint *,aa',sub('impure elemental',args='xx,label',decl='integer,intent(out)::xx\ncharacter(len=*),intent(in)::label',body='print *,label\nxx=2',name='tag')),'item item 2 2')
add('impure_function_cache_loop_reset',prog('integer::aa(2),bb(2),i','aa=1\ndo i=1,2\nbb=compute(aa)\naa=aa+1\nend do\nprint *,bb',ff),[1,1,2,2,12,12])
add('runtime_fresh_local_each_element',prog('integer::aa(2)',init('aa',[1,2])+'\ncall act(aa)',sub('impure elemental',decl='integer,intent(inout)::xx\ninteger::local',body='if(xx==1)local=7\nxx=local\nprint *,xx',name='act')),7,category='runtime',baseline='skip',diagnostic='uninitialized')
add('runtime_out_partial_branch',prog('integer::aa(2),bb(2)',init('aa',[1,2])+'\nbb=9\ncall act(aa,bb)\nprint *,bb(1)\nprint *,bb(2)',sub(args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='if(src==1)dst=7',name='act')),7,category='runtime',baseline='skip',diagnostic='uninitialized')
add('runtime_dynamic_shape_before_io',prog('integer::aa(3),bb(3),n','aa=1\nn=2\ncall act(aa,bb(1:n))',sub('impure elemental',args='src,dst',decl='integer,intent(in)::src\ninteger,intent(out)::dst',body='print *,src\ndst=src',name='act')),category='runtime',baseline='skip')

add('impure_shape_only_inquiry',prog('integer::aa(3)','print *,size(compute(aa))',ff),3,baseline='compile')
add('empty_function_scalar_side_actual',prog('integer::aa(0),bb(0)','bb=combine(aa,compute(7))\nprint *,size(bb)',ff+
    fun(body='print *,xx\nrr=xx+yy',args='xx,yy',decl='integer,intent(in)::xx,yy',name='combine')),0,baseline='compile')
add('empty_subroutine_scalar_side_actual',prog('integer::aa(0)','call copy_to(compute(7),aa)\nprint *,size(aa)',ff+copy),0,baseline='compile')
add('nonempty_subroutine_scalar_side_once',prog('integer::aa(3)','call copy_to(compute(7),aa)\nprint *,aa',ff+copy),[7,17,17,17])
(ROOT/'manifest.json').write_text(json.dumps(dict(description=__doc__,cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} cases')
