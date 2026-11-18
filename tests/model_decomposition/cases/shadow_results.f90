program p
implicit none
print *,f0(1),f1(1),f2(1),f3(1)
contains
integer function f0(a) result(fraction)
integer,intent(in)::a
fraction=a+0
end function
integer function f1(a) result(exponent)
integer,intent(in)::a
exponent=a+1
end function
integer function f2(a) result(set_exponent)
integer,intent(in)::a
set_exponent=a+2
end function
integer function f3(a) result(iachar)
integer,intent(in)::a
iachar=a+3
end function
end program
