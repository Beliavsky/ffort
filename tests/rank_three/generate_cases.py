#!/usr/bin/env python3
"""Independent Python-calculated column-major rank-three oracle fixtures."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;cases=[]
def add(name,decl,body,expected='',contained='',category='success',baseline=None):
 s='program rankthree\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+contained+'\n' if contained else '')+'end program rankthree\n'
 rawadd(name,s,expected,category,baseline)
def rawadd(name,s,expected='',category='success',baseline=None):
 (R/'cases'/f'{name}.f90').write_text(s)
 if not isinstance(expected,str): expected=' '.join(map(str,expected))
 cases.append(dict(name=name,source=f'cases/{name}.f90',category=category,baseline=baseline or ('run' if category=='success' else 'compile' if category in ('runtime','unsupported') else 'reject'),expected_stdout=expected))
def keys(xs,ys,zs):return [(i,j,k) for k in zs for j in ys for i in xs]
def val(q):i,j,k=q;return 100*k+10*j+i
for n,m,l in [(1,1,1),(2,3,4),(3,2,2),(0,3,2),(2,0,3),(2,3,0)]:
 for lo,lj,lk in [(1,1,1),(-2,4,-3)]:
  vv=[val(q) for q in keys(range(lo,lo+n),range(lj,lj+m),range(lk,lk+l))]
  bounds=[v for low,ex in [(lo,n),(lj,m),(lk,l)] for v in (low if ex else 1,low+ex-1 if ex else 0)]
  add(f'layout_{n}_{m}_{l}_{lo}_{lj}_{lk}'.replace('-','neg'),f'integer :: aa({lo}:{lo+n-1},{lj}:{lj+m-1},{lk}:{lk+l-1}),bb({n},{m},{l}),i,j,k',f'''do k={lk},{lk+l-1}
do j={lj},{lj+m-1}
do i={lo},{lo+n-1}
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
bb=max(abs(-aa),7)+2
print *,aa,bb
print *,size(aa),size(aa,1),size(aa,2),size(aa,3)
print *,lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2),lbound(aa,3),ubound(aa,3)
print *,size(aa+1,3),lbound(aa+1,3),ubound(aa+1,3)''',vv+[max(abs(v),7)+2 for v in vv]+[n*m*l,n,m,l]+bounds+[l,1,l])
xs=[-1,0,1];ys=[2,3];zs=[4,5,6];kk=keys(xs,ys,zs)
init='''do k=4,6
do j=2,3
do i=-1,1
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
'''
for mask in range(1,8):
 sels=[];axes=[];dims=[]
 for d,axis in enumerate([xs,ys,zs]):
  if mask&(1<<d):sels.append(':');axes.append(axis);dims.append(len(axis))
  else:sels.append(str(axis[1]));axes.append([axis[1]])
 section='aa('+','.join(sels)+')';vv=[val(q) for q in keys(*axes)]
 body=init+f'bb={section}+3\nprint *,{section},bb\nprint *,size({section})\n'+'\n'.join(f'print *,size({section},{d}),lbound({section},{d}),ubound({section},{d})' for d in range(1,len(dims)+1))
 add(f'section_rank_{len(dims)}_axes_{mask}',f'integer :: aa(-1:1,2:3,4:6),bb({",".join(map(str,dims))}),i,j,k',body,vv+[v+3 for v in vv]+[len(vv)]+[z for n in dims for z in [n,1,n]])
for name,lhs,rhs,lk,rk in [('reverse_all',':,:,:','1:-1:-1,3:2:-1,6:4:-1',kk,keys(xs[::-1],ys[::-1],zs[::-1])),('shift_third',':,:,5:6',':,:,4:5',keys(xs,ys,[5,6]),keys(xs,ys,[4,5])),('interleaved','-1:1:2,:,4:6:2','1:-1:-2,3:2:-1,6:4:-2',keys([-1,1],ys,[4,6]),keys([1,-1],ys[::-1],[6,4]))]:
 vv={q:val(q) for q in kk};snap=[vv[q] for q in rk]
 for q,v in zip(lk,snap):vv[q]=v
 add('overlap_'+name,'integer :: aa(-1:1,2:3,4:6),i,j,k',init+f'aa({lhs})=aa({rhs})\nprint *,aa',[vv[q] for q in kk])
add('dynamic_third_section','integer :: aa(-1:1,2:3,4:6),i,j,k,lo,hi,st',init+'lo=6\nhi=4\nst=-2\nprint *,aa(:,3,lo:hi:st)\naa(:,3,lo:hi:st)=9\nprint *,aa',[val(q) for q in keys(xs,[3],[6,4])]+[9 if q[1]==3 and q[2] in (4,6) else val(q) for q in kk])
add('real_and_logical','real(8) :: aa(2,1,2)\nlogical :: ll(2,1,2)','aa=4.0d0\naa(2,1,2)=9.0d0\nprint *,sqrt(aa)+0.5d0\nll=aa>5.0d0\nprint *,ll,.not.ll',[2.5,2.5,2.5,3.5,'F','F','F','T','T','T','T','F'])
add('character','character(3) :: aa(2,1,2)',"aa='abc'\naa(2,1,2)='xyz'\nprint *,aa(1,1,1),aa(2,1,2)",'abcxyz')
add('automatic_result_dummy_copyback','integer :: aa(2,2,3),bb(2,2,3)','aa=1\ncall bump(aa(:,:,3:1:-1),2,2,3)\nbb=twice(aa)\nprint *,aa,bb',[3]*8+[8,3,3,3]+[6]*8+[16,6,6,6],'''subroutine bump(xx,n,m,l)
integer,intent(in) :: n,m,l
integer,intent(inout) :: xx(-2:,4:,7:)
integer :: temp(n,m,l)
temp=xx+2
xx=temp
xx(-2,4,7)=8
end subroutine bump
function twice(xx) result(rr)
integer,intent(in) :: xx(:,:,:)
integer :: rr(size(xx,1),size(xx,2),size(xx,3))
rr=xx*2
end function twice''')
add('automatic_inout_inquiry','integer :: aa(2,3,4)','aa=1\ncall bump(aa)\nprint *,aa',[2]*24,'''subroutine bump(xx)
integer,intent(inout) :: xx(:,:,:)
integer :: temp(size(xx,1),size(xx,2),size(xx,3))
temp=xx+1
xx=temp
end subroutine bump''')
add('optional_elemental','integer :: aa(2,2,2)','aa=2\ncall maybe(aa)\ncall maybe()\naa=square(aa)\ncall bump(aa)\nprint *,aa',[10]*8,'''subroutine maybe(xx)
integer,intent(inout),optional :: xx(:,:,:)
if (present(xx)) then
xx=xx+1
end if
end subroutine maybe
elemental integer function square(x) result(r)
integer,intent(in) :: x
r=x*x
end function square
elemental subroutine bump(x)
integer,intent(inout) :: x
x=x+1
end subroutine bump''')
for dims in [(0,2147483647,2147483647),(2147483647,0,2147483647),(2147483647,2147483647,0)]:
 add('zero_huge_'+str(dims.index(0)),'integer :: aa('+','.join(map(str,dims))+')','print *,size(aa),size(aa,1),size(aa,2),size(aa,3)',[0,*dims],baseline='skip')
add('cap_exact','integer :: aa(32,32,128)','aa=7\nprint *,size(aa),aa(32,32,128)',[131072,7])
for name,shape in [('cap_exceeded','100,100,101'),('int64_product_overflow','2147483647,2147483647,2147483647')]:add(name,'integer :: aa('+shape+')','print *,size(aa)',category='unsupported',baseline='skip')
add('rank_four','integer :: aa(1,1,1,1)','aa=1',category='unsupported')
for name,decl,body in [('allocatable','integer,allocatable :: aa(:,:,:)','allocate(aa(1,1,1))'),('sum','integer :: aa(2,2,2)','aa=1\nprint *,sum(aa)'),('maxloc','integer :: aa(2,2,2)','aa=1\nprint *,maxloc(aa)'),('pack','integer :: aa(2,2,2)','aa=1\nprint *,pack(aa,.true.)'),('reshape','integer :: aa(2,2,2)','aa=reshape([1,2,3,4,5,6,7,8],[2,2,2])')]:add('limited_'+name,decl,body,category='unsupported')
add('same_size_wrong_shape','integer :: aa(2,3,4),bb(4,3,2)','aa=1\nbb=aa',category='invalid')
add('runtime_wrong_shape','integer :: aa(2,3,4),bb(4,3,2)','aa=1\nbb=1\ncall copy(aa,bb)',contained='subroutine copy(x,y)\ninteger,intent(in) :: x(:,:,:)\ninteger,intent(out) :: y(:,:,:)\ny=x\nend subroutine copy',category='runtime')
add('third_index_oob','integer :: aa(2,2,2),k','aa=1\nk=3\nprint *,aa(1,1,k)',category='runtime')
original=R/'xutilities_tensor_original.f90'
if not original.exists(): raise FileNotFoundError('Missing included original tensor procedure')
body=original.read_text().rstrip('\n')
rawadd('original_xutilities_tensor','module tensor_fixture\nimplicit none\ninteger,parameter :: dp=kind(1.0d0)\ncontains\n'+body+'''\nend module tensor_fixture
program synthetic_tensor_driver
use tensor_fixture
implicit none
real(kind=dp) :: aa(2,3),bb(2,3,1)
integer :: i,j
do j=1,3
do i=1,2
aa(i,j)=10*j+i
end do
end do
bb=tensor(aa)
print *,bb,size(bb,1),size(bb,2),size(bb,3)
end program synthetic_tensor_driver
''',[11,12,21,22,31,32,2,3,1])
# RANDOM_NUMBER is checked by invariants, never by comparison with GNU's stream.
add('random_rank_three_range','real(8) :: aa(2,3,4)\ninteger :: i,j,k,n','''call random_number(aa)
n=0
do k=1,4
do j=1,3
do i=1,2
if (aa(i,j,k)>=0.0d0.and.aa(i,j,k)<1.0d0) n=n+1
end do
end do
end do
print *,size(aa),size(aa,3),n''',[24,4,24])
add('random_rank_three_section','real :: aa(2,2,3)\ninteger :: i,j,k,n','''aa=-1.0
call random_number(aa(:,:,3:1:-2))
n=0
do k=1,3,2
do j=1,2
do i=1,2
if (aa(i,j,k)>=0.0.and.aa(i,j,k)<1.0) n=n+1
end do
end do
end do
print *,n,aa(:,:,2)''',[8,-1,-1,-1,-1])
add('parameter_scalar_slice_bounds','''integer,parameter :: aa(-1:0,3:5,7:10)=4
integer,parameter :: bb(2,3)=aa(:,:,8)
integer,parameter :: n=aa(-1,3,7),m=size(aa,2),l=ubound(aa,3)-lbound(aa,3)+1
integer :: cc(n,m,l)''','''cc=bb(1,1)+1
print *,aa(:,4,9),bb,size(cc),size(cc,3),cc(4,3,4)''',[4,4]+[4]*6+[48,4,5])
for mode,statement,expected in [('read','v=aa(1,1,next(2))\nprint *,v,hits',[7,1]),('write','aa(1,1,next(2))=9\nprint *,aa,hits',[7,9,1]),('dummy','call bump(aa(1,1,next(2)))\nprint *,aa,hits',[7,17,1])]:
 rawadd('impure_third_index_'+mode,'''module counter_state
implicit none
integer :: hits
contains
impure elemental integer function next(x) result(k)
integer,intent(in) :: x
hits=hits+1
k=x
end function next
subroutine bump(v)
integer,intent(inout) :: v
v=v+10
end subroutine bump
end module counter_state
program third_index_once
use counter_state
implicit none
integer :: aa(1,1,2),v
hits=0
aa=7
'''+statement+'\nend program third_index_once\n',expected)
# Retain the historical allocation boundary source as a positive oracle.
for case in cases:
 if case['name']=='limited_allocatable':
  case.update(category='success',baseline='run',expected_stdout='')

(R/'manifest.json').write_text(json.dumps(dict(description='Independent rank-three array fixtures',original_tensor_sha256=hashlib.sha256(body.encode()).hexdigest(),cases=cases),indent=2)+'\n')
print(f'Generated {len(cases)} cases')
