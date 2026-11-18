subroutine read_vec_data_unit(iu,xx,nlines_skip,close_unit)
! read xx(:) from unit iu, one element per line
integer      , intent(in)               :: iu           ! unit from which data read
real(kind=dp), intent(out), allocatable :: xx(:)        ! data read on output
integer      , intent(in) , optional    :: nlines_skip  ! # of lines to skip before reading data
logical      , intent(in) , optional    :: close_unit   ! if present and .true., close unit before RETURNing
integer      , parameter                :: nmax = 10**8 ! max # of obs to read
real(kind=dp)                           :: xbig(nmax)
integer                                 :: i,ierr,nread
nread = nmax
if (present(nlines_skip)) then
   do i=1,nlines_skip
      read (iu,*)
   end do
end if
do i=1,nmax
   read (iu,*,iostat=ierr) xbig(i)
   if (ierr /= 0) then
      nread = i-1
      exit
   end if
end do
allocate (xx(nread))
xx = xbig(:nread)
if (default(.false.,close_unit)) close(iu)
end subroutine read_vec_data_unit
!
