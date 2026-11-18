program p
implicit none

print *,spacing(2),nearest(3)
contains
integer function spacing(x)
integer,intent(in)::x
spacing=x+1
end function
integer function nearest(x)
integer,intent(in)::x
nearest=x+2
end function
end program
