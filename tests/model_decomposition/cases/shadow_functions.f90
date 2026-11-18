program p
implicit none
print *,fraction(1),exponent(1),set_exponent(1),iachar(1)
contains
integer function fraction(a)
integer,intent(in)::a
fraction=a+1
end function
integer function exponent(a)
integer,intent(in)::a
exponent=a+2
end function
integer function set_exponent(a)
integer,intent(in)::a
set_exponent=a+3
end function
integer function iachar(a)
integer,intent(in)::a
iachar=a+4
end function
end program
