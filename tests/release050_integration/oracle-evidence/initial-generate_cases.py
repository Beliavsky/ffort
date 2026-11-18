#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parent
(R/'cases').mkdir(exist_ok=True)
C=[]
def add(name,src,out,features,category='success',gnu='run',note=''):
 src=src.strip()+'\n';p=R/'cases'/(name+'.f90');p.write_bytes(src.encode())
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=out,features=features)
 if category!='success':c.update(diagnostic='PENDING immutable candidate',diagnostic_line=1,diagnostic_column=1)
 if note:c['oracle_note']=note
 C.append(c)
def prog(decl,body,uses=''):
 return 'program p\n'+uses+'\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
def fill(kind=''):
 return 'do k=1,2\ndo j=1,2\ndo i=1,3\na(i,j,k)=100'+kind+'*k+10'+kind+'*j+i\nend do\nend do\nend do'
# All record expectations are independently calculated from the source operations.
add('axis1_masks_rank3_file',prog('integer::a(3,2,2),g(3,2,2),b(3,2,2),i,j,k\ncharacter(4)::s(3,2,2)',fill()+'''
g=a([3,1,3],:,:)
b=shiftr(iand(g,maskr(4)),1)
do k=1,2
do j=1,2
do i=1,3
write(s(i,j,k),'(b4.4)')b(i,j,k)
end do
end do
end do
print '(a)',s'''),''.join(f'{((100*k+10*j+i)&15)>>1:04b}\n' for k in [1,2] for j in [1,2] for i in [3,1,3]),['axis1 duplicate gather','MASKR scalar expansion','SHIFTR rank3','rank3 internal elements'])
add('axis2_wide_mask_records',prog('integer(8)::a(2,3,2),g(2,2,2),b(2,2,2)\ninteger::i,j,k\ncharacter(16)::s(2,2,2)', '''do k=1,2
do j=1,3
do i=1,2
a(i,j,k)=100_8*k+10_8*j+i
end do
end do
end do
g=a(:,[3,1],:)
b=ior(iand(g,maskr(8,kind=8)),maskl(4,kind=8))
do k=1,2
do j=1,2
do i=1,2
write(s(i,j,k),'(z16.16)')b(i,j,k)
end do
end do
end do
print '(a)',s'''),''.join(f'{(0xf<<60)|((100*k+10*j+i)&255):016X}\n' for k in [1,2] for j in [3,1] for i in [1,2]),['axis2 gather','INTEGER8 full-bit payload','MASKL/MASKR','rank3 file'])
add('axis3_nondefault_bounds',prog('integer::a(-1:0,4:5,-1:0),g(2,2,3),i,j,k\ncharacter(3)::s(2,2,3)', '''do k=-1,0
do j=4,5
do i=-1,0
a(i,j,k)=(k+2)*16+(j-4)*4+(i+1)
end do
end do
end do
g=shiftr(a(:,:,[0,-1,0]),1)
do k=1,3
do j=1,2
do i=1,2
write(s(i,j,k),'(i3.3)')g(i,j,k)
end do
end do
end do
print '(a)',s'''),''.join(f'{((k+2)*16+(j-4)*4+(i+1))>>1:03d}\n' for k in [0,-1,0] for j in [4,5] for i in [-1,0]),['axis3 nondefault bounds','repeated selection','SHIFTR','rank3 file'])
add('self_reallocation_snapshot',prog('integer,allocatable::a(:,:,:)\ninteger::i,j,k\ncharacter(4)::s(4)', '''allocate(a(2,2,3))
do k=1,3
do j=1,2
do i=1,2
a(i,j,k)=100*k+10*j+i
end do
end do
end do
a=a(:,:,[3,1,3,2])
if(size(a,3)/=4)error stop 'extent'
do k=1,4
write(s(k),'(z4.4)')iand(a(1,1,k),maskr(8))
end do
print '(a)',s'''),''.join(f'{(100*k+11)&255:04X}\n' for k in [3,1,3,2]),['gather alias snapshot','allocatable rank3 resize','bit processing','rank1 element file'])
add('rank1_undefined_neighbors',prog('character(8)::s(3)\ncharacter(20)::fmt', '''fmt='(z2.2,1x,i0)'
write(s(2),fmt=fmt)iand(maskl(4),255),shiftr(maskr(4),1)
print '(a)','['//s(2)//']'
print '(i0)',len(s(1))'''),'[00 7    ]\n8\n',['undefined neighbors remain unread','runtime named FMT','MASKL full32 width','SHIFTR'])
add('rank2_neighbors_wide',prog('character(16)::s(2,2)', '''s='################'
write(s(2,1),'(z16.16)')shiftr(-1_8,1)
print '(a)',s'''),'################\n7FFFFFFFFFFFFFFF\n################\n################\n',['rank2 element file','neighbor preservation','INTEGER8 logical shift'])
add('deferred_rank3_file',prog('character(:),allocatable::s(:,:,:)\ncharacter(12)::fmt\ninteger::j,k', '''allocate(character(6)::s(1,2,2))
fmt='(i6.6)'
do k=1,2
do j=1,2
write(s(1,j,k),fmt)maskr(j+k)
end do
end do
print '(a)',s'''),''.join(f'{(1<<(j+k))-1:06d}\n' for k in [1,2] for j in [1,2]),['deferred file length','rank3 descriptors','dynamic MASKR count','runtime format'])
add('gather_assumed_file_dummy', '''module m
contains
subroutine emit(v,s)
integer,intent(in)::v(:,:,:)
character(*),intent(out)::s(:,:,:)
integer::i,j,k
do k=1,size(v,3)
do j=1,size(v,2)
do i=1,size(v,1)
write(s(i,j,k),'(i3.3)')shiftr(v(i,j,k),1)
end do
end do
end do
end subroutine
end module
program p
use m
implicit none
integer::a(2,1,2)
character(3)::s(2,1,2)
a(:,1,1)=[8,10]
a(:,1,2)=[12,14]
call emit((a(:,:,[2,1])),s)
print '(a)',s
end program''','006\n007\n004\n005\n',['parenthesized gather IN value','assumed-length OUT array','rank3 element file'])
add('implied_do_element_values',prog('character(8)::s(2)\ninteger::i', '''write(s(2),'(4z2.2)')(maskr(i),i=0,3)
print '(a)',s(2)
print '(i0)',i'''),'00010307\n4\n',['output implied-DO','MASKR per iteration','undefined internal target'])
add('colon_skips_element_slash',prog('character(6)::s(1,1)', '''write(s(1,1),'(z2.2,:,/)')maskr(4)
print '(a)','['//s(1,1)//']' '''),'[0F    ]\n',['rank2 internal file','colon skips slash','blank padding'])
add('positioning_pending_stdout',prog('character(8)::s(1)', '''write(*,'(a)',advance='no')'P:'
write(s(1),'(b8.8,t3,a)')maskr(4),'XY'
print '(a)',s(1)'''),'P:00XY1111\n',['B output','T backward overwrite','internal file independent of pending stdout'])
add('case_inline_call', '''module m
contains
subroutine emit(n)
integer,intent(in)::n
character(4)::s(2)
write(s(2),'(z4.4)')maskr(n)
print '(a)',s(2)
end subroutine
end module
program p
use m
implicit none
select case(iand(7,maskr(2)))
case(3);call emit(4)
case default;error stop 'wrong branch'
end select
end program''','000F\n',['CASE same-line CALL','MASKR selector','internal element in callee'])
add('case_inline_write',prog('character(4)::s(2)', '''select case(maskr(3))
case(7);write(s(2),'(z2.2)')shiftr(maskl(4),28)
case default;error stop 'wrong branch'
end select
print '(a)','['//s(2)//']' '''),'[0F  ]\n',['CASE same-line WRITE','MASKL+SHIFTR','internal padding'])
add('record_defaults_staged_items', '''module m
implicit none
type::box
integer::a,n=4,b
character(3)::s='Ab'
end type
end module
program p
use m
implicit none
type(box)::x,y
integer::n
character(8)::buf(2)
y=x
x%s='Q'
n=y%n
write(buf(2),'(a,1x,z2.2)')y%s,maskr(n)
print '(a)','['//buf(2)//']'
end program''','[Ab  0F  ]\n',['mixed defaults','CHAR deep copy','staged component/bit items','element file'])
add('fresh_function_file_result', '''module m
contains
function labels(n) result(answer)
integer,intent(in)::n
character(4)::answer(2)
write(answer(1),'(z4.4)')maskr(n)
write(answer(2),'(z4.4)')shiftr(maskr(n),1)
end function
end module
program p
use m
implicit none
character(4)::s(2)
s=labels(3)
print '(a)',s
s=labels(1)
print '(a)',s
end program''','0007\n0003\n0001\n0000\n',['fresh function result array','internal element output','mask/shift result lifetime'])
add('empty_gather_bit_no_data',prog('integer::a(2,3,1),g(2,0,1),n\ncharacter(5)::s(1)', '''g=shiftr(a(:,[integer::],:),n)
write(s(1),'(i0,1x,i0)')size(g),kind(maskl(0,kind=8))
print '(a)','['//s(1)//']' '''),'[0 8  ]\n',['empty axis2 gather','undefined base and scalar shift not read','KIND result','element file'])
add('kind_unallocated_gather',prog('integer(8),allocatable::a(:,:,:)\ninteger::idx(2)\ncharacter(3)::s(1)', '''write(s(1),'(i0)')kind(shiftr(a(:,idx,:),0))
print '(a)','['//s(1)//']' '''),'[8  ]\n',['KIND unallocated gather','undefined vector not evaluated','SHIFTR metadata','element file'])
add('paired_gather_bit_alias',prog('integer::a(2,1,2),g(2,1,2),i,k\ncharacter(4)::s(2,1,2)', '''a(:,1,1)=[1,2]
a(:,1,2)=[8,4]
g=ior(a([2,1],:,:),a([1,2],:,:))
do k=1,2
do i=1,2
write(s(i,1,k),'(b4.4)')g(i,1,k)
end do
end do
print '(a)',s'''),'0011\n0011\n1100\n1100\n',['independent gather snapshots','IOR alias reads','rank3 file'])
add('constant_kind_full_width',prog('integer(8)::v(3)\ncharacter(2)::s(3)\ninteger::i', '''v=shiftr(maskl([0,1,64],kind=int(8,8)),[0_8,63_8,64_8])
do i=1,3
write(s(i),'(i0)')v(i)
end do
print '(a)',s
print '(i0)',kind(maskr(1,kind=int(8,8)))'''),'0 \n1 \n0 \n8\n',['constant converted KIND','MASKL zero/full widths','mixed input-kind shift','internal records'])
add('zero_length_element',prog('character(0)::s(1,1,1)', '''write(s(1,1,1),'(a)')''
if(maskr(0)/=0)error stop 'zero mask'
print '(a)','['//s(1,1,1)//']' '''),'[]\n',['zero-length rank3 element','empty transfer','zero mask'])
# GNU compiles these but never evaluates undefined data, invalid bounds/controls or unavailable records.
add('gather_bounds_pending_atomic',prog('integer::a(2,1,1)\ncharacter(8)::s(1)', '''a(:,1,1)=[1,2]
write(*,'(a)',advance='no')'SAFE'
write(s(1),'(i0)')shiftr(a([3],:,:),1)'''),'SAFE',['invalid vector index','internal output staging','pending stdout preserved'],category='runtime',gnu='compile')
add('gather_undefined_atomic',prog('integer::a(2,1,1)\ncharacter(8)::s(1)', '''a(1,1,1)=8
write(*,'(a)')'SAFE'
write(s(1),'(i0)')iand(a([2],:,:),maskr(4))'''),'SAFE\n',['selected undefined value','no target commit','prior stdout preserved'],category='runtime',gnu='compile')
add('mask_count_atomic',prog('integer::n\ncharacter(8)::s(2)', '''n=33
write(*,'(a)',advance='no')'SAFE'
write(s(2),'(z8.8)')maskr(n)'''),'SAFE',['MASKR count bounds','internal element failure atomicity'],category='runtime',gnu='compile')
add('shift_count_atomic',prog('integer::n\ncharacter(8)::s(1,1,1)', '''n=-1
write(*,'(a)')'SAFE'
write(s(1,1,1),'(i0)')shiftr(maskr(8),n)'''),'SAFE\n',['SHIFTR count bounds','rank3 internal target'],category='runtime',gnu='compile')
add('dynamic_internal_slash_atomic',prog('character(8)::s(2)\ncharacter(12)::fmt', '''fmt='(i0,/)'
write(*,'(a)',advance='no')'SAFE'
write(s(2),fmt)maskr(2)'''),'SAFE',['runtime slash boundary','scalar record represented by element','pending stdout'],category='runtime',gnu='compile')
add('short_record_atomic',prog('character(1)::s(1)', '''write(*,'(a)',advance='no')'SAFE'
write(s(1),'(z2.2)')maskr(8)'''),'SAFE',['whole-record overflow','no partial file write','B/O/Z exact width'],category='runtime',gnu='compile')
add('undefined_file_index_atomic',prog('character(4)::s(2)\ninteger::i', '''write(*,'(a)')'SAFE'
write(s(i),'(z4.4)')maskr(4)'''),'SAFE\n',['target index evaluated before items','undefined index rejection'],category='runtime',gnu='compile')
add('rank3_scatter_boundary',prog('integer::a(2,1,1),b(1,1,1)', '''a=0
b=maskr(4)
a([1],:,:)=b
print '(i0)',a(1,1,1)'''),'',['read-only vector gather contract','scatter remains excluded'],category='reject',gnu='compile')
# Populated only after preserving and reviewing the first immutable preview observations.
DIAGNOSTICS={}
for c in C:
 if c['name'] in DIAGNOSTICS:
  line,column,message=DIAGNOSTICS[c['name']]
  c.update(diagnostic=message,diagnostic_line=line,diagnostic_column=column)
(R/'manifest.json').write_text(json.dumps(dict(cases=C),indent=2)+'\n')
(R/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in C],inputs=[]),indent=2)+'\n')
print(len(C),'cases generated')
