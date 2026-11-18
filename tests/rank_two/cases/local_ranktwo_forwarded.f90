program independent_ranktwo
implicit none
integer :: answer
call outer(answer)
print *,answer
contains
subroutine outer(rr)
 integer,intent(out) :: rr
 integer :: local(-1:0,4:6)
 local=3
 call inner(local)
 rr=local(-1,4)+local(0,6)
end subroutine outer
subroutine inner(xx)
 integer,intent(inout) :: xx(:,:)
 xx=xx*2
 xx(2,3)=19
end subroutine inner
end program independent_ranktwo
