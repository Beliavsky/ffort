program independent_ranktwo
implicit none
real(4) :: aa(2,3)
print *,111
call consume(aa)
contains
subroutine consume(xx)
real(8),intent(in) :: xx(:,:)
end subroutine consume
end program independent_ranktwo
