! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
integer,allocatable::a(:,:,:),b(:,:,:),c(:,:,:)
allocate(a(-2:-1,4:4,7:8))
allocate(b(3:4,-1:-1,9:10))
a=2
b=7
call copy(a,b)
print *,shape(a),lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,7))
deallocate(b)
allocate(b(3:3,-1:1,9:10))
b=4
call copy(a,b)
print *,shape(a),lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,9))
c=b(:,:,10:9:-1)
print *,shape(c),lbound(c,1),lbound(c,2),lbound(c,3),sum(c(:,:,1))
a=b+1
print *,shape(a),lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,9))
contains
subroutine copy(x,y)
integer,allocatable,intent(in out)::x(:,:,:)
integer,allocatable,intent(in)::y(:,:,:)
x=y
end subroutine
end program
