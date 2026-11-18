! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
character(:),allocatable::a(:,:,:),b(:,:,:)
allocate(character(2)::a(-1:0,4:4,7:8))
allocate(character(4)::b(3:4,5:5,9:10))
a='ab'
b='test'
call copy(a,b)
print *,shape(a),len(a),lbound(a,1),lbound(a,2),lbound(a,3),a(3,5,9)
a='q'
print *,shape(a),len(a),lbound(a,3)
call replace(a)
print *,shape(a),len(a),lbound(a,3),a(1,1,-2)
b=a(:,2:1:-1,-1:-2:-1)
print *,shape(b),len(b),lbound(b,1),lbound(b,2),lbound(b,3),b(1,1,1)
contains
subroutine copy(x,y)
character(:),allocatable,intent(in & ! preserve descriptor length
 & out)::x(:,:,:)
character(:),allocatable,intent(in)::y(:,:,:)
x=y
end subroutine
subroutine replace(x)
character(:),allocatable,optional,intent(in out)::x(:,:,:)
if(present(x)) then
 deallocate(x)
 allocate(character(3)::x(1,2,-2:-1))
 x='end'
end if
end subroutine
end program
