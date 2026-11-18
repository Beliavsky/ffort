program independent_ranktwo
implicit none
integer :: aa(2,3)
aa=9
print *,111
call revise(aa)
contains
subroutine revise(xx)
 integer,intent(inout) :: xx(-1:,5:)
 xx(0,8)=7
end subroutine revise
end program independent_ranktwo
