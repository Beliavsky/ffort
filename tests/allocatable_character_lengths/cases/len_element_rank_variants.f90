program p
implicit none
character(3) :: words(0)
character(3),allocatable :: matrix(:,:),cube(:,:,:)
call fill_matrix(words,matrix)
call fill_cube(words,cube)
if (len(matrix)/=3 .or. size(matrix)/=4) error stop 1
if (any(matrix/='abc')) error stop 2
if (len(cube)/=3 .or. size(cube)/=0) error stop 3
print *,1
contains
subroutine fill_matrix(words,a)
character(*),intent(in) :: words(:)
character(len=len(words(1))),allocatable,intent(out) :: a(:,:)
allocate(a(-1:0,3:4))
a='abcd'
end subroutine
subroutine fill_cube(words,a)
character(*),intent(in) :: words(:)
character(len=len(words)),allocatable,intent(out) :: a(:,:,:)
allocate(a(0,1,2))
end subroutine
end program
