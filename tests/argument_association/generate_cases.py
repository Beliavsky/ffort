#!/usr/bin/env python3
"""Regenerate independent argument-association fixtures and specified expectations."""
from pathlib import Path
import json
import math

ROOT = Path(__file__).resolve().parent
(ROOT/'cases').mkdir(exist_ok=True)
CASES = []


def add(name, source, expected='', category='success', baseline='run', **kw):
    file = f'cases/{name}.f90'
    (ROOT/file).write_text(source.strip()+'\n')
    CASES.append(dict(name=name, source=file, category=category,
                      baseline=baseline, expected_stdout=str(expected), **kw))


def prog(body, decl='', procedures='', uses=''):
    return f'program main\n{uses}\nimplicit none\n{decl}\n{body}\n'+(
        'contains\n'+procedures+'\n' if procedures else '')+'end program main\n'


def sub(decl, body, args='x', name='change', prefix=''):
    return f'{prefix}subroutine {name}({args})\n{decl}\n{body}\nend subroutine {name}'


def fun(decl, body, args='x', name='inspect', typ='integer'):
    return f'{typ} function {name}({args}) result(r)\n{decl}\n{body}\nend function {name}'


def runtime(name, source, expected='', **kw):
    add(name, source, expected, category='runtime', baseline='compile', **kw)


def invalid(name, source, baseline='reject', **kw):
    add(name, source, category='invalid', baseline=baseline, **kw)


def array_init(name='a', lower=1, upper=5):
    return '\n'.join(f'{name}({i})={j}' for j, i in enumerate(range(lower, upper+1), 1))


# Scalar association, including previously undefined storage and frozen subscripts.
for typ, value, expected in [('integer','17','17'),('real','2.5','2.5'),
                             ('real(8)','1.000000000001_8','1.000000000001'),
                             ('logical','.true.','T')]:
    tag = typ.replace('(','').replace(')','')
    add('scalar_out_'+tag, prog('call change(a)\nprint *,a', f'{typ} :: a',
        sub(f'{typ}, intent(out) :: x', 'x='+value)), expected,
        rel_tol=1e-13, abs_tol=1e-15)
add('scalar_inout', prog('a=4\ncall change(a)\ncall change(a)\nprint *,a',
    'integer :: a',sub('integer, intent(inout) :: x','x=x*3+1')), '40')
add('undefined_inout_defined_before_read',prog('call change(a)\nprint *,a',
    'integer :: a',sub('integer, intent(inout) :: x','x=8')), '8')
add('scalar_element_out',prog('a=9\ncall change(a(-1))\nprint *,a',
    'integer :: a(-2:2)',sub('integer, intent(out) :: x','x=4')),'9 4 9 9 9')
add('scalar_element_inout',prog('a=9\ncall change(a(0))\nprint *,a',
    'integer :: a(-2:2)',sub('integer, intent(inout) :: x','x=x-4')),'9 9 5 9 9')
add('frozen_element_subscript',prog('a=0\ni=2\ncall change(a(i),i)\nprint *,a,i',
    'integer :: a(4),i',sub('integer, intent(out) :: x,j','j=4\nx=7',args='x,j')),
    '0 7 0 0 4')
add('expression_input_before_out',prog('a=4\ncall change(a+3,a)\nprint *,a',
    'integer :: a',sub('integer, intent(in) :: y\ninteger, intent(out) :: x',
    'x=y*2',args='y,x')),'14')
add('output_inside_subroutine',prog('call change(a)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x','x=11\nprint *,x')),'11 11')
add('pure_subroutine_inout',prog('a=4\ncall change(a)\nprint *,a','integer :: a',
    sub('integer, intent(inout) :: x','x=x+1',prefix='pure ')),'5')
add('out_used_as_loop_variable',prog('call change(a)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x','do x=1,3\nend do')),'4')
add('nested_scalar_forwarding',prog('a=2\ncall change(a)\nprint *,a','integer :: a',
    sub('integer, intent(inout) :: x','call next(x)\nx=x*2')+'\n'+
    sub('integer, intent(inout) :: x','x=x+3',name='next')),'10')
add('nested_out_to_inout',prog('call change(a)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x','call next(x)')+'\n'+
    sub('integer, intent(inout) :: x','x=19',name='next')),'19')
add('nested_out_to_out',prog('a=99\ncall change(a)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x','x=1\ncall next(x)')+'\n'+
    sub('integer, intent(out) :: x','x=22',name='next')),'22')
add('unused_undefined_in',prog('call change(a)\nprint *,7','integer :: a',
    sub('integer, intent(in) :: x','return')),'7')
add('input_alias_read_only',prog('a=3\ncall change(a,a)','integer :: a',
    sub('integer, intent(in) :: x,y','print *,x+y',args='x,y')),'6')

# Rank-one array binding and inquiries; dummy indexing is independent of caller bounds.
add('array_input_nonunit_lower',prog(array_init(lower=-2,upper=2)+'\nprint *,inspect(a)',
    'integer :: a(-2:2)',fun('integer, intent(in) :: x(:)',
    'r=x(1)+10*x(5)+size(x)+lbound(x,1)+ubound(x,1)')),'62')
add('array_input_explicit_dummy_lower',prog(array_init(lower=-2,upper=2)+'\nprint *,inspect(a)',
    'integer :: a(-2:2)',fun('integer, intent(in) :: x(0:)',
    'r=x(0)+10*x(4)+size(x,1)+lbound(x,1)+ubound(x,1)')),'60')
add('array_input_negative_dummy_lower',prog(array_init()+'\nprint *,inspect(a)',
    'integer :: a(5)',fun('integer, intent(in) :: x(-3:)',
    'r=x(-3)+10*x(1)+lbound(x,1)+ubound(x,1)')),'49')
add('array_input_expression',prog(array_init()+'\nprint *,inspect(a+2*a)',
    'integer :: a(5)',fun('integer, intent(in) :: x(:)','r=x(1)+x(5)')),'18')
add('array_input_reverse_expression',prog(array_init()+'\nprint *,inspect(a(5:1:-2)+10)',
    'integer :: a(5)',fun('integer, intent(in) :: x(:)','r=x(1)+10*x(3)+size(x)')),'128')
add('array_input_partially_defined',prog('a(3)=6\nprint *,inspect(a)','integer :: a(5)',
    fun('integer, intent(in) :: x(:)','r=x(3)')),'6')
add('array_inout_partially_defined',prog('a(3)=6\ncall change(a)\nprint *,a','integer :: a(5)',
    sub('integer, intent(inout) :: x(:)','x=x(3)')),'6 6 6 6 6')
add('array_out_whole',prog('call change(a)\nprint *,a','integer :: a(-2:2)',
    sub('integer, intent(out) :: x(:)\ninteger :: i','do i=1,size(x)\nx(i)=i*2\nend do')),
    '2 4 6 8 10')
add('array_out_explicit_dummy_lower',prog('call change(a)\nprint *,a','integer :: a(5)',
    sub('integer, intent(out) :: x(-2:)\ninteger :: i',
    'do i=lbound(x,1),ubound(x,1)\nx(i)=i\nend do')),'-2 -1 0 1 2')
for name,section,expected in [
    ('stride','a(-2:2:2)','11 2 13 4 15'),
    ('reverse','a(2:-2:-1)','11 12 13 14 15'),
    ('reverse_stride','a(2:-2:-2)','11 2 13 4 15')]:
    add('array_inout_'+name,prog(array_init(lower=-2,upper=2)+f'\ncall change({section})\nprint *,a',
        'integer :: a(-2:2)',sub('integer, intent(inout) :: x(:)','x=x+10')),expected)
add('array_out_stride_preserves_others',prog('a=9\ncall change(a(1:5:2))\nprint *,a',
    'integer :: a(5)',sub('integer, intent(out) :: x(:)','x=4')),'4 9 4 9 4')
add('array_out_reverse_order',prog('a=0\ncall change(a(5:1:-2))\nprint *,a','integer :: a(5)',
    sub('integer, intent(out) :: x(:)\ninteger :: i','do i=1,size(x)\nx(i)=i\nend do')),
    '3 0 2 0 1')
add('array_inout_self_overlap_assignment',prog(array_init()+'\ncall change(a)\nprint *,a',
    'integer :: a(5)',sub('integer, intent(inout) :: x(:)','x(2:5)=x(1:4)')),'1 1 2 3 4')
add('array_inout_scalar_expansion_snapshot',prog(array_init()+'\ncall change(a)\nprint *,a',
    'integer :: a(5)',sub('integer, intent(inout) :: x(:)','x=x+x(1)')),'2 3 4 5 6')
add('array_disjoint_writable_sections',prog('a=0\ncall change(a(1:6:2),a(2:6:2))\nprint *,a',
    'integer :: a(6)',sub('integer, intent(out) :: x(:),y(:)','x=4\ny=9',args='x,y')),
    '4 9 4 9 4 9')
add('array_disjoint_input_output',prog(array_init(upper=6)+'\ncall change(a(1:3),a(4:6))\nprint *,a',
    'integer :: a(6)',sub('integer, intent(in) :: x(:)\ninteger, intent(out) :: y(:)',
    'y=x*2',args='x,y')),'1 2 3 2 4 6')
add('array_expression_snapshot_output',prog(array_init()+'\ncall change(a+0,a)\nprint *,a',
    'integer :: a(5)',sub('integer, intent(in) :: x(:)\ninteger, intent(out) :: y(:)',
    'y=x*2',args='x,y')),'2 4 6 8 10')
add('nested_array_forwarding',prog(array_init()+'\ncall change(a(5:1:-1))\nprint *,a',
    'integer :: a(5)',sub('integer, intent(inout) :: x(:)','call next(x(2:4:2))')+'\n'+
    sub('integer, intent(inout) :: y(0:)','y=y+20',args='y',name='next')),'1 22 3 24 5')
add('nested_array_out_forwarding',prog('a=9\ncall change(a)\nprint *,a','integer :: a(5)',
    sub('integer, intent(out) :: x(:)','call next(x)')+'\n'+
    sub('integer, intent(inout) :: y(:)','y=12',args='y',name='next')),'12 12 12 12 12')
add('nested_array_element_forwarding',prog(array_init()+'\ncall change(a(5:1:-1))\nprint *,a',
    'integer :: a(5)',sub('integer, intent(inout) :: x(:)','call next(x(2))')+'\n'+
    sub('integer, intent(inout) :: y','y=y+20',args='y',name='next')),'1 2 3 24 5')
add('array_inquiries_do_not_read_data',prog('call change(a)','integer :: a(-2:2)',
    sub('integer, intent(in) :: x(:)','print *,size(x),size(x,1),lbound(x,1),ubound(x,1)')),
    '5 5 1 5')
add('empty_array_output',prog('call change(a)\nprint *,size(a)','integer :: a(0)',
    sub('integer, intent(out) :: x(:)','x=7')),'0')
add('empty_section_output',prog('a=3\ncall change(a(4:2))\nprint *,a','integer :: a(5)',
    sub('integer, intent(out) :: x(:)','x=7')),'3 3 3 3 3')
add('empty_sections_no_alias',prog('a=3\ncall change(a(4:2),a(3:1))\nprint *,a',
    'integer :: a(5)',sub('integer, intent(out) :: x(:),y(:)','x=7\ny=8',args='x,y')),
    '3 3 3 3 3')
add('empty_dummy_inquiries',prog('call change(a)','integer :: a(2:1)',
    sub('integer, intent(in) :: x(-3:)','print *,size(x),lbound(x,1),ubound(x,1)')),
    '0 1 0')
for typ,init,operation,expected in [('real','1.25','x+0.5','1.75 1.75 1.75'),
        ('real(8)','1.0_8','x+1.0e-12_8','1.000000000001 1.000000000001 1.000000000001'),
        ('logical','.true.','.not. x','F F F')]:
    tag=typ.replace('(','').replace(')','')
    add('array_inout_'+tag,prog(f'a={init}\ncall change(a)\nprint *,a',f'{typ} :: a(3)',
        sub(f'{typ}, intent(inout) :: x(:)','x='+operation)),expected,
        rel_tol=1e-13,abs_tol=1e-15)
add('pure_array_output',prog('call change(a)\nprint *,a','integer :: a(3)',
    sub('integer, intent(out) :: x(:)','x=5',prefix='pure ')),'5 5 5')

# Parentheses make a read-only temporary, including when the underlying variable
# is also bound to a writable dummy. These are not overlapping direct bindings.
add('scalar_parenthesized_input_snapshot',prog('a=4\ncall change((a),a)\nprint *,a',
    'integer :: a',sub('integer, intent(in) :: x\ninteger, intent(out) :: y','y=x+2',args='x,y')),'6')
add('array_parenthesized_input_snapshot',prog(array_init()+'\ncall change((a),a)\nprint *,a',
    'integer :: a(5)',sub('integer, intent(in) :: x(:)\ninteger, intent(out) :: y(:)',
    'y=x*2',args='x,y')),'2 4 6 8 10')
add('section_parenthesized_input_snapshot',prog(array_init()+'\ncall change((a(5:1:-1)),a)\nprint *,a',
    'integer :: a(5)',sub('integer, intent(in) :: x(:)\ninteger, intent(out) :: y(:)',
    'y=x',args='x,y')),'5 4 3 2 1')
add('dynamic_triplet_frozen_before_out',prog('a=0\nlo=1\nhi=5\ns=2\ncall change(a(lo:hi:s),lo,hi,s)\nprint *,a,lo,hi,s',
    'integer :: a(5),lo,hi,s',sub('integer, intent(out) :: x(:),lo,hi,s',
    'lo=2\nhi=4\ns=1\nx=9',args='x,lo,hi,s')),'9 0 9 0 9 2 4 1')
add('array_unused_outside_endpoints',prog(array_init()+'\ncall change(a(1:6:2))\nprint *,a',
    'integer :: a(5)',sub('integer, intent(inout) :: x(:)','x=x+10')),'11 2 13 4 15')
add('empty_outside_endpoints',prog('a=1\ncall change(a(99:90))\nprint *,a',
    'integer :: a(3)',sub('integer, intent(out) :: x(:)','x=2')),'1 1 1')
add('different_array_extents',prog('a=1\nb=2\ncall change(a,b)\nprint *,a,b',
    'integer :: a(2),b(3)',sub('integer, intent(inout) :: x(:),y(:)',
    'x=x+size(y)\ny=y+size(x)',args='x,y')),'4 4 4 4 4')
add('array_repeated_dynamic_frames',prog(array_init()+'\nprint *,inspect(a(1:1)),inspect(a),inspect(a(3:4))',
    'integer :: a(5)',fun('integer, intent(in) :: x(:)','r=size(x)*100+x(1)+x(size(x))')),
    '102 506 207')
add('nested_array_input_expression',prog(array_init()+'\nprint *,inspect(a)',
    'integer :: a(5)',fun('integer, intent(in) :: x(:)','r=next(x(5:1:-2)+1)')+'\n'+
    fun('integer, intent(in) :: y(-2:)','r=y(-2)+10*y(0)',args='y',name='next')),'26')
add('dummy_lower_parameter',prog('call change(a)\nprint *,a','integer :: a(3)',
    sub('integer, parameter :: lo=-1\ninteger, intent(out) :: x(lo:)',
    'x(-1)=3\nx(0)=4\nx(1)=5')),'3 4 5')
add('array_readonly_duplicate_alias',prog(array_init()+'\ncall change(a,a(5:1:-1))',
    'integer :: a(5)',sub('integer, intent(in) :: x(:),y(:)',
    'print *,x(1),y(1)',args='x,y')),'1 5')
add('scalar_disjoint_elements',prog('a=0\ncall change(a(1),a(3))\nprint *,a',
    'integer :: a(3)',sub('integer, intent(out) :: x,y','x=4\ny=8',args='x,y')),'4 0 8')
add('dummy_lower_large_constant',prog('a=1\ncall change(a)\nprint *,a',
    'integer :: a(2)',sub('integer, intent(inout) :: x(200:)',
    'x(200)=3\nx(201)=5')),'3 5')

add('empty_dummy_minimum_lower',prog('call change(a)','integer :: a(0)',
    sub('integer, intent(in) :: x(-2147483647-1:)',
    'print *,size(x),lbound(x,1),ubound(x,1)')),'0 1 0')
add('dummy_minimum_lower_nonempty',prog('a=3\ncall change(a)\nprint *,a',
    'integer :: a(2)',sub('integer, intent(inout) :: x(-2147483647-1:)',
    'x(-2147483647-1)=4\nx(-2147483647)=8')),'4 8')
invalid('duplicate_intent_attributes',prog('a=1\ncall change(a)','integer :: a',
    sub('integer, intent(in), intent(out) :: x','return')))

# REAL64 element/section actuals must retain kind metadata independently from
# whole-array association, using both numeric and host-imported named kinds.
for kind_tag, typ, suffix, uses, declarations in [
    ('numeric','real(8)','8','',''),
    ('named','real(dp)','dp','use, intrinsic :: iso_fortran_env, only : real64',
     'integer, parameter :: dp=real64\n')]:
    declaration=declarations+typ+' :: a(5)'
    add('real64_'+kind_tag+'_section_in',prog('a=1.25_'+suffix+'\nprint *,inspect(a(5:1:-2))',
        declaration,fun(typ+', intent(in) :: x(:)','r=x(1)+x(3)',typ=typ),uses),'2.5',
        rel_tol=1e-13,abs_tol=1e-15)
    for intent in ('out','inout'):
        value='2.5_'+suffix if intent=='out' else 'x+1.0_'+suffix
        add('real64_'+kind_tag+'_section_'+intent,prog(
            'a=1.25_'+suffix+'\ncall change(a(5:1:-2))\nprint *,a',
            declaration,sub(typ+', intent('+intent+') :: x(:)','x='+value),uses),
            '2.5 1.25 2.5 1.25 2.5' if intent=='out' else '2.25 1.25 2.25 1.25 2.25',
            rel_tol=1e-13,abs_tol=1e-15)
        add('real64_'+kind_tag+'_element_'+intent,prog(
            'a=1.25_'+suffix+'\ncall change(a(2))\nprint *,a',
            declaration,sub(typ+', intent('+intent+') :: x','x='+value),uses),
            '1.25 2.5 1.25 1.25 1.25' if intent=='out' else '1.25 2.25 1.25 1.25 1.25',
            rel_tol=1e-13,abs_tol=1e-15)

# User-facing statistics example combines a module, input arrays and scalar outputs.
statistics = '''module statistics
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
contains
pure subroutine mean_stddev(x,mean_value,stddev)
real(dp), intent(in) :: x(:)
real(dp), intent(out) :: mean_value,stddev
integer :: i,n
n=size(x)
if(n<1) error stop 'empty sample'
mean_value=0.0_dp
do i=1,n
mean_value=mean_value+x(i)
end do
mean_value=mean_value/real(n)
stddev=0.0_dp
do i=1,n
stddev=stddev+(x(i)-mean_value)**2
end do
stddev=sqrt(stddev/real(n))
end subroutine mean_stddev
end module statistics
'''
add('module_mean_stddev',statistics+prog(
    'x(1)=2.0_dp\nx(2)=4.0_dp\nx(3)=4.0_dp\nx(4)=4.0_dp\nx(5)=5.0_dp\n'
    'x(6)=5.0_dp\nx(7)=7.0_dp\nx(8)=9.0_dp\ncall mean_stddev(x,m,s)\nprint *,m,s\n'
    'call mean_stddev(x(8:2:-2),m,s)\nprint *,m,s',
    'real(dp) :: x(8),m,s',uses='use statistics, only : dp,mean_stddev'),
    f'5 2 5.5 {math.sqrt(4.25):.17g}',rel_tol=2e-12,abs_tol=1e-13)

# Definedness is interpreter safety policy; GNU is compile-only for these programs.
runtime('out_clears_scalar_before_read',prog('a=7\ncall change(a)','integer :: a',
    sub('integer, intent(out) :: x','print *,x')))
runtime('out_unassigned_return',prog('a=7\ncall change(a)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x','return')))
runtime('out_early_return_later_read',prog('a=7\ncall change(a,.true.)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x\nlogical, intent(in) :: condition',
    'if(condition) return\nx=5',args='x,condition')))
runtime('inout_undefined_read',prog('call change(a)','integer :: a',
    sub('integer, intent(inout) :: x','x=x+1')))
runtime('in_undefined_read',prog('call change(a)','integer :: a',
    sub('integer, intent(in) :: x','print *,x')))
runtime('out_array_clears_before_read',prog('a=7\ncall change(a)','integer :: a(3)',
    sub('integer, intent(out) :: x(:)','print *,x(2)')))
runtime('out_array_partial_definedness',prog('a=7\ncall change(a)\nprint *,a(1)\nprint *,a(2)',
    'integer :: a(3)',sub('integer, intent(out) :: x(:)','x(1)=4')),'4')
runtime('out_section_partial_definedness',prog('a=7\ncall change(a(1:5:2))\nprint *,a(2),a(4),a(1)\nprint *,a(3)',
    'integer :: a(5)',sub('integer, intent(out) :: x(:)','x(1)=4')),'7 7 4')
runtime('nested_out_clears_outer',prog('call change(a)\nprint *,a','integer :: a',
    sub('integer, intent(out) :: x','x=3\ncall next(x)')+'\n'+
    sub('integer, intent(out) :: x','return',name='next')))
runtime('out_array_nested_clear',prog('a=1\ncall change(a)\nprint *,a(1)\nprint *,a(3)',
    'integer :: a(4)',sub('integer, intent(inout) :: x(:)','call next(x(2:3))')+'\n'+
    sub('integer, intent(out) :: x(:)','x(1)=3',name='next')),'1')
runtime('array_input_uninitialized_element',prog('a(1)=1\nprint *,inspect(a)','integer :: a(3)',
    fun('integer, intent(in) :: x(:)','r=x(2)')))
runtime('array_input_expression_reads_undefined',prog('a(1)=1\nprint *,inspect(a+1)',
    'integer :: a(3)',fun('integer, intent(in) :: x(:)','r=x(1)')))
runtime('dummy_array_bounds_error',prog('a=1\ncall change(a)','integer :: a(3)',
    sub('integer, intent(inout) :: x(:)','x(0)=3')))
runtime('dummy_shape_mismatch',prog('a=1\nb=2\ncall change(a,b)','integer :: a(3),b(2)',
    sub('integer, intent(out) :: x(:)\ninteger, intent(in) :: y(:)','x=y',args='x,y')))
runtime('zero_stride_actual',prog('a=1\ns=0\ncall change(a(1:3:s))','integer :: a(3),s',
    sub('integer, intent(inout) :: x(:)','x=3')))
runtime('out_of_bounds_actual_section',prog('a=1\ncall change(a(1:4))','integer :: a(3)',
    sub('integer, intent(inout) :: x(:)','x=3')))
runtime('out_of_bounds_actual_element',prog('a=1\ncall change(a(4))','integer :: a(3)',
    sub('integer, intent(out) :: x','x=3')))

# The interpreter deliberately rejects ambiguous writable aliasing, even when the
# particular callee would not violate Fortran's narrower access-based alias rules.
for name,decl,setup,actuals,params in [
    ('scalar_alias','integer :: a','a=1','a,a','integer, intent(out) :: x,y'),
    ('scalar_inout_alias','integer :: a','a=1','a,a','integer, intent(inout) :: x,y'),
    ('scalar_input_output_alias','integer :: a','a=1','a,a',
     'integer, intent(in) :: x\ninteger, intent(out) :: y'),
    ('array_whole_alias','integer :: a(5)','a=1','a,a','integer, intent(out) :: x(:),y(:)'),
    ('array_overlap_stride_alias','integer :: a(5)','a=1','a(1:5:2),a(3:5)',
     'integer, intent(out) :: x(:),y(:)'),
    ('array_reverse_alias','integer :: a(5)','a=1','a(5:1:-2),a(1:3)',
     'integer, intent(out) :: x(:),y(:)'),
    ('array_element_alias','integer :: a(5)','a=1','a,a(2)',
     'integer, intent(inout) :: x(:),y'),
    ('array_input_output_alias','integer :: a(5)','a=1','a,a',
     'integer, intent(in) :: x(:)\ninteger, intent(out) :: y(:)')]:
    runtime(name,prog(setup+f'\ncall change({actuals})',decl,
        sub(params,'return',args='x,y')))
runtime('nested_alias_forwarding',prog('a=1\ncall change(a)','integer :: a(4)',
    sub('integer, intent(inout) :: x(:)','call next(x(1:3),x(2:4))')+'\n'+
    sub('integer, intent(out) :: x(:),y(:)','return',args='x,y',name='next')))
# Runtime inquiry DIM validation is independent of array data initialization.
for intrinsic in ('size','lbound','ubound'):
    runtime('dynamic_'+intrinsic+'_bad_dim',prog('d=2\nprint *,'+intrinsic+'(a,d)',
        'integer :: a(3),d'))
add('dynamic_inquiry_valid_dim',prog('d=1\nprint *,size(a,d),lbound(a,d),ubound(a,d)',
    'integer :: a(-2:2),d'),'5 -2 2')
# The loop variable belongs to an outer call frame, so the active-binding guard
# rather than merely a main-program lexical check must prevent the inner call.
invalid('nested_active_do_variable',prog('a=0\ncall change(a)','integer :: a',
    sub('integer, intent(inout) :: x','do x=1,3\ncall next(x)\nend do')+'\n'+
    sub('integer, intent(out) :: x','x=8',name='next')))

# Work and storage policies are independent of the language oracle. The GNU
# baseline verifies source validity only; no GNU resource rejection is claimed.
runtime('call_array_element_cap',prog('print *,99\ncall change(a,a)','integer :: a(40000)',
    sub('integer, intent(in) :: x(:),y(:)','return',args='x,y')),'99',
    diagnostic='argument array element limit')
add('call_array_element_cap_boundary',prog('call change(a,a)','integer :: a(32768)',
    sub('integer, intent(in) :: x(:),y(:)','print *,size(x)+size(y)',args='x,y')),'65536')
runtime('call_copy_work_budget',prog('print *,99\ncall change(a)','integer :: a(100)',
    sub('integer, intent(in) :: x(:)','return')),'99',args=['--max-steps','50'],
    diagnostic='step limit')
runtime('call_out_work_budget',prog('print *,99\ncall change(a)','integer :: a(100)',
    sub('integer, intent(out) :: x(:)','x=3')),'99',args=['--max-steps','50'],
    diagnostic='step limit')
runtime('call_scalar_shared_budget',prog('a=0\nprint *,99\ndo i=1,100\ncall change(a)\nend do',
    'integer :: a,i',sub('integer, intent(inout) :: x','x=x+1')),'99',
    args=['--max-steps','50'],diagnostic='step limit')
runtime('call_nested_shared_budget',prog('a=0\nprint *,99\ndo i=1,100\ncall change(a)\nend do',
    'integer :: a,i',sub('integer, intent(inout) :: x','call next(x)')+'\n'+
    sub('integer, intent(inout) :: x','x=x+1',name='next')),'99',
    args=['--max-steps','70'],diagnostic='step limit')

# Compile-time exact type, kind, rank and definability checks.
for name,actual,decl,baseline in [
    ('literal','3','', 'reject'),('expression','a+1','integer :: a','reject'),
    ('parenthesized','(a)','integer :: a','reject'),
    ('parameter','a','integer, parameter :: a=2','reject'),
    ('function','inspect()','', 'reject')]:
    extra=fun('','r=3',args='') if name=='function' else ''
    invalid('out_reject_'+name,prog('print *,123\ncall change('+actual+')',decl,
        sub('integer, intent(out) :: x','x=1')+'\n'+extra),baseline=baseline)
for name,actual,decl in [('literal','3',''),('expression','a+1','integer :: a'),
                        ('parameter','a','integer, parameter :: a=2')]:
    invalid('inout_reject_'+name,prog('print *,123\ncall change('+actual+')',decl,
        sub('integer, intent(inout) :: x','x=1')))
invalid('forward_intent_in_to_out',prog('a=1\ncall change(a)','integer :: a',
    sub('integer, intent(in) :: x','call next(x)')+'\n'+
    sub('integer, intent(out) :: x','x=2',name='next')))
invalid('forward_array_intent_in_to_inout',prog('a=1\ncall change(a)','integer :: a(3)',
    sub('integer, intent(in) :: x(:)','call next(x(2:3))')+'\n'+
    sub('integer, intent(inout) :: x(:)','x=2',name='next')))
invalid('array_out_expression',prog('a=1\ncall change(a+1)','integer :: a(3)',
    sub('integer, intent(out) :: x(:)','x=2')))
invalid('array_inout_parenthesized',prog('a=1\ncall change((a))','integer :: a(3)',
    sub('integer, intent(inout) :: x(:)','x=2')))
for name,actual,decl,dummy in [
    ('out_integer_to_real','a','integer :: a','real, intent(out) :: x'),
    ('out_real_kind_mismatch','a','real(8) :: a','real, intent(out) :: x'),
    ('inout_logical_to_integer','a','logical :: a','integer, intent(inout) :: x'),
    ('scalar_to_array','a','integer :: a','integer, intent(inout) :: x(:)'),
    ('element_to_assumed_shape','a(1)','integer :: a(3)','integer, intent(inout) :: x(:)'),
    ('array_to_scalar','a','integer :: a(3)','integer, intent(out) :: x'),
    ('section_to_scalar','a(1:1)','integer :: a(3)','integer, intent(out) :: x'),
    ('array_kind_mismatch','a','real(8) :: a(3)','real, intent(inout) :: x(:)'),
    ('array_type_mismatch','a','logical :: a(3)','integer, intent(out) :: x(:)')]:
    invalid(name,prog('print *,123\ncall change('+actual+')',decl,sub(dummy,'return')))
invalid('function_writable_dummy',prog('a=1\nprint *,inspect(a)','integer :: a',
    fun('integer, intent(inout) :: x','x=x+1\nr=x')),baseline='compile')
invalid('explicit_shape_dummy_unsupported',prog('a=1\ncall change(a)','integer :: a(3)',
    sub('integer, intent(inout) :: x(3)','x=2')),baseline='compile')
invalid('assumed_size_dummy_unsupported',prog('a=1\ncall change(a)','integer :: a(3)',
    sub('integer, intent(inout) :: x(*)','x(1)=2')),baseline='compile')
invalid('rank_two_dummy_unsupported',prog('a=1\ncall change(a)','integer :: a(3)',
    sub('integer, intent(inout) :: x(:,:)','return')),baseline='reject')
invalid('array_dummy_initializer',prog('a=1\ncall change(a)','integer :: a(3)',
    sub('integer, intent(inout) :: x(:)=1','return')))
invalid('inquiry_scalar_argument',prog('a=1\nprint *,size(a)','integer :: a'))
invalid('inquiry_noninteger_dim',prog('a=1\nprint *,size(a,1.0)','integer :: a(3)'))
add('lbound_without_dimension',prog('a=1\nprint *,lbound(a)','integer :: a(3)'),'1')
invalid('inquiry_kind_keyword_unsupported',prog('a=1\nprint *,size(a,kind=8)','integer :: a(3)'),baseline='compile')
invalid('active_do_actual_direct',prog('do i=1,3\ncall change(i)\nend do','integer :: i',
    sub('integer, intent(out) :: x','x=8')))
# This is legal because the callee only reads the active DO variable.
add('active_do_input_allowed',prog('do i=1,3\ncall change(i)\nend do','integer :: i',
    sub('integer, intent(in) :: x','print *,x')),'1 2 3')

# Require the intended safety diagnostic, not merely any runtime failure.
undefined_cases = {
    'out_clears_scalar_before_read', 'out_unassigned_return',
    'out_early_return_later_read', 'inout_undefined_read', 'in_undefined_read',
    'out_array_clears_before_read', 'out_array_partial_definedness',
    'out_section_partial_definedness', 'nested_out_clears_outer',
    'out_array_nested_clear', 'array_input_uninitialized_element',
    'array_input_expression_reads_undefined',
}
for case in CASES:
    name=case['name']
    if case['category'] != 'runtime' or case.get('diagnostic'):
        continue
    if name in undefined_cases:
        case['diagnostic']='uninitialized'
    elif 'alias' in name:
        case['diagnostic']='overlapping'
    elif 'bounds' in name:
        case['diagnostic']='bounds'
    elif name=='dummy_shape_mismatch':
        case['diagnostic']='conform'
    elif name=='zero_stride_actual':
        case['diagnostic']='stride is zero'
    elif name in ('dynamic_lbound_bad_dim', 'dynamic_ubound_bad_dim'):
        case['diagnostic']='LBOUND/UBOUND DIM outside ARRAY rank'
    elif name.endswith('_bad_dim'):
        case['diagnostic']='DIM must equal 1'

# The array cap is now 131072; retain historical boundary source fixtures.
# Current-cap tests are generated from fi_ir in tests/array_limits/run_tests.py.
ARRAY_LIMIT_MIGRATIONS = {'call_array_element_cap': '99'}
for row in CASES:
    if row['name'] in ARRAY_LIMIT_MIGRATIONS:
        row.update(category='success', baseline='run', expected_stdout=ARRAY_LIMIT_MIGRATIONS[row['name']],
                   note='Historical 65536-element cap probe; legal with the larger cap.')
        row.pop('diagnostic', None)

# Preserve the already certified explicit-shape capability metadata.
for row in CASES:
    if row['name'] == 'explicit_shape_dummy_unsupported':
        row.update(name='explicit_shape_dummy_supported', category='success', baseline='run')

(ROOT/'manifest.json').write_text(json.dumps(dict(cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} cases')
