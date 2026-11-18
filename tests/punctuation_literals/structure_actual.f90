module boxes
implicit none
type :: box
character::c
end type
end module
program p
use boxes
implicit none
type(box)::b
b=box(')')
print '(a)',b%c
end program
