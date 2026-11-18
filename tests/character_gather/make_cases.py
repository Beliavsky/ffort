from pathlib import Path
import json,hashlib,zipfile
r=Path(__file__).parent/'tests';(r/'cases').mkdir(parents=True,exist_ok=True);rows=[]
def add(name,src,mode='run'):
 src=src.strip()+'\n';(r/'cases'/f'{name}.f90').write_text(src);rows.append({'name':name,'source':f'cases/{name}.f90','sha256':hashlib.sha256(src.encode()).hexdigest(),'mode':mode})
base="implicit none\ncharacter(3)::x(-1:1)=[character(3)::'one','two','tri']\ninteger::idx(4)=[1,-1,1,0]\n"
for name,body in [('repeated_lower_bound',"print '(a)',x(idx)"),('overlap_assignment',"x=x([1,0,-1])\nprint '(a)',x"),('empty',"print *,size(x([integer::]))"),('index_expression',"print '(a)',x([0,-1]+1)"),('fixed_untyped_constructor',"print '(a)',[x(idx)]")]:add(name,base+body+'\nend')
add('unselected_undefined',"implicit none\ncharacter(3)::x(3)\nx(2)='abc'\nprint '(a)',x([2,2])\nend")
add('selected_undefined',"implicit none\ncharacter(3)::x(3)\nx(2)='abc'\nprint '(a)',x([1])\nend",'runtime-reject')
add('out_of_bounds',base+"print '(a)',x([2])\nend",'runtime-reject')
add('zero_length',"implicit none\ncharacter(0)::x(2)\nx=''\nprint *,size(x([2,1,2])),len(x([2,1]))\nend")
add('parameter',"implicit none\ncharacter(2),parameter::x(3)=['ab','cd','ef']\nprint '(a)',x([3,1])\nend")
add('len_undefined_metadata',"implicit none\ncharacter(3)::x(3)\ninteger::i(2)\nprint *,len(x(i))\nend")
add('scatter_reject',base+"x([1,-1])='abc'\nend",'check-reject')
add('numeric_rank1_boundary',"integer::x(3)=[1,2,3]\nprint*,x([3,1])\nend")
add('character_rank2_boundary',"character(2)::x(2,2)\nx='ok'\nprint*,x([2,1],:)\nend",'check-reject')
add('allocatable_resize','''module m
contains
subroutine set_alloc(values,x)
character(*),intent(in)::values(:)
character(*),allocatable,intent(inout)::x(:)
if(allocated(x))deallocate(x)
allocate(x(size(values)))
x=values
end subroutine
subroutine select_vec_character(iuse,xx)
integer,intent(in)::iuse(:)
character(*),allocatable,intent(inout)::xx(:)
call set_alloc((xx(iuse)),xx)
end subroutine
end module
program main
use m
implicit none
character(3),allocatable::x(:)
allocate(x(3))
x=[character(3)::'one','two','tri']
call select_vec_character([3,1,3,2],x)
print '(a)',x
end program''')
for name,body,mode in [('deferred_length',"print '(a)',x([2,1])",'run'),('deferred_typed_constructor',"print '(a)',[character(3)::x([2,1])]",'run'),('deferred_untyped_constructor_boundary',"print '(a)',[x([2,1])]",'check-reject')]:add(name,"implicit none\ncharacter(:),allocatable::x(:)\nallocate(character(3)::x(2))\nx=['abc','def']\n"+body+'\nend',mode)
add('released_constructor_cache',"implicit none\ncharacter(65536)::x(1)\ninteger::i,y(257)\nx='a'\ny=[(index(x([1]),'a'),i=1,257)]\nprint *,sum(y)\nend")
add('released_output_cache',"implicit none\ncharacter(65536)::x(1)\ninteger::i\nx='a'\nprint '(i1)',(index(x([1]),'a'),i=1,257)\nend")
add('fixed_unallocated_len',"implicit none\ncharacter(7),allocatable::x(:)\ninteger::idx(2)\nprint *,len(x(idx)),kind(x(idx))\nend")
add('deferred_empty_len',"implicit none\ncharacter(:),allocatable::x(:)\ninteger::idx(0)\nallocate(character(4)::x(0))\nprint *,size(x(idx)),len(x(idx))\nend")
parts=[];meta={}
for name in ['select_vec_character','set_alloc_character_vec','set_optional_integer']:
 raw=(r.parent/('utilities-'+name+'-original-body.f90')).read_bytes()
 parts.append(raw.decode().replace('\r\n','\n'));meta[name]={'raw_sha256':hashlib.sha256(raw).hexdigest(),'normalized_sha256':hashlib.sha256(parts[-1].encode()).hexdigest()}
closure='''module m
implicit none
character(*),parameter::mod_str="in util_mod::"
interface set_alloc
module procedure set_alloc_character_vec
end interface
interface set_optional
module procedure set_optional_integer
end interface
contains
'''+''.join(parts)+'''end module
program main
use m
implicit none
character(3),allocatable::x(:)
allocate(x(3))
x=[character(3)::'one','two','tri']
call select_vec_character([3,1,3,2],x)
print '(a)',x
call select_vec_character([2,1],x,1)
print '(a)',x
end program
'''
add('original_dependency_closure',closure)
(r.parent/'UTILITIES-PROVENANCE.json').write_text(json.dumps({'original_source_sha256':'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883','bodies':meta,'closure_note':'Three original bodies unchanged except line-ending normalization; narrowed generic wrappers, restated mod_str constant and new driver. Not complete utilities module.'},indent=2)+'\n')
add('aggregate_live_cache_limit',"implicit none\ncharacter(65536)::x(1)\ninteger::idx(129)\nx='a'\nidx=1\nif(sum(index(x(idx),'a')+index(x(idx),'a'))/=258)error stop 'sum'\nend",'runtime-reject')
(r/'manifest.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');(r/'SOURCE-IDENTITY.json').write_text(json.dumps({c['source']:c['sha256'] for c in rows},indent=2)+'\n')
