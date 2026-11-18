#!/usr/bin/env python3
"""Independent synthetic 0.52 interactions. No upstream/original source claims."""
from pathlib import Path
import hashlib,json,argparse
ROWS=[]
def add(name,decl,body,out,features,mode='run',gnu_mode=None):
    src='program main\nimplicit none\n'+decl.strip()+'\n'+body.strip()+'\nend program\n'
    ROWS.append(dict(name=name,source=src,mode=mode,gnu_mode=gnu_mode or ('execute' if mode=='run' else 'compile-only'),stdout=out,features=features))
add('while_rotation_refresh','character(2)::x(3)\ninteger::i',"""x=['A ','B ','C ']
i=0
do while(i<3)
  print '(3a2)',x([3,1,2])
  x=x([2,3,1])
  i=i+1
end do""",'C A B \nA B C \nB C A \n',['DO WHILE','gather cache refresh','alias assignment'])
add('while_gather_condition','character(1)::x(3)\ninteger::n',"""x=['a','b','c']
n=0
do while(any(x([1,3])/=['b','a']))
  x=x([2,3,1])
  n=n+1
end do
print '(i0,1x,3a1)',n,x""",'1 bca\n',['array LOGICAL condition','gather in condition','body refresh'])
add('mask_shift_indices','character(2)::x(4)\ninteger(8)::idx(4)',"""x=['AA','BB','CC','DD']
idx=iand(shiftr([12_8,10_8,12_8,14_8],1),maskr(2,kind=8))+1
print '(4(a2,1x))',x(idx)""",'CC BB CC DD\n',['INTEGER8 masks/SHIFTR','duplicate gather ordering'])
add('element_file_rank3','character(2)::x(3)\ncharacter(8)::s(1,2,1)',"""x=['aa','bb','cc']
s='KEEP'
write(s(1,2,1),'(a2,":",a2)')x([3,1])
print '(a)',s(1,1,1),s(1,2,1)""",'KEEP    \ncc:aa   \n',['gather output items','rank3 element internal WRITE','neighbor preservation'])
add('allocatable_alias_rebounds','character(2),allocatable::x(:)',"""allocate(x(0:2))
x=['aa','bb','cc']
x=x([2,0,2,1])
print '(i0,1x,i0,1x,4a2)',lbound(x,1),ubound(x,1),x""",'1 4 ccaaccbb\n',['allocatable self-gather','lower bounds','snapshot before reallocation'])
add('deferred_typed_concat','character(:),allocatable::x(:)\ncharacter(4)::y(3)',"""allocate(character(2)::x(2))
x=['a ','b ']
y=[character(4)::x([2,1]),'Z']
print '(a)',y""",'b   \na   \nZ   \n',['deferred descriptor','typed constructor padding','gather leaf'])
add('output_do_index_overlay','character(1)::x(3)\ninteger::i',"""x=['a','b','c']
i=9
print '(a)',(x([i,4-i]),i=1,3)
print '(i0)',i""",'a\nc\nb\nb\nc\na\n4\n',['output implied-DO','gather indices refresh','control final value'])
add('constructor_index_cache','character(3)::x(3)\ninteger::a(3),i',"""x=['axx','bxb','xxc']
i=9
a=[(index(x([i]),'x'),i=1,3)]
print '(3(i0,1x),i0)',a,i""",'2 2 1 9\n',['constructor index ownership','gather inside INDEX','outer index preserved'])
add('empty_deferred_metadata','character(:),allocatable::x(:),y(:)',"""allocate(character(5)::x(0))
y=x([integer::])
print '(i0,1x,i0,1x,i0)',size(y),len(y),kind(y)""",'0 5 1\n',['empty deferred gather','assignment descriptor','no base values'])
add('fixed_unallocated_kind_len','character(6),allocatable::x(:)\ninteger::idx(2),n',"""n=0
do while(n<1)
  print '(i0,1x,i0)',len(x(idx)),kind(x(idx))
  n=n+1
end do""",'6 1\n',['fixed LEN','KIND','undefined index and unavailable base non-evaluation'])
add('minmax_gather_padding','character(2)::x(3)\ncharacter(3)::y(3)',"""x=['aa','cc','b ']
y=max(x([3,1,2]),'bb ')
print '(a)',y""",'bb \nbb \ncc \n',['CHARACTER MAX','scalar expansion','gather result lengths'])
add('derived_field_staging','character(3)::x(3)\ntype::record\n character(3)::s="abc"\n integer::n=2\nend type\ntype(record)::r',"""x=r%s
x(2)='DEF'
print '(a)',x([r%n,1,r%n])""",'DEF\nabc\nDEF\n',['derived CHAR default','component index scalar','ordinary CHAR gather'])
add('bounds_failure_pending','character(2)::x(2)\ninteger::idx(2)',"""x=['ab','cd']
idx=[1,3]
write(*,'(a)',advance='no')'SAFE'
print '(a)',x(idx)""",'SAFE',['bounds check','pending stdout atomicity'],mode='runtime')
add('undefined_element_file','character(2)::x(2)\ncharacter(8)::dest(2)',"""x(1)='ab'
dest='KEEP'
write(*,'(a)',advance='no')'SAFE'
write(dest(2),'(a)')x([1,2])
print '(a)',dest""",'SAFE',['undefined selected element','element file staging','pending stdout'],mode='runtime')
add('dynamic_untyped_boundary','character(:),allocatable::x(:)',"""allocate(character(2)::x(2))
x=['ab','cd']
write(*,'(a)',advance='no')'SAFE'
print '(a)',[x([2,1])]""",'SAFE',['preserved dynamic untyped constructor boundary','pending stdout'],mode='runtime')
add('dynamic_internal_slash','character(2)::x(2)\ncharacter(8)::dest(2)\ncharacter(12)::fmt',"""x=['ab','cd']
dest='KEEP'
fmt='(a2,/,a2)'
write(*,'(a)',advance='no')'SAFE'
write(dest(2),fmt)x([2,1])
print '(a)',dest""",'SAFE',['runtime format','reached internal slash retained boundary','gather staging'],mode='runtime')
# Parenthesized IN actual snapshots before INTENT(OUT) deallocation.
src='''module move_mod
implicit none
contains
subroutine replace(src,dst)
character(*),intent(in)::src(:)
character(*),allocatable,intent(out)::dst(:)
allocate(dst(size(src)))
dst=src
end subroutine
end module
program main
use move_mod
implicit none
character(2),allocatable::x(:)
allocate(x(3))
x=['aa','bb','cc']
call replace((x([3,1,3])),x)
print '(3a2)',x
end program
'''
ROWS.append(dict(name='in_actual_out_alias',source=src,mode='run',gnu_mode='execute',stdout='ccaacc\n',features=['parenthesized INTENT(IN) actual','INTENT(OUT) alias deallocation','deep-copy']))
ROWS.append(dict(name='unparenthesized_actual_boundary',source=src.replace('call replace((x([3,1,3])),x)','call replace(x([3,1,3]),x)'),mode='reject',gnu_mode='compile-only',stdout='',features=['retained unparenthesized actual boundary','no writable gather expansion']))
# Supported module-defined counterpart; original main-local TYPE fixture stays intact.
ROWS.append(dict(name='module_derived_field_staging',source='module record_mod\nimplicit none\ntype::record\n character(3)::s="abc"\n integer::n=2\nend type\nend module\nprogram main\nuse record_mod\nimplicit none\ncharacter(3)::x(3)\ntype(record)::r\nx=r%s\nx(2)=\'DEF\'\nprint \'(a)\',x([r%n,1,r%n])\nend program\n',mode='run',gnu_mode='execute',stdout='DEF\nabc\nDEF\n',features=['module derived default','component staging','gather indices']))
# Scalar staging keeps the retained strict metadata walker boundary separate.
ROWS.append(dict(name='module_component_scalar_staging',source=ROWS[-1]['source'].replace('character(3)::x(3)','character(3)::x(3)\ninteger::n').replace("print '(a)',x([r%n,1,r%n])","n=r%n\nprint '(a)',x([n,1,n])"),mode='run',gnu_mode='execute',stdout='DEF\nabc\nDEF\n',features=['module derived default','scalar component staging','gather indices']))
# Metadata corrections preserve all first-attempt Fortran bytes. These are retained subset boundaries.
for r in ROWS:
 if r['name']=='unparenthesized_actual_boundary':
  r.update(mode='runtime',features=['bare CHARACTER gather input','whole-base writable sibling alias boundary'])
 if r['name']=='module_derived_field_staging':
  r.update(mode='runtime',gnu_mode='compile-only',stdout='')
 if r['name']=='derived_field_staging':
  r.update(mode='reject',gnu_mode='compile-only',stdout='')
 if r['name']=='dynamic_untyped_boundary':
  r.update(mode='reject',stdout='')
DIAGNOSTICS={
 'module_derived_field_staging':(15,18,'invalid KIND argument opcode'),
 'derived_field_staging':(4,5,'Expected (, found ::'),
 'bounds_failure_pending':(8,15,'vector row index out of bounds'),
 'undefined_element_file':(8,23,'read of uninitialized gathered array element'),
 'dynamic_untyped_boundary':(7,22,'Untyped CHARACTER constructor requires descriptor-known item lengths'),
 'dynamic_internal_slash':(10,1,'slash record editing requires another record; scalar internal/child WRITE is unsupported'),
 'unparenthesized_actual_boundary':(17,1,'bare CHARACTER gather base overlaps a writable actual'),
}
for r in ROWS:
 if r['name'] in DIAGNOSTICS:
  line,column,message=DIAGNOSTICS[r['name']]
  r['diagnostic']=dict(line=line,column=column,message=message)
def generate(root):
 root=Path(root);(root/'cases').mkdir(parents=True,exist_ok=True);rows=[]
 for r in ROWS:
  c=dict(r);source=c.pop('source');(root/'cases'/(r['name']+'.f90')).write_text(source)
  c['source_sha256']=hashlib.sha256(source.encode()).hexdigest();rows.append(c)
 (root/'manifest.json').write_text(json.dumps(rows,indent=2)+'\n')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',default=str(Path(__file__).resolve().parent));a=p.parse_args();generate(a.output)
