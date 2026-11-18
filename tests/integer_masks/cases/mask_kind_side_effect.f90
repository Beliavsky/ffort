program p
implicit none
print *,maskl(1,kind=f())
contains
integer function f()
f=4
end function
end program
