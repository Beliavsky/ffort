#!/usr/bin/env python3
"""Independent source expectations for KIND, constructors, init and RANDOM_NUMBER."""
from pathlib import Path
from textwrap import dedent
import json
ROOT = Path(__file__).resolve().parent
CASES=[]
def add(name, source, expected='', category='success', baseline=None, **kw):
    source=dedent(source).strip()+'\n'
    if baseline is None: baseline='run' if category=='success' else 'compile' if category in ('runtime','unsupported') else 'reject'
    if not isinstance(expected,str): expected=' '.join(map(str,expected)) if isinstance(expected,(list,tuple)) else str(expected)
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(source)
    CASES.append(dict(name=name, source=f'cases/{name}.f90', category=category, baseline=baseline, expected_stdout=expected, **kw))
def prog(decl, body, procs=''):
    return f'program p\nimplicit none\n{decl}\n{body}\n'+('contains\n'+procs+'\n' if procs else '')+'end program p\n'
def init(name, values, lo=1): return '\n'.join(f'{name}({j+lo})={v}' for j,v in enumerate(values))
def rands(n): return ' '.join(['R']*n)
mean_module='''module m
implicit none
integer, parameter :: dp = kind(1.0d0)
contains
function mean(x) result(y)
real(kind=dp), intent(in) :: x(:)
real(kind=dp)             :: y
y = sum(x)/size(x)
end function mean
end module m
'''
add('user_exact_mean_initialized', mean_module+'''
program main
use m
implicit none
real(kind=dp) :: x(3) = [10.0_dp, 20.0_dp, 30.0_dp]
print*,mean(x)
end program main''',20.0,source_message='Sentinel_f8ebe0b63e008191a1baeb322e4d87c6')
add('user_exact_mean_random', mean_module+'''
program main
use m
implicit none
real(kind=dp) :: x(1000)
call random_number(x)
print*,mean(x)
end program main''','R',source_message='Sentinel_537262b13c7081918d28bbbb2b7736e2', random=True, repeatable=True)
# Kind inquiries are scalar integer metadata, not value evaluation.
for text,expected in [('17',4),('1.0',4),('1.0d0',8),('1.0_4',4),('1.0_8',8),('.true.',4),("'abc'",1)]:
    add('kind_literal_'+str(len(CASES)),prog('',f'print *,kind({text})'),expected)
add('kind_keyword_mixed_case',prog('', 'print *,KiNd(X=1.0d0)'),8)
add('kind_nested_parameter',prog('integer,parameter::dp=kind(1d0),n=kind(dp)\nreal(dp)::aa(n)=[1.0_dp,2.0_dp,3.0_dp,4.0_dp]','print *,dp,n,kind(aa),sum(aa)'),[8,4,8,10.0])
add('kind_parameter_in_type_selector',prog('real(kind=kind(1d0))::aa=1.125d0','print *,kind(aa),aa'),[8,1.125])
add('kind_undefined_scalar',prog('integer::ii\nreal::ss\nreal(8)::dd\nlogical::ll','print *,kind(ii),kind(ss),kind(dd),kind(ll)'),[4,4,8,4])
add('kind_undefined_arrays',prog('real(8)::aa(-1:2),bb(2,3)','print *,kind(aa),kind(bb),kind(aa(2:1)),kind(bb(1,:))'),[8]*4)
add('kind_undefined_arithmetic',prog('real(8)::aa\ninteger::ii','print *,kind(1.0d0/aa),kind(1/ii)'),[8,4])
add('kind_unevaluated_subscripts',prog('real(8)::aa(2)\ninteger::ii','print *,kind(aa(ii)),kind(aa(999))'),[8,8])
add('kind_array_reduction',prog('real(8)::aa(2,3)','print *,kind(sum(aa)),kind(sum(aa,dim=1))'),[8,8])
add('kind_impure_function_not_called',prog('integer::aa','print *,kind(noisy(aa))','impure elemental real(8) function noisy(xx) result(yy)\ninteger,intent(in)::xx\nprint *,991\nyy=1.0d0\nend function'),8)
add('kind_ordinary_function_not_called',prog('integer::aa','print *,kind(no_value(aa))','real(8) function no_value(xx) result(yy)\ninteger,intent(in)::xx\nend function'),8)
for label, call in [('missing','kind()'),('extra','kind(1,2)'),('bad_keyword','kind(y=1)'),('duplicate','kind(x=1,x=2)'),('keyword_positional','kind(x=1,2)')]:
    add('kind_invalid_'+label,prog('',f'print *,991\nprint *,{call}'),category='invalid')
# Constructors exercise syntax, types, flattening, snapshots, contexts and kinds.
for syntax,left,right in [('bracket','[',']'),('slash','(/','/)')]:
    for typ, vals, exp in [('integer','1,-2,3',[1,-2,3]),('real','1.25,-2.5,3.75',[1.25,-2.5,3.75]),('real8','1.25d0,-2.5d0,3.75d0',[1.25,-2.5,3.75]),('logical','.true.,.false.,.true.','T F T')]:
        decl={'integer':'integer','real':'real','real8':'real(8)','logical':'logical'}[typ]
        add('constructor_'+syntax+'_'+typ,prog(f'{decl}::aa(3)',f'aa={left}{vals}{right}\nprint *,aa'),exp)
add('constructor_single_element',prog('integer::aa(1)','aa=[7]\nprint *,aa'),7)
add('constructor_nested',prog('integer::aa(5)','aa=[1,[2,3],(/4,5/)]\nprint *,aa'),[1,2,3,4,5])
add('constructor_array_flattening',prog('integer::aa(-1:1),bb(7)',init('aa',[10,20,30],-1)+'\nbb=[aa,7,aa(1:-1:-1)]\nprint *,bb'),[10,20,30,7,30,20,10])
add('constructor_empty_array_items',prog('real(8)::aa(0),bb(2)','bb=[aa,1d0,aa,2d0,aa]\nprint *,bb,kind([aa,1d0])'),[1.0,2.0,8])
add('constructor_all_empty_items',prog('integer::aa(0),bb(0)','bb=[aa,aa]\nprint *,size(bb),sum([aa])'),[0,0])
add('constructor_array_expression_item',prog('integer::aa(2),bb(5)',init('aa',[2,3])+'\nbb=[aa+1,9,aa*2]\nprint *,bb'),[3,4,9,4,6])
add('constructor_assignment_snapshot',prog('integer::aa(4)',init('aa',[1,2,3,4])+'\naa=[aa(4),aa(3),aa(2),aa(1)]\nprint *,aa'),[4,3,2,1])
add('constructor_section_snapshot',prog('integer::aa(5)',init('aa',[1,2,3,4,5])+'\naa(1:5:2)=[aa(5),aa(3),aa(1)]\nprint *,aa'),[5,2,3,4,1])
add('constructor_intrinsic_inputs',prog('','print *,sum([2,3,4]),product([2,3,4]),dot_product([1,2],[3,4]),size([1,2])'),[9,24,11,2])
add('constructor_print',prog('','print *,[1,2,3],(/4,5/)'),[1,2,3,4,5])
add('constructor_keyword_call',prog('','print *,twice(xx=[1d0,2d0])','real(8) function twice(xx) result(yy)\nreal(8),intent(in)::xx(:)\nyy=2*sum(xx)\nend function'),6.0)
add('constructor_dynamic_item_extent',prog('integer::aa(3),bb(4),nn',init('aa',[1,2,3])+'\nnn=2\nbb=[aa(:nn),7,8]\nprint *,bb'),[1,2,7,8])
add('constructor_continued',prog('real(8)::aa(3)','aa=[1d0, &\n! a comment\n& 2d0,3d0]\nprint *,aa'),[1.0,2.0,3.0])
add('constructor_impure_order_once',prog('integer::aa(3)','aa=[noisy(1),noisy(2),noisy(3)]\nprint *,aa','impure elemental integer function noisy(xx) result(yy)\ninteger,intent(in)::xx\nprint *,xx\nyy=10*xx\nend function'),[1,2,3,10,20,30])
for label, expr in [('type_mix','[1,2.0]'),('kind_mix','[1.0,2d0]'),('logical_mix','[.true.,1]'),('trailing_comma','[1,2,]'),('missing_close','[1,2'),('empty','[]')]:
    add('constructor_invalid_'+label,prog('integer::aa(2)',f'print *,991\naa={expr}'),category='invalid')
for label,expr in [('typed','[integer::1,2]'),('typed_empty','[integer::]'),('implied_do','[(ii,ii=1,2)]')]:
    add('constructor_unsupported_'+label,prog('integer::aa(2),ii',f'aa={expr}' if label!='typed_empty' else 'print *,size('+expr+')'),
        expected='0' if label=='typed_empty' else '', category='success' if label in ('typed_empty','implied_do') else 'unsupported')
add('constructor_rank_two_item_unsupported',prog('integer::aa(2,2),bb(4)','aa=1\nbb=[aa]'),category='unsupported')
add('constructor_runtime_undefined_item',prog('integer::aa(2),zz','print *,71\naa=[1,zz]\nprint *,aa'),71,category='runtime',baseline='skip',diagnostic='uninitialized')
add('constructor_runtime_extent',prog('integer::aa(3),bb(4),nn','aa=1\nnn=2\nprint *,72\nbb=[aa(:nn),7]\nprint *,bb'),72,category='runtime',baseline='compile')
add('constructor_runtime_zero_stride',prog('integer::aa(3),bb(2),ss','aa=1\nss=0\nprint *,73\nbb=[aa(::ss)]\nprint *,bb'),73,category='runtime',baseline='compile',diagnostic='stride')
# Declaration initialization is evaluated once; procedure-local SAVE remains unsupported.
for typ, initval, expected in [('integer','3',[3]*4),('real','1.5',[1.5]*4),('real(8)','1.5d0',[1.5]*4),('logical','.true.','T T T T')]:
    add('array_init_scalar_'+str(len(CASES)),prog(f'{typ}::aa(-1:2)={initval}','print *,aa'),expected)
add('array_init_rank_two',prog('integer::aa(-1:0,2:4)=7','print *,aa'),[7]*6)
add('array_init_empty_scalar',prog('real(8)::aa(0)=3d0,bb(2,0)=4d0','print *,size(aa),size(bb)'),[0,0])
add('array_init_constructor_conversion',prog('real(8)::aa(3)=[1,2,3]\ninteger::bb(3)=[1.9,-2.9,3.1]','print *,aa,bb'),[1.0,2.0,3.0,1,-2,3])
add('array_init_multi_declarator',prog('integer,parameter::nn=3\ninteger::aa(nn)=[1,2,3],zz=4,bb(nn)=7','print *,aa,zz,bb'),[1,2,3,4,7,7,7])
add('array_init_parameter_expressions',prog('integer,parameter::nn=3,kk=4\ninteger::aa(nn)=[kk,kk+1,kk*2]','print *,aa'),[4,5,8])
add('array_init_nested',prog('real(8)::aa(3)=[1d0,[2d0,3d0]]','print *,aa'),[1.0,2.0,3.0])
add('array_init_mutation',prog('integer::aa(3)=[1,2,3]','aa(2)=9\nprint *,aa'),[1,9,3])
add('array_init_module_parameter',mean_module+'''program main
use m, only: dp,mean
implicit none
real(dp)::aa(3)=[10._dp,20._dp,30._dp]
print *,kind(aa),mean(aa)
end program''',[8,20.0])
for label, decl in [('extent','integer::aa(3)=[1,2]'),('rank','integer::aa(2,2)=[1,2,3,4]'),('logical_numeric','logical::aa(2)=[1,2]'),('variable','integer::zz=3\ninteger::aa(2)=[zz,zz]'),('forward','integer::aa(2)=[nn,nn]\ninteger,parameter::nn=2'),('self','integer::aa(2)=[aa(1),1]')]:
    add('array_init_invalid_'+label,prog(decl,'print *,991'),category='invalid')
add('array_init_unsupported_parameter',prog('integer,parameter::aa(3)=[1,2,3]','print *,aa'),category='unsupported')
add('array_init_unsupported_local_save',prog('','call work()','subroutine work()\ninteger::aa(2)=[1,2]\nprint *,aa\nend subroutine'),category='unsupported')
add('array_init_invalid_constant_divzero',prog('real::aa(2)=[1.0,1.0/0.0]','print *,991'),category='invalid')
# Random harvest destinations. R placeholders validate each value independently.
for kind in (4,8):
    for rank, dims,n in [('scalar','',1),('vector','(9)',9),('matrix','(-1:1,2:4)',9)]:
        add(f'random_real{kind}_{rank}',prog(f'real({kind})::aa{dims}',f'call random_number(aa)\nprint *,kind(aa),aa'),str(kind)+' '+rands(n),random=True,repeatable=True)
    add(f'random_real{kind}_keyword',prog(f'real({kind})::aa(3)','call RANDOM_NUMBER(HaRvEsT=aa)\nprint *,aa'),rands(3),random=True)
    add(f'random_real{kind}_distribution_smoke',prog(f'real({kind})::aa(4096)','call random_number(aa)\nprint *,aa'),random=True,statistics=4096,repeatable=True)
add('random_scalar_element',prog('real(8)::aa(3)=-1d0','call random_number(aa(2))\nprint *,aa'),'-1 R -1',random=True)
add('random_strided_section',prog('real(8)::aa(-2:3)=-1d0','call random_number(aa(-2:3:2))\nprint *,aa'),'R -1 R -1 R -1',random=True)
add('random_reverse_section',prog('real::aa(5)=-1.0','call random_number(aa(5:1:-2))\nprint *,aa'),'R -1 R -1 R',random=True)
add('random_rank_two_sections',prog('real(8)::aa(3,4)=-1d0','call random_number(aa(3:1:-2,4:1:-2))\nprint *,aa'),'-1 -1 -1 R -1 R -1 -1 -1 R -1 R',random=True)
add('random_rank_reduced_section',prog('real::aa(3,3)=-1.0','call random_number(aa(2,3:1:-1))\nprint *,aa'),'-1 R -1 -1 R -1 -1 R -1',random=True)
add('random_empty_arrays',prog('real::aa(0),bb(2,0)','call random_number(aa)\ncall random_number(bb)\nprint *,size(aa),size(bb)'),[0,0])
add('random_empty_section',prog('real(8)::aa(3)=-1d0','call random_number(aa(2:1))\nprint *,aa'),[-1]*3)
add('random_preserve_unselected_defined',prog('real::aa(5)','aa(1)=8\naa(5)=9\ncall random_number(aa(2:4))\nprint *,aa'),'8 R R R 9',random=True)
add('random_out_dummy',prog('real(8)::aa(3)','call fill(aa)\nprint *,aa','subroutine fill(xx)\nreal(8),intent(out)::xx(:)\ncall random_number(xx)\nend subroutine'),rands(3),random=True)
add('random_inout_dummy_section',prog('real(8)::aa(5)=-1d0','call fill(aa(1:5:2))\nprint *,aa','subroutine fill(xx)\nreal(8),intent(inout)::xx(:)\ncall random_number(xx)\nend subroutine'),'R -1 R -1 R',random=True)
add('random_impure_elemental_subroutine',prog('real::aa(3)','call fill(aa)\nprint *,aa','impure elemental subroutine fill(xx)\nreal,intent(out)::xx\ncall random_number(xx)\nend subroutine'),rands(3),random=True)
add('random_repeated_calls_advance',prog('real(8)::aa(4),bb(4)','call random_number(aa)\ncall random_number(bb)\nprint *,aa,bb'),rands(8),random=True,repeatable=True,distinct_halves=True)
for label, decl, call in [('integer','integer::aa','random_number(aa)'),('logical','logical::aa','random_number(aa)'),('constant','real,parameter::aa=1.0','random_number(aa)'),('expression','real::aa','random_number(aa+1.0)'),('literal','','random_number(1.0)'),('missing','','random_number()'),('extra','real::aa,bb','random_number(aa,bb)'),('bad_keyword','real::aa','random_number(x=aa)'),('duplicate','real::aa','random_number(aa,harvest=aa)'),('constructor','','random_number([1.0,2.0])')]:
    add('random_invalid_'+label,prog(decl,'print *,991\ncall '+call),category='invalid')
add('random_invalid_intent_in',prog('real::aa','aa=1\ncall fill(aa)','subroutine fill(xx)\nreal,intent(in)::xx\ncall random_number(xx)\nend subroutine'),category='invalid')
for prefix in ('pure','elemental'):
    add('random_invalid_'+prefix,prog('real::aa','call fill(aa)',prefix+' subroutine fill(xx)\nreal,intent(out)::xx\ncall random_number(xx)\nend subroutine'),category='invalid')
add('random_invalid_function_expression',prog('real::aa','aa=random_number(aa)\nprint *,991'),category='invalid')
add('random_seed_unsupported',prog('','call random_seed()\nprint *,991'),991, boundary_note='Historical fixture name retained; no-argument RANDOM_SEED is now supported. SIZE/PUT/GET remain unsupported.')
add('random_runtime_oob',prog('real::aa(3)\ninteger::ii','ii=4\nprint *,81\ncall random_number(aa(ii))\nprint *,991'),81,category='runtime',baseline='compile',diagnostic='bound')
add('random_runtime_stride_zero',prog('real::aa(3)\ninteger::ss','ss=0\nprint *,82\ncall random_number(aa(::ss))\nprint *,991'),82,category='runtime',baseline='compile',diagnostic='stride')
add('random_runtime_uninitialized_subscript',prog('real::aa(3)\ninteger::ii','print *,83\ncall random_number(aa(ii))\nprint *,991'),83,category='runtime',baseline='skip',diagnostic='uninitialized')
add('random_runtime_unselected_undefined',prog('real::aa(3)','call random_number(aa(2))\nprint *,84\nprint *,aa(1)'),84,category='runtime',baseline='skip',diagnostic='uninitialized')
add('random_runtime_budget',prog('real::aa(1000)','call random_number(aa)\nprint *,991'),category='runtime',baseline='skip',args=['--max-steps','20'],diagnostic='limit')
# Shape/type inquiries may appear in constant contexts without reading values.
add('kind_undefined_variable_parameter',prog('real(8)::zz\ninteger,parameter::kk=kind(zz)\nreal(kk)::aa(2)=[1.0_kk,2.0_kk]','print *,kk,aa'),[8,1.0,2.0])
add('kind_real32_rounding',prog('integer,parameter::sp=kind(1.0),dp=kind(1d0)\nreal(sp)::aa(2)=[16777217.0_sp,16777216.0_sp]\nreal(dp)::bb(2)=[16777217.0_dp,16777216.0_dp]','print *,aa(1)-aa(2),bb(1)-bb(2),kind(aa),kind(bb)'),[0.0,1.0,4,8])
# Candidate-only metamorphic stream assertions check traversal order and that
# zero-size destinations and type-only inquiries do not consume values.
add('random_stream_vector',prog('real(8)::aa(6)','call random_number(aa)\nprint *,aa'),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_matrix',prog('real(8)::aa(2,3)','call random_number(aa)\nprint *,aa'),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_scalar',prog('real(8)::aa\ninteger::ii','do ii=1,6\ncall random_number(aa)\nprint *,aa\nend do'),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_reverse',prog('real(8)::aa(6)','call random_number(aa(6:1:-1))\nprint *,aa'),rands(6),random=True,stream_group='real8',stream_order=list(range(5,-1,-1)))
add('random_stream_strided',prog('real(8)::aa(11)','call random_number(aa(1:11:2))\nprint *,aa(1:11:2)'),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_empty',prog('real(8)::aa(6),bb(0),cc(2,0)','call random_number(bb)\ncall random_number(cc)\ncall random_number(aa(3:1))\ncall random_number(aa)\nprint *,aa'),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_kind',prog('real(8)::aa(6)\ninteger::kk','kk=kind(draw(1))\ncall random_number(aa)\nprint *,aa','impure elemental real(8) function draw(ii) result(xx)\ninteger,intent(in)::ii\ncall random_number(xx)\nend function'),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
# Resource limits are checked, including constructed results larger than storage.
add('constructor_runtime_expanded_limit',prog('integer::aa(32768),nn','aa=1\nnn=32768\nprint *,91\nprint *,sum([aa(:nn),aa(:nn),aa(:nn)])'),91,category='runtime',baseline='compile')
add('constructor_static_expanded_limit',prog('integer::aa(32768)','aa=1\nprint *,991\nprint *,sum([aa,aa,aa])'),category='unsupported')
add('constructor_runtime_work_budget',prog('integer::aa(1000),bb(1000)','aa=1\nbb=[aa]\nprint *,991'),category='runtime',baseline='skip',args=['--max-steps','20'],diagnostic='limit')
add('array_init_storage_limit',prog('integer::aa(65537)=1','print *,991'),category='unsupported')
add('constructor_runtime_arithmetic_overflow',prog('integer::aa(2),vv','vv=2147483647\nprint *,92\naa=[vv,1]+1\nprint *,aa'),92,category='runtime',baseline='compile',diagnostic='overflow')
large_items=', &\n'.join(','.join(str(i) for i in range(start,min(start+15,1001))) for start in range(1,1001,15))
add('constructor_thousand_items',prog('integer::aa(1000)=[ &\n'+large_items+']','print *,size(aa),sum(aa),aa(1),aa(1000)'),[1000,500500,1,1000])
add('array_init_expression_conversion',prog('real(8)::aa(3)=[1,2,3]*2','print *,aa'),[2.0,4.0,6.0])
add('parameter_constructor_reduction',prog('integer,parameter::nn=sum([1,2])\ninteger::aa(nn)=[7,8,9]','print *,nn,aa'),[3,7,8,9])
add('kind_dynamic_undefined_section',prog('real(8)::aa(3)\ninteger::ii,jj,ss','print *,kind(aa(ii:jj:ss))'),8)
add('kind_constructor_undefined_values',prog('real(8)::aa\ninteger,parameter::kk=kind([aa,1d0])','print *,kk'),8)
add('constructor_impure_elemental_array_once',prog('integer::aa(2),bb(3)','aa=[1,2]\nbb=[noisy(aa),9]\nprint *,bb','impure elemental integer function noisy(xx) result(yy)\ninteger,intent(in)::xx\nprint *,xx\nyy=10*xx\nend function'),[1,2,10,20,9])
add('constructor_impure_reduction_once',prog('integer::aa(2),vv','aa=[1,2]\nvv=sum([noisy(aa),9])\nprint *,vv','impure elemental integer function noisy(xx) result(yy)\ninteger,intent(in)::xx\nprint *,xx\nyy=10*xx\nend function'),[1,2,39])
add('kind_constructor_impure_not_called',prog('','print *,kind([noisy(1),noisy(2)])','impure elemental integer function noisy(xx) result(yy)\ninteger,intent(in)::xx\nprint *,xx\nyy=10*xx\nend function'),4)
# Nested random draws while freezing another RANDOM_NUMBER destination must be
# reentrant and consume the same shared stream, including an empty destination.
bound_proc='impure elemental integer function bound(nn) result(rr)\ninteger,intent(in)::nn\nreal(8)::dd\ncall random_number(dd)\nprint *,dd\nrr=nn\nend function'
add('random_stream_nested_bound',prog('real(8)::aa(5)','call random_number(aa(1:bound(5)))\nprint *,aa',bound_proc),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_nested_empty_bound',prog('real(8)::aa(5)','call random_number(aa(bound(6):5))\ncall random_number(aa)\nprint *,aa',bound_proc),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
add('random_stream_nested_two_bounds',prog('real(8)::aa(2,2)','call random_number(aa(1:bound(2),1:bound(2)))\nprint *,aa',bound_proc),rands(6),random=True,stream_group='real8',stream_order=list(range(6)))
# Literal/named REAL selectors retain their prior grammar. The extension is a
# direct KIND inquiry, including array/type-only inquiry operands. Other legal
# constant-expression selectors are explicit unsupported boundary probes.
for label,selector in [('arithmetic','kind=4+4'),('positional_kind','kind(1d0)'),('positional_arithmetic','4+4'),('nested','kind=kind(1d0)+0'),('intrinsic','kind=int(8.0)')]:
    supported=label=='positional_kind'
    add('real_selector_'+label,prog('real('+selector+')::aa=1.125d0','print *,kind(aa),aa'),[8,1.125] if supported else '',category='success' if supported else 'unsupported',boundary_note='REAL selectors support literals, named parameters and direct KIND inquiries; general constant expressions remain outside the subset.')
add('real_selector_undefined_array_kind',prog('real(8)::aa(3)\nreal(kind=kind(aa))::bb=1.125d0','print *,kind(bb),bb'),[8,1.125])
add('real_selector_constructor_kind',prog('real(kind=kind([1d0,2d0]))::aa=1.125d0','print *,kind(aa),aa'),[8,1.125])
add('real_selector_procedure_header',prog('','print *,identity(1.125d0)','real(kind=4+4) function identity(xx) result(yy)\nreal(kind=4+4),intent(in)::xx\nyy=xx\nend function'),category='unsupported',boundary_note='General constant-expression REAL selectors remain outside the subset; source preserved as an unsupported boundary test.')
add('real_selector_direct_kind_procedure_header',prog('','print *,identity(1.125d0)','real(kind=kind(1d0)) function identity(xx) result(yy)\nreal(kind=kind(1d0)),intent(in)::xx\nyy=xx\nend function'),category='unsupported',boundary_note='Typed function headers retain literal/named parameter selectors. Direct KIND is supported in explicit declarations instead.')
add('real_selector_direct_kind_result_declaration',prog('','print *,identity(1.125d0)','function identity(xx) result(yy)\nreal(kind=kind(1d0)),intent(in)::xx\nreal(kind=kind(1d0))::yy\nyy=xx\nend function'),1.125)
for label,decl in [('mutable','integer::kk=8\nreal(kind=kk)::aa'),('noninteger','real(kind=8.0)::aa'),('array','real(kind=[8])::aa'),('zero','real(kind=0)::aa')]:
    add('real_selector_invalid_'+label,prog(decl,'print *,991'),category='invalid')
add('real_selector_unsupported_16',prog('real(kind=16)::aa','print *,991'),category='unsupported')
for label,selector in [('abs','abs(-8)'),('max','max(4,8)'),('min','min(8,16)'),('mod','mod(17,9)'),('sum','sum([4,4])'),('product','product([2,4])'),('size','size([1,2,3,4,5,6,7,8])'),('power','2**3'),('division','16/2')]:
    add('real_selector_const_'+label,prog('real(kind='+selector+')::aa=1.125d0','print *,kind(aa),aa'),category='unsupported',boundary_note='General constant-expression REAL selectors remain outside the subset; source preserved as an unsupported boundary test.')
add('random_number_user_shadow_unsupported',prog('real::aa','call random_number(aa)\nprint *,aa','subroutine random_number(xx)\nreal,intent(out)::xx\nxx=0.25\nend subroutine'),category='unsupported',boundary_note='RANDOM_NUMBER is reserved by the subset; explicit user procedures with this name are rejected, never silently treated as intrinsic calls.')
# Features supported in 0.17.0; preserve every original source fixture.
SUPPORTED_017 = {'array_init_unsupported_parameter': '1 2 3'}
for row in CASES:
    if row['name'] in SUPPORTED_017:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_017[row['name']])

# Retain historical capacity fixtures, accepted by the current larger default.
# Current-cap tests are generated from fi_ir in tests/array_limits/run_tests.py.
ARRAY_LIMIT_MIGRATIONS = {'constructor_runtime_expanded_limit': '91 98304', 'constructor_static_expanded_limit': '991 98304', 'array_init_storage_limit': '991'}
for row in CASES:
    if row['name'] in ARRAY_LIMIT_MIGRATIONS:
        row.update(category='success', baseline='run', expected_stdout=ARRAY_LIMIT_MIGRATIONS[row['name']],
                   note='Historical 65536-element cap probe; legal with the larger cap.')
        row.pop('diagnostic', None)

(ROOT/'manifest.json').write_text(json.dumps(dict(cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} cases')
