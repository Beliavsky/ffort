program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
call change(aa(1,8:4:-1),10)
call change(aa(3:-2:-2,5),20)
print *,aa
contains
subroutine change(xx,amount)
integer,intent(inout)::xx(-3:)
integer,intent(in)::amount
print *,size(xx),lbound(xx,1),ubound(xx,1)
xx=xx+amount
end subroutine
end program section_oracle
