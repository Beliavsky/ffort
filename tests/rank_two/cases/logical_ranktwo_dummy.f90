program independent_ranktwo
implicit none
logical :: aa(2,3)
aa=.false.
call invert(aa)
print *,aa
contains
subroutine invert(xx)
 logical,intent(inout) :: xx(:,:)
 xx=.not.xx
 xx(1,2)=.false.
end subroutine invert
end program independent_ranktwo
