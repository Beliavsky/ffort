! SPDX-License-Identifier: MIT
! Independent public value ownership, metadata and cap arithmetic guards.
program test_release042_storage
use iso_fortran_env,only:int64
use fi_ir,only:value_t,component_value_t,ty_integer,ty_character,ty_derived_base,shape_size,max_array_elements
implicit none
type(value_t)::a,b,c
type(value_t),allocatable::v(:),copy(:)
integer::i
if(max_array_elements/=1000000) error stop 'default cap changed'
if(shape_size([100_int64,100_int64,100_int64])/=1000000_int64) error stop 'at cap'
if(shape_size([100_int64,100_int64,101_int64])<=1000000_int64) error stop 'above cap'
if(shape_size([huge(0_int64),0_int64,huge(0_int64)])/=0_int64) error stop 'zero product'
if(shape_size([huge(0_int64),huge(0_int64),huge(0_int64)])<=1000000_int64) error stop 'overflow saturate'
a%tag=ty_derived_base+1
allocate(a%record)
allocate(a%record%components(2),a%record%component_defined(2))
a%record%components(1)=component_value_t(tag=ty_integer,i=17_int64)
a%record%components(2)=component_value_t(tag=ty_integer,i=29_int64)
a%record%component_defined=[.true.,.false.]
b=a
b%record%components(1)%i=91
b%record%component_defined(2)=.true.
if(a%record%components(1)%i/=17.or.a%record%component_defined(2)) error stop 'scalar alias'
allocate(v(3),copy(3))
v(1)=a
v(2)=value_t(tag=ty_character,s='x   ')
v(3)=value_t(tag=ty_character,s='')
copy=v
v(1)%record%components(2)%i=88
v(1)%record%component_defined(1)=.false.
v(2)%s='longer text'
v(3)%s='z'
if(copy(1)%record%components(2)%i/=29) error stop 'array record alias'
if(.not.copy(1)%record%component_defined(1).or.copy(1)%record%component_defined(2)) error stop 'flags alias'
if(copy(2)%s/='x   '.or.len(copy(2)%s)/=4) error stop 'character alias'
if(len(copy(3)%s)/=0) error stop 'zero-length copy'
do i=2,3
 if(allocated(copy(i)%record)) error stop 'intrinsic payload allocated'
end do
c=copy(1)
deallocate(copy)
if(c%record%components(1)%i/=17.or.c%record%component_defined(2)) error stop 'lifetime'
v=value_t(tag=ty_integer,i=3_int64)
do i=1,3
 if(allocated(v(i)%record).or.allocated(v(i)%s)) error stop 'payload release'
end do
print '(a)','ok'
end program
