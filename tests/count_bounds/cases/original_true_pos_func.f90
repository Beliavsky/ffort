module m
implicit none
contains
function true_pos_func(tf) result(ipos)
! return in ipos the positions of the true elements in tf(:)
logical, intent(in) :: tf(:)
integer             :: ipos(count(tf))
integer             :: i,j
j = 0
do i=1,size(tf)
   if (tf(i)) then
      j = j + 1
      ipos(j) = i
   end if
end do
end function true_pos_func
!
end module
program p
use m
implicit none
logical::empty(0)
print *,true_pos_func([.true.,.false.,.true.,.true.])
print *,size(true_pos_func([.false.,.false.]))
print *,size(true_pos_func(empty))
print *,sum(true_pos_func([.false.,.true.]))
print *,true_pos_func([.true.])
end program
