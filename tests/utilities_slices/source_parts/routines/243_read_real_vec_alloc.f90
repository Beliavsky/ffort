subroutine read_real_vec_alloc(text,xx)
! read xx(:) from text
character (len=*), intent(in)               :: text
real(kind=dp)    , intent(out), allocatable :: xx(:)
integer                                     :: ierr,n
character (len=*), parameter                :: msg="in util_mod::read_real_vec_alloc, "
read (text,*,iostat=ierr) n
if (ierr /= 0) then
   write (*,*) msg,"could not read an integer from '" // trim(text) // "'"
   stop
end if
allocate (xx(n))
if (n > 0) then
   read (text,*,iostat=ierr) n,xx
   if (ierr /= 0) then
      write (*,*) msg,"could not read integer and ",n," reals from '" // trim(text) // "'"
      stop
   end if
end if
end subroutine read_real_vec_alloc
!
