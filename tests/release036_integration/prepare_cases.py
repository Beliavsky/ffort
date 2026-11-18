#!/usr/bin/env python3
"""Generate fresh 0.36 composition fixtures and byte-exact original closures."""
from pathlib import Path
import hashlib,json,math,textwrap
ROOT=Path(__file__).resolve().parent
CASES=ROOT/'cases';CASES.mkdir(exist_ok=True)
(ROOT/'original').mkdir(exist_ok=True)
cases=[]
def digest(data): return hashlib.sha256(data).hexdigest()
def add(name,source,expected='',category='success',baseline=None,**kw):
    data=textwrap.dedent(source).lstrip().encode() if isinstance(source,str) else source
    (CASES/(name+'.f90')).write_bytes(data)
    cases.append(dict(name=name,source='cases/'+name+'.f90',category=category,
        baseline=baseline or ('run' if category=='success' else 'compile'),
        expected_stdout=expected,compare_mode=kw.pop('compare_mode','exact'),**kw))
def program(decl,body):return 'program main\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
add('gather_elemental_reduction',program('integer(8)::a(3,2),b(3,2)\nlogical::m(3,2)', '''a=reshape([-4_8,0_8,3_8,2_8,-1_8,7_8],[3,2])
b=dim(a([3,1,3],:),0_8)
m=b>0_8
write(*,'("rows:",6(1x,i0))')b
write(*,'("reduce:",4(1x,i0))')sum(b),count(m),merge(1,0,parity(m)),count(parity(m,dim=2))
write(*,'("kinds:",4(1x,i0))')kind(b),kind(dim(b,0_8)),radix(b),kind(huge(b))'''),
'rows: 3 0 3 7 2 7\nreduce: 22 5 1 1\nkinds: 8 8 2 8\n')
add('reallocate_snapshot_models', '''module snapshots
implicit none
contains
subroutine replace_rows(x,y)
real(8),intent(in)::x(:,:)
real(8),allocatable,intent(out)::y(:,:)
allocate(y(size(x,1),size(x,2)))
y=sign(dim(x,0d0),-1d0)
end subroutine
end module
program main
use snapshots
implicit none
real(8),allocatable::a(:,:)
integer::idx(3)
allocate(a(-1:1,2))
a=reshape([1d0,-2d0,3d0,4d0,5d0,6d0],[3,2])
idx=[1,-1,1]
call replace_rows((a(idx,:)),a)
write(*,'("snapshot:",8(1x,i0))')shape(a),int(a)
a=a([2,1],:)
write(*,'("again:",6(1x,i0))')shape(a),int(a)
write(*,'("model:",3(1x,i0))')kind(tiny(a)),radix(a),count(parity(a<0d0,dim=1))
end program
''','snapshot: 3 2 -3 -1 -3 -6 -4 -6\nagain: 2 2 -1 -3 -4 -6\nmodel: 8 2 0\n')
add('gather_function_snapshot_once','''module selection
implicit none
integer::calls=0
contains
impure elemental function pick(i) result(idx)
integer,intent(in)::i
integer::idx
calls=calls+1
idx=i
end function
end module
program main
use selection
implicit none
integer::a(3,2),b(2,2)
a=reshape([1,2,3,4,5,6],[3,2])
b=dim(a(pick([3,1]),:),0)
write(*,'("first:",5(1x,i0))')calls,b
b=sign(a(pick([2,2]),:),-1)
write(*,'("second:",5(1x,i0))')calls,b
write(*,'("reduced:",2(1x,i0))')merge(1,0,parity(b<0)),radix(b)
end program
''','first: 2 3 1 6 4\nsecond: 4 -2 -2 -5 -5\nreduced: 0 2\n')
add('model_function_not_executed','''module models
implicit none
integer::calls=0
contains
impure elemental function touch() result(x)
real(8)::x
calls=calls+1
x=3d0
end function
end module
program main
use models
implicit none
real(8)::a(2,2)
a=1d0
write(*,'("metadata:",5(1x,i0))')radix(touch()),kind(epsilon(touch())), &
kind(tiny(sign(touch(),-1d0))),kind(huge(log_gamma(touch()))),calls
write(*,'("array:",3(1x,i0))')kind(epsilon(dim(a([2,1],:),0d0))),radix(a),calls
end program
''','metadata: 2 8 8 8 0\narray: 8 2 0\n')
add('gamma_gather_float_kinds',program('real(8)::a(3,2)\nreal(4)::s(2)', '''a=reshape([1d0,2d0,3d0,4d0,5d0,6d0],[3,2])
s=sign([0.0,2.0],[-0.0,0.0])
print *,log_gamma(a([3,1],:))
write(*,'("zero:",4(1x,i0))')int(sign(1.0,s)),kind(s),kind(log_gamma(a))'''),
'0.6931471805599453 0.0 4.787491742782046 1.791759469228055 zero: -1 1 4 8',compare_mode='tokens')
add('empty_gather_masks',program('real(8)::a(2,3),z(0,3)\ninteger::rows(0)\nlogical::m(0,3)', '''a=1d0
z=dim(a(rows,:),epsilon(a))
m=z>tiny(z)
write(*,'("empty:",6(1x,i0))')shape(z),count(m),count(parity(m,dim=1)),size(parity(m,dim=2)),merge(1,0,parity(m))
write(*,'("models:",4(1x,i0))')kind(epsilon(z)),radix(z),kind(tiny(z)),kind(huge(z))'''),
'empty: 0 3 0 0 0 0\nmodels: 8 2 8 8\n')
add('model_without_values', '''module unevaluated
implicit none
integer::calls=0
contains
impure elemental function boom() result(x)
real(8)::x
calls=calls+1
x=0d0
x=log_gamma(x)
end function
subroutine optional_model(x)
real(8),optional,intent(in)::x(:,:)
write(*,'("optional:",4(1x,i0))')kind(epsilon(x)),radix(x),kind(tiny(x)),kind(huge(x))
end subroutine
end module
program main
use unevaluated
implicit none
real(8),allocatable::a(:,:)
integer::indices(2)
write(*,'("unallocated:",4(1x,i0))')kind(epsilon(a(indices,:))),radix(a(indices,:)),kind(tiny(a)),kind(huge(a))
write(*,'("unevaluated:",3(1x,i0))')radix(boom()),kind(epsilon(log_gamma(a))),calls
call optional_model()
write(*,'("status:",1x,i0)')merge(1,0,allocated(a))
end program
''','unallocated: 8 2 8 8\nunevaluated: 2 8 0\noptional: 8 2 8 8\nstatus: 0\n',baseline='compile',scope_note='Candidate descriptor-only inquiry contract; GNU compiles but undefined indices, unallocated and absent operands are not executed as GNU safety probes.')
add('tiny_epsilon_huge_exact',program('real(8)::x\ninteger(8)::i', '''write(*,'("binary:",6(1x,i0))') &
merge(1,0,epsilon(x)==2d0**(-52)),merge(1,0,tiny(x)==2d0**(-1022)), &
merge(1,0,huge(x)==(2d0-2d0**(-52))*2d0**1023),radix(x),radix(i),kind(huge(i))
print *,epsilon(x),tiny(x),huge(x),huge(i)'''),
'binary: 1 1 1 2 2 8 2.220446049250313e-16 2.2250738585072014e-308 1.7976931348623157e308 9223372036854775807',compare_mode='tokens')
add('integer8_edge_composition',program('integer(8)::lo,hi,a(2,2)', '''hi=huge(0_8)
lo=-hi-1_8
a=reshape([lo,hi,-1_8,0_8],[2,2])
write(*,'("edges:",4(1x,i0))')sign(lo,-1_8),dim(hi,hi),dim(lo,0_8),dim(hi,0_8)
write(*,'("gather:",4(1x,i0))')sign(a([2,1],:),-1_8)'''),
'edges: -9223372036854775808 0 0 9223372036854775807\ngather: -9223372036854775807 -9223372036854775808 0 -1\n')
add('gnu_dim_wrapped_negative_difference',program('integer(8)::lo,hi','hi=huge(0_8)\nlo=-hi\nwrite(*,\'(i0)\')dim(lo,hi)'),
'0\n',baseline='compile',compiler_discrepancy='GNU 14.2 emits 2 for DIM(-HUGE(0_8),HUGE(0_8)) consistent with subtraction wrapping before max. The independent mathematical result is zero. This probe is compiled, not executed or called GNU-equivalent.',scope_note='Overflow-avoiding DIM contract independently checked against zero; no GNU runtime equivalence claimed.')
add('array_models_specification', '''module spec
implicit none
contains
subroutine calculate(a)
real(8),intent(in)::a(:,:)
integer::work(radix(a)+kind(tiny(a)))
work=1
write(*,'("spec:",3(1x,i0))')size(work),sum(work),kind(epsilon(log_gamma(a)))
end subroutine
end module
program main
use spec
implicit none
real(8)::a(0,3)
integer::idx(0)
call calculate((a(idx,:)))
end program
''','spec: 10 10 8\n')
# Candidate runtime policy failures compile with GNU; never execute these probes there.
for name,decl,init,expr,diag in [
('dim_integer_overflow','integer(8)::x','x=huge(0_8)','dim(x,-1_8)','integer overflow'),
('sign_integer_overflow','integer(8)::x','x=-huge(0_8)\nx=x-1_8','sign(x,1_8)','integer overflow'),
('gamma_pole','real(8)::x','x=-2d0','log_gamma(x)','must not be zero or a negative integer'),
('gamma_finite_policy','real(8)::x','x=huge(0d0)','log_gamma(x)','non-finite'),
('gather_bad_row','integer::a(2,2),idx(2)','a=1\nidx=[2,3]','sum(dim(a(idx,:),0))','bound'),
('gather_undefined_index','integer::a(2,2),idx(2)','a=1','sum(dim(a(idx,:),0))','uninitialized'),
('parity_undefined_after_true','logical::m(3)','m(1)=.true.','merge(1,0,parity(m))','uninitialized'),
]:
 fmt='(i0,1x,es24.16)' if decl.startswith('real') else '(2(i0,1x))'
 add(name,program(decl,init+'\nwrite(*,\'(a)\')"before"\nwrite(*,\''+fmt+'\')7,'+expr),category='runtime',diagnostic=diag,completed_stdout='before\n')
add('empty_column_bad_index',program('integer::a(2,0),idx(1)','idx=[3]\nwrite(*,\'(a)\')"before"\nwrite(*,\'(i0)\')size(a(idx,:))'),
category='runtime',diagnostic='bound',completed_stdout='before\n')
# Explicit standard-valid GNU-only subset boundaries, with separately fixed GNU answers.
add('parity_rank3_boundary',program('logical::x(1,1,1)','x=.true.\nwrite(*,\'(i0)\')merge(1,0,parity(x))'),
category='reject',baseline='run',diagnostic='rank',gnu_stdout='1\n')
add('numeric_component_boundary', '''module types
implicit none
type :: item
real(8)::x
end type
end module
program main
use types
implicit none
type(item)::a
write(*,'(i0)')radix(dim(sign(a%x,-1d0),0d0))
end program
''',category='reject',baseline='run',diagnostic='component',gnu_stdout='2\n')
add('gather_scatter_boundary',program('integer::a(2,2)','a=1\na([2,1],:)=2\nwrite(*,\'(i0)\')sum(a)'),
category='reject',baseline='run',diagnostic='vector',gnu_stdout='8\n')
add('gather_writable_actual_boundary','''program main
implicit none
integer::a(2,2)
a=1
call change((a([2,1],:)))
contains
subroutine change(x)
integer,intent(inout)::x(:,:)
x=2
end subroutine
end program
''',category='reject',baseline='reject',diagnostic='gathered row value')
add('mismatched_kind_boundary',program('integer(8)::x','x=1_8\nprint *,dim(x,0)'),category='reject',baseline='reject',diagnostic='matching types')
# Preserve the exact utility dependency closure, including CRLF bytes.
original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
original_hash='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
assert digest(original)==original_hash
specs=[('filter_matrix_rows',8657,8679,'2988489e747a2cdc7f9045e0deae9af543a6121642d9a70632cc66a0a2969473'),
('true_pos_func',1552,1564,'b3d307baf5b780746d191aedf2080a17d2ba353b2013b310ef07f82d63c2582b'),
('set_alloc_real_matrix',2610,2616,'8f3d6e5bf4905c86ab26bfd09a8c2e3684823e524eaf2fccb6bad291f06f68b4')]
lines=original.splitlines(keepends=True)
wrapper=b'module original_filter\nimplicit none\ninteger,parameter::dp=kind(1d0)\ninterface true_pos\nmodule procedure true_pos_func\nend interface\ninterface set_alloc\nmodule procedure set_alloc_real_matrix\nend interface\ncontains\n'
routines=[]
for name,first,last,sha in specs:
 body=b''.join(lines[first-1:last]);start=sum(map(len,lines[:first-1]));assert digest(body)==sha
 routines.append(dict(name=name,source_start_line=first,source_end_line=last,source_byte_start=start,
  source_byte_end_exclusive=start+len(body),wrapper_byte_start=len(wrapper),sha256=sha,bytes=len(body),crlf_lines=body.count(b'\r\n')))
 wrapper+=body+b'\n'
wrapper+=b'end module\n';(ROOT/'original/filter_module.f90').write_bytes(wrapper)
provenance=dict(original_source='../utilities_slices/source/xutilities.f90',original_source_sha256=original_hash,
 wrappers=[dict(path='original/filter_module.f90',sha256=digest(wrapper),routines=routines)],originals=[])
add('original_filter_cross_features','''program main
use original_filter
implicit none
real(dp),allocatable::a(:,:)
allocate(a(4,2))
a=reshape([1d0,2d0,3d0,4d0,10d0,20d0,30d0,40d0],[4,2])
call filter_matrix_rows(a,[1,2],[dim(3d0,1d0),sign(1d0,-1d0)],[4d0,30d0])
write(*,'("filtered:",6(1x,i0))')shape(a),int(a)
write(*,'("combined:",4(1x,i0))')count(parity(a>0d0,dim=1)),radix(a),kind(tiny(a)),int(log_gamma(2d0))
call filter_matrix_rows(a,[1],[100d0],[huge(a)])
write(*,'("removed:",4(1x,i0))')shape(a),count(parity(a>0d0,dim=1)),merge(1,0,parity(a>0d0))
call filter_matrix_rows(a,[1],[tiny(a)],[huge(a)])
write(*,'("repeat:",2(1x,i0))')shape(a)
end program
''','filtered: 2 2 2 3 20 30\ncombined: 0 2 8 0\nremoved: 0 2 0 0\nrepeat: 0 2\n',support_sources=['original/filter_module.f90'])
# Unchanged full upstream programs coexist with the untouched utility closure.
# Fixed mathematical/IEEE oracles, never candidate or GNU output as expectations.
originals=[
('../elementary_math/cases/demo_dim.f90','0 3.21 0 0 1 0 0 2 0 0 10'),
('../elementary_math/cases/demo_sign.f90','12 12 -12 12 12 -12 this processor distinguishes +0 from -0 either way, 0==-0 is true! T either way, 0=/-0 is false! F elemental 12 12 -12'),
('../elementary_math/cases/demo_log_gamma.f90','1 0 1 '+str(math.log(2))),
('../parity_intrinsic/demo_parity.f90','T T F T F T T T T F F F'),
('../numeric_model_inquiries/original/demo_radix.f90','The radix for the default integer kind is 2 The radix for the default real kind is 2 The radix for the doubleprecision real kind is 2'),
('../numeric_model_inquiries/original/demo_tiny.f90','default real is from 1.1754943508222875e-38 to 3.4028234663852886e38 doubleprecision is from 2.2250738585072014e-308 to 1.7976931348623157e308'),
('../numeric_model_inquiries/original/demo_floor.f90','63.29 63 -63.59 -64 -3 -3 -3 -2 -2 -1 -1 0 0 1 1 2 2 2 2 2.0 1.9999998807907104 1.999999761581421 2 1 1'),
]
for path,oracle in originals:
 data=(ROOT/path).read_bytes();name=Path(path).stem
 local='original/'+name+'.f90';(ROOT/local).write_bytes(data)
 provenance['originals'].append(dict(path=local,source=path,bytes=len(data),sha256=digest(data),upstream_commit='fc14233036d910e3678d350efc24609e11475067'))
 cases.append(dict(name='unchanged_'+name,source=local,category='success',baseline='run',expected_stdout=oracle,
  compare_mode='tokens',support_sources=['original/filter_module.f90'],scope_note='Full unchanged M_intrinsics program plus exact original utility closure; no program rewrite. Whitespace-insensitive token comparison is limited to upstream list output.'))
license_data=(ROOT.parent/'elementary_math/UPSTREAM-LICENSE').read_bytes()
(ROOT/'original/M_INTRINSICS_LICENSE').write_bytes(license_data)
provenance['license']=dict(path='original/M_INTRINSICS_LICENSE',sha256=digest(license_data))
(ROOT/'original-source-map.json').write_text(json.dumps(provenance,indent=2)+'\n')
(ROOT/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
