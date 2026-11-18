program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
call change(aa(3:-2:-2,8:4:-2))
print *,aa
contains
subroutine change(xx)
integer,intent(inout) :: xx(-3:,7:)
print *,size(xx),size(xx,1),size(xx,2),lbound(xx,1),ubound(xx,1),lbound(xx,2),ubound(xx,2)
print *,xx
xx=xx+1000
end subroutine
end program section_oracle
