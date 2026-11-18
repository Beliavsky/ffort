program p
implicit none
print *,maskl(f())
contains
integer function f()
f=2
end function
end program
