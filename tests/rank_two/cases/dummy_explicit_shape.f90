program independent_ranktwo
implicit none
integer :: aa(2,3)
aa=1
call consume(aa)
contains
subroutine consume(xx)
integer,intent(in) :: xx(2,3)
print *,xx(1,1)
end subroutine consume
end program independent_ranktwo
