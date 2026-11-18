module dependency_closure
implicit none
character(*),parameter::mod_str="utilities, "
contains
subroutine unique_int(ivec,ipos,nuniq)
! return in ipos(1:nuniq) the positions of the unique elements of ivec(:)
integer, intent(in)  :: ivec(:)
integer, intent(out) :: ipos(:) ! positions of unique integers in ivec
integer, intent(out) :: nuniq   ! # of unique integers in ivec
integer              :: i,n
n = size(ivec)
if (size(ipos) /= n) then
   write (*,*) mod_str//"unique_int, size(ivec), size(ipos) =",n,size(ipos)," should be equal, stopPinG"
   stop
end if
if (n == 0) then
   nuniq = 0
   return
end if
ipos(1) = 1
nuniq   = 1
do i=2,n
   if (all(ivec(i) /= ivec(ipos(:nuniq)))) then
      nuniq = nuniq + 1
      ipos(nuniq) = i
   end if
end do
end subroutine unique_int

pure recursive subroutine set_alloc_int_vec(ii,jj,jmin,jmax)
! for integer vectors xx(:) and yy(:), allocate yy and set it to xx
! keep only values between jmin and jmax, inclusive, if they are present
integer, intent(in)               :: ii(:)
integer, intent(out), allocatable :: jj(:)
integer, intent(in) , optional    :: jmin,jmax
integer                           :: ni
if (present(jmin) .and. present(jmax)) then
   call set_alloc_int_vec(pack(ii,ii >= jmin .and. ii <= jmax),jj)
else if (present(jmin)) then
   call set_alloc_int_vec(pack(ii,ii >= jmin),jj)
else if (present(jmax)) then
   call set_alloc_int_vec(pack(ii,ii <= jmax),jj)
else
   ni = size(ii)
!   print*,"size(ii)=",size(ii) ! debug
!   print*,"ni=",ni ! debug
   allocate (jj(ni))
   jj = ii
end if
end subroutine set_alloc_int_vec
end module
