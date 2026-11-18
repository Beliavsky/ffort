module m
implicit none
private
public::make,operator(.pair.)
interface make
module procedure make_int,make_real
end interface
interface operator(.pair.)
module procedure pair_values
end interface
contains
pure function make_int(n) result(y)
integer,intent(in)::n
integer::y(n)
y=2
end function
pure function make_real(x) result(y)
real,intent(in)::x(:)
real::y(size(x))
y=2*x
end function
pure function pair_values(a,b) result(y)
integer,intent(in)::a,b
integer::y(2)
y=[a,b]
end function
end module
program p
use m
implicit none
print *,make(3),make([1.0,3.0]),4.pair.9
end program
