program independent_ranktwo
implicit none
integer :: aa(2,3)
print *,111
call consume(aa+1)
contains
subroutine consume(xx)
integer,intent(out) :: xx(:,:)
end subroutine consume
end program independent_ranktwo
