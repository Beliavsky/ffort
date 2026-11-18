module utility_slice
implicit none
interface default
module procedure default_logical,default_character
end interface
contains
!
subroutine read_alloc_char(iu,xx,nx,print_vec,label,same_line)
! read the size of an allocatable array and then the array from the next line
integer          , intent(in)               :: iu    ! unit read
character (len=*), intent(out), allocatable :: xx(:) ! data read
integer          , intent(out), optional    :: nx    ! size(xx)
logical          , intent(in) , optional    :: print_vec
character (len=*), intent(in) , optional    :: label
logical          , intent(in) , optional    :: same_line
integer                                     :: i,nx_,ndum
read (iu,*) nx_
nx_ = max(0,nx_)
allocate (xx(nx_))
if (present_and_true(same_line)) then
   backspace(iu)
   read (iu,*) ndum,xx
else
   read (iu,*) xx
end if
if (present(nx)) nx = nx_
if (default(.false.,print_vec)) write (*,"(1x,a30,':',100(1x,a))") trim(default("          ",label)), &
                                                               (trim(xx(i)),i=1,size(xx))
end subroutine read_alloc_char
!
pure function present_and_true(xx) result(tf)
logical, intent(in), optional :: xx
logical                       :: tf
if (present(xx)) then
   tf = xx
else
   tf = .false.
end if
end function present_and_true
elemental function default_logical(def,opt) result(tf)
! return opt if it is present, otherwise def (logical arguments and result)
logical, intent(in)           :: def
logical, intent(in), optional :: opt
logical                       :: tf
if (present(opt)) then
   tf = opt
else
   tf = def
end if
end function default_logical
elemental function default_character(def,opt) result(yy)
! return opt if it is present, otherwise def (character arguments and result)
character (len=*), intent(in)           :: def
character (len=*), intent(in), optional :: opt
character (len=len(def))                :: yy
if (present(opt)) then
   yy = opt
else
   yy = def
end if
end function default_character
end module
program p
use utility_slice
implicit none
integer::u,n
character(4),allocatable::xx(:)
u=27
call read_alloc_char(u,xx,n,same_line=.true.)
if(n/=0.or.size(xx)/=0)stop 1
end program
