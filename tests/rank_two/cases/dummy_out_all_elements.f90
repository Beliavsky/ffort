program independent_ranktwo
implicit none
integer :: aa(-1:0,2:4)
call fill(aa)
print *,aa
contains
subroutine fill(xx)
 integer,intent(out) :: xx(3:,7:)
 integer :: ii,jj
 do jj=7,9
 do ii=3,4
 xx(ii,jj)=ii+10*jj
 end do
 end do
end subroutine fill
end program independent_ranktwo
