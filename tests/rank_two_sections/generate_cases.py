#!/usr/bin/env python3
"""Independent rank-two section fixtures, with Python-calculated expectations.

No interpreter module is imported. Indices and output are enumerated independently
in Fortran column-major order. GNU Fortran is the second oracle.
"""
from pathlib import Path
from textwrap import dedent
import json
import random
ROOT=Path(__file__).resolve().parent
CASES=[]

def add(name,source,expected='',category='success',baseline=None,diagnostic=None,**kw):
    if baseline is None:
        baseline='run' if category=='success' else 'compile' if category in ('runtime','unsupported') else 'reject'
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(dedent(source).strip()+'\n')
    if not isinstance(expected,str): expected=' '.join(str(x) for x in expected)
    case=dict(name=name,source=f'cases/{name}.f90',category=category,baseline=baseline,expected_stdout=expected,**kw)
    if diagnostic: case['diagnostic']=diagnostic
    CASES.append(case)

def prog(decl,body,contained=''):
    return 'program section_oracle\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+contained+'\n' if contained else '')+'end program section_oracle\n'

def initialize(lo=-2,hi=3,lj=4,hj=8):
    return f'do j={lj},{hj}\n do i={lo},{hi}\n aa(i,j)=100*j+i\n end do\nend do\n'

def mapping(xs,ys): return [(i,j) for j in ys for i in xs]
def flat(aa,lo=-2,hi=3,lj=4,hj=8): return [aa[i,j] for i,j in mapping(range(lo,hi+1),range(lj,hj+1))]
def initial(lo=-2,hi=3,lj=4,hj=8): return {(i,j):100*j+i for i,j in mapping(range(lo,hi+1),range(lj,hj+1))}

# Ten triplet forms and three scalars in each dimension: all 160 section pairs.
# Include out-of-bounds nonselected endpoints and empty out-of-bounds triplets.
D1=[(':',list(range(-2,4)),False),('::2',[-2,0,2],False),('-2:3:3',[-2,1],False),
    ('3:-2:-2',[3,1,-1],False),('3::-1',[3],False),(':3:-1',[],False),
    ('::-1',[],False),('1:0',[],False),('-20:-21',[],False),('-2:4:4',[-2,2],False),
    ('-2',[-2],True),('1',[1],True),('3',[3],True)]
D2=[(':',list(range(4,9)),False),('::2',[4,6,8],False),('4:8:3',[4,7],False),
    ('8:4:-2',[8,6,4],False),('8::-1',[8],False),(':8:-1',[],False),
    ('::-1',[],False),('6:5',[],False),('20:19',[],False),('4:9:3',[4,7],False),
    ('4',[4],True),('6',[6],True),('8',[8],True)]
for p,(sx,xs,xscalar) in enumerate(D1):
 for q,(sy,ys,yscalar) in enumerate(D2):
    if xscalar and yscalar: continue
    dims=([len(xs)] if not xscalar else [])+([len(ys)] if not yscalar else [])
    section=f'aa({sx},{sy})'
    selected=mapping(xs,ys)
    values=[100*j+i for i,j in selected]
    aa=initial()
    for key in selected: aa[key]+=1000
    inquiries=[len(values)]+dims+[item for dim in dims for item in (1,dim)]
    body=initialize()+f'print *, {section}\nprint *,size({section})\n'
    for d in range(1,len(dims)+1): body+=f'print *,size({section},{d})\n'
    for d in range(1,len(dims)+1): body+=f'print *,lbound({section},{d}),ubound({section},{d})\n'
    body+=f'bb={section}+2\nprint *,bb\n{section}={section}+1000\nprint *,aa'
    add(f'selection_{p:02}_{q:02}',prog(f'integer :: aa(-2:3,4:8),bb({",".join(map(str,dims))}),i,j',body),values+inquiries+[v+2 for v in values]+flat(aa))

# Runtime scalar selectors and triplets ensure selection is resolved at execution.
add('runtime_triplets_both_dimensions',prog('integer :: aa(-2:3,4:8),i,j,lo,hi,st,col,cl,ch,cs',initialize()+'''lo=3
hi=-2
st=-2
cl=8
ch=4
cs=-2
col=6
print *,aa(lo:hi:st,cl:ch:cs)
print *,aa(lo:hi:st,col)
print *,aa(lo,cl:ch:cs)
print *,size(aa(lo:hi:st,cl:ch:cs),1),size(aa(lo:hi:st,cl:ch:cs),2)
aa(lo:hi:st,cl:ch:cs)=17
print *,aa'''),[100*j+i for i,j in mapping([3,1,-1],[8,6,4])]+[603,601,599]+[803,603,403]+[3,3]+[17 if i in [3,1,-1] and j in [8,6,4] else 100*j+i for i,j in mapping(range(-2,4),range(4,9))])

# Assignment must snapshot overlapping RHS selections, including mixed ranks.
assignment_specs=[('shift_columns',':,5:8',':,4:7',mapping(range(-2,4),range(5,9)),mapping(range(-2,4),range(4,8))),
 ('shift_rows','-1:3,:','-2:2,:',mapping(range(-1,4),range(4,9)),mapping(range(-2,3),range(4,9))),
 ('reverse_both',':,:','3:-2:-1,8:4:-1',mapping(range(-2,4),range(4,9)),mapping(range(3,-3,-1),range(8,3,-1))),
 ('mixed_row_reverse','-2,:','3,8:4:-1',mapping([-2],range(4,9)),mapping([3],range(8,3,-1))),
 ('mixed_column_reverse',':,4','3:-2:-1,8',mapping(range(-2,4),[4]),mapping(range(3,-3,-1),[8])),
 ('interleaved_both','-1:3:2,4:8:2','-2:2:2,8:4:-2',mapping([-1,1,3],[4,6,8]),mapping([-2,0,2],[8,6,4]))]
for name,lhs,rhs,lk,rk in assignment_specs:
    aa=initial();vv=[aa[k] for k in rk]
    for k,v in zip(lk,vv): aa[k]=v
    add('snapshot_'+name,prog('integer :: aa(-2:3,4:8),i,j',initialize()+f'aa({lhs})=aa({rhs})\nprint *,aa'),flat(aa))

# Deterministic random strided assignments, always conformable but often overlapping.
rng=random.Random(98010)
for k in range(32):
    nx,ny=rng.randint(1,3),rng.randint(1,3)
    def pick(lo,hi,count):
        while True:
            step=rng.choice([-2,-1,1,2]);start=rng.randint(lo,hi);last=start+(count-1)*step
            if lo<=last<=hi: return f'{start}:{last}:{step}',list(range(start,last+(1 if step>0 else -1),step))
    lx,xs=pick(-2,3,nx);ly,ys=pick(4,8,ny);rx,xx=pick(-2,3,nx);ry,yy=pick(4,8,ny)
    aa=initial();vv=[aa[z]*2-7 for z in mapping(xx,yy)]
    for z,v in zip(mapping(xs,ys),vv): aa[z]=v
    add(f'random_snapshot_{k:02}',prog('integer :: aa(-2:3,4:8),i,j',initialize()+f'aa({lx},{ly})=2*aa({rx},{ry})-7\nprint *,aa'),flat(aa))

add('empty_dimension_inquiries',prog('integer :: aa(-2:-3,4:8),bb(-2:3,4:3)', '''print *,size(aa(:,:)),size(aa(:,:),1),size(aa(:,:),2)
print *,lbound(aa(:,:),1),ubound(aa(:,:),1),lbound(aa(:,:),2),ubound(aa(:,:),2)
print *,size(bb(:,:)),size(bb(:,:),1),size(bb(:,:),2)
print *,lbound(bb(:,:),1),ubound(bb(:,:),1),lbound(bb(:,:),2),ubound(bb(:,:),2)
aa(:,:)=3
bb(:,:)=7
print *,aa(:,:),bb(:,:)'''),[0,0,5,1,0,1,5,0,6,0,1,6,1,0])
add('inquiries_without_element_reads',prog('integer :: aa(-2:3,4:8)', '''print *,size(aa(3:-2:-2,8:4:-2)),size(aa(3,4:8))
print *,size(aa(:,5),1),lbound(aa(3:-2:-2,8:4:-2),2),ubound(aa(3:-2:-2,8:4:-2),2)
print *,size(aa(3:-2:-2,8:4:-2)+1),size(aa(3,:)+aa(-2,:))'''),[9,5,6,1,3,9,5])
add('zero_extent_scalar_still_reads_rhs',prog('integer :: aa(3,3),vv', 'aa=7\nprint *,111\naa(2:1,:)=vv'),[111],category='runtime',diagnostic='uninitialized')
add('zero_extent_array_skips_rhs_data',prog('integer :: aa(3,3),vv,zz', """aa=7
aa(2:1,:)=aa(2:1,:)+vv
print *,aa,size(aa(:,2:1)+vv)
zz=0
aa(:,2:1)=aa(:,2:1)+1/zz
print *,aa"""),[7]*9+[0]+[7]*9,baseline='compile')
add('real32_section_assignment',prog('real :: aa(-1:2,3:5)\ninteger :: bb(2,2)', '''aa=1.25
aa(-1:2:2,3:5:2)=2.75
bb=aa(-1:2:2,3:5:2)
print *,aa,bb
print *,sqrt(aa(-1:2:2,3:5:2)),aa(-1:2:2,3:5:2)>2.0'''),[2.75,1.25,2.75,1.25,1.25,1.25,1.25,1.25,2.75,1.25,2.75,1.25]+[2]*4+[2.75**0.5]*4+['T']*4)
add('real64_section_expression',prog('real(8) :: aa(2,3)', '''aa=0.5d0
aa(1,1)=1.0d0
aa(2,3)=2.0d0
print *,exp(aa(2:1:-1,3:1:-2)),real(aa(:,2)),int(aa(:,1))'''),[7.38905609893065,1.6487212707001282,1.6487212707001282,2.718281828459045,0.5,0.5,1,0],rel_tol=1e-12,abs_tol=1e-14)
add('logical_sections',prog('logical :: aa(2,3)', '''aa=.false.
aa(1,:)=.true.
print *,aa(:,3:1:-1),.not.aa(1,:),aa(1,:).and.aa(2,:)
aa(:,2:3)=.not.aa(:,1:2)
print *,aa'''),['T','F']*3+['F']*6+['T','F','F','T','F','T'])

# Actual sections rebase independently, preserve element order and scatter copy-out.
add('dummy_ranktwo_inout_rebased',prog('integer :: aa(-2:3,4:8),i,j',initialize()+'''call change(aa(3:-2:-2,8:4:-2))
print *,aa''','''subroutine change(xx)
integer,intent(inout) :: xx(-3:,7:)
print *,size(xx),size(xx,1),size(xx,2),lbound(xx,1),ubound(xx,1),lbound(xx,2),ubound(xx,2)
print *,xx
xx=xx+1000
end subroutine'''),[9,3,3,-3,-1,7,9]+[100*j+i for i,j in mapping([3,1,-1],[8,6,4])]+[100*j+i+(1000 if i in [3,1,-1] and j in [8,6,4] else 0) for i,j in mapping(range(-2,4),range(4,9))])
add('dummy_row_column_rankone',prog('integer :: aa(-2:3,4:8),i,j',initialize()+'''call change(aa(1,8:4:-1),10)
call change(aa(3:-2:-2,5),20)
print *,aa''','''subroutine change(xx,amount)
integer,intent(inout)::xx(-3:)
integer,intent(in)::amount
print *,size(xx),lbound(xx,1),ubound(xx,1)
xx=xx+amount
end subroutine'''),[5,-3,1,3,-3,-1]+[100*j+i+(10 if i==1 else 0)+(20 if i in [3,1,-1] and j==5 else 0) for i,j in mapping(range(-2,4),range(4,9))])
add('dummy_nested_forwarding',prog('integer :: aa(-2:3,4:8),i,j',initialize()+'''call outer(aa(3:-2:-1,8:4:-2))
print *,aa''','''subroutine outer(xx)
integer,intent(inout)::xx(-3:,7:)
call inner(xx(-2:1:2,9:7:-1))
call line(xx(-3,7:9))
end subroutine
subroutine inner(yy)
integer,intent(inout)::yy(:,:)
yy=yy+1000
end subroutine
subroutine line(zz)
integer,intent(inout)::zz(:)
zz=zz+2000
end subroutine'''),[100*j+i+(1000 if i in [2,0] and j in [4,6,8] else 0)+(2000 if i==3 and j in [4,6,8] else 0) for i,j in mapping(range(-2,4),range(4,9))])
add('dummy_partial_in_reads_selected_only',prog('integer :: aa(3,3)', '''aa(3,3)=71
print *,first(aa(3:1:-1,3:1:-1))''','''integer function first(xx) result(ans)
integer,intent(in)::xx(:,:)
ans=xx(1,1)
end function'''),[71])
add('dummy_out_only_selected',prog('integer :: aa(3,3)', '''aa=9
call fill(aa(1:3:2,3:1:-2))
print *,aa''','''subroutine fill(xx)
integer,intent(out)::xx(:,:)
xx=7
end subroutine'''),[7,9,7,9,9,9,7,9,7])
add('dummy_ranktwo_expression_temporary',prog('integer :: aa(3,3)', '''aa=2
call work(aa(1:3:2,1:3:2),aa(1:3:2,1:3:2)+1)
print *,aa''','''subroutine work(xx,yy)
integer,intent(inout)::xx(:,:)
integer,intent(in)::yy(:,:)
xx=xx+yy
end subroutine'''),[5,2,5,2,2,2,5,2,5])
add('dummy_readonly_alias_accepted',prog('integer :: aa(3,3)', '''aa=2
call work(aa(1:3:2,:),aa(:,1:3:2))''','''subroutine work(xx,yy)
integer,intent(in)::xx(:,:),yy(:,:)
print *,xx,yy
end subroutine'''),[2]*12)
add('dummy_freezes_indices_before_call',prog('integer :: aa(3,3),ii,jj', '''aa=1
ii=2
jj=3
call work(aa(ii,jj:1:-1),ii,jj)
print *,aa,ii,jj''','''subroutine work(xx,ii,jj)
integer,intent(inout)::xx(:),ii,jj
ii=1
jj=1
xx=7
end subroutine'''),[1,7,1]*3+[1,1])
add('dummy_empty_bindings_do_not_overlap',prog('integer :: aa(3,3)', '''aa=9
call work(aa(2:1,:),aa(:,2:1))
print *,aa''','''subroutine work(xx,yy)
integer,intent(inout)::xx(:,:),yy(:,:)
print *,size(xx),size(xx,1),size(xx,2),size(yy),size(yy,1),size(yy,2)
xx=1
yy=2
end subroutine'''),[0,0,3,0,3,0]+[9]*9)
add('dummy_empty_rebased_inquiry',prog('integer :: aa(3,3)', '''call work(aa(2:1,:))''','''subroutine work(xx)
integer,intent(in)::xx(-3:,7:)
print *,size(xx),lbound(xx,1),ubound(xx,1),lbound(xx,2),ubound(xx,2)
end subroutine'''),[0,1,0,7,9])

# Aliasing pairs deliberately exercise non-arithmetic flat mappings, reverse
# mappings and min/max coincidences that a one-dimensional shortcut gets wrong.
alias_specs=[
 ('interleaved_rows',':,4:8:2',':,5:7:2',mapping(range(-2,4),[4,6,8]),mapping(range(-2,4),[5,7])),
 ('interleaved_columns','-2:2:2,:','-1:3:2,:',mapping([-2,0,2],range(4,9)),mapping([-1,1,3],range(4,9))),
 ('cross_diagonals','-2:0:2,4:8:4','-1:3:4,5:7:2',mapping([-2,0],[4,8]),mapping([-1,3],[5,7])),
 ('reverse_disjoint','3:1:-1,8:4:-2','0:-2:-1,4:8:2',mapping([3,2,1],[8,6,4]),mapping([0,-1,-2],[4,6,8])),
 ('same','-2:2:2,4:8:2','-2:2:2,4:8:2',mapping([-2,0,2],[4,6,8]),mapping([-2,0,2],[4,6,8])),
 ('one_middle_point','-2:2:2,4:8:2','0:1,5:6',mapping([-2,0,2],[4,6,8]),mapping([0,1],[5,6])),
 ('reversed_overlap','3:-2:-2,8:4:-2','-2:3,4:8',mapping([3,1,-1],[8,6,4]),mapping(range(-2,4),range(4,9))),
 ('interior_not_endpoints','-2:3,4:8:2','-2:3,6:6',mapping(range(-2,4),[4,6,8]),mapping(range(-2,4),[6]))]
for name,left,right,lk,rk in alias_specs:
    overlap=bool(set(lk)&set(rk));aa=initial()
    if not overlap:
        for z in lk: aa[z]+=1000
        for z in rk: aa[z]+=2000
    source=prog('integer :: aa(-2:3,4:8),i,j',initialize()+f'print *,111\ncall work(aa({left}),aa({right}))\nprint *,aa','''subroutine work(xx,yy)
integer,intent(inout)::xx(:,:),yy(:,:)
print *,222
xx=xx+1000
yy=yy+2000
end subroutine''')
    add('alias_'+name,source,[111] if overlap else [111,222]+flat(aa),category='runtime' if overlap else 'success',baseline='skip' if overlap else 'run',diagnostic='overlapping' if overlap else None)

# Runtime failures must happen at execution, with preceding output preserved.
runtime=[
 ('stride_first_zero','integer :: aa(3,3),ss','aa=1\nss=0\nprint *,111\nprint *,aa(::ss,:)','stride'),
 ('stride_second_zero','integer :: aa(3,3),ss','aa=1\nss=0\nprint *,111\nprint *,aa(:,::ss)','stride'),
 ('stride_zero_even_if_other_empty','integer :: aa(3,3),ss','ss=0\nprint *,111\nprint *,size(aa(2:1,::ss))','stride'),
 ('scalar_first_bounds','integer :: aa(3,3),ii','aa=1\nii=0\nprint *,111\nprint *,aa(ii,:)','bounds'),
 ('scalar_second_bounds','integer :: aa(3,3),ii','aa=1\nii=4\nprint *,111\nprint *,aa(:,ii)','bounds'),
 ('triplet_first_bounds','integer :: aa(3,3),ii','aa=1\nii=4\nprint *,111\nprint *,aa(1:ii,:)','bounds'),
 ('triplet_second_bounds','integer :: aa(3,3),ii','aa=1\nii=0\nprint *,111\nprint *,aa(:,3:ii:-1)','bounds'),
 ('scalar_invalid_with_other_empty','integer :: aa(3,3),ii','ii=0\nprint *,111\nprint *,size(aa(ii,2:1))','bounds'),
 ('undefined_scalar_selector','integer :: aa(3,3),ii','aa=1\nprint *,111\nprint *,aa(ii,:)','uninitialized'),
 ('undefined_second_triplet','integer :: aa(3,3),ii','aa=1\nprint *,111\nprint *,aa(:,1:ii)','uninitialized'),
 ('undefined_selected_read','integer :: aa(3,3)','aa(1,1)=1\nprint *,111\nprint *,aa(1:2,1)','uninitialized'),
 ('inquiry_bad_dim','integer :: aa(3,3),dd','dd=2\nprint *,111\nprint *,size(aa(1,:),dd)','DIM'),
 ('shape_mismatch_equal_total','integer :: aa(3,3),nn','aa=1\nnn=2\nprint *,111\naa(1:nn,1:3)=aa(1:3,1:nn)','conform'),
 ('shape_mismatch_empty_dims','integer :: aa(3,3),nn','nn=2\nprint *,111\naa(nn:1,:)=aa(:,nn:1)','conform'),
 ('scalar_expansion_reads_once','integer :: aa(3,3)','print *,111\naa(:,1)=aa(1,1)','uninitialized'),
 ('expression_conformance','integer :: aa(3,3),nn','aa=1\nnn=2\nprint *,111\nprint *,aa(1:nn,:)+aa(:,1:nn)','conform'),
 ('selected_write_bounds','integer :: aa(3,3),ii','aa=1\nii=4\nprint *,111\naa(:,1:ii)=3','bounds'),
]
for name,decl,body,diag in runtime: add(name,prog(decl,body),[111],category='runtime',diagnostic=diag)
add('dummy_out_partial_undefined_copyback',prog('integer :: aa(3,3)', '''aa=9
call partial(aa(1:3:2,1:3:2))
print *,aa(2,2),aa(1,1)
print *,aa(3,3)''','''subroutine partial(xx)
integer,intent(out)::xx(:,:)
xx(1,1)=7
end subroutine'''),[9,7],category='runtime',diagnostic='uninitialized')
add('dummy_out_read_undefined',prog('integer :: aa(3,3)', '''aa=9
print *,111
call work(aa(:,1:3:2))''','''subroutine work(xx)
integer,intent(out)::xx(:,:)
print *,xx(1,1)
end subroutine'''),[111],category='runtime',diagnostic='uninitialized')
add('dummy_scalar_section_alias',prog('integer :: aa(3,3)', '''aa=2
print *,111
call work(aa(1:3:2,1:3:2),aa(3,3))''','''subroutine work(xx,yy)
integer,intent(inout)::xx(:,:)
integer,intent(in)::yy
print *,222
xx=yy
end subroutine'''),[111],category='runtime',baseline='skip',diagnostic='overlapping')

for name,element,section in [('nonmonotone_minmax','3,3','1:3:2,3:1:-1'),('nonaffine_residue','1,2','1:3:2,1:2')]:
    add('alias_'+name,prog('integer :: aa(3,3)',f'aa=2\nprint *,111\ncall work(aa({element}),aa({section}))',"""subroutine work(xx,yy)
integer,intent(inout)::xx
integer,intent(in)::yy(:,:)
print *,222
xx=1
end subroutine"""),[111],category='runtime',baseline='skip',diagnostic='overlapping')

add('dynamic_descriptors_refresh_each_loop',prog('integer :: aa(4,4),ii,jj,kk',"""aa=0
do kk=1,4
aa(1:kk,kk)=kk
aa(kk,4:1:-1)=aa(kk,4:1:-1)+10
print *,aa(kk,:),size(aa(1:kk,kk))
end do
print *,aa"""),[11,10,10,10,1,10,12,10,10,2,10,10,13,10,3,10,10,10,14,4,11,10,10,10,2,12,10,10,3,3,13,10,4,4,4,14])
add('extreme_runtime_strides',prog('integer :: aa(-2:3,4:8),i,j,ss,tt',initialize()+"""ss=2147483647
tt=-2147483647-1
print *,aa(-2:3:ss,4:8:ss),aa(3:-2:tt,8:4:tt)
print *,size(aa(::tt,:)),size(aa(:,::tt))"""),[398,803,0,0])
add('matrix_bound_expressions_freeze',prog('integer :: aa(3,3)',"""aa=3
aa(1,1)=2
aa(2,1)=1
aa(aa(2,1):aa(1,1),aa(2,1):aa(1,1))=9
print *,aa"""),[9,9,3,9,9,3,3,3,3])

# Static rejection: rank/type/subscript shape, writable actuals and unsupported forms.
invalid=[
 ('real_scalar_subscript','integer :: aa(3,3)','print *,aa(1.0,:)'),
 ('real_triplet_lower','integer :: aa(3,3)','print *,aa(1.0:2,:)'),
 ('real_triplet_stride_second','integer :: aa(3,3)','print *,aa(:,1:2:1.0)'),
 ('logical_triplet_upper','integer :: aa(3,3)','print *,aa(:,1:.true.)'),
 ('array_triplet_bound','integer :: aa(3,3),ii(2)','print *,aa(:,1:ii)'),
 ('rank_mismatch_assign','integer :: aa(3,3),bb(3,1)','aa(1,:)=bb'),
 ('rank_mismatch_expression','integer :: aa(3,3)','print *,aa(1,:)+aa(:,:)'),
 ('rank_mismatch_intrinsic','integer :: aa(3,3)','print *,max(aa(1,:),aa(:,:))'),
 ('too_many_subscripts','integer :: aa(3,3)','print *,aa(:,:,1)'),
 ('too_few_subscripts','integer :: aa(3,3)','print *,aa(:)'),
 ('scalar_section','integer :: aa','print *,aa(:,:)'),
 ('malformed_three_colons','integer :: aa(3,3)','print *,aa(1:::2,:)'),
]
for name,decl,body in invalid: add(name,prog(decl,'print *,999\n'+body),category='invalid')
add('unsupported_vector_subscript',prog('integer :: aa(3,3),ii(2)', 'print *,999\nprint *,aa(ii,:)'),'999',category='runtime',diagnostic='uninitialized array element ii')
for name,actual,decl in [('dummy_rankone_to_ranktwo','aa(1,:)','integer,intent(in)::xx(:,:)'),('dummy_ranktwo_to_rankone','aa(:,:)','integer,intent(in)::xx(:)'),('dummy_real_kind_mismatch','real(aa(:,:))','real(8),intent(in)::xx(:,:)')]:
    add(name,prog('integer :: aa(3,3)',f'print *,999\ncall work({actual})',f'subroutine work(xx)\n{decl}\nend subroutine'),category='invalid')
for name,actual in [('dummy_parenthesized_writable','(aa(:,:))'),('dummy_expression_writable','aa(:,:)+1')]:
    add(name,prog('integer :: aa(3,3)',f'print *,999\ncall work({actual})','''subroutine work(xx)
integer,intent(inout)::xx(:,:)
xx=1
end subroutine'''),category='invalid')
add('dummy_intent_in_section_write',prog('integer :: aa(3,3)','print *,999\ncall outer(aa)','''subroutine outer(xx)
integer,intent(in)::xx(:,:)
xx(:,1)=2
end subroutine'''),category='invalid')
add('dummy_intent_in_section_forward',prog('integer :: aa(3,3)','print *,999\ncall outer(aa)','''subroutine outer(xx)
integer,intent(in)::xx(:,:)
call inner(xx(:,1:2))
end subroutine
subroutine inner(yy)
integer,intent(out)::yy(:,:)
yy=2
end subroutine'''),category='invalid')

(ROOT/'manifest.json').write_text(json.dumps({'description':__doc__,'cases':CASES},indent=2)+'\n')
print(f'Generated {len(CASES)} cases')
