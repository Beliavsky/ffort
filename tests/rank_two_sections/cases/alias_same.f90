program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
print *,111
call work(aa(-2:2:2,4:8:2),aa(-2:2:2,4:8:2))
print *,aa
contains
subroutine work(xx,yy)
integer,intent(inout)::xx(:,:),yy(:,:)
print *,222
xx=xx+1000
yy=yy+2000
end subroutine
end program section_oracle
