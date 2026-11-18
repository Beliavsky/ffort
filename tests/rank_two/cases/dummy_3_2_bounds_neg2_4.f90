program independent_ranktwo
implicit none
integer :: aa(-2:0,4:5),ii,jj
do jj=4,5
 do ii=-2,0
 aa(ii,jj)=100*jj+ii
 end do
end do
call bump(aa)
print *,aa
print *,total(aa),total(aa+1)
contains
subroutine bump(xx)
 integer,intent(inout) :: xx(-4:,6:)
 print *,size(xx),size(xx,1),size(xx,2)
 print *,lbound(xx,1),ubound(xx,1),lbound(xx,2),ubound(xx,2)
 xx=xx+3
end subroutine bump
integer function total(xx) result(rr)
 integer,intent(in) :: xx(:,:)
 integer :: ii,jj
 rr=0
 do jj=lbound(xx,2),ubound(xx,2)
 do ii=lbound(xx,1),ubound(xx,1)
 rr=rr+xx(ii,jj)
 end do
 end do
end function total
end program independent_ranktwo
