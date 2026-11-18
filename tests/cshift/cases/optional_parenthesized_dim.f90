program p
implicit none

call inspect(2)
print *, "PASS"
contains
subroutine inspect(d)
integer,optional,intent(in)::d
integer::a(2,3),b(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
if(present(d)) then
b=cshift(a,1,(d))
if(any(b/=reshape([3,4,5,6,1,2],[2,3]))) error stop 1
end if
end subroutine
end program
