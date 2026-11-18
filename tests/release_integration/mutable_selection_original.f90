! Original IMINLOC and VECTOR bodies; module declarations and driver are new.
module mutable_selection
implicit none
integer,parameter::dp=kind(1.0d0)
real(dp),dimension(2,3)::grid=reshape([4.0_dp,-2.0_dp,9.0_dp,1.0_dp,-2.0_dp,8.0_dp],[2,3])
logical,dimension(2,3)::mask=reshape([.true.,.false.,.true.,.true.,.true.,.false.],[2,3])
integer::calls=0
integer,parameter::initial_min(2)=minloc(reshape([4,-2,9,1,-2,8],[2,3]))
contains
function iminloc(arr)
real(kind=dp), dimension(:), intent(in) :: arr
integer, dimension(1) :: imin
integer :: iminloc
imin=minloc(arr(:))
iminloc=imin(1)
end function iminloc
function vector(xmat) result(xvec)
! convert a matrix to a vector
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp)             :: xvec(size(xmat))
xvec = reshape(xmat,(/size(xmat)/))
end function vector
!
subroutine change()
grid(1,1)=-5.0_dp
grid(2,3)=12.0_dp
calls=calls+1
end subroutine
end module
program combined_023
use mutable_selection
implicit none
print *,initial_min,minloc(grid),maxloc(grid),minloc(grid,back=.true.)
print *,minloc(grid,dim=1),maxloc(grid,dim=2)
print *,minloc(grid,mask=mask),iminloc(vector(grid)),iminloc(vector(grid(2:1:-1,3:1:-1)))
call change()
print *,calls,iminloc(vector(grid)),maxloc(grid,dim=1),minloc(grid,mask=mask)
print *,size(vector(grid(:,1:0))),iminloc(vector(grid(:,1:0)))
end program
