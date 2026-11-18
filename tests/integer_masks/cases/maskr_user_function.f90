program p
implicit none
print *,maskr(f())
contains
integer function f()
f=2
end function
end program
