program independent_ranktwo
implicit none
real(8) :: aa(2,2)
aa=1.25d0
call scale(aa)
print *,aa
contains
subroutine scale(xx)
 real(8),intent(inout) :: xx(:,:)
 xx=xx*2.0d0
 xx(2,1)=xx(2,1)+0.125d0
end subroutine scale
end program independent_ranktwo
