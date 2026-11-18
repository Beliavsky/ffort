subroutine read_strings_vec(iu,strings,nmax,fmt,close_unit)
! read strings from unit iu, one string per line
integer            , intent(in)               :: iu
character (len=*)  , intent(out), allocatable :: strings(:)
integer            , intent(in) , optional    :: nmax
character (len=*)  , intent(in) , optional    :: fmt
logical            , intent(in) , optional    :: close_unit
integer                                       :: i,nmax_,ierr,nread
nmax_ = default(nmax,1000000)
allocate (strings(nmax_))
nread = nmax_
do i=1,nmax_
   if (present(fmt)) then
      read (iu,fmt,iostat=ierr) strings(i)
   else
      read (iu,*,iostat=ierr) strings(i)
   end if
   if (ierr /= 0) then
      nread = i-1
      exit
   end if
end do
call set_alloc((strings(:nread)),strings)
if (present(close_unit)) then
   if (close_unit) close(iu)
end if
end subroutine read_strings_vec
!
