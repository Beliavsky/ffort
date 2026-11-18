program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=9
print *,111
call revise(aa)
contains
subroutine revise(xx)
 integer,intent(out) :: xx(:,:)
 print *,xx(2,2)
end subroutine revise
end program independent_ranktwo
