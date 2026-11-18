module model_generics
implicit none
interface pick
module procedure scalar4,scalar8
end interface
contains
integer function scalar4(x)
real,intent(in)::x
scalar4=4
end function
integer function scalar8(x)
real(8),intent(in)::x
scalar8=8
end function
end module
program model_composition
use model_generics
implicit none
real::a(2)
real(8)::b(0)
integer::v(radix(a))
integer,parameter::k=2*radix(b)
v=1
print *,pick(epsilon(a)),pick(tiny(b)),pick(huge(b))
print *,size(v),sum(v),floor(2.0-epsilon(a),kind=k),radix(huge(b))
print *,tiny(b)/epsilon(b),huge(0_8)/huge(0)
print *,floor([2.0,2.0-epsilon(a),2.0-2.0*epsilon(a)])
end program
