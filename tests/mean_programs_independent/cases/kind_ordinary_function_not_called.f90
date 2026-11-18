program p
implicit none
integer::aa
print *,kind(no_value(aa))
contains
real(8) function no_value(xx) result(yy)
integer,intent(in)::xx
end function
end program p
