module m

contains
subroutine make(a)
real(8),allocatable,intent(out)::a(:,:)
allocate(a(-1:0,4:6))
a=2.0_8
end subroutine
subroutine bump(a)
real(8),allocatable,intent(inout)::a(:,:)
a(-1,5)=7.0_8
end subroutine
end module
program main
use m
real(8),allocatable::v(:,:)
call make(v)
call bump(v)
print *,size(v),lbound(v,1),lbound(v,2),ubound(v,2),sum(v)
end program
