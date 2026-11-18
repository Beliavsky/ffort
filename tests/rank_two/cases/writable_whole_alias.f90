program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=1
print *,111
call collide(aa,aa)
contains
subroutine collide(xx,yy)
 integer,intent(inout) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=yy+1
end subroutine collide
end program independent_ranktwo
