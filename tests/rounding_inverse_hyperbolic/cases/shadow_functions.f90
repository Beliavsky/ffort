program p
implicit none
print *,aint(1),anint(2),asinh(3),acosh(4)
contains
integer function aint(x)
integer,intent(in)::x
aint=x+1
end function
integer function anint(x)
integer,intent(in)::x
anint=x+2
end function
integer function asinh(x)
integer,intent(in)::x
asinh=x+3
end function
integer function acosh(x)
integer,intent(in)::x
acosh=x+4
end function
end program
