module operators
implicit none
private
public :: operator(.in.), operator(.notall.), operator(.twice.), operator(.join.), operator(.p.)
interface operator(.in.)
 module procedure :: int_in_vec, real_in_vec
end interface operator(.in.)
interface operator(.notall.)
 module procedure notall
end interface
interface operator(.twice.)
 module procedure twice_int, twice_real
end interface
interface operator(.join.)
 module procedure join_int, join_logical
end interface
interface operator(.p.)
 module procedure power_pair
end interface
contains
pure function int_in_vec(i,ivec) result(tf)
integer, intent(in) :: i,ivec(:)
logical             :: tf
integer::j
tf=.false.
do j=1,size(ivec)
 tf=tf.or.i==ivec(j)
end do
end function int_in_vec
pure function real_in_vec(x,vec) result(tf)
real(kind=8),intent(in)::x,vec(:)
logical::tf
integer::j
tf=.false.
do j=1,size(vec)
 tf=tf.or.x==vec(j)
end do
end function
pure function notall(ivec) result(tf)
logical, intent(in) :: ivec(:)
logical             :: tf
integer::j
tf=.false.
do j=1,size(ivec)
 tf=tf.or..not.ivec(j)
end do
end function
pure elemental integer function twice_int(x) result(y)
integer,intent(in)::x
y=2*x
end function
pure elemental real(kind=8) function twice_real(x) result(y)
real(kind=8),intent(in)::x
y=2*x
end function
pure elemental integer function join_int(x,y) result(z)
integer,intent(in)::x,y
z=10*x+y
end function
pure elemental logical function join_logical(x,y) result(z)
logical,intent(in)::x,y
z=x.eqv.y
end function
pure integer function power_pair(x,y) result(z)
integer,intent(in)::x,y
z=x**y
end function
end module
program main
use operators
implicit none

print *, 2 .twice. 3
end program
