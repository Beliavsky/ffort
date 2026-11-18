program independent_ranktwo
implicit none
integer :: aa(6)
print *,111
call consume(aa)
contains
subroutine consume(xx)
integer,intent(in) :: xx(:,:)
end subroutine consume
end program independent_ranktwo
