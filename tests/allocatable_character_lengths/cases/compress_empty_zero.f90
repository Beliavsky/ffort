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
character(4) :: empty(0)
character(4), allocatable :: values(:)
character(0) :: zero(3), zero_empty(0)
character(0), allocatable :: zero_values(:)
integer :: factors_empty(0), factors_zero(3)
allocate(values(-2:2))
values='old'
call compress(empty,factors_empty,values)
if (.not.allocated(values)) error stop 1
if (len(values)/=4 .or. size(values)/=0) error stop 2
if (lbound(values,1)/=1 .or. ubound(values,1)/=0) error stop 3
zero=''
call compress(zero,factors_zero,zero_values)
if (any(factors_zero/=1)) error stop 4
if (size(zero_values)/=1 .or. len(zero_values)/=0) error stop 5
call compress(zero_empty,factors_empty,zero_values)
if (.not.allocated(zero_values)) error stop 6
if (size(zero_values)/=0 .or. len(zero_values)/=0) error stop 7
print *,1
end program
