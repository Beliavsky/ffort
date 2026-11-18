program independent_ranktwo
implicit none
integer :: aa(0,3),bb(0,2)
print *,111
call revise(aa,bb)
contains
subroutine revise(xx,yy)
 integer,intent(in) :: xx(:,:),yy(:,:)
 print *,xx+yy
end subroutine revise
end program independent_ranktwo
