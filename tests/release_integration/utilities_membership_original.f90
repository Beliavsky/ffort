module utility_operators
implicit none
private
public::operator(.in.),operator(.notall.)
interface operator(.in.)
module procedure int_in_vec
end interface
interface operator(.notall.)
module procedure notall
end interface
contains
pure function int_in_vec(i,ivec) result(tf)
integer, intent(in) :: i,ivec(:)
logical             :: tf
tf = (any(i == ivec))
end function int_in_vec
pure function notall(ivec) result(tf)
logical, intent(in) :: ivec(:)
logical             :: tf
tf = .not. all(ivec)
end function notall
end module
program main
use utility_operators
implicit none
print *,3 .in. [1,3,5],2 .in. [1,3,5]
print *,.notall. [.true.,.false.],.notall. [.true.,.true.]
end program
