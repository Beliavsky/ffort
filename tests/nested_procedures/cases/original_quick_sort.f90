module original_sort
implicit none
integer, parameter :: dp=kind(0d0)
interface isnan
module procedure isnan_real
end interface
contains
elemental function isnan_real(x) result(tf)
real(kind=dp),intent(in)::x
logical::tf
tf=x/=x
end function
recursive subroutine quick_sort(list, order)
! Quick sort routine from:
! Brainerd, W.S., Goldberg, C.H. & Adams, J.C. (1990) "Programmer's Guide to
! Fortran 90", McGraw-Hill  ISBN 0-07-000248-7, pages 149-150.
! Modified by Alan Miller to include an associated integer array which gives
! the positions of the elements in the original order.
real(kind=dp), intent(in out) :: list(:)
integer      , intent(out)    :: order(:)
! Local variable
integer :: i
do i = 1, size(list)
  order(i) = i
end do
if (any(isnan(list))) return
call quick_sort_1(1, size(list))
contains
recursive subroutine quick_sort_1(left_end, right_end)
integer, intent(in) :: left_end, right_end
!     Local variables
integer             :: i, j, itemp
real(kind=dp)                :: reference, temp
integer, parameter  :: max_simple_sort_size = 6
if (right_end < left_end + max_simple_sort_size) then
  ! Use interchange sort for small lists
  call interchange_sort(left_end, right_end)
else
  ! Use partition ("quick") sort
  reference = list((left_end + right_end)/2)
  i = left_end - 1; j = right_end + 1
  do
    ! Scan list from left end until element >= reference is found
    do
      i = i + 1
!      if (i > size(list)) exit ! added 01/03/2021 10:54 AM by Vivek Rao to avoid out-of-bounds error
      if (list(i) >= reference) exit
    end do
    ! Scan list from right end until element <= reference is found
    do
      j = j - 1
!      if (j < 1) exit ! added 01/03/2021 10:55 AM by Vivek Rao to avoid out-of-bounds error
      if (list(j) <= reference) exit
    end do
    if (i < j) then
      ! Swap two out-of-order elements
      temp = list(i); list(i) = list(j); list(j) = temp
      itemp = order(i); order(i) = order(j); order(j) = itemp
    else if (i == j) then
      i = i + 1
      exit
    else
      exit
    end if
  end do
  if (left_end < j) call quick_sort_1(left_end, j)
  if (i < right_end) call quick_sort_1(i, right_end)
end if
end subroutine quick_sort_1

subroutine interchange_sort(left_end, right_end)
integer, intent(in) :: left_end, right_end
!     Local variables
integer             :: i, j, itemp
real(kind=dp)                :: temp
do i = left_end, right_end - 1
  do j = i+1, right_end
    if (list(i) > list(j)) then
      temp = list(i); list(i) = list(j); list(j) = temp
      itemp = order(i); order(i) = order(j); order(j) = itemp
    end if
  end do
end do
end subroutine interchange_sort
end subroutine quick_sort
subroutine verify_sort(original)
real(kind=dp),intent(in)::original(:)
real(kind=dp)::x(size(original)),once(size(original))
integer::order(size(original)),again(size(original)),seen(size(original)),i,n
logical::sorted_ok,indexed_ok,permutation_ok,repeated_ok
n=size(original)
x=original
call quick_sort(x,order)
sorted_ok=.true.
indexed_ok=.true.
permutation_ok=.true.
seen=0
do i=1,n
  if(i>1) then
    if(x(i)<x(i-1)) sorted_ok=.false.
  end if
  if(order(i)<1.or.order(i)>n) then
    permutation_ok=.false.
    indexed_ok=.false.
  else
    seen(order(i))=seen(order(i))+1
    if(x(i)/=original(order(i))) indexed_ok=.false.
  end if
end do
if(any(seen/=1)) permutation_ok=.false.
once=x
call quick_sort(x,again)
repeated_ok=all(x==once)
seen=0
do i=1,n
  if(again(i)<1.or.again(i)>n) then
    repeated_ok=.false.
  else
    seen(again(i))=seen(again(i))+1
    if(x(i)/=once(again(i))) repeated_ok=.false.
  end if
end do
if(any(seen/=1)) repeated_ok=.false.
print *,n,sorted_ok,indexed_ok,permutation_ok,repeated_ok,sum(x),sum(order)
end subroutine
end module
program p
use original_sort
implicit none
real(kind=dp)::x(64)
integer::i,n
x=0.0_dp
call verify_sort(x(:0))
x(1)=-4.0_dp
call verify_sort(x(:1))
x(:2)=[2.0_dp,-2.0_dp]
call verify_sort(x(:2))
x(:6)=[6.0_dp,-2.0_dp,6.0_dp,3.0_dp,0.0_dp,-2.0_dp]
call verify_sort(x(:6))
x(:7)=[7.0_dp,-2.0_dp,7.0_dp,3.0_dp,0.0_dp,-2.0_dp,9.0_dp]
call verify_sort(x(:7))
x(:8)=5.0_dp
call verify_sort(x(:8))
do i=1,17
  x(i)=1.0_dp*(i-9)
end do
call verify_sort(x(:17))
do i=1,31
  x(i)=1.0_dp*(16-i)
end do
call verify_sort(x(:31))
do i=1,64
  x(i)=1.0_dp*(mod(17*i,13)-6)
end do
call verify_sort(x)
call verify_sort(x)
end program
