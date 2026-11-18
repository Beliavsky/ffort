program independent_ranktwo
implicit none
integer :: aa(2,2)
aa(2,2)=8
call partial(aa)
print *,aa(1,1),aa(2,2)
print *,aa(1,2)
contains
subroutine partial(xx)
 integer,intent(inout) :: xx(:,:)
 xx(1,1)=42
end subroutine partial
end program independent_ranktwo
