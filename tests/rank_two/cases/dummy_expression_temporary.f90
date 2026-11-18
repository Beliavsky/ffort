program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=7
call revise(aa,aa+1)
print *,aa
contains
subroutine revise(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=xx+yy
end subroutine revise
end program independent_ranktwo
