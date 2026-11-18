module boxes
type :: box
doubleprecision :: value
end type
end module
program p
use boxes
implicit none
type(box)::b
b=box(2.25d0)
print *,b%value
end program
