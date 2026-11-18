program independent_ranktwo
implicit none
integer :: aa(0,3),bb(0,2)
print *,111
call combine(aa,bb)
contains
subroutine combine(xx,yy)
 integer,intent(out) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=yy
end subroutine combine
end program independent_ranktwo
