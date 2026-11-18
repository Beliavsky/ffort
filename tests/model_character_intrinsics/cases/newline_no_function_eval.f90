program p
implicit none
print *,iachar(new_line(f()))
contains
function f() result(c)
character::c
error stop 1
end function
end program
