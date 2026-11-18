program p
implicit none
print *,f(1),g(2),h(3),j(4)
contains
integer function f(x) result(aint)
integer,intent(in)::x
aint=x+1
end function
integer function g(x) result(anint)
integer,intent(in)::x
anint=x+2
end function
integer function h(x) result(asinh)
integer,intent(in)::x
asinh=x+3
end function
integer function j(x) result(acosh)
integer,intent(in)::x
acosh=x+4
end function
end program
