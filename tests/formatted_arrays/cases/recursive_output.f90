program main
implicit none

print '(2i3)',make()
contains
impure elemental integer function make()
print *,"bad"
make=1
end function
end program
