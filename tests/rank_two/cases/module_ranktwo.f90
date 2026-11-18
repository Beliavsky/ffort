module matrices
 implicit none
 private
 public :: increment,checksum
contains
 subroutine increment(xx)
 integer,intent(inout) :: xx(:,:)
 xx=xx+2
 end subroutine increment
 integer function checksum(xx) result(rr)
 integer,intent(in) :: xx(:,:)
 integer :: i,j
 rr=0
 do j=1,size(xx,2)
 do i=1,size(xx,1)
 rr=rr+xx(i,j)
 end do
 end do
 end function checksum
end module matrices
program independent_ranktwo
 use matrices,only:increment,checksum
 implicit none
 integer :: aa(2,3)
 aa=4
 call increment(aa)
 print *,aa,checksum(aa)
end program independent_ranktwo
