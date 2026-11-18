module utility_alloc_chars
implicit none
contains
pure subroutine set_alloc_character_vec(xx,yy,nsize)
! for character arrays xx(:) and yy(:), allocate yy and set it to xx
character (len=*) , intent(in)               :: xx(:)
character (len=*) , intent(out), allocatable :: yy(:)
integer           , intent(out), optional    :: nsize
allocate (yy(size(xx)))
yy = xx
if (present(nsize)) nsize = size(yy)
end subroutine set_alloc_character_vec
subroutine set_alloc_character_mat(xx,yy)
! for character arrays xx(:,:) and yy(:,:), allocate yy and set it to xx
character (len=*) , intent(in)               :: xx(:,:)
character (len=*) , intent(out), allocatable :: yy(:,:)
allocate (yy(size(xx,1),size(xx,2)))
yy = xx
end subroutine set_alloc_character_mat
end module
program main
use utility_alloc_chars
implicit none
character(3)::x(3)=['one','two','tri']
character(4),allocatable::y(:)
character(3)::m(2,2)
character(5),allocatable::n(:,:)
character(3)::empty(0,2)
integer::counted
call set_alloc_character_vec(x,y,counted)
print *,counted,len(y),size(y)
print '(3a5)',y
m='abc'
call set_alloc_character_mat(m,n)
print *,len(n),size(n,1),size(n,2)
print '(4a6)',n
call set_alloc_character_mat(empty,n)
print *,allocated(n),len(n),size(n)
end program
