program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=3
call revise(aa,(aa))
print *,aa
contains
subroutine revise(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=xx+yy
end subroutine revise
end program independent_ranktwo
