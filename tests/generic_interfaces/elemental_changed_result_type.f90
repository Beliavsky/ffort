module operations
implicit none
interface flip
module procedure from_integer,from_real
end interface
contains
elemental real(kind=8) function from_integer(x) result(y)
integer,intent(in)::x
y=2.5_8*x
end function
elemental integer function from_real(x) result(y)
real(kind=8),intent(in)::x
y=int(x)+10
end function
end module
program main
use operations
implicit none
integer::a(3)=[1,2,3]
real(kind=8)::x(3)=[1.0_8,2.0_8,3.0_8]
print *,flip(2),flip(2.0_8)
print *,flip(a),flip(x)
print *,flip(flip(2)),flip(flip(2.0_8))
print *,flip(flip(a)),flip(flip(x))
end program
