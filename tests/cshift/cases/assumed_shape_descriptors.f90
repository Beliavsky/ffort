program p
implicit none
integer::a(-1:1,4:7)
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
call inspect(a(1:-1:-1,7:4:-1),[-1,0,1])
print *, "PASS"
contains
subroutine inspect(a,s)
integer,intent(in)::a(:,:),s(:)
integer::b(size(a,1),size(a,2))
b=cshift(a,s,2)
if(any(b/=reshape([3,11,7,12,8,4,9,5,1,6,2,10],[3,4]))) error stop 1
end subroutine
end program
