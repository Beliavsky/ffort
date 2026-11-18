module types
implicit none
type :: item
real(8)::x
end type
end module
program main
use types
implicit none
type(item)::a
write(*,'(i0)')radix(dim(sign(a%x,-1d0),0d0))
end program
