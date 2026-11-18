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
character(3) :: words(2)
character(3),allocatable :: values(:)
integer :: factors(1)
words=['abc','def']
call compress(words,factors,values)
print *,999
end program
