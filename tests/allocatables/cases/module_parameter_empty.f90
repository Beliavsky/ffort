module m
implicit none
integer,parameter::mat(-1:-2,4:6)=reshape([1],[0,3])
contains
integer function total() result(n)
n=sum(mat)+size(mat,2)+lbound(mat,2)+ubound(mat,2)
end function
subroutine inspect()
print *,size(mat),size(mat,2),lbound(mat,1),ubound(mat,1),lbound(mat,2),ubound(mat,2)
print *,sum(mat(:,:)),size(mat(:,4)),total()
end subroutine
end module
program main
use m
call inspect()
print *,total()
end program
