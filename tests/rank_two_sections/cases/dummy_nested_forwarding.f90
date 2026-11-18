program section_oracle
implicit none
integer :: aa(-2:3,4:8),i,j
do j=4,8
 do i=-2,3
 aa(i,j)=100*j+i
 end do
end do
call outer(aa(3:-2:-1,8:4:-2))
print *,aa
contains
subroutine outer(xx)
integer,intent(inout)::xx(-3:,7:)
call inner(xx(-2:1:2,9:7:-1))
call line(xx(-3,7:9))
end subroutine
subroutine inner(yy)
integer,intent(inout)::yy(:,:)
yy=yy+1000
end subroutine
subroutine line(zz)
integer,intent(inout)::zz(:)
zz=zz+2000
end subroutine
end program section_oracle
