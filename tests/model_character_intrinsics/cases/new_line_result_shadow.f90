program p
implicit none
print *,f()
contains
integer function f() result(new_line)
new_line=7
end function
end program
