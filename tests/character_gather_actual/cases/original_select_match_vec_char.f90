module m
implicit none
interface set_alloc
module procedure set_alloc_character_vec
end interface
contains
subroutine match_char(xgood,xx,iuse)
! return in iuse(:) the positions in xx(:) of elements that are found in xgood(:)
character (len=*), intent(in)               :: xgood(:)
character (len=*), intent(in)               :: xx(:)
integer          , intent(out), allocatable :: iuse(:)
logical                                     :: xmask(size(xx))
integer                                     :: i,j,n,nuse
n = size(xx)
forall (i=1:n) xmask(i) = any(xgood == xx(i))
nuse = count(xmask)
allocate (iuse(nuse))
j = 0
do i=1,n
   if (xmask(i)) then
      j = j + 1
      iuse(j) = i
      if (j == nuse) exit
   end if
end do
end subroutine match_char
subroutine select_match_vec_char(xgood,xx,xuse)
! return in xuse the elements in xx(:) that are in xgood(:)
character (len=*), intent(in)               :: xgood(:),xx(:)
character (len=*), intent(out), allocatable :: xuse(:)
integer                       , allocatable :: iuse(:)
call match_char(xgood,xx,iuse)
call set_alloc(xx(iuse),xuse)
end subroutine select_match_vec_char
pure subroutine set_alloc_character_vec(xx,yy,nsize)
! for character arrays xx(:) and yy(:), allocate yy and set it to xx
character (len=*) , intent(in)               :: xx(:)
character (len=*) , intent(out), allocatable :: yy(:)
integer           , intent(out), optional    :: nsize
allocate (yy(size(xx)))
yy = xx
if (present(nsize)) nsize = size(yy)
end subroutine set_alloc_character_vec
end module
program main
use m
implicit none
character(3)::xx(4)=["red","blu","red","grn"]
character(3),allocatable::answer(:)
call select_match_vec_char(["red"],xx,answer)
print "(a)",answer
call select_match_vec_char([character(3)::],xx,answer)
print "(i0)",size(answer)
call select_match_vec_char(["grn","blu"],xx,answer)
print "(a)",answer
end program
