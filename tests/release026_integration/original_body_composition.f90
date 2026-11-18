module original_utilities
implicit none
integer,parameter::dp=8
contains
function munge(xx,yy,delim) result(xy)
! create array of strings containing combinations of xx and yy
character (len=*), intent(in) :: xx(:),yy(:),delim
character (len=len(xx)+len(yy)+len(delim)) :: xy(size(xx)*size(yy))
integer :: ix,iy,nx
nx = size(xx)
forall (ix=1:size(xx),iy=1:size(yy)) xy(ix + (iy-1)*nx) = trim(xx(ix)) // delim // trim(yy(iy))
end function munge

elemental function floor_10(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 10.0_dp**(floor(log10(abs(xx)))) * merge(1,-1,xx>0.0_dp)
end function floor_10

elemental function ceiling_10(xx) result(yy)
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 10.0_dp**(ceiling(log10(abs(xx)))) * merge(1,-1,xx>0.0_dp)
end function ceiling_10

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
program p
use original_utilities
implicit none
character(2)::left(2)=['a ','b '],right(2)=['1 ','2 ']
character(:),allocatable::words(:)
character(7),allocatable::wide(:)
integer::i,n
words=munge(left,right,':')
forall(i=1:size(words)) words(i)=words(size(words)+1-i)
call set_alloc_character_vec(words,wide,n)
print *,len(words),len(wide),n
print '(4a7)',wide
print *,floor_10([-123.0_dp,12.3_dp]),ceiling_10([-123.0_dp,12.3_dp])
end program
