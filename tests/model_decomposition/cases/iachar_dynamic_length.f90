program p
implicit none
print *,code('AB')
contains
integer function code(c)
character(*),intent(in)::c
code=iachar(c)
end function
end program
