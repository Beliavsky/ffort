module m
implicit none
character(*),parameter::mod_str="in util_mod::"
interface set_alloc
module procedure set_alloc_character_vec
end interface
interface set_optional
module procedure set_optional_integer
end interface
contains
subroutine select_vec_character(iuse,xx,idim)
! select elements in positions iuse along dimension idim
integer          , intent(in)                  :: iuse(:)
integer          , intent(in)    , optional    :: idim
character (len=*), intent(in out), allocatable :: xx(:)
character (len=*), parameter                   :: msg=mod_str//"select_vec_character, "
integer                                        :: idim_
call set_optional(idim_,1,idim)
if (idim_ /= 1) then
   write (*,*) msg,"idim_ =",idim_," must equal 1, stoppinG"
   stop
end if
call set_alloc((xx(iuse)),xx)
end subroutine select_vec_character
pure subroutine set_alloc_character_vec(xx,yy,nsize)
! for character arrays xx(:) and yy(:), allocate yy and set it to xx
character (len=*) , intent(in)               :: xx(:)
character (len=*) , intent(out), allocatable :: yy(:)
integer           , intent(out), optional    :: nsize
allocate (yy(size(xx)))
yy = xx
if (present(nsize)) nsize = size(yy)
end subroutine set_alloc_character_vec
elemental subroutine set_optional_integer(i,idef,iopt)
! set i to (iopt,idef) if iopt (is,is not) PRESENT
integer, intent(out)          :: i
integer, intent(in)           :: idef
integer, intent(in), optional :: iopt
if (present(iopt)) then
   i = iopt
else
   i = idef
end if
end subroutine set_optional_integer
end module
program main
use m
implicit none
character(3),allocatable::x(:)
allocate(x(3))
x=[character(3)::'one','two','tri']
call select_vec_character([3,1,3,2],x)
print '(a)',x
call select_vec_character([2,1],x,1)
print '(a)',x
end program
