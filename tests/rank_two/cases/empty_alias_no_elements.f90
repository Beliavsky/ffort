program independent_ranktwo
implicit none
integer :: aa(0,3)
call revise(aa,aa)
print *,size(aa),size(aa,2)
contains
subroutine revise(xx,yy)
 integer,intent(out) :: xx(:,:)
 integer,intent(in) :: yy(:,:)
 xx=yy+1
end subroutine revise
end program independent_ranktwo
