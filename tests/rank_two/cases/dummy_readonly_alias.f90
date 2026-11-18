program independent_ranktwo
implicit none
integer :: aa(2,3)
aa=5
print *,tally(aa,aa)
contains
integer function tally(xx,yy) result(rr)
 integer,intent(in) :: xx(:,:),yy(-1:,4:)
 rr=xx(2,3)+yy(0,6)+size(xx)+size(yy)
end function tally
end program independent_ranktwo
