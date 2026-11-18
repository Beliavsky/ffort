module m
implicit none
integer,parameter::v(-2:0)=[3,4,5]
integer,parameter::mat(-1:0,3:5)=reshape([1,2,3,4,5,6],[2,3])
integer,allocatable::shared(:)
contains
integer function total() result(n)
n=sum(v)+sum(mat)+sum(mat(0,3:5:2))+lbound(mat,1)+ubound(mat,2)
end function
subroutine nested()
integer::work(size(mat,1),size(mat,2))
work=mat
print *,v(-1),mat(-1,4),sum(work),size(mat),lbound(v,1),ubound(v,1),total()
end subroutine
subroutine outer()
call nested()
if(lbound(shared,1)/=-3.or.sum(shared)/=14) error stop 1
end subroutine
end module
program main
use m
allocate(shared(-3:-2))
shared=7
call outer()
print *,total(),lbound(shared,1),sum(shared)
end program
