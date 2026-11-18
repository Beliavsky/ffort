program p
real(8),allocatable::a(:,:,:)
a=make(3)
print *,size(a),size(a,3),lbound(a,3),sum(a(:,:,1))+sum(a(:,:,2))+sum(a(:,:,3))
a=make(0)
print *,allocated(a),size(a),size(a,1),size(a,2),size(a,3)
contains
function make(n) result(x)
integer,intent(in)::n
real(8),allocatable::x(:,:,:)
allocate(x(-1:0,4:4,7:6+n)); x=1.5d0
end function
end program
