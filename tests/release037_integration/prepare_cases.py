#!/usr/bin/env python3
"""Generate independent 0.37 composed fixtures; retained bodies are byte exact."""
from pathlib import Path
import hashlib,json,textwrap
ROOT=Path(__file__).resolve().parent
CASES=ROOT/'cases';CASES.mkdir(exist_ok=True)
(ROOT/'original').mkdir(exist_ok=True)
cases=[]
def digest(b):return hashlib.sha256(b).hexdigest()
def add(name,source,expected='',category='success',baseline=None,**kw):
 data=textwrap.dedent(source).lstrip().encode() if isinstance(source,str) else source
 (CASES/(name+'.f90')).write_bytes(data)
 cases.append(dict(name=name,source='cases/'+name+'.f90',category=category,
  baseline=baseline or ('run' if category=='success' else 'compile'),expected_stdout=expected,
  compare_mode=kw.pop('compare_mode','exact'),**kw))
def program(decl,body):return 'program main\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
add('gather_roundtrip_ascii',program('real(8)::a(3,2),b(3,2),c(3,2)\ninteger::e(3,2)\ncharacter(1)::letters(3)', '''a=reshape([-8d0,0.5d0,3d0,16d0,-0.25d0,0d0],[3,2])
b=a([3,1,3],:)
e=exponent(b)
c=set_exponent(fraction(b),e)
letters=['A','z','0']
write(*,'("roundtrip:",4(1x,i0))')count(c==b),count(isnan(c)),count(spacing(c)>0d0),count(nearest(c,1d0)>c)
write(*,'("exponents:",6(1x,i0))')e
write(*,'("ascii:",5(1x,i0))')iachar(letters,kind=8),kind(iachar('A',8)),count(parity(b>0d0,dim=1))'''),
'roundtrip: 6 0 6 6\nexponents: 2 4 2 0 5 0\nascii: 65 122 48 8 1\n',gnu_extension='isnan')
for kind,powmin,expsub,digits in [(4,-126,-148,23),(8,-1022,-1073,52)]:
 suf='_4' if kind==4 else '_8'
 real=lambda s:s+suf
 add('binary_edges_real'+str(kind),program(f'real({kind})::t,u,z,n,h\ninteger::e',f'''t=tiny({real('0.0')})
u=t*epsilon(t)
z=-{real('0.0')}
n=nearest(z,{real('1.0')})
h=huge(t)
e=exponent(u)
write(*,'("subnormal:",6(1x,i0))')e,merge(1,0,fraction(u)=={real('0.5')}), &
merge(1,0,set_exponent({real('0.5')},{expsub})==u),merge(1,0,spacing(u)==t), &
merge(1,0,n==u),merge(1,0,nearest({real('0.0')},-{real('1.0')})==-u)
write(*,'("zero:",5(1x,i0))')int(sign({real('1.0')},fraction(z))),exponent(z), &
int(sign({real('1.0')},set_exponent(z,huge(0_8)))), &
int(sign({real('1.0')},nearest(-u,{real('1.0')}))),int(sign({real('1.0')},nearest(u,-{real('1.0')})))
write(*,'("normal:",6(1x,i0))')merge(1,0,nearest(t,-{real('1.0')})==t-u), &
merge(1,0,spacing(t)==t),merge(1,0,set_exponent(fraction(h),exponent(h))==h), &
merge(1,0,nearest(h,-{real('1.0')})<h),merge(1,0,spacing(h)=={real('2.0')}**{(127 if kind==4 else 1023)-digits}), &
merge(1,0,u>0)
print *,u,spacing(h)'''),f'subnormal: {expsub} 1 1 1 1 1 zero: -1 0 -1 -1 1 normal: 1 1 1 1 1 1 '+
 ('1.401298464324817070923729583289916131280e-45 2.0282409603651670423947251286016e31' if kind==4 else
 '4.940656458412465441765687928682213723651e-324 1.995840309534719811656372713036838566067e292'),compare_mode='tokens')
add('mixed_direction_keyword',program('real(4)::x\nreal(8)::s\nreal(8)::a(2)\ninteger(8)::e(2)', '''x=1.0
s=tiny(0d0)*epsilon(0d0)
a=[1d0,-8d0]
e=[2_8,-2_8]
write(*,'("mixed:",4(1x,i0))')merge(1,0,nearest(s=s,x=x)>x),kind(nearest(s=s,x=x)), &
merge(1,0,nearest(x=x,s=-s)<x),kind(nearest(x=s,s=x))
write(*,'("keywords:",6(1x,i0))')int(set_exponent(i=e,x=a)*8d0),exponent(x=a), &
kind(fraction(x=a)),kind(iachar(kind=8,c='Q'))'''),
'mixed: 1 4 1 8\nkeywords: 16 -1 1 4 8 8\n')
add('wide_exponent_signed_underflow',program('real(8)::x(2),y(2)\ninteger(8)::n', '''x=[1d0,-1d0]
n=-huge(0_8)
y=set_exponent(x,n)
write(*,'("wide:",5(1x,i0))')int(sign(1d0,y)),count(y==0d0), &
int(sign(1d0,set_exponent(-0d0,huge(0_8)))),kind(exponent(y))'''),
'wide: 1 -1 2 -1 4\n',baseline='compile',compiler_discrepancy='GNU 14.2 returns nonzero SET_EXPONENT for I=-HUGE(0_8). The bounded interpreter contract returns signed zero without narrowing the exponent. This case has an independent signed-zero oracle, not a GNU runtime equivalence claim.',scope_note='Extreme INTEGER8 exponent policy independently tested; GNU compiles only.')
add('ascii_exact_records',program('character(3)::s\ncharacter(1)::a(4)\ninteger(8)::v(4)', '''s='Az0'
a(1)=s(1:1)
a(2)=s(2:2)
a(3)=achar(0)
a(4)=achar(127)
v=iachar(c=a,kind=8)
write(*,'("codes:",4(1x,i0))')v
write(*,'("text:[",a,"]",1x,i0)')achar(iachar(s(1:1))),iachar(s(3:3))'''),
'codes: 65 122 0 127\ntext:[A] 48\n')
add('empty_rank3_composition',program('real(8)::a(0,2,3),b(0,2,3),s\ninteger::e(0,2,3)\ncharacter(1)::c(0,2,3)\nlogical::mask(0,2,3)', '''s=0d0
b=nearest(set_exponent(fraction(a),huge(0_8)),s)
e=exponent(spacing(b))
mask=isnan(b)
write(*,'("empty:",8(1x,i0))')size(b,1),size(b,2),size(b,3),size(e),size(iachar(c,8)),count(mask(:,:,1)),sum(e(:,:,1)),kind(b)'''),
'empty: 0 2 3 0 0 0 0 8\n',gnu_extension='isnan')
add('rank3_elemental_masks',program('real(8)::a(2,1,2),b(2,1,2)\ninteger::e(2,1,2),codes(2,1,2)\ncharacter(1)::c(2,1,2)\nlogical::mask(2,1,2)', '''a(:,1,1)=[1d0,2d0]
a(:,1,2)=[4d0,8d0]
e=exponent(a)
b=set_exponent(fraction(a),e)
c(:,1,1)=['A','B']
c(:,1,2)=['C','D']
codes=iachar(c)
mask=isnan(nearest(a,1d0))
write(*,'("rank3:",7(1x,i0))')size(b,1),size(b,2),size(b,3),count(b(:,:,1)==a(:,:,1))+count(b(:,:,2)==a(:,:,2)), &
sum(e(:,:,1))+sum(e(:,:,2)),sum(codes(:,:,1))+sum(codes(:,:,2)),count(mask(:,:,1))+count(mask(:,:,2))'''),
'rank3: 2 1 2 4 10 266 0\n',gnu_extension='isnan')
add('optional_allocatable_composition','''module transform
implicit none
contains
function convert(x,direction) result(y)
real(8),intent(in)::x(:,:)
real(8),optional,intent(in)::direction
real(8)::y(size(x,1),size(x,2))
y=set_exponent(fraction(x),exponent(x))
if(present(direction))y=nearest(y,direction)
end function
end module
program main
use transform
implicit none
real(8),allocatable::a(:,:)
a=reshape([1d0,2d0,4d0,8d0],[2,2])
a=convert((a([2,1],:)))
write(*,'("optional:",7(1x,i0))')shape(a),int(a),kind(a)
a=convert(a,direction=-1d0)
write(*,'("next:",2(1x,i0))')count(a<reshape([2d0,1d0,8d0,4d0],[2,2])),count(spacing(a)>0d0)
end program
''','optional: 2 2 2 1 8 4 8\nnext: 4 4\n')
add('metadata_no_evaluation','''program main
implicit none
real(8),allocatable::a(:,:)
real(8)::s
integer::idx(2)
s=0d0
write(*,'("meta:",7(1x,i0))')kind(fraction(a(idx,:))),kind(exponent(a)), &
kind(set_exponent(a,huge(0_8))),kind(spacing(a)),kind(nearest(a,s)),kind(isnan(a)),kind(iachar('A',8))
write(*,'("status:",1x,i0)')merge(1,0,allocated(a))
end program
''','meta: 8 4 8 8 8 4 8\nstatus: 0\n',baseline='compile',gnu_extension='isnan',scope_note='Descriptor-only KIND contract; GNU compilation only, never execute undefined/unallocated metadata probes.')
# Every negative runtime record has an independently fixed completed prefix.
for name,decl,init,expr,diag in [
 ('nearest_zero_direction','real(8)::x,s','x=1d0\ns=-0d0','nearest(x,s)','nonzero'),
 ('nearest_outward_overflow','real(4)::x','x=huge(0.0)','nearest(x,1.0)','finite REAL range'),
 ('set_exponent_wide_overflow','real(8)::x\ninteger(8)::i','x=1d0\ni=huge(0_8)','set_exponent(x,i)','overflow'),
 ('fraction_undefined','real(8)::x','','fraction(x)','uninitialized'),
 ('exponent_undefined','real(8)::x','','exponent(x)','uninitialized'),
 ('spacing_undefined_array','real(8)::x(2)','x(1)=1d0','sum(spacing(x))','uninitialized'),
 ('isnan_undefined_after_finite','real(8)::x(2)','x(1)=1d0','count(isnan(x))','uninitialized'),
 ('isnan_nonfinite_policy','real(8)::x','x=huge(0d0)','count([isnan(x*2d0)])','non-finite'),
]:
 add(name,program(decl,init+'\nwrite(*,\'(a)\')"before"\nprint *,7,'+expr),category='runtime',diagnostic=diag,
  completed_stdout='before\n',**({'gnu_extension':'isnan'} if 'isnan' in name else {}))
add('iachar_nonascii',b"program main\nimplicit none\ncharacter(1)::c\nc='\x80'\nwrite(*,'(a)')'before'\nprint *,7,iachar(c)\nend program\n",category='runtime',diagnostic='ASCII',completed_stdout='before\n',scope_note='Single high-byte literal tests IACHAR ASCII policy directly, without failing earlier in CHAR/ACHAR.')
add('iachar_dynamic_nonunit','''module strings
implicit none
contains
subroutine code(c)
character(*),intent(in)::c
write(*,'(a)')'before'
print *,7,iachar(c)
end subroutine
end module
program main
use strings
call code('AB')
end program
''',category='runtime',diagnostic='length',completed_stdout='before\n')
# Invalid sources must fail cleanly under GNU as well; no runtime oracle is used.
for name,decl,expr,diag in [
 ('fraction_integer_boundary','integer::x','fraction(x)','real'),
 ('set_exponent_real_power_boundary','real::x','set_exponent(x,1.0)','integer'),
 ('nearest_integer_direction_boundary','real::x','nearest(x,1)','real'),
 ('iachar_length_boundary','character(2)::c','iachar(c)','length'),
 ('iachar_kind_boundary','character(1)::c','iachar(c,3)','kind'),
 ('isnan_integer_boundary','integer::x','isnan(x)','real'),
]:
 add(name,program(decl,'print *,'+expr),category='reject',baseline='reject',diagnostic=diag,
  **({'gnu_extension':'isnan'} if 'isnan' in name else {}))
# Preserve every original body/dependency, with synthetic module and DP only.
original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
original_hash='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
assert digest(original)==original_hash
specs=[('ran_uni_vec',510,514),('runif_vec',2651,2658),('random_logical_vec',6192,6200),
 ('random_logical_matrix',6202,6210),('random_logical_3d',6212,6220),('random_matrix',7847,7851),('quick_sort',8870,8942)]
lines=original.splitlines(keepends=True)
wrapper=b'module original_utilities\nimplicit none\ninteger,parameter::dp=kind(0d0)\ncontains\n'
routines=[]
for name,first,last in specs:
 body=b''.join(lines[first-1:last]);start=sum(map(len,lines[:first-1]))
 routines.append(dict(name=name,source_start_line=first,source_end_line=last,source_byte_start=start,
  source_byte_end_exclusive=start+len(body),wrapper_byte_start=len(wrapper),sha256=digest(body),bytes=len(body),crlf_lines=body.count(b'\r\n')))
 wrapper+=body+b'\n'
wrapper+=b'end module\n';(ROOT/'original/utility_module.f90').write_bytes(wrapper)
provenance=dict(original_source='../utilities_slices/source/xutilities.f90',original_source_sha256=original_hash,
 wrappers=[dict(path='original/utility_module.f90',sha256=digest(wrapper),routines=routines)],originals=[])
original_support=dict(support_sources=['original/utility_module.f90'],gnu_extension='isnan')
add('original_rng_all_six','''program main
use original_utilities
implicit none
real(dp)::x(7),y(4),z(4),m(2,3)
logical::v(5),b(2,3),c(2,1,3)
x=ran_uni_vec(7)
y=runif_vec(4)
z=runif_vec(4,2d0)
m=random_matrix(2,3)
v=random_logical_vec(5,0d0)
b=random_logical_matrix(2,3,2d0)
c=random_logical_3d(2,1,3,0d0)
write(*,'("ranges:",5(1x,i0))')count(x>=0d0.and.x<1d0),count(y>=0d0.and.y<1d0), &
count(z>=1.5d0.and.z<=2.5d0),count(m>=0d0.and.m<1d0),count(isnan(m))
write(*,'("logical:",6(1x,i0))')count(v),count(b),count(c(:,:,1))+count(c(:,:,2))+count(c(:,:,3)),size(c,1),size(c,2),size(c,3)
write(*,'("models:",4(1x,i0))')count(set_exponent(fraction(x),exponent(x))==x), &
count(spacing(m)>0d0),count(nearest(m,1d0)>m),kind(m)
end program
''','ranges: 7 4 4 6 0\nlogical: 0 6 0 2 1 3\nmodels: 7 6 6 8\n',**original_support)
add('original_rng_empty_shapes','''program main
use original_utilities
implicit none
real(dp)::x(0),a(0,3)
logical::v(0),m(2,0),b(1,0,3)
x=ran_uni_vec(0)
x=runif_vec(0,2d0)
a=random_matrix(0,3)
v=random_logical_vec(0,2d0)
m=random_logical_matrix(2,0,0d0)
b=random_logical_3d(1,0,3,2d0)
write(*,'("empty_rng:",10(1x,i0))')size(x),shape(a),size(v),shape(m),shape(b),count(isnan(a))
end program
''','empty_rng: 0 0 3 0 2 0 1 0 3 0\n',**original_support)
add('original_sort_rng_composition','''program main
use original_utilities
implicit none
real(dp)::x(11),original(11)
integer::order(11),i,matches
original=runif_vec(11)
x=set_exponent(fraction(original),exponent(original))
call quick_sort(x,order)
matches=0
do i=1,size(x)
if(x(i)==original(order(i)))matches=matches+1
end do
write(*,'("sort_rng:",5(1x,i0))')count(x>=0d0.and.x<1d0),count(x(2:)>=x(:10)), &
matches,count(isnan(x)),count(nearest(x,1d0)>x)
end program
''','sort_rng: 11 10 11 0 11\n',**original_support)
add('original_sort_known_edges','''program main
use original_utilities
implicit none
real(dp)::x(9),original(9),empty(0),one(1),u
integer::order(9),eo(0),oo(1),i,matches,signs
u=tiny(0d0)*epsilon(0d0)
original=[3d0,-0d0,2d0,-u,-4d0,0d0,u,3d0,1d0]
x=set_exponent(fraction(original),exponent(original))
call quick_sort(x,order)
call quick_sort(empty,eo)
one=-0d0
call quick_sort(one,oo)
matches=0
signs=0
do i=1,size(x)
if(x(i)==original(order(i)))matches=matches+1
if(sign(1d0,x(i))==sign(1d0,original(order(i))))signs=signs+1
end do
write(*,'("sort:",5(1x,i0))')count(x(2:)>=x(:8)),matches,count(isnan(x)),sum(order),signs
write(*,'("edges:",6(1x,i0))')merge(1,0,x(1)==-4d0),merge(1,0,x(2)==-u), &
merge(1,0,x(5)==u),size(eo),oo,int(sign(1d0,one))
end program
''','sort: 8 9 0 45 9\nedges: 1 1 1 0 1 -1\n',**original_support)
# Existing purity/effect policy must stay closed around the new RNG allowance.
for name,body,diag,baseline in [
 ('pure_rng_boundary','pure function draw() result(x)\nreal::x\ncall random_number(x)\nend function','pure','reject'),
 ('ordinary_io_boundary','function draw() result(x)\nreal::x\nprint *,1\nx=0.0\nend function','function','run'),
]:
 add(name,'program main\nimplicit none\nreal::x\nx=draw()\ncontains\n'+body+'\nend program\n',category='reject',baseline=baseline,
  diagnostic=diag,**({'gnu_stdout':'           1\n'} if baseline=='run' else {}))
add('ordinary_module_write_boundary','''module state
implicit none
integer::counter=0
contains
function draw() result(x)
real::x
counter=counter+1
call random_number(x)
end function
end module
program main
use state
implicit none
real::x
x=draw()
write(*,'(i0)')counter
end program
''',category='reject',baseline='run',diagnostic='function',gnu_stdout='1\n')
# Original upstream programs are copied by the importer then replayed from local pins.
index=ROOT/'original-program-inputs.json'
if index.exists():
 for item in json.loads(index.read_text()):
  data=(ROOT/item['path']).read_bytes();assert digest(data)==item['sha256']
  provenance['originals'].append({k:v for k,v in item.items() if k!='oracle'})
  cases.append(dict(name='unchanged_'+Path(item['path']).stem,source=item['path'],category='success',baseline='run',
   expected_stdout=item['oracle'],compare_mode='tokens',**original_support))
 license_data=(ROOT/'original/M_INTRINSICS_LICENSE').read_bytes()
 provenance['license']=dict(path='original/M_INTRINSICS_LICENSE',sha256=digest(license_data))
(ROOT/'original-source-map.json').write_text(json.dumps(provenance,indent=2)+'\n')
(ROOT/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')

# A safe standalone GNU discrepancy reproducer, not part of candidate pass counts.
(ROOT/'oracle-limitations').mkdir(exist_ok=True)
(ROOT/'oracle-limitations/gnu_set_exponent_wide.f90').write_text("""program probe
implicit none
integer(8)::i
real(8)::x(2),y(2)
i=-huge(0_8)
x=[1d0,-1d0]
y=set_exponent(x,i)
write(*,'(i0,2(1x,es24.16))')i,y
end program
""")
