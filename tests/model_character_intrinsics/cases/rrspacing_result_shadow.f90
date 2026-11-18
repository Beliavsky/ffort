program p
implicit none
print *,f()
contains
integer function f() result(rrspacing)
rrspacing=7
end function
end program
