program rankthree
implicit none
integer :: aa(2,3,4)
aa=1
call bump(aa)
print *,aa
contains
subroutine bump(xx)
integer,intent(inout) :: xx(:,:,:)
integer :: temp(size(xx,1),size(xx,2),size(xx,3))
temp=xx+1
xx=temp
end subroutine bump
end program rankthree
