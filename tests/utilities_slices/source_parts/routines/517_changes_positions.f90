subroutine changes_positions(ivec,ipos,ival)
! return the first position and the positions where ivec(:) changes, and the corresponding values
integer, intent(in)               :: ivec(:)
integer, intent(out), allocatable :: ipos(:)
integer, intent(out), allocatable :: ival(:)
integer                           :: i,ich,n,nch
n = size(ivec)
if (n < 1) then
   allocate (ipos(0),ival(0))
   return
end if
nch = num_changes(ivec)
allocate (ipos(nch),ival(nch))
ipos(1) = 1
ival(1) = ivec(1)
ich = 1
do i=2,n
   if (ivec(i) /= ivec(i-1)) then
      ich = ich + 1
      ipos(ich) = i
      ival(ich) = ivec(i)
      if (ich == nch) exit
   end if
end do
end subroutine changes_positions
!
