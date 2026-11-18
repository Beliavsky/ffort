program main
implicit none

print '(2i3)',make()
contains
function make() result(a)
integer::a(5)
a=[1,2,3,4,5]
end function
end program
