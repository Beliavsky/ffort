#!/usr/bin/env python3
"""Reproduce CSHIFT fixtures and manifest; never rewrite the upstream program."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent
CASES = ROOT / 'cases'
CASES.mkdir(exist_ok=True)
ORIGINAL_SHA = '86868f08e1dc9d4b533e4b170734d02d6006642397486ce4160420b08eaf2fbd'
original = (ROOT / 'demo_cshift.f90').read_bytes()
assert hashlib.sha256(original).hexdigest() == ORIGINAL_SHA and len(original) == 857
cases = []

def add(name, body, category='success', baseline='run', expected='PASS', diagnostic='', **extra):
    (CASES / (name + '.f90')).write_text(body)
    case = dict(name=name, source='cases/' + name + '.f90', category=category,
                baseline=baseline, expected_stdout=expected)
    if diagnostic:
        case['diagnostic'] = diagnostic
    case.update(extra)
    cases.append(case)

def program(decl, body, procs=''):
    return ('program p\nimplicit none\n' + decl + '\n' + body + '\nprint *, "PASS"\n' +
            ('contains\n' + procs + '\n' if procs else '') + 'end program\n')

def fail(name, decl, expr, category='reject', baseline='reject', diagnostic=''):
    add(name, program(decl, expr), category, baseline, '', diagnostic)

def vec(values):
    return '[' + ','.join(map(str, values)) + ']'

def shifted(data, rows, columns, shifts, dim):
    # Independent column-major oracle, with Python modulo including negative minima.
    result = []
    for j in range(columns):
        for i in range(rows):
            amount = shifts[0] if len(shifts) == 1 else shifts[j if dim == 1 else i]
            ii, jj = ((i + amount) % rows, j) if dim == 1 else (i, (j + amount) % columns)
            result.append(data[ii + rows * jj])
    return result

cases.append(dict(name='original_demo_cshift', source='demo_cshift.f90', category='success', baseline='run',
    expected_stdout='start with: 10 20 30 40 50 shift -2 40 50 10 20 30 shift +2 30 40 50 10 20 '
    'start with a matrix 1 4 7 10 2 5 8 11 3 6 9 12 '
    'matrix shifted along rows, each by its own amount [-1,0,1] '
    '4 7 10 1 2 5 8 11 12 3 6 9'))

add('rank1_signed_modulo', program('integer::a(5),b(5)', '''a=[10,20,30,40,50]
if(any(cshift(a,0)/=a)) error stop 1
if(any(cshift(a,5)/=a)) error stop 2
if(any(cshift(a,-10)/=a)) error stop 3
if(any(cshift(a,12)/=[30,40,50,10,20])) error stop 4
if(any(cshift(a,-12)/=[40,50,10,20,30])) error stop 5
b=cshift(array=a,shift=2,dim=1)
if(any(b/=[30,40,50,10,20])) error stop 6'''))
for name, kind, suffix in [('integer4', 'integer', ''), ('integer8', 'integer(8)', '_8'),
                           ('real4', 'real', '.0'), ('real8', 'real(8)', '.0_8')]:
    values = [str(i) + suffix for i in range(1, 13)]
    expected = shifted(values, 3, 4, [1, -1, 8, -7], 1)
    body = f'a=reshape({vec(values)},[3,4])\nb=cshift(a,[1,-1,8,-7])\n'
    body += f'if(any(b/=reshape({vec(expected)},[3,4]))) error stop 1\n'
    body += 'if(kind(b)/=kind(a)) error stop 2\nif(any(shape(b)/=shape(a))) error stop 3'
    add('rank2_' + name, program(f'{kind}::a(3,4),b(3,4)', body))
add('logical_and_character', program('logical::a(2,3),b(2,3)\ncharacter(len=3)::c(2,3),d(2,3)', '''a=reshape([.true.,.false.,.false.,.true.,.true.,.true.],[2,3])
b=cshift(a,shift=[1,-1],dim=2)
if(any(b.neqv.reshape([.false.,.true.,.true.,.false.,.true.,.true.],[2,3]))) error stop 1
c=reshape(['a  ',' bb','c c',' dd','e  ',' ff'],[2,3])
d=cshift(c,shift=[1,-1],dim=2)
if(any(d/=reshape(['c c',' ff','e  ',' bb','a  ',' dd'],[2,3]))) error stop 2
if(len(d)/=3.or.kind(d)/=kind(c)) error stop 3'''))
add('rank1_logical_character', program('logical::a(4)\ncharacter(len=3)::c(4)', '''a=[.true.,.false.,.true.,.true.]
if(any(cshift(a,-1).neqv.[.true.,.true.,.false.,.true.])) error stop 1
c=['a  ','b b',' cc',' d ']
if(any(cshift(c,2)/=[' cc',' d ','a  ','b b'])) error stop 2'''))
add('character_zero_length', program('character(len=0)::a(2,3),b(2,3)', '''a=''
b=cshift(a,[1,0,-1],1)
if(len(b)/=0.or.size(b)/=6) error stop 1'''))
add('rank2_keywords_scalar_dim2', program('integer::a(3,4),b(3,4)', '''a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
b=cshift(dim=2_8,shift=-1_8,array=a)
if(any(b/=reshape([10,11,12,1,2,3,4,5,6,7,8,9],[3,4]))) error stop 1'''))
minimum = -9223372036854775808
maximum = 9223372036854775807
for name, shift in [('minimum_integer64', minimum), ('maximum_integer64', maximum)]:
    expression = '(-9223372036854775807_8-1_8)' if shift == minimum else '9223372036854775807_8'
    expected = shifted(list(range(1, 7)), 3, 2, [shift, shift + (1 if shift == minimum else -1)], 1)
    add(name, program('integer(8)::s(2)\ninteger::a(3,2)', f'''a=reshape([1,2,3,4,5,6],[3,2])
s=[{expression},{expression}{'+1_8' if shift == minimum else '-1_8'}]
if(any(cshift(a,s,1_8)/=reshape({vec(expected)},[3,2]))) error stop 1
if(any(cshift([1,2,3],{expression})/={vec(shifted([1,2,3],3,1,[shift],1))})) error stop 2'''))
add('minimum_integer32', program('integer::s', '''s=-2147483647-1
if(any(cshift([1,2,3],s)/=[2,3,1])) error stop 1'''))
add('nonunit_bounds_sections', program('integer::a(-1:4,-2:3),b(3,3),i,j,s(-3:-1)', '''do j=-2,3
do i=-1,4
a(i,j)=10*j+i
end do
end do
s=[1,0,-1]
b=cshift(a(4:0:-2,3:-1:-2),s(-1:-3:-1),2)
if(any(b/=reshape([-6,32,10,34,12,-10,14,-8,30],[3,3]))) error stop 1
if(lbound(cshift(a,1),1)/=1.or.lbound(cshift(a,1),2)/=1) error stop 2'''))
add('shift_strided_section', program('integer::a(2,3),s(-2:3)', '''a=reshape([1,2,3,4,5,6],[2,3])
s=[1,99,-2,99,3,99]
if(any(cshift(a,s(-2:2:2),1)/=reshape([2,1,3,4,6,5],[2,3]))) error stop 1'''))
add('self_assignment_snapshot', program('integer::a(3,3)', '''a=reshape([1,2,3,4,5,6,7,8,9],[3,3])
a=cshift(a,[1,-1,2],1)
if(any(a/=reshape([2,3,1,6,4,5,9,7,8],[3,3]))) error stop 1
a(:,3:1:-1)=cshift(a(:,3:1:-1),1,2)
if(any(a/=reshape([9,7,8,2,3,1,6,4,5],[3,3]))) error stop 2'''))
add('shift_aliases_array', program('integer::a(3,3)', '''a=reshape([1,2,3,4,5,6,7,8,9],[3,3])
a=cshift(a,a(:,1),2)
if(any(a/=reshape([4,8,3,7,2,6,1,5,9],[3,3]))) error stop 1'''))
add('dynamic_allocatable_descriptors', program('integer,allocatable::a(:,:),b(:,:),s(:)\ninteger::n,d', '''n=3
d=2
allocate(a(-1:1,4:7))
allocate(s(-2:0))
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
s=[1,-2,5]
b=cshift(a,s,d)
if(any(shape(b)/=[3,4])) error stop 1
if(any(b/=reshape([4,8,6,7,11,9,10,2,12,1,5,3],[3,4]))) error stop 2
if(lbound(b,1)/=1.or.lbound(b,2)/=1) error stop 3'''))
add('assumed_shape_descriptors', program('integer::a(-1:1,4:7)', '''a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
call inspect(a(1:-1:-1,7:4:-1),[-1,0,1])''', '''subroutine inspect(a,s)
integer,intent(in)::a(:,:),s(:)
integer::b(size(a,1),size(a,2))
b=cshift(a,s,2)
if(any(b/=reshape([3,11,7,12,8,4,9,5,1,6,2,10],[3,4]))) error stop 1
end subroutine'''))
add('one_element_empty_axes', program('integer::a(0,3),b(3,0),c(0),s(0),one(1,1)', '''a=0
b=0
c=0
s=0
one=17
if(any(cshift(one,-9223372036854775807_8-1_8)/=one)) error stop 1
if(size(cshift(c,9))/=0) error stop 2
if(size(cshift(a,[1,-1,0],1))/=0) error stop 3
if(size(cshift(a,s,2))/=0) error stop 4
if(size(cshift(b,s,1))/=0) error stop 5
if(size(cshift(b,[1,2,3],2))/=0) error stop 6'''))
# GNU14 may reject materialization of valid empty rank-two shifts under
# -fcheck=all; keep this standard-shape invariant separate from its oracle.
add('empty_array_materialization', program('integer::a(0,3),b(0,3),c(2,0),d(2,0)',
    'a=0\nc=0\nb=cshift(a,[1,-1,0],1)\nd=cshift(c,[1,-1],2)\n' +
    'if(size(b)/=0.or.size(d)/=0) error stop 1'), baseline='compile',
    boundary_note='Valid empty result/SHIFT conformance; GNU14 bounds-checking materialization discrepancy is not adopted.')
add('nested_composition', program('integer::a(2,3),b(2,3)', '''a=reshape([1,2,3,4,5,6],[2,3])
b=cshift(cshift(a,[1,0,-1]),[1,-1],2)
if(any(b/=reshape([3,5,6,1,2,4],[2,3]))) error stop 1
if(sum(cshift(a,1))/=21) error stop 2
if(any(shape(cshift(a,1))/=[2,3])) error stop 3'''))
add('constant_parameters', program('integer,parameter::a(3)=[1,2,3]\ninteger,parameter::b(3)=cshift(a,-1)\ncharacter(len=2),parameter::c(3)=cshift(["ab","cd","ef"],1)', '''if(any(b/=[3,1,2])) error stop 1
if(any(c/=['cd','ef','ab'])) error stop 2'''))
add('pure_function_source', program('integer::a(3)', '''a=cshift(make(3),1)
if(any(a/=[2,3,1])) error stop 1''', '''pure function make(n) result(r)
integer,intent(in)::n
integer::r(n),i
do i=1,n
r(i)=i
end do
end function'''))
add('ordinary_function_source', program('integer::a(3)', '''a=cshift(make(3),-1)
if(any(a/=[3,1,2])) error stop 1''', '''function make(n) result(r)
integer,intent(in)::n
integer::r(n),i
do i=1,n
r(i)=i
end do
end function'''))
add('recursive_function_source', program('integer::a(3)', '''a=cshift(make(3,4),1)
if(any(a/=[6,7,5])) error stop 1''', '''recursive function make(n,k) result(r)
integer,intent(in)::n,k
integer::r(n),i
do i=1,n
r(i)=i
end do
if(k>0) r=make(n,k-1)+1
end function'''))
add('character_function_source', program('character(len=3)::a(3)', '''a=cshift(make(),1)
if(any(a/=['b b',' cc','a  '])) error stop 1''', '''function make() result(r)
character(len=3)::r(3)
r=['a  ','b b',' cc']
end function'''))
add('pure_where_forall', program('integer::a(4),b(4),i', '''a=[1,2,3,4]
b=0
where(a>1) b=cshift(a,1)
if(any(b/=[0,3,4,1])) error stop 1
forall(i=1:4) b(i)=sum(cshift(a,i))
if(any(b/=10)) error stop 2'''))
add('user_procedure_shadowing', program('integer::a(3)', '''a=cshift([1,2,3],1)
if(any(a/=[2,3,4])) error stop 1''', '''function cshift(a,n) result(r)
integer,intent(in)::a(:),n
integer::r(size(a))
r=a+n
end function'''))

add('scalar_variable_shadow',program('integer::cshift','cshift=17\nif(cshift/=17) error stop 1'))
add('array_variable_shadow',program('integer::cshift(3),x','cshift=[4,5,6]\nx=cshift(2)\nif(x/=5) error stop 1'))
add('scalar_function_shadow',program('real(8)::x','x=cshift(3)\nif(x/=3.5d0) error stop 1',
    'real(8) function cshift(n)\ninteger,intent(in)::n\ncshift=n+0.5d0\nend function'))
add('function_result_shadow',program('integer::a(3)','a=make()\nif(any(a/=[4,5,6])) error stop 1',
    'function make() result(cshift)\ninteger::cshift(3)\ncshift=[4,5,6]\ncshift(2)=5\nend function'))
add('generic_shadow_different_type', 'module m\nimplicit none\ninterface cshift\nmodule procedure positive\nend interface\ncontains\nlogical function positive(n) result(r)\ninteger,intent(in)::n\nr=n>0\nend function\nend module\nprogram p\nuse m\nimplicit none\nif(.not.cshift(4)) error stop 1\nif(cshift(-1)) error stop 2\nprint *, "PASS"\nend program\n')

# Nondeterministic results use identities, never comparison of GNU and candidate streams.
add('rng_scalar_shift_once', program('integer::a(257),b(257),i,s', '''do i=1,257
a(i)=i
end do
b=cshift(a,draw())
s=b(1)-1
do i=1,257
if(b(i)/=modulo(i-1+s,257)+1) error stop 1
end do''', '''integer function draw() result(r)
real(8)::x
call random_number(x)
r=int(x*257d0)
end function'''))
add('rng_scalar_source_once', program('real(8)::a(128),b(128)', '''a=0d0
b=cshift(a+draw(),31)
if(any(b/=b(1))) error stop 1
if(b(1)<0d0.or.b(1)>=1d0) error stop 2''', '''real(8) function draw() result(r)
call random_number(r)
end function'''))
add('rng_array_source_once', program('real(8)::a(128)', '''a=cshift(draw(128),31)
if(any(a/=a(1))) error stop 1
if(a(1)<0d0.or.a(1)>=1d0) error stop 2''', '''function draw(n) result(r)
integer,intent(in)::n
real(8)::r(n),x
call random_number(x)
r=x
end function'''))
add('rng_array_shift_frozen', program('integer::a(257,4),b(257,4),i,j,s', '''do j=1,4
do i=1,257
a(i,j)=i
end do
end do
b=cshift(a,draw(),1)
do j=1,4
s=b(1,j)-1
do i=1,257
if(b(i,j)/=modulo(i-1+s,257)+1) error stop 1
end do
end do''', '''function draw() result(r)
integer::r(4),j
real(8)::x(4)
call random_number(x)
do j=1,4
r(j)=int(257d0*x(j))
end do
end function'''))
add('kind_arguments_unevaluated', program('integer::k\ninteger::a(3)', '''k=kind(cshift(make(),shift=shift(),dim=dim()))
if(k/=8) error stop 1
k=kind(cshift(a,shift(),dim()))
if(k/=4) error stop 2''', '''function make() result(r)
integer(8)::r(3)
error stop "KIND evaluated ARRAY"
end function
integer function shift() result(r)
error stop "KIND evaluated SHIFT"
end function
integer function dim() result(r)
error stop "KIND evaluated DIM"
end function'''))
add('optional_parenthesized_dim', program('', 'call inspect(2)', '''subroutine inspect(d)
integer,optional,intent(in)::d
integer::a(2,3),b(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
if(present(d)) then
b=cshift(a,1,(d))
if(any(b/=reshape([3,4,5,6,1,2],[2,3]))) error stop 1
end if
end subroutine'''))
add('optional_direct_dim', program('', 'call inspect(2)', '''subroutine inspect(d)
integer,optional,intent(in)::d
integer::a(2,3),b(2,3)
a=1
b=cshift(a,1,d)
end subroutine'''), 'reject', 'compile', '')
add('optional_absent_parenthesized_dim', program('', 'call inspect()', '''subroutine inspect(d)
integer,optional,intent(in)::d
integer::a(2,3),b(2,3)
a=1
b=cshift(a,1,(d))
end subroutine'''), 'runtime', 'compile', '')

for name, decl, expr in [
    ('scalar_array', 'integer::x', 'x=cshift(1,1)'),
    ('rank3_array', 'integer::a(2,2,2),b(2,2,2)', 'a=1\nb=cshift(a,1)'),
    ('real_shift', 'integer::a(3)', 'a=cshift([1,2,3],1.0)'),
    ('logical_shift', 'integer::a(3)', 'a=cshift([1,2,3],.true.)'),
    ('array_shift_rank1', 'integer::a(3)', 'a=cshift([1,2,3],[1])'),
    ('rank2_shift', 'integer::a(2,2),s(2,2)', 'a=1\ns=0\na=cshift(a,s)'),
    ('static_shape_mismatch', 'integer::a(2,3)', 'a=1\na=cshift(a,[1,2])'),
    ('real_dim', 'integer::a(3)', 'a=cshift([1,2,3],1,1.0)'),
    ('array_dim', 'integer::a(3)', 'a=cshift([1,2,3],1,[1])'),
    ('dim_zero_constant', 'integer::a(3)', 'a=cshift([1,2,3],1,0)'),
    ('dim_negative_constant', 'integer::a(3)', 'a=cshift([1,2,3],1,-1)'),
    ('dim_oversized_constant', 'integer::a(3)', 'a=cshift([1,2,3],1,2)'),
    ('duplicate_shift', 'integer::a(3)', 'a=cshift([1,2,3],1,shift=2)'),
    ('duplicate_array', 'integer::a(3)', 'a=cshift([1,2,3],shift=1,array=[1,2,3])'),
    ('missing_shift', 'integer::a(3)', 'a=cshift([1,2,3])'),
    ('missing_array', 'integer::a(3)', 'a=cshift(shift=1)'),
    ('unknown_keyword', 'integer::a(3)', 'a=cshift([1,2,3],1,kind=4)'),
    ('too_many_arguments', 'integer::a(3)', 'a=cshift([1,2,3],1,1,1)'),
    ('positional_after_keyword', 'integer::a(3)', 'a=cshift(array=[1,2,3],1)'),
]:
    fail(name, decl, expr, baseline='compile' if name=='rank3_array' else 'reject')
for name, value in [('zero', '0'), ('negative', '-3'), ('oversized', '3'), ('huge_integer8', '9223372036854775807_8')]:
    fail('dynamic_dim_' + name, 'integer::a(2,3),b(2,3)\ninteger(8)::d', 'a=1\nd='+value+'\nb=cshift(a,1,d)', 'runtime', 'compile', 'DIM')
fail('dynamic_shape_mismatch', 'integer,allocatable::a(:,:),s(:),b(:,:)\ninteger::n',
     'n=2\nallocate(a(2,3))\nallocate(s(n))\na=1\ns=0\nb=cshift(a,s)', 'runtime', 'compile', 'SHIFT shape')
fail('undefined_array', 'integer::a(3),b(3)', 'b=cshift(a,1)', 'runtime', 'compile')
fail('undefined_shift', 'integer::a(3),b(3),s', 'a=1\nb=cshift(a,s)', 'runtime', 'compile')
fail('undefined_shift_entry', 'integer::a(2,3),b(2,3),s(3)', 'a=1\ns(1)=0\ns(2)=0\nb=cshift(a,s)', 'runtime', 'compile')
fail('undefined_dim', 'integer::a(3),b(3),d', 'a=1\nb=cshift(a,1,d)', 'runtime', 'compile')
fail('unallocated_array', 'integer,allocatable::a(:),b(:)', 'b=cshift(a,1)', 'runtime', 'compile')
fail('unallocated_shift', 'integer,allocatable::s(:)\ninteger::a(2,3),b(2,3)', 'a=1\nb=cshift(a,s)', 'runtime', 'compile')
for item in ['array', 'shift']:
    proc = ('subroutine inspect(a)\ninteger,optional,intent(in)::a(:)\ninteger::b(3)\nb=cshift(a,1)\nend subroutine' if item=='array' else
            'subroutine inspect(s)\ninteger,optional,intent(in)::s\ninteger::b(3)\nb=cshift([1,2,3],s)\nend subroutine')
    add('absent_optional_'+item, program('', 'call inspect()', proc), 'runtime', 'compile', '')
for name,decl,body,procs,diagnostic in [
    ('empty_evaluates_scalar_shift','integer::a(0),b(0)','a=0\nb=cshift(a,shift())',
     'integer function shift() result(r)\nerror stop "SHIFT evaluated"\nend function','SHIFT evaluated'),
    ('empty_evaluates_shift_entries','integer::a(0,2),b(0,2)','a=0\nb=cshift(a,[shift(),0],1)',
     'integer function shift() result(r)\nerror stop "SHIFT entry evaluated"\nend function','SHIFT entry evaluated'),
    ('empty_evaluates_dim','integer::a(0),b(0)','a=0\nb=cshift(a,1,dim())',
     'integer function dim() result(r)\nerror stop "DIM evaluated"\nend function','DIM evaluated'),
    ('empty_source_descriptor_function','integer::b(0)','b=cshift(make(0),1)',
     'function make(n) result(r)\ninteger,intent(in)::n\ninteger::r(n)\nerror stop "ARRAY descriptor evaluated"\nend function','ARRAY descriptor evaluated'),
]:
    add(name,program(decl,body,procs),'runtime','compile','',diagnostic)
fail('empty_dynamic_bad_dim','integer::a(0,3),b(0,3),d','a=0\nd=0\nb=cshift(a,[1,2,3],d)','runtime','compile','DIM')
fail('empty_undefined_shift_entry','integer::a(0,3),b(0,3),s(3)','a=0\ns(1)=1\ns(3)=1\nb=cshift(a,s)','runtime','compile')

rng = '''integer function shift() result(r)
real::x
call random_number(x)
r=int(x*3.0)
end function'''
for name,body in [('where_impure_reject','a=1\nwhere(a>0) a=cshift(a,shift())'),
                  ('forall_impure_reject','a=1\nforall(i=1:3) a(i)=sum(cshift(a,shift()))')]:
    add(name,program('integer::a(3),i',body,rng),'reject','reject' if name.startswith('forall') else 'compile','')
add('source_io_effect_reject',program('integer::a(3)','a=cshift(make(),1)',
    'function make() result(r)\ninteger::r(3)\nprint *,"leak"\nr=1\nend function'),'reject','compile','')
add('source_saved_effect_reject',program('integer::a(3)','a=cshift(make(),1)',
    'function make() result(r)\ninteger::r(3)\ninteger,save::n=0\nn=n+1\nr=n\nend function'),'reject','compile','')
add('shared_work_budget',program('integer::a(1000),b(1000)','a=1\nb=cshift(a,1)'),
    'runtime','compile','','step limit',args=['--max-steps','1500'])
add('temporary_element_boundary',program('integer::n,v','n=65536\nv=sum(cshift(make(n),1))\nif(v/=65536) error stop 1',
    'function make(n) result(r)\ninteger,intent(in)::n\ninteger::r(n)\nr=1\nend function'))
add('temporary_character_boundary',program('integer::n\ncharacter(len=4096)::a(2048)',
    'n=2048\na=cshift(make(n),1)\nif(any(a/="x")) error stop 1',
    'function make(n) result(r)\ninteger,intent(in)::n\ncharacter(len=4096)::r(n)\nr="x"\nend function'))
add('temporary_element_limit',program('integer::n,v','n=500001\nv=sum(cshift(make(n),1))',
    'function make(n) result(r)\ninteger,intent(in)::n\ninteger::r(n)\nr=1\nend function'),
    'runtime','compile','','temporary element limit',args=['--max-steps','20000000'])
add('temporary_character_byte_limit',program('integer::n\ncharacter(len=4096)::a(2049)',
    'n=2049\na=cshift(make(n),1)',
    'function make(n) result(r)\ninteger,intent(in)::n\ncharacter(len=4096)::r(n)\nr="x"\nend function'),
    'runtime','compile','','CHARACTER temporary byte limit')

add('failed_output_record', 'program p\nimplicit none\ninteger::a(3),d\na=[1,2,3]\nd=0\nprint \'(a)\', "BEFORE"\nprint *, "partial", cshift(a,1,d)\nend program\n',
    'runtime','compile','','DIM',completed_stdout='BEFORE\n')

manifest = dict(description='Bounded rank-one/rank-two CSHIFT, complete unchanged M_intrinsics example, independently constructed or invariant oracles.',
    original=dict(local_file='demo_cshift.f90', source_path='example/demo_cshift.f90',
                  upstream_repository='https://github.com/urbanjost/M_intrinsics',
                  upstream_commit='fc14233036d910e3678d350efc24609e11475067',
                  sha256=ORIGINAL_SHA, bytes=857, altered=False), cases=cases)
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('generated',len(cases),'CSHIFT cases')
