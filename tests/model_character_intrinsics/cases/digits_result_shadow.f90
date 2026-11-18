program p
implicit none
print *,f()
contains
integer function f() result(digits)
digits=7
end function
end program
