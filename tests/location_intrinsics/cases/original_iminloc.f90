module utility_slice
implicit none
integer,parameter::dp=selected_real_kind(15,307)
contains
function iminloc(arr)
real(kind=dp), dimension(:), intent(in) :: arr
integer, dimension(1) :: imin
integer :: iminloc
imin=minloc(arr(:))
iminloc=imin(1)
end function iminloc
end module
program p
use utility_slice
implicit none
real(dp)::a(4)
a=[3.0_dp,-1.0_dp,-1.0_dp,5.0_dp]
print *,iminloc(a),iminloc(a(4:1:-1)),iminloc(a(1:0))
end program
