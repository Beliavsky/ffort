program p
implicit none
integer::a(3)
a=cshift(make(3),1)
if(any(a/=[2,3,1])) error stop 1
print *, "PASS"
contains
pure function make(n) result(r)
integer,intent(in)::n
integer::r(n),i
do i=1,n
r(i)=i
end do
end function
end program
