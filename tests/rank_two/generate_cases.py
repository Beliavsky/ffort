#!/usr/bin/env python3
"""Generate independently specified rank-two Fortran fixtures and expectations.

Expected arrays are calculated in Python using first-index-fastest order.
No interpreter implementation code is imported.
"""
from pathlib import Path
import json
from textwrap import dedent
ROOT=Path(__file__).resolve().parent
CASES=[]

def add(name, source, expected='', category='success', baseline=None, diagnostic=None, **kw):
    if baseline is None: baseline='run' if category=='success' else 'compile' if category in ('runtime','unsupported') else 'reject'
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(dedent(source).strip()+'\n')
    if not isinstance(expected,str): expected=' '.join(str(x) for x in expected)
    case=dict(name=name,source=f'cases/{name}.f90',category=category,baseline=baseline,expected_stdout=expected,**kw)
    if diagnostic: case['diagnostic']=diagnostic
    CASES.append(case)

def prog(decl,body,contained=''):
    return 'program independent_ranktwo\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+contained+'\n' if contained else '')+'end program independent_ranktwo\n'

def vals(n,m,lo,lj):
    return [100*j+i for j in range(lj,lj+m) for i in range(lo,lo+n)]

# Matrix includes rectangular/singleton/empty arrays and nonunit lower bounds.
for n,m in [(0,0),(0,3),(3,0),(1,1),(1,4),(4,1),(2,3),(3,2),(4,5)]:
  for lo,lj in [(-3,4),(1,1),(6,-2)]:
    name=f'layout_{n}_{m}_bounds_{lo}_{lj}'.replace('-','neg')
    v=vals(n,m,lo,lj)
    inq=[n*m,n,m,lo if n else 1,lo+n-1 if n else 0,lj if m else 1,lj+m-1 if m else 0]
    body=f'''do j={lj},{lj+m-1}
      do i={lo},{lo+n-1}
        aa(i,j)=100*j+i
      end do
    end do
    print *, size(aa),size(aa,1),size(aa,2)
    print *, lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
    print *, aa
    bb=aa+7
    print *, bb
    print *, size(aa+1,1),size(aa+1,2),lbound(aa+1,1),ubound(aa+1,1)
    print *, lbound(aa+1,2),ubound(aa+1,2)
    '''
    add(name,prog(f'integer :: aa({lo}:{lo+n-1},{lj}:{lj+m-1}),bb({n},{m}),i,j',body),inq+v+[x+7 for x in v]+[n,m,1,n,1,m])

add('constant_bounds',prog('''integer, parameter :: rows=2,cols=3,low=-2
integer :: aa(low:low+rows-1,cols),i,j''','''do j=1,cols
 do i=low,low+rows-1
 aa(i,j)=i+j
 end do
end do
print *, aa,size(aa,2),lbound(aa,1)'''),[-1,0,0,1,1,2,3,-2])
add('dimension_order_mixed_declaration',prog('integer :: aa(2,3),bb(-1:0,4:6),i','''aa=9
bb=4
bb(0,5)=aa(2,3)+8
print *, aa,bb'''),[9]*6+[4,4,4,17,4,4])
add('snapshot_scalar_element',prog('integer :: aa(2,3),i,j','''do j=1,3
 do i=1,2
 aa(i,j)=10*j+i
 end do
end do
aa=aa+aa(1,1)
print *, aa'''),[22,23,32,33,42,43])
add('inquiries_without_data_read',prog('integer :: aa(-2:0,7:8)','''print *, size(aa),size(aa,1),size(aa,2)
print *, lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
print *, size(aa+1),ubound(aa+1,2)'''),[6,3,2,-2,0,7,8,6,2])
add('nested_ranktwo_subscripts',prog('integer :: aa(-1:0,2:4),ii(2,2)','''aa=5
ii=2
ii(2,1)=-1
ii(2,2)=4
aa(ii(2,1),ii(2,2))=17
print *, aa,aa(ii(2,1),2)'''),[5,5,5,5,17,5,5])
add('integer_elemental_ops',prog('integer :: aa(2,2),bb(-1:0,3:4),cc(2,2)','''aa(1,1)=-5
aa(2,1)=0
aa(1,2)=3
aa(2,2)=8
bb=2
cc=max(abs(aa),bb)+min(aa,1)+mod(aa,2)
print *,cc
cc=aa*aa/2-3
print *,cc
print *, aa==bb,aa>0,aa<bb'''),[-1,2,5,9,9,-3,1,29,'F','F','F','F','F','F','T','T','T','T','F','F'])
add('logical_ranktwo_ops',prog('logical :: aa(2,2),bb(-1:0,4:5)','''aa=.false.
aa(2,1)=.true.
aa(1,2)=.true.
bb=.not.aa
print *, aa,bb,aa.and.bb,aa.or.bb,aa.eqv.bb,aa.neqv.bb'''),['F','T','T','F','T','F','F','T']+['F']*4+['T']*4+['F']*4+['T']*4)
add('real32_conversion',prog('''real :: aa(2,2)
integer :: bb(2,2)''','''aa(1,1)=-2.75
aa(2,1)=1.25
aa(1,2)=3.5
aa(2,2)=4.0
bb=aa
print *, bb
print *, real(bb)+0.5,sqrt(abs(aa)),int(aa)'''),'-2 1 3 4 -1.5 1.5 3.5 4.5 1.6583123951777 1.1180339887499 1.87082869338697 2 -2 1 3 4')
add('real64_elemental',prog('real(8) :: aa(2,2),bb(2,2)','''aa(1,1)=0.0d0
aa(2,1)=1.0d0
aa(1,2)=2.0d0
aa(2,2)=-1.0d0
bb=log(exp(aa))+sqrt(abs(aa))
print *,bb,erfc(aa)'''),'0.0 2.0 3.414213562373095 0.0 1.0 0.15729920705028513 0.004677734981047266 1.8427007929497148',rel_tol=1e-12,abs_tol=1e-14)
add('scalar_calls_with_ranktwo_elements',prog('integer :: aa(2,2)','''aa=3
call revise(aa(2,1),aa(1,2))
print *,aa''','''subroutine revise(xx,yy)
 integer,intent(inout) :: xx
 integer,intent(out) :: yy
 xx=xx+10
 yy=xx+7
end subroutine revise'''),[3,13,20,3])
add('nested_loop_bounds_from_shape',prog('integer :: aa(-2:1,3:4),ii,jj,acc','''aa=0
acc=0
do jj=lbound(aa,2),ubound(aa,2)
 do ii=lbound(aa,1),ubound(aa,1)
 aa(ii,jj)=ii*jj
 acc=acc+aa(ii,jj)
 end do
end do
print *,aa,acc'''),[-6,-3,0,3,-8,-4,0,4,-14])
# Whole-array actuals, lower-bound remapping, shape propagation and copy-back.
for n,m in [(0,0),(0,3),(3,0),(1,1),(2,3),(3,2)]:
  for lo,lj in [(-2,4),(3,-1)]:
    v=vals(n,m,lo,lj)
    d1,d2=-4,6
    inq=[n*m,n,m,d1 if n else 1,d1+n-1 if n else 0,d2 if m else 1,d2+m-1 if m else 0]
    body=f'''do jj={lj},{lj+m-1}
 do ii={lo},{lo+n-1}
 aa(ii,jj)=100*jj+ii
 end do
end do
call bump(aa)
print *,aa
print *,total(aa),total(aa+1)'''
    sub=f'''subroutine bump(xx)
 integer,intent(inout) :: xx({d1}:,{d2}:)
 print *,size(xx),size(xx,1),size(xx,2)
 print *,lbound(xx,1),ubound(xx,1),lbound(xx,2),ubound(xx,2)
 xx=xx+3
end subroutine bump
integer function total(xx) result(rr)
 integer,intent(in) :: xx(:,:)
 integer :: ii,jj
 rr=0
 do jj=lbound(xx,2),ubound(xx,2)
 do ii=lbound(xx,1),ubound(xx,1)
 rr=rr+xx(ii,jj)
 end do
 end do
end function total'''
    add(f'dummy_{n}_{m}_bounds_{lo}_{lj}'.replace('-','neg'),prog(f'integer :: aa({lo}:{lo+n-1},{lj}:{lj+m-1}),ii,jj',body,sub),inq+[x+3 for x in v]+[sum(v)+3*n*m,sum(v)+4*n*m])
add('dummy_out_all_elements',prog('integer :: aa(-1:0,2:4)','''call fill(aa)
print *,aa''','''subroutine fill(xx)
 integer,intent(out) :: xx(3:,7:)
 integer :: ii,jj
 do jj=7,9
 do ii=3,4
 xx(ii,jj)=ii+10*jj
 end do
 end do
end subroutine fill'''),[73,74,83,84,93,94])
add('dummy_readonly_alias',prog('integer :: aa(2,3)','''aa=5
print *,tally(aa,aa)''','''integer function tally(xx,yy) result(rr)
 integer,intent(in) :: xx(:,:),yy(-1:,4:)
 rr=xx(2,3)+yy(0,6)+size(xx)+size(yy)
end function tally'''),[22])
add('dummy_expression_temporary',prog('integer :: aa(2,2)','''aa=7
call revise(aa,aa+1)
print *,aa''','''subroutine revise(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=xx+yy
end subroutine revise'''),[15]*4)
add('dummy_nested_forwarding',prog('integer :: aa(-1:0,5:7)','''aa=2
call first(aa)
print *,aa''','''subroutine first(xx)
 integer,intent(inout) :: xx(3:,-2:)
 call second(xx)
 xx(4,0)=xx(4,0)+7
end subroutine first
subroutine second(yy)
 integer,intent(inout) :: yy(-4:,7:)
 yy=yy*3
 yy(-4,8)=19
end subroutine second'''),[6,6,19,6,6,13])
add('ranktwo_locals_each_frame',prog('integer :: aa(2,2)','''aa=4
print *,work(aa),work(aa+1)''','''integer function work(xx) result(rr)
 integer,intent(in) :: xx(:,:)
 integer :: local(2,2)
 local=xx*2
 rr=local(1,1)+local(2,2)
end function work'''),[16,20])
add('module_ranktwo', '''module matrices
 implicit none
 private
 public :: increment,checksum
contains
 subroutine increment(xx)
 integer,intent(inout) :: xx(:,:)
 xx=xx+2
 end subroutine increment
 integer function checksum(xx) result(rr)
 integer,intent(in) :: xx(:,:)
 integer :: i,j
 rr=0
 do j=1,size(xx,2)
 do i=1,size(xx,1)
 rr=rr+xx(i,j)
 end do
 end do
 end function checksum
end module matrices
program independent_ranktwo
 use matrices,only:increment,checksum
 implicit none
 integer :: aa(2,3)
 aa=4
 call increment(aa)
 print *,aa,checksum(aa)
end program independent_ranktwo''',[6]*6+[36])
add('empty_array_skips_data_expressions',prog('integer :: aa(0,3),bb(0,3),uninit','''aa=bb+uninit
print *,size(aa),size(aa,1),size(aa,2)'''),[0,0,3],baseline='compile')
add('size_limit_exact',prog('integer :: aa(256,256)','''aa=3
aa(256,256)=7
print *,size(aa),aa(1,1),aa(256,256)'''),[65536,3,7],args=['--max-steps','2000000'])

# Runtime safety cases: GNU compilation verifies standard syntax, not undefined behavior.
for expr in ['aa(0,1)','aa(3,1)','aa(1,0)','aa(1,4)','aa(3,0)','aa(0,2)']:
    slug=expr.replace('aa','read').replace('(','_').replace(')','').replace(',','_')
    add('bounds_'+slug,prog('integer :: aa(2,3)','aa=9\nprint *,111\nprint *,'+expr),'111',category='runtime',diagnostic='bounds')
for expr in ['aa(0,1)','aa(3,1)','aa(1,0)','aa(1,4)']:
    slug=expr.replace('aa','write').replace('(','_').replace(')','').replace(',','_')
    add('bounds_'+slug,prog('integer :: aa(2,3)','aa=9\nprint *,111\n'+expr+'=42'),'111',category='runtime',diagnostic='bounds')
for dims,elem in [('0,3','1,1'),('3,0','1,1'),('-2:-3,4:6','-2,4')]:
    add('empty_bounds_'+str(len(CASES)),prog(f'integer :: aa({dims})',f'print *,111\nprint *,aa({elem})'),'111',category='runtime',diagnostic='bounds')
add('uninitialized_second_column',prog('integer :: aa(2,2)','''aa(1,1)=1
aa(2,1)=2
print *,111
print *,aa(1,2)'''),'111',category='runtime',diagnostic='uninitialized')
add('uninitialized_print_atomic',prog('integer :: aa(2,2)','''aa(1,1)=1
aa(2,1)=2
print *,111
print *,999,aa'''),'111',category='runtime',diagnostic='uninitialized')
add('dummy_out_partial_flags',prog('integer :: aa(2,2)','''aa=3
call partial(aa)
print *,aa(1,1)
print *,aa(1,2)''','''subroutine partial(xx)
 integer,intent(out) :: xx(:,:)
 xx(1,1)=42
end subroutine partial'''),'42',category='runtime',diagnostic='uninitialized')
add('dummy_inout_partial_flags',prog('integer :: aa(2,2)','''aa(2,2)=8
call partial(aa)
print *,aa(1,1),aa(2,2)
print *,aa(1,2)''','''subroutine partial(xx)
 integer,intent(inout) :: xx(:,:)
 xx(1,1)=42
end subroutine partial'''),'42 8',category='runtime',diagnostic='uninitialized')
add('dummy_dynamic_shape_mismatch',prog('integer :: aa(2,3),bb(3,2)','''aa=5
bb=9
print *,111
call combine(aa,bb)''','''subroutine combine(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=xx+yy
end subroutine combine'''),'111',category='runtime',diagnostic='conform')
add('dummy_empty_shape_mismatch',prog('integer :: aa(0,3),bb(0,2)','''print *,111
call combine(aa,bb)''','''subroutine combine(xx,yy)
 integer,intent(out) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=yy
end subroutine combine'''),'111',category='runtime',diagnostic='conform')
add('writable_whole_alias',prog('integer :: aa(2,2)','''aa=1
print *,111
call collide(aa,aa)''','''subroutine collide(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=yy+1
end subroutine collide'''),'111',category='runtime',diagnostic='overlapping')
add('writable_whole_element_alias',prog('integer :: aa(2,2)','''aa=1
print *,111
call collide(aa,aa(2,1))''','''subroutine collide(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy
 xx=yy+1
end subroutine collide'''),'111',category='runtime',diagnostic='overlapping')
add('empty_scalar_expansion_evaluated',prog('integer :: aa(0,3),unknown','''print *,111
aa=unknown'''),'111',category='runtime',diagnostic='uninitialized')
add('ranktwo_integer_overflow',prog('integer :: aa(2,2)','''aa=2147483647
print *,111
aa=aa+1'''),'111',category='runtime',diagnostic='overflow')
for dim in [0,3,-1]:
  for intrinsic in ['size','lbound','ubound']:
    add(f'bad_{intrinsic}_dim_{dim}'.replace('-','neg'),prog('integer :: aa(2,2),dd',f'dd={dim}\nprint *,111\nprint *,{intrinsic}(aa,dd)'),'111',category='runtime',diagnostic='DIM')

# Invalid Fortran and explicitly excluded valid language boundaries.
for name,decl,body in [
 ('static_shape_equal_total','integer :: aa(2,3),bb(3,2)','aa=bb'),
 ('static_shape_one_dimension','integer :: aa(2,3),bb(2,2)','aa=bb'),
 ('static_expression_shape','integer :: aa(2,3),bb(3,2)','print *,aa+bb'),
 ('scalar_subscript_arity_one','integer :: aa(2,3)','print *,aa(1)'),
 ('scalar_subscript_arity_three','integer :: aa(2,3)','print *,aa(1,2,1)'),
 ('real_first_subscript','integer :: aa(2,3)','print *,aa(1.0,2)'),
 ('real_second_subscript','integer :: aa(2,3)','print *,aa(1,2.0)'),
 ('logical_second_subscript','integer :: aa(2,3)','print *,aa(1,.true.)'),
 ('real_bound_second','integer :: aa(2,3.0)','print *,111'),
 ('rank_mismatch_assignment','integer :: aa(2,3),bb(6)','aa=bb'),
 ]:
  add(name,prog(decl,'print *,111\n'+body),category='invalid')
for name,decl,body in [
 ('rank_three','integer :: aa(2,2,2)','aa=1\nprint *,aa'),
 ('matrix_constructor_reshape','integer :: aa(2,2)','aa=reshape([1,2,3,4],[2,2])\nprint *,aa'),
 ('dimension_attribute','integer,dimension(2,3) :: aa','aa=1\nprint *,aa'),
 ('matrix_bound_vector_result','integer :: aa(2,3)','print *,lbound(aa)'),
 ]:
  add(name,prog(decl,'print *,111\n'+body),category='unsupported')
add('matrix_size_keyword',prog('integer :: aa(2,3)','print *,111\nprint *,size(aa,dim=2)'),[111,3])
for name,actual_decl,dummy_decl,call in [
 ('dummy_rank_one_to_two','integer :: aa(6)','integer,intent(in) :: xx(:,:)','consume(aa)'),
 ('dummy_rank_two_to_one','integer :: aa(2,3)','integer,intent(in) :: xx(:)','consume(aa)'),
 ('dummy_real_kind_mismatch','real(4) :: aa(2,3)','real(8),intent(in) :: xx(:,:)','consume(aa)'),
 ('dummy_expression_not_definable','integer :: aa(2,3)','integer,intent(out) :: xx(:,:)','consume(aa+1)'),
 ]:
    add(name,prog(actual_decl,'print *,111\ncall '+call,'subroutine consume(xx)\n'+dummy_decl+'\nend subroutine consume'),category='invalid')
for name,dummy_decl in [('dummy_explicit_shape','integer,intent(in) :: xx(2,3)'),('dummy_assumed_size','integer,intent(in) :: xx(2,*)')]:
    add(name,prog('integer :: aa(2,3)','aa=1\ncall consume(aa)','subroutine consume(xx)\n'+dummy_decl+'\nprint *,xx(1,1)\nend subroutine consume'),[1] if name=='dummy_explicit_shape' else '',category='success' if name=='dummy_explicit_shape' else 'unsupported')
add('size_limit_over',prog('integer :: aa(257,256)','print *,111'),category='unsupported',diagnostic='65536')
add('matrix_multiply_loops',prog('integer :: aa(2,3),bb(3,2),cc(2,2),ii,jj','''do jj=1,3
 do ii=1,2
 aa(ii,jj)=ii+2*jj
 end do
end do
do jj=1,2
 do ii=1,3
 bb(ii,jj)=2*ii-jj
 end do
end do
call multiply(aa,bb,cc)
print *,cc''','''subroutine multiply(xx,yy,zz)
 integer,intent(in) :: xx(:,:),yy(:,:)
 integer,intent(out) :: zz(:,:)
 integer :: ii,jj,kk
 zz=0
 do jj=1,size(zz,2)
 do ii=1,size(zz,1)
 do kk=1,size(xx,2)
 zz(ii,jj)=zz(ii,jj)+xx(ii,kk)*yy(kk,jj)
 end do
 end do
 end do
end subroutine multiply'''),[53,62,38,44])
add('real64_ranktwo_dummy',prog('real(8) :: aa(2,2)','''aa=1.25d0
call scale(aa)
print *,aa''','''subroutine scale(xx)
 real(8),intent(inout) :: xx(:,:)
 xx=xx*2.0d0
 xx(2,1)=xx(2,1)+0.125d0
end subroutine scale'''),'2.5 2.625 2.5 2.5',rel_tol=1e-12,abs_tol=1e-14)
add('logical_ranktwo_dummy',prog('logical :: aa(2,3)','''aa=.false.
call invert(aa)
print *,aa''','''subroutine invert(xx)
 logical,intent(inout) :: xx(:,:)
 xx=.not.xx
 xx(1,2)=.false.
end subroutine invert'''),['T','T','F','T','T','T'])
add('freeze_two_element_subscripts',prog('integer :: aa(2,3),ii,jj','''aa=1
ii=2
jj=1
call revise(aa(ii,jj),ii,jj)
print *,aa,ii,jj''','''subroutine revise(xx,ii,jj)
 integer,intent(inout) :: xx,ii,jj
 ii=1
 jj=3
 xx=7
end subroutine revise'''),[1,7,1,1,1,1,1,3])
add('empty_alias_no_elements',prog('integer :: aa(0,3)','''call revise(aa,aa)
print *,size(aa),size(aa,2)''','''subroutine revise(xx,yy)
 integer,intent(out) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=yy+1
end subroutine revise'''),[0,3],baseline='compile')
add('extreme_nonunit_bounds',prog('integer :: aa(-2147483647:-2147483646,2147483646:2147483647)','''aa=3
aa(-2147483646,2147483647)=7
print *,aa
print *,lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)'''),[3,3,3,7,-2147483647,-2147483646,2147483646,2147483647])
add('wide_but_empty',prog('integer :: aa(65536,0)','''print *,size(aa),size(aa,1),size(aa,2)
print *,lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
aa=1
print *,aa'''),[0,65536,0,1,65536,1,0])
add('multiple_array_size_limit',prog('integer :: aa(128,256),bb(256,128)','''aa=1
bb=2
print *,size(aa),size(bb),aa(128,256),bb(256,128)'''),[32768,32768,1,2],args=['--max-steps','2000000'])
add('static_empty_shape_mismatch',prog('integer :: aa(0,3),bb(0,2)','print *,111\naa=bb'),category='invalid')
add('static_intrinsic_shape_mismatch',prog('integer :: aa(2,3),bb(3,2)','print *,111\nprint *,min(aa,bb)'),category='invalid')
add('bounds_cancelled_flat_offset_write',prog('integer :: aa(2,3)','aa=9\nprint *,111\naa(3,0)=42'),'111',category='runtime',diagnostic='bounds')
add('dummy_out_reads_undefined',prog('integer :: aa(2,2)','''aa=9
print *,111
call revise(aa)''','''subroutine revise(xx)
 integer,intent(out) :: xx(:,:)
 print *,xx(2,2)
end subroutine revise'''),'111',category='runtime',diagnostic='uninitialized')
add('dummy_second_dim_bounds',prog('integer :: aa(2,3)','''aa=9
print *,111
call revise(aa)''','''subroutine revise(xx)
 integer,intent(inout) :: xx(-1:,5:)
 xx(0,8)=7
end subroutine revise'''),'111',category='runtime',diagnostic='bounds')
add('empty_expression_shape_mismatch',prog('integer :: aa(0,3),bb(0,2)','''print *,111
call revise(aa,bb)''','''subroutine revise(xx,yy)
 integer,intent(in) :: xx(:,:),yy(:,:)
 print *,xx+yy
end subroutine revise'''),'111',category='runtime',diagnostic='conform')
add('ranktwo_parenthesized_temporary',prog('integer :: aa(2,2)','''aa=3
call revise(aa,(aa))
print *,aa''','''subroutine revise(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=xx+yy
end subroutine revise'''),[6]*4)
add('ranktwo_branch_and_do',prog('integer :: aa(2,2),ii','''aa=1
if (aa(2,1)==1) aa(1,2)=4
do ii=aa(1,1),aa(1,2)
 aa(2,2)=aa(2,2)+ii
end do
if (aa(2,2)>5) then
 print *,aa
else
 print *,999
end if'''),[1,1,4,11])
add('same_shape_different_bounds_binary',prog('integer :: aa(-1:0,3:5),bb(7:8,-4:-2),ii,jj','''do jj=3,5
 do ii=-1,0
 aa(ii,jj)=ii+jj
 end do
end do
do jj=-4,-2
 do ii=7,8
 bb(ii,jj)=ii-jj
 end do
end do
print *,aa+bb,bb-aa'''),[13,15,13,15,13,15,9,9,7,7,5,5])

add('local_rankone_fresh_frame',prog('integer :: kk','''print *,work(2),work(5)''','''integer function work(xx) result(rr)
 integer,intent(in) :: xx
 integer :: local(-1:1)
 local=xx
 local(0)=xx+3
 rr=local(-1)+local(0)+local(1)
end function work'''),[9,18])
add('local_ranktwo_fresh_undefined',prog('integer :: kk','''print *,work(1)
print *,work(2)''','''integer function work(xx) result(rr)
 integer,intent(in) :: xx
 integer :: local(2,2)
 if (xx==1) local=7
 rr=local(2,2)
end function work'''),'7',category='runtime',diagnostic='uninitialized')
add('local_ranktwo_forwarded',prog('integer :: answer','''call outer(answer)
print *,answer''','''subroutine outer(rr)
 integer,intent(out) :: rr
 integer :: local(-1:0,4:6)
 local=3
 call inner(local)
 rr=local(-1,4)+local(0,6)
end subroutine outer
subroutine inner(xx)
 integer,intent(inout) :: xx(:,:)
 xx=xx*2
 xx(2,3)=19
end subroutine inner'''),[25])
add('array_result_remains_unsupported',prog('integer :: kk','''print *,array_result()''','''function array_result() result(rr)
 integer :: rr(2,2)
 rr=1
end function array_result'''),[1,1,1,1])

# Rank-two sections are supported since 0.10.0. Preserve the former probes.
add('matrix_section',prog('integer :: aa(2,3)','print *,111\naa=1\nprint *,aa(:,:)'),[111]+[1]*6)
add('column_section',prog('integer :: aa(2,3)','print *,111\naa=1\nprint *,aa(:,2)'),[111]+[1]*2)
add('row_section',prog('integer :: aa(2,3)','print *,111\naa=1\nprint *,aa(1,:)'),[111]+[1]*3)
# The array cap is now 131072; retain historical boundary source fixtures.
# Current-cap tests are generated from fi_ir in tests/array_limits/run_tests.py.
ARRAY_LIMIT_MIGRATIONS = {'size_limit_over': '111'}
for row in CASES:
    if row['name'] in ARRAY_LIMIT_MIGRATIONS:
        row.update(category='success', baseline='run', expected_stdout=ARRAY_LIMIT_MIGRATIONS[row['name']],
                   note='Historical 65536-element cap probe; legal with the larger cap.')
        row.pop('diagnostic', None)

# RESHAPE is supported since 0.22.0; retain the historical fixture unchanged.
for row in CASES:
    if row['name'] == 'matrix_constructor_reshape':
        row.update(category='success', baseline='run', expected_stdout='111 1 2 3 4',
                   note='RESHAPE is supported in 0.22.0; preserve the original source unchanged.')

# DIMENSION attributes supported since 0.23.0; retain the original fixture.
for row in CASES:
    if row['name'] == 'dimension_attribute':
        row.update(category='success', baseline='run', expected_stdout='111 1 1 1 1 1 1',
                   note='DIMENSION attributes supported in 0.23.0; original source unchanged.')

# Rank-three milestone: retain the original fixture as a positive oracle.
for row in CASES:
    if row['name'] == 'rank_three':
        row.update(category='success', baseline='run', expected_stdout='111 1 1 1 1 1 1 1 1')

# Vector LBOUND is supported since 0.46.0; retain the original fixture.
for row in CASES:
    if row['name'] == 'matrix_bound_vector_result':
        row.update(category='success', baseline='run', expected_stdout='111 1 1',
                   note='Vector LBOUND is supported in 0.46.0; original source unchanged.')

(ROOT/'manifest.json').write_text(json.dumps(dict(cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} cases')
