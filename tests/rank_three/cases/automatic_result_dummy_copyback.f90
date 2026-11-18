program rankthree
implicit none
integer :: aa(2,2,3),bb(2,2,3)
aa=1
call bump(aa(:,:,3:1:-1),2,2,3)
bb=twice(aa)
print *,aa,bb
contains
subroutine bump(xx,n,m,l)
integer,intent(in) :: n,m,l
integer,intent(inout) :: xx(-2:,4:,7:)
integer :: temp(n,m,l)
temp=xx+2
xx=temp
xx(-2,4,7)=8
end subroutine bump
function twice(xx) result(rr)
integer,intent(in) :: xx(:,:,:)
integer :: rr(size(xx,1),size(xx,2),size(xx,3))
rr=xx*2
end function twice
end program rankthree
