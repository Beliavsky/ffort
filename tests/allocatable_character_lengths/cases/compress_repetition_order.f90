module exact_compress_module
implicit none
contains
pure subroutine compress(words,factors,values)
character (len=*)         , intent(in)               :: words(:)   ! (n) 
integer                   , intent(out)              :: factors(:) ! (n) integer values corresponding to words(:)
character (len=len(words)), allocatable, intent(out) :: values(:)  ! unique values of words(:)
integer :: i,n,nfac,imatch
n = size(words)
if (size(factors) /= n) error stop "in compress, need size(words) == size(factors)"
if (n < 1) then
   allocate (values(0))
   return
end if
allocate (values(n))
values(1) = words(1)
factors(1) = 1
nfac = 1
do i=2,n
   imatch = findloc(values(:nfac),words(i),dim=1)
   if (imatch == 0) then
      nfac = nfac + 1
      factors(i) = nfac
      values(nfac) = words(i)
   else
      factors(i) = imatch
   end if
end do
values = values(:nfac)
end subroutine compress
end module
program p
use exact_compress_module
implicit none
character(3) :: words(7)
character(3), allocatable :: values(:)
integer :: factors(7)
words=['cat','dog','cat','eel','dog','ant','eel']
call compress(words,factors,values)
if (any(factors/=[1,2,1,3,2,4,3])) error stop 1
if (.not.allocated(values)) error stop 2
if (len(values)/=3 .or. size(values)/=4) error stop 3
if (lbound(values,1)/=1 .or. ubound(values,1)/=4) error stop 4
if (any(values/=['cat','dog','eel','ant'])) error stop 5
words=['ant','ant','cat','ant','cat','eel','ant']
call compress(words,factors,values)
if (any(factors/=[1,1,2,1,2,3,1])) error stop 6
if (size(values)/=3 .or. any(values/=['ant','cat','eel'])) error stop 7
print *,1
end program
