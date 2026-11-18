program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=3
call partial(aa)
print *,aa(1,1)
print *,aa(1,2)
contains
subroutine partial(xx)
 integer,intent(out) :: xx(:,:)
 xx(1,1)=42
end subroutine partial
end program independent_ranktwo
