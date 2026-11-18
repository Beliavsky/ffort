program independent_ranktwo
implicit none
integer :: aa(2,3),bb(3,2)
aa=5
bb=9
print *,111
call combine(aa,bb)
contains
subroutine combine(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=xx+yy
end subroutine combine
end program independent_ranktwo
