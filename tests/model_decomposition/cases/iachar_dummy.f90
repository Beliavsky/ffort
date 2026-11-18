program p
implicit none
print *,code('A'),code('z')
contains
integer(8) function code(c)
character(*),intent(in)::c
code=iachar(c,8)
end function
end program
