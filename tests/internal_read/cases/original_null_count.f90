module util_mod
implicit none
integer,parameter::dp=kind(1d0)
contains
subroutine read_int_vec_alloc(text,ivec)
! read ivec(:) from text, which contains the number of integers followed by the integers
character (len=*), intent(in)               :: text
integer          , intent(out), allocatable :: ivec(:)
integer                                     :: ierr,n
character (len=*), parameter                :: msg="in util_mod::read_int_vec_alloc, "
read (text,*,iostat=ierr) n
if (ierr /= 0) then
   write (*,*) msg,"could not read an integer from '" // trim(text) // "'"
   stop
end if
allocate (ivec(n))
if (n > 0) then
   read (text,*,iostat=ierr) n,ivec
   if (ierr /= 0) then
      write (*,*) msg,"could not read ",n+1," integers from '" // trim(text) // "'"
      stop
   end if
end if
end subroutine read_int_vec_alloc
!
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
end module
program p
use util_mod
implicit none
integer,allocatable::a(:)
real(dp),allocatable::b(:)
call read_int_vec_alloc(',',a)
end
