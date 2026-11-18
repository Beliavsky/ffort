module operations
implicit none

interface choose
module procedure a,b,c
end interface
contains
integer function a(x) result(y)
integer,intent(in)::x
y=x+100
end function
integer function b(x) result(y)
integer,intent(in)::x(:)
y=sum(x)+200
end function
integer function c(x) result(y)
integer,intent(in)::x(:,:)
y=sum(x)+300
end function
end module
program main
use operations
implicit none
integer::v(2)=[1,2]
integer::w(2,2)
w(1,1)=1
w(2,1)=2
w(1,2)=3
w(2,2)=4
print *,choose(4),choose(v),choose(w)

end program
